// lib/features/chat/providers/message_provider.dart
// Updated message provider using new authentication system and HTTP services
// UPDATED: Removed all channel references, fully users-based system
// UPDATED: Added SQLite local storage for offline-first messaging
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/chat/providers/chat_database_provider.dart';
import 'package:textgb/features/chat/services/chat_database_service.dart';

part 'message_provider.g.dart';

// Message State
class MessageState {
  final bool isLoading;
  final bool isLoadingMore; // For pagination
  final List<MessageModel> messages;
  final String? error;
  final bool hasMore;
  final String? replyToMessageId;
  final MessageModel? replyToMessage;
  final List<MessageModel> pinnedMessages;
  final bool isTyping;
  final Map<String, String> participantNames; // userId -> userName
  final Map<String, String> participantImages; // userId -> userImage
  final bool isLoadedFromLocal; // Track if loaded from SQLite

  const MessageState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.messages = const [],
    this.error,
    this.hasMore = true,
    this.replyToMessageId,
    this.replyToMessage,
    this.pinnedMessages = const [],
    this.isTyping = false,
    this.participantNames = const {},
    this.participantImages = const {},
    this.isLoadedFromLocal = false,
  });

  MessageState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<MessageModel>? messages,
    String? error,
    bool? hasMore,
    String? replyToMessageId,
    MessageModel? replyToMessage,
    List<MessageModel>? pinnedMessages,
    bool? isTyping,
    Map<String, String>? participantNames,
    Map<String, String>? participantImages,
    bool? isLoadedFromLocal,
    bool clearReply = false,
    bool clearError = false,
  }) {
    return MessageState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      messages: messages ?? this.messages,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      replyToMessageId:
          clearReply ? null : (replyToMessageId ?? this.replyToMessageId),
      replyToMessage:
          clearReply ? null : (replyToMessage ?? this.replyToMessage),
      pinnedMessages: pinnedMessages ?? this.pinnedMessages,
      isTyping: isTyping ?? this.isTyping,
      participantNames: participantNames ?? this.participantNames,
      participantImages: participantImages ?? this.participantImages,
      isLoadedFromLocal: isLoadedFromLocal ?? this.isLoadedFromLocal,
    );
  }

  // Helper method to get participant name
  String getParticipantName(String userId) {
    return participantNames[userId] ?? 'Unknown User';
  }

  // Helper method to get participant image
  String getParticipantImage(String userId) {
    return participantImages[userId] ?? '';
  }
}

@riverpod
class MessageNotifier extends _$MessageNotifier {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  ChatDatabaseService get _databaseService => ref.read(chatDatabaseProvider);
  static const Uuid _uuid = Uuid();

  // Pagination
  int _currentPage = 0;
  static const int _pageSize = 50;

  @override
  FutureOr<MessageState> build(String chatId) async {
    // Use new user-based auth system
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const MessageState(error: 'User not authenticated');
    }

    // Load participant details for the chat
    await _loadParticipantDetails(chatId);

    // Phase 1: Load from SQLite immediately (instant, offline-first)
    await _loadMessagesFromLocal(chatId);

    // Phase 2: Start listening to messages stream (background sync)
    _subscribeToMessages(chatId);

    // Load pinned messages
    _loadPinnedMessages(chatId);

    return const MessageState(isLoading: true);
  }

  /// Load messages from local SQLite database (instant, offline-first)
  Future<void> _loadMessagesFromLocal(String chatId) async {
    try {
      final localMessages =
          await _databaseService.getMessages(chatId, limit: _pageSize);

      if (localMessages.isNotEmpty) {
        debugPrint(
            'MessageProvider: Loaded ${localMessages.length} messages from SQLite for chat $chatId');

        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          messages: localMessages,
          isLoading: false,
          isLoadedFromLocal: true,
          hasMore: localMessages.length >= _pageSize,
          clearError: true,
        ));
      }
    } catch (e) {
      debugPrint('MessageProvider: Error loading from SQLite: $e');
      // Continue to load from server even if local fails
    }
  }

  /// Save messages to local SQLite database
  Future<void> _saveMessagesToLocal(List<MessageModel> messages) async {
    try {
      if (messages.isEmpty) return;
      await _databaseService.upsertMessages(messages);
      debugPrint(
          'MessageProvider: Saved ${messages.length} messages to SQLite');
    } catch (e) {
      debugPrint('MessageProvider: Error saving to SQLite: $e');
    }
  }

  /// Update message status in local SQLite database
  Future<void> _updateMessageStatusInLocal(
      String messageId, MessageStatus status) async {
    try {
      await _databaseService.updateMessageStatus(messageId, status.name);
    } catch (e) {
      debugPrint(
          'MessageProvider: Error updating message status in SQLite: $e');
    }
  }

  Future<void> _loadParticipantDetails(String chatId) async {
    try {
      // Get chat details to find participants
      final chat = await _repository.getChatById(chatId);
      if (chat == null) return;

      final authNotifier = ref.read(authenticationProvider.notifier);
      final Map<String, String> participantNames = {};
      final Map<String, String> participantImages = {};

      // Load details for each participant
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

      // Update state with participant details
      final currentState = state.valueOrNull ?? const MessageState();
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
      (messages) async {
        // Save new messages from server to SQLite for offline access
        await _saveMessagesToLocal(messages);

        final currentState = state.valueOrNull ?? const MessageState();

        // Merge local and server messages, preserving any sending/failed messages
        final mergedMessages = _mergeMessages(currentState.messages, messages);

        state = AsyncValue.data(currentState.copyWith(
          messages: mergedMessages,
          isLoading: false,
          clearError: true,
        ));
      },
      onError: (error) {
        debugPrint('Message stream error: $error');
        final currentState = state.valueOrNull ?? const MessageState();
        // Keep local messages visible even on network error
        state = AsyncValue.data(currentState.copyWith(
          error: error.toString(),
          isLoading: false,
        ));
      },
    );
  }

  /// Merge local and server messages, preserving optimistic messages
  List<MessageModel> _mergeMessages(
      List<MessageModel> local, List<MessageModel> server) {
    // Keep optimistic messages (sending/failed status) that haven't been confirmed by server
    final optimisticMessages = local
        .where((msg) =>
            msg.status == MessageStatus.sending ||
            msg.status == MessageStatus.failed)
        .toList();

    // Create a set of server message IDs for quick lookup
    final serverMessageIds = server.map((m) => m.messageId).toSet();

    // Find optimistic messages that aren't in server response yet
    final pendingOptimistic = optimisticMessages
        .where((msg) => !serverMessageIds.contains(msg.messageId))
        .toList();

    // Merge: server messages + pending optimistic messages
    final merged = [...server];
    for (final msg in pendingOptimistic) {
      // Insert at the right position based on timestamp
      final insertIndex =
          merged.indexWhere((m) => m.timestamp.isBefore(msg.timestamp));
      if (insertIndex == -1) {
        merged.add(msg);
      } else {
        merged.insert(insertIndex, msg);
      }
    }

    // Sort by timestamp descending (newest first)
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return merged;
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

  // Helper method to build reply metadata
  Map<String, dynamic> _buildReplyMetadata(MessageModel? replyToMessage) {
    if (replyToMessage == null) return {};

    final metadata = <String, dynamic>{};

    // Store reply type
    metadata['replyToType'] = replyToMessage.type.name;

    // Store reply media URL if it's a media message
    if (replyToMessage.hasMedia()) {
      metadata['replyToMediaUrl'] = replyToMessage.mediaUrl;
    }

    return metadata;
  }

  // Send text message
  Future<void> sendTextMessage(String chatId, String content) async {
    // Use new user-based auth system
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      debugPrint('Cannot send message: user not authenticated');
      return;
    }

    if (content.trim().isEmpty) {
      debugPrint('Cannot send empty message');
      return;
    }

    final currentState = state.valueOrNull ?? const MessageState();

    // Build reply metadata if replying
    final replyMetadata = _buildReplyMetadata(currentState.replyToMessage);

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
      mediaMetadata: replyMetadata.isNotEmpty ? replyMetadata : null,
    );

    // Step 1: Save to SQLite immediately (optimistic, for offline support)
    await _databaseService.upsertMessage(message);

    // Step 2: Add to state (instant UI update)
    final updatedMessages = [message, ...currentState.messages];
    state = AsyncValue.data(currentState.copyWith(
      messages: updatedMessages,
      clearReply: true,
      clearError: true,
    ));

    // Step 3: Send to server
    try {
      await _repository.sendMessage(message);

      // Update status to sent in SQLite
      await _updateMessageStatusInLocal(message.messageId, MessageStatus.sent);

      // Update message status to sent
      await _repository.updateMessageStatus(
          chatId, message.messageId, MessageStatus.sent);

      // Update state with sent status
      _updateMessageInState(message.messageId, MessageStatus.sent);
    } catch (e) {
      debugPrint('Error sending message: $e');

      // Update status to failed in SQLite
      await _updateMessageStatusInLocal(
          message.messageId, MessageStatus.failed);

      // Update state with failed status
      _updateMessageInState(message.messageId, MessageStatus.failed);

      final latestState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(latestState.copyWith(
        error: 'Failed to send message: $e',
      ));
    }
  }

  /// Helper to update a single message status in state
  void _updateMessageInState(String messageId, MessageStatus status) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedMessages = currentState.messages.map((msg) {
      if (msg.messageId == messageId) {
        return msg.copyWith(status: status);
      }
      return msg;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(messages: updatedMessages));
  }

  // Send image message
  Future<void> sendImageMessage(String chatId, File imageFile,
      {String? caption}) async {
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

    // Check file size
    final fileSize = await imageFile.length();
    if (fileSize > 50 * 1024 * 1024) {
      // 50MB limit
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Image size exceeds 50MB limit',
      ));
      return;
    }

    final fileName = '${_uuid.v4()}.jpg';
    final currentState = state.valueOrNull ?? const MessageState();

    // Build reply metadata if replying
    final replyMetadata = _buildReplyMetadata(currentState.replyToMessage);

    // Merge with image metadata
    final imageMetadata = {
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': 'image/jpeg',
      'isUploading': true,
      ...replyMetadata,
    };

    // Create optimistic message
    final tempMessage = MessageModel(
      messageId: _uuid.v4(),
      chatId: chatId,
      senderId: currentUser.uid,
      content: caption ?? '',
      type: MessageEnum.image,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      replyToMessageId: currentState.replyToMessageId,
      replyToContent: currentState.replyToMessage?.getDisplayContent(),
      replyToSender: currentState.replyToMessage?.senderId,
      mediaMetadata: imageMetadata,
    );

    // Step 1: Save to SQLite immediately (optimistic)
    await _databaseService.upsertMessage(tempMessage);

    // Step 2: Add to local state immediately
    final updatedMessages = [tempMessage, ...currentState.messages];
    state = AsyncValue.data(currentState.copyWith(
      messages: updatedMessages,
      clearReply: true,
      clearError: true,
    ));

    try {
      // Upload image via R2 through Go backend (using auth repository)
      final authNotifier = ref.read(authenticationProvider.notifier);
      final imageUrl = await authNotifier.storeFileToStorage(
        file: imageFile,
        reference: 'chat_media/$chatId/$fileName',
      );

      // Create final message with uploaded URL
      final finalMessage = tempMessage.copyWith(
        mediaUrl: imageUrl,
        status: MessageStatus.sending,
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': 'image/jpeg',
          'isUploading': false,
          ...replyMetadata,
        },
      );

      // Update SQLite with final message
      await _databaseService.upsertMessage(finalMessage);

      // Send final message
      await _repository.sendMessage(finalMessage);
      await _repository.updateMessageStatus(
          chatId, finalMessage.messageId, MessageStatus.sent);

      // Update SQLite status
      await _updateMessageStatusInLocal(
          finalMessage.messageId, MessageStatus.sent);
      _updateMessageInState(finalMessage.messageId, MessageStatus.sent);
    } catch (e) {
      debugPrint('Error sending image: $e');

      // Update SQLite status to failed
      await _updateMessageStatusInLocal(
          tempMessage.messageId, MessageStatus.failed);
      _updateMessageInState(tempMessage.messageId, MessageStatus.failed);

      final latestState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(latestState.copyWith(
        error: 'Failed to send image: $e',
      ));
    }
  }

  // Send video message
  Future<void> sendVideoMessage(String chatId, File videoFile,
      {String? caption}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      debugPrint('Cannot send video: user not authenticated');
      return;
    }

    if (!videoFile.existsSync()) {
      debugPrint('Video file does not exist');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Video file not found',
      ));
      return;
    }

    try {
      // Check file size
      final fileSize = await videoFile.length();
      if (fileSize > 100 * 1024 * 1024) {
        // 100MB limit for videos
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'Video size exceeds 100MB limit',
        ));
        return;
      }

      final fileName = '${_uuid.v4()}.mp4';
      final currentState = state.valueOrNull ?? const MessageState();

      // Build reply metadata if replying
      final replyMetadata = _buildReplyMetadata(currentState.replyToMessage);

      // Merge with video metadata
      final videoMetadata = {
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': 'video/mp4',
        'isUploading': true,
        'duration': 0, // Could be calculated if needed
        ...replyMetadata,
      };

      // Create optimistic message
      final tempMessage = MessageModel(
        messageId: _uuid.v4(),
        chatId: chatId,
        senderId: currentUser.uid,
        content: caption ?? '',
        type: MessageEnum.video,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        replyToMessageId: currentState.replyToMessageId,
        replyToContent: currentState.replyToMessage?.getDisplayContent(),
        replyToSender: currentState.replyToMessage?.senderId,
        mediaMetadata: videoMetadata,
      );

      // Add to local state immediately
      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearReply: true,
        clearError: true,
      ));

      // Upload video via R2 through Go backend (using auth repository)
      final authNotifier = ref.read(authenticationProvider.notifier);
      final videoUrl = await authNotifier.storeFileToStorage(
        file: videoFile,
        reference: 'chat_media/$chatId/$fileName',
      );

      // Create final message with uploaded URL
      final finalMessage = tempMessage.copyWith(
        mediaUrl: videoUrl,
        status: MessageStatus.sending,
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': 'video/mp4',
          'isUploading': false,
          'duration': 0,
          ...replyMetadata,
        },
      );

      // Send final message
      await _repository.sendMessage(finalMessage);
      await _repository.updateMessageStatus(
          chatId, finalMessage.messageId, MessageStatus.sent);
    } catch (e) {
      debugPrint('Error sending video: $e');

      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send video: $e',
      ));
    }
  }

  // Send file message
  Future<void> sendFileMessage(
      String chatId, File file, String fileName) async {
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
      if (fileSize > 50 * 1024 * 1024) {
        // 50MB limit
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'File size exceeds 50MB limit',
        ));
        return;
      }

      final currentState = state.valueOrNull ?? const MessageState();

      // Build reply metadata if replying
      final replyMetadata = _buildReplyMetadata(currentState.replyToMessage);

      // Merge with file metadata
      final fileMetadata = {
        'fileName': fileName,
        'fileSize': fileSize,
        'isUploading': true,
        ...replyMetadata,
      };

      // Create optimistic message
      final tempMessage = MessageModel(
        messageId: _uuid.v4(),
        chatId: chatId,
        senderId: currentUser.uid,
        content: '',
        type: MessageEnum.file,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        replyToMessageId: currentState.replyToMessageId,
        replyToContent: currentState.replyToMessage?.getDisplayContent(),
        replyToSender: currentState.replyToMessage?.senderId,
        mediaMetadata: fileMetadata,
      );

      // Add to local state immediately
      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearReply: true,
        clearError: true,
      ));

      // Upload file via R2 through Go backend (using auth repository)
      final authNotifier = ref.read(authenticationProvider.notifier);
      final fileUrl = await authNotifier.storeFileToStorage(
        file: file,
        reference: 'chat_media/$chatId/$fileName',
      );

      // Create final message with uploaded URL
      final finalMessage = tempMessage.copyWith(
        mediaUrl: fileUrl,
        status: MessageStatus.sending,
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'isUploading': false,
          ...replyMetadata,
        },
      );

      // Send final message
      await _repository.sendMessage(finalMessage);
      await _repository.updateMessageStatus(
          chatId, finalMessage.messageId, MessageStatus.sent);
    } catch (e) {
      debugPrint('Error sending file: $e');

      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send file: $e',
      ));
    }
  }

  // Send audio message (voice note)
  Future<void> sendAudioMessage(String chatId, File audioFile,
      {Duration? duration}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      debugPrint('Cannot send audio: user not authenticated');
      return;
    }

    if (!audioFile.existsSync()) {
      debugPrint('Audio file does not exist');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Audio file not found',
      ));
      return;
    }

    try {
      // Check file size
      final fileSize = await audioFile.length();
      if (fileSize > 25 * 1024 * 1024) {
        // 25MB limit for audio
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'Audio size exceeds 25MB limit',
        ));
        return;
      }

      final fileName = '${_uuid.v4()}.m4a';
      final currentState = state.valueOrNull ?? const MessageState();

      // Build reply metadata if replying
      final replyMetadata = _buildReplyMetadata(currentState.replyToMessage);

      // Merge with audio metadata
      final audioMetadata = {
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': 'audio/m4a',
        'isUploading': true,
        'duration': duration?.inSeconds ?? 0,
        'isVoiceNote': true,
        ...replyMetadata,
      };

      // Create optimistic message
      final tempMessage = MessageModel(
        messageId: _uuid.v4(),
        chatId: chatId,
        senderId: currentUser.uid,
        content: '',
        type: MessageEnum.audio,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        replyToMessageId: currentState.replyToMessageId,
        replyToContent: currentState.replyToMessage?.getDisplayContent(),
        replyToSender: currentState.replyToMessage?.senderId,
        mediaMetadata: audioMetadata,
      );

      // Add to local state immediately
      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearReply: true,
        clearError: true,
      ));

      // Upload audio via R2 through Go backend (using auth repository)
      final authNotifier = ref.read(authenticationProvider.notifier);
      final audioUrl = await authNotifier.storeFileToStorage(
        file: audioFile,
        reference: 'chat_media/$chatId/$fileName',
      );

      // Create final message with uploaded URL
      final finalMessage = tempMessage.copyWith(
        mediaUrl: audioUrl,
        status: MessageStatus.sending,
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': 'audio/m4a',
          'isUploading': false,
          'duration': duration?.inSeconds ?? 0,
          'isVoiceNote': true,
          ...replyMetadata,
        },
      );

      // Send final message
      await _repository.sendMessage(finalMessage);
      await _repository.updateMessageStatus(
          chatId, finalMessage.messageId, MessageStatus.sent);
    } catch (e) {
      debugPrint('Error sending audio: $e');

      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send audio: $e',
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
  Future<void> editMessage(
      String chatId, String messageId, String newContent) async {
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
  Future<void> deleteMessage(
      String chatId, String messageId, bool deleteForEveryone) async {
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
  Future<void> togglePinMessage(
      String chatId, String messageId, bool isPinned) async {
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
  Future<void> markMessagesAsDelivered(
      String chatId, List<String> messageIds) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || messageIds.isEmpty) return;

    try {
      for (final messageId in messageIds) {
        await _repository.markMessageAsDelivered(
            chatId, messageId, currentUser.uid);
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
    final messageIndex =
        currentState.messages.indexWhere((msg) => msg.messageId == messageId);
    if (messageIndex == -1) return;

    final failedMessage = currentState.messages[messageIndex];
    if (failedMessage.status != MessageStatus.failed) return;

    try {
      // Update status to sending in SQLite
      await _updateMessageStatusInLocal(messageId, MessageStatus.sending);

      // Update status to sending in state
      final updatedMessages = List<MessageModel>.from(currentState.messages);
      updatedMessages[messageIndex] =
          failedMessage.copyWith(status: MessageStatus.sending);

      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearError: true,
      ));

      // Retry sending
      await _repository
          .sendMessage(failedMessage.copyWith(status: MessageStatus.sending));
      await _repository.updateMessageStatus(
          chatId, messageId, MessageStatus.sent);

      // Update SQLite status to sent
      await _updateMessageStatusInLocal(messageId, MessageStatus.sent);
      _updateMessageInState(messageId, MessageStatus.sent);
    } catch (e) {
      debugPrint('Error retrying message: $e');

      // Update SQLite status back to failed
      await _updateMessageStatusInLocal(messageId, MessageStatus.failed);

      final latestState = state.valueOrNull;
      if (latestState != null) {
        final updatedMessages = List<MessageModel>.from(latestState.messages);
        if (messageIndex < updatedMessages.length) {
          updatedMessages[messageIndex] =
              failedMessage.copyWith(status: MessageStatus.failed);
        }

        state = AsyncValue.data(latestState.copyWith(
          messages: updatedMessages,
          error: 'Failed to retry message: $e',
        ));
      }
    }
  }

  // Load more messages (pagination) - loads from SQLite
  Future<void> loadMoreMessages(String chatId) async {
    final currentState = state.valueOrNull;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    try {
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

      _currentPage++;

      // Load older messages from SQLite
      final olderMessages = await _databaseService.getMessages(
        chatId,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      debugPrint(
          'MessageProvider: Loaded ${olderMessages.length} more messages from SQLite (page $_currentPage)');

      // Check if there are more messages
      final hasMoreMessages = olderMessages.length >= _pageSize;

      // Append older messages to existing list
      final allMessages = [...currentState.messages, ...olderMessages];

      state = AsyncValue.data(currentState.copyWith(
        messages: allMessages,
        isLoadingMore: false,
        hasMore: hasMoreMessages,
      ));
    } catch (e) {
      debugPrint('Error loading more messages: $e');

      state = AsyncValue.data(currentState.copyWith(
        isLoadingMore: false,
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

  // React to message (add emoji reaction)
  Future<void> reactToMessage(
      String chatId, String messageId, String emoji) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      // Update local state immediately for better UX
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.messageId == messageId) {
            final reactions = Map<String, String>.from(msg.reactions ?? {});

            // Toggle reaction - if user already reacted with this emoji, remove it
            if (reactions[currentUser.uid] == emoji) {
              reactions.remove(currentUser.uid);
            } else {
              reactions[currentUser.uid] = emoji;
            }

            return msg.copyWith(reactions: reactions);
          }
          return msg;
        }).toList();

        state =
            AsyncValue.data(currentState.copyWith(messages: updatedMessages));
      }

      // TODO: Send reaction to server when implemented
      // await _repository.addMessageReaction(chatId, messageId, currentUser.uid, emoji);
    } catch (e) {
      debugPrint('Error reacting to message: $e');

      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to react to message: $e',
      ));
    }
  }

  // Forward message to another chat
  Future<void> forwardMessage(MessageModel message, String toChatId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      // Create new message with forwarded content
      final forwardedMessage = MessageModel(
        messageId: _uuid.v4(),
        chatId: toChatId,
        senderId: currentUser.uid,
        content: message.content,
        type: message.type,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaUrl: message.mediaUrl,
        mediaMetadata: {
          ...message.mediaMetadata ?? {},
          'isForwarded': true,
          'originalSender': getParticipantName(message.senderId),
          'originalTimestamp': message.timestamp.toIso8601String(),
        },
      );

      // Send forwarded message
      await _repository.sendMessage(forwardedMessage);
      await _repository.updateMessageStatus(
          toChatId, forwardedMessage.messageId, MessageStatus.sent);
    } catch (e) {
      debugPrint('Error forwarding message: $e');

      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to forward message: $e',
      ));
    }
  }

  // Add message reaction
  Future<void> addMessageReaction(
      String chatId, String messageId, String emoji) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      // Update local state immediately for better UX
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.messageId == messageId) {
            final reactions = Map<String, String>.from(msg.reactions ?? {});
            reactions[currentUser.uid] = emoji;
            return msg.copyWith(reactions: reactions);
          }
          return msg;
        }).toList();

        state =
            AsyncValue.data(currentState.copyWith(messages: updatedMessages));
      }

      // TODO: Send reaction to server when implemented
      // await _repository.addMessageReaction(chatId, messageId, currentUser.uid, emoji);
    } catch (e) {
      debugPrint('Error adding message reaction: $e');
    }
  }

  // Remove message reaction
  Future<void> removeMessageReaction(String chatId, String messageId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      // Update local state immediately for better UX
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.messageId == messageId) {
            final reactions = Map<String, String>.from(msg.reactions ?? {});
            reactions.remove(currentUser.uid);
            return msg.copyWith(reactions: reactions);
          }
          return msg;
        }).toList();

        state =
            AsyncValue.data(currentState.copyWith(messages: updatedMessages));
      }

      // TODO: Send reaction removal to server when implemented
      // await _repository.removeMessageReaction(chatId, messageId, currentUser.uid);
    } catch (e) {
      debugPrint('Error removing message reaction: $e');
    }
  }

  // Get messages by type
  List<MessageModel> getMessagesByType(MessageEnum type) {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => msg.type == type).toList();
  }

  // Get messages from specific user
  List<MessageModel> getMessagesFromUser(String userId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages
        .where((msg) => msg.senderId == userId)
        .toList();
  }

  // Get failed messages
  List<MessageModel> getFailedMessages() {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages
        .where((msg) => msg.status == MessageStatus.failed)
        .toList();
  }

  // Retry all failed messages
  Future<void> retryAllFailedMessages(String chatId) async {
    final failedMessages = getFailedMessages();
    if (failedMessages.isEmpty) return;

    for (final message in failedMessages) {
      await retryFailedMessage(chatId, message.messageId);
    }
  }

  // Export messages as text
  String exportMessagesAsText() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.messages.isEmpty) return '';

    final buffer = StringBuffer();
    final sortedMessages = List<MessageModel>.from(currentState.messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final message in sortedMessages) {
      final senderName = getParticipantName(message.senderId);
      final timestamp = message.timestamp.toLocal().toString().split('.')[0];

      buffer
          .writeln('[$timestamp] $senderName: ${message.getDisplayContent()}');

      if (message.isReply() && message.replyToContent != null) {
        buffer.writeln('  └─ Replied to: ${message.replyToContent}');
      }
    }

    return buffer.toString();
  }

  // Clear chat messages locally (not from server)
  void clearLocalMessages() {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(
        messages: [],
        pinnedMessages: [],
        clearReply: true,
        clearError: true,
      ));
    }
  }

  // Get message count by status
  Map<MessageStatus, int> getMessageCountByStatus() {
    final currentState = state.valueOrNull;
    if (currentState == null) return {};

    final counts = <MessageStatus, int>{};
    for (final status in MessageStatus.values) {
      counts[status] =
          currentState.messages.where((msg) => msg.status == status).length;
    }
    return counts;
  }

  // Check if message exists
  bool messageExists(String messageId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return false;

    return currentState.messages.any((msg) => msg.messageId == messageId);
  }

  // Get message by ID
  MessageModel? getMessageById(String messageId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return null;

    try {
      return currentState.messages
          .firstWhere((msg) => msg.messageId == messageId);
    } catch (e) {
      return null;
    }
  }

  // Update local message (for optimistic updates)
  void updateLocalMessage(String messageId, MessageModel updatedMessage) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedMessages = currentState.messages.map((msg) {
      if (msg.messageId == messageId) {
        return updatedMessage;
      }
      return msg;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(messages: updatedMessages));
  }

  // Get message statistics
  Map<String, dynamic> getMessageStatistics(String chatId) {
    final currentState = state.valueOrNull;
    if (currentState == null) {
      return {
        'totalMessages': 0,
        'textMessages': 0,
        'imageMessages': 0,
        'videoMessages': 0,
        'audioMessages': 0,
        'fileMessages': 0,
        'pinnedMessages': 0,
        'myMessages': 0,
        'otherMessages': 0,
      };
    }

    final currentUserId = ref.read(currentUserIdProvider);
    final totalMessages = currentState.messages.length;
    final textMessages = currentState.messages
        .where((msg) => msg.type == MessageEnum.text)
        .length;
    final imageMessages = currentState.messages
        .where((msg) => msg.type == MessageEnum.image)
        .length;
    final videoMessages = currentState.messages
        .where((msg) => msg.type == MessageEnum.video)
        .length;
    final audioMessages = currentState.messages
        .where((msg) => msg.type == MessageEnum.audio)
        .length;
    final fileMessages = currentState.messages
        .where((msg) => msg.type == MessageEnum.file)
        .length;
    final pinnedMessages = currentState.pinnedMessages.length;
    final myMessages = currentUserId != null
        ? currentState.messages
            .where((msg) => msg.senderId == currentUserId)
            .length
        : 0;
    final otherMessages = totalMessages - myMessages;

    return {
      'totalMessages': totalMessages,
      'textMessages': textMessages,
      'imageMessages': imageMessages,
      'videoMessages': videoMessages,
      'audioMessages': audioMessages,
      'fileMessages': fileMessages,
      'pinnedMessages': pinnedMessages,
      'myMessages': myMessages,
      'otherMessages': otherMessages,
    };
  }

  // Refresh participants data
  Future<void> refreshParticipants(String chatId) async {
    await _loadParticipantDetails(chatId);
  }

  // Get current user ID
  String? get currentUserId => ref.read(currentUserIdProvider);

  // Check if current user is authenticated
  bool get isAuthenticated => currentUserId != null;

  // Get participant info helpers
  String getParticipantName(String userId) {
    final currentState = state.valueOrNull;
    return currentState?.getParticipantName(userId) ?? 'Unknown User';
  }

  String getParticipantImage(String userId) {
    final currentState = state.valueOrNull;
    return currentState?.getParticipantImage(userId) ?? '';
  }

  // Bulk message operations
  Future<void> deleteMultipleMessages(
      String chatId, List<String> messageIds, bool deleteForEveryone) async {
    if (messageIds.isEmpty) return;

    try {
      final futures = messageIds.map((messageId) =>
          _repository.deleteMessage(chatId, messageId, deleteForEveryone));

      await Future.wait(futures);
    } catch (e) {
      debugPrint('Error deleting multiple messages: $e');

      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to delete messages: $e',
      ));
    }
  }

  // Get latest message
  MessageModel? get latestMessage {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.messages.isEmpty) return null;

    return currentState.messages.first; // Messages are sorted by timestamp desc
  }

  // Check if chat has any media messages
  bool get hasMediaMessages {
    final currentState = state.valueOrNull;
    if (currentState == null) return false;

    return currentState.messages.any((msg) =>
        msg.type == MessageEnum.image ||
        msg.type == MessageEnum.video ||
        msg.type == MessageEnum.audio ||
        msg.type == MessageEnum.file);
  }

  // Get media messages only
  List<MessageModel> get mediaMessages {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages
        .where((msg) =>
            msg.type == MessageEnum.image ||
            msg.type == MessageEnum.video ||
            msg.type == MessageEnum.audio ||
            msg.type == MessageEnum.file)
        .toList();
  }

  // Get text messages only
  List<MessageModel> get textMessages {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages
        .where((msg) => msg.type == MessageEnum.text)
        .toList();
  }

  // Get messages with reactions
  List<MessageModel> get messagesWithReactions {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => msg.hasReactions()).toList();
  }

  // Get reply messages
  List<MessageModel> get replyMessages {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => msg.isReply()).toList();
  }

  // Get unread messages count
  int getUnreadMessagesCount() {
    final currentState = state.valueOrNull;
    if (currentState == null) return 0;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return 0;

    return currentState.messages
        .where((msg) =>
            msg.senderId != currentUserId && !msg.isReadBy(currentUserId))
        .length;
  }

  // Mark all messages as read
  Future<void> markAllMessagesAsRead(String chatId) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final unreadMessages = currentState.messages
        .where((msg) =>
            msg.senderId != currentUserId && !msg.isReadBy(currentUserId))
        .toList();

    if (unreadMessages.isEmpty) return;

    try {
      // Mark messages as delivered (since we don't have read functionality)
      await markMessagesAsDelivered(
          chatId, unreadMessages.map((msg) => msg.messageId).toList());
    } catch (e) {
      debugPrint('Error marking all messages as read: $e');
    }
  }

  // Get messages sent today
  List<MessageModel> get todaysMessages {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return currentState.messages
        .where((msg) =>
            msg.timestamp.isAfter(startOfDay) &&
            msg.timestamp.isBefore(endOfDay))
        .toList();
  }

  // Get messages sent this week
  List<MessageModel> get thisWeeksMessages {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekMidnight =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return currentState.messages
        .where((msg) => msg.timestamp.isAfter(startOfWeekMidnight))
        .toList();
  }

  // Send location message
  Future<void> sendLocationMessage(
      String chatId, double latitude, double longitude,
      {String? address}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final currentState = state.valueOrNull ?? const MessageState();

      final message = MessageModel(
        messageId: _uuid.v4(),
        chatId: chatId,
        senderId: currentUser.uid,
        content: address ?? 'Location',
        type: MessageEnum.location,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaMetadata: {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        },
      );

      // Optimistically add message to local state
      final updatedMessages = [message, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearError: true,
      ));

      // Send to server
      await _repository.sendMessage(message);
      await _repository.updateMessageStatus(
          chatId, message.messageId, MessageStatus.sent);
    } catch (e) {
      debugPrint('Error sending location message: $e');

      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send location: $e',
      ));
    }
  }

  // Send contact message
  Future<void> sendContactMessage(
      String chatId, String contactName, String contactPhone) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final currentState = state.valueOrNull ?? const MessageState();

      final message = MessageModel(
        messageId: _uuid.v4(),
        chatId: chatId,
        senderId: currentUser.uid,
        content: contactName,
        type: MessageEnum.contact,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaMetadata: {
          'contactName': contactName,
          'contactPhone': contactPhone,
        },
      );

      // Optimistically add message to local state
      final updatedMessages = [message, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearError: true,
      ));

      // Send to server
      await _repository.sendMessage(message);
      await _repository.updateMessageStatus(
          chatId, message.messageId, MessageStatus.sent);
    } catch (e) {
      debugPrint('Error sending contact message: $e');

      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send contact: $e',
      ));
    }
  }

  // Send gift message
  Future<void> sendGiftMessage(
    String chatId, {
    required String giftId,
    required String giftName,
    required String giftIcon,
    required int giftValue,
    String? recipientId,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      debugPrint('Cannot send gift: user not authenticated');
      return;
    }

    try {
      final currentState = state.valueOrNull ?? const MessageState();

      // Build gift metadata
      final giftMetadata = {
        'giftId': giftId,
        'giftName': giftName,
        'giftIcon': giftIcon,
        'giftValue': giftValue,
        'isOpened': false,
      };

      // Create optimistic message
      final tempMessage = MessageModel(
        messageId: _uuid.v4(),
        chatId: chatId,
        senderId: currentUser.uid,
        content: '', // Gift messages don't have text content
        type: MessageEnum.gift,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaMetadata: giftMetadata,
      );

      // Add to local state immediately
      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearError: true,
      ));

      // Note: The gift API call (wallet deduction) is already handled by VirtualGiftsBottomSheet
      // Here we just send the chat message notification

      // Send message to chat repository
      await _repository.sendMessage(tempMessage);
      await _repository.updateMessageStatus(
          chatId, tempMessage.messageId, MessageStatus.sent);
    } catch (e) {
      debugPrint('Error sending gift message: $e');

      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send gift: $e',
      ));
    }
  }

  // Check if user is currently typing
  bool get isCurrentlyTyping {
    final currentState = state.valueOrNull;
    return currentState?.isTyping ?? false;
  }

  // Get sending messages count
  int get sendingMessagesCount {
    final currentState = state.valueOrNull;
    if (currentState == null) return 0;

    return currentState.messages
        .where((msg) => msg.status == MessageStatus.sending)
        .length;
  }

  // Get failed messages count
  int get failedMessagesCount {
    final currentState = state.valueOrNull;
    if (currentState == null) return 0;

    return currentState.messages
        .where((msg) => msg.status == MessageStatus.failed)
        .length;
  }

  // Check if there are any failed messages
  bool get hasFailedMessages => failedMessagesCount > 0;

  // Check if there are any sending messages
  bool get hasSendingMessages => sendingMessagesCount > 0;

  // Get message by timestamp
  List<MessageModel> getMessagesByDateRange(DateTime start, DateTime end) {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages
        .where((msg) =>
            msg.timestamp.isAfter(start) && msg.timestamp.isBefore(end))
        .toList();
  }

  // Get messages containing specific text
  List<MessageModel> getMessagesContaining(String text) {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    final searchText = text.toLowerCase();
    return currentState.messages
        .where((msg) => msg.content.toLowerCase().contains(searchText))
        .toList();
  }

  // Dispose resources when provider is disposed
  void dispose() {
    // Clean up any subscriptions or resources
    debugPrint('MessageNotifier disposed for chat');
  }
}
