import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'textgb.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }
  
  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        uid TEXT PRIMARY KEY,
        name TEXT,
        phoneNumber TEXT,
        image TEXT,
        token TEXT,
        aboutMe TEXT,
        lastSeen TEXT,
        createdAt TEXT
      )
    ''');

    // Contacts table
    await db.execute('''
      CREATE TABLE contacts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userUid TEXT,
        contactUid TEXT,
        FOREIGN KEY (userUid) REFERENCES users (uid),
        FOREIGN KEY (contactUid) REFERENCES users (uid)
      )
    ''');
    
    // Blocked contacts table
    await db.execute('''
      CREATE TABLE blocked_contacts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userUid TEXT,
        blockedUid TEXT,
        FOREIGN KEY (userUid) REFERENCES users (uid),
        FOREIGN KEY (blockedUid) REFERENCES users (uid)
      )
    ''');
    
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
        statusContext TEXT,
        isDeletedForEveryone INTEGER,
        isEdited INTEGER,
        originalMessage TEXT,
        syncStatus TEXT,
        FOREIGN KEY (chatId) REFERENCES chats (id)
      )
    ''');
    
    // Message deletions table
    await db.execute('''
      CREATE TABLE message_deletions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        messageId TEXT,
        userUid TEXT,
        FOREIGN KEY (messageId) REFERENCES messages (messageId)
      )
    ''');
    
    // Message reactions table
    await db.execute('''
      CREATE TABLE message_reactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        messageId TEXT,
        userUid TEXT,
        emoji TEXT,
        timestamp TEXT,
        syncStatus TEXT,
        FOREIGN KEY (messageId) REFERENCES messages (messageId)
      )
    ''');
    
    // Create indexes for faster querying
    await db.execute('CREATE INDEX idx_messages_chatId ON messages (chatId)');
    await db.execute('CREATE INDEX idx_contacts_userUid ON contacts (userUid)');
    await db.execute('CREATE INDEX idx_message_reactions_messageId ON message_reactions (messageId)');
  }
  
  // Helper method for closing database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}