// lib/features/chat/repositories/chat_repository_impl.dart
// Concrete implementation of ChatRepository
// Combines WebSocket (real-time) + SQLite (local storage) + HTTP (REST API)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/features/chat/services/chat_database_service.dart';
import 'package:textgb/shared/services/websocket_service.dart';
import 'package:textgb/shared/services/http_client.dart';

/// Concrete implementation of ChatRepository
/// Uses WebSocket for real-time, SQLite for offline, and HTTP for REST operations
class ChatRepositoryImpl implements ChatRepository {
  final WebSocketService _wsService;
  final ChatDatabaseService _dbService;
  final HttpClientService _httpClient;

  // Stream controllers for real-time updates
  final _chatUpdateController = StreamController<ChatModel>.broadcast();
  final _messageUpdateController = StreamController<MessageModel>.broadcast();
  final _allChatsController = StreamController<List<ChatModel>>.broadcast();

  // Subscriptions
  StreamSubscription<WSMessage>? _wsMessageSubscription;

  ChatRepositoryImpl({
    WebSocketService? wsService,
    ChatDatabaseService? dbService,
    HttpClientService? httpClient,
  })  : _wsService = wsService ?? WebSocketService(),
        _dbService = dbService ?? ChatDatabaseService(),
        _httpClient = httpClient ?? HttpClientService() {
    _initializeWebSocketListeners();
  }

  // ===============================
  // INITIALIZATION
  // ===============================

  void _initializeWebSocketListeners() {
    _wsMessageSubscription = _wsService.messageStream.listen((wsMessage) {
      _handleWebSocketMessage(wsMessage);
    });
  }

  void _handleWebSocketMessage(WSMessage wsMessage) {
    try {
      switch (wsMessage.type) {
        case WSMessageType.newMessage:
          _handleNewMessage(wsMessage.data);
          break;
        case WSMessageType.messageStatus:
          _handleMessageStatusUpdate(wsMessage.data);
          break;
        case WSMessageType.messageDeleted:
          _handleMessageDeleted(wsMessage.data);
          break;
        case WSMessageType.messageReaction:
          _handleMessageReaction(wsMessage.data);
          break;
        case WSMessageType.chatCreated:
        case WSMessageType.chatUpdated:
          _handleChatUpdate(wsMessage.data);
          break;
        case WSMessageType.chatDeleted:
          _handleChatDeleted(wsMessage.data);
          break;
        default:
          debugPrint('Unhandled WebSocket message type: ${wsMessage.type}');
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) async {
    try {
      final message = MessageModel.fromMap(data, data['id'] ?? '');
      
      // Save to local DB
      await _dbService.upsertMessage(message);
      
      // Update unread count if not from current user
      if (message.senderId != currentUserId) {
        await _dbService.incrementUnreadCount(message.chatId);
      }
      
      // Update chat's last message
      final chat = await _dbService.getChatById(message.chatId);
      if (chat != null) {
        final updatedChat = chat.copyWith(
          lastMessage: message.content,
          lastMessageId: message.id,
          lastMessageSenderId: message.senderId,
          lastMessageSenderName: message.senderName,
          lastMessageType: message.type.value,
          lastMessageTime: message.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _dbService.upsertChat(updatedChat);
        _chatUpdateController.add(updatedChat);
      }
      
      // Broadcast message update
      _messageUpdateController.add(message);
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  void _handleMessageStatusUpdate(Map<String, dynamic> data) async {
    try {
      final messageId = data['messageId'] ?? data['message_id'];
      final status = MessageStatus.fromString(data['status']);
      
      await _dbService.updateMessageStatus(messageId: messageId, status: status);
      
      final message = await _dbService.getMessageById(messageId);
      if (message != null) {
        _messageUpdateController.add(message);
      }
    } catch (e) {
      debugPrint('Error handling message status update: $e');
    }
  }

  void _handleMessageDeleted(Map<String, dynamic> data) async {
    try {
      final messageId = data['messageId'] ?? data['message_id'];
      await _dbService.deleteMessage(messageId);
    } catch (e) {
      debugPrint('Error handling message deleted: $e');
    }
  }

  void _handleMessageReaction(Map<String, dynamic> data) async {
    try {
      final messageId = data['messageId'] ?? data['message_id'];
      final message = await _dbService.getMessageById(messageId);
      
      if (message != null) {
        // Update reactions locally
        final updatedReactions = Map<String, String>.from(message.reactions);
        final emoji = data['emoji'];
        final userId = data['userId'] ?? data['user_id'];
        final action = data['action'];
        
        if (action == 'add') {
          updatedReactions[emoji] = userId;
        } else {
          updatedReactions.remove(emoji);
        }
        
        final updatedMessage = message.copyWith(reactions: updatedReactions);
        await _dbService.upsertMessage(updatedMessage);
        _messageUpdateController.add(updatedMessage);
      }
    } catch (e) {
      debugPrint('Error handling message reaction: $e');
    }
  }

  void _handleChatUpdate(Map<String, dynamic> data) async {
    try {
      final chat = ChatModel.fromMap(data, data['id'] ?? '');
      await _dbService.upsertChat(chat);
      _chatUpdateController.add(chat);
    } catch (e) {
      debugPrint('Error handling chat update: $e');
    }
  }

  void _handleChatDeleted(Map<String, dynamic> data) async {
    try {
      final chatId = data['chatId'] ?? data['chat_id'];
      await _dbService.deleteChat(chatId);
    } catch (e) {
      debugPrint('Error handling chat deleted: $e');
    }
  }

  // ===============================
  // CONNECTION MANAGEMENT
  // ===============================

  @override
  Future<void> connect() async {
    try {
      await _wsService.connect();
      debugPrint('✅ Chat repository connected');
    } catch (e) {
      debugPrint('❌ Failed to connect chat repository: $e');
      throw ChatRepositoryException('Failed to connect', originalError: e);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _wsService.disconnect();
      debugPrint('✅ Chat repository disconnected');
    } catch (e) {
      debugPrint('❌ Failed to disconnect chat repository: $e');
      throw ChatRepositoryException('Failed to disconnect', originalError: e);
    }
  }

  @override
  bool get isConnected => _wsService.isConnected;

  @override
  Stream<bool> get connectionStateStream =>
      _wsService.connectionStateStream.map((state) => state == WSConnectionState.connected);

  @override
  Future<void> reconnect() async {
    await _wsService.reconnect();
  }

  // ===============================
  // CHAT OPERATIONS
  // ===============================

  @override
  Future<List<ChatModel>> getChats() async {
    try {
      // Load from local DB first (instant)
      final localChats = await _dbService.getAllChats();
      
      // Return local data immediately
      if (localChats.isNotEmpty) {
        _allChatsController.add(localChats);
      }
      
      // Sync with server in background if connected
      if (isConnected) {
        _syncChatsInBackground();
      }
      
      return localChats;
    } catch (e) {
      debugPrint('❌ Error getting chats: $e');
      throw ChatRepositoryException('Failed to get chats', originalError: e);
    }
  }

  Future<void> _syncChatsInBackground() async {
    try {
      final response = await _httpClient.get('/chats');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chats = (data['chats'] as List)
            .map((c) => ChatModel.fromMap(c, c['id']))
            .toList();
        
        // Update local DB
        for (final chat in chats) {
          await _dbService.upsertChat(chat);
        }
        
        // Broadcast updated chats
        _allChatsController.add(chats);
      }
    } catch (e) {
      debugPrint('Background chat sync failed: $e');
    }
  }

  @override
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      // Check local DB first
      final localChat = await _dbService.getChatById(chatId);
      
      if (localChat != null) {
        return localChat;
      }
      
      // Fetch from server if not found locally
      if (isConnected) {
        final response = await _httpClient.get('/chats/$chatId');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final chat = ChatModel.fromMap(data, data['id']);
          await _dbService.upsertChat(chat);
          return chat;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error getting chat by ID: $e');
      throw ChatRepositoryException('Failed to get chat', originalError: e);
    }
  }

  @override
  Future<ChatModel> getOrCreateOneOnOneChat({
    required String currentUserId,
    required String otherUserId,
    required String otherUserName,
    required String otherUserImage,
  }) async {
    try {
      // Try to find existing chat locally
      final localChats = await _dbService.getAllChats();
      for (final chat in localChats) {
        if (chat.isOneOnOne && chat.participantIds.contains(otherUserId)) {
          return chat;
        }
      }
      
      // Create new chat via API
      final response = await _httpClient.post('/chats/one-on-one', body: {
        'currentUserId': currentUserId,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'otherUserImage': otherUserImage,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final chat = ChatModel.fromMap(data['chat'] ?? data, data['id']);
        await _dbService.upsertChat(chat);
        return chat;
      }
      
      throw ChatRepositoryException('Failed to create one-on-one chat');
    } catch (e) {
      debugPrint('❌ Error getting/creating one-on-one chat: $e');
      throw ChatRepositoryException('Failed to get or create chat', originalError: e);
    }
  }

  @override
  Future<ChatModel> createGroupChat({
    required String groupName,
    required String? groupImage,
    required String? groupDescription,
    required String creatorId,
    required List<String> participantIds,
    required List<String> participantNames,
    required List<String> participantImages,
  }) async {
    try {
      final response = await _httpClient.post('/chats/group', body: {
        'groupName': groupName,
        'groupImage': groupImage,
        'groupDescription': groupDescription,
        'creatorId': creatorId,
        'participantIds': participantIds,
        'participantNames': participantNames,
        'participantImages': participantImages,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final chat = ChatModel.fromMap(data['chat'] ?? data, data['id']);
        await _dbService.upsertChat(chat);
        return chat;
      }
      
      throw ChatRepositoryException('Failed to create group chat');
    } catch (e) {
      debugPrint('❌ Error creating group chat: $e');
      throw ChatRepositoryException('Failed to create group chat', originalError: e);
    }
  }

  @override
  Future<void> updateChatSettings({
    required String chatId,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
    bool? isBlocked,
  }) async {
    try {
      await _dbService.updateChatSettings(
        chatId: chatId,
        isMuted: isMuted,
        isPinned: isPinned,
        isArchived: isArchived,
        isBlocked: isBlocked,
      );
      
      // Sync with server if connected
      if (isConnected) {
        await _httpClient.put('/chats/$chatId/settings', body: {
          if (isMuted != null) 'isMuted': isMuted,
          if (isPinned != null) 'isPinned': isPinned,
          if (isArchived != null) 'isArchived': isArchived,
          if (isBlocked != null) 'isBlocked': isBlocked,
        });
      }
    } catch (e) {
      debugPrint('❌ Error updating chat settings: $e');
      throw ChatRepositoryException('Failed to update chat settings', originalError: e);
    }
  }

  @override
  Future<void> deleteChat(String chatId) async {
    try {
      await _dbService.deleteChat(chatId);
      
      // Notify server if connected
      if (isConnected) {
        await _httpClient.delete('/chats/$chatId');
      }
    } catch (e) {
      debugPrint('❌ Error deleting chat: $e');
      throw ChatRepositoryException('Failed to delete chat', originalError: e);
    }
  }

  @override
  Future<void> clearChatMessages(String chatId) async {
    try {
      await _dbService.clearChatMessages(chatId);
    } catch (e) {
      debugPrint('❌ Error clearing chat messages: $e');
      throw ChatRepositoryException('Failed to clear chat messages', originalError: e);
    }
  }

  @override
  Future<List<ChatModel>> searchChats(String query) async {
    try {
      return await _dbService.searchChats(query);
    } catch (e) {
      debugPrint('❌ Error searching chats: $e');
      throw ChatRepositoryException('Failed to search chats', originalError: e);
    }
  }

  @override
  Stream<ChatModel> watchChat(String chatId) {
    return _chatUpdateController.stream.where((chat) => chat.id == chatId);
  }

  @override
  Stream<List<ChatModel>> watchAllChats() {
    return _allChatsController.stream;
  }

  // ===============================
  // MESSAGE OPERATIONS
  // ===============================

  @override
  Future<List<MessageModel>> getMessages({
    required String chatId,
    int limit = 50,
    String? before,
  }) async {
    try {
      // Load from local DB first
      final localMessages = await _dbService.getMessages(
        chatId: chatId,
        limit: limit,
        before: before,
      );
      
      // Return local data immediately
      if (localMessages.isNotEmpty) {
        return localMessages;
      }
      
      // Fetch from server if empty and connected
      if (isConnected) {
        String endpoint = '/chats/$chatId/messages?limit=$limit';
        if (before != null) {
          endpoint += '&before=$before';
        }
        
        final response = await _httpClient.get(endpoint);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final messages = (data['messages'] as List)
              .map((m) => MessageModel.fromMap(m, m['id']))
              .toList();
          
          // Save to local DB
          await _dbService.batchInsertMessages(messages);
          return messages;
        }
      }
      
      return localMessages;
    } catch (e) {
      debugPrint('❌ Error getting messages: $e');
      throw ChatRepositoryException('Failed to get messages', originalError: e);
    }
  }

  @override
  Future<MessageModel?> getMessageById(String messageId) async {
    try {
      return await _dbService.getMessageById(messageId);
    } catch (e) {
      debugPrint('❌ Error getting message by ID: $e');
      throw ChatRepositoryException('Failed to get message', originalError: e);
    }
  }

  @override
  Future<MessageModel> sendTextMessage({
    required String chatId,
    required String content,
    String? repliedToMessageId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw ChatRepositoryException('User not authenticated');
      
      // Create message locally
      final message = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: chatId,
        senderId: user.uid,
        senderName: user.displayName ?? 'User',
        senderImage: user.photoURL ?? '',
        content: content,
        type: MessageType.text,
        status: MessageStatus.sending,
        repliedToMessageId: repliedToMessageId,
        createdAt: DateTime.now().toIso8601String(),
      );
      
      // Save to local DB immediately
      await _dbService.upsertMessage(message);
      
      // Send via WebSocket
      if (isConnected) {
        _wsService.sendTextMessage(
          chatId: chatId,
          content: content,
          repliedToMessageId: repliedToMessageId,
        );
        
        // Update status to sent
        final sentMessage = message.copyWith(status: MessageStatus.sent);
        await _dbService.upsertMessage(sentMessage);
        return sentMessage;
      } else {
        // Mark as failed if not connected
        final failedMessage = message.copyWith(status: MessageStatus.failed);
        await _dbService.upsertMessage(failedMessage);
        return failedMessage;
      }
    } catch (e) {
      debugPrint('❌ Error sending text message: $e');
      throw ChatRepositoryException('Failed to send message', originalError: e);
    }
  }

  @override
  Future<MessageModel> sendImageMessage({
    required String chatId,
    required File imageFile,
    String? caption,
    String? repliedToMessageId,
  }) async {
    try {
      // Upload image first
      final imageUrl = await uploadMediaFile(file: imageFile, type: 'image');
      
      // Create and send message via HTTP
      final response = await _httpClient.post('/messages', body: {
        'chatId': chatId,
        'senderId': currentUserId,
        'type': 'image',
        'mediaUrl': imageUrl,
        'content': caption ?? '',
        'repliedToMessageId': repliedToMessageId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final message = MessageModel.fromMap(data['message'] ?? data, data['id']);
        await _dbService.upsertMessage(message);
        return message;
      }
      
      throw ChatRepositoryException('Failed to send image message');
    } catch (e) {
      debugPrint('❌ Error sending image message: $e');
      throw ChatRepositoryException('Failed to send image message', originalError: e);
    }
  }

  @override
  Future<MessageModel> sendVideoMessage({
    required String chatId,
    required File videoFile,
    String? caption,
    String? repliedToMessageId,
  }) async {
    try {
      // Upload video first
      final videoUrl = await uploadMediaFile(file: videoFile, type: 'video');
      
      // Create and send message via HTTP
      final response = await _httpClient.post('/messages', body: {
        'chatId': chatId,
        'senderId': currentUserId,
        'type': 'video',
        'mediaUrl': videoUrl,
        'content': caption ?? '',
        'repliedToMessageId': repliedToMessageId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final message = MessageModel.fromMap(data['message'] ?? data, data['id']);
        await _dbService.upsertMessage(message);
        return message;
      }
      
      throw ChatRepositoryException('Failed to send video message');
    } catch (e) {
      debugPrint('❌ Error sending video message: $e');
      throw ChatRepositoryException('Failed to send video message', originalError: e);
    }
  }

  @override
  Future<MessageModel> sendAudioMessage({
    required String chatId,
    required File audioFile,
    required int duration,
    String? repliedToMessageId,
  }) async {
    try {
      // Upload audio first
      final audioUrl = await uploadMediaFile(file: audioFile, type: 'audio');
      
      // Create and send message via HTTP
      final response = await _httpClient.post('/messages', body: {
        'chatId': chatId,
        'senderId': currentUserId,
        'type': 'audio',
        'mediaUrl': audioUrl,
        'duration': duration,
        'content': '',
        'repliedToMessageId': repliedToMessageId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final message = MessageModel.fromMap(data['message'] ?? data, data['id']);
        await _dbService.upsertMessage(message);
        return message;
      }
      
      throw ChatRepositoryException('Failed to send audio message');
    } catch (e) {
      debugPrint('❌ Error sending audio message: $e');
      throw ChatRepositoryException('Failed to send audio message', originalError: e);
    }
  }

  @override
  Future<MessageModel> sendDocumentMessage({
    required String chatId,
    required File documentFile,
    required String fileName,
    String? repliedToMessageId,
  }) async {
    try {
      // Upload document first
      final documentUrl = await uploadMediaFile(file: documentFile, type: 'document');
      
      // Create and send message via HTTP
      final response = await _httpClient.post('/messages', body: {
        'chatId': chatId,
        'senderId': currentUserId,
        'type': 'document',
        'mediaUrl': documentUrl,
        'fileName': fileName,
        'content': fileName,
        'repliedToMessageId': repliedToMessageId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final message = MessageModel.fromMap(data['message'] ?? data, data['id']);
        await _dbService.upsertMessage(message);
        return message;
      }
      
      throw ChatRepositoryException('Failed to send document message');
    } catch (e) {
      debugPrint('❌ Error sending document message: $e');
      throw ChatRepositoryException('Failed to send document message', originalError: e);
    }
  }

  @override
  Future<MessageModel> sendLocationMessage({
    required String chatId,
    required double latitude,
    required double longitude,
    String? locationName,
    String? repliedToMessageId,
  }) async {
    try {
      final response = await _httpClient.post('/messages', body: {
        'chatId': chatId,
        'senderId': currentUserId,
        'type': 'location',
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'content': locationName ?? 'Location',
        'repliedToMessageId': repliedToMessageId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final message = MessageModel.fromMap(data['message'] ?? data, data['id']);
        await _dbService.upsertMessage(message);
        return message;
      }
      
      throw ChatRepositoryException('Failed to send location message');
    } catch (e) {
      debugPrint('❌ Error sending location message: $e');
      throw ChatRepositoryException('Failed to send location message', originalError: e);
    }
  }

  @override
  Future<MessageModel> sendContactMessage({
    required String chatId,
    required String contactName,
    required String contactPhone,
    String? repliedToMessageId,
  }) async {
    try {
      final response = await _httpClient.post('/messages', body: {
        'chatId': chatId,
        'senderId': currentUserId,
        'type': 'contact',
        'contactName': contactName,
        'contactPhone': contactPhone,
        'content': contactName,
        'repliedToMessageId': repliedToMessageId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final message = MessageModel.fromMap(data['message'] ?? data, data['id']);
        await _dbService.upsertMessage(message);
        return message;
      }
      
      throw ChatRepositoryException('Failed to send contact message');
    } catch (e) {
      debugPrint('❌ Error sending contact message: $e');
      throw ChatRepositoryException('Failed to send contact message', originalError: e);
    }
  }

  @override
  Future<List<MessageModel>> forwardMessages({
    required List<String> messageIds,
    required String toChatId,
  }) async {
    try {
      final response = await _httpClient.post('/messages/forward', body: {
        'messageIds': messageIds,
        'toChatId': toChatId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final messages = (data['messages'] as List)
            .map((m) => MessageModel.fromMap(m, m['id']))
            .toList();
        
        await _dbService.batchInsertMessages(messages);
        return messages;
      }
      
      throw ChatRepositoryException('Failed to forward messages');
    } catch (e) {
      debugPrint('❌ Error forwarding messages: $e');
      throw ChatRepositoryException('Failed to forward messages', originalError: e);
    }
  }

  @override
  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  }) async {
    try {
      await _dbService.updateMessageStatus(messageId: messageId, status: status);
      
      // Notify server via WebSocket if connected
      if (isConnected) {
        _wsService.updateMessageStatus(messageId: messageId, status: status.value);
      }
    } catch (e) {
      debugPrint('❌ Error updating message status: $e');
      throw ChatRepositoryException('Failed to update message status', originalError: e);
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _dbService.deleteMessage(messageId);
      
      // Notify server if connected
      if (isConnected) {
        await _httpClient.delete('/messages/$messageId');
      }
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
      throw ChatRepositoryException('Failed to delete message', originalError: e);
    }
  }

  @override
  Future<void> toggleMessageStar(String messageId) async {
    try {
      final message = await _dbService.getMessageById(messageId);
      if (message != null) {
        await _dbService.toggleMessageStar(messageId, !message.isStarred);
      }
    } catch (e) {
      debugPrint('❌ Error toggling message star: $e');
      throw ChatRepositoryException('Failed to toggle message star', originalError: e);
    }
  }

  @override
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      if (isConnected) {
        _wsService.sendReaction(messageId: messageId, emoji: emoji, isAdd: true);
      }
      
      // Update locally
      final message = await _dbService.getMessageById(messageId);
      if (message != null) {
        final updatedReactions = Map<String, String>.from(message.reactions);
        updatedReactions[emoji] = currentUserId ?? '';
        final updatedMessage = message.copyWith(reactions: updatedReactions);
        await _dbService.upsertMessage(updatedMessage);
      }
    } catch (e) {
      debugPrint('❌ Error adding reaction: $e');
      throw ChatRepositoryException('Failed to add reaction', originalError: e);
    }
  }

  @override
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      if (isConnected) {
        _wsService.sendReaction(messageId: messageId, emoji: emoji, isAdd: false);
      }
      
      // Update locally
      final message = await _dbService.getMessageById(messageId);
      if (message != null) {
        final updatedReactions = Map<String, String>.from(message.reactions);
        updatedReactions.remove(emoji);
        final updatedMessage = message.copyWith(reactions: updatedReactions);
        await _dbService.upsertMessage(updatedMessage);
      }
    } catch (e) {
      debugPrint('❌ Error removing reaction: $e');
      throw ChatRepositoryException('Failed to remove reaction', originalError: e);
    }
  }

  @override
  Future<List<MessageModel>> searchMessagesInChat({
    required String chatId,
    required String query,
  }) async {
    try {
      return await _dbService.searchMessagesInChat(chatId: chatId, query: query);
    } catch (e) {
      debugPrint('❌ Error searching messages: $e');
      throw ChatRepositoryException('Failed to search messages', originalError: e);
    }
  }

  @override
  Future<List<MessageModel>> getStarredMessages() async {
    try {
      return await _dbService.getStarredMessages();
    } catch (e) {
      debugPrint('❌ Error getting starred messages: $e');
      throw ChatRepositoryException('Failed to get starred messages', originalError: e);
    }
  }

  @override
  Stream<MessageModel> watchMessages(String chatId) {
    return _messageUpdateController.stream.where((msg) => msg.chatId == chatId);
  }

  @override
  Stream<MessageModel> watchNewMessages() {
    return _messageUpdateController.stream;
  }

  // ===============================
  // UNREAD COUNT OPERATIONS
  // ===============================

  @override
  Future<int> getUnreadCount(String chatId) async {
    try {
      return await _dbService.getUnreadCount(chatId);
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      throw ChatRepositoryException('Failed to get unread count', originalError: e);
    }
  }

  @override
  Future<int> getTotalUnreadCount() async {
    try {
      return await _dbService.getTotalUnreadCount();
    } catch (e) {
      debugPrint('❌ Error getting total unread count: $e');
      throw ChatRepositoryException('Failed to get total unread count', originalError: e);
    }
  }

  @override
  Future<void> markChatAsRead(String chatId) async {
    try {
      await _dbService.resetUnreadCount(chatId);
      
      // Notify server if connected
      if (isConnected) {
        await _httpClient.put('/chats/$chatId/read', body: {});
      }
    } catch (e) {
      debugPrint('❌ Error marking chat as read: $e');
      throw ChatRepositoryException('Failed to mark chat as read', originalError: e);
    }
  }

  @override
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await updateMessageStatus(messageId: messageId, status: MessageStatus.delivered);
    } catch (e) {
      debugPrint('❌ Error marking message as read: $e');
      throw ChatRepositoryException('Failed to mark message as read', originalError: e);
    }
  }

  // ===============================
  // MEDIA OPERATIONS
  // ===============================

  @override
  Future<String> uploadMediaFile({
    required File file,
    required String type,
    Function(double progress)? onProgress,
  }) async {
    try {
      final response = await _httpClient.uploadFile(
        '/upload',
        file,
        'file',
        additionalFields: {'type': type},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      
      throw ChatRepositoryException('Failed to upload media file');
    } catch (e) {
      debugPrint('❌ Error uploading media file: $e');
      throw ChatRepositoryException('Failed to upload media file', originalError: e);
    }
  }

  @override
  Future<String> downloadMediaFile({
    required String url,
    required String fileName,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Implementation for downloading media files
      // This would use http package to download and save to local storage
      throw UnimplementedError('Download media file not implemented yet');
    } catch (e) {
      debugPrint('❌ Error downloading media file: $e');
      throw ChatRepositoryException('Failed to download media file', originalError: e);
    }
  }

  @override
  Future<List<MessageModel>> getChatMedia({
    required String chatId,
    MessageType? type,
  }) async {
    try {
      return await _dbService.getChatMedia(chatId: chatId, type: type);
    } catch (e) {
      debugPrint('❌ Error getting chat media: $e');
      throw ChatRepositoryException('Failed to get chat media', originalError: e);
    }
  }

  // ===============================
  // SYNC OPERATIONS
  // ===============================

  @override
  Future<void> syncWithServer() async {
    try {
      debugPrint('🔄 Starting sync with server...');
      
      // Sync pending messages
      final pendingMessages = await getPendingMessages();
      for (final message in pendingMessages) {
        try {
          await retryMessage(message.id);
        } catch (e) {
          debugPrint('Failed to retry message ${message.id}: $e');
        }
      }
      
      // Sync chats
      await _syncChatsInBackground();
      
      debugPrint('✅ Sync completed');
    } catch (e) {
      debugPrint('❌ Error syncing with server: $e');
      throw ChatRepositoryException('Failed to sync with server', originalError: e);
    }
  }

  @override
  Future<ChatModel?> refreshChat(String chatId) async {
    try {
      if (!isConnected) return await getChatById(chatId);
      
      final response = await _httpClient.get('/chats/$chatId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chat = ChatModel.fromMap(data, data['id']);
        await _dbService.upsertChat(chat);
        return chat;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error refreshing chat: $e');
      throw ChatRepositoryException('Failed to refresh chat', originalError: e);
    }
  }

  @override
  Future<List<MessageModel>> refreshMessages(String chatId) async {
    try {
      if (!isConnected) return await getMessages(chatId: chatId);
      
      final response = await _httpClient.get('/chats/$chatId/messages');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data['messages'] as List)
            .map((m) => MessageModel.fromMap(m, m['id']))
            .toList();
        
        await _dbService.batchInsertMessages(messages);
        return messages;
      }
      
      return [];
    } catch (e) {
      debugPrint('❌ Error refreshing messages: $e');
      throw ChatRepositoryException('Failed to refresh messages', originalError: e);
    }
  }

  @override
  Future<List<MessageModel>> getPendingMessages() async {
    try {
      return await _dbService.getPendingMessages();
    } catch (e) {
      debugPrint('❌ Error getting pending messages: $e');
      throw ChatRepositoryException('Failed to get pending messages', originalError: e);
    }
  }

  @override
  Future<void> retryMessage(String messageId) async {
    try {
      final message = await _dbService.getMessageById(messageId);
      if (message == null) return;
      
      // Update status to sending
      await _dbService.updateMessageStatus(
        messageId: messageId,
        status: MessageStatus.sending,
      );
      
      // Retry sending based on message type
      if (message.isTextMessage) {
        await sendTextMessage(
          chatId: message.chatId,
          content: message.content,
          repliedToMessageId: message.repliedToMessageId,
        );
      }
      // Add retry logic for other message types as needed
    } catch (e) {
      debugPrint('❌ Error retrying message: $e');
      // Mark as failed
      await _dbService.updateMessageStatus(
        messageId: messageId,
        status: MessageStatus.failed,
      );
      throw ChatRepositoryException('Failed to retry message', originalError: e);
    }
  }

  // ===============================
  // CACHE OPERATIONS
  // ===============================

  @override
  Future<void> clearCache() async {
    try {
      await _dbService.clearAllData();
      debugPrint('✅ Cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
      throw ChatRepositoryException('Failed to clear cache', originalError: e);
    }
  }

  @override
  Future<void> clearChatCache(String chatId) async {
    try {
      await _dbService.clearChatMessages(chatId);
      debugPrint('✅ Chat cache cleared: $chatId');
    } catch (e) {
      debugPrint('❌ Error clearing chat cache: $e');
      throw ChatRepositoryException('Failed to clear chat cache', originalError: e);
    }
  }

  @override
  Future<int> getCacheSize() async {
    try {
      return await _dbService.getDatabaseSize();
    } catch (e) {
      debugPrint('❌ Error getting cache size: $e');
      throw ChatRepositoryException('Failed to get cache size', originalError: e);
    }
  }

  // ===============================
  // USER INFO OPERATIONS
  // ===============================

  @override
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<bool> isParticipant(String chatId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) return false;
      return chat.participantIds.contains(currentUserId);
    } catch (e) {
      debugPrint('❌ Error checking participant: $e');
      return false;
    }
  }

  @override
  Future<void> addParticipants({
    required String chatId,
    required List<String> userIds,
  }) async {
    try {
      final response = await _httpClient.post('/chats/$chatId/participants', body: {
        'userIds': userIds,
      });
      
      if (response.statusCode == 200) {
        await refreshChat(chatId);
      }
    } catch (e) {
      debugPrint('❌ Error adding participants: $e');
      throw ChatRepositoryException('Failed to add participants', originalError: e);
    }
  }

  @override
  Future<void> removeParticipant({
    required String chatId,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.delete('/chats/$chatId/participants/$userId');
      
      if (response.statusCode == 200) {
        await refreshChat(chatId);
      }
    } catch (e) {
      debugPrint('❌ Error removing participant: $e');
      throw ChatRepositoryException('Failed to remove participant', originalError: e);
    }
  }

  @override
  Future<void> leaveGroupChat(String chatId) async {
    try {
      if (currentUserId == null) return;
      
      await removeParticipant(chatId: chatId, userId: currentUserId!);
      await _dbService.deleteChat(chatId);
    } catch (e) {
      debugPrint('❌ Error leaving group chat: $e');
      throw ChatRepositoryException('Failed to leave group chat', originalError: e);
    }
  }

  @override
  Future<void> updateGroupInfo({
    required String chatId,
    String? groupName,
    String? groupImage,
    String? groupDescription,
  }) async {
    try {
      final response = await _httpClient.put('/chats/$chatId', body: {
        if (groupName != null) 'groupName': groupName,
        if (groupImage != null) 'groupImage': groupImage,
        if (groupDescription != null) 'groupDescription': groupDescription,
      });
      
      if (response.statusCode == 200) {
        await refreshChat(chatId);
      }
    } catch (e) {
      debugPrint('❌ Error updating group info: $e');
      throw ChatRepositoryException('Failed to update group info', originalError: e);
    }
  }

  @override
  Future<void> promoteToAdmin({
    required String chatId,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.put('/chats/$chatId/admins/$userId', body: {
        'action': 'promote',
      });
      
      if (response.statusCode == 200) {
        await refreshChat(chatId);
      }
    } catch (e) {
      debugPrint('❌ Error promoting to admin: $e');
      throw ChatRepositoryException('Failed to promote to admin', originalError: e);
    }
  }

  @override
  Future<void> demoteAdmin({
    required String chatId,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.put('/chats/$chatId/admins/$userId', body: {
        'action': 'demote',
      });
      
      if (response.statusCode == 200) {
        await refreshChat(chatId);
      }
    } catch (e) {
      debugPrint('❌ Error demoting admin: $e');
      throw ChatRepositoryException('Failed to demote admin', originalError: e);
    }
  }

  // ===============================
  // CLEANUP
  // ===============================

  Future<void> dispose() async {
    await _wsMessageSubscription?.cancel();
    await _chatUpdateController.close();
    await _messageUpdateController.close();
    await _allChatsController.close();
    await _dbService.close();
  }
}