// lib/features/chat/repositories/chat_repository.dart
// Updated chat repository with SQLite offline storage and HTTP sync
// UPDATED: Offline-first architecture with local database caching
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/models/video_reaction_model.dart';
import 'package:textgb/features/chat/models/moment_reaction_model.dart';
import 'package:textgb/features/chat/database/chat_database_helper.dart';
import 'package:textgb/shared/services/http_client.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

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
  Future<void> setChatWallpaper(String chatId, String userId, String? wallpaperUrl);
  Future<void> setChatFontSize(String chatId, String userId, double fontSize);
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
  Future<void> markMessageAsDelivered(String chatId, String messageId, String userId);
  Future<void> markMessageAsRead(String chatId, String messageId, String userId);
  Future<void> editMessage(String chatId, String messageId, String newContent);
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone);
  Future<void> pinMessage(String chatId, String messageId);
  Future<void> unpinMessage(String chatId, String messageId);
  Future<List<MessageModel>> searchMessages(String chatId, String query);
  Future<List<MessageModel>> getPinnedMessages(String chatId);
  Future<void> addMessageReaction(String chatId, String messageId, String userId, String emoji);
  Future<void> removeMessageReaction(String chatId, String messageId, String userId);

  // Media operations
  Future<String> uploadMedia(File file, String fileName, String chatId);
  Future<void> deleteMedia(String mediaUrl);

  // User presence and status
  Future<void> updateUserPresence(String userId, bool isOnline);
  Future<Map<String, bool>> getUsersPresence(List<String> userIds);
  Future<void> updateUserTypingStatus(String chatId, String userId, bool isTyping);
  Future<Map<String, bool>> getChatTypingStatus(String chatId);

  // Utility
  String generateChatId(String userId1, String userId2);
  Future<bool> chatHasMessages(String chatId);
  Future<List<String>> getUserChats(String userId);
  Future<int> getUnreadMessagesCount(String userId);
  Future<int> getChatUnreadCount(String chatId, String userId);

  // Sync operations
  Future<void> syncChats(String userId);
  Future<void> syncMessages(String chatId);
  Future<void> syncAllData(String userId);
}

// ========================================
// OFFLINE-FIRST HTTP IMPLEMENTATION
// ========================================

class OfflineFirstChatRepository implements ChatRepository {
  final HttpClientService _httpClient;
  final ChatDatabaseHelper _dbHelper;
  final Uuid _uuid;
  
  // Stream controllers for real-time updates
  final Map<String, StreamController<List<ChatModel>>> _chatStreamControllers = {};
  final Map<String, StreamController<List<MessageModel>>> _messageStreamControllers = {};
  
  // Sync timers
  Timer? _syncTimer;
  bool _isSyncing = false;

  OfflineFirstChatRepository({
    HttpClientService? httpClient,
    ChatDatabaseHelper? dbHelper,
    Uuid? uuid,
  })  : _httpClient = httpClient ?? HttpClientService(),
        _dbHelper = dbHelper ?? ChatDatabaseHelper(),
        _uuid = uuid ?? const Uuid() {
    _startAutoSync();
  }

  // Helper method to create RFC3339 timestamps
  String _createTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  @override
  String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // ========================================
  // AUTO SYNC FUNCTIONALITY
  // ========================================

  void _startAutoSync() {
    // Sync every 30 seconds when app is active
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isSyncing) {
        _syncPendingData();
      }
    });
  }

  Future<void> _syncPendingData() async {
    if (_isSyncing) return;
    
    try {
      _isSyncing = true;
      
      // Sync unsent messages
      final unsentMessages = await _dbHelper.getUnsyncedMessages();
      for (final message in unsentMessages) {
        if (message.status == MessageStatus.sending || message.status == MessageStatus.failed) {
          await _sendMessageToServer(message);
        }
      }
      
      debugPrint('Auto-sync completed: ${unsentMessages.length} messages synced');
    } catch (e) {
      debugPrint('Auto-sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ========================================
  // CHAT OPERATIONS (OFFLINE-FIRST)
  // ========================================

  @override
  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    final chatId = generateChatId(currentUserId, otherUserId);
    
    try {
      // Check local database first
      var chat = await _dbHelper.getChatById(chatId);
      
      if (chat == null) {
        // Create new chat locally
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
        
        await _dbHelper.insertOrUpdateChat(chat);
        
        // Try to sync with server
        _createChatOnServer(chat).catchError((e) {
          debugPrint('Failed to create chat on server: $e');
        });
      }
      
      return chatId;
    } catch (e) {
      debugPrint('Error creating/getting chat: $e');
      throw ChatRepositoryException('Failed to create or get chat: $e');
    }
  }

  Future<void> _createChatOnServer(ChatModel chat) async {
    try {
      final response = await _httpClient.post('/chats', body: {
        'participants': chat.participants,
        'createdAt': chat.createdAt.toIso8601String(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _dbHelper.markChatAsSynced(chat.chatId);
      }
    } catch (e) {
      debugPrint('Error creating chat on server: $e');
      rethrow;
    }
  }

  @override
  Stream<List<ChatModel>> getChatsStream(String userId) {
    // Return existing stream controller if available
    if (_chatStreamControllers.containsKey(userId)) {
      return _chatStreamControllers[userId]!.stream;
    }
    
    // Create new stream controller
    final controller = StreamController<List<ChatModel>>.broadcast(
      onListen: () => _startChatSync(userId),
      onCancel: () => _stopChatSync(userId),
    );
    
    _chatStreamControllers[userId] = controller;
    
    return controller.stream;
  }

  Future<void> _startChatSync(String userId) async {
    final controller = _chatStreamControllers[userId];
    if (controller == null) return;
    
    // First, emit local data immediately
    final localChats = await _dbHelper.getUserChats(userId);
    controller.add(localChats);
    
    // Then sync with server periodically
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      
      try {
        // Fetch from server
        await _syncChatsFromServer(userId);
        
        // Get updated local data and emit
        final updatedChats = await _dbHelper.getUserChats(userId);
        if (!controller.isClosed) {
          controller.add(updatedChats);
        }
      } catch (e) {
        debugPrint('Chat sync error: $e');
        // Still emit local data on error
        final localChats = await _dbHelper.getUserChats(userId);
        if (!controller.isClosed) {
          controller.add(localChats);
        }
      }
    });
  }

  void _stopChatSync(String userId) {
    final controller = _chatStreamControllers.remove(userId);
    controller?.close();
  }

  Future<void> _syncChatsFromServer(String userId) async {
    try {
      final response = await _httpClient.get('/chats');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> chatsData = data['chats'] ?? [];

        // Save to local database
        for (final chatData in chatsData) {
          try {
            final chat = ChatModel.fromMap(chatData as Map<String, dynamic>);
            await _dbHelper.insertOrUpdateChat(chat);
          } catch (e) {
            debugPrint('Error parsing chat: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing chats from server: $e');
    }
  }

  @override
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      // Get from local database first
      var chat = await _dbHelper.getChatById(chatId);
      
      // Try to sync from server in background
      _syncChatFromServer(chatId).catchError((e) {
        debugPrint('Failed to sync chat from server: $e');
      });
      
      return chat;
    } catch (e) {
      debugPrint('Error getting chat by ID: $e');
      return null;
    }
  }

  Future<void> _syncChatFromServer(String chatId) async {
    try {
      final response = await _httpClient.get('/chats/$chatId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final chat = ChatModel.fromMap(data);
        await _dbHelper.insertOrUpdateChat(chat);
      }
    } catch (e) {
      debugPrint('Error syncing chat from server: $e');
    }
  }

  @override
  Future<void> updateChatLastMessage(ChatModel chat) async {
    try {
      // Update local database immediately
      await _dbHelper.updateChatLastMessage(
        chatId: chat.chatId,
        lastMessage: chat.lastMessage,
        lastMessageType: chat.lastMessageType,
        lastMessageSender: chat.lastMessageSender,
        lastMessageTime: chat.lastMessageTime,
      );
      
      // Sync with server in background
      _updateChatOnServer(chat).catchError((e) {
        debugPrint('Failed to update chat on server: $e');
      });
    } catch (e) {
      debugPrint('Error updating chat last message: $e');
      rethrow;
    }
  }

  Future<void> _updateChatOnServer(ChatModel chat) async {
    try {
      final response = await _httpClient.put('/chats/${chat.chatId}/last-message', body: {
        'lastMessage': chat.lastMessage,
        'lastMessageType': chat.lastMessageType.name,
        'lastMessageSender': chat.lastMessageSender,
        'lastMessageTime': chat.lastMessageTime.toIso8601String(),
        'updatedAt': _createTimestamp(),
      });

      if (response.statusCode == 200) {
        await _dbHelper.markChatAsSynced(chat.chatId);
      }
    } catch (e) {
      debugPrint('Error updating chat on server: $e');
    }
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      // Update local database immediately
      await _dbHelper.markChatAsRead(chatId, userId);
      
      // Sync with server in background
      _markChatAsReadOnServer(chatId, userId).catchError((e) {
        debugPrint('Failed to mark chat as read on server: $e');
      });
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
      rethrow;
    }
  }

  Future<void> _markChatAsReadOnServer(String chatId, String userId) async {
    try {
      await _httpClient.post('/chats/$chatId/mark-read', body: {
        'userId': userId,
        'readAt': _createTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking chat as read on server: $e');
    }
  }

  @override
  Future<void> toggleChatPin(String chatId, String userId) async {
    try {
      // Update local database immediately
      await _dbHelper.toggleChatPin(chatId, userId);
      
      // Sync with server
      await _httpClient.post('/chats/$chatId/toggle-pin', body: {
        'userId': userId,
        'pinnedAt': _createTimestamp(),
      });
    } catch (e) {
      debugPrint('Error toggling chat pin: $e');
      // Revert local change on server error
      await _dbHelper.toggleChatPin(chatId, userId);
      rethrow;
    }
  }

  @override
  Future<void> toggleChatArchive(String chatId, String userId) async {
    try {
      // Update local database immediately
      await _dbHelper.toggleChatArchive(chatId, userId);
      
      // Sync with server
      await _httpClient.post('/chats/$chatId/toggle-archive', body: {
        'userId': userId,
        'archivedAt': _createTimestamp(),
      });
    } catch (e) {
      debugPrint('Error toggling chat archive: $e');
      // Revert local change on server error
      await _dbHelper.toggleChatArchive(chatId, userId);
      rethrow;
    }
  }

  @override
  Future<void> toggleChatMute(String chatId, String userId) async {
    try {
      // Update local database immediately
      await _dbHelper.toggleChatMute(chatId, userId);
      
      // Sync with server
      await _httpClient.post('/chats/$chatId/toggle-mute', body: {
        'userId': userId,
        'mutedAt': _createTimestamp(),
      });
    } catch (e) {
      debugPrint('Error toggling chat mute: $e');
      // Revert local change on server error
      await _dbHelper.toggleChatMute(chatId, userId);
      rethrow;
    }
  }

  @override
  Future<void> setChatWallpaper(String chatId, String userId, String? wallpaperUrl) async {
    try {
      // Update via server (not stored locally for wallpapers)
      await _httpClient.post('/chats/$chatId/wallpaper', body: {
        'userId': userId,
        'wallpaperUrl': wallpaperUrl,
        'updatedAt': _createTimestamp(),
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to set chat wallpaper: $e');
    }
  }

  @override
  Future<void> setChatFontSize(String chatId, String userId, double fontSize) async {
    try {
      // Update via server (not stored locally for font sizes)
      await _httpClient.post('/chats/$chatId/font-size', body: {
        'userId': userId,
        'fontSize': fontSize,
        'updatedAt': _createTimestamp(),
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to set chat font size: $e');
    }
  }

  @override
  Future<void> deleteChat(String chatId, String userId, {bool deleteForEveryone = false}) async {
    try {
      // Delete from local database
      await _dbHelper.deleteChat(chatId, userId);
      
      // Delete from server
      await _httpClient.delete('/chats/$chatId?userId=$userId&deleteForEveryone=$deleteForEveryone');
    } catch (e) {
      throw ChatRepositoryException('Failed to delete chat: $e');
    }
  }

  @override
  Future<void> clearChatHistory(String chatId, String userId) async {
    try {
      // Clear from local database
      await _dbHelper.clearChatHistory(chatId);
      
      // Clear on server
      await _httpClient.post('/chats/$chatId/clear-history', body: {
        'userId': userId,
        'clearedAt': _createTimestamp(),
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to clear chat history: $e');
    }
  }

  // ========================================
  // MESSAGE OPERATIONS (OFFLINE-FIRST)
  // ========================================

  @override
  Future<String> sendMessage(MessageModel message) async {
    try {
      final messageId = message.messageId.isEmpty ? _uuid.v4() : message.messageId;
      final localMessage = message.copyWith(
        messageId: messageId,
        status: MessageStatus.sending,
      );
      
      // Save to local database immediately
      await _dbHelper.insertOrUpdateMessage(localMessage);
      
      // Update chat last message
      await _dbHelper.updateChatLastMessage(
        chatId: message.chatId,
        lastMessage: message.getDisplayContent(),
        lastMessageType: message.type,
        lastMessageSender: message.senderId,
        lastMessageTime: message.timestamp,
      );
      
      // Send to server in background
      _sendMessageToServer(localMessage).then((_) async {
        // Update status to sent on success
        await _dbHelper.updateMessageStatus(messageId, MessageStatus.sent);
      }).catchError((e) async {
        // Update status to failed on error
        debugPrint('Failed to send message to server: $e');
        await _dbHelper.updateMessageStatus(messageId, MessageStatus.failed);
      });
      
      return messageId;
    } catch (e) {
      throw ChatRepositoryException('Failed to send message: $e');
    }
  }

  Future<void> _sendMessageToServer(MessageModel message) async {
    try {
      final response = await _httpClient.post('/chats/${message.chatId}/messages', body: {
        'messageId': message.messageId,
        'chatId': message.chatId,
        'senderId': message.senderId,
        'content': message.content,
        'type': message.type.name,
        'status': message.status.name,
        'timestamp': message.timestamp.toIso8601String(),
        'mediaUrl': message.mediaUrl,
        'mediaMetadata': message.mediaMetadata,
        'replyToMessageId': message.replyToMessageId,
        'replyToContent': message.replyToContent,
        'replyToSender': message.replyToSender,
        'reactions': message.reactions,
        'isEdited': message.isEdited,
        'editedAt': message.editedAt?.toIso8601String(),
        'isPinned': message.isPinned,
        'readBy': message.readBy?.map((k, v) => MapEntry(k, v.toIso8601String())),
        'deliveredTo': message.deliveredTo?.map((k, v) => MapEntry(k, v.toIso8601String())),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _dbHelper.markMessageAsSynced(message.messageId);
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending message to server: $e');
      rethrow;
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
        'thumbnailUrl': momentReaction.thumbnailUrl,
        'momentId': momentReaction.momentId,
        'authorName': momentReaction.authorName,
        'authorImage': momentReaction.authorImage,
        'mediaType': momentReaction.mediaType,
        'momentContent': momentReaction.content,
      },
    );

    return await sendMessage(message);
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    // Return existing stream controller if available
    if (_messageStreamControllers.containsKey(chatId)) {
      return _messageStreamControllers[chatId]!.stream;
    }
    
    // Create new stream controller
    final controller = StreamController<List<MessageModel>>.broadcast(
      onListen: () => _startMessageSync(chatId),
      onCancel: () => _stopMessageSync(chatId),
    );
    
    _messageStreamControllers[chatId] = controller;
    
    return controller.stream;
  }

  Future<void> _startMessageSync(String chatId) async {
    final controller = _messageStreamControllers[chatId];
    if (controller == null) return;
    
    // First, emit local data immediately
    final localMessages = await _dbHelper.getChatMessages(chatId);
    controller.add(localMessages);
    
    // Then sync with server periodically
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      
      try {
        // Fetch from server
        await _syncMessagesFromServer(chatId);
        
        // Get updated local data and emit
        final updatedMessages = await _dbHelper.getChatMessages(chatId);
        if (!controller.isClosed) {
          controller.add(updatedMessages);
        }
      } catch (e) {
        debugPrint('Message sync error: $e');
        // Still emit local data on error
        final localMessages = await _dbHelper.getChatMessages(chatId);
        if (!controller.isClosed) {
          controller.add(localMessages);
        }
      }
    });
  }

  void _stopMessageSync(String chatId) {
    final controller = _messageStreamControllers.remove(chatId);
    controller?.close();
  }

  Future<void> _syncMessagesFromServer(String chatId) async {
    try {
      final response = await _httpClient.get('/chats/$chatId/messages?limit=100&sort=desc');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];

        // Save to local database
        for (final messageData in messagesData) {
          try {
            final message = MessageModel.fromMap(messageData as Map<String, dynamic>);
            await _dbHelper.insertOrUpdateMessage(message);
          } catch (e) {
            debugPrint('Error parsing message: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing messages from server: $e');
    }
  }

  @override
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    try {
      // Update local database
      await _dbHelper.updateMessageStatus(messageId, status);
      
      // Sync with server in background
      _httpClient.put('/chats/$chatId/messages/$messageId/status', body: {
        'status': status.name,
        'updatedAt': _createTimestamp(),
      }).catchError((e) {
        debugPrint('Failed to update message status on server: $e');
      });
    } catch (e) {
      debugPrint('Error updating message status: $e');
      rethrow;
    }
  }

  @override
  Future<void> markMessageAsDelivered(String chatId, String messageId, String userId) async {
    try {
      // Update via server (delivery tracking on server side)
      await _httpClient.post('/chats/$chatId/messages/$messageId/delivered', body: {
        'userId': userId,
        'deliveredAt': _createTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking message as delivered: $e');
    }
  }

  @override
  Future<void> markMessageAsRead(String chatId, String messageId, String userId) async {
    try {
      // Update via server (read tracking on server side)
      await _httpClient.post('/chats/$chatId/messages/$messageId/read', body: {
        'userId': userId,
        'readAt': _createTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  @override
  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    try {
      // Update local database
      await _dbHelper.editMessage(messageId, newContent);
      
      // Sync with server
      await _httpClient.put('/chats/$chatId/messages/$messageId', body: {
        'content': newContent,
        'isEdited': true,
        'editedAt': _createTimestamp(),
        'updatedAt': _createTimestamp(),
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to edit message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    try {
      // Delete from local database
      await _dbHelper.deleteMessage(messageId);
      
      // Delete from server
      await _httpClient.delete('/chats/$chatId/messages/$messageId?deleteForEveryone=$deleteForEveryone');
    } catch (e) {
      throw ChatRepositoryException('Failed to delete message: $e');
    }
  }

  @override
  Future<void> pinMessage(String chatId, String messageId) async {
    try {
      // Update local database
      await _dbHelper.togglePinMessage(messageId);
      
      // Sync with server
      await _httpClient.post('/chats/$chatId/messages/$messageId/pin', body: {
        'pinnedAt': _createTimestamp(),
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to pin message: $e');
    }
  }

  @override
  Future<void> unpinMessage(String chatId, String messageId) async {
    try {
      // Update local database
      await _dbHelper.togglePinMessage(messageId);
      
      // Sync with server
      await _httpClient.delete('/chats/$chatId/messages/$messageId/pin');
    } catch (e) {
      throw ChatRepositoryException('Failed to unpin message: $e');
    }
  }

  @override
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    try {
      // Search in local database first
      final localResults = await _dbHelper.searchMessages(chatId, query);
      
      // Also try to get server results (don't wait for them)
      _searchMessagesOnServer(chatId, query).catchError((e) {
        debugPrint('Failed to search messages on server: $e');
      });
      
      return localResults;
    } catch (e) {
      throw ChatRepositoryException('Failed to search messages: $e');
    }
  }

  Future<List<MessageModel>> _searchMessagesOnServer(String chatId, String query) async {
    try {
      final response = await _httpClient.get(
          '/chats/$chatId/messages/search?q=${Uri.encodeComponent(query)}&limit=100');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];

        final messages = messagesData
            .map((messageData) => MessageModel.fromMap(messageData as Map<String, dynamic>))
            .toList();

        // Save results to local database
        for (final message in messages) {
          await _dbHelper.insertOrUpdateMessage(message);
        }

        return messages;
      }
      return [];
    } catch (e) {
      debugPrint('Error searching messages on server: $e');
      return [];
    }
  }

  @override
  Future<List<MessageModel>> getPinnedMessages(String chatId) async {
    try {
      // Get from local database first
      final localPinned = await _dbHelper.getPinnedMessages(chatId);
      
      // Sync with server in background
      _syncPinnedMessagesFromServer(chatId).catchError((e) {
        debugPrint('Failed to sync pinned messages from server: $e');
      });
      
      return localPinned;
    } catch (e) {
      throw ChatRepositoryException('Failed to get pinned messages: $e');
    }
  }

  Future<void> _syncPinnedMessagesFromServer(String chatId) async {
    try {
      final response = await _httpClient.get('/chats/$chatId/messages/pinned');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];

        for (final messageData in messagesData) {
          final message = MessageModel.fromMap(messageData as Map<String, dynamic>);
          await _dbHelper.insertOrUpdateMessage(message);
        }
      }
    } catch (e) {
      debugPrint('Error syncing pinned messages from server: $e');
    }
  }

  @override
  Future<void> addMessageReaction(String chatId, String messageId, String userId, String emoji) async {
    try {
      // Update via server (reactions managed server-side)
      await _httpClient.post('/chats/$chatId/messages/$messageId/reactions', body: {
        'userId': userId,
        'emoji': emoji,
        'reactedAt': _createTimestamp(),
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to add message reaction: $e');
    }
  }

  @override
  Future<void> removeMessageReaction(String chatId, String messageId, String userId) async {
    try {
      // Update via server (reactions managed server-side)
      await _httpClient.delete('/chats/$chatId/messages/$messageId/reactions/$userId');
    } catch (e) {
      throw ChatRepositoryException('Failed to remove message reaction: $e');
    }
  }

  // ========================================
  // MEDIA OPERATIONS
  // ========================================

  @override
  Future<String> uploadMedia(File file, String fileName, String chatId) async {
    try {
      // Check file size
      final fileSize = await file.length();
      if (fileSize > 100 * 1024 * 1024) {
        throw ChatRepositoryException('File size exceeds 100MB limit');
      }

      final response = await _httpClient.uploadFile(
        '/upload',
        file,
        'file',
        additionalFields: {
          'type': 'chat_media',
          'chatId': chatId,
          'fileName': fileName,
          'uploadedAt': _createTimestamp(),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final mediaUrl = data['url'] as String;
        
        // Save media info to local database
        await _dbHelper.insertOrUpdateMedia(
          messageId: _uuid.v4(), // Will be updated when message is created
          chatId: chatId,
          mediaUrl: mediaUrl,
          mediaType: _getMediaTypeFromFile(fileName),
          fileName: fileName,
          fileSize: fileSize,
          mimeType: _getMimeTypeFromFile(fileName),
        );
        
        return mediaUrl;
      } else {
        throw ChatRepositoryException('Failed to upload media: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to upload media: $e');
    }
  }

  @override
  Future<void> deleteMedia(String mediaUrl) async {
    try {
      await _httpClient.delete('/media?url=${Uri.encodeComponent(mediaUrl)}');
    } catch (e) {
      throw ChatRepositoryException('Failed to delete media: $e');
    }
  }

  String _getMediaTypeFromFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
      return 'video';
    } else if (['mp3', 'm4a', 'wav', 'aac'].contains(extension)) {
      return 'audio';
    } else {
      return 'file';
    }
  }

  String _getMimeTypeFromFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    final mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
      'mp3': 'audio/mpeg',
      'm4a': 'audio/mp4',
      'wav': 'audio/wav',
      'aac': 'audio/aac',
    };
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  // ========================================
  // USER PRESENCE AND STATUS
  // ========================================

  @override
  Future<void> updateUserPresence(String userId, bool isOnline) async {
    try {
      // Update local database
      await _dbHelper.updateParticipantOnlineStatus(userId, isOnline);
      
      // Update on server
      await _httpClient.post('/users/$userId/presence', body: {
        'isOnline': isOnline,
        'lastSeen': _createTimestamp(),
        'updatedAt': _createTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user presence: $e');
    }
  }

  @override
  Future<Map<String, bool>> getUsersPresence(List<String> userIds) async {
    try {
      final response = await _httpClient.post('/users/presence/batch', body: {
        'userIds': userIds,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final presenceData = data['presence'] as Map<String, dynamic>? ?? {};

        final result = <String, bool>{};
        presenceData.forEach((userId, isOnline) {
          result[userId] = isOnline as bool? ?? false;
        });

        return result;
      }
      return {};
    } catch (e) {
      debugPrint('Error getting users presence: $e');
      return {};
    }
  }

  @override
  Future<void> updateUserTypingStatus(String chatId, String userId, bool isTyping) async {
    try {
      // Update local database
      await _dbHelper.updateTypingStatus(
        chatId: chatId,
        userId: userId,
        isTyping: isTyping,
      );
      
      // Update on server
      await _httpClient.post('/chats/$chatId/typing', body: {
        'userId': userId,
        'isTyping': isTyping,
        'timestamp': _createTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  @override
  Future<Map<String, bool>> getChatTypingStatus(String chatId) async {
    try {
      // Get from local database first
      final typingUsers = await _dbHelper.getTypingUsers(chatId);
      final result = <String, bool>{};
      for (final userId in typingUsers) {
        result[userId] = true;
      }
      
      // Also try to get from server
      final response = await _httpClient.get('/chats/$chatId/typing');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final typingData = data['typing'] as Map<String, dynamic>? ?? {};
        
        typingData.forEach((userId, isTyping) {
          result[userId] = isTyping as bool? ?? false;
        });
      }
      
      return result;
    } catch (e) {
      debugPrint('Error getting chat typing status: $e');
      return {};
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  @override
  Future<bool> chatHasMessages(String chatId) async {
    try {
      // Check local database first
      final localMessages = await _dbHelper.getChatMessages(chatId, limit: 1);
      if (localMessages.isNotEmpty) return true;
      
      // Check server
      final response = await _httpClient.get('/chats/$chatId/has-messages');
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
  Future<List<String>> getUserChats(String userId) async {
    try {
      // Get from local database
      final chats = await _dbHelper.getUserChats(userId);
      return chats.map((chat) => chat.chatId).toList();
    } catch (e) {
      throw ChatRepositoryException('Failed to get user chats: $e');
    }
  }

  @override
  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      // Get from local database
      final chats = await _dbHelper.getUserChats(userId);
      int totalUnread = 0;
      
      for (final chat in chats) {
        final unreadCount = await _dbHelper.getUnreadMessagesCount(chat.chatId, userId);
        totalUnread += unreadCount;
      }
      
      return totalUnread;
    } catch (e) {
      debugPrint('Error getting unread messages count: $e');
      return 0;
    }
  }

  @override
  Future<int> getChatUnreadCount(String chatId, String userId) async {
    try {
      // Get from local database
      return await _dbHelper.getUnreadMessagesCount(chatId, userId);
    } catch (e) {
      debugPrint('Error getting chat unread count: $e');
      return 0;
    }
  }

  // ========================================
  // SYNC OPERATIONS
  // ========================================

  @override
  Future<void> syncChats(String userId) async {
    try {
      await _syncChatsFromServer(userId);
    } catch (e) {
      debugPrint('Error syncing chats: $e');
      rethrow;
    }
  }

  @override
  Future<void> syncMessages(String chatId) async {
    try {
      await _syncMessagesFromServer(chatId);
    } catch (e) {
      debugPrint('Error syncing messages: $e');
      rethrow;
    }
  }

  @override
  Future<void> syncAllData(String userId) async {
    try {
      // Sync chats
      await _syncChatsFromServer(userId);
      
      // Get all chats
      final chats = await _dbHelper.getUserChats(userId);
      
      // Sync messages for each chat
      for (final chat in chats) {
        await _syncMessagesFromServer(chat.chatId);
      }
      
      debugPrint('All data synced successfully');
    } catch (e) {
      debugPrint('Error syncing all data: $e');
      rethrow;
    }
  }

  // ========================================
  // CLEANUP AND DISPOSAL
  // ========================================

  void dispose() {
    _syncTimer?.cancel();
    
    // Close all stream controllers
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

  // Clear local cache
  Future<void> clearLocalCache() async {
    try {
      await _dbHelper.clearAllData();
      debugPrint('Local cache cleared');
    } catch (e) {
      debugPrint('Error clearing local cache: $e');
      rethrow;
    }
  }

  // Get local database statistics
  Future<Map<String, int>> getLocalStatistics() async {
    try {
      return await _dbHelper.getDatabaseStatistics();
    } catch (e) {
      debugPrint('Error getting local statistics: $e');
      return {};
    }
  }

  // Cleanup old messages
  Future<int> cleanupOldMessages({int daysOld = 365}) async {
    try {
      return await _dbHelper.deleteOldMessages(daysOld: daysOld);
    } catch (e) {
      debugPrint('Error cleaning up old messages: $e');
      return 0;
    }
  }

  // Optimize database
  Future<void> optimizeDatabase() async {
    try {
      await _dbHelper.vacuumDatabase();
      debugPrint('Database optimized');
    } catch (e) {
      debugPrint('Error optimizing database: $e');
      rethrow;
    }
  }

  // Get database size
  Future<int> getDatabaseSize() async {
    try {
      return await _dbHelper.getDatabaseSize();
    } catch (e) {
      debugPrint('Error getting database size: $e');
      return 0;
    }
  }

  // Export chat data
  Future<Map<String, dynamic>> exportChatData() async {
    try {
      return await _dbHelper.exportToJson();
    } catch (e) {
      debugPrint('Error exporting chat data: $e');
      return {};
    }
  }

  // Import chat data
  Future<void> importChatData(Map<String, dynamic> data) async {
    try {
      await _dbHelper.importFromJson(data);
      debugPrint('Chat data imported successfully');
    } catch (e) {
      debugPrint('Error importing chat data: $e');
      rethrow;
    }
  }
}

// ========================================
// REPOSITORY PROVIDER
// ========================================

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final repository = OfflineFirstChatRepository();
  
  // Cleanup when provider is disposed
  ref.onDispose(() {
    if (repository is OfflineFirstChatRepository) {
      repository.dispose();
    }
  });
  
  return repository;
});

// ========================================
// EXCEPTION CLASSES
// ========================================

class ChatRepositoryException implements Exception {
  final String message;
  const ChatRepositoryException(this.message);

  @override
  String toString() => 'ChatRepositoryException: $message';
}

class ChatNotFoundException extends ChatRepositoryException {
  const ChatNotFoundException(String chatId) : super('Chat not found: $chatId');
}

class MessageNotFoundException extends ChatRepositoryException {
  const MessageNotFoundException(String messageId)
      : super('Message not found: $messageId');
}

class UserNotInChatException extends ChatRepositoryException {
  const UserNotInChatException(String userId, String chatId)
      : super('User $userId not in chat $chatId');
}

class InsufficientPermissionsException extends ChatRepositoryException {
  const InsufficientPermissionsException(String action)
      : super('Insufficient permissions for: $action');
}

class MediaUploadException extends ChatRepositoryException {
  const MediaUploadException(String reason)
      : super('Media upload failed: $reason');
}

class NetworkException extends ChatRepositoryException {
  const NetworkException(String message) : super('Network error: $message');
}

class RateLimitException extends ChatRepositoryException {
  const RateLimitException()
      : super('Rate limit exceeded. Please try again later.');
}

class InvalidMessageTypeException extends ChatRepositoryException {
  const InvalidMessageTypeException(String type)
      : super('Invalid message type: $type');
}

class FileSizeExceededException extends ChatRepositoryException {
  final int maxSize;
  final int actualSize;
  const FileSizeExceededException(this.maxSize, this.actualSize)
      : super('File size $actualSize exceeds maximum allowed size $maxSize');
}

class UnsupportedFileTypeException extends ChatRepositoryException {
  const UnsupportedFileTypeException(String fileType)
      : super('Unsupported file type: $fileType');
}

class SyncException extends ChatRepositoryException {
  const SyncException(String message) : super('Sync error: $message');
}

class DatabaseException extends ChatRepositoryException {
  const DatabaseException(String message) : super('Database error: $message');
}