// lib/shared/database/chat_database.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';

class ChatDatabase {
  static final ChatDatabase _instance = ChatDatabase._internal();
  factory ChatDatabase() => _instance;
  ChatDatabase._internal();

  static Database? _database;

  // Database tables
  static const String chatsTable = 'chats';
  static const String messagesTable = 'messages';
  static const String reactionsTable = 'reactions';

  // SyncStatus enum conversion
  static const Map<SyncStatus, String> syncStatusToString = {
    SyncStatus.synced: 'synced',
    SyncStatus.pending: 'pending',
    SyncStatus.failed: 'failed',
  };

  static const Map<String, SyncStatus> stringToSyncStatus = {
    'synced': SyncStatus.synced,
    'pending': SyncStatus.pending,
    'failed': SyncStatus.failed,
  };

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'textgb_chat.db');

    return await openDatabase(
      path,
      version: 2, // Incremented version for schema migration
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Chats table
    await db.execute('''
      CREATE TABLE $chatsTable (
        id TEXT PRIMARY KEY,
        contactUID TEXT,
        contactName TEXT,
        contactImage TEXT,
        lastMessage TEXT,
        messageType TEXT,
        timeSent TEXT,
        unreadCount INTEGER,
        isGroup INTEGER,
        groupId TEXT
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE $messagesTable (
        messageId TEXT PRIMARY KEY,
        chatId TEXT,
        senderUID TEXT,
        senderName TEXT,
        senderImage TEXT,
        message TEXT,
        messageType TEXT,
        timeSent TEXT,
        isSent INTEGER,
        isDelivered INTEGER,
        repliedMessage TEXT,
        repliedTo TEXT,
        repliedMessageType TEXT,
        statusContext TEXT,
        isDeletedForEveryone INTEGER DEFAULT 0,
        isEdited INTEGER DEFAULT 0,
        originalMessage TEXT,
        syncStatus TEXT
      )
    ''');

    // Deleted messages mapping table
    await db.execute('''
      CREATE TABLE deleted_messages (
        messageId TEXT,
        userId TEXT,
        PRIMARY KEY (messageId, userId)
      )
    ''');

    // Reactions table
    await db.execute('''
      CREATE TABLE $reactionsTable (
        messageId TEXT,
        userId TEXT,
        emoji TEXT,
        timestamp TEXT,
        PRIMARY KEY (messageId, userId)
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute('ALTER TABLE $messagesTable ADD COLUMN isDeletedForEveryone INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE $messagesTable ADD COLUMN isEdited INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE $messagesTable ADD COLUMN originalMessage TEXT');

      // Create deleted_messages table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS deleted_messages (
          messageId TEXT,
          userId TEXT,
          PRIMARY KEY (messageId, userId)
        )
      ''');

      // Create reactions table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $reactionsTable (
          messageId TEXT,
          userId TEXT,
          emoji TEXT,
          timestamp TEXT,
          PRIMARY KEY (messageId, userId)
        )
      ''');
    }
  }

  // Save a chat to local database
  Future<void> saveChat(ChatModel chat) async {
    final db = await database;
    await db.insert(
      chatsTable,
      chat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all chats from local database
  Future<List<ChatModel>> getChats() async {
    final db = await database;
    final maps = await db.query(chatsTable, orderBy: '${Constants.timeSent} DESC');
    return List.generate(maps.length, (i) => ChatModel.fromMap(maps[i]));
  }

  // Update chat's last message
  Future<void> updateChatLastMessage(
    String chatId,
    String lastMessage,
    MessageEnum messageType,
    String timeSent,
  ) async {
    final db = await database;
    await db.update(
      chatsTable,
      {
        Constants.lastMessage: lastMessage,
        Constants.messageType: messageType.name,
        Constants.timeSent: timeSent,
      },
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  // Reset unread counter for a chat
  Future<void> resetUnreadCounter(String chatId) async {
    final db = await database;
    await db.update(
      chatsTable,
      {'unreadCount': 0},
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  // Save a message to local database
  Future<void> saveMessage(
    String chatId,
    MessageModel message, {
    SyncStatus syncStatus = SyncStatus.synced,
  }) async {
    final db = await database;
    
    // Add chatId to message data for local storage
    final messageData = message.toMap();
    messageData['chatId'] = chatId;
    messageData['syncStatus'] = syncStatusToString[syncStatus];
    
    await db.insert(
      messagesTable,
      messageData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Save reactions separately
    if (message.reactions.isNotEmpty) {
      for (final entry in message.reactions.entries) {
        await db.insert(
          reactionsTable,
          {
            'messageId': message.messageId,
            'userId': entry.key,
            'emoji': entry.value['emoji'],
            'timestamp': entry.value['timestamp'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    
    // Increment unread counter for recipient if it's a new message
    if (syncStatus == SyncStatus.synced && message.senderUID != chatId.split('_').firstWhere((uid) => uid != message.senderUID)) {
      await _incrementUnreadCounter(chatId);
    }
  }

  // Get messages for a chat
  Future<List<MessageModel>> getMessages(String chatId) async {
    final db = await database;
    
    // Get all messages for the chat
    final messageMaps = await db.query(
      messagesTable,
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: '${Constants.timeSent} DESC',
    );
    
    // Create MessageModel instances
    List<MessageModel> messages = [];
    for (final messageMap in messageMaps) {
      // Get all deletedBy entries for this message
      final deletedByEntries = await db.query(
        'deleted_messages',
        where: 'messageId = ?',
        whereArgs: [messageMap['messageId']],
      );
      
      // Create a list of user IDs who deleted this message
      List<String> deletedBy = deletedByEntries.map((entry) => entry['userId'] as String).toList();
      
      // Get all reactions for this message
      final reactionMaps = await db.query(
        reactionsTable,
        where: 'messageId = ?',
        whereArgs: [messageMap['messageId']],
      );
      
      // Create a map of reactions with userId -> {emoji, timestamp}
      Map<String, Map<String, String>> reactions = {};
      for (final reactionMap in reactionMaps) {
        reactions[reactionMap['userId'] as String] = {
          'emoji': reactionMap['emoji'] as String,
          'timestamp': reactionMap['timestamp'] as String,
        };
      }
      
      // Create a copy of the message map with deletedBy and reactions
      final messageWithDeletedBy = Map<String, dynamic>.from(messageMap);
      messageWithDeletedBy[Constants.deletedBy] = deletedBy;
      messageWithDeletedBy['reactions'] = reactions;
      
      // Create MessageModel from the enhanced map
      messages.add(MessageModel.fromMap(messageWithDeletedBy));
    }
    
    return messages;
  }

  // Get all unsynced messages
  Future<List<MessageModel>> getUnsyncedMessages() async {
    final db = await database;
    
    // Get all messages with syncStatus = 'pending'
    final messageMaps = await db.query(
      messagesTable,
      where: 'syncStatus = ?',
      whereArgs: ['pending'],
    );
    
    // Create MessageModel instances
    List<MessageModel> messages = [];
    for (final messageMap in messageMaps) {
      // Add deletedBy and reactions as with getMessages
      final deletedByEntries = await db.query(
        'deleted_messages',
        where: 'messageId = ?',
        whereArgs: [messageMap['messageId']],
      );
      
      List<String> deletedBy = deletedByEntries.map((entry) => entry['userId'] as String).toList();
      
      final reactionMaps = await db.query(
        reactionsTable,
        where: 'messageId = ?',
        whereArgs: [messageMap['messageId']],
      );
      
      Map<String, Map<String, String>> reactions = {};
      for (final reactionMap in reactionMaps) {
        reactions[reactionMap['userId'] as String] = {
          'emoji': reactionMap['emoji'] as String,
          'timestamp': reactionMap['timestamp'] as String,
        };
      }
      
      final messageWithDeletedBy = Map<String, dynamic>.from(messageMap);
      messageWithDeletedBy[Constants.deletedBy] = deletedBy;
      messageWithDeletedBy['reactions'] = reactions;
      
      messages.add(MessageModel.fromMap(messageWithDeletedBy));
    }
    
    return messages;
  }

  // Mark a message as synced
  Future<void> markMessageAsSynced(String messageId) async {
    final db = await database;
    await db.update(
      messagesTable,
      {'syncStatus': syncStatusToString[SyncStatus.synced]},
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // Update message delivery status
  Future<void> updateMessageDeliveryStatus(String messageId, bool isDelivered) async {
    final db = await database;
    await db.update(
      messagesTable,
      {'isDelivered': isDelivered ? 1 : 0},
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }
  
  // Mark a message as deleted for a specific user
  Future<void> markMessageAsDeleted(String messageId, String userId) async {
    final db = await database;
    
    // Add entry to deleted_messages table
    await db.insert(
      'deleted_messages',
      {
        'messageId': messageId,
        'userId': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Mark a message as deleted for everyone
  Future<void> deleteMessageForEveryone(String messageId) async {
    final db = await database;
    
    // Update message to mark as deleted for everyone
    await db.update(
      messagesTable,
      {'isDeletedForEveryone': 1},
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }
  
  // Edit a message
  Future<void> editMessage(String messageId, String newMessage) async {
    final db = await database;
    
    // Get original message first
    final messageResult = await db.query(
      messagesTable,
      columns: ['message'],
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
    
    if (messageResult.isNotEmpty) {
      final originalMessage = messageResult.first['message'] as String;
      
      // Update message
      await db.update(
        messagesTable,
        {
          'message': newMessage,
          'isEdited': 1,
          'originalMessage': originalMessage,
        },
        where: 'messageId = ?',
        whereArgs: [messageId],
      );
      
      // Check if this was the last message in any chat and update if necessary
      final chatResult = await db.query(
        chatsTable,
        columns: ['id', Constants.lastMessage],
        where: '${Constants.lastMessage} = ?',
        whereArgs: [originalMessage],
      );
      
      for (final chatMap in chatResult) {
        await db.update(
          chatsTable,
          {Constants.lastMessage: newMessage},
          where: 'id = ?',
          whereArgs: [chatMap['id']],
        );
      }
    }
  }
  
  // Add reaction to a message
  Future<void> addReaction(String messageId, String userId, String emoji) async {
    final db = await database;
    
    // Add reaction to reactions table
    await db.insert(
      reactionsTable,
      {
        'messageId': messageId,
        'userId': userId,
        'emoji': emoji,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Remove reaction from a message
  Future<void> removeReaction(String messageId, String userId) async {
    final db = await database;
    
    // Delete reaction from reactions table
    await db.delete(
      reactionsTable,
      where: 'messageId = ? AND userId = ?',
      whereArgs: [messageId, userId],
    );
  }
  
  // Helper method to increment unread counter for a chat
  Future<void> _incrementUnreadCounter(String chatId) async {
    final db = await database;
    
    // Get current unread count
    final result = await db.query(
      chatsTable,
      columns: ['unreadCount'],
      where: 'id = ?',
      whereArgs: [chatId],
    );
    
    if (result.isNotEmpty) {
      int currentCount = result.first['unreadCount'] as int? ?? 0;
      
      // Increment and update
      await db.update(
        chatsTable,
        {'unreadCount': currentCount + 1},
        where: 'id = ?',
        whereArgs: [chatId],
      );
    }
  }
  
  // Clear all data (for testing or logout)
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(chatsTable);
    await db.delete(messagesTable);
    await db.delete('deleted_messages');
    await db.delete(reactionsTable);
  }
}