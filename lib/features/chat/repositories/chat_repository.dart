// lib/features/chat/repositories/chat_repository.dart
// FIXED: Properly syncs messages from PostgreSQL backend to local SQLite
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/models/video_reaction_model.dart';
import 'package:textgb/features/chat/models/moment_reaction_model.dart';
import 'package:textgb/features/chat/database/chat_database_helper.dart';
import 'package:textgb/shared/services/http_client.dart';
import 'package:textgb/shared/utilities/datetime_helper.dart';
import 'package:uuid/uuid.dart';

// ========================================
// ABSTRACT REPOSITORY INTERFACE
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
// FIXED OFFLINE-FIRST IMPLEMENTATION
// ========================================

class OfflineFirstChatRepository implements ChatRepository {
  final HttpClientService _httpClient;
  final ChatDatabaseHelper _dbHelper;
  final Uuid _uuid;
  
  // Stream controllers
  final Map<String, StreamController<List<ChatModel>>> _chatStreamControllers = {};
  final Map<String, StreamController<List<MessageModel>>> _messageStreamControllers = {};
  
  // Sync tracking
  final Map<String, bool> _isSyncing = {};
  final Map<String, DateTime> _lastSyncTime = {};
  
  OfflineFirstChatRepository({
    HttpClientService? httpClient,
    ChatDatabaseHelper? dbHelper,
    Uuid? uuid,
  })  : _httpClient = httpClient ?? HttpClientService(),
        _dbHelper = dbHelper ?? ChatDatabaseHelper(),
        _uuid = uuid ?? const Uuid();

  @override
  String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // ========================================
  // CHAT OPERATIONS
  // ========================================

  @override
  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    final chatId = generateChatId(currentUserId, otherUserId);
    
    try {
      // Check local database first
      var chat = await _dbHelper.getChatById(chatId);
      
      if (chat != null) {
        return chatId;
      }
      
      // Create new chat locally
      final newChat = ChatModel(
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
      
      await _dbHelper.insertOrUpdateChat(newChat);
      
      // Create on server (don't wait)
      _createChatOnServer(newChat).catchError((e) {
        debugPrint('Failed to create chat on server: $e');
      });
      
      return chatId;
    } catch (e) {
      debugPrint('Error creating/getting chat: $e');
      rethrow;
    }
  }

  Future<void> _createChatOnServer(ChatModel chat) async {
    try {
      await _httpClient.post('/chats', body: {
        'chatId': chat.chatId,
        'participants': chat.participants,
        'createdAt': DateTimeHelper.toIso8601(chat.createdAt),
      });
    } catch (e) {
      debugPrint('Error creating chat on server: $e');
    }
  }

  @override
  Stream<List<ChatModel>> getChatsStream(String userId) {
    if (_chatStreamControllers.containsKey(userId)) {
      return _chatStreamControllers[userId]!.stream;
    }
    
    final controller = StreamController<List<ChatModel>>.broadcast(
      onListen: () => _startChatStream(userId),
      onCancel: () => _stopChatStream(userId),
    );
    
    _chatStreamControllers[userId] = controller;
    return controller.stream;
  }

  void _startChatStream(String userId) {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      final controller = _chatStreamControllers[userId];
      
      if (controller == null || controller.isClosed) {
        timer.cancel();
        return;
      }
      
      try {
        final chats = await _dbHelper.getUserChats(userId);
        if (!controller.isClosed) {
          controller.add(chats);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    });
  }

  void _stopChatStream(String userId) {
    _chatStreamControllers.remove(userId)?.close();
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
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    await _dbHelper.markChatAsRead(chatId, userId);
    
    // Sync with server
    _httpClient.post('/chats/$chatId/mark-read', body: {
      'userId': userId,
      'readAt': DateTimeHelper.toIso8601(DateTime.now()),
    }).catchError((e) => debugPrint('Failed to mark chat as read on server: $e'));
  }

  @override
  Future<void> toggleChatPin(String chatId, String userId) async {
    await _dbHelper.toggleChatPin(chatId, userId);
  }

  @override
  Future<void> toggleChatArchive(String chatId, String userId) async {
    await _dbHelper.toggleChatArchive(chatId, userId);
  }

  @override
  Future<void> toggleChatMute(String chatId, String userId) async {
    await _dbHelper.toggleChatMute(chatId, userId);
  }

  @override
  Future<void> deleteChat(String chatId, String userId, {bool deleteForEveryone = false}) async {
    await _dbHelper.deleteChat(chatId, userId);
    
    await _httpClient.delete('/chats/$chatId?userId=$userId&deleteForEveryone=$deleteForEveryone');
  }

  @override
  Future<void> clearChatHistory(String chatId, String userId) async {
    await _dbHelper.clearChatHistory(chatId);
    
    await _httpClient.post('/chats/$chatId/clear-history', body: {
      'userId': userId,
      'clearedAt': DateTimeHelper.toIso8601(DateTime.now()),
    });
  }

  // ========================================
  // MESSAGE OPERATIONS - FIXED
  // ========================================

  @override
  Future<String> sendMessage(MessageModel message) async {
    try {
      final messageId = message.messageId.isEmpty ? _uuid.v4() : message.messageId;
      final localMessage = message.copyWith(
        messageId: messageId,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
      );
      
      // 1. Save to local database FIRST
      await _dbHelper.insertOrUpdateMessage(localMessage);
      debugPrint('✅ Message saved to local DB: $messageId');
      
      // 2. Update chat last message
      await _dbHelper.updateChatLastMessage(
        chatId: message.chatId,
        lastMessage: message.getDisplayContent(),
        lastMessageType: message.type,
        lastMessageSender: message.senderId,
        lastMessageTime: localMessage.timestamp,
      );
      
      // 3. Send to server in background
      _sendMessageToServer(localMessage).then((_) async {
        await _dbHelper.updateMessageStatus(messageId, MessageStatus.sent);
        debugPrint('✅ Message sent to server: $messageId');
      }).catchError((e) async {
        debugPrint('❌ Failed to send message to server: $e');
        await _dbHelper.updateMessageStatus(messageId, MessageStatus.failed);
      });
      
      return messageId;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      rethrow;
    }
  }

  Future<void> _sendMessageToServer(MessageModel message) async {
    final response = await _httpClient.post('/chats/${message.chatId}/messages', body: {
      'messageId': message.messageId,
      'chatId': message.chatId,
      'senderId': message.senderId,
      'content': message.content,
      'type': message.type.name,
      'status': message.status.name,
      'timestamp': DateTimeHelper.toIso8601(message.timestamp),
      'mediaUrl': message.mediaUrl,
      'mediaMetadata': message.mediaMetadata,
      'replyToMessageId': message.replyToMessageId,
      'replyToContent': message.replyToContent,
      'replyToSender': message.replyToSender,
      'reactions': message.reactions,
      'isEdited': message.isEdited,
      'editedAt': message.editedAt != null ? DateTimeHelper.toIso8601(message.editedAt!) : null,
      'isPinned': message.isPinned,
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Server returned ${response.statusCode}');
    }
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
  // MESSAGE STREAM - FIXED TO SYNC FROM SERVER
  // ========================================

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    if (_messageStreamControllers.containsKey(chatId)) {
      return _messageStreamControllers[chatId]!.stream;
    }
    
    final controller = StreamController<List<MessageModel>>.broadcast(
      onListen: () => _startMessageStream(chatId),
      onCancel: () => _stopMessageStream(chatId),
    );
    
    _messageStreamControllers[chatId] = controller;
    return controller.stream;
  }

  void _startMessageStream(String chatId) {
    // Immediately sync from server when stream starts
    _syncMessagesFromServer(chatId);
    
    // Then poll local DB for updates
    Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      final controller = _messageStreamControllers[chatId];
      
      if (controller == null || controller.isClosed) {
        timer.cancel();
        return;
      }
      
      try {
        final messages = await _dbHelper.getChatMessages(chatId);
        if (!controller.isClosed) {
          controller.add(messages);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    });
    
    // Sync from server every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_messageStreamControllers[chatId] == null) {
        timer.cancel();
        return;
      }
      
      await _syncMessagesFromServer(chatId);
    });
  }

  void _stopMessageStream(String chatId) {
    _messageStreamControllers.remove(chatId)?.close();
  }

  // CRITICAL: This syncs messages from your PostgreSQL backend to local SQLite
  Future<void> _syncMessagesFromServer(String chatId) async {
    // Prevent concurrent syncs
    if (_isSyncing[chatId] == true) return;
    
    _isSyncing[chatId] = true;
    
    try {
      debugPrint('🔄 Syncing messages from server for chat $chatId');
      
      final response = await _httpClient.get('/chats/$chatId/messages?limit=100&sort=desc');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];

        debugPrint('📥 Received ${messagesData.length} messages from server');

        for (final messageData in messagesData) {
          try {
            final message = MessageModel.fromMap(messageData as Map<String, dynamic>);
            await _dbHelper.insertOrUpdateMessage(message);
          } catch (e) {
            debugPrint('❌ Error parsing message from server: $e');
            debugPrint('   Message data: $messageData');
          }
        }
        
        _lastSyncTime[chatId] = DateTime.now();
        debugPrint('✅ Successfully synced ${messagesData.length} messages to local DB');
      } else {
        debugPrint('❌ Server returned ${response.statusCode} for messages');
      }
    } catch (e) {
      debugPrint('❌ Error syncing messages from server: $e');
    } finally {
      _isSyncing[chatId] = false;
    }
  }

  @override
  Future<void> syncMessages(String chatId) async {
    await _syncMessagesFromServer(chatId);
  }

  @override
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    await _dbHelper.updateMessageStatus(messageId, status);
    
    _httpClient.put('/chats/$chatId/messages/$messageId/status', body: {
      'status': status.name,
      'updatedAt': DateTimeHelper.toIso8601(DateTime.now()),
    }).catchError((e) => debugPrint('Failed to update message status on server: $e'));
  }

  @override
  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    await _dbHelper.editMessage(messageId, newContent);
    
    await _httpClient.put('/chats/$chatId/messages/$messageId', body: {
      'content': newContent,
      'isEdited': true,
      'editedAt': DateTimeHelper.toIso8601(DateTime.now()),
    });
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    await _dbHelper.deleteMessage(messageId);
    
    await _httpClient.delete('/chats/$chatId/messages/$messageId?deleteForEveryone=$deleteForEveryone');
  }

  @override
  Future<void> pinMessage(String chatId, String messageId) async {
    await _dbHelper.togglePinMessage(messageId);
    
    await _httpClient.post('/chats/$chatId/messages/$messageId/pin', body: {
      'pinnedAt': DateTimeHelper.toIso8601(DateTime.now()),
    });
  }

  @override
  Future<void> unpinMessage(String chatId, String messageId) async {
    await _dbHelper.togglePinMessage(messageId);
    
    await _httpClient.delete('/chats/$chatId/messages/$messageId/pin');
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
  Future<void> syncAllData(String userId) async {
    try {
      // Sync chats
      final response = await _httpClient.get('/chats?userId=$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> chatsData = data['chats'] ?? [];

        for (final chatData in chatsData) {
          try {
            final chat = ChatModel.fromMap(chatData as Map<String, dynamic>);
            await _dbHelper.insertOrUpdateChat(chat);
            
            // Sync messages for each chat
            await _syncMessagesFromServer(chat.chatId);
          } catch (e) {
            debugPrint('Error parsing chat: $e');
          }
        }
      }
      
      debugPrint('✅ All data synced successfully');
    } catch (e) {
      debugPrint('❌ Error syncing all data: $e');
    }
  }

  // ========================================
  // CLEANUP
  // ========================================

  void dispose() {
    for (final controller in _chatStreamControllers.values) {
      controller.close();
    }
    _chatStreamControllers.clear();
    
    for (final controller in _messageStreamControllers.values) {
      controller.close();
    }
    _messageStreamControllers.clear();
    
    debugPrint('Chat repository disposed');
  }
}

// ========================================
// REPOSITORY PROVIDER
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