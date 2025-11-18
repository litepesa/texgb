// lib/features/chat/services/chat_database_service.dart
// Local database service for offline chat and message storage using sqflite

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/enums/enums.dart';

class ChatDatabaseService {
  static final ChatDatabaseService _instance = ChatDatabaseService._internal();
  factory ChatDatabaseService() => _instance;
  ChatDatabaseService._internal();

  Database? _database;
  static const String _databaseName = 'wemachat_local.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _chatsTable = 'chats';
  static const String _messagesTable = 'messages';
  static const String _syncTable = 'sync_metadata';

  // Initialize database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    debugPrint('ChatDB: Initializing database at $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create database schema
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('ChatDB: Creating database schema v$version');

    // Chats table
    await db.execute('''
      CREATE TABLE $_chatsTable (
        chat_id TEXT PRIMARY KEY,
        participant1_id TEXT NOT NULL,
        participant2_id TEXT NOT NULL,
        last_message TEXT,
        last_message_type TEXT,
        last_message_sender TEXT,
        last_message_time INTEGER,
        unread_counts TEXT,
        is_archived TEXT,
        is_pinned TEXT,
        is_muted TEXT,
        chat_wallpapers TEXT,
        font_sizes TEXT,
        original_video_id TEXT,
        original_video_url TEXT,
        original_video_thumbnail TEXT,
        original_video_caption TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        synced_at INTEGER,
        UNIQUE(participant1_id, participant2_id)
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE $_messagesTable (
        message_id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        content TEXT,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        media_url TEXT,
        media_metadata TEXT,
        file_name TEXT,
        reply_to_message_id TEXT,
        reply_to_content TEXT,
        reply_to_sender TEXT,
        reactions TEXT,
        read_by TEXT,
        delivered_to TEXT,
        is_pinned INTEGER DEFAULT 0,
        is_edited INTEGER DEFAULT 0,
        edited_at INTEGER,
        video_reaction_data TEXT,
        is_original_reaction INTEGER DEFAULT 0,
        timestamp INTEGER NOT NULL,
        synced_at INTEGER,
        FOREIGN KEY (chat_id) REFERENCES $_chatsTable (chat_id) ON DELETE CASCADE
      )
    ''');

    // Sync metadata table (tracks last sync time for each chat)
    await db.execute('''
      CREATE TABLE $_syncTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        last_synced INTEGER NOT NULL,
        sync_status TEXT NOT NULL,
        UNIQUE(entity_type, entity_id)
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_chats_last_message_time ON $_chatsTable(last_message_time DESC)');
    await db.execute('CREATE INDEX idx_chats_participants ON $_chatsTable(participant1_id, participant2_id)');
    await db.execute('CREATE INDEX idx_messages_chat_id ON $_messagesTable(chat_id, timestamp DESC)');
    await db.execute('CREATE INDEX idx_messages_sender ON $_messagesTable(sender_id)');
    await db.execute('CREATE INDEX idx_messages_status ON $_messagesTable(status)');
    await db.execute('CREATE INDEX idx_sync_entity ON $_syncTable(entity_type, entity_id)');

    debugPrint('ChatDB: Database schema created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('ChatDB: Upgrading database from v$oldVersion to v$newVersion');
    // Add migration logic here for future schema changes
  }

  // ==================== CHAT OPERATIONS ====================

  /// Insert or update a chat
  Future<void> upsertChat(ChatModel chat) async {
    final db = await database;

    final chatData = {
      'chat_id': chat.chatId,
      'participant1_id': chat.participants[0],
      'participant2_id': chat.participants.length > 1 ? chat.participants[1] : '',
      'last_message': chat.lastMessage,
      'last_message_type': chat.lastMessageType,
      'last_message_sender': chat.lastMessageSender,
      'last_message_time': chat.lastMessageTime.millisecondsSinceEpoch,
      'unread_counts': jsonEncode(chat.unreadCounts),
      'is_archived': jsonEncode(chat.isArchived),
      'is_pinned': jsonEncode(chat.isPinned),
      'is_muted': jsonEncode(chat.isMuted),
      'chat_wallpapers': jsonEncode(chat.chatWallpapers ?? {}),
      'font_sizes': jsonEncode(chat.fontSizes ?? {}),
      'original_video_id': chat.originalVideoId,
      'original_video_url': chat.originalVideoUrl,
      'original_video_thumbnail': chat.originalVideoThumbnail,
      'original_video_caption': chat.originalVideoCaption,
      'created_at': chat.createdAt.millisecondsSinceEpoch,
      'updated_at': chat.updatedAt?.millisecondsSinceEpoch,
      'synced_at': DateTime.now().millisecondsSinceEpoch,
    };

    await db.insert(
      _chatsTable,
      chatData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('ChatDB: Upserted chat ${chat.chatId}');
  }

  /// Insert or update multiple chats (bulk operation)
  Future<void> upsertChats(List<ChatModel> chats) async {
    final db = await database;
    final batch = db.batch();

    for (final chat in chats) {
      final chatData = {
        'chat_id': chat.chatId,
        'participant1_id': chat.participants[0],
        'participant2_id': chat.participants.length > 1 ? chat.participants[1] : '',
        'last_message': chat.lastMessage,
        'last_message_type': chat.lastMessageType,
        'last_message_sender': chat.lastMessageSender,
        'last_message_time': chat.lastMessageTime.millisecondsSinceEpoch,
        'unread_counts': jsonEncode(chat.unreadCounts),
        'is_archived': jsonEncode(chat.isArchived),
        'is_pinned': jsonEncode(chat.isPinned),
        'is_muted': jsonEncode(chat.isMuted),
        'chat_wallpapers': jsonEncode(chat.chatWallpapers ?? {}),
        'font_sizes': jsonEncode(chat.fontSizes ?? {}),
        'original_video_id': chat.originalVideoId,
        'original_video_url': chat.originalVideoUrl,
        'original_video_thumbnail': chat.originalVideoThumbnail,
        'original_video_caption': chat.originalVideoCaption,
        'created_at': chat.createdAt.millisecondsSinceEpoch,
        'updated_at': chat.updatedAt?.millisecondsSinceEpoch,
        'synced_at': DateTime.now().millisecondsSinceEpoch,
      };

      batch.insert(
        _chatsTable,
        chatData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    debugPrint('ChatDB: Upserted ${chats.length} chats');
  }

  /// Get all chats for a user, sorted by last message time
  Future<List<ChatModel>> getChats(String userId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      _chatsTable,
      where: 'participant1_id = ? OR participant2_id = ?',
      whereArgs: [userId, userId],
      orderBy: 'last_message_time DESC',
    );

    return maps.map((map) => _chatFromMap(map)).toList();
  }

  /// Get a specific chat by ID
  Future<ChatModel?> getChat(String chatId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      _chatsTable,
      where: 'chat_id = ?',
      whereArgs: [chatId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _chatFromMap(maps.first);
  }

  /// Delete a chat and all its messages
  Future<void> deleteChat(String chatId) async {
    final db = await database;
    await db.delete(
      _chatsTable,
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
    debugPrint('ChatDB: Deleted chat $chatId');
  }

  // ==================== MESSAGE OPERATIONS ====================

  /// Insert or update a message
  Future<void> upsertMessage(MessageModel message) async {
    final db = await database;

    final messageData = {
      'message_id': message.messageId,
      'chat_id': message.chatId,
      'sender_id': message.senderId,
      'content': message.content,
      'type': message.type.name,
      'status': message.status.name,
      'media_url': message.mediaUrl,
      'media_metadata': message.mediaMetadata != null ? jsonEncode(message.mediaMetadata) : null,
      'file_name': message.fileName,
      'reply_to_message_id': message.replyToMessageId,
      'reply_to_content': message.replyToContent,
      'reply_to_sender': message.replyToSender,
      'reactions': message.reactions != null ? jsonEncode(message.reactions) : null,
      'read_by': message.readBy != null ? jsonEncode(message.readBy!.map((k, v) => MapEntry(k, v.toIso8601String()))) : null,
      'delivered_to': message.deliveredTo != null ? jsonEncode(message.deliveredTo!.map((k, v) => MapEntry(k, v.toIso8601String()))) : null,
      'is_pinned': message.isPinned ? 1 : 0,
      'is_edited': message.isEdited ? 1 : 0,
      'edited_at': message.editedAt?.millisecondsSinceEpoch,
      'video_reaction_data': message.videoReactionData != null ? jsonEncode(message.videoReactionData!) : null,
      'is_original_reaction': message.isOriginalReaction == true ? 1 : 0,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'synced_at': DateTime.now().millisecondsSinceEpoch,
    };

    await db.insert(
      _messagesTable,
      messageData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('ChatDB: Upserted message ${message.messageId}');
  }

  /// Insert or update multiple messages (bulk operation)
  Future<void> upsertMessages(List<MessageModel> messages) async {
    final db = await database;
    final batch = db.batch();

    for (final message in messages) {
      final messageData = {
        'message_id': message.messageId,
        'chat_id': message.chatId,
        'sender_id': message.senderId,
        'content': message.content,
        'type': message.type.name,
        'status': message.status.name,
        'media_url': message.mediaUrl,
        'media_metadata': message.mediaMetadata != null ? jsonEncode(message.mediaMetadata) : null,
        'file_name': message.fileName,
        'reply_to_message_id': message.replyToMessageId,
        'reply_to_content': message.replyToContent,
        'reply_to_sender': message.replyToSender,
        'reactions': message.reactions != null ? jsonEncode(message.reactions) : null,
        'read_by': message.readBy != null ? jsonEncode(message.readBy!.map((k, v) => MapEntry(k, v.toIso8601String()))) : null,
        'delivered_to': message.deliveredTo != null ? jsonEncode(message.deliveredTo!.map((k, v) => MapEntry(k, v.toIso8601String()))) : null,
        'is_pinned': message.isPinned ? 1 : 0,
        'is_edited': message.isEdited ? 1 : 0,
        'edited_at': message.editedAt?.millisecondsSinceEpoch,
        'video_reaction_data': message.videoReactionData != null ? jsonEncode(message.videoReactionData!) : null,
        'is_original_reaction': message.isOriginalReaction == true ? 1 : 0,
        'timestamp': message.timestamp.millisecondsSinceEpoch,
        'synced_at': DateTime.now().millisecondsSinceEpoch,
      };

      batch.insert(
        _messagesTable,
        messageData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    debugPrint('ChatDB: Upserted ${messages.length} messages');
  }

  /// Get messages for a chat, paginated
  Future<List<MessageModel>> getMessages(
    String chatId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  /// Get a specific message by ID
  Future<MessageModel?> getMessage(String messageId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _messageFromMap(maps.first);
  }

  /// Get pinned messages for a chat
  Future<List<MessageModel>> getPinnedMessages(String chatId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'chat_id = ? AND is_pinned = 1',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  /// Update message status
  Future<void> updateMessageStatus(String messageId, String status) async {
    final db = await database;
    await db.update(
      _messagesTable,
      {
        'status': status,
        'synced_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
    debugPrint('ChatDB: Updated message $messageId status to $status');
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete(
      _messagesTable,
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
    debugPrint('ChatDB: Deleted message $messageId');
  }

  /// Delete all messages in a chat (clear chat history)
  Future<void> deleteAllMessagesInChat(String chatId) async {
    final db = await database;
    await db.delete(
      _messagesTable,
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
    debugPrint('ChatDB: Deleted all messages in chat $chatId');
  }

  /// Search messages by content
  Future<List<MessageModel>> searchMessages(String query, {String? chatId}) async {
    final db = await database;

    String whereClause = 'content LIKE ?';
    List<dynamic> whereArgs = ['%$query%'];

    if (chatId != null) {
      whereClause += ' AND chat_id = ?';
      whereArgs.add(chatId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: 100,
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  // ==================== SYNC OPERATIONS ====================

  /// Update sync metadata
  Future<void> updateSyncMetadata(String entityType, String entityId, String status) async {
    final db = await database;
    await db.insert(
      _syncTable,
      {
        'entity_type': entityType,
        'entity_id': entityId,
        'last_synced': DateTime.now().millisecondsSinceEpoch,
        'sync_status': status,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get last sync time for an entity
  Future<DateTime?> getLastSyncTime(String entityType, String entityId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _syncTable,
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(maps.first['last_synced'] as int);
  }

  /// Get unsynced messages (for background sync)
  Future<List<MessageModel>> getUnsyncedMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'synced_at IS NULL OR status = ?',
      whereArgs: ['sending'],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  // ==================== UTILITY METHODS ====================

  /// Clear all data (useful for logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_chatsTable);
    await db.delete(_messagesTable);
    await db.delete(_syncTable);
    debugPrint('ChatDB: Cleared all local data');
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    final chatsCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_chatsTable')) ?? 0;
    final messagesCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_messagesTable')) ?? 0;
    final unsyncedCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_messagesTable WHERE synced_at IS NULL')) ?? 0;

    return {
      'chats': chatsCount,
      'messages': messagesCount,
      'unsynced': unsyncedCount,
    };
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('ChatDB: Database closed');
  }

  // ==================== MAPPER METHODS ====================

  ChatModel _chatFromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chat_id'] as String,
      participants: [
        map['participant1_id'] as String,
        if ((map['participant2_id'] as String).isNotEmpty) map['participant2_id'] as String,
      ],
      lastMessage: (map['last_message'] as String?) ?? '',
      lastMessageType: MessageEnum.values.firstWhere(
        (e) => e.name == map['last_message_type'],
        orElse: () => MessageEnum.text,
      ),
      lastMessageSender: (map['last_message_sender'] as String?) ?? '',
      lastMessageTime: map['last_message_time'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['last_message_time'] as int)
        : DateTime.now(),
      unreadCounts: Map<String, int>.from(jsonDecode(map['unread_counts'] as String)),
      isArchived: Map<String, bool>.from(jsonDecode(map['is_archived'] as String)),
      isPinned: Map<String, bool>.from(jsonDecode(map['is_pinned'] as String)),
      isMuted: Map<String, bool>.from(jsonDecode(map['is_muted'] as String)),
      chatWallpapers: map['chat_wallpapers'] != null ? Map<String, String>.from(jsonDecode(map['chat_wallpapers'] as String)) : null,
      fontSizes: map['font_sizes'] != null ? Map<String, double>.from(jsonDecode(map['font_sizes'] as String)) : null,
      originalVideoId: map['original_video_id'] as String?,
      originalVideoUrl: map['original_video_url'] as String?,
      originalVideoThumbnail: map['original_video_thumbnail'] as String?,
      originalVideoCaption: map['original_video_caption'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int) : null,
    );
  }

  MessageModel _messageFromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['message_id'] as String,
      chatId: map['chat_id'] as String,
      senderId: map['sender_id'] as String,
      content: (map['content'] as String?) ?? '',
      type: MessageEnum.values.firstWhere((e) => e.name == map['type']),
      status: MessageStatus.values.firstWhere((e) => e.name == map['status']),
      mediaUrl: map['media_url'] as String?,
      mediaMetadata: map['media_metadata'] != null ? jsonDecode(map['media_metadata'] as String) : null,
      fileName: map['file_name'] as String?,
      replyToMessageId: map['reply_to_message_id'] as String?,
      replyToContent: map['reply_to_content'] as String?,
      replyToSender: map['reply_to_sender'] as String?,
      reactions: map['reactions'] != null ? Map<String, String>.from(jsonDecode(map['reactions'] as String)) : null,
      readBy: map['read_by'] != null
        ? (jsonDecode(map['read_by'] as String) as Map<String, dynamic>).map((k, v) => MapEntry(k, DateTime.parse(v as String)))
        : null,
      deliveredTo: map['delivered_to'] != null
        ? (jsonDecode(map['delivered_to'] as String) as Map<String, dynamic>).map((k, v) => MapEntry(k, DateTime.parse(v as String)))
        : null,
      isPinned: (map['is_pinned'] as int) == 1,
      isEdited: (map['is_edited'] as int) == 1,
      editedAt: map['edited_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['edited_at'] as int) : null,
      videoReactionData: map['video_reaction_data'] != null
        ? jsonDecode(map['video_reaction_data'] as String) as Map<String, dynamic>
        : null,
      isOriginalReaction: map['is_original_reaction'] != null ? (map['is_original_reaction'] as int) == 1 : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}
