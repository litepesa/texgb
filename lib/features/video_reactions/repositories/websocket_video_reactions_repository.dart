// lib/features/video_reactions/repositories/websocket_video_reactions_repository.dart
// WebSocket-based implementation of video reactions repository
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_model.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_chat_model.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_message_model.dart';
import 'package:textgb/features/video_reactions/repositories/video_reactions_repository.dart';
import 'package:textgb/shared/providers/websocket_provider.dart';
import 'package:textgb/shared/services/http_client.dart';
import 'package:textgb/shared/services/websocket_service.dart';
import 'package:uuid/uuid.dart';

class WebSocketVideoReactionsRepository implements VideoReactionsRepository {
  final HttpClientService _httpClient;
  final WebSocketService _wsService;
  final Uuid _uuid;

  // Local caches for real-time updates
  final _chatsController = StreamController<List<VideoReactionChatModel>>.broadcast();
  final Map<String, StreamController<List<VideoReactionMessageModel>>> _messagesControllers = {};
  final Map<String, List<VideoReactionChatModel>> _chatsCache = {};
  final Map<String, List<VideoReactionMessageModel>> _messagesCache = {};

  WebSocketVideoReactionsRepository({
    HttpClientService? httpClient,
    WebSocketService? wsService,
    Uuid? uuid,
  })  : _httpClient = httpClient ?? HttpClientService(),
        _wsService = wsService ?? WebSocketService(),
        _uuid = uuid ?? const Uuid() {
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    // Connect to WebSocket if not already connected
    if (!_wsService.isConnected) {
      _wsService.connect();
    }

    // Listen to WebSocket events
    _wsService.eventStream.listen(_handleWebSocketEvent);

    // Listen to connection state changes
    _wsService.connectionStateStream.listen((isConnected) {
      if (isConnected) {
        debugPrint('WebSocket connected - resubscribing to chats');
        _resubscribeToActiveChats();
      }
    });
  }

  void _handleWebSocketEvent(WebSocketMessage message) {
    try {
      switch (message.type) {
        case 'message_received':
          _handleNewMessage(message.data);
          break;
        case 'message_updated':
          _handleMessageUpdate(message.data);
          break;
        case 'message_deleted':
          _handleMessageDeletion(message.data);
          break;
        case 'message_delivered':
          _handleMessageDelivered(message.data);
          break;
        case 'message_read':
          _handleMessageRead(message.data);
          break;
        case 'chat_updated':
          _handleChatUpdate(message.data);
          break;
        case 'user_typing':
          _handleTypingIndicator(message.data);
          break;
        default:
          debugPrint('Unhandled WebSocket event: ${message.type}');
      }
    } catch (e) {
      debugPrint('Error handling WebSocket event: $e');
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = VideoReactionMessageModel.fromMap(data);
      final chatId = message.chatId;

      // Update messages cache
      if (_messagesCache.containsKey(chatId)) {
        _messagesCache[chatId]!.insert(0, message);
        _messagesControllers[chatId]?.add(_messagesCache[chatId]!);
      }

      // Update chat last message
      _updateChatLastMessageFromMessage(chatId, message);
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  void _handleMessageUpdate(Map<String, dynamic> data) {
    try {
      final updatedMessage = VideoReactionMessageModel.fromMap(data);
      final chatId = updatedMessage.chatId;

      if (_messagesCache.containsKey(chatId)) {
        final messages = _messagesCache[chatId]!;
        final index = messages.indexWhere((m) => m.messageId == updatedMessage.messageId);
        
        if (index != -1) {
          messages[index] = updatedMessage;
          _messagesControllers[chatId]?.add(messages);
        }
      }
    } catch (e) {
      debugPrint('Error handling message update: $e');
    }
  }

  void _handleMessageDeletion(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'] as String;
      final messageId = data['messageId'] as String;

      if (_messagesCache.containsKey(chatId)) {
        _messagesCache[chatId]!.removeWhere((m) => m.messageId == messageId);
        _messagesControllers[chatId]?.add(_messagesCache[chatId]!);
      }
    } catch (e) {
      debugPrint('Error handling message deletion: $e');
    }
  }

  void _handleMessageDelivered(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'] as String;
      final messageId = data['messageId'] as String;
      final userId = data['userId'] as String;
      final deliveredAt = DateTime.parse(data['deliveredAt'] as String);

      if (_messagesCache.containsKey(chatId)) {
        final messages = _messagesCache[chatId]!;
        final index = messages.indexWhere((m) => m.messageId == messageId);
        
        if (index != -1) {
          final message = messages[index];
          final updatedDeliveredTo = Map<String, DateTime>.from(message.deliveredTo ?? {});
          updatedDeliveredTo[userId] = deliveredAt;
          
          messages[index] = message.copyWith(
            deliveredTo: updatedDeliveredTo,
            status: MessageStatus.delivered,
          );
          _messagesControllers[chatId]?.add(messages);
        }
      }
    } catch (e) {
      debugPrint('Error handling message delivered: $e');
    }
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    try {
      final chatId = data['chatId'] as String;
      final messageId = data['messageId'] as String;
      final userId = data['userId'] as String;
      final readAt = DateTime.parse(data['readAt'] as String);

      if (_messagesCache.containsKey(chatId)) {
        final messages = _messagesCache[chatId]!;
        final index = messages.indexWhere((m) => m.messageId == messageId);
        
        if (index != -1) {
          final message = messages[index];
          final updatedReadBy = Map<String, DateTime>.from(message.readBy ?? {});
          updatedReadBy[userId] = readAt;
          
          messages[index] = message.copyWith(
            readBy: updatedReadBy,
            status: MessageStatus.read,
          );
          _messagesControllers[chatId]?.add(messages);
        }
      }
    } catch (e) {
      debugPrint('Error handling message read: $e');
    }
  }

  void _handleChatUpdate(Map<String, dynamic> data) {
    try {
      final updatedChat = VideoReactionChatModel.fromMap(data);
      
      for (final userId in _chatsCache.keys) {
        final chats = _chatsCache[userId]!;
        final index = chats.indexWhere((c) => c.chatId == updatedChat.chatId);
        
        if (index != -1) {
          chats[index] = updatedChat;
          _chatsController.add(chats);
        }
      }
    } catch (e) {
      debugPrint('Error handling chat update: $e');
    }
  }

  void _handleTypingIndicator(Map<String, dynamic> data) {
    // Typing indicators can be handled by the UI layer through event streams
    debugPrint('Typing indicator: $data');
  }

  void _updateChatLastMessageFromMessage(String chatId, VideoReactionMessageModel message) {
    for (final userId in _chatsCache.keys) {
      final chats = _chatsCache[userId]!;
      final index = chats.indexWhere((c) => c.chatId == chatId);
      
      if (index != -1) {
        final chat = chats[index];
        final updatedChat = chat.copyWith(
          lastMessage: message.getDisplayContent(),
          lastMessageType: message.type,
          lastMessageSender: message.senderId,
          lastMessageTime: message.timestamp,
        );
        
        chats[index] = updatedChat;
        chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        _chatsController.add(chats);
      }
    }
  }

  void _resubscribeToActiveChats() {
    // Resubscribe to all active chats after reconnection
    for (final chatId in _messagesControllers.keys) {
      _wsService.subscribeToChat(chatId);
    }
    
    // Resubscribe to user chats
    for (final userId in _chatsCache.keys) {
      _wsService.subscribeToUserChats(userId);
    }
  }

  String _createTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  // ========================================
  // INTERFACE IMPLEMENTATION
  // ========================================

  @override
  String generateChatId(String userId1, String userId2, String videoId) {
    final sortedIds = [userId1, userId2]..sort();
    return 'video_reaction_${videoId}_${sortedIds[0]}_${sortedIds[1]}';
  }

  @override
  Future<bool> chatExists(String chatId) async {
    try {
      final response = await _httpClient.get('/video-reactions/chats/$chatId/exists');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking chat existence: $e');
      return false;
    }
  }

  @override
  Future<bool> chatHasMessages(String chatId) async {
    try {
      final response = await _httpClient.get('/video-reactions/chats/$chatId/has-messages');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['hasMessages'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking chat messages: $e');
      return false;
    }
  }

  @override
  Future<String> createVideoReactionChat({
    required String currentUserId,
    required String videoOwnerId,
    required VideoReactionModel videoReaction,
  }) async {
    try {
      final chatId = generateChatId(currentUserId, videoOwnerId, videoReaction.videoId);

      // Use WebSocket to create chat
      final response = await _wsService.createChat({
        'chatId': chatId,
        'participants': [currentUserId, videoOwnerId],
        'originalReaction': videoReaction.toMap(),
        'createdAt': _createTimestamp(),
      });

      if (response != null) {
        // Send the initial video reaction message via WebSocket
        await sendVideoReactionMessage(
          chatId: chatId,
          senderId: currentUserId,
          content: videoReaction.reaction ?? '',
          videoReactionData: videoReaction,
          isOriginalReaction: true,
        );

        // Subscribe to the new chat
        await _wsService.subscribeToChat(chatId);

        return response['chatId'] ?? chatId;
      } else {
        throw VideoReactionsRepositoryException('Failed to create video reaction chat');
      }
    } catch (e) {
      debugPrint('Error creating video reaction chat: $e');
      throw VideoReactionsRepositoryException('Failed to create video reaction chat: $e');
    }
  }

  @override
  Stream<List<VideoReactionChatModel>> getVideoReactionChatsStream(String userId) {
    // Initialize cache if not exists
    if (!_chatsCache.containsKey(userId)) {
      _chatsCache[userId] = [];
      _loadInitialChats(userId);
    }

    // Subscribe to user's chats via WebSocket
    _wsService.subscribeToUserChats(userId);

    // Return stream from controller
    return _chatsController.stream.map((allChats) {
      // Filter and sort chats for this user
      final userChats = _chatsCache[userId] ?? [];
      return userChats
          .where((chat) => !chat.isArchivedForUser(userId))
          .toList()
        ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    });
  }

  Future<void> _loadInitialChats(String userId) async {
    try {
      final response = await _httpClient.get('/video-reactions/chats');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> chatsData = data['chats'] ?? [];

        final chats = chatsData
            .map((chatData) {
              try {
                return VideoReactionChatModel.fromMap(chatData as Map<String, dynamic>);
              } catch (e) {
                debugPrint('Error parsing chat: $e');
                return null;
              }
            })
            .whereType<VideoReactionChatModel>()
            .toList();

        _chatsCache[userId] = chats;
        _chatsController.add(chats);
      }
    } catch (e) {
      debugPrint('Error loading initial chats: $e');
    }
  }

  @override
  Future<VideoReactionChatModel?> getVideoReactionChatById(String chatId) async {
    try {
      final response = await _httpClient.get('/video-reactions/chats/$chatId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return VideoReactionChatModel.fromMap(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw VideoReactionsRepositoryException('Failed to get chat by ID: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('404')) return null;
      throw VideoReactionsRepositoryException('Failed to get chat by ID: $e');
    }
  }

  @override
  Future<void> updateChatLastMessage(VideoReactionChatModel chat) async {
    try {
      await _httpClient.put('/video-reactions/chats/${chat.chatId}/last-message', body: {
        'lastMessage': chat.lastMessage,
        'lastMessageType': chat.lastMessageType.name,
        'lastMessageSender': chat.lastMessageSender,
        'lastMessageTime': chat.lastMessageTime.toIso8601String(),
        'updatedAt': _createTimestamp(),
      });
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to update chat last message: $e');
    }
  }

  @override
  Future<String> sendVideoReactionMessage({
    required String chatId,
    required String senderId,
    required String content,
    required VideoReactionModel? videoReactionData,
    bool isOriginalReaction = false,
  }) async {
    try {
      final messageId = _uuid.v4();

      final messageData = {
        'messageId': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'content': content,
        'type': MessageEnum.text.name,
        'status': MessageStatus.sending.name,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'videoReactionData': videoReactionData?.toMap(),
        'isOriginalReaction': isOriginalReaction,
      };

      // Send via WebSocket
      final response = await _wsService.sendMessage(messageData);

      if (response != null) {
        return response['messageId'] ?? messageId;
      } else {
        throw VideoReactionsRepositoryException('Failed to send video reaction message');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to send video reaction message: $e');
    }
  }

  @override
  Future<String> sendTextMessage({
    required String chatId,
    required String senderId,
    required String content,
    String? replyToMessageId,
  }) async {
    try {
      final messageId = _uuid.v4();

      final messageData = {
        'messageId': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'content': content,
        'type': MessageEnum.text.name,
        'status': MessageStatus.sending.name,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      };

      // Send via WebSocket
      final response = await _wsService.sendMessage(messageData);

      if (response != null) {
        return response['messageId'] ?? messageId;
      } else {
        throw VideoReactionsRepositoryException('Failed to send text message');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to send text message: $e');
    }
  }

  @override
  Future<String> sendImageMessage({
    required String chatId,
    required String senderId,
    required File imageFile,
    String? replyToMessageId,
  }) async {
    try {
      final messageId = _uuid.v4();

      // TODO: Upload image file to storage and get URL
      // For now, using HTTP endpoint for file uploads
      final response = await _httpClient.uploadFile(
        '/video-reactions/chats/$chatId/upload-image',
        imageFile,
        'image',
        additionalFields: {
          'messageId': messageId,
          'senderId': senderId,
          if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['messageId'] ?? messageId;
      } else {
        throw VideoReactionsRepositoryException('Failed to send image: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to send image message: $e');
    }
  }

  @override
  Future<String> sendFileMessage({
    required String chatId,
    required String senderId,
    required File file,
    required String fileName,
    String? replyToMessageId,
  }) async {
    try {
      final messageId = _uuid.v4();

      // Upload file via HTTP endpoint
      final response = await _httpClient.uploadFile(
        '/video-reactions/chats/$chatId/upload-file',
        file,
        'file',
        additionalFields: {
          'messageId': messageId,
          'senderId': senderId,
          'fileName': fileName,
          if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['messageId'] ?? messageId;
      } else {
        throw VideoReactionsRepositoryException('Failed to send file: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to send file message: $e');
    }
  }

  @override
  Stream<List<VideoReactionMessageModel>> getMessagesStream(String chatId) {
    // Initialize cache and controller if not exists
    if (!_messagesCache.containsKey(chatId)) {
      _messagesCache[chatId] = [];
      _messagesControllers[chatId] = StreamController<List<VideoReactionMessageModel>>.broadcast();
      _loadInitialMessages(chatId);
    }

    // Subscribe to chat via WebSocket
    _wsService.subscribeToChat(chatId);

    // Return stream from controller
    return _messagesControllers[chatId]!.stream;
  }

  Future<void> _loadInitialMessages(String chatId) async {
    try {
      final response = await _httpClient.get('/video-reactions/chats/$chatId/messages?limit=100&sort=desc');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];

        final messages = messagesData
            .map((messageData) => VideoReactionMessageModel.fromMap(messageData as Map<String, dynamic>))
            .toList();

        _messagesCache[chatId] = messages;
        _messagesControllers[chatId]?.add(messages);
      }
    } catch (e) {
      debugPrint('Error loading initial messages: $e');
    }
  }

  @override
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    try {
      await _wsService.updateMessage(chatId, messageId, {
        'status': status.name,
        'updatedAt': _createTimestamp(),
      });
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to update message status: $e');
    }
  }

  @override
  Future<void> markMessageAsDelivered(String chatId, String messageId, String userId) async {
    try {
      await _wsService.markMessageDelivered(chatId, messageId);
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to mark message as delivered: $e');
    }
  }

  @override
  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    try {
      await _wsService.updateMessage(chatId, messageId, {
        'content': newContent,
        'isEdited': true,
        'editedAt': _createTimestamp(),
        'updatedAt': _createTimestamp(),
      });
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to edit message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    try {
      await _wsService.deleteMessage(chatId, messageId, deleteForEveryone);
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to delete message: $e');
    }
  }

  @override
  Future<void> pinMessage(String chatId, String messageId) async {
    try {
      await _wsService.pinMessage(chatId, messageId);
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to pin message: $e');
    }
  }

  @override
  Future<void> unpinMessage(String chatId, String messageId) async {
    try {
      await _wsService.unpinMessage(chatId, messageId);
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to unpin message: $e');
    }
  }

  @override
  Future<List<VideoReactionMessageModel>> searchMessages(String chatId, String query) async {
    try {
      final response = await _httpClient.get(
          '/video-reactions/chats/$chatId/messages/search?q=${Uri.encodeComponent(query)}&limit=100');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];

        return messagesData
            .map((messageData) => VideoReactionMessageModel.fromMap(messageData as Map<String, dynamic>))
            .toList();
      } else {
        throw VideoReactionsRepositoryException('Failed to search messages: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to search messages: $e');
    }
  }

  @override
  Future<List<VideoReactionMessageModel>> getPinnedMessages(String chatId) async {
    try {
      final response = await _httpClient.get('/video-reactions/chats/$chatId/messages/pinned');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];

        return messagesData
            .map((messageData) => VideoReactionMessageModel.fromMap(messageData as Map<String, dynamic>))
            .toList();
      } else {
        throw VideoReactionsRepositoryException('Failed to get pinned messages: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to get pinned messages: $e');
    }
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      await _wsService.markChatRead(chatId);
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to mark chat as read: $e');
    }
  }

  @override
  Future<void> toggleChatPin(String chatId, String userId) async {
    try {
      await _httpClient.post('/video-reactions/chats/$chatId/toggle-pin', body: {
        'userId': userId,
        'pinnedAt': _createTimestamp(),
      });
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to toggle chat pin: $e');
    }
  }

  @override
  Future<void> toggleChatArchive(String chatId, String userId) async {
    try {
      await _httpClient.post('/video-reactions/chats/$chatId/toggle-archive', body: {
        'userId': userId,
        'archivedAt': _createTimestamp(),
      });
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to toggle chat archive: $e');
    }
  }

  @override
  Future<void> toggleChatMute(String chatId, String userId) async {
    try {
      await _httpClient.post('/video-reactions/chats/$chatId/toggle-mute', body: {
        'userId': userId,
        'mutedAt': _createTimestamp(),
      });
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to toggle chat mute: $e');
    }
  }

  @override
  Future<void> deleteChat(String chatId, String userId, {bool deleteForEveryone = false}) async {
    try {
      await _httpClient.delete(
          '/video-reactions/chats/$chatId?userId=$userId&deleteForEveryone=$deleteForEveryone');

      // Unsubscribe from chat
      await _wsService.unsubscribeFromChat(chatId);

      // Clean up local cache
      _messagesCache.remove(chatId);
      await _messagesControllers[chatId]?.close();
      _messagesControllers.remove(chatId);
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to delete chat: $e');
    }
  }

  @override
  Future<void> clearChatHistory(String chatId, String userId) async {
    try {
      await _httpClient.post('/video-reactions/chats/$chatId/clear-history', body: {
        'userId': userId,
        'clearedAt': _createTimestamp(),
      });

      // Clear local cache
      _messagesCache[chatId] = [];
      _messagesControllers[chatId]?.add([]);
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to clear chat history: $e');
    }
  }

  // Additional methods for typing indicators
  Future<void> sendTypingIndicator(String chatId, bool isTyping) async {
    try {
      await _wsService.sendTypingIndicator(chatId, isTyping);
    } catch (e) {
      debugPrint('Failed to send typing indicator: $e');
    }
  }

  // Clean up resources
  Future<void> dispose() async {
    await _chatsController.close();
    
    for (final controller in _messagesControllers.values) {
      await controller.close();
    }
    
    _messagesControllers.clear();
    _chatsCache.clear();
    _messagesCache.clear();
  }
}

// Updated provider to use WebSocket implementation
final websocketVideoReactionsRepositoryProvider = Provider<VideoReactionsRepository>((ref) {
  final wsService = ref.watch(websocketServiceProvider);
  final repository = WebSocketVideoReactionsRepository(wsService: wsService);
  
  ref.onDispose(() {
    repository.dispose();
  });
  
  return repository;
});
