// lib/features/chat/providers/chat_provider.dart
// Updated chat provider using new authentication system and HTTP services
// UPDATED: Removed all channel references, fully users-based system
// UPDATED: Added SQLite local storage for offline-first chat list
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/chat_list_item_model.dart';
import 'package:textgb/features/chat/models/video_reaction_model.dart';
import 'package:textgb/features/chat/models/moment_reaction_model.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/chat/providers/chat_database_provider.dart';
import 'package:textgb/features/chat/services/chat_database_service.dart';

part 'chat_provider.g.dart';

// Chat List State
class ChatListState {
  final bool isLoading;
  final List<ChatListItemModel> chats;
  final String? error;
  final bool hasMore;
  final String searchQuery;
  final bool isLoadedFromLocal; // Track if loaded from SQLite

  const ChatListState({
    this.isLoading = false,
    this.chats = const [],
    this.error,
    this.hasMore = true,
    this.searchQuery = '',
    this.isLoadedFromLocal = false,
  });

  ChatListState copyWith({
    bool? isLoading,
    List<ChatListItemModel>? chats,
    String? error,
    bool? hasMore,
    String? searchQuery,
    bool? isLoadedFromLocal,
  }) {
    return ChatListState(
      isLoading: isLoading ?? this.isLoading,
      chats: chats ?? this.chats,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadedFromLocal: isLoadedFromLocal ?? this.isLoadedFromLocal,
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
  ChatDatabaseService get _databaseService => ref.read(chatDatabaseProvider);

  @override
  FutureOr<ChatListState> build() async {
    // Use new user-based auth system
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const ChatListState(error: 'User not authenticated');
    }

    // Phase 1: Load from SQLite immediately (instant, offline-first)
    await _loadChatsFromLocal(currentUser.uid);

    // Phase 2: Start listening to chats stream for this user (background sync)
    _subscribeToChats(currentUser.uid);

    return const ChatListState(isLoading: true);
  }

  /// Load chats from local SQLite database (instant, offline-first)
  Future<void> _loadChatsFromLocal(String userId) async {
    try {
      final localChats = await _databaseService.getChats(userId);

      if (localChats.isNotEmpty) {
        debugPrint('ChatProvider: Loaded ${localChats.length} chats from SQLite');

        // Build chat list items from local chats
        final chatItems = await _buildChatListItems(localChats, userId);

        state = AsyncValue.data(ChatListState(
          chats: chatItems,
          isLoading: false,
          isLoadedFromLocal: true,
        ));
      }
    } catch (e) {
      debugPrint('ChatProvider: Error loading from SQLite: $e');
      // Continue to load from server even if local fails
    }
  }

  /// Save chats to local SQLite database
  Future<void> _saveChatsToLocal(List<ChatModel> chats) async {
    try {
      if (chats.isEmpty) return;
      await _databaseService.upsertChats(chats);
      debugPrint('ChatProvider: Saved ${chats.length} chats to SQLite');
    } catch (e) {
      debugPrint('ChatProvider: Error saving to SQLite: $e');
    }
  }

  void _subscribeToChats(String userId) {
    // Listen to chats stream and update state
    _repository.getChatsStream(userId).listen(
      (chats) async {
        try {
          // Save chats to SQLite for offline access
          await _saveChatsToLocal(chats);

          final chatItems = await _buildChatListItems(chats, userId);

          state = AsyncValue.data(ChatListState(
            chats: chatItems,
            isLoading: false,
          ));
        } catch (e) {
          debugPrint('Error in chat stream: $e');
          // Keep local chats visible even on error
          final currentState = state.valueOrNull;
          state = AsyncValue.data(ChatListState(
            chats: currentState?.chats ?? [],
            error: e.toString(),
            isLoading: false,
          ));
        }
      },
      onError: (error) {
        debugPrint('Chat stream error: $error');
        // Keep local chats visible even on network error
        final currentState = state.valueOrNull;
        state = AsyncValue.data(ChatListState(
          chats: currentState?.chats ?? [],
          error: error.toString(),
          isLoading: false,
        ));
      },
    );
  }

  Future<List<ChatListItemModel>> _buildChatListItems(
      List<ChatModel> chats, String currentUserId) async {
    // Use new user-based auth provider to get user details
    final authNotifier = ref.read(authenticationProvider.notifier);
    final chatItems = <ChatListItemModel>[];

    for (final chat in chats) {
      try {
        final otherUserId = chat.getOtherParticipant(currentUserId);

        // Get user details from our user-based system
        final contact = await authNotifier.getUserById(otherUserId);

        if (contact != null) {
          // User found - use full details
          chatItems.add(ChatListItemModel(
            chat: chat,
            contactName: contact.name.isNotEmpty ? contact.name : contact.phoneNumber,
            contactImage: contact.profileImage, // Use profileImage from UserModel
            contactPhone: contact.phoneNumber,
            isOnline: _isUserOnline(contact.lastSeen),
            lastSeen: _parseLastSeen(contact.lastSeen),
          ));
        } else {
          // User not found - create fallback chat item
          debugPrint('Could not find user details for ID: $otherUserId - using fallback');
          chatItems.add(ChatListItemModel(
            chat: chat,
            contactName: otherUserId.length > 10 ? otherUserId.substring(0, 10) : otherUserId, // Truncate long IDs
            contactImage: '', // No image available
            contactPhone: otherUserId, // Use user ID as phone fallback
            isOnline: false,
            lastSeen: null,
          ));
        }
      } catch (e) {
        // Even on error, create a fallback chat item so user can see the chat
        debugPrint('Error building chat item: $e');
        final otherUserId = chat.getOtherParticipant(currentUserId);
        chatItems.add(ChatListItemModel(
          chat: chat,
          contactName: 'User ${otherUserId.substring(0, 8)}...', // Show partial ID
          contactImage: '',
          contactPhone: otherUserId,
          isOnline: false,
          lastSeen: null,
        ));
      }
    }

    // Sort by last message time (most recent first)
    chatItems.sort((a, b) => b.chat.lastMessageTime.compareTo(a.chat.lastMessageTime));

    return chatItems;
  }

  // Helper method to determine if user is online (within last 5 minutes)
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

  // Helper method to parse last seen string to DateTime
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

  // Chat actions
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

  // Delete chat functionality
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
        await _sendVideoReactionMessage(chatId, currentUserId, videoReaction);
      }
      
      return chatId;
    } catch (e) {
      debugPrint('Error creating chat: $e');
      return null;
    }
  }

  // Send video reaction message
  Future<void> _sendVideoReactionMessage(String chatId, String senderId, VideoReactionModel videoReaction) async {
    try {
      await _repository.sendVideoReactionMessage(
        chatId: chatId,
        senderId: senderId,
        videoReaction: videoReaction,
      );
    } catch (e) {
      debugPrint('Error sending video reaction message: $e');
      // Don't rethrow - chat creation should still succeed
    }
  }

  // Create chat with video reaction from video model
  Future<String?> createChatWithVideoReaction({
    required String otherUserId,
    required String videoId,
    required String videoUrl,
    required String thumbnailUrl,
    required String userName, // Changed from channelName
    required String userImage, // Changed from channelImage
    required String reaction,
  }) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return null;

    try {
      // Create or get existing chat
      final chatId = await _repository.createOrGetChat(currentUserId, otherUserId);
      
      // Create video reaction data
      final videoReaction = VideoReactionModel(
        videoId: videoId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        userName: userName, // Changed from channelName
        userImage: userImage, // Changed from channelImage
        reaction: reaction,
        timestamp: DateTime.now(),
      );

      // Send video reaction message
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
      // Create or get existing chat
      final chatId = await _repository.createOrGetChat(currentUserId, otherUserId);
      
      // Send moment reaction message
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

  // Check if chat has messages before creating/showing it
  Future<bool> chatHasMessages(String chatId) async {
    try {
      return await _repository.chatHasMessages(chatId);
    } catch (e) {
      debugPrint('Error checking chat messages: $e');
      return false;
    }
  }

  // Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      return await _repository.getChatById(chatId);
    } catch (e) {
      debugPrint('Error getting chat by ID: $e');
      return null;
    }
  }

  // Refresh chat list manually
  void refreshChatList() {
    ref.invalidateSelf();
  }

  // Set chat wallpaper
  Future<void> setChatWallpaper(String chatId, String? wallpaperUrl) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.setChatWallpaper(chatId, userId, wallpaperUrl);
    } catch (e) {
      debugPrint('Error setting chat wallpaper: $e');
      rethrow;
    }
  }

  // Set chat font size
  Future<void> setChatFontSize(String chatId, double fontSize) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.setChatFontSize(chatId, userId, fontSize);
    } catch (e) {
      debugPrint('Error setting chat font size: $e');
      rethrow;
    }
  }

  // Update chat last message
  Future<void> updateChatLastMessage(ChatModel chat) async {
    try {
      await _repository.updateChatLastMessage(chat);
    } catch (e) {
      debugPrint('Error updating chat last message: $e');
      rethrow;
    }
  }

  // Get chats stream for real-time updates
  Stream<List<ChatModel>> getChatsStream() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      return Stream.error('User not authenticated');
    }
    return _repository.getChatsStream(userId);
  }

  // Helper method to get current user ID from new auth system
  String? get currentUserId => ref.read(currentUserIdProvider);

  // Helper method to check if user is authenticated
  bool get isAuthenticated => currentUserId != null;

  // Get filtered chats based on search query
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

  // Get pinned chats
  List<ChatListItemModel> getPinnedChats() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentUserId == null) return [];

    return currentState.chats.where((chatItem) => 
        chatItem.chat.isPinnedForUser(currentUserId!)).toList();
  }

  // Get regular (non-pinned) chats
  List<ChatListItemModel> getRegularChats() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentUserId == null) return [];

    return currentState.chats.where((chatItem) => 
        !chatItem.chat.isPinnedForUser(currentUserId!)).toList();
  }

  // Get unread chats count
  int getUnreadChatsCount() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentUserId == null) return 0;

    return currentState.chats.where((chatItem) => 
        chatItem.chat.getUnreadCount(currentUserId!) > 0).length;
  }

  // Get total unread messages count
  int getTotalUnreadMessagesCount() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentUserId == null) return 0;

    return currentState.chats.fold<int>(0, (total, chatItem) => 
        total + chatItem.chat.getUnreadCount(currentUserId!));
  }

  // Mark all chats as read
  Future<void> markAllChatsAsRead() async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentUserId == null) return;

    try {
      final futures = currentState.chats
          .where((chatItem) => chatItem.chat.getUnreadCount(currentUserId!) > 0)
          .map((chatItem) => _repository.markChatAsRead(chatItem.chat.chatId, currentUserId!));

      await Future.wait(futures);
    } catch (e) {
      debugPrint('Error marking all chats as read: $e');
      rethrow;
    }
  }

  // Archive multiple chats
  Future<void> archiveMultipleChats(List<String> chatIds) async {
    if (currentUserId == null) return;

    try {
      final futures = chatIds.map((chatId) => 
          _repository.toggleChatArchive(chatId, currentUserId!));

      await Future.wait(futures);

      // Remove from local state
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedChats = currentState.chats
            .where((chatItem) => !chatIds.contains(chatItem.chat.chatId))
            .toList();
        
        state = AsyncValue.data(currentState.copyWith(chats: updatedChats));
      }
    } catch (e) {
      debugPrint('Error archiving multiple chats: $e');
      rethrow;
    }
  }

  // Delete multiple chats
  Future<void> deleteMultipleChats(List<String> chatIds, {bool deleteForEveryone = false}) async {
    if (currentUserId == null) return;

    try {
      final futures = chatIds.map((chatId) => 
          _repository.deleteChat(chatId, currentUserId!, deleteForEveryone: deleteForEveryone));

      await Future.wait(futures);

      // Remove from local state
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedChats = currentState.chats
            .where((chatItem) => !chatIds.contains(chatItem.chat.chatId))
            .toList();
        
        state = AsyncValue.data(currentState.copyWith(chats: updatedChats));
      }
    } catch (e) {
      debugPrint('Error deleting multiple chats: $e');
      rethrow;
    }
  }

  // Get chat statistics
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
    };
  }

  // Find user by phone number or name for chat creation
  Future<String?> findUserForChat(String searchQuery) async {
    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      final users = await authNotifier.searchUsers(searchQuery);
      
      if (users.isNotEmpty) {
        return users.first.uid;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error finding user for chat: $e');
      return null;
    }
  }

  // Get user details for chat
  Future<Map<String, dynamic>?> getUserDetailsForChat(String userId) async {
    try {
      final authNotifier = ref.read(authenticationProvider.notifier);
      final user = await authNotifier.getUserById(userId);
      
      if (user != null) {
        return {
          'uid': user.uid,
          'name': user.name,
          'profileImage': user.profileImage,
          'phoneNumber': user.phoneNumber,
          'isOnline': _isUserOnline(user.lastSeen),
          'lastSeen': user.lastSeen,
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user details for chat: $e');
      return null;
    }
  }

  // Bulk operations for chat management
  Future<void> performBulkChatAction({
    required List<String> chatIds,
    required String action, // 'archive', 'delete', 'pin', 'mute'
    bool deleteForEveryone = false,
  }) async {
    if (currentUserId == null || chatIds.isEmpty) return;

    try {
      List<Future<void>> futures = [];

      for (final chatId in chatIds) {
        switch (action) {
          case 'archive':
            futures.add(_repository.toggleChatArchive(chatId, currentUserId!));
            break;
          case 'delete':
            futures.add(_repository.deleteChat(chatId, currentUserId!, deleteForEveryone: deleteForEveryone));
            break;
          case 'pin':
            futures.add(_repository.toggleChatPin(chatId, currentUserId!));
            break;
          case 'mute':
            futures.add(_repository.toggleChatMute(chatId, currentUserId!));
            break;
          default:
            debugPrint('Unknown bulk action: $action');
            continue;
        }
      }

      await Future.wait(futures);

      // Update local state based on action
      final currentState = state.valueOrNull;
      if (currentState != null && (action == 'delete' || action == 'archive')) {
        final updatedChats = currentState.chats
            .where((chatItem) => !chatIds.contains(chatItem.chat.chatId))
            .toList();
        
        state = AsyncValue.data(currentState.copyWith(chats: updatedChats));
      }
    } catch (e) {
      debugPrint('Error performing bulk chat action: $e');
      rethrow;
    }
  }
}