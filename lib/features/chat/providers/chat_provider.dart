// lib/features/chat/providers/chat_provider.dart
// FIXED: Simplified unread counter, removed complex readBy tracking, improved reliability
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/chat_list_item_model.dart';
import 'package:textgb/features/chat/models/video_reaction_model.dart';
import 'package:textgb/features/chat/models/moment_reaction_model.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/chat/database/chat_database_helper.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

part 'chat_provider.g.dart';

// ========================================
// CHAT LIST STATE - SIMPLIFIED
// ========================================

class ChatListState {
  final bool isLoading;
  final List<ChatListItemModel> chats;
  final String? error;
  final bool hasMore;
  final String searchQuery;
  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int totalUnreadCount;

  const ChatListState({
    this.isLoading = false,
    this.chats = const [],
    this.error,
    this.hasMore = true,
    this.searchQuery = '',
    this.isOnline = true,
    this.isSyncing = false,
    this.lastSyncTime,
    this.totalUnreadCount = 0,
  });

  ChatListState copyWith({
    bool? isLoading,
    List<ChatListItemModel>? chats,
    String? error,
    bool? hasMore,
    String? searchQuery,
    bool? isOnline,
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? totalUnreadCount,
  }) {
    return ChatListState(
      isLoading: isLoading ?? this.isLoading,
      chats: chats ?? this.chats,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
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
// CHAT LIST PROVIDER (SIMPLIFIED)
// ========================================

@riverpod
class ChatList extends _$ChatList {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  ChatDatabaseHelper get _dbHelper => ChatDatabaseHelper();
  
  StreamSubscription<List<ChatModel>>? _chatSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _unreadCountTimer;
  Timer? _syncTimer;
  
  @override
  FutureOr<ChatListState> build() async {
    // Cleanup on dispose
    ref.onDispose(() {
      debugPrint('🧹 ChatList provider disposed - cleaning up');
      _chatSubscription?.cancel();
      _connectivitySubscription?.cancel();
      _unreadCountTimer?.cancel();
      _syncTimer?.cancel();
    });

    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const ChatListState(error: 'User not authenticated');
    }

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = !connectivityResult.contains(ConnectivityResult.none);

    // Subscribe to chats stream
    _subscribeToChats(currentUser.uid);
    
    // Monitor connectivity
    _monitorConnectivity(currentUser.uid);
    
    // Start unread count monitoring
    _startUnreadCountMonitoring(currentUser.uid);
    
    // Start periodic sync
    _startPeriodicSync(currentUser.uid);
    
    // Initial sync if online
    if (isOnline) {
      _syncChats(currentUser.uid);
    }
    
    return ChatListState(
      isLoading: true,
      isOnline: isOnline,
    );
  }

  void _subscribeToChats(String userId) {
    _chatSubscription?.cancel();
    
    debugPrint('📡 Subscribing to chats stream for user: $userId');
    
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
  }

  void _monitorConnectivity(String userId) {
    _connectivitySubscription?.cancel();
    
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      final isOnline = !results.contains(ConnectivityResult.none);
      final currentState = state.valueOrNull;
      
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(isOnline: isOnline));
        
        // Sync when coming online
        if (isOnline && !currentState.isOnline) {
          debugPrint('🌐 Device came online - triggering sync');
          _syncChats(userId);
        }
      }
    });
  }

  void _startUnreadCountMonitoring(String userId) {
    _unreadCountTimer?.cancel();
    
    // Update unread count every 3 seconds (simplified from complex logic)
    _unreadCountTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final currentState = state.valueOrNull;
      if (currentState != null && currentState.chats.isNotEmpty) {
        final totalUnread = _calculateTotalUnread(currentState.chats, userId);
        
        if (totalUnread != currentState.totalUnreadCount) {
          state = AsyncValue.data(currentState.copyWith(
            totalUnreadCount: totalUnread,
          ));
        }
      }
    });
  }

  void _startPeriodicSync(String userId) {
    _syncTimer?.cancel();
    
    // Sync every 30 seconds in background
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final currentState = state.valueOrNull;
      if (currentState?.isOnline == true && currentState?.isSyncing != true) {
        _syncChats(userId);
      }
    });
  }

  // SIMPLIFIED: Just count messages where sender != currentUser
  int _calculateTotalUnread(List<ChatListItemModel> chatItems, String userId) {
    int total = 0;
    for (final chatItem in chatItems) {
      total += chatItem.chat.getUnreadCount(userId);
    }
    return total;
  }

  Future<void> _syncChats(String userId) async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.isSyncing) return;
    
    try {
      state = AsyncValue.data(currentState.copyWith(isSyncing: true));
      
      // Sync all data from server
      await _repository.syncAllData(userId);
      
      final updatedState = state.valueOrNull ?? currentState;
      state = AsyncValue.data(updatedState.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      ));
      
      debugPrint('✅ Chats synced successfully');
    } catch (e) {
      debugPrint('❌ Sync error: $e');
      final updatedState = state.valueOrNull ?? currentState;
      state = AsyncValue.data(updatedState.copyWith(
        isSyncing: false,
        error: 'Sync failed: $e',
      ));
    }
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
  // PUBLIC METHODS - SIMPLIFIED
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

  // SIMPLIFIED: Just update the unread count to 0
  Future<void> markChatAsRead(String chatId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.markChatAsRead(chatId, userId);
      
      // Update local state immediately
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedChats = currentState.chats.map((chatItem) {
          if (chatItem.chat.chatId == chatId) {
            final updatedChat = chatItem.chat.copyWith(
              unreadCounts: {...chatItem.chat.unreadCounts, userId: 0},
            );
            return ChatListItemModel(
              chat: updatedChat,
              contactName: chatItem.contactName,
              contactImage: chatItem.contactImage,
              contactPhone: chatItem.contactPhone,
              isOnline: chatItem.isOnline,
              lastSeen: chatItem.lastSeen,
            );
          }
          return chatItem;
        }).toList();
        
        final totalUnread = _calculateTotalUnread(updatedChats, userId);
        
        state = AsyncValue.data(currentState.copyWith(
          chats: updatedChats,
          totalUnreadCount: totalUnread,
        ));
      }
      
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
      
      // Remove from local state
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedChats = currentState.chats
            .where((chatItem) => chatItem.chat.chatId != chatId)
            .toList();
        
        final totalUnread = _calculateTotalUnread(updatedChats, userId);
        
        state = AsyncValue.data(currentState.copyWith(
          chats: updatedChats,
          totalUnreadCount: totalUnread,
        ));
      }
      
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

  Future<void> syncChats() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await _syncChats(userId);
  }

  Future<void> syncAllData() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final currentState = state.valueOrNull;
    if (currentState == null || currentState.isSyncing) return;

    try {
      state = AsyncValue.data(currentState.copyWith(isSyncing: true));
      
      await _repository.syncAllData(userId);
      
      final updatedState = state.valueOrNull ?? currentState;
      state = AsyncValue.data(updatedState.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      ));
      
      debugPrint('✅ All data synced');
    } catch (e) {
      debugPrint('❌ Sync all data error: $e');
      final updatedState = state.valueOrNull ?? currentState;
      state = AsyncValue.data(updatedState.copyWith(
        isSyncing: false,
        error: 'Sync failed: $e',
      ));
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
        'isSyncing': false,
        'lastSyncTime': null,
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
      'isSyncing': currentState.isSyncing,
      'lastSyncTime': currentState.lastSyncTime,
    };
  }

  String? get currentUserId => ref.read(currentUserIdProvider);
  bool get isAuthenticated => currentUserId != null;
  
  bool get isOnline {
    final currentState = state.valueOrNull;
    return currentState?.isOnline ?? false;
  }
  
  bool get isSyncing {
    final currentState = state.valueOrNull;
    return currentState?.isSyncing ?? false;
  }
  
  int get totalUnreadCount {
    final currentState = state.valueOrNull;
    return currentState?.totalUnreadCount ?? 0;
  }
}