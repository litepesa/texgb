// lib/shared/database/chat_database.dart
import 'package:sqflite/sqflite.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/database/database_helper.dart';

enum SyncStatus {
  synced,
  pending,
  failed
}

class ChatDatabase {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  // Get all chats for current user
  Future<List<ChatModel>> getChats() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('chats', orderBy: 'lastMessageTime DESC');
    
    return List.generate(maps.length, (i) {
      return ChatModel.fromMap(maps[i]);
    });
  }
  
  // Save a chat
  Future<void> saveChat(ChatModel chat) async {
    final db = await _databaseHelper.database;
    
    await db.insert(
      'chats',
      chat.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Update chat's last message
  Future<void> updateChatLastMessage(
    String chatId, 
    String lastMessage,
    MessageEnum messageType,
    String timeSent,
    {int? incrementUnread = 0}
  ) async {
    final db = await _databaseHelper.database;
    
    Map<String, dynamic> updates = {
      'lastMessage': lastMessage,
      'lastMessageType': messageType.name,
      'lastMessageTime': timeSent,
    };
    
    if (incrementUnread != null && incrementUnread > 0) {
      // Get current unread count
      final result = await db.query(
        'chats', 
        columns: ['unreadCount'],
        where: 'id = ?',
        whereArgs: [chatId],
      );
      
      if (result.isNotEmpty) {
        final currentUnread = result.first['unreadCount'] as int? ?? 0;
        updates['unreadCount'] = currentUnread + incrementUnread;
      } else {
        updates['unreadCount'] = incrementUnread;
      }
    }
    
    await db.update(
      'chats',
      updates,
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }
  
  // Reset unread counter when opening a chat
  Future<void> resetUnreadCounter(String chatId) async {
    final db = await _databaseHelper.database;
    
    await db.update(
      'chats',
      {'unreadCount': 0},
      where: 'id = ?',
      whereArgs: [chatId],
    );
  }
  
  // Get messages for a chat
  Future<List<MessageModel>> getMessages(String chatId) async {
    final db = await _databaseHelper.database;
    
    // First get all messages
    final List<Map<String, dynamic>> messageMaps = await db.query(
      'messages',
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timeSent DESC',
    );
    
    // Process each message
    List<MessageModel> messages = [];
    for (var map in messageMaps) {
      // Get deletions for this message
      final List<Map<String, dynamic>> deletionMaps = await db.query(
        'message_deletions',
        where: 'messageId = ?',
        whereArgs: [map['messageId']],
      );
      
      List<String> deletedBy = deletionMaps.map((m) => m['userUid'] as String).toList();
      
      // Get reactions for this message
      final List<Map<String, dynamic>> reactionMaps = await db.query(
        'message_reactions',
        where: 'messageId = ?',
        whereArgs: [map['messageId']],
      );
      
      Map<String, Map<String, String>> reactions = {};
      for (var reaction in reactionMaps) {
        reactions[reaction['userUid'] as String] = {
          'emoji': reaction['emoji'] as String,
          'timestamp': reaction['timestamp'] as String,
        };
      }
      
      // Add deletedBy and reactions to the message map
      map['deletedBy'] = deletedBy;
      map['reactions'] = reactions;
      
      // Convert to message model
      messages.add(MessageModel.fromMap(map));
    }
    
    return messages;
  }
  
  // Save a message
  Future<void> saveMessage(String chatId, MessageModel message, {SyncStatus syncStatus = SyncStatus.pending}) async {
    final db = await _databaseHelper.database;
    
    // Start a transaction
    await db.transaction((txn) async {
      // Save the message
      Map<String, dynamic> messageMap = message.toMap();
      messageMap['chatId'] = chatId;
      messageMap['syncStatus'] = syncStatus.name;
      
      await txn.insert(
        'messages',
        messageMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Save deletions
      for (String userId in message.deletedBy) {
        await txn.insert(
          'message_deletions',
          {
            'messageId': message.messageId,
            'userUid': userId,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      // Save reactions
      message.reactions.forEach((userId, reactionData) async {
        await txn.insert(
          'message_reactions',
          {
            'messageId': message.messageId,
            'userUid': userId,
            'emoji': reactionData['emoji'],
            'timestamp': reactionData['timestamp'],
            'syncStatus': syncStatus.name,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
    });
  }
  
  // Update message delivery status
  Future<void> updateMessageDeliveryStatus(String messageId, bool isDelivered) async {
    final db = await _databaseHelper.database;
    
    await db.update(
      'messages',
      {'isDelivered': isDelivered ? 1 : 0},
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }
  
  // Mark message as synced
  Future<void> markMessageAsSynced(String messageId) async {
    final db = await _databaseHelper.database;
    
    await db.update(
      'messages',
      {'syncStatus': SyncStatus.synced.name},
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }
  
  // Get unsynced messages
  Future<List<MessageModel>> getUnsyncedMessages() async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'syncStatus = ?',
      whereArgs: [SyncStatus.pending.name],
    );
    
    return List.generate(maps.length, (i) {
      // Process as in getMessages method
      // For simplicity, we're not including reactions/deletions here
      return MessageModel.fromMap(maps[i]);
    });
  }
  
  // Add reaction to message
  Future<void> addReaction(String messageId, String userId, String emoji, {SyncStatus syncStatus = SyncStatus.pending}) async {
    final db = await _databaseHelper.database;
    
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    
    await db.insert(
      'message_reactions',
      {
        'messageId': messageId,
        'userUid': userId,
        'emoji': emoji,
        'timestamp': timestamp,
        'syncStatus': syncStatus.name,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Remove reaction from message
  Future<void> removeReaction(String messageId, String userId) async {
    final db = await _databaseHelper.database;
    
    await db.delete(
      'message_reactions',
      where: 'messageId = ? AND userUid = ?',
      whereArgs: [messageId, userId],
    );
  }
  
  // Mark message as deleted
  Future<void> markMessageAsDeleted(String messageId, String userId) async {
    final db = await _databaseHelper.database;
    
    await db.insert(
      'message_deletions',
      {
        'messageId': messageId,
        'userUid': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Delete message for everyone
  Future<void> deleteMessageForEveryone(String messageId) async {
    final db = await _databaseHelper.database;
    
    await db.update(
      'messages',
      {
        'isDeletedForEveryone': 1,
        'syncStatus': SyncStatus.pending.name,
      },
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
  }
  
  // Edit message
  Future<void> editMessage(String messageId, String newMessage) async {
    final db = await _databaseHelper.database;
    
    // First get the original message
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
    
    if (maps.isNotEmpty) {
      final originalMessage = maps.first['message'] as String;
      
      await db.update(
        'messages',
        {
          'message': newMessage,
          'isEdited': 1,
          'originalMessage': originalMessage,
          'syncStatus': SyncStatus.pending.name,
        },
        where: 'messageId = ?',
        whereArgs: [messageId],
      );
    }
  }
  
  // Save user to local database
  Future<void> saveUser(UserModel user) async {
    final db = await _databaseHelper.database;
    
    await db.transaction((txn) async {
      // Save user
      await txn.insert(
        'users',
        {
          'uid': user.uid,
          'name': user.name,
          'phoneNumber': user.phoneNumber,
          'image': user.image,
          'token': user.token,
          'aboutMe': user.aboutMe,
          'lastSeen': user.lastSeen,
          'createdAt': user.createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Clear existing contacts and add new ones
      await txn.delete(
        'contacts',
        where: 'userUid = ?',
        whereArgs: [user.uid],
      );
      
      for (String contactUid in user.contactsUIDs) {
        await txn.insert(
          'contacts',
          {
            'userUid': user.uid,
            'contactUid': contactUid,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      // Clear existing blocked contacts and add new ones
      await txn.delete(
        'blocked_contacts',
        where: 'userUid = ?',
        whereArgs: [user.uid],
      );
      
      for (String blockedUid in user.blockedUIDs) {
        await txn.insert(
          'blocked_contacts',
          {
            'userUid': user.uid,
            'blockedUid': blockedUid,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
  
  // Get user by ID
  Future<UserModel?> getUser(String uid) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    // Get contacts for user
    final List<Map<String, dynamic>> contactMaps = await db.query(
      'contacts',
      where: 'userUid = ?',
      whereArgs: [uid],
    );
    
    List<String> contactsUIDs = contactMaps.map((m) => m['contactUid'] as String).toList();
    
    // Get blocked contacts for user
    final List<Map<String, dynamic>> blockedMaps = await db.query(
      'blocked_contacts',
      where: 'userUid = ?',
      whereArgs: [uid],
    );
    
    List<String> blockedUIDs = blockedMaps.map((m) => m['blockedUid'] as String).toList();
    
    // Create user model
    return UserModel(
      uid: maps.first['uid'] as String,
      name: maps.first['name'] as String,
      phoneNumber: maps.first['phoneNumber'] as String,
      image: maps.first['image'] as String,
      token: maps.first['token'] as String,
      aboutMe: maps.first['aboutMe'] as String,
      lastSeen: maps.first['lastSeen'] as String,
      createdAt: maps.first['createdAt'] as String,
      contactsUIDs: contactsUIDs,
      blockedUIDs: blockedUIDs,
    );
  }
  
  // Delete all data (used for logout)
  Future<void> clearAllData() async {
    final db = await _databaseHelper.database;
    
    await db.transaction((txn) async {
      await txn.delete('message_reactions');
      await txn.delete('message_deletions');
      await txn.delete('messages');
      await txn.delete('chats');
      await txn.delete('blocked_contacts');
      await txn.delete('contacts');
      await txn.delete('users');
    });
  }
}