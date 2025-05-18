// lib/shared/database/chat_database.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';

class ChatDatabase {
  static Database? _database;
  static final ChatDatabase _instance = ChatDatabase._internal();

  factory ChatDatabase() => _instance;

  ChatDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, 'textgb_chat.db');
    return await openDatabase(
      path,
      version: 3, // Increment version for schema changes
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Chats table
    await db.execute('''
    CREATE TABLE chats(
      id TEXT PRIMARY KEY,
      contactUID TEXT,
      contactName TEXT,
      contactImage TEXT,
      lastMessage TEXT,
      messageType TEXT,
      timeSent TEXT,
      unreadCount INTEGER,
      isGroup INTEGER,
      groupId TEXT,
      unreadCountByUser TEXT
    )
    ''');

    // Messages table
    await db.execute('''
    CREATE TABLE messages(
      messageId TEXT PRIMARY KEY,
      chatId TEXT,
      senderUID TEXT,
      senderName TEXT,
      senderImage TEXT,
      message TEXT,
      messageType TEXT,
      timeSent TEXT,
      messageStatus TEXT,
      syncStatus TEXT,
      repliedMessage TEXT,
      repliedTo TEXT,
      repliedMessageType TEXT,
      statusContext TEXT,
      deletedBy TEXT,
      isDeletedForEveryone INTEGER,
      isEdited INTEGER,
      originalMessage TEXT,
      editedAt TEXT,
      reactions TEXT
    )
    ''');
    
    // Index for faster chat lookup
    await db.execute(
      'CREATE INDEX idx_messages_chatId ON messages(chatId)'
    );
    
    // Index for faster sync status lookup
    await db.execute(
      'CREATE INDEX idx_messages_syncStatus ON messages(syncStatus)'
    );
    
    // Index for faster message status lookup
    await db.execute(
      'CREATE INDEX idx_messages_messageStatus ON messages(messageStatus)'
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for v2
      await db.execute('ALTER TABLE messages ADD COLUMN messageStatus TEXT');
      await db.execute('ALTER TABLE messages ADD COLUMN syncStatus TEXT');
      await db.execute('ALTER TABLE messages ADD COLUMN editedAt TEXT');
      
      // Create indexes for faster lookup
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_messages_chatId ON messages(chatId)'
      );
      
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_messages_syncStatus ON messages(syncStatus)'
      );
      
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_messages_messageStatus ON messages(messageStatus)'
      );
    }
    
    if (oldVersion < 3) {
      // Add unreadCountByUser for chat table in v3
      await db.execute('ALTER TABLE chats ADD COLUMN unreadCountByUser TEXT');
    }
  }

  // Save a chat to the database
  Future<void> saveChat(ChatModel chat) async {
    final db = await database;
    
    // Prepare the chat map
    final Map<String, dynamic> chatMap = chat.toMap();
    
    // Convert the unreadCountByUser to a JSON string for storage
    if (chatMap['unreadCountByUser'] is Map) {
      chatMap['unreadCountByUser'] = jsonEncode(chatMap['unreadCountByUser']);
    }
    
    // Convert boolean values to integers for SQLite
    chatMap['isGroup'] = chatMap['isGroup'] == true ? 1 : 0;
    
    await db.insert(
      'chats',
      chatMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all chats
  Future<List<ChatModel>> getChats() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      orderBy: 'timeSent DESC',
    );
    
    return List.generate(maps.length, (i) {
      // Convert boolean values from integers for Dart
      maps[i]['isGroup'] = maps[i]['isGroup'] == 1;
      
      // Parse the unreadCountByUser JSON
      if (maps[i]['unreadCountByUser'] is String) {
        try {
          maps[i]['unreadCountByUser'] = jsonDecode(maps[i]['unreadCountByUser']);
        } catch (e) {
          maps[i]['unreadCountByUser'] = {};
        }
      } else {
        maps[i]['unreadCountByUser'] = {};
      }
      
      return ChatModel.fromMap(maps[i]);
    });
  }

  // Get a chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      where: 'id = ?',
      whereArgs: [chatId],
    );

    if (maps.isNotEmpty) {
      // Convert boolean values from integers for Dart
      maps.first['isGroup'] = maps.first['isGroup'] == 1;
      
      // Parse the unreadCountByUser JSON
      if (maps.first['unreadCountByUser'] is String) {
        try {
          maps.first['unreadCountByUser'] = jsonDecode(maps.first['unreadCountByUser']);
        } catch (e) {
          maps.first['unreadCountByUser'] = {};
        }
      } else {
        maps.first['unreadCountByUser'] = {};
      }
      
      return ChatModel.fromMap(maps.first);
    }
    return null;
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
      'chats',
      {
        'lastMessage': lastMessage,
        'messageType': messageType.name,
        'timeSent': timeSent,
      },
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    final db = await database;
    await db.delete(
      'chats',
      where: 'id = ?',
      whereArgs: [chatId],
    );
    // Also delete all messages in the chat
    await db.delete(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
    );
  }

  // Save a message to the database
  Future<void> saveMessage(
    String chatId,
    MessageModel message,
    {SyncStatus syncStatus = SyncStatus.pending}
  ) async {
    final db = await database;
    
    // Prepare the message map with chatId included
    final messageMap = message.toMap();
    messageMap['chatId'] = chatId;
    
    // Override the syncStatus with the provided value
    messageMap['syncStatus'] = syncStatus.name;
    
    // Convert complex objects to JSON strings
    if (messageMap['deletedBy'] is List) {
      messageMap['deletedBy'] = jsonEncode(messageMap['deletedBy']);
    }
    
    if (messageMap['reactions'] is Map) {
      messageMap['reactions'] = jsonEncode(messageMap['reactions']);
    }
    
    // Convert boolean values to integers for SQLite
    messageMap['isDeletedForEveryone'] = messageMap['isDeletedForEveryone'] == true ? 1 : 0;
    messageMap['isEdited'] = messageMap['isEdited'] == true ? 1 : 0;
    
    await db.insert(
      'messages',
      messageMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get messages for a chat
  Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timeSent DESC',
    );
    
    return _convertMessagesToModels(maps);
  }
  
  // Helper method to convert message maps to models
  List<MessageModel> _convertMessagesToModels(List<Map<String, dynamic>> maps) {
    return maps.map((map) {
      // Convert integer values to booleans
      map['isDeletedForEveryone'] = map['isDeletedForEveryone'] == 1;
      map['isEdited'] = map['isEdited'] == 1;
      
      // Parse lists and maps from JSON
      if (map['deletedBy'] is String) {
        try {
          map['deletedBy'] = jsonDecode(map['deletedBy']);
        } catch (e) {
          map['deletedBy'] = [];
        }
      }
      
      if (map['reactions'] is String) {
        try {
          map['reactions'] = jsonDecode(map['reactions']);
        } catch (e) {
          map['reactions'] = {};
        }
      }
      
      return MessageModel.fromMap(map);
    }).toList();
  }

  // Get a message by ID
  Future<MessageModel?> getMessageById(String messageId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'messageId = ?',
      whereArgs: [messageId],
    );

    if (maps.isNotEmpty) {
      return _convertMessagesToModels([maps.first]).first;
    }
    return null;
  }

  // Update message delivery status (old method - kept for backward compatibility)
  Future<void> updateMessageDeliveryStatus(String messageId, bool isDelivered) async {
    final db = await database;
    await db.update(
      'messages',
      {
        'messageStatus': isDelivered ? MessageStatus.delivered.name : MessageStatus.sent.name,
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // Update message status (enhanced version)
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final db = await database;
    await db.update(
      'messages',
      {
        'messageStatus': status.name,
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }
  
  // Update sync status for a message
  Future<void> updateSyncStatus(String messageId, SyncStatus status) async {
    final db = await database;
    
    try {
      await db.update(
        'messages',
        {'syncStatus': status.name},
        where: 'messageId = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      debugPrint('Error updating sync status in local DB: $e');
    }
  }
  
  // Mark a message as synced
  Future<void> markMessageAsSynced(String messageId) async {
    final db = await database;
    
    try {
      await db.update(
        'messages',
        {'syncStatus': SyncStatus.synced.name},
        where: 'messageId = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      debugPrint('Error marking message as synced in local DB: $e');
    }
  }
  
  // Get unsynced messages
  Future<List<MessageModel>> getUnsyncedMessages() async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'messages',
        where: 'syncStatus = ?',
        whereArgs: [SyncStatus.pending.name],
        orderBy: 'timeSent ASC', // Oldest first to maintain order
      );
      
      return _convertMessagesToModels(maps);
    } catch (e) {
      debugPrint('Error getting unsynced messages from local DB: $e');
      return [];
    }
  }

  // Mark a message as deleted for a user
  Future<void> markMessageAsDeleted(String messageId, String userId) async {
    final db = await database;
    
    // Get the current message
    final message = await getMessageById(messageId);
    if (message == null) return;
    
    // Update the deletedBy list
    final deletedBy = List<String>.from(message.deletedBy);
    if (!deletedBy.contains(userId)) {
      deletedBy.add(userId);
    }
    
    await db.update(
      'messages',
      {
        'deletedBy': jsonEncode(deletedBy),
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // Mark a message as deleted for everyone
  Future<void> deleteMessageForEveryone(String messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {
        'isDeletedForEveryone': 1,
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // Edit a message
  Future<void> editMessage(String messageId, String newMessage) async {
    final db = await database;
    
    // Get the current message to preserve original content
    final message = await getMessageById(messageId);
    if (message == null) return;
    
    // Only store original message if this is the first edit
    final originalMessage = message.isEdited ? message.originalMessage : message.message;
    
    await db.update(
      'messages',
      {
        'message': newMessage,
        'isEdited': 1,
        'originalMessage': originalMessage,
        'editedAt': DateTime.now().millisecondsSinceEpoch.toString(),
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // Add a reaction to a message
  Future<void> addReaction(String messageId, String userId, String emoji) async {
    final db = await database;
    
    // Get the current message
    final message = await getMessageById(messageId);
    if (message == null) return;
    
    // Update reactions
    final reactions = Map<String, Map<String, String>>.from(message.reactions);
    reactions[userId] = {
      'emoji': emoji,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    
    await db.update(
      'messages',
      {
        'reactions': jsonEncode(reactions),
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // Remove a reaction from a message
  Future<void> removeReaction(String messageId, String userId) async {
    final db = await database;
    
    // Get the current message
    final message = await getMessageById(messageId);
    if (message == null) return;
    
    // Update reactions
    final reactions = Map<String, Map<String, String>>.from(message.reactions);
    reactions.remove(userId);
    
    await db.update(
      'messages',
      {
        'reactions': jsonEncode(reactions),
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }

  // Reset unread counter for a chat (old method - kept for backward compatibility)
  Future<void> resetUnreadCounter(String chatId) async {
    final db = await database;
    
    // Update the chat
    await db.update(
      'chats',
      {
        'unreadCount': 0,
      },
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }
  
  // Enhanced unread counter method - update for specific user
  Future<void> updateUnreadCounter(
    String chatId, 
    String userId, 
    bool isIncrease, 
    int totalUnread
  ) async {
    final db = await database;
    
    // Get current chat
    final chat = await getChatById(chatId);
    if (chat == null) return;
    
    // Get or create unreadCountByUser map
    Map<String, dynamic> unreadCounts = Map<String, dynamic>.from(chat.unreadCountByUser);
    
    if (isIncrease) {
      // Increment count
      int currentCount = unreadCounts[userId] ?? 0;
      unreadCounts[userId] = currentCount + 1;
    } else {
      // Reset count
      unreadCounts[userId] = 0;
    }
    
    // Update in database
    await db.update(
      'chats',
      {
        'unreadCountByUser': jsonEncode(unreadCounts),
        'unreadCount': totalUnread, // Update total count for backwards compatibility
      },
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }

  // Get chat ID for a specific message
  Future<String?> getChatIdForMessage(String messageId) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> results = await db.query(
        'messages',
        columns: ['chatId'],
        where: 'messageId = ?',
        whereArgs: [messageId],
      );
      
      if (results.isNotEmpty) {
        return results.first['chatId'] as String?;
      }
    } catch (e) {
      debugPrint('Error getting chat ID for message: $e');
    }
    
    return null;
  }
  
  // Get messages with a specific status
  Future<List<MessageModel>> getMessagesByStatus(MessageStatus status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'messageStatus = ?',
      whereArgs: [status.name],
    );
    
    return _convertMessagesToModels(maps);
  }
  
  // Batch update message status
  Future<void> batchUpdateMessageStatus(
    List<String> messageIds, 
    MessageStatus status
  ) async {
    if (messageIds.isEmpty) return;
    
    final db = await database;
    final batch = db.batch();
    
    for (final messageId in messageIds) {
      batch.update(
        'messages',
        {'messageStatus': status.name},
        where: 'messageId = ?',
        whereArgs: [messageId],
      );
    }
    
    await batch.commit();
  }
  
  // Clear all data (for testing or logout)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('chats');
  }
  
  // Get total unread count across all chats
  Future<int> getTotalUnreadCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(unreadCount) as total FROM chats');
    return Sqflite.firstIntValue(result) ?? 0;
  }
  
  // Get total unread count for a specific user across all chats
  Future<int> getTotalUnreadCountForUser(String userId) async {
    final db = await database;
    final chats = await getChats();
    
    int totalUnread = 0;
    for (final chat in chats) {
      totalUnread += chat.getUnreadCountForUser(userId);
    }
    
    return totalUnread;
  }
  
  // Get failed messages to retry
  Future<List<MessageModel>> getFailedMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'messageStatus = ?',
      whereArgs: [MessageStatus.failed.name],
    );
    
    return _convertMessagesToModels(maps);
  }
  
  // Mark message as failed
  Future<void> markMessageAsFailed(String messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {
        'messageStatus': MessageStatus.failed.name,
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }
  
  // Retry all failed messages
  Future<List<MessageModel>> getMessagesToRetry() async {
    return getFailedMessages();
  }
  
  // Get all sent messages that haven't been delivered
  Future<List<MessageModel>> getSentButNotDeliveredMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'messageStatus = ? AND syncStatus = ?',
      whereArgs: [MessageStatus.sent.name, SyncStatus.synced.name],
    );
    
    return _convertMessagesToModels(maps);
  }
  
  // Update multiple messages statuses at once
  Future<void> updateMultipleMessageStatuses(
    Map<String, MessageStatus> messageStatusUpdates
  ) async {
    if (messageStatusUpdates.isEmpty) return;
    
    final db = await database;
    final batch = db.batch();
    
    messageStatusUpdates.forEach((messageId, status) {
      batch.update(
        'messages',
        {'messageStatus': status.name},
        where: 'messageId = ?',
        whereArgs: [messageId],
      );
    });
    
    await batch.commit();
  }
}