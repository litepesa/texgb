// lib/features/video_reactions/repositories/video_reactions_repository.dart
// EXTRACTED: Standalone video reactions repository
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_model.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_chat_model.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_message_model.dart';
import 'package:textgb/shared/services/http_client.dart';
import 'package:uuid/uuid.dart';

// ========================================
// ABSTRACT REPOSITORY INTERFACE
// ========================================

abstract class VideoReactionsRepository {
  // Video Reaction Chat operations
  Future<String> createVideoReactionChat({
    required String currentUserId,
    required String videoOwnerId,
    required VideoReactionModel videoReaction,
  });
  
  Stream<List<VideoReactionChatModel>> getVideoReactionChatsStream(String userId);
  Future<VideoReactionChatModel?> getVideoReactionChatById(String chatId);
  Future<void> updateChatLastMessage(VideoReactionChatModel chat);
  
  // Video Reaction Message operations
  Future<String> sendVideoReactionMessage({
    required String chatId,
    required String senderId,
    required String content,
    required VideoReactionModel? videoReactionData,
    bool isOriginalReaction = false,
  });
  
  Future<String> sendTextMessage({
    required String chatId,
    required String senderId,
    required String content,
    String? replyToMessageId,
  });

  Future<String> sendImageMessage({
    required String chatId,
    required String senderId,
    required File imageFile,
    String? replyToMessageId,
  });
  
  Future<String> sendFileMessage({
    required String chatId,
    required String senderId,
    required File file,
    required String fileName,
    String? replyToMessageId,
  });
  
  Stream<List<VideoReactionMessageModel>> getMessagesStream(String chatId);
  Future<void> updateMessageStatus(
      String chatId, String messageId, MessageStatus status);
  Future<void> markMessageAsDelivered(
      String chatId, String messageId, String userId);
  Future<void> editMessage(String chatId, String messageId, String newContent);
  Future<void> deleteMessage(
      String chatId, String messageId, bool deleteForEveryone);
  Future<void> pinMessage(String chatId, String messageId);
  Future<void> unpinMessage(String chatId, String messageId);
  Future<List<VideoReactionMessageModel>> searchMessages(String chatId, String query);
  Future<List<VideoReactionMessageModel>> getPinnedMessages(String chatId);
  
  // Chat management
  Future<void> markChatAsRead(String chatId, String userId);
  Future<void> toggleChatPin(String chatId, String userId);
  Future<void> toggleChatArchive(String chatId, String userId);
  Future<void> toggleChatMute(String chatId, String userId);
  Future<void> deleteChat(String chatId, String userId, {bool deleteForEveryone = false});
  Future<void> clearChatHistory(String chatId, String userId);
  
  // Utility
  String generateChatId(String userId1, String userId2, String videoId);
  Future<bool> chatExists(String chatId);
  Future<bool> chatHasMessages(String chatId);
}

// ========================================
// HTTP IMPLEMENTATION
// ========================================

class HttpVideoReactionsRepository implements VideoReactionsRepository {
  final HttpClientService _httpClient;
  final Uuid _uuid;

  HttpVideoReactionsRepository({
    HttpClientService? httpClient,
    Uuid? uuid,
  })  : _httpClient = httpClient ?? HttpClientService(),
        _uuid = uuid ?? const Uuid();

  // Helper method to create RFC3339 timestamps
  String _createTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  @override
  String generateChatId(String userId1, String userId2, String videoId) {
    // Create unique chat ID for video reactions: video_reaction_{videoId}_{user1}_{user2}
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

  // ========================================
  // VIDEO REACTION CHAT OPERATIONS
  // ========================================

  @override
  Future<String> createVideoReactionChat({
    required String currentUserId,
    required String videoOwnerId,
    required VideoReactionModel videoReaction,
  }) async {
    try {
      final chatId = generateChatId(currentUserId, videoOwnerId, videoReaction.videoId);

      final response = await _httpClient.post('/video-reactions/chats', body: {
        'chatId': chatId,
        'participants': [currentUserId, videoOwnerId],
        'originalReaction': videoReaction.toMap(),
        'createdAt': _createTimestamp(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Send the initial video reaction message
        await sendVideoReactionMessage(
          chatId: chatId,
          senderId: currentUserId,
          content: videoReaction.reaction ?? '',
          videoReactionData: videoReaction,
          isOriginalReaction: true,
        );
        
        return data['chatId'] ?? chatId;
      } else {
        throw VideoReactionsRepositoryException(
            'Failed to create video reaction chat: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating video reaction chat: $e');
      throw VideoReactionsRepositoryException('Failed to create video reaction chat: $e');
    }
  }

  @override
  Stream<List<VideoReactionChatModel>> getVideoReactionChatsStream(String userId) {
    return Stream.periodic(const Duration(seconds: 3), (count) async {
      try {
        final response = await _httpClient.get('/video-reactions/chats');

        debugPrint('Video reaction chats response status: ${response.statusCode}');
        debugPrint('Video reaction chats response body: ${response.body}');

        if (response.statusCode == 200) {
          if (response.body.isEmpty) {
            debugPrint('Empty response body, returning empty list');
            return <VideoReactionChatModel>[];
          }

          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final List<dynamic> chatsData = data['chats'] ?? [];

          debugPrint('Parsed ${chatsData.length} video reaction chats from response');

          if (chatsData.isEmpty) {
            return <VideoReactionChatModel>[];
          }

          final chats = chatsData
              .map((chatData) {
                try {
                  return VideoReactionChatModel.fromMap(chatData as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('Error parsing video reaction chat: $e');
                  debugPrint('Chat data: $chatData');
                  return null;
                }
              })
              .whereType<VideoReactionChatModel>()
              .where((chat) => !chat.isArchivedForUser(userId))
              .toList();

          // Sort by last message time (most recent first)
          chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

          return chats;
        } else if (response.statusCode == 404) {
          debugPrint('Video reaction chats endpoint not found, returning empty list');
          return <VideoReactionChatModel>[];
        } else if (response.statusCode == 401) {
          debugPrint('Unauthorized - authentication issue');
          return <VideoReactionChatModel>[];
        } else {
          throw VideoReactionsRepositoryException(
              'Failed to get video reaction chats: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        debugPrint('Error in video reaction chats stream: $e');
        return <VideoReactionChatModel>[];
      }
    }).asyncMap((future) => future);
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
        throw VideoReactionsRepositoryException(
            'Failed to get video reaction chat by ID: ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('404')) return null;
      throw VideoReactionsRepositoryException('Failed to get video reaction chat by ID: $e');
    }
  }

  @override
  Future<void> updateChatLastMessage(VideoReactionChatModel chat) async {
    try {
      final response = await _httpClient.put('/video-reactions/chats/${chat.chatId}/last-message', body: {
        'lastMessage': chat.lastMessage,
        'lastMessageType': chat.lastMessageType.name,
        'lastMessageSender': chat.lastMessageSender,
        'lastMessageTime': chat.lastMessageTime.toIso8601String(),
        'updatedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to update chat last message: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to update chat last message: $e');
    }
  }

  // ========================================
  // VIDEO REACTION MESSAGE OPERATIONS
  // ========================================

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

      final message = VideoReactionMessageModel(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: MessageEnum.text, // Video reactions are displayed as text messages with special data
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        videoReactionData: videoReactionData,
        isOriginalReaction: isOriginalReaction,
      );

      final response = await _httpClient.post('/video-reactions/chats/$chatId/messages', body: message.toMap());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Update chat last message
        await _updateChatWithNewMessage(chatId, message);

        return data['messageId'] ?? messageId;
      } else {
        throw VideoReactionsRepositoryException(
            'Failed to send video reaction message: ${response.body}');
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

      final message = VideoReactionMessageModel(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        content: content,
        type: MessageEnum.text,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        replyToMessageId: replyToMessageId,
      );

      final response = await _httpClient.post('/video-reactions/chats/$chatId/messages', body: message.toMap());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Update chat last message
        await _updateChatWithNewMessage(chatId, message);

        return data['messageId'] ?? messageId;
      } else {
        throw VideoReactionsRepositoryException(
            'Failed to send text message: ${response.body}');
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
      // For now, using local path as placeholder
      final imageUrl = imageFile.path;

      final message = VideoReactionMessageModel(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        content: 'Image',
        type: MessageEnum.image,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaUrl: imageUrl,
        replyToMessageId: replyToMessageId,
      );

      final response = await _httpClient.post('/video-reactions/chats/$chatId/messages', body: message.toMap());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Update chat last message
        await _updateChatWithNewMessage(chatId, message);

        return data['messageId'] ?? messageId;
      } else {
        throw VideoReactionsRepositoryException('Failed to send image message: ${response.body}');
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

      // TODO: Upload file to storage and get URL
      // For now, using local path as placeholder
      final fileUrl = file.path;

      final message = VideoReactionMessageModel(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        content: fileName,
        type: MessageEnum.file,
        status: MessageStatus.sending,
        timestamp: DateTime.now(),
        mediaUrl: fileUrl,
        mediaMetadata: {
          'fileName': fileName,
          'fileSize': await file.length(),
        },
        replyToMessageId: replyToMessageId,
      );

      final response = await _httpClient.post('/video-reactions/chats/$chatId/messages', body: message.toMap());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Update chat last message
        await _updateChatWithNewMessage(chatId, message);

        return data['messageId'] ?? messageId;
      } else {
        throw VideoReactionsRepositoryException('Failed to send file message: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to send file message: $e');
    }
  }

  // Helper method to update chat with new message info
  Future<void> _updateChatWithNewMessage(String chatId, VideoReactionMessageModel message) async {
    try {
      await _httpClient.put('/video-reactions/chats/$chatId/last-message', body: {
        'lastMessage': message.getDisplayContent(),
        'lastMessageType': message.type.name,
        'lastMessageSender': message.senderId,
        'lastMessageTime': message.timestamp.toIso8601String(),
        'updatedAt': _createTimestamp(),
      });

      // Also increment unread count for other participants
      final chat = await getVideoReactionChatById(chatId);
      if (chat != null) {
        for (final participantId in chat.participants) {
          if (participantId != message.senderId) {
            await _incrementUnreadCount(chatId, participantId);
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating chat last message: $e');
    }
  }

  // Helper method to increment unread count
  Future<void> _incrementUnreadCount(String chatId, String userId) async {
    try {
      await _httpClient.post('/video-reactions/chats/$chatId/increment-unread', body: {
        'userId': userId,
      });
    } catch (e) {
      debugPrint('Error incrementing unread count: $e');
    }
  }

  @override
  Stream<List<VideoReactionMessageModel>> getMessagesStream(String chatId) {
    return Stream.periodic(const Duration(seconds: 2), (count) async {
      try {
        final response = await _httpClient
            .get('/video-reactions/chats/$chatId/messages?limit=100&sort=desc');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final List<dynamic> messagesData = data['messages'] ?? [];

          return messagesData
              .map((messageData) =>
                  VideoReactionMessageModel.fromMap(messageData as Map<String, dynamic>))
              .toList();
        } else {
          throw VideoReactionsRepositoryException(
              'Failed to get messages: ${response.body}');
        }
      } catch (e) {
        debugPrint('Error in messages stream: $e');
        throw VideoReactionsRepositoryException('Failed to get messages stream: $e');
      }
    }).asyncMap((future) => future);
  }

  @override
  Future<void> updateMessageStatus(String chatId, String messageId, MessageStatus status) async {
    try {
      final response = await _httpClient
          .put('/video-reactions/chats/$chatId/messages/$messageId/status', body: {
        'status': status.name,
        'updatedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to update message status: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to update message status: $e');
    }
  }

  @override
  Future<void> markMessageAsDelivered(String chatId, String messageId, String userId) async {
    try {
      final response = await _httpClient
          .post('/video-reactions/chats/$chatId/messages/$messageId/delivered', body: {
        'userId': userId,
        'deliveredAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to mark message as delivered: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to mark message as delivered: $e');
    }
  }

  @override
  Future<void> editMessage(String chatId, String messageId, String newContent) async {
    try {
      final response = await _httpClient.put('/video-reactions/chats/$chatId/messages/$messageId', body: {
        'content': newContent,
        'isEdited': true,
        'editedAt': _createTimestamp(),
        'updatedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to edit message: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to edit message: $e');
    }
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId, bool deleteForEveryone) async {
    try {
      final response = await _httpClient.delete(
          '/video-reactions/chats/$chatId/messages/$messageId?deleteForEveryone=$deleteForEveryone');

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to delete message: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to delete message: $e');
    }
  }

  @override
  Future<void> pinMessage(String chatId, String messageId) async {
    try {
      final response = await _httpClient
          .post('/video-reactions/chats/$chatId/messages/$messageId/pin', body: {
        'pinnedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to pin message: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to pin message: $e');
    }
  }

  @override
  Future<void> unpinMessage(String chatId, String messageId) async {
    try {
      final response = await _httpClient
          .delete('/video-reactions/chats/$chatId/messages/$messageId/pin');

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to unpin message: ${response.body}');
      }
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
            .map((messageData) =>
                VideoReactionMessageModel.fromMap(messageData as Map<String, dynamic>))
            .toList();
      } else {
        throw VideoReactionsRepositoryException(
            'Failed to search messages: ${response.body}');
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
            .map((messageData) =>
                VideoReactionMessageModel.fromMap(messageData as Map<String, dynamic>))
            .toList();
      } else {
        throw VideoReactionsRepositoryException(
            'Failed to get pinned messages: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to get pinned messages: $e');
    }
  }

  // ========================================
  // CHAT MANAGEMENT OPERATIONS
  // ========================================

  @override
  Future<void> markChatAsRead(String chatId, String userId) async {
    try {
      final response = await _httpClient.post('/video-reactions/chats/$chatId/mark-read', body: {
        'userId': userId,
        'readAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to mark chat as read: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to mark chat as read: $e');
    }
  }

  @override
  Future<void> toggleChatPin(String chatId, String userId) async {
    try {
      final response = await _httpClient.post('/video-reactions/chats/$chatId/toggle-pin', body: {
        'userId': userId,
        'pinnedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to toggle chat pin: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to toggle chat pin: $e');
    }
  }

  @override
  Future<void> toggleChatArchive(String chatId, String userId) async {
    try {
      final response = await _httpClient.post('/video-reactions/chats/$chatId/toggle-archive', body: {
        'userId': userId,
        'archivedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to toggle chat archive: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to toggle chat archive: $e');
    }
  }

  @override
  Future<void> toggleChatMute(String chatId, String userId) async {
    try {
      final response = await _httpClient.post('/video-reactions/chats/$chatId/toggle-mute', body: {
        'userId': userId,
        'mutedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to toggle chat mute: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to toggle chat mute: $e');
    }
  }

  @override
  Future<void> deleteChat(String chatId, String userId, {bool deleteForEveryone = false}) async {
    try {
      final response = await _httpClient.delete(
          '/video-reactions/chats/$chatId?userId=$userId&deleteForEveryone=$deleteForEveryone');

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to delete chat: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to delete chat: $e');
    }
  }

  @override
  Future<void> clearChatHistory(String chatId, String userId) async {
    try {
      final response = await _httpClient.post('/video-reactions/chats/$chatId/clear-history', body: {
        'userId': userId,
        'clearedAt': _createTimestamp(),
      });

      if (response.statusCode != 200) {
        throw VideoReactionsRepositoryException(
            'Failed to clear chat history: ${response.body}');
      }
    } catch (e) {
      throw VideoReactionsRepositoryException('Failed to clear chat history: $e');
    }
  }
}

// ========================================
// REPOSITORY PROVIDER
// ========================================

final videoReactionsRepositoryProvider = Provider<VideoReactionsRepository>((ref) {
  return HttpVideoReactionsRepository();
});

// ========================================
// EXCEPTION CLASSES
// ========================================

class VideoReactionsRepositoryException implements Exception {
  final String message;
  const VideoReactionsRepositoryException(this.message);

  @override
  String toString() => 'VideoReactionsRepositoryException: $message';
}

class VideoReactionChatNotFoundException extends VideoReactionsRepositoryException {
  const VideoReactionChatNotFoundException(String chatId) 
      : super('Video reaction chat not found: $chatId');
}

class VideoReactionMessageNotFoundException extends VideoReactionsRepositoryException {
  const VideoReactionMessageNotFoundException(String messageId)
      : super('Video reaction message not found: $messageId');
}

class UserNotInVideoReactionChatException extends VideoReactionsRepositoryException {
  const UserNotInVideoReactionChatException(String userId, String chatId)
      : super('User $userId not in video reaction chat $chatId');
}

class InvalidVideoReactionException extends VideoReactionsRepositoryException {
  const InvalidVideoReactionException(String reason)
      : super('Invalid video reaction: $reason');
}