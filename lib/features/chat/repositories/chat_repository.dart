import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/models/video_reaction_model.dart';
import 'package:textgb/features/chat/models/moment_reaction_model.dart';
import 'package:textgb/shared/services/http_client.dart';
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
  Future<void> setChatWallpaper(
      String chatId, String userId, String? wallpaperUrl);
  Future<void> setChatFontSize(String chatId, String userId, double fontSize);
  Future<void> deleteChat(String chatId, String userId,
      {bool deleteForEveryone = false});
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
  Future<void> updateMessageStatus(
      String chatId, String messageId, MessageStatus status);
  Future<void> markMessageAsDelivered(
      String chatId, String messageId, String userId);
  Future<void> markMessageAsRead(
      String chatId, String messageId, String userId);
  Future<void> editMessage(String chatId, String messageId, String newContent);
  Future<void> deleteMessage(
      String chatId, String messageId, bool deleteForEveryone);
  Future<void> pinMessage(String chatId, String messageId);
  Future<void> unpinMessage(String chatId, String messageId);
  Future<List<MessageModel>> searchMessages(String chatId, String query);
  Future<List<MessageModel>> getPinnedMessages(String chatId);
  Future<void> addMessageReaction(
      String chatId, String messageId, String userId, String emoji);
  Future<void> removeMessageReaction(
      String chatId, String messageId, String userId);

  // Media operations (using R2 storage via Go backend)
  Future<String> uploadMedia(File file, String fileName, String chatId);
  Future<void> deleteMedia(String mediaUrl);

  // User presence and status
  Future<void> updateUserPresence(String userId, bool isOnline);
  Future<Map<String, bool>> getUsersPresence(List<String> userIds);
  Future<void> updateUserTypingStatus(
      String chatId, String userId, bool isTyping);
  Future<Map<String, bool>> getChatTypingStatus(String chatId);

  // Utility
  String generateChatId(String userId1, String userId2);
  Future<bool> chatHasMessages(String chatId);
  Future<List<String>> getUserChats(String userId);
  Future<int> getUnreadMessagesCount(String userId);
  Future<int> getChatUnreadCount(String chatId, String userId);

  // Advanced features
  Future<void> reportContent({
    required String reporterId,
    required String contentType,
    required String contentId,
    required String reason,
    String? description,
  });
  Future<Map<String, dynamic>> getChatAnalytics(String chatId);
  Future<String> exportChatMessages(String chatId, String format);
  Future<void> backupChatData(String userId);
  Future<void> cleanupOldData(String userId, {int daysOld = 365});
}

// ========================================
// HTTP IMPLEMENTATION
// ========================================

class HttpChatRepository implements ChatRepository {
  final HttpClientService _httpClient;
  final Uuid _uuid;

  HttpChatRepository({
    HttpClientService? httpClient,
    Uuid? uuid,
  })  : _httpClient = httpClient ?? HttpClientService(),
        _uuid = uuid ?? const Uuid();

  // Helper method to create RFC3339 timestamps
  String _createTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  @override
  String generateChatId(String userId1, String userId2) {
    // Create consistent chat ID regardless of order
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  @override
  Future<bool> chatHasMessages(String chatId) async {
    try {
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

  // ========================================
  // CHAT OPERATIONS
  // ========================================

  @override
  Future<String> createOrGetChat(
      String currentUserId, String otherUserId) async {
    try {
      debugPrint('🔄 Creating/getting chat with user: $otherUserId');
      final chatId = generateChatId(currentUserId, otherUserId);

      final response = await _httpClient.post('/chats', body: {
        'other_user_id': otherUserId, // Changed from 'participants' array
      });

      debugPrint('📡 Chat creation response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Backend returns 'id' field, not 'chatId'
        final returnedChatId = data['id'] ?? data['chatId'] ?? chatId;
        debugPrint('✅ Chat created/retrieved: $returnedChatId');
        return returnedChatId;
      } else {
        debugPrint('❌ Chat creation failed: ${response.statusCode} - ${response.body}');
        throw ChatRepositoryException(
            'Failed to create or get chat: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error creating/getting chat: $e');
      throw ChatRepositoryException('Failed to create or get chat: $e');
    }
  }

  /// Transform backend chat response to frontend ChatModel format
  Map<String, dynamic> _transformChatData(Map<String, dynamic> backendData, String currentUserId) {
    // Backend returns: {id, user1_id, user2_id, unread_count, last_message_text, last_message_at, is_active}
    // Frontend expects: {chatId, participants, unreadCounts, isPinned, isMuted, isArchived, lastMessage, lastMessageTime}

    final user1Id = backendData['user1_id'] ?? backendData['user1Id'] ?? '';
    final user2Id = backendData['user2_id'] ?? backendData['user2Id'] ?? '';
    final unreadCount = backendData['unread_count'] ?? backendData['unreadCount'] ?? 0;
    final lastMessageText = backendData['last_message_text'] ?? backendData['lastMessageText'] ?? '';

    // Parse backend timestamp properly - try multiple field names
    final lastMessageAt = backendData['last_message_at'] ??
                         backendData['lastMessageAt'] ??
                         backendData['updated_at'] ??
                         backendData['updatedAt'];

    // Build participants array
    final participants = [user1Id, user2Id];

    // Build unread counts map (only current user's unread count from backend)
    final unreadCounts = {currentUserId: unreadCount};

    // Initialize empty maps for user-specific settings (these will be managed locally)
    final isPinned = <String, bool>{};
    final isMuted = <String, bool>{};
    final isArchived = <String, bool>{};

    // Use a very old timestamp if no last message exists, so chat appears at bottom
    final defaultTimestamp = DateTime(2000, 1, 1).toIso8601String();

    return {
      'chatId': backendData['id'] ?? '',
      'participants': participants,
      'lastMessage': lastMessageText.isNotEmpty ? lastMessageText : 'No messages yet',
      'lastMessageType': 'text', // Backend doesn't return type yet
      'lastMessageSender': user1Id, // Default to user1, will be updated with actual messages
      'lastMessageTime': lastMessageAt ?? defaultTimestamp,
      'unreadCounts': unreadCounts,
      'isArchived': isArchived,
      'isPinned': isPinned,
      'isMuted': isMuted,
      'createdAt': backendData['created_at'] ?? backendData['createdAt'] ?? DateTime.now().toIso8601String(),
    };
  }

  @override
  Stream<List<ChatModel>> getChatsStream(String userId) {
    // Since we're using HTTP instead of real-time Firebase, we'll implement polling
    // In a production app, you might want to use WebSockets or Server-Sent Events
    return Stream.periodic(const Duration(seconds: 3), (count) async {
      try {
        // FIXED: Changed from '/users/$userId/chats' to '/chats'
        // Backend will get userId from authentication token
        final response = await _httpClient.get('/chats');

        debugPrint('Chat list response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          // Handle empty response body
          if (response.body.isEmpty) {
            debugPrint('Empty response body, returning empty list');
            return <ChatModel>[];
          }

          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final List<dynamic> chatsData = data['chats'] ?? [];

          debugPrint('Parsed ${chatsData.length} chats from response');

          if (chatsData.isEmpty) {
            return <ChatModel>[];
          }

          final chats = chatsData
              .map((chatData) {
                try {
                  // Transform backend data to frontend format
                  final transformedData = _transformChatData(
                    chatData as Map<String, dynamic>,
                    userId,
                  );
                  return ChatModel.fromMap(transformedData);
                } catch (e) {
                  debugPrint('Error parsing chat: $e');
                  debugPrint('Chat data: $chatData');
                  return null;
                }
              })
              .whereType<ChatModel>()
              .where((chat) => !chat.isArchivedForUser(userId))
              .toList();

          // REMOVED: chatHasMessages check - just show all chats
          // The backend should only return chats that have been used (have messages or were recently created)

          // Sort by last message time (most recent first)
          chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

          return chats;
        } else if (response.statusCode == 404) {
          debugPrint('Chat endpoint not found, returning empty list');
          return <ChatModel>[];
        } else if (response.statusCode == 401) {
          debugPrint('Unauthorized - authentication issue');
          return <ChatModel>[];
        } else {
          throw ChatRepositoryException(
              'Failed to get chats: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        debugPrint('Error in chats stream: $e');
        // Return empty list instead of throwing to prevent UI crashes
        return <ChatModel>[];
      }
    }).asyncMap((future) => future);
  }

  @override
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final response = await _httpClient.get('/chats/$chatId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ChatModel.fromMap(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw ChatRepositoryException(
            'Failed to get chat by ID: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('404')) return null;
      throw ChatRepositoryException('Failed to get chat by ID: $e');
    }
  }

  @override
  Future<void> updateChatLastMessage(ChatModel chat) async {
    try {
      final response =
          await _httpClient.put('/chats/${chat.chatId}/last-message', body: {
        'lastMessage': chat.lastMessage,
        'lastMessageType': chat.lastMessageType.name,
        'lastMessageSender': chat.lastMessageSender,
        'lastMessageTime': chat.lastMessageTime.toIso8601String(),
        'updatedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to update chat last message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to update chat last message: $e');
    }
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      final response =
          await _httpClient.post('/chats/$chatId/mark-read', body: {
        'userId': userId,
        'readAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to mark chat as read: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to mark chat as read: $e');
    }
  }

  @override
  Future<void> toggleChatPin(String chatId, String userId) async {
    try {
      final response =
          await _httpClient.post('/chats/$chatId/toggle-pin', body: {
        'userId': userId,
        'pinnedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to toggle chat pin: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to toggle chat pin: $e');
    }
  }

  @override
  Future<void> toggleChatArchive(String chatId, String userId) async {
    try {
      final response =
          await _httpClient.post('/chats/$chatId/toggle-archive', body: {
        'userId': userId,
        'archivedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to toggle chat archive: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to toggle chat archive: $e');
    }
  }

  @override
  Future<void> toggleChatMute(String chatId, String userId) async {
    try {
      final response =
          await _httpClient.post('/chats/$chatId/toggle-mute', body: {
        'userId': userId,
        'mutedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to toggle chat mute: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to toggle chat mute: $e');
    }
  }

  @override
  Future<void> deleteChat(String chatId, String userId,
      {bool deleteForEveryone = false}) async {
    try {
      final response = await _httpClient.delete(
          '/chats/$chatId?userId=$userId&deleteForEveryone=$deleteForEveryone');

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to delete chat: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to delete chat: $e');
    }
  }

  @override
  Future<void> clearChatHistory(String chatId, String userId) async {
    try {
      final response =
          await _httpClient.post('/chats/$chatId/clear-history', body: {
        'userId': userId,
        'clearedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to clear chat history: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to clear chat history: $e');
    }
  }

  @override
  Future<void> setChatWallpaper(
      String chatId, String userId, String? wallpaperUrl) async {
    try {
      final response =
          await _httpClient.post('/chats/$chatId/wallpaper', body: {
        'userId': userId,
        'wallpaperUrl': wallpaperUrl,
        'updatedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to set chat wallpaper: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to set chat wallpaper: $e');
    }
  }

  @override
  Future<void> setChatFontSize(
      String chatId, String userId, double fontSize) async {
    try {
      final response =
          await _httpClient.post('/chats/$chatId/font-size', body: {
        'userId': userId,
        'fontSize': fontSize,
        'updatedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to set chat font size: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to set chat font size: $e');
    }
  }

  // ========================================
  // MESSAGE OPERATIONS
  // ========================================

  @override
  Future<String> sendMessage(MessageModel message) async {
    try {
      final messageId =
          message.messageId.isEmpty ? _uuid.v4() : message.messageId;
      final finalMessage = message.copyWith(messageId: messageId);

      final response =
          await _httpClient.post('/chats/${message.chatId}/messages', body: {
        'messageId': messageId,
        'chatId': message.chatId,
        'senderId': message.senderId,
        'content': message.content,
        'type': message.type.name,
        'status': message.status.name,
        'timestamp': message.timestamp.toUtc().toIso8601String(),
        'mediaUrl': message.mediaUrl,
        'mediaMetadata': message.mediaMetadata,
        'replyToMessageId': message.replyToMessageId,
        'replyToContent': message.replyToContent,
        'replyToSender': message.replyToSender,
        'reactions': message.reactions,
        'isEdited': message.isEdited,
        'editedAt': message.editedAt?.toUtc().toIso8601String(),
        'isPinned': message.isPinned,
        'readBy':
            message.readBy?.map((k, v) => MapEntry(k, v.toUtc().toIso8601String())),
        'deliveredTo': message.deliveredTo
            ?.map((k, v) => MapEntry(k, v.toUtc().toIso8601String())),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Update chat last message
        await _updateChatWithNewMessage(message.chatId, finalMessage);

        return data['messageId'] ?? messageId;
      } else {
        throw ChatRepositoryException(
            'Failed to send message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to send message: $e');
    }
  }

  // Helper method to update chat with new message info
  Future<void> _updateChatWithNewMessage(
      String chatId, MessageModel message) async {
    try {
      await _httpClient.put('/chats/$chatId/last-message', body: {
        'lastMessage': message.getDisplayContent(),
        'lastMessageType': message.type.name,
        'lastMessageSender': message.senderId,
        'lastMessageTime': message.timestamp.toIso8601String(),
        'updatedAt': _createTimestamp(),
      });

      // Also increment unread count for other participants
      final chat = await getChatById(chatId);
      if (chat != null) {
        for (final participantId in chat.participants) {
          if (participantId != message.senderId) {
            await _incrementUnreadCount(chatId, participantId);
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating chat last message: $e');
      // Don't throw - message sending should still succeed
    }
  }

  // Helper method to increment unread count
  Future<void> _incrementUnreadCount(String chatId, String userId) async {
    try {
      await _httpClient.post('/chats/$chatId/increment-unread', body: {
        'userId': userId,
      });
    } catch (e) {
      debugPrint('Error incrementing unread count: $e');
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
    try {
      final messageId = _uuid.v4();

      final message = MessageModel(
        messageId: messageId,
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

      await sendMessage(message);
      return messageId;
    } catch (e) {
      throw ChatRepositoryException('Failed to send video message: $e');
    }
  }

  @override
  Future<String> sendVideoReactionMessage({
    required String chatId,
    required String senderId,
    required VideoReactionModel videoReaction,
  }) async {
    try {
      final messageId = _uuid.v4();

      final message = MessageModel(
        messageId: messageId,
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
          'userName': videoReaction.userName, // Changed from channelName
          'userImage': videoReaction.userImage, // Changed from channelImage
        },
      );

      await sendMessage(message);
      return messageId;
    } catch (e) {
      throw ChatRepositoryException(
          'Failed to send video reaction message: $e');
    }
  }

  @override
  Future<String> sendMomentReactionMessage({
    required String chatId,
    required String senderId,
    required MomentReactionModel momentReaction,
  }) async {
    try {
      final messageId = _uuid.v4();

      final message = MessageModel(
        messageId: messageId,
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

      await sendMessage(message);
      return messageId;
    } catch (e) {
      throw ChatRepositoryException(
          'Failed to send moment reaction message: $e');
    }
  }

  /// Transform backend message response to frontend MessageModel format
  Map<String, dynamic> _transformMessageData(Map<String, dynamic> backendData) {
    // Backend returns: {message_id, chat_id, sender_id, message_text, media_url, media_type, created_at, is_delivered, delivered_at, is_read, read_at}
    // Frontend expects: {messageId, chatId, senderId, content, type, mediaUrl, timestamp, status}

    final messageText = backendData['message_text'] ?? backendData['messageText'] ?? '';
    final mediaType = backendData['media_type'] ?? backendData['mediaType'];
    final mediaUrl = backendData['media_url'] ?? backendData['mediaUrl'];
    final createdAt = backendData['created_at'] ?? backendData['createdAt'] ?? DateTime.now().toIso8601String();
    final isRead = backendData['is_read'] ?? backendData['isRead'] ?? false;
    final isDelivered = backendData['is_delivered'] ?? backendData['isDelivered'] ?? false;

    // Determine message status
    String status = 'sending';
    if (isRead) {
      status = 'read';
    } else if (isDelivered) {
      status = 'delivered';
    } else {
      status = 'sent';
    }

    // Determine message type from media_type or default to text
    String type = 'text';
    if (mediaType != null && mediaType.isNotEmpty) {
      type = mediaType; // 'image', 'video', 'audio', etc.
    }

    return {
      'messageId': backendData['message_id'] ?? backendData['messageId'] ?? '',
      'chatId': backendData['chat_id'] ?? backendData['chatId'] ?? '',
      'senderId': backendData['sender_id'] ?? backendData['senderId'] ?? '',
      'content': messageText,
      'type': type,
      'status': status,
      'timestamp': createdAt,
      'mediaUrl': mediaUrl,
      'mediaMetadata': backendData['media_metadata'] ?? backendData['mediaMetadata'],
      'isEdited': false,
      'isPinned': false,
    };
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    // Implement polling for messages since we're not using real-time Firebase
    return Stream.periodic(const Duration(seconds: 2), (count) async {
      try {
        final response = await _httpClient
            .get('/chats/$chatId/messages?limit=100&sort=desc');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final List<dynamic> messagesData = data['messages'] ?? [];

          return messagesData
              .map((messageData) => _transformMessageData(messageData as Map<String, dynamic>))
              .map((transformedData) => MessageModel.fromMap(transformedData))
              .toList();
        } else {
          throw ChatRepositoryException(
              'Failed to get messages: ${response.body}');
        }
      } catch (e) {
        debugPrint('Error in messages stream: $e');
        throw ChatRepositoryException('Failed to get messages stream: $e');
      }
    }).asyncMap((future) => future);
  }

  @override
  Future<void> updateMessageStatus(
      String chatId, String messageId, MessageStatus status) async {
    try {
      final response = await _httpClient
          .put('/chats/$chatId/messages/$messageId/status', body: {
        'status': status.name,
        'updatedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to update message status: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to update message status: $e');
    }
  }

  @override
  Future<void> markMessageAsDelivered(
      String chatId, String messageId, String userId) async {
    try {
      final response = await _httpClient
          .post('/chats/$chatId/messages/$messageId/delivered', body: {
        'userId': userId,
        'deliveredAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to mark message as delivered: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to mark message as delivered: $e');
    }
  }

  @override
  Future<void> markMessageAsRead(
      String chatId, String messageId, String userId) async {
    try {
      final response = await _httpClient
          .post('/chats/$chatId/messages/$messageId/read', body: {
        'userId': userId,
        'readAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to mark message as read: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to mark message as read: $e');
    }
  }

  @override
  Future<void> editMessage(
      String chatId, String messageId, String newContent) async {
    try {
      final response =
          await _httpClient.put('/chats/$chatId/messages/$messageId', body: {
        'content': newContent,
        'isEdited': true,
        'editedAt': _createTimestamp(),
        'updatedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to edit message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to edit message: $e');
    }
  }

  @override
  Future<void> deleteMessage(
      String chatId, String messageId, bool deleteForEveryone) async {
    try {
      final response = await _httpClient.delete(
          '/chats/$chatId/messages/$messageId?deleteForEveryone=$deleteForEveryone');

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to delete message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to delete message: $e');
    }
  }

  @override
  Future<void> pinMessage(String chatId, String messageId) async {
    try {
      final response = await _httpClient
          .post('/chats/$chatId/messages/$messageId/pin', body: {
        'pinnedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to pin message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to pin message: $e');
    }
  }

  @override
  Future<void> unpinMessage(String chatId, String messageId) async {
    try {
      final response =
          await _httpClient.delete('/chats/$chatId/messages/$messageId/pin');

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to unpin message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to unpin message: $e');
    }
  }

  @override
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    try {
      final response = await _httpClient.get(
          '/chats/$chatId/messages/search?q=${Uri.encodeComponent(query)}&limit=100');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];

        return messagesData
            .map((messageData) =>
                MessageModel.fromMap(messageData as Map<String, dynamic>))
            .toList();
      } else {
        throw ChatRepositoryException(
            'Failed to search messages: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to search messages: $e');
    }
  }

  @override
  Future<List<MessageModel>> getPinnedMessages(String chatId) async {
    try {
      final response = await _httpClient.get('/chats/$chatId/messages/pinned');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];

        return messagesData
            .map((messageData) =>
                MessageModel.fromMap(messageData as Map<String, dynamic>))
            .toList();
      } else {
        throw ChatRepositoryException(
            'Failed to get pinned messages: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get pinned messages: $e');
    }
  }

  @override
  Future<void> addMessageReaction(
      String chatId, String messageId, String userId, String emoji) async {
    try {
      final response = await _httpClient
          .post('/chats/$chatId/messages/$messageId/reactions', body: {
        'userId': userId,
        'emoji': emoji,
        'reactedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to add message reaction: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to add message reaction: $e');
    }
  }

  @override
  Future<void> removeMessageReaction(
      String chatId, String messageId, String userId) async {
    try {
      final response = await _httpClient
          .delete('/chats/$chatId/messages/$messageId/reactions/$userId');

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to remove message reaction: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to remove message reaction: $e');
    }
  }

  // ========================================
  // MEDIA OPERATIONS (R2 via Go backend)
  // ========================================

  @override
  Future<String> uploadMedia(File file, String fileName, String chatId) async {
    try {
      // Check file size
      final fileSize = await file.length();
      if (fileSize > 100 * 1024 * 1024) {
        // 100MB limit
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
        return data['url'] as String;
      } else {
        throw ChatRepositoryException(
            'Failed to upload media: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to upload media: $e');
    }
  }

  @override
  Future<void> deleteMedia(String mediaUrl) async {
    try {
      final response = await _httpClient
          .delete('/media?url=${Uri.encodeComponent(mediaUrl)}');

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to delete media: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to delete media: $e');
    }
  }

  // ========================================
  // USER PRESENCE AND STATUS
  // ========================================

  @override
  Future<void> updateUserPresence(String userId, bool isOnline) async {
    try {
      final response = await _httpClient.post('/users/$userId/presence', body: {
        'isOnline': isOnline,
        'lastSeen': _createTimestamp(),
        'updatedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to update user presence: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to update user presence: $e');
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

        // Convert to Map<String, bool>
        final result = <String, bool>{};
        presenceData.forEach((userId, isOnline) {
          result[userId] = isOnline as bool? ?? false;
        });

        return result;
      } else {
        throw ChatRepositoryException(
            'Failed to get users presence: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get users presence: $e');
    }
  }

  @override
  Future<void> updateUserTypingStatus(
      String chatId, String userId, bool isTyping) async {
    try {
      final response = await _httpClient.post('/chats/$chatId/typing', body: {
        'userId': userId,
        'isTyping': isTyping,
        'timestamp': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to update typing status: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to update typing status: $e');
    }
  }

  @override
  Future<Map<String, bool>> getChatTypingStatus(String chatId) async {
    try {
      final response = await _httpClient.get('/chats/$chatId/typing');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final typingData = data['typing'] as Map<String, dynamic>? ?? {};

        // Convert to Map<String, bool>
        final result = <String, bool>{};
        typingData.forEach((userId, isTyping) {
          result[userId] = isTyping as bool? ?? false;
        });

        return result;
      } else {
        throw ChatRepositoryException(
            'Failed to get chat typing status: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get chat typing status: $e');
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  @override
  Future<List<String>> getUserChats(String userId) async {
    try {
      // FIXED: Changed from '/users/$userId/chats/ids' to '/chats/ids'
      // Backend will get userId from authentication token
      final response = await _httpClient.get('/chats/ids');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> chatIds = data['chatIds'] ?? [];
        return chatIds.cast<String>();
      } else {
        throw ChatRepositoryException(
            'Failed to get user chats: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get user chats: $e');
    }
  }

  @override
  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      // FIXED: Changed from '/users/$userId/unread-count' to '/chats/unread-count'
      // Backend will get userId from authentication token
      final response = await _httpClient.get('/chats/unread-count');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['unreadCount'] ?? 0;
      } else {
        throw ChatRepositoryException(
            'Failed to get unread messages count: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get unread messages count: $e');
    }
  }

  @override
  Future<int> getChatUnreadCount(String chatId, String userId) async {
    try {
      final response =
          await _httpClient.get('/chats/$chatId/unread-count?userId=$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['unreadCount'] ?? 0;
      } else {
        throw ChatRepositoryException(
            'Failed to get chat unread count: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get chat unread count: $e');
    }
  }

  // ========================================
  // ADVANCED FEATURES
  // ========================================

  @override
  Future<void> reportContent({
    required String reporterId,
    required String contentType,
    required String contentId,
    required String reason,
    String? description,
  }) async {
    try {
      final response = await _httpClient.post('/reports', body: {
        'reporterId': reporterId,
        'contentType': contentType,
        'contentId': contentId,
        'reason': reason,
        'description': description,
        'reportedAt': _createTimestamp(),
        'status': 'pending',
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ChatRepositoryException(
            'Failed to report content: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to report content: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getChatAnalytics(String chatId) async {
    try {
      final response = await _httpClient.get('/chats/$chatId/analytics');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['analytics'] ?? {};
      } else {
        throw ChatRepositoryException(
            'Failed to get chat analytics: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get chat analytics: $e');
    }
  }

  @override
  Future<String> exportChatMessages(String chatId, String format) async {
    try {
      final response =
          await _httpClient.get('/chats/$chatId/export?format=$format');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['exportUrl'] ?? '';
      } else {
        throw ChatRepositoryException(
            'Failed to export chat messages: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to export chat messages: $e');
    }
  }

  @override
  Future<void> backupChatData(String userId) async {
    try {
      // FIXED: Changed from '/users/$userId/backup-chats' to '/chats/backup'
      // Backend will get userId from authentication token
      final response = await _httpClient.post('/chats/backup', body: {
        'backupAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to backup chat data: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to backup chat data: $e');
    }
  }

  @override
  Future<void> cleanupOldData(String userId, {int daysOld = 365}) async {
    try {
      // FIXED: Changed from '/users/$userId/cleanup' to '/chats/cleanup'
      // Backend will get userId from authentication token
      final response = await _httpClient.post('/chats/cleanup', body: {
        'daysOld': daysOld,
        'cleanupAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to cleanup old data: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to cleanup old data: $e');
    }
  }

  // ========================================
  // ADDITIONAL HELPER METHODS
  // ========================================

  // Get chat participants info
  Future<List<Map<String, dynamic>>> getChatParticipants(String chatId) async {
    try {
      final response = await _httpClient.get('/chats/$chatId/participants');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> participants = data['participants'] ?? [];
        return participants.cast<Map<String, dynamic>>();
      } else {
        throw ChatRepositoryException(
            'Failed to get chat participants: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get chat participants: $e');
    }
  }

  // Block/Unblock user in chat
  Future<void> toggleUserBlock(
      String userId, String targetUserId, bool block) async {
    try {
      final response = await _httpClient
          .post('/users/$userId/${block ? 'block' : 'unblock'}', body: {
        'targetUserId': targetUserId,
        'blockedAt': block ? _createTimestamp() : null,
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to ${block ? 'block' : 'unblock'} user: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException(
          'Failed to ${block ? 'block' : 'unblock'} user: $e');
    }
  }

  // Get blocked users list
  Future<List<String>> getBlockedUsers(String userId) async {
    try {
      final response = await _httpClient.get('/users/$userId/blocked');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> blockedUsers = data['blockedUsers'] ?? [];
        return blockedUsers.cast<String>();
      } else {
        throw ChatRepositoryException(
            'Failed to get blocked users: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get blocked users: $e');
    }
  }

  // Check if user is blocked
  Future<bool> isUserBlocked(String userId, String targetUserId) async {
    try {
      final response =
          await _httpClient.get('/users/$userId/blocked/$targetUserId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['isBlocked'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Get chat settings
  Future<Map<String, dynamic>> getChatSettings(
      String chatId, String userId) async {
    try {
      final response =
          await _httpClient.get('/chats/$chatId/settings?userId=$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['settings'] ?? {};
      } else {
        throw ChatRepositoryException(
            'Failed to get chat settings: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get chat settings: $e');
    }
  }

  // Update chat settings
  Future<void> updateChatSettings(
      String chatId, String userId, Map<String, dynamic> settings) async {
    try {
      final response = await _httpClient.put('/chats/$chatId/settings', body: {
        'userId': userId,
        'settings': settings,
        'updatedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to update chat settings: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to update chat settings: $e');
    }
  }

  // Get message delivery report
  Future<Map<String, dynamic>> getMessageDeliveryReport(
      String chatId, String messageId) async {
    try {
      final response = await _httpClient
          .get('/chats/$chatId/messages/$messageId/delivery-report');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['deliveryReport'] ?? {};
      } else {
        throw ChatRepositoryException(
            'Failed to get message delivery report: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException(
          'Failed to get message delivery report: $e');
    }
  }

  // Get chat media files
  Future<List<Map<String, dynamic>>> getChatMediaFiles(String chatId,
      {String? mediaType}) async {
    try {
      final queryParam = mediaType != null ? '?type=$mediaType' : '';
      final response = await _httpClient.get('/chats/$chatId/media$queryParam');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> mediaFiles = data['mediaFiles'] ?? [];
        return mediaFiles.cast<Map<String, dynamic>>();
      } else {
        throw ChatRepositoryException(
            'Failed to get chat media files: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get chat media files: $e');
    }
  }

  // Get chat links
  Future<List<Map<String, dynamic>>> getChatLinks(String chatId) async {
    try {
      final response = await _httpClient.get('/chats/$chatId/links');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> links = data['links'] ?? [];
        return links.cast<Map<String, dynamic>>();
      } else {
        throw ChatRepositoryException(
            'Failed to get chat links: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get chat links: $e');
    }
  }

  // Schedule message (future feature)
  Future<String> scheduleMessage(
      MessageModel message, DateTime scheduledTime) async {
    try {
      final response = await _httpClient
          .post('/chats/${message.chatId}/scheduled-messages', body: {
        'messageId': message.messageId.isEmpty ? _uuid.v4() : message.messageId,
        'chatId': message.chatId,
        'senderId': message.senderId,
        'content': message.content,
        'type': message.type.name,
        'mediaUrl': message.mediaUrl,
        'mediaMetadata': message.mediaMetadata,
        'scheduledTime': scheduledTime.toIso8601String(),
        'createdAt': _createTimestamp(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['scheduledMessageId'] ?? message.messageId;
      } else {
        throw ChatRepositoryException(
            'Failed to schedule message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to schedule message: $e');
    }
  }

  // Cancel scheduled message
  Future<void> cancelScheduledMessage(String scheduledMessageId) async {
    try {
      final response =
          await _httpClient.delete('/scheduled-messages/$scheduledMessageId');

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to cancel scheduled message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to cancel scheduled message: $e');
    }
  }

  // Get scheduled messages for a chat
  Future<List<Map<String, dynamic>>> getScheduledMessages(String chatId) async {
    try {
      final response =
          await _httpClient.get('/chats/$chatId/scheduled-messages');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> scheduledMessages = data['scheduledMessages'] ?? [];
        return scheduledMessages.cast<Map<String, dynamic>>();
      } else {
        throw ChatRepositoryException(
            'Failed to get scheduled messages: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get scheduled messages: $e');
    }
  }

  // Test connection to chat service
  Future<bool> testConnection() async {
    try {
      final response = await _httpClient.get('/chats/health');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Chat service connection test failed: $e');
      return false;
    }
  }

  // Get chat service status
  Future<Map<String, dynamic>> getServiceStatus() async {
    try {
      final response = await _httpClient.get('/chats/status');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw ChatRepositoryException(
            'Failed to get service status: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get service status: $e');
    }
  }

  // Migrate chat data (for future use)
  Future<void> migrateChatData(
      String userId, Map<String, dynamic> migrationConfig) async {
    try {
      // FIXED: Changed from '/users/$userId/migrate' to '/chats/migrate'
      // Backend will get userId from authentication token
      final response = await _httpClient.post('/chats/migrate', body: {
        'config': migrationConfig,
        'migratedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to migrate chat data: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to migrate chat data: $e');
    }
  }

  // Bulk delete messages
  Future<void> bulkDeleteMessages(
      String chatId, List<String> messageIds, bool deleteForEveryone) async {
    try {
      final response =
          await _httpClient.post('/chats/$chatId/messages/bulk-delete', body: {
        'messageIds': messageIds,
        'deleteForEveryone': deleteForEveryone,
        'deletedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to bulk delete messages: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to bulk delete messages: $e');
    }
  }

  // Get user chat statistics
  Future<Map<String, dynamic>> getUserChatStatistics(String userId) async {
    try {
      // FIXED: Changed from '/users/$userId/chat-statistics' to '/chats/statistics'
      // Backend will get userId from authentication token
      final response = await _httpClient.get('/chats/statistics');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['statistics'] ?? {};
      } else {
        throw ChatRepositoryException(
            'Failed to get user chat statistics: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get user chat statistics: $e');
    }
  }

  // Set auto-delete timer for chat
  Future<void> setAutoDeleteTimer(
      String chatId, String userId, Duration? timer) async {
    try {
      final response =
          await _httpClient.post('/chats/$chatId/auto-delete', body: {
        'userId': userId,
        'timerSeconds': timer?.inSeconds,
        'updatedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException(
            'Failed to set auto-delete timer: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to set auto-delete timer: $e');
    }
  }
}

// ========================================
// REPOSITORY PROVIDER
// ========================================

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return HttpChatRepository();
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

// Additional exception classes for specific scenarios
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