// lib/features/chat/providers/chat_provider.dart
// UPDATED: Simplified WebSocket-based real-time chat provider
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/chat_list_item_model.dart';
import 'package:textgb/features/chat/models/video_reaction_model.dart';
import 'package:textgb/features/chat/models/moment_reaction_model.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/chat/database/chat_database_helper.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'dart:async';

part 'chat_provider.g.dart';

// ========================================
// SIMPLIFIED CHAT LIST STATE 
// ========================================

class ChatListState {
  final bool isLoading;
  final List<ChatListItemModel> chats;
  final String? error;
  final bool hasMore;
  final String searchQuery;
  final bool isOnline;
  final int totalUnreadCount;
  final bool isSyncing;

  const ChatListState({
    this.isLoading = false,
    this.chats = const [],
    this.error,
    this.hasMore = true,
    this.searchQuery = '',
    this.isOnline = true,
    this.totalUnreadCount = 0,
    this.isSyncing = false,
  });

  ChatListState copyWith({
    bool? isLoading,
    List<ChatListItemModel>? chats,
    String? error,
    bool? hasMore,
    String? searchQuery,
    bool? isOnline,
    int? totalUnreadCount,
    bool? isSyncing,
    bool clearError = false,
  }) {
    return ChatListState(
      isLoading: isLoading ?? this.isLoading,
      chats: chats ?? this.chats,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      isOnline: isOnline ?? this.isOnline,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  List<ChatListItemModel> get filteredChats {
    if (searchQuery.isEmpty) return chats;
    
    return chats.where((chatItem) {
      final query = searchQuery.toLowerCase();
      return chatItem.contactName.toLowerCase().contains(query) ||
             chatItem.chat.lastMessage.toLowerCase().contains(query);
    }).toList();
  }

  List<ChatListItemModel> getPinnedChats(String currentUserId) {
    return filteredChats.where((chat) => 
        chat.chat.isPinnedForUser(currentUserId)).toList();
  }

  List<ChatListItemModel> getRegularChats(String currentUserId) {
    return filteredChats.where((chat) => 
        !chat.chat.isPinnedForUser(currentUserId)).toList();
  }
}

// ========================================
// SIMPLIFIED WEBSOCKET CHAT LIST PROVIDER
// ========================================

@riverpod
class ChatList extends _$ChatList {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  OfflineFirstChatRepository get _wsRepository => _repository as OfflineFirstChatRepository;
  ChatDatabaseHelper get _dbHelper => ChatDatabaseHelper();
  
  StreamSubscription<List<ChatModel>>? _chatSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _syncTimer;
  
  @override
  FutureOr<ChatListState> build() async {
    // Cleanup on dispose
    ref.onDispose(() {
      debugPrint('🧹 ChatList provider disposed - cleaning up');
      _chatSubscription?.cancel();
      _connectionSubscription?.cancel();
      _syncTimer?.cancel();
    });

    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const ChatListState(error: 'User not authenticated');
    }

    // Initialize WebSocket repository
    await _initializeRepository(currentUser.uid);

    // Set up real-time listeners
    _setupRealtimeListeners(currentUser.uid);
    
    return ChatListState(
      isLoading: true,
      isOnline: _wsRepository.isConnected,
    );
  }

  Future<void> _initializeRepository(String userId) async {
    try {
      // Get auth token - simplified approach using Firebase Auth directly
      String? token;
      
      try {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          token = await firebaseUser.getIdToken();
          debugPrint('✅ Got auth token from Firebase Auth');
        } else {
          throw Exception('No Firebase user found');
        }
      } catch (e) {
        debugPrint('❌ Could not get auth token: $e');
        throw Exception('Could not obtain authentication token');
      }
      
      if (token != null) {
        // Initialize WebSocket repository
        await _wsRepository.initialize(userId, token);
        debugPrint('✅ Repository initialized for user: $userId');
      } else {
        throw Exception('Could not obtain authentication token');
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize repository: $e');
      final currentState = state.valueOrNull ?? const ChatListState();
      state = AsyncValue.data(currentState.copyWith(error: e.toString()));
    }
  }

  void _setupRealtimeListeners(String userId) {
    debugPrint('📡 Setting up real-time listeners for user: $userId');
    
    // Subscribe to WebSocket chat stream (replaces complex polling)
    _chatSubscription?.cancel();
    _chatSubscription = _repository.getChatsStream(userId).listen(
      (chats) async {
        try {
          final chatItems = await _buildChatListItems(chats, userId);
          final totalUnread = _calculateTotalUnread(chatItems, userId);
          
          final currentState = state.valueOrNull ?? const ChatListState();
          state = AsyncValue.data(currentState.copyWith(
            chats: chatItems,
            isLoading: false,
            totalUnreadCount: totalUnread,
            clearError: true,
          ));
          
          debugPrint('✅ Chat list updated: ${chats.length} chats, $totalUnread unread');
        } catch (e, stack) {
          debugPrint('❌ Error in chat stream: $e');
          final currentState = state.valueOrNull ?? const ChatListState();
          state = AsyncValue.data(currentState.copyWith(
            error: e.toString(),
            isLoading: false,
          ));
        }
      },
      onError: (error, stack) {
        debugPrint('❌ Chat stream error: $error');
        final currentState = state.valueOrNull ?? const ChatListState();
        state = AsyncValue.data(currentState.copyWith(
          error: error.toString(),
          isLoading: false,
        ));
      },
    );

    // Monitor WebSocket connection status
    _connectionSubscription?.cancel();
    _connectionSubscription = _wsRepository.connectionStream.listen((isConnected) {
      final currentState = state.valueOrNull;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(isOnline: isConnected));
        debugPrint('🔌 Connection status changed: $isConnected');
      }
    });

    // Set up periodic sync timer (every 5 minutes as fallback)
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_wsRepository.isConnected) {
        _performBackgroundSync(userId);
      }
    });
  }

  Future<void> _performBackgroundSync(String userId) async {
    try {
      await _repository.syncAllData(userId);
      debugPrint('✅ Background sync completed');
    } catch (e) {
      debugPrint('❌ Background sync failed: $e');
    }
  }

  // SIMPLIFIED: Just count messages where sender != currentUser
  int _calculateTotalUnread(List<ChatListItemModel> chatItems, String userId) {
    int total = 0;
    for (final chatItem in chatItems) {
      total += chatItem.chat.getUnreadCount(userId);
    }
    return total;
  }

  Future<List<ChatListItemModel>> _buildChatListItems(
      List<ChatModel> chats, String currentUserId) async {
    final authNotifier = ref.read(authenticationProvider.notifier);
    final chatItems = <ChatListItemModel>[];

    for (final chat in chats) {
      try {
        final otherUserId = chat.getOtherParticipant(currentUserId);
        
        String contactName = 'Unknown User';
        String contactImage = '';
        String contactPhone = '';
        bool isOnline = false;
        DateTime? lastSeen;
        
        // Try cached data first
        var cachedData = await _getCachedUserDetails(otherUserId, chat.chatId);
        
        if (cachedData != null) {
          contactName = cachedData['name']?.toString() ?? 'Unknown User';
          contactImage = cachedData['profileImage']?.toString() ?? '';
          contactPhone = cachedData['phoneNumber']?.toString() ?? '';
          
          final lastSeenStr = cachedData['lastSeen']?.toString();
          if (lastSeenStr != null) {
            isOnline = _isUserOnline(lastSeenStr);
            lastSeen = _parseLastSeen(lastSeenStr);
          }
        } else {
          // Fetch from server in background (don't block UI)
          _fetchAndCacheUserDetails(otherUserId, chat.chatId, authNotifier);
        }
        
        // Always add chat item (with cached/default data)
        chatItems.add(ChatListItemModel(
          chat: chat,
          contactName: contactName,
          contactImage: contactImage,
          contactPhone: contactPhone,
          isOnline: isOnline,
          lastSeen: lastSeen,
        ));
      } catch (e) {
        debugPrint('❌ Error building chat item for chat ${chat.chatId}: $e');
        
        // Add fallback item
        chatItems.add(ChatListItemModel(
          chat: chat,
          contactName: 'Unknown User',
          contactImage: '',
          contactPhone: '',
          isOnline: false,
          lastSeen: null,
        ));
      }
    }

    // Sort by last message time (most recent first)
    chatItems.sort((a, b) => b.chat.lastMessageTime.compareTo(a.chat.lastMessageTime));

    return chatItems;
  }

  Future<Map<String, dynamic>?> _getCachedUserDetails(String userId, String chatId) async {
    try {
      final participants = await _dbHelper.getChatParticipants(chatId);
      final participant = participants.firstWhere(
        (p) => p['userId'] == userId,
        orElse: () => <String, dynamic>{},
      );
      
      if (participant.isNotEmpty) {
        return {
          'uid': userId,
          'name': participant['userName'],
          'profileImage': participant['userImage'] ?? '',
          'phoneNumber': participant['phoneNumber'] ?? '',
          'lastSeen': participant['lastSeen'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(participant['lastSeen']).toIso8601String()
              : DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('Error getting cached user details: $e');
    }
    return null;
  }

  // Background user fetching (non-blocking)
  void _fetchAndCacheUserDetails(String userId, String chatId, dynamic authNotifier) {
    Future.microtask(() async {
      try {
        final userModel = await authNotifier.getUserById(userId);
        if (userModel != null) {
          await _dbHelper.insertOrUpdateParticipant(
            chatId: chatId,
            userId: userId,
            userName: userModel.name,
            userImage: userModel.profileImage,
            phoneNumber: userModel.phoneNumber,
            isOnline: _isUserOnline(userModel.lastSeen),
            lastSeen: userModel.lastSeen,
          );
          
          // Trigger a refresh after caching
          ref.invalidateSelf();
        }
      } catch (e) {
        debugPrint('Background user fetch failed for $userId: $e');
      }
    });
  }

  bool _isUserOnline(String lastSeenString) {
    try {
      final lastSeen = DateTime.parse(lastSeenString);
      final now = DateTime.now();
      final difference = now.difference(lastSeen);
      return difference.inMinutes <= 5;
    } catch (e) {
      return false;
    }
  }

  DateTime? _parseLastSeen(String lastSeenString) {
    try {
      return DateTime.parse(lastSeenString);
    } catch (e) {
      return null;
    }
  }

  // ========================================
  // PUBLIC METHODS - SIMPLIFIED (WebSocket-based)
  // ========================================

  void setSearchQuery(String query) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(searchQuery: query));
    }
  }

  void clearSearch() {
    setSearchQuery('');
  }

  Future<void> togglePinChat(String chatId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.toggleChatPin(chatId, userId);
      debugPrint('✅ Chat pin toggled');
    } catch (e) {
      debugPrint('❌ Error toggling pin: $e');
      rethrow;
    }
  }

  Future<void> toggleArchiveChat(String chatId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.toggleChatArchive(chatId, userId);
      debugPrint('✅ Chat archive toggled');
    } catch (e) {
      debugPrint('❌ Error toggling archive: $e');
      rethrow;
    }
  }

  Future<void> toggleMuteChat(String chatId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.toggleChatMute(chatId, userId);
      debugPrint('✅ Chat mute toggled');
    } catch (e) {
      debugPrint('❌ Error toggling mute: $e');
      rethrow;
    }
  }

  // SIMPLIFIED: WebSocket handles real-time updates automatically
  Future<void> markChatAsRead(String chatId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.markChatAsRead(chatId, userId);
      debugPrint('✅ Chat marked as read');
    } catch (e) {
      debugPrint('❌ Error marking chat as read: $e');
      rethrow;
    }
  }

  Future<void> deleteChat(String chatId, {bool deleteForEveryone = false}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.deleteChat(chatId, userId, deleteForEveryone: deleteForEveryone);
      debugPrint('✅ Chat deleted');
    } catch (e) {
      debugPrint('❌ Error deleting chat: $e');
      rethrow;
    }
  }

  Future<void> clearChatHistory(String chatId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.clearChatHistory(chatId, userId);
      debugPrint('✅ Chat history cleared');
    } catch (e) {
      debugPrint('❌ Error clearing chat history: $e');
      rethrow;
    }
  }

  Future<String?> createOrGetChat(String otherUserId) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return null;

    try {
      final chatId = await _repository.createOrGetChat(currentUserId, otherUserId);
      debugPrint('✅ Chat created/retrieved: $chatId');
      return chatId;
    } catch (e) {
      debugPrint('❌ Error creating/getting chat: $e');
      return null;
    }
  }

  Future<String?> createChatWithVideoReaction({
    required String otherUserId,
    required String videoId,
    required String videoUrl,
    required String thumbnailUrl,
    required String userName,
    required String userImage,
    required String reaction,
  }) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return null;

    try {
      final chatId = await _repository.createOrGetChat(currentUserId, otherUserId);
      
      final videoReaction = VideoReactionModel(
        videoId: videoId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        userName: userName,
        userImage: userImage,
        reaction: reaction,
        timestamp: DateTime.now(),
      );

      await _repository.sendVideoReactionMessage(
        chatId: chatId,
        senderId: currentUserId,
        videoReaction: videoReaction,
      );
      
      debugPrint('✅ Chat created with video reaction');
      return chatId;
    } catch (e) {
      debugPrint('❌ Error creating chat with video reaction: $e');
      return null;
    }
  }

  Future<String?> createChatWithMomentReaction({
    required String otherUserId,
    required MomentReactionModel momentReaction,
  }) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return null;

    try {
      final chatId = await _repository.createOrGetChat(currentUserId, otherUserId);
      
      await _repository.sendMomentReactionMessage(
        chatId: chatId,
        senderId: currentUserId,
        momentReaction: momentReaction,
      );
      
      debugPrint('✅ Chat created with moment reaction');
      return chatId;
    } catch (e) {
      debugPrint('❌ Error creating chat with moment reaction: $e');
      return null;
    }
  }

  // Manual sync (rarely needed with WebSocket)
  Future<void> syncChats() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final currentState = state.valueOrNull ?? const ChatListState();
    state = AsyncValue.data(currentState.copyWith(isSyncing: true));

    try {
      await _repository.syncAllData(userId);
      debugPrint('✅ Manual sync completed');
      
      // Update state to remove syncing indicator
      final newState = state.valueOrNull ?? const ChatListState();
      state = AsyncValue.data(newState.copyWith(isSyncing: false));
    } catch (e) {
      debugPrint('❌ Manual sync failed: $e');
      final newState = state.valueOrNull ?? const ChatListState();
      state = AsyncValue.data(newState.copyWith(isSyncing: false));
    }
  }

  // ========================================
  // GETTERS - SIMPLIFIED
  // ========================================

  List<ChatListItemModel> getFilteredChats([String? query]) {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    if (query != null && query.isNotEmpty) {
      return currentState.chats.where((chatItem) {
        final searchQuery = query.toLowerCase();
        return chatItem.contactName.toLowerCase().contains(searchQuery) ||
               chatItem.chat.lastMessage.toLowerCase().contains(searchQuery);
      }).toList();
    }

    return currentState.filteredChats;
  }

  List<ChatListItemModel> getPinnedChats() {
    final currentState = state.valueOrNull;
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentState == null || currentUserId == null) return [];

    return currentState.getPinnedChats(currentUserId);
  }

  List<ChatListItemModel> getRegularChats() {
    final currentState = state.valueOrNull;
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentState == null || currentUserId == null) return [];

    return currentState.getRegularChats(currentUserId);
  }

  int getUnreadChatsCount() {
    final currentState = state.valueOrNull;
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentState == null || currentUserId == null) return 0;

    return currentState.chats.where((chatItem) => 
        chatItem.chat.getUnreadCount(currentUserId) > 0).length;
  }

  int getTotalUnreadMessagesCount() {
    final currentState = state.valueOrNull;
    return currentState?.totalUnreadCount ?? 0;
  }

  Map<String, dynamic> getChatStatistics() {
    final currentState = state.valueOrNull;
    final currentUserId = ref.read(currentUserIdProvider);
    
    if (currentState == null || currentUserId == null) {
      return {
        'totalChats': 0,
        'pinnedChats': 0,
        'unreadChats': 0,
        'totalUnreadMessages': 0,
        'mutedChats': 0,
        'onlineContacts': 0,
        'isOnline': false,
        'connectionType': 'websocket',
      };
    }

    final pinnedChats = currentState.getPinnedChats(currentUserId).length;
    final unreadChats = getUnreadChatsCount();
    final mutedChats = currentState.chats.where((chatItem) => 
        chatItem.chat.isMutedForUser(currentUserId)).length;
    final onlineContacts = currentState.chats.where((chatItem) => 
        chatItem.isOnline).length;

    return {
      'totalChats': currentState.chats.length,
      'pinnedChats': pinnedChats,
      'unreadChats': unreadChats,
      'totalUnreadMessages': currentState.totalUnreadCount,
      'mutedChats': mutedChats,
      'onlineContacts': onlineContacts,
      'isOnline': currentState.isOnline,
      'connectionType': 'websocket',
    };
  }

  String? get currentUserId => ref.read(currentUserIdProvider);
  bool get isAuthenticated => currentUserId != null;
  
  bool get isOnline {
    final currentState = state.valueOrNull;
    return currentState?.isOnline ?? false;
  }
  
  int get totalUnreadCount {
    final currentState = state.valueOrNull;
    return currentState?.totalUnreadCount ?? 0;
  }

  bool get isConnected => _wsRepository.isConnected;

  // Reconnection helper
  Future<bool> reconnectIfNeeded() async {
    if (!isConnected) {
      return await _wsRepository.reconnect();
    }
    return isConnected;
  }
}