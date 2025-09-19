// lib/features/chat/repositories/chat_repository.dart
// FIXED: Simplified offline-first architecture with proper timestamp handling
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
// SIMPLIFIED OFFLINE-FIRST IMPLEMENTATION
// ========================================

class OfflineFirstChatRepository implements ChatRepository {
  final HttpClientService _httpClient;
  final ChatDatabaseHelper _dbHelper;
  final Uuid _uuid;
  
  // Simplified stream controllers - one per type
  final Map<String, StreamController<List<ChatModel>>> _chatStreamControllers = {};
  final Map<String, StreamController<List<MessageModel>>> _messageStreamControllers = {};
  
  // Background sync timer
  Timer? _syncTimer;

  OfflineFirstChatRepository({
    HttpClientService? httpClient,
    ChatDatabaseHelper? dbHelper,
    Uuid? uuid,
  })  : _httpClient = httpClient ?? HttpClientService(),
        _dbHelper = dbHelper ?? ChatDatabaseHelper(),
        _uuid = uuid ?? const Uuid() {
    _startBackgroundSync();
  }

  @override
  String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // ========================================
  // BACKGROUND SYNC (Simplified)
  // ========================================

  void _startBackgroundSync() {
    // Sync every 30 seconds in background
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _backgroundSync();
    });
  }

  Future<void> _backgroundSync() async {
    try {
      // Sync unsynced messages
      final unsynced = await _dbHelper.getUnsyncedMessages();
      for (final message in unsynced.take(10)) { // Limit to 10 per sync
        await _sendMessageToServer(message).catchError((e) {
          debugPrint('Background sync failed for message ${message.messageId}: $e');
        });
      }
    } catch (e) {
      debugPrint('Background sync error: $e');
    }
  }

  // ========================================
  // CHAT OPERATIONS (Offline-First)
  // ========================================

  @override
  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    final chatId = generateChatId(currentUserId, otherUserId);
    
    try {
      // Check local database first - ATOMIC CHECK
      var chat = await _dbHelper.getChatById(chatId);
      
      if (chat != null) {
        return chatId; // Chat already exists
      }
      
      // Create new chat locally (with duplicate prevention)
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
      
      // Insert with IGNORE conflict strategy (prevents duplicates)
      await _dbHelper.insertOrUpdateChat(newChat);
      
      // Try to create on server (don't wait)
      _createChatOnServer(newChat).catchError((e) {
        debugPrint('Failed to create chat on server: $e');
      });
      
      return chatId;
    } catch (e) {
      debugPrint('Error creating/getting chat: $e');
      throw ChatRepositoryException('Failed to create or get chat: $e');
    }
  }

  Future<void> _createChatOnServer(ChatModel chat) async {
    try {
      final response = await _httpClient.post('/chats', body: {
        'chatId': chat.chatId,
        'participants': chat.participants,
        'createdAt': DateTimeHelper.toIso8601(chat.createdAt),
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
    // Return existing stream or create new one
    if (_chatStreamControllers.containsKey(userId)) {
      return _chatStreamControllers[userId]!.stream;
    }
    
    // Create new broadcast stream controller
    final controller = StreamController<List<ChatModel>>.broadcast(
      onListen: () => _startChatStream(userId),
      onCancel: () => _stopChatStream(userId),
    );
    
    _chatStreamControllers[userId] = controller;
    return controller.stream;
  }

  void _startChatStream(String userId) {
    // Simple polling every 1 second for local changes
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
    final controller = _chatStreamControllers.remove(userId);
    controller?.close();
  }

  @override
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      return await _dbHelper.getChatById(chatId);
    } catch (e) {
      debugPrint('Error getting chat by ID: $e');
      return null;
    }
  }

  @override
  Future<void> updateChatLastMessage(ChatModel chat) async {
    try {
      await _dbHelper.updateChatLastMessage(
        chatId: chat.chatId,
        lastMessage: chat.lastMessage,
        lastMessageType: chat.lastMessageType,
        lastMessageSender: chat.lastMessageSender,
        lastMessageTime: chat.lastMessageTime,
      );
    } catch (e) {
      debugPrint('Error updating chat last message: $e');
      rethrow;
    }
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      // Mark in local database
      await _dbHelper.markAllMessagesAsRead(chatId, userId);
      
      // Sync with server (don't wait)
      _httpClient.post('/chats/$chatId/mark-read', body: {
        'userId': userId,
        'readAt': DateTimeHelper.toIso8601(DateTime.now()),
      }).catchError((e) {
        debugPrint('Failed to mark chat as read on server: $e');
      });
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
      rethrow;
    }
  }

  @override
  Future<void> toggleChatPin(String chatId, String userId) async {
    try {
      await _dbHelper.toggleChatPin(chatId, userId);
      
      // Sync with server
      await _httpClient.post('/chats/$chatId/toggle-pin', body: {
        'userId': userId,
        'pinnedAt': DateTimeHelper.toIso8601(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error toggling chat pin: $e');
      // Revert on error
      await _dbHelper.toggleChatPin(chatId, userId);
      rethrow;
    }
  }

  @override
  Future<void> toggleChatArchive(String chatId, String userId) async {
    try {
      await _dbHelper.toggleChatArchive(chatId, userId);
      
      await _httpClient.post('/chats/$chatId/toggle-archive', body: {
        'userId': userId,
        'archivedAt': DateTimeHelper.toIso8601(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error toggling chat archive: $e');
      await _dbHelper.toggleChatArchive(chatId, userId);
      rethrow;
    }
  }

  @override
  Future<void> toggleChatMute(String chatId, String userId) async {
    try {
      await _dbHelper.toggleChatMute(chatId, userId);
      
      await _httpClient.post('/chats/$chatId/toggle-mute', body: {
        'userId': userId,
        'mutedAt': DateTimeHelper.toIso8601(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error toggling chat mute: $e');
      await _dbHelper.toggleChatMute(chatId, userId);
      rethrow;
    }
  }

  @override
  Future<void> setChatWallpaper(String chatId, String userId, String? wallpaperUrl) async {
    try {
      await _httpClient.post('/chats/$chatId/wallpaper', body: {
        'userId': userId,
        'wallpaperUrl': wallpaperUrl,
        'updatedAt': DateTimeHelper.toIso8601(DateTime.now()),
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to set chat wallpaper: $e');
    }
  }

  @override
  Future<void> setChatFontSize(String chatId, String userId, double fontSize) async {
    try {
      await _httpClient.post('/chats/$chatId/font-size', body: {
        'userId': userId,
        'fontSize': fontSize,
        'updatedAt': DateTimeHelper.toIso8601(DateTime.now()),
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to set chat font size: $e');
    }
  }

  @override
  Future<void> deleteChat(String chatId, String userId, {bool deleteForEveryone = false}) async {
    try {
      await _dbHelper.deleteChat(chatId, userId);
      
      await _httpClient.delete('/chats/$chatId?userId=$userId&deleteForEveryone=$deleteForEveryone');
    } catch (e) {
      throw ChatRepositoryException('Failed to delete chat: $e');
    }
  }

  @override
  Future<void> clearChatHistory(String chatId, String userId) async {
    try {
      await _dbHelper.clearChatHistory(chatId);
      
      await _httpClient.post('/chats/$chatId/clear-history', body: {
        'userId': userId,
        'clearedAt': DateTimeHelper.toIso8601(DateTime.now()),
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to clear chat history: $e');
    }
  }

  // ========================================
  // MESSAGE OPERATIONS (Offline-First)
  // ========================================

  @override
  Future<String> sendMessage(MessageModel message) async {
    try {
      final messageId = message.messageId.isEmpty ? _uuid.v4() : message.messageId;
      final localMessage = message.copyWith(
        messageId: messageId,
        status: MessageStatus.sending,
        timestamp: DateTime.now(), // Use device time
      );
      
      // 1. Save to local database FIRST (instant feedback)
      await _dbHelper.insertOrUpdateMessage(localMessage);
      
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
        'readBy': message.readBy?.map((k, v) => MapEntry(k, DateTimeHelper.toIso8601(v))),
        'deliveredTo': message.deliveredTo?.map((k, v) => MapEntry(k, DateTimeHelper.toIso8601(v))),
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
    // Poll every 500ms for local changes (messages need faster updates)
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
  }

  void _stopMessageStream(String chatId) {
    final controller = _messageStreamControllers.remove(chatId);
    controller?.close();
  }

  @override
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    try {
      await _dbHelper.updateMessageStatus(messageId, status);
      
      _httpClient.put('/chats/$chatId/messages/$messageId/status', body: {
        'status': status.name,
        'updatedAt': DateTimeHelper.toIso8601(DateTime.now()),
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
      await _httpClient.post('/chats/$chatId/messages/$messageId/delivered', body: {
        'userId': userId,
        'deliveredAt': DateTimeHelper.toIso8601(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error marking message as delivered: $e');
    }
  }

  @override
  Future<void> markMessageAsRead(String chatId, String messageId, String userId) async {
    try {
      await _httpClient.post('/chats/$chatId/messages/$messageId/read', body: {
        'userId': userId,
        'readAt': DateTimeHelper.toIso8601(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  @override
  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    try {
      await _dbHelper.editMessage(messageId, newContent);
      
      await _httpClient.put('/chats/$chatId/messages/$messageId', body: {
        'content': newContent,
        'isEdited': true,
        'editedAt': DateTimeHelper.toIso8601(DateTime.now()),
        'updatedAt': DateTimeHelper.toIso8601(DateTime.now()),
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to edit message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    try {
      await _dbHelper.deleteMessage(messageId);
      
      await _httpClient.delete('/chats/$chatId/messages/$messageId?deleteForEveryone=$deleteForEveryone');
    } catch (e) {
      throw ChatRepositoryException('Failed to delete message: $e');
    }
  }

  @override
  Future<void> pinMessage(String chatId, String messageId) async {
    try {
      await _dbHelper.togglePinMessage(messageId);
      
      await _httpClient.post('/chats/$chatId/messages/$messageId/pin', body: {
        'pinnedAt': DateTimeHelper.toIso8601(DateTime.now()),
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to pin message: $e');
    }
  }

  @override
  Future<void> unpinMessage(String chatId, String messageId) async {
    try {
      await _dbHelper.togglePinMessage(messageId);
      
      await _httpClient.delete('/chats/$chatId/messages/$messageId/pin');
    } catch (e) {
      throw ChatRepositoryException('Failed to unpin message: $e');
    }
  }

  @override
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    try {
      return await _dbHelper.searchMessages(chatId, query);
    } catch (e) {
      throw ChatRepositoryException('Failed to search messages: $e');
    }
  }

  @override
  Future<List<MessageModel>> getPinnedMessages(String chatId) async {
    try {
      return await _dbHelper.getPinnedMessages(chatId);
    } catch (e) {
      throw ChatRepositoryException('Failed to get pinned messages: $e');
    }
  }

  @override
  Future<void> addMessageReaction(String chatId, String messageId, String userId, String emoji) async {
    try {
      await _httpClient.post('/chats/$chatId/messages/$messageId/reactions', body: {
        'userId': userId,
        'emoji': emoji,
        'reactedAt': DateTimeHelper.toIso8601(DateTime.now()),
      });
    } catch (e) {
      throw ChatRepositoryException('Failed to add message reaction: $e');
    }
  }

  @override
  Future<void> removeMessageReaction(String chatId, String messageId, String userId) async {
    try {
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
          'uploadedAt': DateTimeHelper.toIso8601(DateTime.now()),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['url'] as String;
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

  // ========================================
  // USER PRESENCE & STATUS
  // ========================================

  @override
  Future<void> updateUserPresence(String userId, bool isOnline) async {
    try {
      await _dbHelper.updateParticipantOnlineStatus(userId, isOnline);
      
      await _httpClient.post('/users/$userId/presence', body: {
        'isOnline': isOnline,
        'lastSeen': DateTimeHelper.toIso8601(DateTime.now()),
        'updatedAt': DateTimeHelper.toIso8601(DateTime.now()),
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
      await _dbHelper.updateTypingStatus(
        chatId: chatId,
        userId: userId,
        isTyping: isTyping,
      );
      
      await _httpClient.post('/chats/$chatId/typing', body: {
        'userId': userId,
        'isTyping': isTyping,
        'timestamp': DateTimeHelper.toIso8601(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  @override
  Future<Map<String, bool>> getChatTypingStatus(String chatId) async {
    try {
      final typingUsers = await _dbHelper.getTypingUsers(chatId);
      final result = <String, bool>{};
      for (final userId in typingUsers) {
        result[userId] = true;
      }
      
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
      final messages = await _dbHelper.getChatMessages(chatId, limit: 1);
      return messages.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking chat messages: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getUserChats(String userId) async {
    try {
      final chats = await _dbHelper.getUserChats(userId);
      return chats.map((chat) => chat.chatId).toList();
    } catch (e) {
      throw ChatRepositoryException('Failed to get user chats: $e');
    }
  }

  @override
  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      return await _dbHelper.getTotalUnreadMessagesCount(userId);
    } catch (e) {
      debugPrint('Error getting unread messages count: $e');
      return 0;
    }
  }

  @override
  Future<int> getChatUnreadCount(String chatId, String userId) async {
    try {
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
      final response = await _httpClient.get('/chats?userId=$userId');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> chatsData = data['chats'] ?? [];

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
  Future<void> syncMessages(String chatId) async {
    try {
      final response = await _httpClient.get('/chats/$chatId/messages?limit=100&sort=desc');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];

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
  Future<void> syncAllData(String userId) async {
    try {
      await syncChats(userId);
      
      final chats = await _dbHelper.getUserChats(userId);
      
      for (final chat in chats) {
        await syncMessages(chat.chatId);
      }
      
      debugPrint('All data synced successfully');
    } catch (e) {
      debugPrint('Error syncing all data: $e');
      rethrow;
    }
  }

  // ========================================
  // CLEANUP & DISPOSAL
  // ========================================

  void dispose() {
    _syncTimer?.cancel();
    
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

  Future<void> clearLocalCache() async {
    try {
      await _dbHelper.clearAllData();
      debugPrint('Local cache cleared');
    } catch (e) {
      debugPrint('Error clearing local cache: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getLocalStatistics() async {
    try {
      return await _dbHelper.getDatabaseStatistics();
    } catch (e) {
      debugPrint('Error getting local statistics: $e');
      return {};
    }
  }

  Future<int> cleanupOldMessages({int daysOld = 365}) async {
    try {
      return await _dbHelper.deleteOldMessages(daysOld: daysOld);
    } catch (e) {
      debugPrint('Error cleaning up old messages: $e');
      return 0;
    }
  }

  Future<void> optimizeDatabase() async {
    try {
      await _dbHelper.vacuumDatabase();
      debugPrint('Database optimized');
    } catch (e) {
      debugPrint('Error optimizing database: $e');
      rethrow;
    }
  }

  Future<int> getDatabaseSize() async {
    try {
      return await _dbHelper.getDatabaseSize();
    } catch (e) {
      debugPrint('Error getting database size: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> exportChatData() async {
    try {
      return await _dbHelper.exportToJson();
    } catch (e) {
      debugPrint('Error exporting chat data: $e');
      return {};
    }
  }

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