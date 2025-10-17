// lib/features/chat/services/chat_database_service.dart
// SQLite service for local chat and message storage
// Provides offline support and caching

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';

/// Exception class for database errors
class DatabaseException implements Exception {
  final String message;
  final dynamic originalError;

  const DatabaseException(this.message, {this.originalError});

  @override
  String toString() => 'DatabaseException: $message';
}

/// SQLite service for chat database operations
class ChatDatabaseService {
  // Singleton pattern
  static final ChatDatabaseService _instance = ChatDatabaseService._internal();
  factory ChatDatabaseService() => _instance;
  ChatDatabaseService._internal();

  // Database instance
  Database? _database;
  
  // Database configuration
  static const String _databaseName = 'textgb_chat.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _chatsTable = 'chats';
  static const String _messagesTable = 'messages';
  static const String _unreadCountsTable = 'unread_counts';

  // ===============================
  // DATABASE INITIALIZATION
  // ===============================

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      debugPrint('📂 Initializing database at: $path');

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );
    } catch (e) {
      debugPrint('❌ Database initialization failed: $e');
      throw DatabaseException('Failed to initialize database', originalError: e);
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('📊 Creating database tables...');

    // Create chats table
    await db.execute('''
      CREATE TABLE $_chatsTable (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        participant_ids TEXT NOT NULL,
        participant_names TEXT NOT NULL,
        participant_images TEXT NOT NULL,
        group_name TEXT,
        group_image TEXT,
        group_description TEXT,
        group_admin_id TEXT,
        group_admin_ids TEXT,
        last_message_id TEXT,
        last_message TEXT,
        last_message_sender_id TEXT,
        last_message_sender_name TEXT,
        last_message_type TEXT DEFAULT 'text',
        last_message_time TEXT NOT NULL,
        is_muted INTEGER DEFAULT 0,
        is_pinned INTEGER DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        is_blocked INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create messages table
    await db.execute('''
      CREATE TABLE $_messagesTable (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        sender_image TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        media_url TEXT,
        thumbnail_url TEXT,
        file_name TEXT,
        file_size INTEGER,
        duration INTEGER,
        replied_to_message_id TEXT,
        replied_to_content TEXT,
        replied_to_sender_name TEXT,
        replied_to_type TEXT,
        latitude REAL,
        longitude REAL,
        location_name TEXT,
        contact_name TEXT,
        contact_phone TEXT,
        reactions TEXT,
        is_forwarded INTEGER DEFAULT 0,
        is_starred INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        delivered_at TEXT,
        FOREIGN KEY (chat_id) REFERENCES $_chatsTable (id) ON DELETE CASCADE
      )
    ''');

    // Create unread counts table
    await db.execute('''
      CREATE TABLE $_unreadCountsTable (
        chat_id TEXT PRIMARY KEY,
        count INTEGER DEFAULT 0,
        FOREIGN KEY (chat_id) REFERENCES $_chatsTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_messages_chat_id ON $_messagesTable (chat_id)');
    await db.execute('CREATE INDEX idx_messages_created_at ON $_messagesTable (created_at DESC)');
    await db.execute('CREATE INDEX idx_messages_status ON $_messagesTable (status)');
    await db.execute('CREATE INDEX idx_chats_updated_at ON $_chatsTable (updated_at DESC)');
    await db.execute('CREATE INDEX idx_chats_is_archived ON $_chatsTable (is_archived)');

    debugPrint('✅ Database tables created successfully');
  }

  /// Upgrade database (for future versions)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrading database from v$oldVersion to v$newVersion');
    // Handle database migrations here in future versions
  }

  /// On database open
  Future<void> _onOpen(Database db) async {
    debugPrint('✅ Database opened successfully');
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ===============================
  // CHAT OPERATIONS
  // ===============================

  /// Insert or update a chat
  Future<void> upsertChat(ChatModel chat) async {
    try {
      final db = await database;
      await db.insert(
        _chatsTable,
        _chatToMap(chat),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('💾 Chat saved: ${chat.id}');
    } catch (e) {
      debugPrint('❌ Error saving chat: $e');
      throw DatabaseException('Failed to save chat', originalError: e);
    }
  }

  /// Get all chats
  Future<List<ChatModel>> getAllChats() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _chatsTable,
        orderBy: 'is_pinned DESC, updated_at DESC',
      );
      return maps.map((map) => _mapToChat(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting chats: $e');
      throw DatabaseException('Failed to get chats', originalError: e);
    }
  }

  /// Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _chatsTable,
        where: 'id = ?',
        whereArgs: [chatId],
        limit: 1,
      );
      
      if (maps.isEmpty) return null;
      return _mapToChat(maps.first);
    } catch (e) {
      debugPrint('❌ Error getting chat: $e');
      throw DatabaseException('Failed to get chat', originalError: e);
    }
  }

  /// Update chat settings
  Future<void> updateChatSettings({
    required String chatId,
    bool? isMuted,
    bool? isPinned,
    bool? isArchived,
    bool? isBlocked,
  }) async {
    try {
      final db = await database;
      final Map<String, dynamic> updates = {};
      
      if (isMuted != null) updates['is_muted'] = isMuted ? 1 : 0;
      if (isPinned != null) updates['is_pinned'] = isPinned ? 1 : 0;
      if (isArchived != null) updates['is_archived'] = isArchived ? 1 : 0;
      if (isBlocked != null) updates['is_blocked'] = isBlocked ? 1 : 0;
      
      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();
        await db.update(
          _chatsTable,
          updates,
          where: 'id = ?',
          whereArgs: [chatId],
        );
        debugPrint('💾 Chat settings updated: $chatId');
      }
    } catch (e) {
      debugPrint('❌ Error updating chat settings: $e');
      throw DatabaseException('Failed to update chat settings', originalError: e);
    }
  }

  /// Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      final db = await database;
      await db.delete(
        _chatsTable,
        where: 'id = ?',
        whereArgs: [chatId],
      );
      debugPrint('🗑️ Chat deleted: $chatId');
    } catch (e) {
      debugPrint('❌ Error deleting chat: $e');
      throw DatabaseException('Failed to delete chat', originalError: e);
    }
  }

  /// Search chats
  Future<List<ChatModel>> searchChats(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _chatsTable,
        where: 'group_name LIKE ? OR last_message LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'updated_at DESC',
      );
      return maps.map((map) => _mapToChat(map)).toList();
    } catch (e) {
      debugPrint('❌ Error searching chats: $e');
      throw DatabaseException('Failed to search chats', originalError: e);
    }
  }

  // ===============================
  // MESSAGE OPERATIONS
  // ===============================

  /// Insert or update a message
  Future<void> upsertMessage(MessageModel message) async {
    try {
      final db = await database;
      await db.insert(
        _messagesTable,
        _messageToMap(message),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('💾 Message saved: ${message.id}');
    } catch (e) {
      debugPrint('❌ Error saving message: $e');
      throw DatabaseException('Failed to save message', originalError: e);
    }
  }

  /// Batch insert messages (more efficient)
  Future<void> batchInsertMessages(List<MessageModel> messages) async {
    try {
      final db = await database;
      final batch = db.batch();
      
      for (final message in messages) {
        batch.insert(
          _messagesTable,
          _messageToMap(message),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
      debugPrint('💾 Batch inserted ${messages.length} messages');
    } catch (e) {
      debugPrint('❌ Error batch inserting messages: $e');
      throw DatabaseException('Failed to batch insert messages', originalError: e);
    }
  }

  /// Get messages for a chat
  Future<List<MessageModel>> getMessages({
    required String chatId,
    int limit = 50,
    String? before,
  }) async {
    try {
      final db = await database;
      String whereClause = 'chat_id = ? AND is_deleted = 0';
      List<dynamic> whereArgs = [chatId];
      
      if (before != null) {
        // Get the timestamp of the "before" message
        final beforeMessage = await getMessageById(before);
        if (beforeMessage != null) {
          whereClause += ' AND created_at < ?';
          whereArgs.add(beforeMessage.createdAt);
        }
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        _messagesTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
        limit: limit,
      );
      
      return maps.map((map) => _mapToMessage(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting messages: $e');
      throw DatabaseException('Failed to get messages', originalError: e);
    }
  }

  /// Get message by ID
  Future<MessageModel?> getMessageById(String messageId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _messagesTable,
        where: 'id = ?',
        whereArgs: [messageId],
        limit: 1,
      );
      
      if (maps.isEmpty) return null;
      return _mapToMessage(maps.first);
    } catch (e) {
      debugPrint('❌ Error getting message: $e');
      throw DatabaseException('Failed to get message', originalError: e);
    }
  }

  /// Update message status
  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  }) async {
    try {
      final db = await database;
      final updates = {
        'status': status.value,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (status == MessageStatus.delivered) {
        updates['delivered_at'] = DateTime.now().toIso8601String();
      }
      
      await db.update(
        _messagesTable,
        updates,
        where: 'id = ?',
        whereArgs: [messageId],
      );
      debugPrint('💾 Message status updated: $messageId -> ${status.value}');
    } catch (e) {
      debugPrint('❌ Error updating message status: $e');
      throw DatabaseException('Failed to update message status', originalError: e);
    }
  }

  /// Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      final db = await database;
      await db.update(
        _messagesTable,
        {
          'is_deleted': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [messageId],
      );
      debugPrint('🗑️ Message deleted: $messageId');
    } catch (e) {
      debugPrint('❌ Error deleting message: $e');
      throw DatabaseException('Failed to delete message', originalError: e);
    }
  }

  /// Toggle message star
  Future<void> toggleMessageStar(String messageId, bool isStarred) async {
    try {
      final db = await database;
      await db.update(
        _messagesTable,
        {
          'is_starred': isStarred ? 1 : 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [messageId],
      );
      debugPrint('⭐ Message star toggled: $messageId -> $isStarred');
    } catch (e) {
      debugPrint('❌ Error toggling message star: $e');
      throw DatabaseException('Failed to toggle message star', originalError: e);
    }
  }

  /// Get starred messages
  Future<List<MessageModel>> getStarredMessages() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _messagesTable,
        where: 'is_starred = 1 AND is_deleted = 0',
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => _mapToMessage(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting starred messages: $e');
      throw DatabaseException('Failed to get starred messages', originalError: e);
    }
  }

  /// Search messages in a chat
  Future<List<MessageModel>> searchMessagesInChat({
    required String chatId,
    required String query,
  }) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _messagesTable,
        where: 'chat_id = ? AND content LIKE ? AND is_deleted = 0',
        whereArgs: [chatId, '%$query%'],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => _mapToMessage(map)).toList();
    } catch (e) {
      debugPrint('❌ Error searching messages: $e');
      throw DatabaseException('Failed to search messages', originalError: e);
    }
  }

  /// Get pending messages (failed to send)
  Future<List<MessageModel>> getPendingMessages() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _messagesTable,
        where: 'status IN (?, ?) AND is_deleted = 0',
        whereArgs: [MessageStatus.sending.value, MessageStatus.failed.value],
        orderBy: 'created_at ASC',
      );
      return maps.map((map) => _mapToMessage(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting pending messages: $e');
      throw DatabaseException('Failed to get pending messages', originalError: e);
    }
  }

  /// Clear all messages in a chat
  Future<void> clearChatMessages(String chatId) async {
    try {
      final db = await database;
      await db.delete(
        _messagesTable,
        where: 'chat_id = ?',
        whereArgs: [chatId],
      );
      debugPrint('🗑️ Chat messages cleared: $chatId');
    } catch (e) {
      debugPrint('❌ Error clearing chat messages: $e');
      throw DatabaseException('Failed to clear chat messages', originalError: e);
    }
  }

  /// Get chat media (images, videos, documents)
  Future<List<MessageModel>> getChatMedia({
    required String chatId,
    MessageType? type,
  }) async {
    try {
      final db = await database;
      String whereClause = 'chat_id = ? AND is_deleted = 0 AND type IN (?, ?, ?)';
      List<dynamic> whereArgs = [chatId, 'image', 'video', 'document'];
      
      if (type != null) {
        whereClause = 'chat_id = ? AND is_deleted = 0 AND type = ?';
        whereArgs = [chatId, type.value];
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        _messagesTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );
      
      return maps.map((map) => _mapToMessage(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting chat media: $e');
      throw DatabaseException('Failed to get chat media', originalError: e);
    }
  }

  // ===============================
  // UNREAD COUNT OPERATIONS
  // ===============================

  /// Get unread count for a chat
  Future<int> getUnreadCount(String chatId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _unreadCountsTable,
        where: 'chat_id = ?',
        whereArgs: [chatId],
        limit: 1,
      );
      
      if (maps.isEmpty) return 0;
      return maps.first['count'] as int;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      throw DatabaseException('Failed to get unread count', originalError: e);
    }
  }

  /// Set unread count for a chat
  Future<void> setUnreadCount(String chatId, int count) async {
    try {
      final db = await database;
      await db.insert(
        _unreadCountsTable,
        {'chat_id': chatId, 'count': count},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('💾 Unread count set: $chatId -> $count');
    } catch (e) {
      debugPrint('❌ Error setting unread count: $e');
      throw DatabaseException('Failed to set unread count', originalError: e);
    }
  }

  /// Increment unread count
  Future<void> incrementUnreadCount(String chatId) async {
    try {
      final db = await database;
      final currentCount = await getUnreadCount(chatId);
      await setUnreadCount(chatId, currentCount + 1);
    } catch (e) {
      debugPrint('❌ Error incrementing unread count: $e');
      throw DatabaseException('Failed to increment unread count', originalError: e);
    }
  }

  /// Reset unread count (mark as read)
  Future<void> resetUnreadCount(String chatId) async {
    try {
      await setUnreadCount(chatId, 0);
    } catch (e) {
      debugPrint('❌ Error resetting unread count: $e');
      throw DatabaseException('Failed to reset unread count', originalError: e);
    }
  }

  /// Get total unread count across all chats
  Future<int> getTotalUnreadCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(count) as total FROM $_unreadCountsTable',
      );
      return result.first['total'] as int? ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting total unread count: $e');
      throw DatabaseException('Failed to get total unread count', originalError: e);
    }
  }

  // ===============================
  // CLEANUP OPERATIONS
  // ===============================

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete(_messagesTable);
      await db.delete(_chatsTable);
      await db.delete(_unreadCountsTable);
      debugPrint('🗑️ All data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing all data: $e');
      throw DatabaseException('Failed to clear all data', originalError: e);
    }
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);
      final file = await File(path).stat();
      return file.size;
    } catch (e) {
      debugPrint('❌ Error getting database size: $e');
      return 0;
    }
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('🔒 Database closed');
  }

  // ===============================
  // HELPER METHODS (MAPPING)
  // ===============================

  Map<String, dynamic> _chatToMap(ChatModel chat) {
    return {
      'id': chat.id,
      'type': chat.type.value,
      'participant_ids': chat.participantIds.join(','),
      'participant_names': chat.participantNames.join(','),
      'participant_images': chat.participantImages.join(','),
      'group_name': chat.groupName,
      'group_image': chat.groupImage,
      'group_description': chat.groupDescription,
      'group_admin_id': chat.groupAdminId,
      'group_admin_ids': chat.groupAdminIds.join(','),
      'last_message_id': chat.lastMessageId,
      'last_message': chat.lastMessage,
      'last_message_sender_id': chat.lastMessageSenderId,
      'last_message_sender_name': chat.lastMessageSenderName,
      'last_message_type': chat.lastMessageType,
      'last_message_time': chat.lastMessageTime,
      'is_muted': chat.isMuted ? 1 : 0,
      'is_pinned': chat.isPinned ? 1 : 0,
      'is_archived': chat.isArchived ? 1 : 0,
      'is_blocked': chat.isBlocked ? 1 : 0,
      'created_at': chat.createdAt,
      'updated_at': chat.updatedAt,
    };
  }

  ChatModel _mapToChat(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'],
      type: ChatType.fromString(map['type']),
      participantIds: (map['participant_ids'] as String).split(',').where((s) => s.isNotEmpty).toList(),
      participantNames: (map['participant_names'] as String).split(',').where((s) => s.isNotEmpty).toList(),
      participantImages: (map['participant_images'] as String).split(',').where((s) => s.isNotEmpty).toList(),
      groupName: map['group_name'],
      groupImage: map['group_image'],
      groupDescription: map['group_description'],
      groupAdminId: map['group_admin_id'],
      groupAdminIds: map['group_admin_ids'] != null 
          ? (map['group_admin_ids'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      lastMessageId: map['last_message_id'],
      lastMessage: map['last_message'],
      lastMessageSenderId: map['last_message_sender_id'],
      lastMessageSenderName: map['last_message_sender_name'],
      lastMessageType: map['last_message_type'] ?? 'text',
      lastMessageTime: map['last_message_time'],
      unreadCounts: {}, // Will be populated separately
      isMuted: map['is_muted'] == 1,
      isPinned: map['is_pinned'] == 1,
      isArchived: map['is_archived'] == 1,
      isBlocked: map['is_blocked'] == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  Map<String, dynamic> _messageToMap(MessageModel message) {
    return {
      'id': message.id,
      'chat_id': message.chatId,
      'sender_id': message.senderId,
      'sender_name': message.senderName,
      'sender_image': message.senderImage,
      'content': message.content,
      'type': message.type.value,
      'status': message.status.value,
      'media_url': message.mediaUrl,
      'thumbnail_url': message.thumbnailUrl,
      'file_name': message.fileName,
      'file_size': message.fileSize,
      'duration': message.duration,
      'replied_to_message_id': message.repliedToMessageId,
      'replied_to_content': message.repliedToContent,
      'replied_to_sender_name': message.repliedToSenderName,
      'replied_to_type': message.repliedToType?.value,
      'latitude': message.latitude,
      'longitude': message.longitude,
      'location_name': message.locationName,
      'contact_name': message.contactName,
      'contact_phone': message.contactPhone,
      'reactions': message.reactions.isNotEmpty ? jsonEncode(message.reactions) : null,
      'is_forwarded': message.isForwarded ? 1 : 0,
      'is_starred': message.isStarred ? 1 : 0,
      'is_deleted': message.isDeleted ? 1 : 0,
      'created_at': message.createdAt,
      'updated_at': message.updatedAt,
      'delivered_at': message.deliveredAt,
    };
  }

  MessageModel _mapToMessage(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      chatId: map['chat_id'],
      senderId: map['sender_id'],
      senderName: map['sender_name'],
      senderImage: map['sender_image'],
      content: map['content'],
      type: MessageType.fromString(map['type']),
      status: MessageStatus.fromString(map['status']),
      mediaUrl: map['media_url'],
      thumbnailUrl: map['thumbnail_url'],
      fileName: map['file_name'],
      fileSize: map['file_size'],
      duration: map['duration'],
      repliedToMessageId: map['replied_to_message_id'],
      repliedToContent: map['replied_to_content'],
      repliedToSenderName: map['replied_to_sender_name'],
      repliedToType: map['replied_to_type'] != null 
          ? MessageType.fromString(map['replied_to_type'])
          : null,
      latitude: map['latitude'],
      longitude: map['longitude'],
      locationName: map['location_name'],
      contactName: map['contact_name'],
      contactPhone: map['contact_phone'],
      reactions: map['reactions'] != null 
          ? Map<String, String>.from(jsonDecode(map['reactions']))
          : {},
      isForwarded: map['is_forwarded'] == 1,
      isStarred: map['is_starred'] == 1,
      isDeleted: map['is_deleted'] == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      deliveredAt: map['delivered_at'],
    );
  }
}