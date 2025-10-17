// lib/features/video_reactions/providers/video_reactions_provider.dart
// EXTRACTED: Standalone video reactions provider
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_model.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_chat_model.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_message_model.dart';
import 'package:textgb/features/video_reactions/repositories/video_reactions_repository.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/users/models/user_model.dart';

part 'video_reactions_provider.g.dart';

// ========================================
// VIDEO REACTION CHATS LIST STATE & PROVIDER
// ========================================

class VideoReactionChatsState {
  final bool isLoading;
  final List<VideoReactionChatModel> chats;
  final String? error;
  final bool hasMore;
  final String searchQuery;

  const VideoReactionChatsState({
    this.isLoading = false,
    this.chats = const [],
    this.error,
    this.hasMore = true,
    this.searchQuery = '',
  });

  VideoReactionChatsState copyWith({
    bool? isLoading,
    List<VideoReactionChatModel>? chats,
    String? error,
    bool? hasMore,
    String? searchQuery,
  }) {
    return VideoReactionChatsState(
      isLoading: isLoading ?? this.isLoading,
      chats: chats ?? this.chats,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<VideoReactionChatModel> get filteredChats {
    if (searchQuery.isEmpty) return chats;
    
    return chats.where((chat) {
      final query = searchQuery.toLowerCase();
      return chat.originalReaction.userName.toLowerCase().contains(query) ||
             chat.lastMessage.toLowerCase().contains(query) ||
             chat.originalReaction.reaction?.toLowerCase().contains(query) == true;
    }).toList();
  }

  List<VideoReactionChatModel> getPinnedChats(String currentUserId) {
    return filteredChats.where((chat) => chat.isPinnedForUser(currentUserId)).toList();
  }

  List<VideoReactionChatModel> getRegularChats(String currentUserId) {
    return filteredChats.where((chat) => !chat.isPinnedForUser(currentUserId)).toList();
  }
}

@riverpod
class VideoReactionChatsList extends _$VideoReactionChatsList {
  VideoReactionsRepository get _repository => ref.read(videoReactionsRepositoryProvider);
  
  @override
  FutureOr<VideoReactionChatsState> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const VideoReactionChatsState(error: 'User not authenticated');
    }

    _subscribeToChats(currentUser.uid);
    return const VideoReactionChatsState(isLoading: true);
  }

  void _subscribeToChats(String userId) {
    _repository.getVideoReactionChatsStream(userId).listen(
      (chats) async {
        try {
          // Build chat items with user data
          final chatItems = await _buildChatListItems(chats, userId);
          
          state = AsyncValue.data(VideoReactionChatsState(
            chats: chatItems,
            isLoading: false,
          ));
        } catch (e) {
          debugPrint('Error in video reaction chats stream: $e');
          state = AsyncValue.data(VideoReactionChatsState(
            error: e.toString(),
            isLoading: false,
          ));
        }
      },
      onError: (error) {
        debugPrint('Video reaction chats stream error: $error');
        state = AsyncValue.data(VideoReactionChatsState(
          error: error.toString(),
          isLoading: false,
        ));
      },
    );
  }

  Future<List<VideoReactionChatModel>> _buildChatListItems(
      List<VideoReactionChatModel> chats, String currentUserId) async {
    // Sort by last message time (most recent first)
    final sortedChats = List<VideoReactionChatModel>.from(chats);
    sortedChats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return sortedChats;
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

  Future<void> deleteChat(String chatId, {bool deleteForEveryone = false}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      await _repository.deleteChat(chatId, userId, deleteForEveryone: deleteForEveryone);
      
      // Remove from local state immediately for better UX
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedChats = currentState.chats
            .where((chat) => chat.chatId != chatId)
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

  // Create video reaction chat
  Future<String?> createVideoReactionChat({
    required String videoOwnerId,
    required VideoReactionModel videoReaction,
  }) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return null;

    try {
      return await _repository.createVideoReactionChat(
        currentUserId: currentUserId,
        videoOwnerId: videoOwnerId,
        videoReaction: videoReaction,
      );
    } catch (e) {
      debugPrint('Error creating video reaction chat: $e');
      return null;
    }
  }

  // Helper method to create video reaction from video and user data
  Future<String?> createVideoReactionFromVideo({
    required VideoModel video,
    required String reaction,
  }) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return null;

    // Get video owner data
    final authNotifier = ref.read(authenticationProvider.notifier);
    final videoOwner = await authNotifier.getUserById(video.userId);
    if (videoOwner == null) return null;

    // Create video reaction model
    final videoReaction = VideoReactionModel(
      videoId: video.id,
      videoUrl: video.isMultipleImages && video.imageUrls.isNotEmpty 
          ? video.imageUrls.first 
          : video.videoUrl,
      thumbnailUrl: video.isMultipleImages && video.imageUrls.isNotEmpty 
          ? video.imageUrls.first 
          : video.thumbnailUrl,
      userName: videoOwner.name,
      userImage: videoOwner.profileImage,
      reaction: reaction,
      timestamp: DateTime.now(),
    );

    return await createVideoReactionChat(
      videoOwnerId: video.userId,
      videoReaction: videoReaction,
    );
  }

  // Refresh chat list
  void refreshChatList() {
    ref.invalidateSelf();
  }

  // Get helper methods
  String? get currentUserId => ref.read(currentUserIdProvider);
  bool get isAuthenticated => currentUserId != null;

  List<VideoReactionChatModel> getFilteredChats([String? query]) {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    if (query != null && query.isNotEmpty) {
      return currentState.chats.where((chat) {
        final searchQuery = query.toLowerCase();
        return chat.originalReaction.userName.toLowerCase().contains(searchQuery) ||
               chat.lastMessage.toLowerCase().contains(searchQuery) ||
               chat.originalReaction.reaction?.toLowerCase().contains(searchQuery) == true;
      }).toList();
    }

    return currentState.filteredChats;
  }

  List<VideoReactionChatModel> getPinnedChats() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentUserId == null) return [];

    return currentState.getPinnedChats(currentUserId!);
  }

  List<VideoReactionChatModel> getRegularChats() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentUserId == null) return [];

    return currentState.getRegularChats(currentUserId!);
  }

  int getUnreadChatsCount() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentUserId == null) return 0;

    return currentState.chats.where((chat) => 
        chat.getUnreadCount(currentUserId!) > 0).length;
  }

  int getTotalUnreadMessagesCount() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentUserId == null) return 0;

    return currentState.chats.fold<int>(0, (total, chat) => 
        total + chat.getUnreadCount(currentUserId!));
  }
}

// ========================================
// VIDEO REACTION MESSAGES STATE & PROVIDER
// ========================================

class VideoReactionMessagesState {
  final bool isLoading;
  final List<VideoReactionMessageModel> messages;
  final String? error;
  final bool hasMore;
  final String? replyToMessageId;
  final VideoReactionMessageModel? replyToMessage;
  final List<VideoReactionMessageModel> pinnedMessages;
  final bool isTyping;
  final Map<String, String> participantNames;
  final Map<String, String> participantImages;
  final VideoReactionModel? originalVideoReaction; // The video reaction that started this chat

  const VideoReactionMessagesState({
    this.isLoading = false,
    this.messages = const [],
    this.error,
    this.hasMore = true,
    this.replyToMessageId,
    this.replyToMessage,
    this.pinnedMessages = const [],
    this.isTyping = false,
    this.participantNames = const {},
    this.participantImages = const {},
    this.originalVideoReaction,
  });

  VideoReactionMessagesState copyWith({
    bool? isLoading,
    List<VideoReactionMessageModel>? messages,
    String? error,
    bool? hasMore,
    String? replyToMessageId,
    VideoReactionMessageModel? replyToMessage,
    List<VideoReactionMessageModel>? pinnedMessages,
    bool? isTyping,
    Map<String, String>? participantNames,
    Map<String, String>? participantImages,
    VideoReactionModel? originalVideoReaction,
    bool clearReply = false,
    bool clearError = false,
  }) {
    return VideoReactionMessagesState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      replyToMessageId: clearReply ? null : (replyToMessageId ?? this.replyToMessageId),
      replyToMessage: clearReply ? null : (replyToMessage ?? this.replyToMessage),
      pinnedMessages: pinnedMessages ?? this.pinnedMessages,
      isTyping: isTyping ?? this.isTyping,
      participantNames: participantNames ?? this.participantNames,
      participantImages: participantImages ?? this.participantImages,
      originalVideoReaction: originalVideoReaction ?? this.originalVideoReaction,
    );
  }

  String getParticipantName(String userId) {
    return participantNames[userId] ?? 'Unknown User';
  }

  String getParticipantImage(String userId) {
    return participantImages[userId] ?? '';
  }
}

@riverpod
class VideoReactionMessages extends _$VideoReactionMessages {
  VideoReactionsRepository get _repository => ref.read(videoReactionsRepositoryProvider);
  static const String _messageIdPrefix = 'vr_msg_';

  @override
  FutureOr<VideoReactionMessagesState> build(String chatId) async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const VideoReactionMessagesState(error: 'User not authenticated');
    }

    // Load chat data to get original video reaction
    await _loadChatData(chatId);
    
    // Load participant details
    await _loadParticipantDetails(chatId);

    // Start listening to messages stream
    _subscribeToMessages(chatId);
    
    // Load pinned messages
    _loadPinnedMessages(chatId);
    
    return const VideoReactionMessagesState(isLoading: true);
  }

  Future<void> _loadChatData(String chatId) async {
    try {
      final chat = await _repository.getVideoReactionChatById(chatId);
      if (chat != null) {
        final currentState = state.valueOrNull ?? const VideoReactionMessagesState();
        state = AsyncValue.data(currentState.copyWith(
          originalVideoReaction: chat.originalReaction,
        ));
      }
    } catch (e) {
      debugPrint('Error loading chat data: $e');
    }
  }

  Future<void> _loadParticipantDetails(String chatId) async {
    try {
      final chat = await _repository.getVideoReactionChatById(chatId);
      if (chat == null) return;

      final authNotifier = ref.read(authenticationProvider.notifier);
      final Map<String, String> participantNames = {};
      final Map<String, String> participantImages = {};

      for (final userId in chat.participants) {
        try {
          final user = await authNotifier.getUserById(userId);
          if (user != null) {
            participantNames[userId] = user.name;
            participantImages[userId] = user.profileImage;
          }
        } catch (e) {
          debugPrint('Error loading participant details for $userId: $e');
          participantNames[userId] = 'Unknown User';
          participantImages[userId] = '';
        }
      }

      final currentState = state.valueOrNull ?? const VideoReactionMessagesState();
      state = AsyncValue.data(currentState.copyWith(
        participantNames: participantNames,
        participantImages: participantImages,
      ));
    } catch (e) {
      debugPrint('Error loading participant details: $e');
    }
  }

  void _subscribeToMessages(String chatId) {
    _repository.getMessagesStream(chatId).listen(
      (messages) {
        final currentState = state.valueOrNull ?? const VideoReactionMessagesState();
        state = AsyncValue.data(currentState.copyWith(
          messages: messages,
          isLoading: false,
          clearError: true,
        ));
      },
      onError: (error) {
        debugPrint('Video reaction messages stream error: $error');
        final currentState = state.valueOrNull ?? const VideoReactionMessagesState();
        state = AsyncValue.data(currentState.copyWith(
          error: error.toString(),
          isLoading: false,
        ));
      },
    );
  }

  Future<void> _loadPinnedMessages(String chatId) async {
    try {
      final pinnedMessages = await _repository.getPinnedMessages(chatId);
      
      final currentState = state.valueOrNull ?? const VideoReactionMessagesState();
      state = AsyncValue.data(currentState.copyWith(
        pinnedMessages: pinnedMessages,
      ));
    } catch (e) {
      debugPrint('Error loading pinned messages: $e');
    }
  }

  // Send text message
  Future<void> sendTextMessage(String chatId, String content) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      debugPrint('Cannot send message: user not authenticated');
      return;
    }

    if (content.trim().isEmpty) {
      debugPrint('Cannot send empty message');
      return;
    }

    try {
      final currentState = state.valueOrNull ?? const VideoReactionMessagesState();
      
      // Create optimistic message
      final tempMessageId = '$_messageIdPrefix${DateTime.now().millisecondsSinceEpoch}';
      final message = VideoReactionMessageModel(
        messageId: tempMessageId,
        chatId: chatId,
        senderId: currentUser.uid,
        content: content.trim(),
        type: MessageEnum.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        replyToMessageId: currentState.replyToMessageId,
        replyToContent: currentState.replyToMessage?.getDisplayContent(),
        replyToSender: currentState.replyToMessage?.senderId,
      );

      // Optimistically add message to local state
      final updatedMessages = [message, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearReply: true,
        clearError: true,
      ));

      // Send to server
      final messageId = await _repository.sendTextMessage(
        chatId: chatId,
        senderId: currentUser.uid,
        content: content.trim(),
        replyToMessageId: currentState.replyToMessageId,
      );
      
      // Update message status to sent
      await _repository.updateMessageStatus(chatId, messageId, MessageStatus.sent);
      
    } catch (e) {
      debugPrint('Error sending message: $e');
      
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.status == MessageStatus.sending && msg.senderId == currentUser.uid) {
            return msg.copyWith(status: MessageStatus.failed);
          }
          return msg;
        }).toList();
        
        state = AsyncValue.data(currentState.copyWith(
          messages: updatedMessages,
          error: 'Failed to send message: $e',
        ));
      }
    }
  }

  // Send image message
  Future<void> sendImageMessage(String chatId, File imageFile) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      debugPrint('Cannot send image: user not authenticated');
      return;
    }

    try {
      final currentState = state.valueOrNull ?? const VideoReactionMessagesState();
      
      // Create optimistic message
      final tempMessageId = '$_messageIdPrefix${DateTime.now().millisecondsSinceEpoch}';
      final message = VideoReactionMessageModel(
        messageId: tempMessageId,
        chatId: chatId,
        senderId: currentUser.uid,
        content: 'Image',
        type: MessageEnum.image,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaUrl: imageFile.path, // Temporary local path
        replyToMessageId: currentState.replyToMessageId,
        replyToContent: currentState.replyToMessage?.getDisplayContent(),
        replyToSender: currentState.replyToMessage?.senderId,
      );

      // Optimistically add message to local state
      final updatedMessages = [message, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearReply: true,
        clearError: true,
      ));

      // Send to server
      final messageId = await _repository.sendImageMessage(
        chatId: chatId,
        senderId: currentUser.uid,
        imageFile: imageFile,
        replyToMessageId: currentState.replyToMessageId,
      );
      
      // Update message status to sent
      await _repository.updateMessageStatus(chatId, messageId, MessageStatus.sent);
      
    } catch (e) {
      debugPrint('Error sending image: $e');
      
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.status == MessageStatus.sending && msg.senderId == currentUser.uid) {
            return msg.copyWith(status: MessageStatus.failed);
          }
          return msg;
        }).toList();
        
        state = AsyncValue.data(currentState.copyWith(
          messages: updatedMessages,
          error: 'Failed to send image: $e',
        ));
      }
    }
  }

  // Send file message
  Future<void> sendFileMessage(String chatId, File file, String fileName) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      debugPrint('Cannot send file: user not authenticated');
      return;
    }

    try {
      final currentState = state.valueOrNull ?? const VideoReactionMessagesState();
      
      // Create optimistic message
      final tempMessageId = '$_messageIdPrefix${DateTime.now().millisecondsSinceEpoch}';
      final message = VideoReactionMessageModel(
        messageId: tempMessageId,
        chatId: chatId,
        senderId: currentUser.uid,
        content: fileName,
        type: MessageEnum.file,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaUrl: file.path, // Temporary local path
        fileName: fileName,
        replyToMessageId: currentState.replyToMessageId,
        replyToContent: currentState.replyToMessage?.getDisplayContent(),
        replyToSender: currentState.replyToMessage?.senderId,
      );

      // Optimistically add message to local state
      final updatedMessages = [message, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearReply: true,
        clearError: true,
      ));

      // Send to server
      final messageId = await _repository.sendFileMessage(
        chatId: chatId,
        senderId: currentUser.uid,
        file: file,
        fileName: fileName,
        replyToMessageId: currentState.replyToMessageId,
      );
      
      // Update message status to sent
      await _repository.updateMessageStatus(chatId, messageId, MessageStatus.sent);
      
    } catch (e) {
      debugPrint('Error sending file: $e');
      
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.status == MessageStatus.sending && msg.senderId == currentUser.uid) {
            return msg.copyWith(status: MessageStatus.failed);
          }
          return msg;
        }).toList();
        
        state = AsyncValue.data(currentState.copyWith(
          messages: updatedMessages,
          error: 'Failed to send file: $e',
        ));
      }
    }
  }

  // Reply to message
  void setReplyToMessage(VideoReactionMessageModel message) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(
        replyToMessageId: message.messageId,
        replyToMessage: message,
        clearError: true,
      ));
    }
  }

  void cancelReply() {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(
        clearReply: true,
        clearError: true,
      ));
    }
  }

  // Edit message
  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    if (newContent.trim().isEmpty) {
      debugPrint('Cannot edit message with empty content');
      return;
    }

    try {
      await _repository.editMessage(chatId, messageId, newContent.trim());
    } catch (e) {
      debugPrint('Error editing message: $e');
      
      final currentState = state.valueOrNull ?? const VideoReactionMessagesState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to edit message: $e',
      ));
    }
  }

  // Delete message
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    try {
      await _repository.deleteMessage(chatId, messageId, deleteForEveryone);
    } catch (e) {
      debugPrint('Error deleting message: $e');
      
      final currentState = state.valueOrNull ?? const VideoReactionMessagesState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to delete message: $e',
      ));
    }
  }

  // Pin/Unpin message
  Future<void> togglePinMessage(String chatId, String messageId, bool isPinned) async {
    try {
      if (isPinned) {
        await _repository.unpinMessage(chatId, messageId);
      } else {
        final currentState = state.valueOrNull;
        if (currentState != null && currentState.pinnedMessages.length >= 10) {
          state = AsyncValue.data(currentState.copyWith(
            error: 'Maximum 10 messages can be pinned',
          ));
          return;
        }
        
        await _repository.pinMessage(chatId, messageId);
      }
      
      // Reload pinned messages
      await _loadPinnedMessages(chatId);
      
    } catch (e) {
      debugPrint('Error toggling pin message: $e');
      
      final currentState = state.valueOrNull ?? const VideoReactionMessagesState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to ${isPinned ? 'unpin' : 'pin'} message: $e',
      ));
    }
  }

  // Mark messages as delivered
  Future<void> markMessagesAsDelivered(String chatId, List<String> messageIds) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || messageIds.isEmpty) return;

    try {
      for (final messageId in messageIds) {
        await _repository.markMessageAsDelivered(chatId, messageId, currentUser.uid);
      }
    } catch (e) {
      debugPrint('Error marking messages as delivered: $e');
    }
  }

  // Search messages
  Future<List<VideoReactionMessageModel>> searchMessages(String chatId, String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      return await _repository.searchMessages(chatId, query.trim());
    } catch (e) {
      debugPrint('Error searching messages: $e');
      
      final currentState = state.valueOrNull ?? const VideoReactionMessagesState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to search messages: $e',
      ));
      
      return [];
    }
  }

  // Clear error
  void clearError() {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(clearError: true));
    }
  }

  // Retry failed message
  Future<void> retryFailedMessage(String chatId, String messageId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final messageIndex = currentState.messages.indexWhere((msg) => msg.messageId == messageId);
    if (messageIndex == -1) return;

    final failedMessage = currentState.messages[messageIndex];
    if (failedMessage.status != MessageStatus.failed) return;

    try {
      // Update status to sending
      final updatedMessages = List<VideoReactionMessageModel>.from(currentState.messages);
      updatedMessages[messageIndex] = failedMessage.copyWith(status: MessageStatus.sending);
      
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearError: true,
      ));

      // Retry sending based on message type
      String newMessageId;
      if (failedMessage.type == MessageEnum.text) {
        newMessageId = await _repository.sendTextMessage(
          chatId: chatId,
          senderId: currentUser.uid,
          content: failedMessage.content,
          replyToMessageId: failedMessage.replyToMessageId,
        );
      } else if (failedMessage.type == MessageEnum.image && failedMessage.mediaUrl != null) {
        newMessageId = await _repository.sendImageMessage(
          chatId: chatId,
          senderId: currentUser.uid,
          imageFile: File(failedMessage.mediaUrl!),
          replyToMessageId: failedMessage.replyToMessageId,
        );
      } else if (failedMessage.type == MessageEnum.file && failedMessage.mediaUrl != null) {
        newMessageId = await _repository.sendFileMessage(
          chatId: chatId,
          senderId: currentUser.uid,
          file: File(failedMessage.mediaUrl!),
          fileName: failedMessage.fileName ?? failedMessage.content,
          replyToMessageId: failedMessage.replyToMessageId,
        );
      } else {
        throw Exception('Unsupported message type for retry');
      }
      
      await _repository.updateMessageStatus(chatId, newMessageId, MessageStatus.sent);
      
    } catch (e) {
      debugPrint('Error retrying message: $e');
      
      final latestState = state.valueOrNull;
      if (latestState != null) {
        final updatedMessages = List<VideoReactionMessageModel>.from(latestState.messages);
        if (messageIndex < updatedMessages.length) {
          updatedMessages[messageIndex] = failedMessage.copyWith(status: MessageStatus.failed);
        }
        
        state = AsyncValue.data(latestState.copyWith(
          messages: updatedMessages,
          error: 'Failed to retry message: $e',
        ));
      }
    }
  }

  // Get helper methods
  String? get currentUserId => ref.read(currentUserIdProvider);
  bool get isAuthenticated => currentUserId != null;

  String getParticipantName(String userId) {
    final currentState = state.valueOrNull;
    return currentState?.getParticipantName(userId) ?? 'Unknown User';
  }

  String getParticipantImage(String userId) {
    final currentState = state.valueOrNull;
    return currentState?.getParticipantImage(userId) ?? '';
  }

  List<VideoReactionMessageModel> getMessagesByType(MessageEnum type) {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => msg.type == type).toList();
  }

  List<VideoReactionMessageModel> getFailedMessages() {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => msg.status == MessageStatus.failed).toList();
  }

  VideoReactionModel? get originalVideoReaction {
    final currentState = state.valueOrNull;
    return currentState?.originalVideoReaction;
  }

  VideoReactionMessageModel? get latestMessage {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.messages.isEmpty) return null;

    return currentState.messages.first;
  }

  bool get hasFailedMessages {
    final failedMessages = getFailedMessages();
    return failedMessages.isNotEmpty;
  }

  int getUnreadMessagesCount() {
    final currentState = state.valueOrNull;
    if (currentState == null) return 0;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return 0;

    return currentState.messages.where((msg) => 
        msg.senderId != currentUserId && !msg.isReadBy(currentUserId)).length;
  }

  void refreshParticipants(String chatId) {
    _loadParticipantDetails(chatId);
  }
}