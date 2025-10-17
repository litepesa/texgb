// lib/features/chat/repositories/chat_repository.dart
// Abstract repository interface for chat operations
// Defines contract for WebSocket + SQLite implementation

import 'dart:io';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';

/// Exception class for chat repository errors
class ChatRepositoryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const ChatRepositoryException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'ChatRepositoryException: $message';
}

/// Abstract repository interface for all chat operations
/// Implementation will use WebSocket for real-time + SQLite for local storage
abstract class ChatRepository {
  // ===============================
  // CONNECTION MANAGEMENT
  // ===============================
  
  /// Connect to WebSocket server
  Future<void> connect();
  
  /// Disconnect from WebSocket server
  Future<void> disconnect();
  
  /// Check if currently connected to WebSocket
  bool get isConnected;
  
  /// Listen to connection state changes
  Stream<bool> get connectionStateStream;
  
  /// Reconnect to WebSocket server
  Future<void> reconnect();

  // ===============================
  // CHAT OPERATIONS
  // ===============================
  
  /// Get all chats for current user
  /// Returns chats from local DB immediately, then syncs with server
  Future<List<ChatModel>> getChats();
  
  /// Get a specific chat by ID
  /// Checks local DB first, then server if not found
  Future<ChatModel?> getChatById(String chatId);
  
  /// Get or create one-on-one chat with another user
  Future<ChatModel> getOrCreateOneOnOneChat({
    required String currentUserId,
    required String otherUserId,
    required String otherUserName,
    required String otherUserImage,
  });
  
  /// Create a new group chat
  Future<ChatModel> createGroupChat({
    required String groupName,
    required String? groupImage,
    required String? groupDescription,
    required String creatorId,
    required List<String> participantIds,
    required List<String> participantNames,
    required List<String> participantImages,
  });
  
  /// Update chat settings (mute, pin, archive, block)
  Future<void> updateChatSettings({
    required String chatId,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
    bool? isBlocked,
  });
  
  /// Delete chat (local only - messages remain on server)
  Future<void> deleteChat(String chatId);
  
  /// Clear all messages in a chat (local only)
  Future<void> clearChatMessages(String chatId);
  
  /// Search chats by name or last message
  Future<List<ChatModel>> searchChats(String query);
  
  /// Listen to real-time chat updates
  Stream<ChatModel> watchChat(String chatId);
  
  /// Listen to all chats updates
  Stream<List<ChatModel>> watchAllChats();

  // ===============================
  // MESSAGE OPERATIONS
  // ===============================
  
  /// Get messages for a specific chat
  /// [limit] - number of messages to fetch
  /// [before] - fetch messages before this message ID (for pagination)
  Future<List<MessageModel>> getMessages({
    required String chatId,
    int limit = 50,
    String? before,
  });
  
  /// Get a specific message by ID
  Future<MessageModel?> getMessageById(String messageId);
  
  /// Send a text message
  Future<MessageModel> sendTextMessage({
    required String chatId,
    required String content,
    String? repliedToMessageId,
  });
  
  /// Send an image message
  Future<MessageModel> sendImageMessage({
    required String chatId,
    required File imageFile,
    String? caption,
    String? repliedToMessageId,
  });
  
  /// Send a video message
  Future<MessageModel> sendVideoMessage({
    required String chatId,
    required File videoFile,
    String? caption,
    String? repliedToMessageId,
  });
  
  /// Send an audio message
  Future<MessageModel> sendAudioMessage({
    required String chatId,
    required File audioFile,
    required int duration,
    String? repliedToMessageId,
  });
  
  /// Send a document message
  Future<MessageModel> sendDocumentMessage({
    required String chatId,
    required File documentFile,
    required String fileName,
    String? repliedToMessageId,
  });
  
  /// Send a location message
  Future<MessageModel> sendLocationMessage({
    required String chatId,
    required double latitude,
    required double longitude,
    String? locationName,
    String? repliedToMessageId,
  });
  
  /// Send a contact message
  Future<MessageModel> sendContactMessage({
    required String chatId,
    required String contactName,
    required String contactPhone,
    String? repliedToMessageId,
  });
  
  /// Forward messages to another chat
  Future<List<MessageModel>> forwardMessages({
    required List<String> messageIds,
    required String toChatId,
  });
  
  /// Update message status (sent, delivered, read)
  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  });
  
  /// Delete message (for current user only)
  Future<void> deleteMessage(String messageId);
  
  /// Star/unstar a message
  Future<void> toggleMessageStar(String messageId);
  
  /// Add reaction to a message
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  });
  
  /// Remove reaction from a message
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  });
  
  /// Search messages within a chat
  Future<List<MessageModel>> searchMessagesInChat({
    required String chatId,
    required String query,
  });
  
  /// Get starred messages
  Future<List<MessageModel>> getStarredMessages();
  
  /// Listen to real-time message updates for a chat
  Stream<MessageModel> watchMessages(String chatId);
  
  /// Listen to new messages across all chats
  Stream<MessageModel> watchNewMessages();

  // ===============================
  // UNREAD COUNT OPERATIONS
  // ===============================
  
  /// Get unread message count for a specific chat
  Future<int> getUnreadCount(String chatId);
  
  /// Get total unread count across all chats
  Future<int> getTotalUnreadCount();
  
  /// Mark chat as read (reset unread count)
  Future<void> markChatAsRead(String chatId);
  
  /// Mark specific message as read
  Future<void> markMessageAsRead(String messageId);

  // ===============================
  // MEDIA OPERATIONS
  // ===============================
  
  /// Upload media file to server
  /// Returns URL of uploaded file
  Future<String> uploadMediaFile({
    required File file,
    required String type, // 'image', 'video', 'audio', 'document'
    Function(double progress)? onProgress,
  });
  
  /// Download media file from server
  /// Returns local file path
  Future<String> downloadMediaFile({
    required String url,
    required String fileName,
    Function(double progress)? onProgress,
  });
  
  /// Get all media messages in a chat
  Future<List<MessageModel>> getChatMedia({
    required String chatId,
    MessageType? type, // Filter by type (image, video, etc.)
  });

  // ===============================
  // SYNC OPERATIONS
  // ===============================
  
  /// Sync local database with server
  /// Called when app comes online or periodically
  Future<void> syncWithServer();
  
  /// Force refresh chat from server
  Future<ChatModel?> refreshChat(String chatId);
  
  /// Force refresh messages from server
  Future<List<MessageModel>> refreshMessages(String chatId);
  
  /// Get pending messages (failed to send)
  Future<List<MessageModel>> getPendingMessages();
  
  /// Retry sending a failed message
  Future<void> retryMessage(String messageId);

  // ===============================
  // CACHE OPERATIONS
  // ===============================
  
  /// Clear all local cache
  Future<void> clearCache();
  
  /// Clear cache for specific chat
  Future<void> clearChatCache(String chatId);
  
  /// Get cache size
  Future<int> getCacheSize();

  // ===============================
  // USER INFO OPERATIONS
  // ===============================
  
  /// Get current user ID
  String? get currentUserId;
  
  /// Check if user is participant in a chat
  Future<bool> isParticipant(String chatId);
  
  /// Add participants to group chat
  Future<void> addParticipants({
    required String chatId,
    required List<String> userIds,
  });
  
  /// Remove participant from group chat
  Future<void> removeParticipant({
    required String chatId,
    required String userId,
  });
  
  /// Leave group chat
  Future<void> leaveGroupChat(String chatId);
  
  /// Update group info (name, image, description)
  Future<void> updateGroupInfo({
    required String chatId,
    String? groupName,
    String? groupImage,
    String? groupDescription,
  });
  
  /// Promote participant to admin
  Future<void> promoteToAdmin({
    required String chatId,
    required String userId,
  });
  
  /// Demote admin to regular participant
  Future<void> demoteAdmin({
    required String chatId,
    required String userId,
  });
}

/// Implementation hint: Concrete implementation will:
/// 1. Use WebSocket for real-time messaging
/// 2. Use SQLite for local storage and offline support
/// 3. Implement sync logic to keep local and server data in sync
/// 4. Handle connection failures and retry logic
/// 5. Provide streams for real-time updates