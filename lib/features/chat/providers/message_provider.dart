// lib/features/chat/providers/message_provider.dart
// FIXED: Mark as read, optimistic updates, and proper state management
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/chat/database/chat_database_helper.dart';
import 'dart:async';

part 'message_provider.g.dart';

// ========================================
// MESSAGE STATE
// ========================================

class MessageState {
  final bool isLoading;
  final List<MessageModel> messages;
  final String? error;
  final bool hasMore;
  final String? replyToMessageId;
  final MessageModel? replyToMessage;
  final List<MessageModel> pinnedMessages;
  final bool isTyping;
  final Map<String, String> participantNames;
  final Map<String, String> participantImages;
  final bool isOnline;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final int pendingMessagesCount;
  final int failedMessagesCount;

  const MessageState({
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
    this.isOnline = true,
    this.isSyncing = false,
    this.lastSyncTime,
    this.pendingMessagesCount = 0,
    this.failedMessagesCount = 0,
  });

  MessageState copyWith({
    bool? isLoading,
    List<MessageModel>? messages,
    String? error,
    bool? hasMore,
    String? replyToMessageId,
    MessageModel? replyToMessage,
    List<MessageModel>? pinnedMessages,
    bool? isTyping,
    Map<String, String>? participantNames,
    Map<String, String>? participantImages,
    bool? isOnline,
    bool? isSyncing,
    DateTime? lastSyncTime,
    int? pendingMessagesCount,
    int? failedMessagesCount,
    bool clearReply = false,
    bool clearError = false,
  }) {
    return MessageState(
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
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingMessagesCount: pendingMessagesCount ?? this.pendingMessagesCount,
      failedMessagesCount: failedMessagesCount ?? this.failedMessagesCount,
    );
  }

  String getParticipantName(String userId) {
    return participantNames[userId] ?? 'Unknown User';
  }

  String getParticipantImage(String userId) {
    return participantImages[userId] ?? '';
  }
}

// ========================================
// MESSAGE PROVIDER (WITH AUTO-DISPOSE)
// ========================================

@riverpod
class MessageNotifier extends _$MessageNotifier {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  ChatDatabaseHelper get _dbHelper => ChatDatabaseHelper();
  static const Uuid _uuid = Uuid();

  StreamSubscription<List<MessageModel>>? _messageSubscription;
  Timer? _markAsReadTimer;

  @override
  FutureOr<MessageState> build(String chatId) async {
    // Cleanup on dispose
    ref.onDispose(() {
      debugPrint('🧹 MessageNotifier disposed for chat $chatId');
      _messageSubscription?.cancel();
      _markAsReadTimer?.cancel();
    });

    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const MessageState(error: 'User not authenticated');
    }

    // Load participant details
    await _loadParticipantDetails(chatId);

    // Subscribe to messages stream
    _subscribeToMessages(chatId);
    
    // Load pinned messages
    await _loadPinnedMessages(chatId);
    
    // Mark messages as read after a short delay
    _scheduleMarkAsRead(chatId, currentUser.uid);
    
    return MessageState(
      isLoading: true,
      isOnline: true,
    );
  }

  void _scheduleMarkAsRead(String chatId, String userId) {
    // Mark as read after 1 second delay (user has opened the chat)
    _markAsReadTimer?.cancel();
    _markAsReadTimer = Timer(const Duration(seconds: 1), () {
      _markAllMessagesAsRead(chatId, userId);
    });
  }

  Future<void> _markAllMessagesAsRead(String chatId, String userId) async {
    try {
      // Get unread messages count first
      final unreadCount = await _dbHelper.getUnreadMessagesCount(chatId, userId);
      
      if (unreadCount > 0) {
        debugPrint('📖 Marking $unreadCount messages as read in chat $chatId');
        
        // Mark all messages as read in database
        await _dbHelper.markAllMessagesAsRead(chatId, userId);
        
        // Update chat unread count to 0
        await _dbHelper.updateChatUnreadCount(chatId, userId, 0);
        
        debugPrint('✅ All messages marked as read');
      }
    } catch (e) {
      debugPrint('❌ Error marking messages as read: $e');
    }
  }

  Future<void> _loadParticipantDetails(String chatId) async {
    try {
      final participants = await _dbHelper.getChatParticipants(chatId);
      final Map<String, String> participantNames = {};
      final Map<String, String> participantImages = {};

      for (final participant in participants) {
        participantNames[participant['userId']] = participant['userName'] ?? 'Unknown';
        participantImages[participant['userId']] = participant['userImage'] ?? '';
      }

      if (participantNames.isNotEmpty) {
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          participantNames: participantNames,
          participantImages: participantImages,
        ));
      }

      // Try to fetch fresh data from server
      final chat = await _repository.getChatById(chatId);
      if (chat != null) {
        final authNotifier = ref.read(authenticationProvider.notifier);
        
        for (final userId in chat.participants) {
          try {
            final user = await authNotifier.getUserById(userId);
            if (user != null) {
              participantNames[userId] = user.name;
              participantImages[userId] = user.profileImage;
              
              await _dbHelper.insertOrUpdateParticipant(
                chatId: chatId,
                userId: userId,
                userName: user.name,
                userImage: user.profileImage,
                phoneNumber: user.phoneNumber,
                isOnline: _isUserOnline(user.lastSeen),
                lastSeen: user.lastSeen,
              );
            }
          } catch (e) {
            debugPrint('❌ Error loading participant $userId: $e');
          }
        }

        final updatedState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(updatedState.copyWith(
          participantNames: participantNames,
          participantImages: participantImages,
        ));
      }
    } catch (e) {
      debugPrint('❌ Error loading participant details: $e');
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

  void _subscribeToMessages(String chatId) {
    _messageSubscription?.cancel();
    
    _messageSubscription = _repository.getMessagesStream(chatId).listen(
      (messages) {
        final currentState = state.valueOrNull ?? const MessageState();
        
        final pendingCount = messages.where((m) => m.status == MessageStatus.sending).length;
        final failedCount = messages.where((m) => m.status == MessageStatus.failed).length;
        
        state = AsyncValue.data(currentState.copyWith(
          messages: messages,
          isLoading: false,
          pendingMessagesCount: pendingCount,
          failedMessagesCount: failedCount,
          clearError: true,
        ));
      },
      onError: (error, stack) {
        debugPrint('❌ Message stream error: $error');
        final currentState = state.valueOrNull ?? const MessageState();
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
      
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        pinnedMessages: pinnedMessages,
      ));
    } catch (e) {
      debugPrint('❌ Error loading pinned messages: $e');
    }
  }

  // ========================================
  // MESSAGE SENDING
  // ========================================

  Future<void> sendTextMessage(String chatId, String content) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || content.trim().isEmpty) return;

    try {
      final currentState = state.valueOrNull ?? const MessageState();
      
      final message = MessageModel(
        messageId: _uuid.v4(),
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

      // Send via repository (handles local save + server sync)
      await _repository.sendMessage(message);
      
      // Clear reply state
      state = AsyncValue.data(currentState.copyWith(clearReply: true));
      
      debugPrint('✅ Text message sent');
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      
      final currentState = state.valueOrNull;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(
          error: 'Failed to send message',
        ));
      }
    }
  }

  Future<void> sendImageMessage(String chatId, File imageFile, {String? caption}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !imageFile.existsSync()) return;

    try {
      final fileSize = await imageFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'Image size exceeds 50MB limit',
        ));
        return;
      }

      final fileName = '${_uuid.v4()}.jpg';
      
      // Create temporary message
      final tempMessage = MessageModel(
        messageId: _uuid.v4(),
        chatId: chatId,
        senderId: currentUser.uid,
        content: caption ?? '',
        type: MessageEnum.image,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': 'image/jpeg',
          'isUploading': true,
        },
      );

      // Save temp message locally first
      await _dbHelper.insertOrUpdateMessage(tempMessage);
      
      // Upload image
      final authNotifier = ref.read(authenticationProvider.notifier);
      final imageUrl = await authNotifier.storeFileToStorage(
        file: imageFile,
        reference: 'chat_media/$chatId/$fileName',
      );
      
      // Create final message with URL
      final finalMessage = tempMessage.copyWith(
        mediaUrl: imageUrl,
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': 'image/jpeg',
          'isUploading': false,
        },
      );

      // Send via repository
      await _repository.sendMessage(finalMessage);
      
      debugPrint('✅ Image message sent');
    } catch (e) {
      debugPrint('❌ Error sending image: $e');
      
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send image',
      ));
    }
  }

  Future<void> sendVideoMessage(String chatId, File videoFile, {String? caption}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !videoFile.existsSync()) return;

    try {
      final fileSize = await videoFile.length();
      if (fileSize > 100 * 1024 * 1024) {
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'Video size exceeds 100MB limit',
        ));
        return;
      }

      final fileName = '${_uuid.v4()}.mp4';
      
      final tempMessage = MessageModel(
        messageId: _uuid.v4(),
        chatId: chatId,
        senderId: currentUser.uid,
        content: caption ?? '',
        type: MessageEnum.video,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': 'video/mp4',
          'isUploading': true,
        },
      );

      await _dbHelper.insertOrUpdateMessage(tempMessage);
      
      final authNotifier = ref.read(authenticationProvider.notifier);
      final videoUrl = await authNotifier.storeFileToStorage(
        file: videoFile,
        reference: 'chat_media/$chatId/$fileName',
      );
      
      final finalMessage = tempMessage.copyWith(
        mediaUrl: videoUrl,
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': 'video/mp4',
          'isUploading': false,
        },
      );

      await _repository.sendMessage(finalMessage);
      
      debugPrint('✅ Video message sent');
    } catch (e) {
      debugPrint('❌ Error sending video: $e');
      
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send video',
      ));
    }
  }

  Future<void> sendFileMessage(String chatId, File file, String fileName) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !file.existsSync() || fileName.trim().isEmpty) return;

    try {
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) {
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'File size exceeds 50MB limit',
        ));
        return;
      }

      final tempMessage = MessageModel(
        messageId: _uuid.v4(),
        chatId: chatId,
        senderId: currentUser.uid,
        content: '',
        type: MessageEnum.file,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'isUploading': true,
        },
      );

      await _dbHelper.insertOrUpdateMessage(tempMessage);
      
      final authNotifier = ref.read(authenticationProvider.notifier);
      final fileUrl = await authNotifier.storeFileToStorage(
        file: file,
        reference: 'chat_media/$chatId/$fileName',
      );
      
      final finalMessage = tempMessage.copyWith(
        mediaUrl: fileUrl,
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'isUploading': false,
        },
      );

      await _repository.sendMessage(finalMessage);
      
      debugPrint('✅ File message sent');
    } catch (e) {
      debugPrint('❌ Error sending file: $e');
      
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send file',
      ));
    }
  }

  Future<void> sendAudioMessage(String chatId, File audioFile, {Duration? duration}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || !audioFile.existsSync()) return;

    try {
      final fileSize = await audioFile.length();
      if (fileSize > 25 * 1024 * 1024) {
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'Audio size exceeds 25MB limit',
        ));
        return;
      }

      final fileName = '${_uuid.v4()}.m4a';
      
      final tempMessage = MessageModel(
        messageId: _uuid.v4(),
        chatId: chatId,
        senderId: currentUser.uid,
        content: '',
        type: MessageEnum.audio,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': 'audio/m4a',
          'duration': duration?.inSeconds ?? 0,
          'isVoiceNote': true,
          'isUploading': true,
        },
      );

      await _dbHelper.insertOrUpdateMessage(tempMessage);
      
      final authNotifier = ref.read(authenticationProvider.notifier);
      final audioUrl = await authNotifier.storeFileToStorage(
        file: audioFile,
        reference: 'chat_media/$chatId/$fileName',
      );
      
      final finalMessage = tempMessage.copyWith(
        mediaUrl: audioUrl,
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': 'audio/m4a',
          'duration': duration?.inSeconds ?? 0,
          'isVoiceNote': true,
          'isUploading': false,
        },
      );

      await _repository.sendMessage(finalMessage);
      
      debugPrint('✅ Audio message sent');
    } catch (e) {
      debugPrint('❌ Error sending audio: $e');
      
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send audio',
      ));
    }
  }

  // ========================================
  // MESSAGE OPERATIONS
  // ========================================

  void setReplyToMessage(MessageModel message) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(
        replyToMessageId: message.messageId,
        replyToMessage: message,
        clearError: true,
      ));
      debugPrint('📝 Reply set to message: ${message.messageId}');
    }
  }

  void cancelReply() {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(
        clearReply: true,
        clearError: true,
      ));
      debugPrint('❌ Reply cancelled');
    }
  }

  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    if (newContent.trim().isEmpty) return;

    try {
      await _repository.editMessage(chatId, messageId, newContent.trim());
      debugPrint('✅ Message edited');
    } catch (e) {
      debugPrint('❌ Error editing message: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to edit message',
      ));
    }
  }

  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    try {
      await _repository.deleteMessage(chatId, messageId, deleteForEveryone);
      debugPrint('✅ Message deleted');
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to delete message',
      ));
    }
  }

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
      
      await _loadPinnedMessages(chatId);
      debugPrint('✅ Message pin toggled');
    } catch (e) {
      debugPrint('❌ Error toggling pin: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to ${isPinned ? 'unpin' : 'pin'} message',
      ));
    }
  }

  Future<void> markMessagesAsDelivered(String chatId, List<String> messageIds) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || messageIds.isEmpty) return;

    try {
      await _dbHelper.markMessagesAsDelivered(chatId, messageIds, currentUser.uid);
      debugPrint('✅ ${messageIds.length} messages marked as delivered');
    } catch (e) {
      debugPrint('❌ Error marking messages as delivered: $e');
    }
  }

  // PUBLIC: Mark all messages as read (called from UI)
  Future<void> markAllMessagesAsRead(String chatId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    await _markAllMessagesAsRead(chatId, currentUser.uid);
  }

  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    if (query.trim().isEmpty) return [];

    try {
      return await _repository.searchMessages(chatId, query.trim());
    } catch (e) {
      debugPrint('❌ Error searching messages: $e');
      return [];
    }
  }

  void clearError() {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(clearError: true));
    }
  }

  Future<void> retryFailedMessage(String chatId, String messageId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      // Update status to sending
      await _dbHelper.updateMessageStatus(messageId, MessageStatus.sending);
      
      // Get the message
      final message = await _dbHelper.getMessageById(messageId);
      if (message != null) {
        // Resend
        await _repository.sendMessage(message);
        debugPrint('✅ Message retry successful');
      }
    } catch (e) {
      debugPrint('❌ Error retrying message: $e');
      
      // Revert to failed status
      await _dbHelper.updateMessageStatus(messageId, MessageStatus.failed);
    }
  }

  // ========================================
  // GETTERS
  // ========================================

  String getParticipantName(String userId) {
    final currentState = state.valueOrNull;
    return currentState?.getParticipantName(userId) ?? 'Unknown User';
  }

  String getParticipantImage(String userId) {
    final currentState = state.valueOrNull;
    return currentState?.getParticipantImage(userId) ?? '';
  }

  List<MessageModel> getFailedMessages() {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => 
        msg.status == MessageStatus.failed).toList();
  }

  Future<void> retryAllFailedMessages(String chatId) async {
    final failedMessages = getFailedMessages();
    if (failedMessages.isEmpty) return;

    for (final message in failedMessages) {
      await retryFailedMessage(chatId, message.messageId);
    }
  }

  String? get currentUserId => ref.read(currentUserIdProvider);
  bool get isAuthenticated => currentUserId != null;
}