// lib/features/video_reactions/repositories/video_reactions_repository.dart
// Video Reactions Repository Interface
// 
// This file defines the contract that all repository implementations must follow.
// 
// CURRENT IMPLEMENTATION: WebSocket-based (websocket_video_reactions_repository.dart)
// - Real-time messaging via WebSocket
// - HTTP used only for file uploads and essential operations
// - No polling, instant message delivery

import 'dart:io';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_model.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_chat_model.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_message_model.dart';

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

// ========================================
// NOTE ON IMPLEMENTATION
// ========================================
// 
// The actual implementation is in websocket_video_reactions_repository.dart
// which uses:
// 
// ✅ WebSocket for:
//    - Real-time messaging (instant delivery)
//    - Chat updates
//    - Typing indicators
//    - Presence updates
//    - Read receipts
//    - Message updates/deletes
// 
// ✅ HTTP for:
//    - File uploads (images, videos, documents)
//    - Initial data loading
//    - Search functionality
//    - Settings/preferences
// 
// The provider is configured in video_reactions_provider.dart:
// final videoReactionsRepositoryProvider = Provider<VideoReactionsRepository>((ref) {
//   return ref.watch(websocketVideoReactionsRepositoryProvider);
// });