// lib/features/chat/repositories/chat_repository.dart
// FIXED: Stable chat streams with proper change detection and reduced polling
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
// FIXED IMPLEMENTATION WITH STABLE STREAMS
// ========================================

class OfflineFirstChatRepository implements ChatRepository {
  final HttpClientService _httpClient;
  final ChatDatabaseHelper _dbHelper;
  final Uuid _uuid;
  
  // Stream controllers with change detection
  final Map<String, StreamController<List<ChatModel>>> _chatStreamControllers = {};
  final Map<String, StreamController<List<MessageModel>>> _messageStreamControllers = {};
  
  // Sync tracking
  final Map<String, bool> _isSyncing = {};
  final Map<String, DateTime> _lastSyncTime = {};
  
  // CRITICAL: Cache to prevent unnecessary UI updates
  final Map<String, List<ChatModel>> _lastChatData = {};
  final Map<String, List<MessageModel>> _lastMessageData = {};
  
  // Timers for controlled polling
  final Map<String, Timer> _chatTimers = {};
  final Map<String, Timer> _messageTimers = {};
  final Map<String, Timer> _syncTimers = {};
  
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
  // FIXED CHAT STREAM WITH CHANGE DETECTION
  // ========================================

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
    debugPrint('🎯 Starting chat stream for user: $userId');
    
    // Initial load
    _loadAndEmitChats(userId);
    
    // FIXED: Poll every 3 seconds instead of every 1 second
    // AND only emit if data actually changed
    _chatTimers[userId] = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final controller = _chatStreamControllers[userId];
      
      if (controller == null || controller.isClosed) {
        timer.cancel();
        _chatTimers.remove(userId);
        return;
      }
      
      await _loadAndEmitChats(userId);
    });
    
    // Background sync every 2 minutes (reduced frequency)
    _syncTimers[userId] = Timer.periodic(const Duration(minutes: 2), (timer) async {
      if (_chatStreamControllers[userId] == null) {
        timer.cancel();
        _syncTimers.remove(userId);
        return;
      }
      
      // Only sync if not currently syncing
      if (_isSyncing[userId] != true) {
        await _syncChatsFromServer(userId);
      }
    });
  }

  // CRITICAL: Only emit if data actually changed
  Future<void> _loadAndEmitChats(String userId) async {
    try {
      final chats = await _dbHelper.getUserChats(userId);
      final controller = _chatStreamControllers[userId];
      
      if (controller == null || controller.isClosed) return;
      
      // CHANGE DETECTION: Compare with last emitted data
      final lastChats = _lastChatData[userId];
      
      if (lastChats == null || !_areChatsEqual(lastChats, chats)) {
        debugPrint('📊 Chat data changed - emitting ${chats.length} chats for $userId');
        _lastChatData[userId] = List.from(chats); // Store copy
        controller.add(chats);
      } else {
        // Data unchanged - don't emit
        debugPrint('📊 Chat data unchanged - skipping emit for $userId');
      }
    } catch (e, stack) {
      debugPrint('❌ Error loading chats for $userId: $e');
      final controller = _chatStreamControllers[userId];
      if (controller != null && !controller.isClosed) {
        controller.addError(e, stack);
      }
    }
  }

  // Compare two chat lists to detect changes
  bool _areChatsEqual(List<ChatModel> list1, List<ChatModel> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      final chat1 = list1[i];
      final chat2 = list2[i];
      
      // Compare key fields that would affect UI
      if (chat1.chatId != chat2.chatId ||
          chat1.lastMessage != chat2.lastMessage ||
          chat1.lastMessageTime != chat2.lastMessageTime ||
          chat1.lastMessageSender != chat2.lastMessageSender ||
          chat1.unreadCounts.toString() != chat2.unreadCounts.toString() ||
          chat1.isPinned.toString() != chat2.isPinned.toString() ||
          chat1.isArchived.toString() != chat2.isArchived.toString() ||
          chat1.isMuted.toString() != chat2.isMuted.toString()) {
        return false;
      }
    }
    
    return true;
  }

  void _stopChatStream(String userId) {
    debugPrint('🛑 Stopping chat stream for user: $userId');
    
    _chatTimers[userId]?.cancel();
    _chatTimers.remove(userId);
    
    _syncTimers[userId]?.cancel();
    _syncTimers.remove(userId);
    
    _chatStreamControllers.remove(userId)?.close();
    _lastChatData.remove(userId);
  }

  // ========================================
  // FIXED MESSAGE STREAM WITH CHANGE DETECTION
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
    debugPrint('📬 Starting message stream for chat: $chatId');
    
    // Initial sync and load
    _syncMessagesFromServer(chatId).then((_) {
      _loadAndEmitMessages(chatId);
    });
    
    // FIXED: Poll every 2 seconds instead of 500ms
    // AND only emit if data actually changed
    _messageTimers[chatId] = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final controller = _messageStreamControllers[chatId];
      
      if (controller == null || controller.isClosed) {
        timer.cancel();
        _messageTimers.remove(chatId);
        return;
      }
      
      await _loadAndEmitMessages(chatId);
    });
    
    // Background sync every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_messageStreamControllers[chatId] == null) {
        timer.cancel();
        return;
      }
      
      if (_isSyncing[chatId] != true) {
        await _syncMessagesFromServer(chatId);
      }
    });
  }

  // CRITICAL: Only emit if messages actually changed
  Future<void> _loadAndEmitMessages(String chatId) async {
    try {
      final messages = await _dbHelper.getChatMessages(chatId);
      final controller = _messageStreamControllers[chatId];
      
      if (controller == null || controller.isClosed) return;
      
      // CHANGE DETECTION: Compare with last emitted data
      final lastMessages = _lastMessageData[chatId];
      
      if (lastMessages == null || !_areMessagesEqual(lastMessages, messages)) {
        debugPrint('📬 Message data changed - emitting ${messages.length} messages for $chatId');
        _lastMessageData[chatId] = List.from(messages); // Store copy
        controller.add(messages);
      } else {
        // Data unchanged - don't emit
        debugPrint('📬 Message data unchanged - skipping emit for $chatId');
      }
    } catch (e, stack) {
      debugPrint('❌ Error loading messages for $chatId: $e');
      final controller = _messageStreamControllers[chatId];
      if (controller != null && !controller.isClosed) {
        controller.addError(e, stack);
      }
    }
  }

  // Compare two message lists to detect changes
  bool _areMessagesEqual(List<MessageModel> list1, List<MessageModel> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      final msg1 = list1[i];
      final msg2 = list2[i];
      
      // Compare key fields that would affect UI
      if (msg1.messageId != msg2.messageId ||
          msg1.content != msg2.content ||
          msg1.status != msg2.status ||
          msg1.timestamp != msg2.timestamp ||
          msg1.isEdited != msg2.isEdited ||
          msg1.isPinned != msg2.isPinned) {
        return false;
      }
    }
    
    return true;
  }

  void _stopMessageStream(String chatId) {
    debugPrint('🛑 Stopping message stream for chat: $chatId');
    
    _messageTimers[chatId]?.cancel();
    _messageTimers.remove(chatId);
    
    _messageStreamControllers.remove(chatId)?.close();
    _lastMessageData.remove(chatId);
  }

  // ========================================
  // IMPROVED SYNC WITH CONFLICT RESOLUTION
  // ========================================

  Future<void> _syncChatsFromServer(String userId) async {
    if (_isSyncing[userId] == true) {
      debugPrint('⏳ Chat sync already in progress for user $userId');
      return;
    }
    
    _isSyncing[userId] = true;
    
    try {
      debugPrint('🔄 Syncing chats from server for user $userId');
      
      final response = await _httpClient.get('/chats?userId=$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> chatsData = data['chats'] ?? [];

        debugPrint('📥 Received ${chatsData.length} chats from server');

        // Batch update for better performance
        final chatsToUpdate = <ChatModel>[];
        
        for (final chatData in chatsData) {
          try {
            final chat = ChatModel.fromMap(chatData as Map<String, dynamic>);
            chatsToUpdate.add(chat);
          } catch (e) {
            debugPrint('❌ Error parsing chat from server: $e');
          }
        }
        
        // Batch insert all chats
        if (chatsToUpdate.isNotEmpty) {
          await _dbHelper.batchInsertChats(chatsToUpdate);
        }
        
        _lastSyncTime[userId] = DateTime.now();
        debugPrint('✅ Successfully synced ${chatsToUpdate.length} chats to local DB');
        
        // Trigger immediate refresh after sync
        await _loadAndEmitChats(userId);
      } else {
        debugPrint('❌ Server returned ${response.statusCode} for chats');
      }
    } catch (e) {
      debugPrint('❌ Error syncing chats from server: $e');
    } finally {
      _isSyncing[userId] = false;
    }
  }

  Future<void> _syncMessagesFromServer(String chatId) async {
    if (_isSyncing[chatId] == true) return;
    
    _isSyncing[chatId] = true;
    
    try {
      debugPrint('🔄 Syncing messages from server for chat $chatId');
      
      final response = await _httpClient.get('/chats/$chatId/messages?limit=100&sort=desc');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];

        debugPrint('📥 Received ${messagesData.length} messages from server');

        // Batch update for better performance
        final messagesToUpdate = <MessageModel>[];
        
        for (final messageData in messagesData) {
          try {
            final message = MessageModel.fromMap(messageData as Map<String, dynamic>);
            messagesToUpdate.add(message);
          } catch (e) {
            debugPrint('❌ Error parsing message from server: $e');
          }
        }
        
        // Batch insert all messages
        if (messagesToUpdate.isNotEmpty) {
          await _dbHelper.batchInsertMessages(messagesToUpdate);
        }
        
        _lastSyncTime[chatId] = DateTime.now();
        debugPrint('✅ Successfully synced ${messagesToUpdate.length} messages to local DB');
        
        // Trigger immediate refresh after sync
        await _loadAndEmitMessages(chatId);
      } else {
        debugPrint('❌ Server returned ${response.statusCode} for messages');
      }
    } catch (e) {
      debugPrint('❌ Error syncing messages from server: $e');
    } finally {
      _isSyncing[chatId] = false;
    }
  }

  // ========================================
  // REST OF THE IMPLEMENTATION (UNCHANGED)
  // ========================================

  @override
  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    final chatId = generateChatId(currentUserId, otherUserId);
    
    try {
      var chat = await _dbHelper.getChatById(chatId);
      
      if (chat != null) {
        return chatId;
      }
      
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
  // MESSAGE OPERATIONS
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
      await _syncChatsFromServer(userId);
      
      // Get all chats and sync their messages
      final chats = await _dbHelper.getUserChats(userId);
      
      for (final chat in chats) {
        await _syncMessagesFromServer(chat.chatId);
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
    // Cancel all timers
    for (final timer in _chatTimers.values) {
      timer.cancel();
    }
    _chatTimers.clear();
    
    for (final timer in _messageTimers.values) {
      timer.cancel();
    }
    _messageTimers.clear();
    
    for (final timer in _syncTimers.values) {
      timer.cancel();
    }
    _syncTimers.clear();
    
    // Close all stream controllers
    for (final controller in _chatStreamControllers.values) {
      controller.close();
    }
    _chatStreamControllers.clear();
    
    for (final controller in _messageStreamControllers.values) {
      controller.close();
    }
    _messageStreamControllers.clear();
    
    // Clear caches
    _lastChatData.clear();
    _lastMessageData.clear();
    _isSyncing.clear();
    _lastSyncTime.clear();
    
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