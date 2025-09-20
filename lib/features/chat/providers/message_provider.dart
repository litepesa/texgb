// lib/features/chat/providers/message_provider.dart
// UPDATED: Complete WebSocket-based real-time message provider
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
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
// SIMPLIFIED MESSAGE STATE 
// ========================================

class MessageState {
  final bool isLoading;
  final List<MessageModel> messages;
  final String? error;
  final bool hasMore;
  final MessageModel? replyToMessage;
  final List<MessageModel> pinnedMessages;
  final Map<String, String> participantNames;
  final Map<String, String> participantImages;
  final bool isOnline;
  final Set<String> typingUsers;
  final int pendingMessagesCount;
  final int failedMessagesCount;

  const MessageState({
    this.isLoading = false,
    this.messages = const [],
    this.error,
    this.hasMore = true,
    this.replyToMessage,
    this.pinnedMessages = const [],
    this.participantNames = const {},
    this.participantImages = const {},
    this.isOnline = true,
    this.typingUsers = const {},
    this.pendingMessagesCount = 0,
    this.failedMessagesCount = 0,
  });

  MessageState copyWith({
    bool? isLoading,
    List<MessageModel>? messages,
    String? error,
    bool? hasMore,
    MessageModel? replyToMessage,
    List<MessageModel>? pinnedMessages,
    Map<String, String>? participantNames,
    Map<String, String>? participantImages,
    bool? isOnline,
    Set<String>? typingUsers,
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
      replyToMessage: clearReply ? null : (replyToMessage ?? this.replyToMessage),
      pinnedMessages: pinnedMessages ?? this.pinnedMessages,
      participantNames: participantNames ?? this.participantNames,
      participantImages: participantImages ?? this.participantImages,
      isOnline: isOnline ?? this.isOnline,
      typingUsers: typingUsers ?? this.typingUsers,
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
// SIMPLIFIED WEBSOCKET MESSAGE PROVIDER
// ========================================

@riverpod
class MessageNotifier extends _$MessageNotifier {
  ChatRepository get _repository => ref.read(chatRepositoryProvider);
  OfflineFirstChatRepository get _wsRepository => _repository as OfflineFirstChatRepository;
  ChatDatabaseHelper get _dbHelper => ChatDatabaseHelper();
  static const Uuid _uuid = Uuid();

  StreamSubscription<List<MessageModel>>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _typingTimer;

  @override
  FutureOr<MessageState> build(String chatId) async {
    // Cleanup on dispose
    ref.onDispose(() {
      debugPrint('🧹 MessageNotifier disposed for chat $chatId');
      _messageSubscription?.cancel();
      _typingSubscription?.cancel();
      _connectionSubscription?.cancel();
      _typingTimer?.cancel();
    });

    // Load participant details first
    await _loadParticipantDetails(chatId);

    // Load initial messages from database
    await _loadInitialMessages(chatId);

    // Set up real-time WebSocket listeners
    _setupRealTimeListeners(chatId);
    
    // Load pinned messages
    await _loadPinnedMessages(chatId);

    return MessageState(
      isLoading: false,
      isOnline: _wsRepository.isConnected,
    );
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

      // Try to fetch fresh data from server in background
      _fetchParticipantDetails(chatId);
    } catch (e) {
      debugPrint('❌ Error loading participant details: $e');
    }
  }

  void _fetchParticipantDetails(String chatId) {
    Future.microtask(() async {
      try {
        final chat = await _repository.getChatById(chatId);
        if (chat != null) {
          final authNotifier = ref.read(authenticationProvider.notifier);
          final Map<String, String> participantNames = {};
          final Map<String, String> participantImages = {};
          
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
            participantNames: {...updatedState.participantNames, ...participantNames},
            participantImages: {...updatedState.participantImages, ...participantImages},
          ));
        }
      } catch (e) {
        debugPrint('❌ Error fetching participant details: $e');
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

  Future<void> _loadInitialMessages(String chatId) async {
    try {
      final messages = await _dbHelper.getChatMessages(chatId);
      
      final currentState = state.valueOrNull ?? const MessageState();
      final pendingCount = messages.where((m) => m.status == MessageStatus.sending).length;
      final failedCount = messages.where((m) => m.status == MessageStatus.failed).length;
      
      state = AsyncValue.data(currentState.copyWith(
        messages: messages,
        isLoading: false,
        pendingMessagesCount: pendingCount,
        failedMessagesCount: failedCount,
        isOnline: _wsRepository.isConnected,
      ));

      debugPrint('📨 Loaded ${messages.length} messages for chat $chatId');
    } catch (e) {
      debugPrint('❌ Error loading messages: $e');
      state = AsyncValue.data(MessageState(error: e.toString()));
    }
  }

  void _setupRealTimeListeners(String chatId) {
    debugPrint('📡 Setting up real-time listeners for chat: $chatId');

    // Real-time messages via WebSocket (replaces complex polling)
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

        debugPrint('📨 Messages updated via WebSocket: ${messages.length}');
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

    // Real-time typing indicators via WebSocket
    _typingSubscription?.cancel();
    _typingSubscription = _wsRepository.typingStream
        .where((data) => data['chatId'] == chatId)
        .listen(_handleTypingStatus);

    // WebSocket connection status
    _connectionSubscription?.cancel();
    _connectionSubscription = _wsRepository.connectionStream.listen((isConnected) {
      final currentState = state.valueOrNull;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(isOnline: isConnected));
        debugPrint('🔌 Message provider connection status: $isConnected');
      }
    });
  }

  void _handleTypingStatus(Map<String, dynamic> data) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final userId = data['userId'] as String;
    final isTyping = data['isTyping'] as bool;
    final currentUserId = ref.read(currentUserIdProvider);

    // Don't show own typing status
    if (userId == currentUserId) return;

    final updatedTypingUsers = Set<String>.from(currentState.typingUsers);
    
    if (isTyping) {
      updatedTypingUsers.add(userId);
    } else {
      updatedTypingUsers.remove(userId);
    }

    state = AsyncValue.data(currentState.copyWith(typingUsers: updatedTypingUsers));
    debugPrint('⌨️ Typing status updated: $userId -> $isTyping');
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
  // MESSAGE SENDING - SIMPLIFIED WITH WEBSOCKET
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
        replyToMessageId: currentState.replyToMessage?.messageId,
        replyToContent: currentState.replyToMessage?.getDisplayContent(),
        replyToSender: currentState.replyToMessage?.senderId,
      );

      // Optimistic update - add message immediately to UI
      final updatedMessages = [message, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        clearReply: true,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));

      // Send via WebSocket repository
      await _repository.sendMessage(message);
      
      debugPrint('✅ Text message sent via WebSocket');
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
      
      // Create temporary message with uploading status
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

      // Optimistic update
      final currentState = state.valueOrNull ?? const MessageState();
      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));

      // Upload image using auth provider's file storage
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

      // Send via WebSocket repository
      await _repository.sendMessage(finalMessage);
      
      debugPrint('✅ Image message sent via WebSocket');
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

      // Optimistic update
      final currentState = state.valueOrNull ?? const MessageState();
      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));

      // Upload video
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
      
      debugPrint('✅ Video message sent via WebSocket');
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

      // Optimistic update
      final currentState = state.valueOrNull ?? const MessageState();
      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));

      // Upload file
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
      
      debugPrint('✅ File message sent via WebSocket');
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

      // Optimistic update
      final currentState = state.valueOrNull ?? const MessageState();
      final updatedMessages = [tempMessage, ...currentState.messages];
      state = AsyncValue.data(currentState.copyWith(
        messages: updatedMessages,
        pendingMessagesCount: currentState.pendingMessagesCount + 1,
      ));

      // Upload audio
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
      
      debugPrint('✅ Audio message sent via WebSocket');
    } catch (e) {
      debugPrint('❌ Error sending audio: $e');
      
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to send audio',
      ));
    }
  }

  // ========================================
  // MESSAGE OPERATIONS - SIMPLIFIED
  // ========================================

  void setReplyToMessage(MessageModel message) {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(
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
      debugPrint('✅ Message edited via WebSocket');
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
      debugPrint('✅ Message deleted via WebSocket');
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
      debugPrint('✅ Message pin toggled via WebSocket');
    } catch (e) {
      debugPrint('❌ Error toggling pin: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to ${isPinned ? 'unpin' : 'pin'} message',
      ));
    }
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
        // Resend via WebSocket
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
  // TYPING INDICATORS - WEBSOCKET BASED
  // ========================================

  Future<void> sendTypingStatus(bool isTyping) async {
    await _wsRepository.sendTypingStatus(chatId, isTyping);
    
    // Auto-stop typing after 3 seconds
    if (isTyping) {
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _wsRepository.sendTypingStatus(chatId, false);
      });
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  Future<void> markAsRead() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    await _repository.markChatAsRead(chatId, currentUserId);
    
    // Notify chat list to refresh
    ref.invalidate(chatListProvider);
  }

  Future<void> syncMessages(String chatId) async {
    try {
      await _repository.syncMessages(chatId);
      debugPrint('✅ Messages synced manually');
    } catch (e) {
      debugPrint('❌ Error syncing messages: $e');
    }
  }

  // ========================================
  // GETTERS - SIMPLIFIED
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
  bool get isConnected => _wsRepository.isConnected;
  
  Set<String> get typingUsers {
    final currentState = state.valueOrNull;
    return currentState?.typingUsers ?? {};
  }

  MessageModel? get replyToMessage {
    final currentState = state.valueOrNull;
    return currentState?.replyToMessage;
  }

  bool get isOnline {
    final currentState = state.valueOrNull;
    return currentState?.isOnline ?? false;
  }

  int get pendingMessagesCount {
    final currentState = state.valueOrNull;
    return currentState?.pendingMessagesCount ?? 0;
  }

  int get failedMessagesCount {
    final currentState = state.valueOrNull;
    return currentState?.failedMessagesCount ?? 0;
  }

  List<MessageModel> get pinnedMessages {
    final currentState = state.valueOrNull;
    return currentState?.pinnedMessages ?? [];
  }

  Map<String, dynamic> getMessageStatistics() {
    final currentState = state.valueOrNull;
    
    if (currentState == null) {
      return {
        'totalMessages': 0,
        'pendingMessages': 0,
        'failedMessages': 0,
        'pinnedMessages': 0,
        'typingUsers': 0,
        'isOnline': false,
        'connectionType': 'websocket',
      };
    }

    return {
      'totalMessages': currentState.messages.length,
      'pendingMessages': currentState.pendingMessagesCount,
      'failedMessages': currentState.failedMessagesCount,
      'pinnedMessages': currentState.pinnedMessages.length,
      'typingUsers': currentState.typingUsers.length,
      'isOnline': currentState.isOnline,
      'connectionType': 'websocket',
    };
  }

  // Reconnection helper
  Future<bool> reconnectIfNeeded() async {
    if (!isConnected) {
      return await _wsRepository.reconnect();
    }
    return isConnected;
  }

  // ========================================
  // ADVANCED MESSAGE OPERATIONS
  // ========================================

  /// Forward a message to another chat
  Future<void> forwardMessage(String messageId, String targetChatId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final originalMessage = await _dbHelper.getMessageById(messageId);
      if (originalMessage == null) return;

      final forwardedMessage = MessageModel(
        messageId: _uuid.v4(),
        chatId: targetChatId,
        senderId: currentUser.uid,
        content: originalMessage.content,
        type: originalMessage.type,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaUrl: originalMessage.mediaUrl,
        mediaMetadata: {
          ...?originalMessage.mediaMetadata,
          'isForwarded': true,
          'originalSender': originalMessage.senderId,
          'originalTimestamp': originalMessage.timestamp.toIso8601String(),
        },
      );

      await _repository.sendMessage(forwardedMessage);
      debugPrint('✅ Message forwarded via WebSocket');
    } catch (e) {
      debugPrint('❌ Error forwarding message: $e');
      final currentState = state.valueOrNull ?? const MessageState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to forward message',
      ));
    }
  }

  /// Add reaction to a message
  Future<void> addReaction(String messageId, String emoji) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final message = await _dbHelper.getMessageById(messageId);
      if (message == null) return;

      final updatedReactions = Map<String, String>.from(message.reactions ?? {});
      updatedReactions[currentUser.uid] = emoji;

      final updatedMessage = message.copyWith(reactions: updatedReactions);
      await _dbHelper.insertOrUpdateMessage(updatedMessage);

      // Update UI immediately
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedMessages = currentState.messages.map((m) {
          if (m.messageId == messageId) {
            return updatedMessage;
          }
          return m;
        }).toList();

        state = AsyncValue.data(currentState.copyWith(messages: updatedMessages));
      }

      debugPrint('✅ Reaction added to message: $messageId');
    } catch (e) {
      debugPrint('❌ Error adding reaction: $e');
    }
  }

  /// Remove reaction from a message
  Future<void> removeReaction(String messageId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final message = await _dbHelper.getMessageById(messageId);
      if (message == null) return;

      final updatedReactions = Map<String, String>.from(message.reactions ?? {});
      updatedReactions.remove(currentUser.uid);

      final updatedMessage = message.copyWith(
        reactions: updatedReactions.isEmpty ? null : updatedReactions,
      );
      await _dbHelper.insertOrUpdateMessage(updatedMessage);

      // Update UI immediately
      final currentState = state.valueOrNull;
      if (currentState != null) {
        final updatedMessages = currentState.messages.map((m) {
          if (m.messageId == messageId) {
            return updatedMessage;
          }
          return m;
        }).toList();

        state = AsyncValue.data(currentState.copyWith(messages: updatedMessages));
      }

      debugPrint('✅ Reaction removed from message: $messageId');
    } catch (e) {
      debugPrint('❌ Error removing reaction: $e');
    }
  }

  /// Get messages by type (e.g., only images, videos, etc.)
  List<MessageModel> getMessagesByType(MessageEnum type) {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((message) => message.type == type).toList();
  }

  /// Get media messages (images, videos, files)
  List<MessageModel> getMediaMessages() {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    return currentState.messages.where((message) => 
      message.type == MessageEnum.image ||
      message.type == MessageEnum.video ||
      message.type == MessageEnum.file ||
      message.type == MessageEnum.audio
    ).toList();
  }

  /// Get unread messages count for current user
  int getUnreadMessagesCount() {
    final currentState = state.valueOrNull;
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentState == null || currentUserId == null) return 0;

    return currentState.messages.where((message) => 
      message.senderId != currentUserId && 
      !(message.readBy?.containsKey(currentUserId) ?? false)
    ).length;
  }

  /// Mark specific message as read
  Future<void> markMessageAsRead(String messageId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final message = await _dbHelper.getMessageById(messageId);
      if (message == null) return;

      final updatedReadBy = Map<String, DateTime>.from(message.readBy ?? {});
      updatedReadBy[currentUser.uid] = DateTime.now();

      final updatedMessage = message.copyWith(readBy: updatedReadBy);
      await _dbHelper.insertOrUpdateMessage(updatedMessage);

      debugPrint('✅ Message marked as read: $messageId');
    } catch (e) {
      debugPrint('❌ Error marking message as read: $e');
    }
  }

  /// Get typing users as formatted string
  String getTypingUsersText() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.typingUsers.isEmpty) return '';

    final typingNames = currentState.typingUsers
        .map((userId) => currentState.getParticipantName(userId))
        .toList();

    if (typingNames.length == 1) {
      return '${typingNames.first} is typing...';
    } else if (typingNames.length == 2) {
      return '${typingNames[0]} and ${typingNames[1]} are typing...';
    } else {
      return 'Several people are typing...';
    }
  }

  /// Check if current user can edit a message
  bool canEditMessage(MessageModel message) {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return false;

    // Only sender can edit
    if (message.senderId != currentUserId) return false;

    // Only text messages can be edited
    if (message.type != MessageEnum.text) return false;

    // Can't edit if already edited (optional restriction)
    // if (message.isEdited) return false;

    // Can't edit messages older than 24 hours
    final now = DateTime.now();
    final timeDifference = now.difference(message.timestamp);
    if (timeDifference.inHours > 24) return false;

    return true;
  }

  /// Check if current user can delete a message
  bool canDeleteMessage(MessageModel message) {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return false;

    // Sender can always delete their own messages
    if (message.senderId == currentUserId) return true;

    // For now, only senders can delete messages
    // In the future, you might add admin permissions here
    return false;
  }

  /// Get message status icon
  String getMessageStatusIcon(MessageModel message) {
    final currentUserId = ref.read(currentUserIdProvider);
    
    // Only show status for own messages
    if (message.senderId != currentUserId) return '';

    switch (message.status) {
      case MessageStatus.sending:
        return '⏳';
      case MessageStatus.sent:
        return '✓';
      case MessageStatus.delivered:
        return '✓✓';
      case MessageStatus.read:
        return '✓✓'; // Could use blue checkmarks
      case MessageStatus.failed:
        return '❌';
    }
  }

  /// Export chat messages to text
  String exportChatToText() {
    final currentState = state.valueOrNull;
    if (currentState == null || currentState.messages.isEmpty) {
      return 'No messages to export';
    }

    final buffer = StringBuffer();
    buffer.writeln('Chat Export - ${DateTime.now().toString()}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    // Sort messages by timestamp (oldest first for export)
    final sortedMessages = List<MessageModel>.from(currentState.messages)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final message in sortedMessages) {
      final senderName = currentState.getParticipantName(message.senderId);
      final timestamp = message.timestamp.toString().substring(0, 19);
      
      buffer.writeln('[$timestamp] $senderName:');
      
      if (message.type == MessageEnum.text) {
        buffer.writeln('  ${message.content}');
      } else {
        buffer.writeln('  [${message.type.name.toUpperCase()}] ${message.getDisplayContent()}');
      }
      
      if (message.replyToContent != null) {
        buffer.writeln('  (Reply to: ${message.replyToContent})');
      }
      
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Clear all error states
  void clearAllErrors() {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(clearError: true));
    }
  }

  /// Force refresh messages from server
  Future<void> forceRefreshMessages() async {
    try {
      await syncMessages(chatId);
      await _loadInitialMessages(chatId);
      debugPrint('✅ Messages force refreshed');
    } catch (e) {
      debugPrint('❌ Error force refreshing messages: $e');
    }
  }

  /// Get detailed connection info
  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': isConnected,
      'isOnline': isOnline,
      'connectionType': 'websocket',
      'chatId': chatId,
      'hasMessages': (state.valueOrNull?.messages.length ?? 0) > 0,
      'typingUsers': typingUsers.length,
      'pendingMessages': pendingMessagesCount,
      'failedMessages': failedMessagesCount,
      'lastUpdate': DateTime.now().toIso8601String(),
    };
  }
}