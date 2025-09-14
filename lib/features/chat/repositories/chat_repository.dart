// lib/features/chat/repositories/chat_repository.dart
// Updated chat repository using HTTP client and R2 storage (no Firebase)
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
  Future<void> editMessage(String chatId, String messageId, String newContent);
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone);
  Future<void> pinMessage(String chatId, String messageId);
  Future<void> unpinMessage(String chatId, String messageId);
  Future<List<MessageModel>> searchMessages(String chatId, String query);
  Future<List<MessageModel>> getPinnedMessages(String chatId);

  // Media operations
  Future<String> uploadMedia(File file, String fileName, String chatId);
  Future<void> deleteMedia(String mediaUrl);

  // Utility
  String generateChatId(String userId1, String userId2);
  Future<bool> chatHasMessages(String chatId);
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
  }) : _httpClient = httpClient ?? HttpClientService(),
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
      throw ChatRepositoryException('Failed to check chat messages: $e');
    }
  }

  // ========================================
  // CHAT OPERATIONS
  // ========================================

  @override
  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    try {
      final chatId = generateChatId(currentUserId, otherUserId);
      
      final response = await _httpClient.post('/chats', body: {
        'chatId': chatId,
        'participants': [currentUserId, otherUserId],
        'createdAt': _createTimestamp(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['chatId'] ?? chatId;
      } else {
        throw ChatRepositoryException('Failed to create or get chat: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating/getting chat: $e');
      throw ChatRepositoryException('Failed to create or get chat: $e');
    }
  }

  @override
  Stream<List<ChatModel>> getChatsStream(String userId) {
    // Since we're using HTTP instead of real-time Firebase, we'll implement polling
    // In a production app, you might want to use WebSockets or Server-Sent Events
    return Stream.periodic(const Duration(seconds: 5), (count) async {
      try {
        final response = await _httpClient.get('/chats?userId=$userId');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final List<dynamic> chatsData = data['chats'] ?? [];
          
          final chats = chatsData
              .map((chatData) => ChatModel.fromMap(chatData as Map<String, dynamic>))
              .where((chat) => !chat.isArchivedForUser(userId))
              .toList();
          
          // Filter chats that have messages
          final chatsWithMessages = <ChatModel>[];
          for (final chat in chats) {
            final hasMessages = await chatHasMessages(chat.chatId);
            if (hasMessages) {
              chatsWithMessages.add(chat);
            }
          }
          
          return chatsWithMessages;
        } else {
          throw ChatRepositoryException('Failed to get chats: ${response.body}');
        }
      } catch (e) {
        debugPrint('Error in chats stream: $e');
        throw ChatRepositoryException('Failed to get chats stream: $e');
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
        throw ChatRepositoryException('Failed to get chat by ID: ${response.body}');
      }
    } catch (e) {
      if (e is NotFoundException) return null;
      throw ChatRepositoryException('Failed to get chat by ID: $e');
    }
  }

  @override
  Future<void> updateChatLastMessage(ChatModel chat) async {
    try {
      final response = await _httpClient.put('/chats/${chat.chatId}/last-message', body: {
        'lastMessage': chat.lastMessage,
        'lastMessageType': chat.lastMessageType.name,
        'lastMessageSender': chat.lastMessageSender,
        'lastMessageTime': chat.lastMessageTime.toIso8601String(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to update chat last message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to update chat last message: $e');
    }
  }

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      final response = await _httpClient.post('/chats/$chatId/mark-read', body: {
        'userId': userId,
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to mark chat as read: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to mark chat as read: $e');
    }
  }

  @override
  Future<void> toggleChatPin(String chatId, String userId) async {
    try {
      final response = await _httpClient.post('/chats/$chatId/toggle-pin', body: {
        'userId': userId,
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to toggle chat pin: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to toggle chat pin: $e');
    }
  }

  @override
  Future<void> toggleChatArchive(String chatId, String userId) async {
    try {
      final response = await _httpClient.post('/chats/$chatId/toggle-archive', body: {
        'userId': userId,
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to toggle chat archive: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to toggle chat archive: $e');
    }
  }

  @override
  Future<void> toggleChatMute(String chatId, String userId) async {
    try {
      final response = await _httpClient.post('/chats/$chatId/toggle-mute', body: {
        'userId': userId,
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to toggle chat mute: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to toggle chat mute: $e');
    }
  }

  @override
  Future<void> deleteChat(String chatId, String userId, {bool deleteForEveryone = false}) async {
    try {
      final response = await _httpClient.delete('/chats/$chatId?userId=$userId&deleteForEveryone=$deleteForEveryone');

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to delete chat: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to delete chat: $e');
    }
  }

  @override
  Future<void> clearChatHistory(String chatId, String userId) async {
    try {
      final response = await _httpClient.post('/chats/$chatId/clear-history', body: {
        'userId': userId,
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to clear chat history: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to clear chat history: $e');
    }
  }

  @override
  Future<void> setChatWallpaper(String chatId, String userId, String? wallpaperUrl) async {
    try {
      final response = await _httpClient.post('/chats/$chatId/wallpaper', body: {
        'userId': userId,
        'wallpaperUrl': wallpaperUrl,
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to set chat wallpaper: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to set chat wallpaper: $e');
    }
  }

  @override
  Future<void> setChatFontSize(String chatId, String userId, double fontSize) async {
    try {
      final response = await _httpClient.post('/chats/$chatId/font-size', body: {
        'userId': userId,
        'fontSize': fontSize,
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to set chat font size: ${response.body}');
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
      final messageId = message.messageId.isEmpty ? _uuid.v4() : message.messageId;
      final finalMessage = message.copyWith(messageId: messageId);

      final response = await _httpClient.post('/chats/${message.chatId}/messages', body: {
        'messageId': messageId,
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
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['messageId'] ?? messageId;
      } else {
        throw ChatRepositoryException('Failed to send message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to send message: $e');
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
      
      final response = await _httpClient.post('/chats/$chatId/messages', body: {
        'messageId': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'content': '',
        'type': MessageEnum.video.name,
        'status': MessageStatus.sending.name,
        'timestamp': _createTimestamp(),
        'mediaUrl': videoUrl,
        'mediaMetadata': {
          'isSharedVideo': true,
          'videoId': videoId,
          'thumbnailUrl': thumbnailUrl,
        },
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return messageId;
      } else {
        throw ChatRepositoryException('Failed to send video message: ${response.body}');
      }
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
      
      final response = await _httpClient.post('/chats/$chatId/messages', body: {
        'messageId': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'content': videoReaction.reaction ?? '',
        'type': MessageEnum.text.name,
        'status': MessageStatus.sending.name,
        'timestamp': _createTimestamp(),
        'mediaUrl': videoReaction.videoUrl,
        'mediaMetadata': {
          'isVideoReaction': true,
          'videoReaction': videoReaction.toMap(),
          'thumbnailUrl': videoReaction.thumbnailUrl,
          'videoId': videoReaction.videoId,
          'channelName': videoReaction.channelName,
          'channelImage': videoReaction.channelImage,
        },
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return messageId;
      } else {
        throw ChatRepositoryException('Failed to send video reaction message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to send video reaction message: $e');
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
      
      final response = await _httpClient.post('/chats/$chatId/messages', body: {
        'messageId': messageId,
        'chatId': chatId,
        'senderId': senderId,
        'content': momentReaction.reaction,
        'type': MessageEnum.text.name,
        'status': MessageStatus.sending.name,
        'timestamp': _createTimestamp(),
        'mediaUrl': momentReaction.mediaUrl,
        'mediaMetadata': {
          'isMomentReaction': true,
          'momentReaction': momentReaction.toMap(),
          'thumbnailUrl': momentReaction.thumbnailUrl,
          'momentId': momentReaction.momentId,
          'authorName': momentReaction.authorName,
          'authorImage': momentReaction.authorImage,
          'mediaType': momentReaction.mediaType,
          'momentContent': momentReaction.content,
        },
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return messageId;
      } else {
        throw ChatRepositoryException('Failed to send moment reaction message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to send moment reaction message: $e');
    }
  }

  @override
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    // Implement polling for messages since we're not using real-time Firebase
    return Stream.periodic(const Duration(seconds: 2), (count) async {
      try {
        final response = await _httpClient.get('/chats/$chatId/messages?limit=50');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final List<dynamic> messagesData = data['messages'] ?? [];
          
          return messagesData
              .map((messageData) => MessageModel.fromMap(messageData as Map<String, dynamic>))
              .toList();
        } else {
          throw ChatRepositoryException('Failed to get messages: ${response.body}');
        }
      } catch (e) {
        debugPrint('Error in messages stream: $e');
        throw ChatRepositoryException('Failed to get messages stream: $e');
      }
    }).asyncMap((future) => future);
  }

  @override
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    try {
      final response = await _httpClient.put('/chats/$chatId/messages/$messageId/status', body: {
        'status': status.name,
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to update message status: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to update message status: $e');
    }
  }

  @override
  Future<void> markMessageAsDelivered(String chatId, String messageId, String userId) async {
    try {
      final response = await _httpClient.post('/chats/$chatId/messages/$messageId/delivered', body: {
        'userId': userId,
        'deliveredAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to mark message as delivered: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to mark message as delivered: $e');
    }
  }

  @override
  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    try {
      final response = await _httpClient.put('/chats/$chatId/messages/$messageId', body: {
        'content': newContent,
        'isEdited': true,
        'editedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to edit message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to edit message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    try {
      final response = await _httpClient.delete('/chats/$chatId/messages/$messageId?deleteForEveryone=$deleteForEveryone');

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to delete message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to delete message: $e');
    }
  }

  @override
  Future<void> pinMessage(String chatId, String messageId) async {
    try {
      final response = await _httpClient.post('/chats/$chatId/messages/$messageId/pin', body: {});

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to pin message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to pin message: $e');
    }
  }

  @override
  Future<void> unpinMessage(String chatId, String messageId) async {
    try {
      final response = await _httpClient.delete('/chats/$chatId/messages/$messageId/pin');

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to unpin message: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to unpin message: $e');
    }
  }

  @override
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    try {
      final response = await _httpClient.get('/chats/$chatId/messages/search?q=${Uri.encodeComponent(query)}&limit=100');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> messagesData = data['messages'] ?? [];
        
        return messagesData
            .map((messageData) => MessageModel.fromMap(messageData as Map<String, dynamic>))
            .toList();
      } else {
        throw ChatRepositoryException('Failed to search messages: ${response.body}');
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
            .map((messageData) => MessageModel.fromMap(messageData as Map<String, dynamic>))
            .toList();
      } else {
        throw ChatRepositoryException('Failed to get pinned messages: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to get pinned messages: $e');
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
      if (fileSize > 50 * 1024 * 1024) { // 50MB limit
        throw ChatRepositoryException('File size exceeds 50MB limit');
      }

      final response = await _httpClient.uploadFile(
        '/upload',
        file,
        'file',
        additionalFields: {
          'type': 'chat',
          'chatId': chatId,
          'fileName': fileName,
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
      final response = await _httpClient.delete('/media?url=${Uri.encodeComponent(mediaUrl)}');

      if (response.statusCode != 200) {
        throw ChatRepositoryException('Failed to delete media: ${response.body}');
      }
    } catch (e) {
      throw ChatRepositoryException('Failed to delete media: $e');
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
// EXCEPTION CLASS
// ========================================

class ChatRepositoryException implements Exception {
  final String message;
  const ChatRepositoryException(this.message);
  
  @override
  String toString() => 'ChatRepositoryException: $message';
}