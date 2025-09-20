// lib/features/chat/repositories/chat_repository.dart
// UPDATED: WebSocket-first chat repository - simplified with real-time capabilities
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/models/video_reaction_model.dart';
import 'package:textgb/features/chat/models/moment_reaction_model.dart';
import 'package:textgb/features/chat/database/chat_database_helper.dart';
import 'package:textgb/features/chat/services/websocket_chat_service.dart';
import 'package:textgb/shared/services/http_client.dart';
import 'package:textgb/shared/utilities/datetime_helper.dart';
import 'package:uuid/uuid.dart';

// ========================================
// ABSTRACT REPOSITORY INTERFACE (unchanged)
// ========================================

abstract class ChatRepository {
  // Chat operations
  Future<String> createOrGetChat(String currentUserId, String otherUserId);
  Stream<List<ChatModel>> getChatsStream(String userId);
  Future<ChatModel?> getChatById(String chatId);
  Future<void> updateChatLastMessage(ChatModel chat);
  Future<void> markChatAsRead(String chatId, String userId);
  Future<void> toggleChatPin(String chatId, String userId);
  Future<void> toggleChatArchive(String chatId, String userId);
  Future<void> toggleChatMute(String chatId, String userId);
  Future<void> deleteChat(String chatId, String userId, {bool deleteForEveryone = false});
  Future<void> clearChatHistory(String chatId, String userId);

  // Message operations
  Future<String> sendMessage(MessageModel message);
  Future<String> sendVideoMessage({
    required String chatId,
    required String senderId,
    required String videoUrl,
    required String thumbnailUrl,
    required String videoId,
  });
  Future<String> sendVideoReactionMessage({
    required String chatId,
    required String senderId,
    required VideoReactionModel videoReaction,
  });
  Future<String> sendMomentReactionMessage({
    required String chatId,
    required String senderId,
    required MomentReactionModel momentReaction,
  });
  Stream<List<MessageModel>> getMessagesStream(String chatId);
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status);
  Future<void> editMessage(String chatId, String messageId, String newContent);
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone);
  Future<void> pinMessage(String chatId, String messageId);
  Future<void> unpinMessage(String chatId, String messageId);
  Future<List<MessageModel>> searchMessages(String chatId, String query);
  Future<List<MessageModel>> getPinnedMessages(String chatId);

  // Utility
  String generateChatId(String userId1, String userId2);
  Future<void> syncMessages(String chatId);
  Future<void> syncAllData(String userId);
}

// ========================================
// WEBSOCKET-FIRST IMPLEMENTATION
// ========================================

class OfflineFirstChatRepository implements ChatRepository {
  final WebSocketChatService _wsService;
  final ChatDatabaseHelper _dbHelper;
  final HttpClientService _httpClient;
  static const Uuid _uuid = Uuid();

  // Simple state tracking
  bool _isInitialized = false;
  String? _currentUserId;

  // Stream controllers for local state management
  final StreamController<List<ChatModel>> _chatsController = 
      StreamController<List<ChatModel>>.broadcast();
  final Map<String, StreamController<List<MessageModel>>> _messageControllers = {};

  OfflineFirstChatRepository({
    WebSocketChatService? wsService,
    ChatDatabaseHelper? dbHelper,
    HttpClientService? httpClient,
  })  : _wsService = wsService ?? WebSocketChatService(),
        _dbHelper = dbHelper ?? ChatDatabaseHelper(),
        _httpClient = httpClient ?? HttpClientService();

  // ========================================
  // INITIALIZATION
  // ========================================

  /// Initialize the repository with user authentication
  Future<bool> initialize(String userId, String authToken) async {
    if (_isInitialized && _currentUserId == userId) {
      return true;
    }

    try {
      debugPrint('🔧 Initializing WebSocket chat repository for user: $userId');

      // Connect to WebSocket
      final connected = await _wsService.connect(userId, authToken);
      
      if (connected) {
        _currentUserId = userId;
        _isInitialized = true;
        
        // Load user's chats and join them
        await _loadAndJoinUserChats(userId);
        
        // Set up WebSocket listeners
        _setupWebSocketListeners();
        
        debugPrint('✅ WebSocket chat repository initialized successfully');
        return true;
      } else {
        debugPrint('❌ Failed to connect to WebSocket');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error initializing chat repository: $e');
      return false;
    }
  }

  /// Load user's chats from database and join them on WebSocket
  Future<void> _loadAndJoinUserChats(String userId) async {
    try {
      final chats = await _dbHelper.getUserChats(userId);
      if (chats.isNotEmpty) {
        final chatIds = chats.map((c) => c.chatId).toList();
        await _wsService.joinChats(chatIds);
        debugPrint('📱 Joined ${chatIds.length} existing chats on WebSocket');
      }
    } catch (e) {
      debugPrint('❌ Error loading and joining chats: $e');
    }
  }

  /// Set up WebSocket real-time listeners
  void _setupWebSocketListeners() {
    // Listen for new messages
    _wsService.messageStream.listen((messages) async {
      // Messages are now handled by WebSocket events, not this stream
      // This is kept for compatibility
    });

    // Listen for WebSocket errors
    _wsService.errorStream.listen((error) {
      debugPrint('❌ WebSocket error: ${error['message']}');
    });

    // Listen for connection changes
    _wsService.connectionStream.listen((isConnected) {
      debugPrint('🔌 WebSocket connection status: $isConnected');
      if (!isConnected) {
        // Handle reconnection logic if needed
      }
    });
  }

  /// Dispose and cleanup
  void dispose() {
    debugPrint('🧹 Disposing WebSocket chat repository');
    _wsService.disconnect();
    _chatsController.close();
    for (final controller in _messageControllers.values) {
      controller.close();
    }
    _messageControllers.clear();
    _isInitialized = false;
    _currentUserId = null;
  }

  // ========================================
  // CHAT OPERATIONS
  // ========================================

  @override
  String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  @override
  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    final chatId = generateChatId(currentUserId, otherUserId);
    
    try {
      // Check if chat exists locally
      var chat = await _dbHelper.getChatById(chatId);
      
      if (chat == null) {
        // Create new chat
        chat = ChatModel(
          chatId: chatId,
          participants: [currentUserId, otherUserId],
          lastMessage: '',
          lastMessageType: MessageEnum.text,
          lastMessageSender: '',
          lastMessageTime: DateTime.now(),
          unreadCounts: {currentUserId: 0, otherUserId: 0},
          isArchived: {currentUserId: false, otherUserId: false},
          isPinned: {currentUserId: false, otherUserId: false},
          isMuted: {currentUserId: false, otherUserId: false},
          createdAt: DateTime.now(),
        );

        // Save locally
        await _dbHelper.insertOrUpdateChat(chat);
        
        // Join on WebSocket
        if (_wsService.isConnected) {
          await _wsService.joinChats([chatId]);
        }
        
        debugPrint('✅ Created new chat: $chatId');
        
        // Refresh chats stream
        final chats = await _dbHelper.getUserChats(currentUserId);
        _chatsController.add(chats);
      }

      return chatId;
    } catch (e) {
      debugPrint('❌ Error creating/getting chat: $e');
      rethrow;
    }
  }

  @override
  Stream<List<ChatModel>> getChatsStream(String userId) {
    // Load initial data and start stream
    _loadInitialChats(userId);
    return _chatsController.stream;
  }

  Future<void> _loadInitialChats(String userId) async {
    try {
      final chats = await _dbHelper.getUserChats(userId);
      _chatsController.add(chats);
    } catch (e) {
      debugPrint('❌ Error loading initial chats: $e');
      _chatsController.addError(e);
    }
  }

  @override
  Future<ChatModel?> getChatById(String chatId) async {
    return await _dbHelper.getChatById(chatId);
  }

  @override
  Future<void> updateChatLastMessage(ChatModel chat) async {
    await _dbHelper.updateChatLastMessage(
      chatId: chat.chatId,
      lastMessage: chat.lastMessage,
      lastMessageType: chat.lastMessageType,
      lastMessageSender: chat.lastMessageSender,
      lastMessageTime: chat.lastMessageTime,
    );

    // Refresh chats stream
    if (_currentUserId != null) {
      final chats = await _dbHelper.getUserChats(_currentUserId!);
      _chatsController.add(chats);
    }
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      // Update locally
      await _dbHelper.markChatAsRead(chatId, userId);
      
      // Sync with server (fire and forget)
      _syncChatReadStatus(chatId, userId).catchError((e) {
        debugPrint('❌ Failed to sync read status: $e');
      });
      
      // Refresh chats stream
      final chats = await _dbHelper.getUserChats(userId);
      _chatsController.add(chats);
      
      debugPrint('✅ Marked chat as read: $chatId');
    } catch (e) {
      debugPrint('❌ Error marking chat as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleChatPin(String chatId, String userId) async {
    try {
      await _dbHelper.toggleChatPin(chatId, userId);
      
      // Refresh chats stream
      final chats = await _dbHelper.getUserChats(userId);
      _chatsController.add(chats);
      
      debugPrint('✅ Toggled chat pin: $chatId');
    } catch (e) {
      debugPrint('❌ Error toggling chat pin: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleChatArchive(String chatId, String userId) async {
    try {
      await _dbHelper.toggleChatArchive(chatId, userId);
      
      // Refresh chats stream
      final chats = await _dbHelper.getUserChats(userId);
      _chatsController.add(chats);
      
      debugPrint('✅ Toggled chat archive: $chatId');
    } catch (e) {
      debugPrint('❌ Error toggling chat archive: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleChatMute(String chatId, String userId) async {
    try {
      await _dbHelper.toggleChatMute(chatId, userId);
      
      // Refresh chats stream
      final chats = await _dbHelper.getUserChats(userId);
      _chatsController.add(chats);
      
      debugPrint('✅ Toggled chat mute: $chatId');
    } catch (e) {
      debugPrint('❌ Error toggling chat mute: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteChat(String chatId, String userId, {bool deleteForEveryone = false}) async {
    try {
      await _dbHelper.deleteChat(chatId, userId);
      
      // Leave WebSocket room
      if (_wsService.isConnected) {
        await _wsService.leaveChats([chatId]);
      }
      
      // Close message controller if exists
      if (_messageControllers.containsKey(chatId)) {
        _messageControllers[chatId]!.close();
        _messageControllers.remove(chatId);
      }
      
      // Refresh chats stream
      final chats = await _dbHelper.getUserChats(userId);
      _chatsController.add(chats);
      
      debugPrint('✅ Deleted chat: $chatId');
    } catch (e) {
      debugPrint('❌ Error deleting chat: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearChatHistory(String chatId, String userId) async {
    try {
      await _dbHelper.clearChatHistory(chatId);
      
      // Refresh message stream if exists
      if (_messageControllers.containsKey(chatId)) {
        final messages = await _dbHelper.getChatMessages(chatId);
        _messageControllers[chatId]!.add(messages);
      }
      
      debugPrint('✅ Cleared chat history: $chatId');
    } catch (e) {
      debugPrint('❌ Error clearing chat history: $e');
      rethrow;
    }
  }

  // ========================================
  // MESSAGE OPERATIONS - WEBSOCKET FIRST
  // ========================================

  @override
  Future<String> sendMessage(MessageModel message) async {
    try {
      final messageId = message.messageId.isEmpty ? _uuid.v4() : message.messageId;
      final finalMessage = message.copyWith(
        messageId: messageId,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
      );

      // Save locally first (optimistic update)
      await _dbHelper.insertOrUpdateMessage(finalMessage);

      // Update message stream immediately
      if (_messageControllers.containsKey(message.chatId)) {
        final messages = await _dbHelper.getChatMessages(message.chatId);
        _messageControllers[message.chatId]!.add(messages);
      }

      // Update chat last message
      await _dbHelper.updateChatLastMessage(
        chatId: finalMessage.chatId,
        lastMessage: finalMessage.getDisplayContent(),
        lastMessageType: finalMessage.type,
        lastMessageSender: finalMessage.senderId,
        lastMessageTime: finalMessage.timestamp,
      );

      // Refresh chats stream
      if (_currentUserId != null) {
        final chats = await _dbHelper.getUserChats(_currentUserId!);
        _chatsController.add(chats);
      }

      // Send via WebSocket
      final success = await _wsService.sendMessage(finalMessage);
      
      if (success) {
        // Update status to sent
        await _dbHelper.updateMessageStatus(messageId, MessageStatus.sent);
        debugPrint('✅ Message sent successfully: $messageId');
      } else {
        // Mark as failed
        await _dbHelper.updateMessageStatus(messageId, MessageStatus.failed);
        debugPrint('❌ Message failed to send: $messageId');
      }

      // Update message stream with final status
      if (_messageControllers.containsKey(message.chatId)) {
        final messages = await _dbHelper.getChatMessages(message.chatId);
        _messageControllers[message.chatId]!.add(messages);
      }

      return messageId;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      rethrow;
    }
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    // Create controller if doesn't exist
    if (!_messageControllers.containsKey(chatId)) {
      _messageControllers[chatId] = StreamController<List<MessageModel>>.broadcast();
    }

    // Load initial messages
    _loadInitialMessages(chatId);
    
    return _messageControllers[chatId]!.stream;
  }

  Future<void> _loadInitialMessages(String chatId) async {
    try {
      final messages = await _dbHelper.getChatMessages(chatId);
      if (_messageControllers.containsKey(chatId)) {
        _messageControllers[chatId]!.add(messages);
      }
    } catch (e) {
      debugPrint('❌ Error loading initial messages: $e');
      if (_messageControllers.containsKey(chatId)) {
        _messageControllers[chatId]!.addError(e);
      }
    }
  }

  @override
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    try {
      await _dbHelper.updateMessageStatus(messageId, status);
      
      // Update message stream
      if (_messageControllers.containsKey(chatId)) {
        final messages = await _dbHelper.getChatMessages(chatId);
        _messageControllers[chatId]!.add(messages);
      }
    } catch (e) {
      debugPrint('❌ Error updating message status: $e');
    }
  }

  @override
  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    try {
      await _dbHelper.editMessage(messageId, newContent);
      
      // Update message stream
      if (_messageControllers.containsKey(chatId)) {
        final messages = await _dbHelper.getChatMessages(chatId);
        _messageControllers[chatId]!.add(messages);
      }
      
      debugPrint('✅ Message edited: $messageId');
    } catch (e) {
      debugPrint('❌ Error editing message: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    try {
      await _dbHelper.deleteMessage(messageId);
      
      // Update message stream
      if (_messageControllers.containsKey(chatId)) {
        final messages = await _dbHelper.getChatMessages(chatId);
        _messageControllers[chatId]!.add(messages);
      }
      
      debugPrint('✅ Message deleted: $messageId');
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
      rethrow;
    }
  }

  @override
  Future<void> pinMessage(String chatId, String messageId) async {
    try {
      await _dbHelper.togglePinMessage(messageId);
      
      // Update message stream
      if (_messageControllers.containsKey(chatId)) {
        final messages = await _dbHelper.getChatMessages(chatId);
        _messageControllers[chatId]!.add(messages);
      }
      
      debugPrint('✅ Message pinned: $messageId');
    } catch (e) {
      debugPrint('❌ Error pinning message: $e');
      rethrow;
    }
  }

  @override
  Future<void> unpinMessage(String chatId, String messageId) async {
    try {
      await _dbHelper.togglePinMessage(messageId);
      
      // Update message stream
      if (_messageControllers.containsKey(chatId)) {
        final messages = await _dbHelper.getChatMessages(chatId);
        _messageControllers[chatId]!.add(messages);
      }
      
      debugPrint('✅ Message unpinned: $messageId');
    } catch (e) {
      debugPrint('❌ Error unpinning message: $e');
      rethrow;
    }
  }

  @override
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    return await _dbHelper.searchMessages(chatId, query);
  }

  @override
  Future<List<MessageModel>> getPinnedMessages(String chatId) async {
    return await _dbHelper.getPinnedMessages(chatId);
  }

  @override
  Future<String> sendVideoMessage({
    required String chatId,
    required String senderId,
    required String videoUrl,
    required String thumbnailUrl,
    required String videoId,
  }) async {
    final message = MessageModel(
      messageId: _uuid.v4(),
      chatId: chatId,
      senderId: senderId,
      content: '',
      type: MessageEnum.video,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      mediaUrl: videoUrl,
      mediaMetadata: {
        'isSharedVideo': true,
        'videoId': videoId,
        'thumbnailUrl': thumbnailUrl,
      },
    );

    return await sendMessage(message);
  }

  @override
  Future<String> sendVideoReactionMessage({
    required String chatId,
    required String senderId,
    required VideoReactionModel videoReaction,
  }) async {
    final message = MessageModel(
      messageId: _uuid.v4(),
      chatId: chatId,
      senderId: senderId,
      content: videoReaction.reaction ?? '',
      type: MessageEnum.text,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      mediaUrl: videoReaction.videoUrl,
      mediaMetadata: {
        'isVideoReaction': true,
        'videoReaction': videoReaction.toMap(),
        'thumbnailUrl': videoReaction.thumbnailUrl,
        'videoId': videoReaction.videoId,
        'userName': videoReaction.userName,
        'userImage': videoReaction.userImage,
      },
    );

    return await sendMessage(message);
  }

  @override
  Future<String> sendMomentReactionMessage({
    required String chatId,
    required String senderId,
    required MomentReactionModel momentReaction,
  }) async {
    final message = MessageModel(
      messageId: _uuid.v4(),
      chatId: chatId,
      senderId: senderId,
      content: momentReaction.reaction,
      type: MessageEnum.text,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
      mediaUrl: momentReaction.mediaUrl,
      mediaMetadata: {
        'isMomentReaction': true,
        'momentReaction': momentReaction.toMap(),
      },
    );

    return await sendMessage(message);
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  /// Check if WebSocket is connected
  bool get isConnected => _wsService.isConnected;

  /// Get current user ID
  String? get currentUserId => _currentUserId;

  /// Check if repository is initialized
  bool get isInitialized => _isInitialized;

  /// Send typing status
  Future<void> sendTypingStatus(String chatId, bool isTyping) async {
    if (_wsService.isConnected) {
      await _wsService.sendTypingStatus(chatId, isTyping);
    }
  }

  /// Get typing stream
  Stream<Map<String, dynamic>> get typingStream => _wsService.typingStream;

  /// Get user status stream
  Stream<Map<String, dynamic>> get userStatusStream => _wsService.userStatusStream;

  /// Get connection stream
  Stream<bool> get connectionStream => _wsService.connectionStream;

  // ========================================
  // SYNC OPERATIONS (Fallback only)
  // ========================================

  @override
  Future<void> syncMessages(String chatId) async {
    // WebSocket handles real-time sync, but keep for fallback
    try {
      final response = await _httpClient.get('/chats/$chatId/messages?limit=50');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];

        for (final messageData in messagesData) {
          try {
            final message = MessageModel.fromMap(messageData as Map<String, dynamic>);
            await _dbHelper.insertOrUpdateMessage(message);
          } catch (e) {
            debugPrint('❌ Error parsing message: $e');
          }
        }
        
        // Update message stream
        if (_messageControllers.containsKey(chatId)) {
          final messages = await _dbHelper.getChatMessages(chatId);
          _messageControllers[chatId]!.add(messages);
        }
        
        debugPrint('✅ Synced ${messagesData.length} messages for chat $chatId');
      }
    } catch (e) {
      debugPrint('❌ Error syncing messages: $e');
    }
  }

  @override
  Future<void> syncAllData(String userId) async {
    try {
      debugPrint('🔄 Syncing all data (fallback)...');
      
      // Sync chats
      final response = await _httpClient.get('/chats?userId=$userId');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> chatsData = data['chats'] ?? [];

        for (final chatData in chatsData) {
          try {
            final chat = ChatModel.fromMap(chatData as Map<String, dynamic>);
            await _dbHelper.insertOrUpdateChat(chat);
          } catch (e) {
            debugPrint('❌ Error parsing chat: $e');
          }
        }
        
        // Update chats stream
        final chats = await _dbHelper.getUserChats(userId);
        _chatsController.add(chats);
        
        debugPrint('✅ Synced ${chatsData.length} chats');
      }
      
      debugPrint('✅ All data synced successfully');
    } catch (e) {
      debugPrint('❌ Error syncing all data: $e');
    }
  }

  /// Sync chat read status with server
  Future<void> _syncChatReadStatus(String chatId, String userId) async {
    try {
      await _httpClient.post('/chats/$chatId/mark-read', body: {
        'userId': userId,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Failed to sync read status with server: $e');
    }
  }

  /// Manually trigger reconnection
  Future<bool> reconnect() async {
    if (!_isInitialized || _currentUserId == null) {
      debugPrint('❌ Cannot reconnect - not initialized');
      return false;
    }

    return await _wsService.reconnect();
  }
}

// ========================================
// REPOSITORY PROVIDER (updated)
// ========================================

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final repository = OfflineFirstChatRepository();
  
  ref.onDispose(() {
    if (repository is OfflineFirstChatRepository) {
      repository.dispose();
    }
  });
  
  return repository;
});