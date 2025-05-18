// lib/shared/database/chat_database.dart - Simplified Version

import 'package:sqflite/sqflite.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/shared/database/database_helper.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// Simplified sync status enum
enum SyncStatus {
  synced,
  pending,
  failed
}

class ChatDatabase {
  Database? _database;
  
  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  // Initialize database
  Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'textgb_offline.db');
      
      print("Database: Initializing SQLite database at $path");
      
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      print("Database: Error initializing database: $e");
      rethrow;
    }
  }
  
  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    try {
      // Create minimal tables just for offline message queuing
      
      // Chats table
      await db.execute('''
        CREATE TABLE chats(
          id TEXT PRIMARY KEY,
          contactUID TEXT,
          contactName TEXT,
          contactImage TEXT,
          lastMessage TEXT,
          lastMessageType TEXT,
          lastMessageTime TEXT,
          unreadCount INTEGER,
          isGroup INTEGER,
          groupId TEXT
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
          isSent INTEGER,
          isDelivered INTEGER,
          repliedMessage TEXT,
          repliedTo TEXT,
          repliedMessageType TEXT,
          syncStatus TEXT
        )
      ''');
      
      print("Database: Tables created successfully");
    } catch (e) {
      print("Database: Error creating database tables: $e");
      throw Exception("Failed to create database tables: $e");
    }
  }
  
  // Get all chats
  Future<List<ChatModel>> getChats() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('chats', orderBy: 'lastMessageTime DESC');
      
      return List.generate(maps.length, (i) {
        return ChatModel.fromMap(maps[i]);
      });
    } catch (e) {
      print("Database: Error getting chats: $e");
      return []; // Return empty list on error
    }
  }
  
  // Save a chat
  Future<void> saveChat(ChatModel chat) async {
    try {
      final db = await database;
      
      await db.insert(
        'chats',
        chat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print("Database: Saved chat ${chat.id}");
    } catch (e) {
      print("Database: Error saving chat: $e");
    }
  }
  
  // Get messages for a chat
  Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'messages',
        where: 'chatId = ?',
        whereArgs: [chatId],
        orderBy: 'timeSent DESC',
      );
      
      return List.generate(maps.length, (i) {
        // Add empty deletedBy list and reactions map
        maps[i]['deletedBy'] = [];
        maps[i]['reactions'] = {};
        
        return MessageModel.fromMap(maps[i]);
      });
    } catch (e) {
      print("Database: Error getting messages: $e");
      return []; // Return empty list on error
    }
  }
  
  // Save a message
  Future<void> saveMessage(String chatId, MessageModel message, {SyncStatus syncStatus = SyncStatus.pending}) async {
    try {
      final db = await database;
      
      // Create a simplified map for storage
      Map<String, dynamic> messageMap = {
        'messageId': message.messageId,
        'chatId': chatId,
        'senderUID': message.senderUID,
        'senderName': message.senderName,
        'senderImage': message.senderImage,
        'message': message.message,
        'messageType': message.messageType.name,
        'timeSent': message.timeSent,
        'isSent': message.isSent ? 1 : 0,
        'isDelivered': message.isDelivered ? 1 : 0,
        'repliedMessage': message.repliedMessage,
        'repliedTo': message.repliedTo,
        'repliedMessageType': message.repliedMessageType?.name,
        'syncStatus': syncStatus.name,
      };
      
      await db.insert(
        'messages',
        messageMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print("Database: Saved message ${message.messageId} with status ${syncStatus.name}");
    } catch (e) {
      print("Database: Error saving message: $e");
      rethrow;
    }
  }
  
  // Update chat's last message
  Future<void> updateChatLastMessage(
    String chatId, 
    String lastMessage,
    MessageEnum messageType,
    String timeSent,
  ) async {
    try {
      final db = await database;
      
      await db.update(
        'chats',
        {
          'lastMessage': lastMessage,
          'lastMessageType': messageType.name,
          'lastMessageTime': timeSent,
        },
        where: 'id = ?',
        whereArgs: [chatId],
      );
      
      print("Database: Updated chat last message for $chatId");
    } catch (e) {
      print("Database: Error updating chat last message: $e");
    }
  }
  
  // Reset unread counter
  Future<void> resetUnreadCounter(String chatId) async {
    try {
      final db = await database;
      
      await db.update(
        'chats',
        {'unreadCount': 0},
        where: 'id = ?',
        whereArgs: [chatId],
      );
    } catch (e) {
      print("Database: Error resetting unread counter: $e");
    }
  }
  
  // Mark message as synced
  Future<void> markMessageAsSynced(String messageId) async {
    try {
      final db = await database;
      
      await db.update(
        'messages',
        {'syncStatus': SyncStatus.synced.name},
        where: 'messageId = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      print("Database: Error marking message as synced: $e");
    }
  }
  
  // Get unsynced messages
  Future<List<MessageModel>> getUnsyncedMessages() async {
    try {
      final db = await database;
      
      final List<Map<String, dynamic>> maps = await db.query(
        'messages',
        where: 'syncStatus = ?',
        whereArgs: [SyncStatus.pending.name],
      );
      
      return List.generate(maps.length, (i) {
        // Add empty deletedBy list and reactions map
        maps[i]['deletedBy'] = [];
        maps[i]['reactions'] = {};
        
        return MessageModel.fromMap(maps[i]);
      });
    } catch (e) {
      print("Database: Error getting unsynced messages: $e");
      return []; // Return empty list on error
    }
  }
  
  // Update message delivery status
  Future<void> updateMessageDeliveryStatus(String messageId, bool isDelivered) async {
    try {
      final db = await database;
      
      await db.update(
        'messages',
        {'isDelivered': isDelivered ? 1 : 0},
        where: 'messageId = ?',
        whereArgs: [messageId],
      );
    } catch (e) {
      print("Database: Error updating message delivery status: $e");
    }
  }
  
  // For other operations like reactions, editing, and deleting, 
  // we'll implement them in a later update since they aren't critical
  // for basic offline message queuing
}