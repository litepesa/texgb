// lib/features/chat/providers/chat_provider.dart
// Updated chat provider with offline-first support using SQLite
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

part 'chat_provider.g.dart';

// Chat List State
class ChatListState {
  final bool isLoading;
  final List<ChatListItemModel> chats;
  final String? error;
  final bool hasMore;
  final String searchQuery;
  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastSyncTime;

  const ChatListState({
    this.isLoading = false,
    this.chats = const [],
    this.error,
    this.hasMore = true,
    this.searchQuery = '',
    this.isOnline = true,
    this.isSyncing = false,
    this.lastSyncTime,
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

  List<ChatListItemModel> get pinnedChats {
    final currentUser = chats.isNotEmpty ? chats.first.chat.participants.firstWhere(
      (id) => id != chats.first.chat.participants.first, 
      orElse: () => chats.first.chat.participants.first
    ) : '';
    return filteredChats.where((chat) => 
        chat.chat.isPinnedForUser(currentUser)).toList();
  }

  List<ChatListItemModel> get regularChats {
    final currentUser = chats.isNotEmpty ? chats.first.chat.participants.firstWhere(
      (id) => id != chats.first.chat.participants.first, 
      orElse: () => chats.first.chat.participants.first
    ) : '';
    return filteredChats.where((chat) => 
        !chat.chat.isPinnedForUser(currentUser)).toList();
  }
}

@riverpod
class ChatList extends _$ChatList {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  ChatDatabaseHelper get _dbHelper => ChatDatabaseHelper();
  
  @override
  FutureOr<ChatListState> build() async {
    // Use new user-based auth system
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const ChatListState(error: 'User not authenticated');
    }

    // Check connectivity status
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    // Start listening to chats stream for this user
    _subscribeToChats(currentUser.uid);
    
    // Start connectivity monitoring
    _monitorConnectivity();
    
    // Trigger initial sync if online
    if (isOnline) {
      _syncChats(currentUser.uid);
    }
    
    return ChatListState(
      isLoading: true,
      isOnline: isOnline,
    );
  }

  void _subscribeToChats(String userId) {
    // Listen to chats stream from repository (which uses local DB + server sync)
    _repository.getChatsStream(userId).listen(
      (chats) async {
        try {
          final chatItems = await _buildChatListItems(chats, userId);
          
          final currentState = state.valueOrNull ?? const ChatListState();
          state = AsyncValue.data(currentState.copyWith(
            chats: chatItems,
            isLoading: false,
          ));
        } catch (e) {
          debugPrint('Error in chat stream: $e');
          final currentState = state.valueOrNull ?? const ChatListState();
          state = AsyncValue.data(currentState.copyWith(
            error: e.toString(),
            isLoading: false,
          ));
        }
      },
      onError: (error) {
        debugPrint('Chat stream error: $error');
        final currentState = state.valueOrNull ?? const ChatListState();
        state = AsyncValue.data(currentState.copyWith(
          error: error.toString(),
          isLoading: false,
        ));
      },
    );
  }

  void _monitorConnectivity() {
    // Monitor connectivity changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) async {
      final connectivityResults = await Connectivity().checkConnectivity();
      final isOnline = !connectivityResults.contains(ConnectivityResult.none);
      final currentState = state.valueOrNull;
      
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(isOnline: isOnline));
        
        // If we just came online, trigger sync
        if (isOnline && !currentState.isOnline) {
          final userId = ref.read(currentUserIdProvider);
          if (userId != null) {
            _syncChats(userId);
          }
        }
      }
    });
  }

  Future<void> _syncChats(String userId) async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.isSyncing) return;
    
    try {
      state = AsyncValue.data(currentState.copyWith(isSyncing: true));
      
      // Trigger repository sync
      await _repository.syncChats(userId);
      
      final updatedState = state.valueOrNull ?? currentState;
      state = AsyncValue.data(updatedState.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('Sync error: $e');
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
        
        // Try to get from local cache first
        var contact = await _getCachedUserDetails(otherUserId);
        
        // If not cached or online, fetch from server
        if (contact == null) {
          contact = await authNotifier.getUserById(otherUserId);
          
          // Cache user details locally
          if (contact != null) {
            await _cacheUserDetails(chat.chatId, contact);
          }
        }
        
        if (contact != null) {
          chatItems.add(ChatListItemModel(
            chat: chat,
            contactName: contact.name,
            contactImage: contact.profileImage,
            contactPhone: contact.phoneNumber,
            isOnline: _isUserOnline(contact.lastSeen),
            lastSeen: _parseLastSeen(contact.lastSeen),
          ));
        } else {
          // Use cached participant info from database
          final participants = await _dbHelper.getChatParticipants(chat.chatId);
          final participant = participants.firstWhere(
            (p) => p['userId'] == otherUserId,
            orElse: () => <String, dynamic>{},
          );
          
          if (participant.isNotEmpty) {
            chatItems.add(ChatListItemModel(
              chat: chat,
              contactName: participant['userName'] ?? 'Unknown',
              contactImage: participant['userImage'] ?? '',
              contactPhone: participant['phoneNumber'] ?? '',
              isOnline: participant['isOnline'] == 1,
              lastSeen: participant['lastSeen'] != null 
                  ? DateTime.parse(participant['lastSeen'])
                  : null,
            ));
          }
        }
      } catch (e) {
        debugPrint('Error building chat item: $e');
      }
    }

    // Sort by last message time (most recent first)
    chatItems.sort((a, b) => b.chat.lastMessageTime.compareTo(a.chat.lastMessageTime));

    return chatItems;
  }

  Future<dynamic> _getCachedUserDetails(String userId) async {
    // This would ideally use a user cache, but for now return null
    // You could implement a separate user cache table in SQLite
    return null;
  }

  Future<void> _cacheUserDetails(String chatId, dynamic user) async {
    try {
      await _dbHelper.insertOrUpdateParticipant(
        chatId: chatId,
        userId: user.uid,
        userName: user.name,
        userImage: user.profileImage,
        phoneNumber: user.phoneNumber,
        isOnline: _isUserOnline(user.lastSeen),
        lastSeen: user.lastSeen,
      );
    } catch (e) {
      debugPrint('Error caching user details: $e');
    }
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

  // Search functionality
  void setSearchQuery(String query) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(searchQuery: query));
    }
  }

  void clearSearch() {
    setSearchQuery('');
  }

  // Chat actions - all now work offline-first
  Future<void> togglePinChat(String chatId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.toggleChatPin(chatId, userId);
    } catch (e) {
      debugPrint('Error toggling pin: $e');
      rethrow;
    }
  }

  Future<void> toggleArchiveChat(String chatId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.toggleChatArchive(chatId, userId);
    } catch (e) {
      debugPrint('Error toggling archive: $e');
      rethrow;
    }
  }

  Future<void> toggleMuteChat(String chatId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.toggleChatMute(chatId, userId);
    } catch (e) {
      debugPrint('Error toggling mute: $e');
      rethrow;
    }
  }

  Future<void> markChatAsRead(String chatId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.markChatAsRead(chatId, userId);
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
      rethrow;
    }
  }

  Future<void> deleteChat(String chatId, {bool deleteForEveryone = false}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.deleteChat(chatId, userId, deleteForEveryone: deleteForEveryone);
      
      // Remove from local state immediately for better UX
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedChats = currentState.chats
            .where((chatItem) => chatItem.chat.chatId != chatId)
            .toList();
        
        state = AsyncValue.data(currentState.copyWith(chats: updatedChats));
      }
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }

  Future<void> clearChatHistory(String chatId) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.clearChatHistory(chatId, userId);
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
      rethrow;
    }
  }

  // Create or get existing chat with another user
  Future<String?> createOrGetChat(String otherUserId) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return null;

    try {
      return await _repository.createOrGetChat(currentUserId, otherUserId);
    } catch (e) {
      debugPrint('Error creating/getting chat: $e');
      return null;
    }
  }

  // Create new chat with optional video reaction
  Future<String?> createChat(String otherUserId, {VideoReactionModel? videoReaction}) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return null;

    try {
      final chatId = await _repository.createOrGetChat(currentUserId, otherUserId);
      
      // If video reaction is provided, send it as the first message
      if (videoReaction != null) {
        await _repository.sendVideoReactionMessage(
          chatId: chatId,
          senderId: currentUserId,
          videoReaction: videoReaction,
        );
      }
      
      return chatId;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      return null;
    }
  }

  // Create chat with video reaction from video model
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
          
      return chatId;
    } catch (e) {
      debugPrint('Error creating chat with video reaction: $e');
      return null;
    }
  }

  // Create chat with moment reaction
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
          
      return chatId;
    } catch (e) {
      debugPrint('Error creating chat with moment reaction: $e');
      return null;
    }
  }

  // Manual sync trigger
  Future<void> syncChats() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    await _syncChats(userId);
  }

  // Sync all data (chats + messages)
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
    } catch (e) {
      debugPrint('Sync all data error: $e');
      final updatedState = state.valueOrNull ?? currentState;
      state = AsyncValue.data(updatedState.copyWith(
        isSyncing: false,
        error: 'Sync failed: $e',
      ));
    }
  }

  // Get chat statistics including offline/online status
  Map<String, dynamic> getChatStatistics() {
    final currentState = state.valueOrNull;
    if (currentState == null) {
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

    final totalChats = currentState.chats.length;
    final pinnedChats = getPinnedChats().length;
    final unreadChats = getUnreadChatsCount();
    final totalUnreadMessages = getTotalUnreadMessagesCount();
    final mutedChats = currentUserId != null 
        ? currentState.chats.where((chatItem) => 
            chatItem.chat.isMutedForUser(currentUserId!)).length
        : 0;
    final onlineContacts = currentState.chats.where((chatItem) => 
        chatItem.isOnline).length;

    return {
      'totalChats': totalChats,
      'pinnedChats': pinnedChats,
      'unreadChats': unreadChats,
      'totalUnreadMessages': totalUnreadMessages,
      'mutedChats': mutedChats,
      'onlineContacts': onlineContacts,
      'isOnline': currentState.isOnline,
      'isSyncing': currentState.isSyncing,
      'lastSyncTime': currentState.lastSyncTime,
    };
  }

  // Get local database statistics
  Future<Map<String, int>> getLocalStatistics() async {
    if (_repository is OfflineFirstChatRepository) {
      return await (_repository as OfflineFirstChatRepository).getLocalStatistics();
    }
    return {};
  }

  // Cleanup old messages
  Future<int> cleanupOldMessages({int daysOld = 365}) async {
    if (_repository is OfflineFirstChatRepository) {
      return await (_repository as OfflineFirstChatRepository).cleanupOldMessages(daysOld: daysOld);
    }
    return 0;
  }

  // Optimize local database
  Future<void> optimizeDatabase() async {
    if (_repository is OfflineFirstChatRepository) {
      await (_repository as OfflineFirstChatRepository).optimizeDatabase();
    }
  }

  // Export chat data for backup
  Future<Map<String, dynamic>> exportChatData() async {
    if (_repository is OfflineFirstChatRepository) {
      return await (_repository as OfflineFirstChatRepository).exportChatData();
    }
    return {};
  }

  // Import chat data from backup
  Future<void> importChatData(Map<String, dynamic> data) async {
    if (_repository is OfflineFirstChatRepository) {
      await (_repository as OfflineFirstChatRepository).importChatData(data);
      // Refresh the UI after import
      ref.invalidateSelf();
    }
  }

  // Clear local cache (useful for logout)
  Future<void> clearLocalCache() async {
    if (_repository is OfflineFirstChatRepository) {
      await (_repository as OfflineFirstChatRepository).clearLocalCache();
      // Refresh the UI after clearing
      ref.invalidateSelf();
    }
  }

  // Rest of the methods remain the same...
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
    if (currentState == null || currentUserId == null) return [];

    return currentState.chats.where((chatItem) => 
        chatItem.chat.isPinnedForUser(currentUserId!)).toList();
  }

  List<ChatListItemModel> getRegularChats() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentUserId == null) return [];

    return currentState.chats.where((chatItem) => 
        !chatItem.chat.isPinnedForUser(currentUserId!)).toList();
  }

  int getUnreadChatsCount() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentUserId == null) return 0;

    return currentState.chats.where((chatItem) => 
        chatItem.chat.getUnreadCount(currentUserId!) > 0).length;
  }

  int getTotalUnreadMessagesCount() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentUserId == null) return 0;

    return currentState.chats.fold<int>(0, (total, chatItem) => 
        total + chatItem.chat.getUnreadCount(currentUserId!));
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
}