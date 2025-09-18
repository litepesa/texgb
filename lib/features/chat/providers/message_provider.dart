// lib/features/chat/providers/message_provider.dart
// Updated message provider with offline-first support using SQLite
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
import 'package:connectivity_plus/connectivity_plus.dart';

part 'message_provider.g.dart';

// Message State with offline support
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

@riverpod
class MessageNotifier extends _$MessageNotifier {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  ChatDatabaseHelper get _dbHelper => ChatDatabaseHelper();
  static const Uuid _uuid = Uuid();

  @override
  FutureOr<MessageState> build(String chatId) async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const MessageState(error: 'User not authenticated');
    }

    // Check connectivity status
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    // Load participant details
    await _loadParticipantDetails(chatId);

    // Start listening to messages stream (offline-first)
    _subscribeToMessages(chatId);
    
    // Load pinned messages
    await _loadPinnedMessages(chatId);
    
    // Start connectivity monitoring
    _monitorConnectivity(chatId);
    
    // Trigger sync if online
    if (isOnline) {
      _syncMessages(chatId);
    }
    
    return MessageState(
      isLoading: true,
      isOnline: isOnline,
    );
  }

  Future<void> _loadParticipantDetails(String chatId) async {
    try {
      // First check local cache
      final participants = await _dbHelper.getChatParticipants(chatId);
      final Map<String, String> participantNames = {};
      final Map<String, String> participantImages = {};

      for (final participant in participants) {
        participantNames[participant['userId']] = participant['userName'] ?? 'Unknown';
        participantImages[participant['userId']] = participant['userImage'] ?? '';
      }

      // If we have cached data, use it immediately
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
              
              // Cache the participant
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
            debugPrint('Error loading participant details for $userId: $e');
          }
        }

        final updatedState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(updatedState.copyWith(
          participantNames: participantNames,
          participantImages: participantImages,
        ));
      }
    } catch (e) {
      debugPrint('Error loading participant details: $e');
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
    _repository.getMessagesStream(chatId).listen(
      (messages) {
        final currentState = state.valueOrNull ?? const MessageState();
        
        // Count pending and failed messages
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
      onError: (error) {
        debugPrint('Message stream error: $error');
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          error: error.toString(),
          isLoading: false,
        ));
      },
    );
  }

  void _monitorConnectivity(String chatId) {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final isOnline = result != ConnectivityResult.none;
      final currentState = state.valueOrNull;
      
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(isOnline: isOnline));
        
        // If we just came online, trigger sync and retry failed messages
        if (isOnline && !currentState.isOnline) {
          _syncMessages(chatId);
          _retryFailedMessages(chatId);
        }
      }
    } as void Function(List<ConnectivityResult> event)?);
  }

  Future<void> _syncMessages(String chatId) async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.isSyncing) return;
    
    try {
      state = AsyncValue.data(currentState.copyWith(isSyncing: true));
      
      await _repository.syncMessages(chatId);
      
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

  Future<void> _retryFailedMessages(String chatId) async {
    try {
      final failedMessages = await _dbHelper.getFailedMessages(chatId);
      
      for (final message in failedMessages) {
        await retryFailedMessage(chatId, message.messageId);
      }
    } catch (e) {
      debugPrint('Error retrying failed messages: $e');
    }
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

  Map<String, dynamic> _buildReplyMetadata(MessageModel? replyToMessage) {
    if (replyToMessage == null) return {};
    
    final metadata = <String, dynamic>{};
    metadata['replyToType'] = replyToMessage.type.name;
    
    if (replyToMessage.hasMedia()) {
      metadata['replyToMediaUrl'] = replyToMessage.mediaUrl;
    }
    
    return metadata;
  }

  // ========================================
  // MESSAGE SENDING (OFFLINE-FIRST)
  // ========================================

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

      // Optimistically add to local state
      final updatedMessages = [message, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearReply: true,
        clearError: true,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));

      // Send via repository (offline-first)
      final messageId = await _repository.sendMessage(message);
      
      // Update local state with sent status
      _updateMessageStatus(chatId, messageId, MessageStatus.sent);
      
    } catch (e) {
      debugPrint('Error sending message: $e');
      
      final currentState = state.valueOrNull;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(
          error: 'Failed to send message: $e',
        ));
      }
    }
  }

  Future<void> sendImageMessage(String chatId, File imageFile, {String? caption}) async {
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
      final fileSize = await imageFile.length();
      if (fileSize > 50 * 1024 * 1024) {
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'Image size exceeds 50MB limit',
        ));
        return;
      }

      final fileName = '${_uuid.v4()}.jpg';
      final currentState = state.valueOrNull ?? const MessageState();
      final replyMetadata = _buildReplyMetadata(currentState.replyToMessage);
      
      final imageMetadata = {
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': 'image/jpeg',
        'isUploading': true,
        ...replyMetadata,
      };
      
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

      // Add to local state immediately
      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearReply: true,
        clearError: true,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));
      
      // Upload image
      final authNotifier = ref.read(authenticationProvider.notifier);
      final imageUrl = await authNotifier.storeFileToStorage(
        file: imageFile,
        reference: 'chat_media/$chatId/$fileName',
      );
      
      // Create final message with URL
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

      // Send via repository
      await _repository.sendMessage(finalMessage);
      
    } catch (e) {
      debugPrint('Error sending image: $e');
      
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send image: $e',
      ));
    }
  }

  Future<void> sendVideoMessage(String chatId, File videoFile, {String? caption}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    if (!videoFile.existsSync()) {
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Video file not found'));
      return;
    }

    try {
      final fileSize = await videoFile.length();
      if (fileSize > 100 * 1024 * 1024) {
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(error: 'Video size exceeds 100MB limit'));
        return;
      }

      final fileName = '${_uuid.v4()}.mp4';
      final currentState = state.valueOrNull ?? const MessageState();
      final replyMetadata = _buildReplyMetadata(currentState.replyToMessage);
      
      final videoMetadata = {
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': 'video/mp4',
        'isUploading': true,
        'duration': 0,
        ...replyMetadata,
      };
      
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

      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearReply: true,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));
      
      final authNotifier = ref.read(authenticationProvider.notifier);
      final videoUrl = await authNotifier.storeFileToStorage(
        file: videoFile,
        reference: 'chat_media/$chatId/$fileName',
      );
      
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

      await _repository.sendMessage(finalMessage);
      
    } catch (e) {
      debugPrint('Error sending video: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to send video: $e'));
    }
  }

  Future<void> sendFileMessage(String chatId, File file, String fileName) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    if (!file.existsSync()) {
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'File not found'));
      return;
    }

    if (fileName.trim().isEmpty) return;

    try {
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) {
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(error: 'File size exceeds 50MB limit'));
        return;
      }

      final currentState = state.valueOrNull ?? const MessageState();
      final replyMetadata = _buildReplyMetadata(currentState.replyToMessage);
      
      final fileMetadata = {
        'fileName': fileName,
        'fileSize': fileSize,
        'isUploading': true,
        ...replyMetadata,
      };

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

      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearReply: true,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));
      
      final authNotifier = ref.read(authenticationProvider.notifier);
      final fileUrl = await authNotifier.storeFileToStorage(
        file: file,
        reference: 'chat_media/$chatId/$fileName',
      );
      
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

      await _repository.sendMessage(finalMessage);
      
    } catch (e) {
      debugPrint('Error sending file: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to send file: $e'));
    }
  }

  Future<void> sendAudioMessage(String chatId, File audioFile, {Duration? duration}) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    if (!audioFile.existsSync()) {
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Audio file not found'));
      return;
    }

    try {
      final fileSize = await audioFile.length();
      if (fileSize > 25 * 1024 * 1024) {
        final currentState = state.valueOrNull ?? const MessageState();
        state = AsyncValue.data(currentState.copyWith(error: 'Audio size exceeds 25MB limit'));
        return;
      }

      final fileName = '${_uuid.v4()}.m4a';
      final currentState = state.valueOrNull ?? const MessageState();
      final replyMetadata = _buildReplyMetadata(currentState.replyToMessage);
      
      final audioMetadata = {
        'fileName': fileName,
        'fileSize': fileSize,
        'mimeType': 'audio/m4a',
        'isUploading': true,
        'duration': duration?.inSeconds ?? 0,
        'isVoiceNote': true,
        ...replyMetadata,
      };
      
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

      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearReply: true,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));
      
      final authNotifier = ref.read(authenticationProvider.notifier);
      final audioUrl = await authNotifier.storeFileToStorage(
        file: audioFile,
        reference: 'chat_media/$chatId/$fileName',
      );
      
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

      await _repository.sendMessage(finalMessage);
      
    } catch (e) {
      debugPrint('Error sending audio: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to send audio: $e'));
    }
  }

  Future<void> sendLocationMessage(String chatId, double latitude, double longitude, {String? address}) async {
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

      final updatedMessages = [message, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearError: true,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));

      await _repository.sendMessage(message);
      
    } catch (e) {
      debugPrint('Error sending location: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to send location: $e'));
    }
  }

  Future<void> sendContactMessage(String chatId, String contactName, String contactPhone) async {
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

      final updatedMessages = [message, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearError: true,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));

      await _repository.sendMessage(message);
      
    } catch (e) {
      debugPrint('Error sending contact: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to send contact: $e'));
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

  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    if (newContent.trim().isEmpty) return;

    try {
      await _repository.editMessage(chatId, messageId, newContent.trim());
    } catch (e) {
      debugPrint('Error editing message: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to edit message: $e'));
    }
  }

  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    try {
      await _repository.deleteMessage(chatId, messageId, deleteForEveryone);
    } catch (e) {
      debugPrint('Error deleting message: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to delete message: $e'));
    }
  }

  Future<void> togglePinMessage(String chatId, String messageId, bool isPinned) async {
    try {
      if (isPinned) {
        await _repository.unpinMessage(chatId, messageId);
      } else {
        final currentState = state.valueOrNull;
        if (currentState != null && currentState.pinnedMessages.length >= 10) {
          state = AsyncValue.data(currentState.copyWith(error: 'Maximum 10 messages can be pinned'));
          return;
        }
        
        await _repository.pinMessage(chatId, messageId);
      }
      
      await _loadPinnedMessages(chatId);
      
    } catch (e) {
      debugPrint('Error toggling pin message: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to ${isPinned ? 'unpin' : 'pin'} message: $e'));
    }
  }

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

  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    if (query.trim().isEmpty) return [];

    try {
      return await _repository.searchMessages(chatId, query.trim());
    } catch (e) {
      debugPrint('Error searching messages: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to search messages: $e'));
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

    final currentState = state.valueOrNull;
    if (currentState == null) return;

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
        failedMessagesCount: currentState.failedMessagesCount - 1,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));

      // Retry sending
      await _repository.sendMessage(failedMessage.copyWith(status: MessageStatus.sending));
      
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
          failedMessagesCount: latestState.failedMessagesCount + 1,
          pendingMessagesCount: latestState.pendingMessagesCount - 1,
        ));
      }
    }
  }

  Future<void> loadMoreMessages(String chatId) async {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.isLoading || !currentState.hasMore) {
      return;
    }

    try {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));
      
      // Load older messages from local database
      final olderMessages = await _dbHelper.getChatMessages(
        chatId, 
        limit: 50,
      );
      
      // Check if we have more messages
      final hasMore = olderMessages.length >= 50;
      
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        hasMore: hasMore,
      ));
      
    } catch (e) {
      debugPrint('Error loading more messages: $e');
      
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: 'Failed to load more messages: $e',
      ));
    }
  }

  void setTyping(String chatId, bool isTyping) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(isTyping: isTyping));
    }
    
    // Update typing status on server
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId != null) {
      _repository.updateUserTypingStatus(chatId, currentUserId, isTyping).catchError((e) {
        debugPrint('Error updating typing status: $e');
      });
    }
  }

  Future<void> reactToMessage(String chatId, String messageId, String emoji) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedMessages = currentState.messages.map((msg) {
          if (msg.messageId == messageId) {
            final reactions = Map<String, String>.from(msg.reactions ?? {});
            
            if (reactions[currentUser.uid] == emoji) {
              reactions.remove(currentUser.uid);
            } else {
              reactions[currentUser.uid] = emoji;
            }
            
            return msg.copyWith(reactions: reactions);
          }
          return msg;
        }).toList();

        state = AsyncValue.data(currentState.copyWith(messages: updatedMessages));
      }

      await _repository.addMessageReaction(chatId, messageId, currentUser.uid, emoji);
      
    } catch (e) {
      debugPrint('Error reacting to message: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to react to message: $e'));
    }
  }

  Future<void> forwardMessage(MessageModel message, String toChatId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
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

      await _repository.sendMessage(forwardedMessage);
      
    } catch (e) {
      debugPrint('Error forwarding message: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to forward message: $e'));
    }
  }

  Future<void> addMessageReaction(String chatId, String messageId, String emoji) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
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

        state = AsyncValue.data(currentState.copyWith(messages: updatedMessages));
      }

      await _repository.addMessageReaction(chatId, messageId, currentUser.uid, emoji);
      
    } catch (e) {
      debugPrint('Error adding message reaction: $e');
    }
  }

  Future<void> removeMessageReaction(String chatId, String messageId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
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

        state = AsyncValue.data(currentState.copyWith(messages: updatedMessages));
      }

      await _repository.removeMessageReaction(chatId, messageId, currentUser.uid);
      
    } catch (e) {
      debugPrint('Error removing message reaction: $e');
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  Future<void> _updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedMessages = currentState.messages.map((msg) {
      if (msg.messageId == messageId) {
        return msg.copyWith(status: status);
      }
      return msg;
    }).toList();

    // Update pending/failed counts
    int pendingCount = 0;
    int failedCount = 0;
    for (final msg in updatedMessages) {
      if (msg.status == MessageStatus.sending) pendingCount++;
      if (msg.status == MessageStatus.failed) failedCount++;
    }

    state = AsyncValue.data(currentState.copyWith(
      messages: updatedMessages,
      pendingMessagesCount: pendingCount,
      failedMessagesCount: failedCount,
    ));
  }

  List<MessageModel> getMessagesByType(MessageEnum type) {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => msg.type == type).toList();
  }

  List<MessageModel> getMessagesFromUser(String userId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => msg.senderId == userId).toList();
  }

  List<MessageModel> getFailedMessages() {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => msg.status == MessageStatus.failed).toList();
  }

  Future<void> retryAllFailedMessages(String chatId) async {
    final failedMessages = getFailedMessages();
    if (failedMessages.isEmpty) return;

    for (final message in failedMessages) {
      await retryFailedMessage(chatId, message.messageId);
    }
  }

  String exportMessagesAsText() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.messages.isEmpty) return '';

    final buffer = StringBuffer();
    final sortedMessages = List<MessageModel>.from(currentState.messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final message in sortedMessages) {
      final senderName = getParticipantName(message.senderId);
      final timestamp = message.timestamp.toLocal().toString().split('.')[0];
      
      buffer.writeln('[$timestamp] $senderName: ${message.getDisplayContent()}');
      
      if (message.isReply() && message.replyToContent != null) {
        buffer.writeln('  └─ Replied to: ${message.replyToContent}');
      }
    }

    return buffer.toString();
  }

  void clearLocalMessages() {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(
        messages: [],
        pinnedMessages: [],
        clearReply: true,
        clearError: true,
        pendingMessagesCount: 0,
        failedMessagesCount: 0,
      ));
    }
  }

  Map<MessageStatus, int> getMessageCountByStatus() {
    final currentState = state.valueOrNull;
    if (currentState == null) return {};

    final counts = <MessageStatus, int>{};
    for (final status in MessageStatus.values) {
      counts[status] = currentState.messages.where((msg) => msg.status == status).length;
    }
    return counts;
  }

  bool messageExists(String messageId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return false;

    return currentState.messages.any((msg) => msg.messageId == messageId);
  }

  MessageModel? getMessageById(String messageId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return null;

    try {
      return currentState.messages.firstWhere((msg) => msg.messageId == messageId);
    } catch (e) {
      return null;
    }
  }

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
        'pendingMessages': 0,
        'failedMessages': 0,
      };
    }

    final currentUserId = ref.read(currentUserIdProvider);
    final totalMessages = currentState.messages.length;
    final textMessages = currentState.messages.where((msg) => msg.type == MessageEnum.text).length;
    final imageMessages = currentState.messages.where((msg) => msg.type == MessageEnum.image).length;
    final videoMessages = currentState.messages.where((msg) => msg.type == MessageEnum.video).length;
    final audioMessages = currentState.messages.where((msg) => msg.type == MessageEnum.audio).length;
    final fileMessages = currentState.messages.where((msg) => msg.type == MessageEnum.file).length;
    final pinnedMessages = currentState.pinnedMessages.length;
    final myMessages = currentUserId != null 
        ? currentState.messages.where((msg) => msg.senderId == currentUserId).length 
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
      'pendingMessages': currentState.pendingMessagesCount,
      'failedMessages': currentState.failedMessagesCount,
    };
  }

  Future<void> refreshParticipants(String chatId) async {
    await _loadParticipantDetails(chatId);
  }

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

  Future<void> deleteMultipleMessages(String chatId, List<String> messageIds, bool deleteForEveryone) async {
    if (messageIds.isEmpty) return;

    try {
      final futures = messageIds.map((messageId) => 
          _repository.deleteMessage(chatId, messageId, deleteForEveryone));

      await Future.wait(futures);
      
    } catch (e) {
      debugPrint('Error deleting multiple messages: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(error: 'Failed to delete messages: $e'));
    }
  }

  MessageModel? get latestMessage {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.messages.isEmpty) return null;

    return currentState.messages.first;
  }

  bool get hasMediaMessages {
    final currentState = state.valueOrNull;
    if (currentState == null) return false;

    return currentState.messages.any((msg) => 
        msg.type == MessageEnum.image || 
        msg.type == MessageEnum.video || 
        msg.type == MessageEnum.audio || 
        msg.type == MessageEnum.file);
  }

  List<MessageModel> get mediaMessages {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => 
        msg.type == MessageEnum.image || 
        msg.type == MessageEnum.video || 
        msg.type == MessageEnum.audio || 
        msg.type == MessageEnum.file).toList();
  }

  List<MessageModel> get textMessages {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => msg.type == MessageEnum.text).toList();
  }

  List<MessageModel> get messagesWithReactions {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => msg.hasReactions()).toList();
  }

  List<MessageModel> get replyMessages {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => msg.isReply()).toList();
  }

  int getUnreadMessagesCount() {
    final currentState = state.valueOrNull;
    if (currentState == null) return 0;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return 0;

    return currentState.messages.where((msg) => 
        msg.senderId != currentUserId && !msg.isReadBy(currentUserId)).length;
  }

  Future<void> markAllMessagesAsRead(String chatId) async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final unreadMessages = currentState.messages.where((msg) => 
        msg.senderId != currentUserId && !msg.isReadBy(currentUserId)).toList();

    if (unreadMessages.isEmpty) return;

    try {
      await markMessagesAsDelivered(chatId, unreadMessages.map((msg) => msg.messageId).toList());
    } catch (e) {
      debugPrint('Error marking all messages as read: $e');
    }
  }

  List<MessageModel> get todaysMessages {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return currentState.messages.where((msg) => 
        msg.timestamp.isAfter(startOfDay) && msg.timestamp.isBefore(endOfDay)).toList();
  }

  List<MessageModel> get thisWeeksMessages {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekMidnight = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    return currentState.messages.where((msg) => 
        msg.timestamp.isAfter(startOfWeekMidnight)).toList();
  }

  bool get isCurrentlyTyping {
    final currentState = state.valueOrNull;
    return currentState?.isTyping ?? false;
  }

  int get sendingMessagesCount {
    final currentState = state.valueOrNull;
    return currentState?.pendingMessagesCount ?? 0;
  }

  int get failedMessagesCount {
    final currentState = state.valueOrNull;
    return currentState?.failedMessagesCount ?? 0;
  }

  bool get hasFailedMessages => failedMessagesCount > 0;
  bool get hasSendingMessages => sendingMessagesCount > 0;

  List<MessageModel> getMessagesByDateRange(DateTime start, DateTime end) {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((msg) => 
        msg.timestamp.isAfter(start) && msg.timestamp.isBefore(end)).toList();
  }

  List<MessageModel> getMessagesContaining(String text) {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    final searchText = text.toLowerCase();
    return currentState.messages.where((msg) => 
        msg.content.toLowerCase().contains(searchText)).toList();
  }

  // Offline/Online status
  bool get isOnline {
    final currentState = state.valueOrNull;
    return currentState?.isOnline ?? false;
  }

  bool get isSyncing {
    final currentState = state.valueOrNull;
    return currentState?.isSyncing ?? false;
  }

  DateTime? get lastSyncTime {
    final currentState = state.valueOrNull;
    return currentState?.lastSyncTime;
  }

  // Manual sync
  Future<void> syncMessages(String chatId) async {
    await _syncMessages(chatId);
  }

  void dispose() {
    debugPrint('MessageNotifier disposed for chat');
  }
}