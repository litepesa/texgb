// lib/features/chat/database/chat_database_helper.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';

class ChatDatabaseHelper {
  static final ChatDatabaseHelper _instance = ChatDatabaseHelper._internal();
  static Database? _database;

  factory ChatDatabaseHelper() => _instance;

  ChatDatabaseHelper._internal();

  // Database version for migrations
  static const int _databaseVersion = 1;
  static const String _databaseName = 'textgb_chat.db';

  // Table names
  static const String _chatsTable = 'chats';
  static const String _messagesTable = 'messages';
  static const String _participantsTable = 'chat_participants';
  static const String _mediaTable = 'chat_media';
  static const String _reactionsTable = 'message_reactions';
  static const String _typingStatusTable = 'typing_status';

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    debugPrint('Initializing chat database at: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  // Configure database settings
  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating chat database tables...');

    // Create chats table
    await db.execute('''
      CREATE TABLE $_chatsTable (
        chatId TEXT PRIMARY KEY,
        participants TEXT NOT NULL,
        lastMessage TEXT,
        lastMessageType TEXT,
        lastMessageSender TEXT,
        lastMessageTime TEXT NOT NULL,
        unreadCounts TEXT,
        isArchived TEXT,
        isPinned TEXT,
        isMuted TEXT,
        createdAt TEXT NOT NULL,
        chatWallpapers TEXT,
        fontSizes TEXT,
        syncedAt TEXT,
        isDeleted INTEGER DEFAULT 0,
        deletedAt TEXT
      )
    ''');

    // Create messages table
    await db.execute('''
      CREATE TABLE $_messagesTable (
        messageId TEXT PRIMARY KEY,
        chatId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        content TEXT,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        mediaUrl TEXT,
        mediaMetadata TEXT,
        replyToMessageId TEXT,
        replyToContent TEXT,
        replyToSender TEXT,
        reactions TEXT,
        isEdited INTEGER DEFAULT 0,
        editedAt TEXT,
        isPinned INTEGER DEFAULT 0,
        readBy TEXT,
        deliveredTo TEXT,
        syncedAt TEXT,
        isDeleted INTEGER DEFAULT 0,
        deletedAt TEXT,
        FOREIGN KEY (chatId) REFERENCES $_chatsTable (chatId) ON DELETE CASCADE
      )
    ''');

    // Create participants table for quick lookups
    await db.execute('''
      CREATE TABLE $_participantsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chatId TEXT NOT NULL,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        userImage TEXT,
        phoneNumber TEXT,
        isOnline INTEGER DEFAULT 0,
        lastSeen TEXT,
        addedAt TEXT NOT NULL,
        FOREIGN KEY (chatId) REFERENCES $_chatsTable (chatId) ON DELETE CASCADE,
        UNIQUE(chatId, userId)
      )
    ''');

    // Create media table for media management
    await db.execute('''
      CREATE TABLE $_mediaTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        messageId TEXT NOT NULL,
        chatId TEXT NOT NULL,
        mediaUrl TEXT NOT NULL,
        thumbnailUrl TEXT,
        mediaType TEXT NOT NULL,
        fileName TEXT,
        fileSize INTEGER,
        mimeType TEXT,
        localPath TEXT,
        downloadedAt TEXT,
        isDownloaded INTEGER DEFAULT 0,
        FOREIGN KEY (messageId) REFERENCES $_messagesTable (messageId) ON DELETE CASCADE,
        FOREIGN KEY (chatId) REFERENCES $_chatsTable (chatId) ON DELETE CASCADE
      )
    ''');

    // Create reactions table for efficient queries
    await db.execute('''
      CREATE TABLE $_reactionsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        messageId TEXT NOT NULL,
        userId TEXT NOT NULL,
        emoji TEXT NOT NULL,
        reactedAt TEXT NOT NULL,
        FOREIGN KEY (messageId) REFERENCES $_messagesTable (messageId) ON DELETE CASCADE,
        UNIQUE(messageId, userId)
      )
    ''');

    // Create typing status table
    await db.execute('''
      CREATE TABLE $_typingStatusTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chatId TEXT NOT NULL,
        userId TEXT NOT NULL,
        isTyping INTEGER DEFAULT 0,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (chatId) REFERENCES $_chatsTable (chatId) ON DELETE CASCADE,
        UNIQUE(chatId, userId)
      )
    ''');

    // Create indexes for better performance
    await _createIndexes(db);

    debugPrint('Chat database tables created successfully');
  }

  // Create indexes for performance optimization
  Future<void> _createIndexes(Database db) async {
    // Chats table indexes
    await db.execute('CREATE INDEX idx_chats_lastMessageTime ON $_chatsTable(lastMessageTime DESC)');
    await db.execute('CREATE INDEX idx_chats_isDeleted ON $_chatsTable(isDeleted)');

    // Messages table indexes
    await db.execute('CREATE INDEX idx_messages_chatId ON $_messagesTable(chatId)');
    await db.execute('CREATE INDEX idx_messages_timestamp ON $_messagesTable(timestamp DESC)');
    await db.execute('CREATE INDEX idx_messages_senderId ON $_messagesTable(senderId)');
    await db.execute('CREATE INDEX idx_messages_type ON $_messagesTable(type)');
    await db.execute('CREATE INDEX idx_messages_status ON $_messagesTable(status)');
    await db.execute('CREATE INDEX idx_messages_isPinned ON $_messagesTable(isPinned)');
    await db.execute('CREATE INDEX idx_messages_isDeleted ON $_messagesTable(isDeleted)');

    // Participants table indexes
    await db.execute('CREATE INDEX idx_participants_chatId ON $_participantsTable(chatId)');
    await db.execute('CREATE INDEX idx_participants_userId ON $_participantsTable(userId)');

    // Media table indexes
    await db.execute('CREATE INDEX idx_media_chatId ON $_mediaTable(chatId)');
    await db.execute('CREATE INDEX idx_media_messageId ON $_mediaTable(messageId)');
    await db.execute('CREATE INDEX idx_media_mediaType ON $_mediaTable(mediaType)');

    // Reactions table indexes
    await db.execute('CREATE INDEX idx_reactions_messageId ON $_reactionsTable(messageId)');

    // Typing status table indexes
    await db.execute('CREATE INDEX idx_typing_chatId ON $_typingStatusTable(chatId)');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');

    // Handle migrations here when database version changes
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE $_chatsTable ADD COLUMN newColumn TEXT');
    // }
  }

  // ========================================
  // CHAT OPERATIONS
  // ========================================

  // Insert or update chat
  Future<void> insertOrUpdateChat(ChatModel chat) async {
    final db = await database;
    
    final chatMap = {
      'chatId': chat.chatId,
      'participants': jsonEncode(chat.participants),
      'lastMessage': chat.lastMessage,
      'lastMessageType': chat.lastMessageType.name,
      'lastMessageSender': chat.lastMessageSender,
      'lastMessageTime': chat.lastMessageTime.toIso8601String(),
      'unreadCounts': jsonEncode(chat.unreadCounts),
      'isArchived': jsonEncode(chat.isArchived),
      'isPinned': jsonEncode(chat.isPinned),
      'isMuted': jsonEncode(chat.isMuted),
      'createdAt': chat.createdAt.toIso8601String(),
      'chatWallpapers': chat.chatWallpapers != null ? jsonEncode(chat.chatWallpapers) : null,
      'fontSizes': chat.fontSizes != null ? jsonEncode(chat.fontSizes) : null,
      'syncedAt': DateTime.now().toIso8601String(),
      'isDeleted': 0,
    };

    await db.insert(
      _chatsTable,
      chatMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('Chat ${chat.chatId} saved to local database');
  }

  // Get chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _chatsTable,
      where: 'chatId = ? AND isDeleted = 0',
      whereArgs: [chatId],
    );

    if (maps.isEmpty) return null;

    return _chatFromMap(maps.first);
  }

  // Get all chats for a user
  Future<List<ChatModel>> getUserChats(String userId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _chatsTable,
      where: 'isDeleted = 0 AND participants LIKE ?',
      whereArgs: ['%"$userId"%'],
      orderBy: 'lastMessageTime DESC',
    );

    return maps.map((map) => _chatFromMap(map)).toList();
  }

  // Get pinned chats
  Future<List<ChatModel>> getPinnedChats(String userId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _chatsTable,
      where: 'isDeleted = 0 AND participants LIKE ? AND isPinned LIKE ?',
      whereArgs: ['%"$userId"%', '%"$userId":true%'],
      orderBy: 'lastMessageTime DESC',
    );

    return maps.map((map) => _chatFromMap(map)).toList();
  }

  // Get archived chats
  Future<List<ChatModel>> getArchivedChats(String userId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _chatsTable,
      where: 'isDeleted = 0 AND participants LIKE ? AND isArchived LIKE ?',
      whereArgs: ['%"$userId"%', '%"$userId":true%'],
      orderBy: 'lastMessageTime DESC',
    );

    return maps.map((map) => _chatFromMap(map)).toList();
  }

  // Search chats
  Future<List<ChatModel>> searchChats(String userId, String query) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _chatsTable,
      where: 'isDeleted = 0 AND participants LIKE ? AND (lastMessage LIKE ? OR chatId LIKE ?)',
      whereArgs: ['%"$userId"%', '%$query%', '%$query%'],
      orderBy: 'lastMessageTime DESC',
    );

    return maps.map((map) => _chatFromMap(map)).toList();
  }

  // Update chat last message
  Future<void> updateChatLastMessage({
    required String chatId,
    required String lastMessage,
    required MessageEnum lastMessageType,
    required String lastMessageSender,
    required DateTime lastMessageTime,
  }) async {
    final db = await database;
    
    await db.update(
      _chatsTable,
      {
        'lastMessage': lastMessage,
        'lastMessageType': lastMessageType.name,
        'lastMessageSender': lastMessageSender,
        'lastMessageTime': lastMessageTime.toIso8601String(),
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  // Update chat unread count
  Future<void> updateChatUnreadCount(String chatId, String userId, int count) async {
    final db = await database;
    
    final chat = await getChatById(chatId);
    if (chat == null) return;

    final unreadCounts = Map<String, int>.from(chat.unreadCounts);
    unreadCounts[userId] = count;

    await db.update(
      _chatsTable,
      {
        'unreadCounts': jsonEncode(unreadCounts),
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId, String userId) async {
    await updateChatUnreadCount(chatId, userId, 0);
  }

  // Toggle chat pin
  Future<void> toggleChatPin(String chatId, String userId) async {
    final db = await database;
    
    final chat = await getChatById(chatId);
    if (chat == null) return;

    final isPinned = Map<String, bool>.from(chat.isPinned);
    isPinned[userId] = !(isPinned[userId] ?? false);

    await db.update(
      _chatsTable,
      {
        'isPinned': jsonEncode(isPinned),
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  // Toggle chat archive
  Future<void> toggleChatArchive(String chatId, String userId) async {
    final db = await database;
    
    final chat = await getChatById(chatId);
    if (chat == null) return;

    final isArchived = Map<String, bool>.from(chat.isArchived);
    isArchived[userId] = !(isArchived[userId] ?? false);

    await db.update(
      _chatsTable,
      {
        'isArchived': jsonEncode(isArchived),
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  // Toggle chat mute
  Future<void> toggleChatMute(String chatId, String userId) async {
    final db = await database;
    
    final chat = await getChatById(chatId);
    if (chat == null) return;

    final isMuted = Map<String, bool>.from(chat.isMuted);
    isMuted[userId] = !(isMuted[userId] ?? false);

    await db.update(
      _chatsTable,
      {
        'isMuted': jsonEncode(isMuted),
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  // Delete chat (soft delete)
  Future<void> deleteChat(String chatId, String userId) async {
    final db = await database;
    
    await db.update(
      _chatsTable,
      {
        'isDeleted': 1,
        'deletedAt': DateTime.now().toIso8601String(),
      },
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  // Clear chat history (delete all messages)
  Future<void> clearChatHistory(String chatId) async {
    final db = await database;
    
    await db.update(
      _messagesTable,
      {
        'isDeleted': 1,
        'deletedAt': DateTime.now().toIso8601String(),
      },
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  // ========================================
  // MESSAGE OPERATIONS
  // ========================================

  // Insert or update message
  Future<void> insertOrUpdateMessage(MessageModel message) async {
    final db = await database;
    
    final messageMap = {
      'messageId': message.messageId,
      'chatId': message.chatId,
      'senderId': message.senderId,
      'content': message.content,
      'type': message.type.name,
      'status': message.status.name,
      'timestamp': message.timestamp.toIso8601String(),
      'mediaUrl': message.mediaUrl,
      'mediaMetadata': message.mediaMetadata != null ? jsonEncode(message.mediaMetadata) : null,
      'replyToMessageId': message.replyToMessageId,
      'replyToContent': message.replyToContent,
      'replyToSender': message.replyToSender,
      'reactions': message.reactions != null ? jsonEncode(message.reactions) : null,
      'isEdited': message.isEdited ? 1 : 0,
      'editedAt': message.editedAt?.toIso8601String(),
      'isPinned': message.isPinned ? 1 : 0,
      'readBy': message.readBy != null 
          ? jsonEncode(message.readBy!.map((k, v) => MapEntry(k, v.toIso8601String()))) 
          : null,
      'deliveredTo': message.deliveredTo != null 
          ? jsonEncode(message.deliveredTo!.map((k, v) => MapEntry(k, v.toIso8601String()))) 
          : null,
      'syncedAt': DateTime.now().toIso8601String(),
      'isDeleted': 0,
    };

    await db.insert(
      _messagesTable,
      messageMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint('Message ${message.messageId} saved to local database');
  }

  // Get messages for a chat
  Future<List<MessageModel>> getChatMessages(String chatId, {int limit = 100}) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'chatId = ? AND isDeleted = 0',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  // Get message by ID
  Future<MessageModel?> getMessageById(String messageId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'messageId = ? AND isDeleted = 0',
      whereArgs: [messageId],
    );

    if (maps.isEmpty) return null;

    return _messageFromMap(maps.first);
  }

  // Get pinned messages
  Future<List<MessageModel>> getPinnedMessages(String chatId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'chatId = ? AND isPinned = 1 AND isDeleted = 0',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  // Search messages
  Future<List<MessageModel>> searchMessages(String chatId, String query) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'chatId = ? AND content LIKE ? AND isDeleted = 0',
      whereArgs: [chatId, '%$query%'],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  // Update message status
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final db = await database;
    
    await db.update(
      _messagesTable,
      {
        'status': status.name,
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // Edit message
  Future<void> editMessage(String messageId, String newContent) async {
    final db = await database;
    
    await db.update(
      _messagesTable,
      {
        'content': newContent,
        'isEdited': 1,
        'editedAt': DateTime.now().toIso8601String(),
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // Delete message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    
    await db.update(
      _messagesTable,
      {
        'isDeleted': 1,
        'deletedAt': DateTime.now().toIso8601String(),
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // Pin/Unpin message
  Future<void> togglePinMessage(String messageId) async {
    final db = await database;
    
    final message = await getMessageById(messageId);
    if (message == null) return;

    await db.update(
      _messagesTable,
      {
        'isPinned': message.isPinned ? 0 : 1,
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // Get media messages
  Future<List<MessageModel>> getMediaMessages(String chatId, {MessageEnum? mediaType}) async {
    final db = await database;
    
    String whereClause = 'chatId = ? AND isDeleted = 0 AND type IN (?, ?, ?, ?)';
    List<dynamic> whereArgs = [
      chatId,
      MessageEnum.image.name,
      MessageEnum.video.name,
      MessageEnum.audio.name,
      MessageEnum.file.name,
    ];

    if (mediaType != null) {
      whereClause = 'chatId = ? AND type = ? AND isDeleted = 0';
      whereArgs = [chatId, mediaType.name];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  // Get unread messages count
  Future<int> getUnreadMessagesCount(String chatId, String userId) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM $_messagesTable 
      WHERE chatId = ? 
      AND senderId != ? 
      AND isDeleted = 0
      AND (readBy IS NULL OR readBy NOT LIKE ?)
    ''', [chatId, userId, '%"$userId"%']);

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ========================================
  // PARTICIPANT OPERATIONS
  // ========================================

  // Insert or update participant
  Future<void> insertOrUpdateParticipant({
    required String chatId,
    required String userId,
    required String userName,
    String? userImage,
    String? phoneNumber,
    bool isOnline = false,
    String? lastSeen,
  }) async {
    final db = await database;
    
    final participantMap = {
      'chatId': chatId,
      'userId': userId,
      'userName': userName,
      'userImage': userImage,
      'phoneNumber': phoneNumber,
      'isOnline': isOnline ? 1 : 0,
      'lastSeen': lastSeen,
      'addedAt': DateTime.now().toIso8601String(),
    };

    await db.insert(
      _participantsTable,
      participantMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get chat participants
  Future<List<Map<String, dynamic>>> getChatParticipants(String chatId) async {
    final db = await database;
    
    return await db.query(
      _participantsTable,
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  // Update participant online status
  Future<void> updateParticipantOnlineStatus(String userId, bool isOnline) async {
    final db = await database;
    
    await db.update(
      _participantsTable,
      {
        'isOnline': isOnline ? 1 : 0,
        'lastSeen': DateTime.now().toIso8601String(),
      },
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  // Convert database map to ChatModel
  ChatModel _chatFromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'],
      participants: List<String>.from(jsonDecode(map['participants'])),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageType: MessageEnum.values.firstWhere(
        (e) => e.name == map['lastMessageType'],
        orElse: () => MessageEnum.text,
      ),
      lastMessageSender: map['lastMessageSender'] ?? '',
      lastMessageTime: DateTime.parse(map['lastMessageTime']),
      unreadCounts: Map<String, int>.from(jsonDecode(map['unreadCounts'] ?? '{}')),
      isArchived: Map<String, bool>.from(jsonDecode(map['isArchived'] ?? '{}')),
      isPinned: Map<String, bool>.from(jsonDecode(map['isPinned'] ?? '{}')),
      isMuted: Map<String, bool>.from(jsonDecode(map['isMuted'] ?? '{}')),
      createdAt: DateTime.parse(map['createdAt']),
      chatWallpapers: map['chatWallpapers'] != null 
          ? Map<String, String>.from(jsonDecode(map['chatWallpapers'])) 
          : null,
      fontSizes: map['fontSizes'] != null 
          ? Map<String, double>.from(jsonDecode(map['fontSizes']).map((k, v) => MapEntry(k, (v as num).toDouble()))) 
          : null,
    );
  }

  // Convert database map to MessageModel
  MessageModel _messageFromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'],
      chatId: map['chatId'],
      senderId: map['senderId'],
      content: map['content'] ?? '',
      type: MessageEnum.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageEnum.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sending,
      ),
      timestamp: DateTime.parse(map['timestamp']),
      mediaUrl: map['mediaUrl'],
      mediaMetadata: map['mediaMetadata'] != null 
          ? Map<String, dynamic>.from(jsonDecode(map['mediaMetadata'])) 
          : null,
      replyToMessageId: map['replyToMessageId'],
      replyToContent: map['replyToContent'],
      replyToSender: map['replyToSender'],
      reactions: map['reactions'] != null 
          ? Map<String, String>.from(jsonDecode(map['reactions'])) 
          : null,
      isEdited: map['isEdited'] == 1,
      editedAt: map['editedAt'] != null ? DateTime.parse(map['editedAt']) : null,
      isPinned: map['isPinned'] == 1,
      readBy: map['readBy'] != null 
          ? Map<String, DateTime>.from(
              (jsonDecode(map['readBy']) as Map).map((k, v) => 
                MapEntry(k.toString(), DateTime.parse(v)))) 
          : null,
      deliveredTo: map['deliveredTo'] != null 
          ? Map<String, DateTime>.from(
              (jsonDecode(map['deliveredTo']) as Map).map((k, v) => 
                MapEntry(k.toString(), DateTime.parse(v)))) 
          : null,
    );
  }

  // Get database statistics
  Future<Map<String, int>> getDatabaseStatistics() async {
    final db = await database;
    
    final chatsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_chatsTable WHERE isDeleted = 0')
    ) ?? 0;
    
    final messagesCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_messagesTable WHERE isDeleted = 0')
    ) ?? 0;
    
    final mediaCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_mediaTable')
    ) ?? 0;

    return {
      'chatsCount': chatsCount,
      'messagesCount': messagesCount,
      'mediaCount': mediaCount,
    };
  }

  // Clear all data (for logout or reset)
  Future<void> clearAllData() async {
    final db = await database;
    
    await db.delete(_chatsTable);
    await db.delete(_messagesTable);
    await db.delete(_participantsTable);
    await db.delete(_mediaTable);
    await db.delete(_reactionsTable);
    await db.delete(_typingStatusTable);
    
    debugPrint('All chat data cleared from local database');
  }

  // Delete old messages (cleanup)
  Future<int> deleteOldMessages({int daysOld = 365}) async {
    final db = await database;
    
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    final deletedCount = await db.delete(
      _messagesTable,
      where: 'timestamp < ? AND isDeleted = 0',
      whereArgs: [cutoffDate.toIso8601String()],
    );
    
    debugPrint('Deleted $deletedCount old messages from local database');
    return deletedCount;
  }

  // Vacuum database to reclaim space
  Future<void> vacuumDatabase() async {
    final db = await database;
    await db.execute('VACUUM');
    debugPrint('Database vacuumed successfully');
  }

  // Get database size in bytes
  Future<int> getDatabaseSize() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    
    try {
      final file = await File(path).stat();
      return file.size;
    } catch (e) {
      debugPrint('Error getting database size: $e');
      return 0;
    }
  }

  // ========================================
  // MEDIA OPERATIONS
  // ========================================

  // Insert or update media
  Future<void> insertOrUpdateMedia({
    required String messageId,
    required String chatId,
    required String mediaUrl,
    String? thumbnailUrl,
    required String mediaType,
    String? fileName,
    int? fileSize,
    String? mimeType,
    String? localPath,
    bool isDownloaded = false,
  }) async {
    final db = await database;
    
    final mediaMap = {
      'messageId': messageId,
      'chatId': chatId,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'mediaType': mediaType,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'localPath': localPath,
      'downloadedAt': isDownloaded ? DateTime.now().toIso8601String() : null,
      'isDownloaded': isDownloaded ? 1 : 0,
    };

    await db.insert(
      _mediaTable,
      mediaMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get chat media files
  Future<List<Map<String, dynamic>>> getChatMedia(String chatId, {String? mediaType}) async {
    final db = await database;
    
    String whereClause = 'chatId = ?';
    List<dynamic> whereArgs = [chatId];
    
    if (mediaType != null) {
      whereClause += ' AND mediaType = ?';
      whereArgs.add(mediaType);
    }

    return await db.query(
      _mediaTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );
  }

  // Mark media as downloaded
  Future<void> markMediaAsDownloaded(String messageId, String localPath) async {
    final db = await database;
    
    await db.update(
      _mediaTable,
      {
        'localPath': localPath,
        'downloadedAt': DateTime.now().toIso8601String(),
        'isDownloaded': 1,
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // ========================================
  // TYPING STATUS OPERATIONS
  // ========================================

  // Update typing status
  Future<void> updateTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    final db = await database;
    
    final typingMap = {
      'chatId': chatId,
      'userId': userId,
      'isTyping': isTyping ? 1 : 0,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await db.insert(
      _typingStatusTable,
      typingMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get typing users in chat
  Future<List<String>> getTypingUsers(String chatId) async {
    final db = await database;
    
    // Get users who were typing in the last 5 seconds
    final cutoffTime = DateTime.now().subtract(const Duration(seconds: 5));
    
    final List<Map<String, dynamic>> maps = await db.query(
      _typingStatusTable,
      where: 'chatId = ? AND isTyping = 1 AND updatedAt > ?',
      whereArgs: [chatId, cutoffTime.toIso8601String()],
    );

    return maps.map((m) => m['userId'] as String).toList();
  }

  // ========================================
  // BATCH OPERATIONS
  // ========================================

  // Batch insert chats
  Future<void> batchInsertChats(List<ChatModel> chats) async {
    final db = await database;
    
    final batch = db.batch();
    
    for (final chat in chats) {
      final chatMap = {
        'chatId': chat.chatId,
        'participants': jsonEncode(chat.participants),
        'lastMessage': chat.lastMessage,
        'lastMessageType': chat.lastMessageType.name,
        'lastMessageSender': chat.lastMessageSender,
        'lastMessageTime': chat.lastMessageTime.toIso8601String(),
        'unreadCounts': jsonEncode(chat.unreadCounts),
        'isArchived': jsonEncode(chat.isArchived),
        'isPinned': jsonEncode(chat.isPinned),
        'isMuted': jsonEncode(chat.isMuted),
        'createdAt': chat.createdAt.toIso8601String(),
        'chatWallpapers': chat.chatWallpapers != null ? jsonEncode(chat.chatWallpapers) : null,
        'fontSizes': chat.fontSizes != null ? jsonEncode(chat.fontSizes) : null,
        'syncedAt': DateTime.now().toIso8601String(),
        'isDeleted': 0,
      };
      
      batch.insert(_chatsTable, chatMap, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
    debugPrint('Batch inserted ${chats.length} chats');
  }

  // Batch insert messages
  Future<void> batchInsertMessages(List<MessageModel> messages) async {
    final db = await database;
    
    final batch = db.batch();
    
    for (final message in messages) {
      final messageMap = {
        'messageId': message.messageId,
        'chatId': message.chatId,
        'senderId': message.senderId,
        'content': message.content,
        'type': message.type.name,
        'status': message.status.name,
        'timestamp': message.timestamp.toIso8601String(),
        'mediaUrl': message.mediaUrl,
        'mediaMetadata': message.mediaMetadata != null ? jsonEncode(message.mediaMetadata) : null,
        'replyToMessageId': message.replyToMessageId,
        'replyToContent': message.replyToContent,
        'replyToSender': message.replyToSender,
        'reactions': message.reactions != null ? jsonEncode(message.reactions) : null,
        'isEdited': message.isEdited ? 1 : 0,
        'editedAt': message.editedAt?.toIso8601String(),
        'isPinned': message.isPinned ? 1 : 0,
        'readBy': message.readBy != null 
            ? jsonEncode(message.readBy!.map((k, v) => MapEntry(k, v.toIso8601String()))) 
            : null,
        'deliveredTo': message.deliveredTo != null 
            ? jsonEncode(message.deliveredTo!.map((k, v) => MapEntry(k, v.toIso8601String()))) 
            : null,
        'syncedAt': DateTime.now().toIso8601String(),
        'isDeleted': 0,
      };
      
      batch.insert(_messagesTable, messageMap, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
    debugPrint('Batch inserted ${messages.length} messages');
  }

  // ========================================
  // SYNC OPERATIONS
  // ========================================

  // Get unsynchronized chats
  Future<List<ChatModel>> getUnsyncedChats() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _chatsTable,
      where: 'syncedAt IS NULL OR syncedAt < ?',
      whereArgs: [DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String()],
    );

    return maps.map((map) => _chatFromMap(map)).toList();
  }

  // Get unsynchronized messages
  Future<List<MessageModel>> getUnsyncedMessages() async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'syncedAt IS NULL OR (status = ? AND syncedAt < ?)',
      whereArgs: [
        MessageStatus.sending.name,
        DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String()
      ],
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  // Mark chat as synced
  Future<void> markChatAsSynced(String chatId) async {
    final db = await database;
    
    await db.update(
      _chatsTable,
      {'syncedAt': DateTime.now().toIso8601String()},
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  // Mark message as synced
  Future<void> markMessageAsSynced(String messageId) async {
    final db = await database;
    
    await db.update(
      _messagesTable,
      {'syncedAt': DateTime.now().toIso8601String()},
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // ========================================
  // BACKUP & RESTORE
  // ========================================

  // Export database to JSON
  Future<Map<String, dynamic>> exportToJson() async {
    final db = await database;
    
    final chats = await db.query(_chatsTable, where: 'isDeleted = 0');
    final messages = await db.query(_messagesTable, where: 'isDeleted = 0');
    final participants = await db.query(_participantsTable);
    final media = await db.query(_mediaTable);
    
    return {
      'version': _databaseVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'chats': chats,
      'messages': messages,
      'participants': participants,
      'media': media,
    };
  }

  // Import database from JSON
  Future<void> importFromJson(Map<String, dynamic> data) async {
    final db = await database;
    
    final batch = db.batch();
    
    // Import chats
    final chats = data['chats'] as List<dynamic>?;
    if (chats != null) {
      for (final chat in chats) {
        batch.insert(_chatsTable, chat as Map<String, dynamic>, 
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    
    // Import messages
    final messages = data['messages'] as List<dynamic>?;
    if (messages != null) {
      for (final message in messages) {
        batch.insert(_messagesTable, message as Map<String, dynamic>, 
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    
    // Import participants
    final participants = data['participants'] as List<dynamic>?;
    if (participants != null) {
      for (final participant in participants) {
        batch.insert(_participantsTable, participant as Map<String, dynamic>, 
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    
    // Import media
    final media = data['media'] as List<dynamic>?;
    if (media != null) {
      for (final mediaItem in media) {
        batch.insert(_mediaTable, mediaItem as Map<String, dynamic>, 
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    
    await batch.commit(noResult: true);
    debugPrint('Database imported successfully');
  }

  // ========================================
  // ADVANCED QUERIES
  // ========================================

  // Get chat statistics
  Future<Map<String, dynamic>> getChatStatistics(String chatId) async {
    final db = await database;
    
    final totalMessages = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $_messagesTable WHERE chatId = ? AND isDeleted = 0', [chatId])
    ) ?? 0;
    
    final mediaMessages = Sqflite.firstIntValue(
      await db.rawQuery('''
        SELECT COUNT(*) FROM $_messagesTable 
        WHERE chatId = ? AND isDeleted = 0 
        AND type IN (?, ?, ?, ?)
      ''', [chatId, MessageEnum.image.name, MessageEnum.video.name, MessageEnum.audio.name, MessageEnum.file.name])
    ) ?? 0;
    
    final firstMessage = await db.query(
      _messagesTable,
      where: 'chatId = ? AND isDeleted = 0',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
      limit: 1,
    );
    
    final lastMessage = await db.query(
      _messagesTable,
      where: 'chatId = ? AND isDeleted = 0',
      whereArgs: [chatId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    
    return {
      'totalMessages': totalMessages,
      'mediaMessages': mediaMessages,
      'firstMessageDate': firstMessage.isNotEmpty ? firstMessage.first['timestamp'] : null,
      'lastMessageDate': lastMessage.isNotEmpty ? lastMessage.first['timestamp'] : null,
    };
  }

  // Get messages by date range
  Future<List<MessageModel>> getMessagesByDateRange(
    String chatId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'chatId = ? AND timestamp >= ? AND timestamp <= ? AND isDeleted = 0',
      whereArgs: [chatId, startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  // Get messages by sender
  Future<List<MessageModel>> getMessagesBySender(String chatId, String senderId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'chatId = ? AND senderId = ? AND isDeleted = 0',
      whereArgs: [chatId, senderId],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  // Get failed messages
  Future<List<MessageModel>> getFailedMessages(String chatId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'chatId = ? AND status = ? AND isDeleted = 0',
      whereArgs: [chatId, MessageStatus.failed.name],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => _messageFromMap(map)).toList();
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    debugPrint('Chat database closed');
  }

  // Delete database (for testing or complete reset)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    
    await databaseFactory.deleteDatabase(path);
    _database = null;
    
    debugPrint('Chat database deleted');
  }
}