// lib/shared/database/database_helper.dart - Simplified

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  
  static Database? _database;
  
  DatabaseHelper._internal();
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'textgb_offline.db');
      print("DatabaseHelper: Initializing database at $path");
      
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      print("DatabaseHelper: Error initializing database: $e");
      rethrow;
    }
  }
  
  Future<void> _onCreate(Database db, int version) async {
    try {
      // Create minimal tables for offline messaging
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chats(
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
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS messages(
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
      
      print("DatabaseHelper: Tables created successfully");
    } catch (e) {
      print("DatabaseHelper: Error creating tables: $e");
      rethrow;
    }
  }
}