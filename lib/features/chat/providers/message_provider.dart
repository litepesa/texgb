// lib/features/chat/providers/message_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';

part 'message_provider.g.dart';

// Message State
class MessageState {
  final bool isLoading;
  final List<MessageModel> messages;
  final String? error;
  final bool hasMore;
  final String? replyToMessageId;
  final MessageModel? replyToMessage;
  final List<MessageModel> pinnedMessages;
  final bool isTyping;

  const MessageState({
    this.isLoading = false,
    this.messages = const [],
    this.error,
    this.hasMore = true,
    this.replyToMessageId,
    this.replyToMessage,
    this.pinnedMessages = const [],
    this.isTyping = false,
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
    );
  }
}

@riverpod
class MessageNotifier extends _$MessageNotifier {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  static const Uuid _uuid = Uuid();

  @override
  FutureOr<MessageState> build(String chatId) async {
    // Start listening to messages stream
    _subscribeToMessages(chatId);
    
    // Load pinned messages
    _loadPinnedMessages(chatId);
    
    return const MessageState(isLoading: true);
  }

  void _subscribeToMessages(String chatId) {
    _repository.getMessagesStream(chatId).listen(
      (messages) {
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          messages: messages,
          isLoading: false,
          clearError: true,
        ));
      },
      onError: (error) {
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
        replyToContent: currentState.replyToMessage?.content,
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
      await _repository.sendMessage(message);
      
      // Update message status to sent
      await _repository.updateMessageStatus(chatId, message.messageId, MessageStatus.sent);
      
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

    if (!imageFile.existsSync()) {
      debugPrint('Image file does not exist');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Image file not found',
      ));
      return;
    }

    try {
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > 50 * 1024 * 1024) { // 50MB limit
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'Image size exceeds 50MB limit',
        ));
        return;
      }

      final fileName = '${_uuid.v4()}.jpg';
      
      // Create optimistic message
      final tempMessage = MessageModel(
        messageId: _uuid.v4(),
        chatId: chatId,
        senderId: currentUser.uid,
        content: '',
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

      // Add to local state immediately
      final currentState = state.valueOrNull ?? const MessageState();
      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearError: true,
      ));
      
      // Upload image
      final imageUrl = await _repository.uploadMedia(imageFile, fileName, chatId);
      
      // Create final message with uploaded URL
      final finalMessage = tempMessage.copyWith(
        mediaUrl: imageUrl,
        status: MessageStatus.sending,
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': 'image/jpeg',
          'isUploading': false,
        },
      );

      // Send final message
      await _repository.sendMessage(finalMessage);
      await _repository.updateMessageStatus(chatId, finalMessage.messageId, MessageStatus.sent);
      
    } catch (e) {
      debugPrint('Error sending image: $e');
      
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send image: $e',
      ));
    }
  }

  // Send file message
  Future<void> sendFileMessage(String chatId, File file, String fileName) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      debugPrint('Cannot send file: user not authenticated');
      return;
    }

    if (!file.existsSync()) {
      debugPrint('File does not exist');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'File not found',
      ));
      return;
    }

    if (fileName.trim().isEmpty) {
      debugPrint('File name cannot be empty');
      return;
    }

    try {
      // Check file size
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) { // 50MB limit
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'File size exceeds 50MB limit',
        ));
        return;
      }

      // Create optimistic message
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

      // Add to local state immediately
      final currentState = state.valueOrNull ?? const MessageState();
      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearError: true,
      ));
      
      // Upload file
      final fileUrl = await _repository.uploadMedia(file, fileName, chatId);
      
      // Create final message with uploaded URL
      final finalMessage = tempMessage.copyWith(
        mediaUrl: fileUrl,
        status: MessageStatus.sending,
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'isUploading': false,
        },
      );

      // Send final message
      await _repository.sendMessage(finalMessage);
      await _repository.updateMessageStatus(chatId, finalMessage.messageId, MessageStatus.sent);
      
    } catch (e) {
      debugPrint('Error sending file: $e');
      
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send file: $e',
      ));
    }
  }

  // Reply to message
  void setReplyToMessage(MessageModel message) {
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
      
      final currentState = state.valueOrNull ?? const MessageState();
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
      
      final currentState = state.valueOrNull ?? const MessageState();
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
        // Check if we've reached the pin limit
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
      
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to ${isPinned ? 'unpin' : 'pin'} message: $e',
      ));
    }
  }

  // Mark messages as delivered (not read - as per requirement)
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
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      return await _repository.searchMessages(chatId, query.trim());
    } catch (e) {
      debugPrint('Error searching messages: $e');
      
      final currentState = state.valueOrNull ?? const MessageState();
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

    // Find the failed message
    final messageIndex = currentState.messages.indexWhere((msg) => msg.messageId == messageId);
    if (messageIndex == -1) return;

    final failedMessage = currentState.messages[messageIndex];
    if (failedMessage.status != MessageStatus.failed) return;

    try {
      // Update status to sending
      final updatedMessages = List<MessageModel>.from(currentState.messages);
      updatedMessages[messageIndex] = failedMessage.copyWith(status: MessageStatus.sending);
      
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearError: true,
      ));

      // Retry sending
      await _repository.sendMessage(failedMessage.copyWith(status: MessageStatus.sending));
      await _repository.updateMessageStatus(chatId, messageId, MessageStatus.sent);
      
    } catch (e) {
      debugPrint('Error retrying message: $e');
      
      final latestState = state.valueOrNull;
      if (latestState != null) {
        final updatedMessages = List<MessageModel>.from(latestState.messages);
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

  // Load more messages (pagination)
  Future<void> loadMoreMessages(String chatId) async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.isLoading || !currentState.hasMore) {
      return;
    }

    try {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));
      
      // In a real implementation, you would load older messages here
      // For now, we'll just mark as no more messages
      await Future.delayed(const Duration(milliseconds: 500));
      
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        hasMore: false,
      ));
      
    } catch (e) {
      debugPrint('Error loading more messages: $e');
      
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: 'Failed to load more messages: $e',
      ));
    }
  }

  // Get typing status (placeholder for future implementation)
  void setTyping(String chatId, bool isTyping) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(isTyping: isTyping));
    }
  }
}