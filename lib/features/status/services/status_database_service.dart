// lib/shared/services/status_database_service.dart
// SQLite service for local status storage
// Provides offline support and caching for statuses

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:textgb/features/status/models/status_model.dart';

/// Exception class for database errors
class StatusDatabaseException implements Exception {
  final String message;
  final dynamic originalError;

  const StatusDatabaseException(this.message, {this.originalError});

  @override
  String toString() => 'StatusDatabaseException: $message';
}

/// SQLite service for status database operations
class StatusDatabaseService {
  // Singleton pattern
  static final StatusDatabaseService _instance = StatusDatabaseService._internal();
  factory StatusDatabaseService() => _instance;
  StatusDatabaseService._internal();

  // Database instance
  Database? _database;

  // Database configuration
  static const String _databaseName = 'textgb_status.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _statusesTable = 'statuses';
  static const String _viewedStatusesTable = 'viewed_statuses';
  static const String _mutedUsersTable = 'muted_users';

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

      debugPrint('📂 Initializing status database at: $path');

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );
    } catch (e) {
      debugPrint('❌ Status database initialization failed: $e');
      throw StatusDatabaseException('Failed to initialize database', originalError: e);
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('📊 Creating status database tables...');

    // Create statuses table
    await db.execute('''
      CREATE TABLE $_statusesTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        user_image TEXT NOT NULL,
        type TEXT NOT NULL,
        media_url TEXT,
        thumbnail_url TEXT,
        caption TEXT,
        text_content TEXT,
        background_color TEXT,
        text_color TEXT,
        duration INTEGER,
        file_size INTEGER,
        privacy TEXT NOT NULL DEFAULT 'everyone',
        selected_contact_ids TEXT,
        views_count INTEGER DEFAULT 0,
        is_muted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL
      )
    ''');

    // Create viewed statuses table (track which statuses current user has viewed)
    await db.execute('''
      CREATE TABLE $_viewedStatusesTable (
        status_id TEXT PRIMARY KEY,
        viewed_at TEXT NOT NULL,
        FOREIGN KEY (status_id) REFERENCES $_statusesTable (id) ON DELETE CASCADE
      )
    ''');

    // Create muted users table (track users whose statuses are muted)
    await db.execute('''
      CREATE TABLE $_mutedUsersTable (
        user_id TEXT PRIMARY KEY,
        muted_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_statuses_user_id ON $_statusesTable (user_id)');
    await db.execute('CREATE INDEX idx_statuses_created_at ON $_statusesTable (created_at DESC)');
    await db.execute('CREATE INDEX idx_statuses_expires_at ON $_statusesTable (expires_at)');
    await db.execute('CREATE INDEX idx_statuses_type ON $_statusesTable (type)');

    debugPrint('✅ Status database tables created successfully');
  }

  /// Upgrade database (for future versions)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrading status database from v$oldVersion to v$newVersion');
    // Handle database migrations here in future versions
  }

  /// On database open
  Future<void> _onOpen(Database db) async {
    debugPrint('✅ Status database opened successfully');
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ===============================
  // STATUS OPERATIONS
  // ===============================

  /// Insert or update a status
  Future<void> upsertStatus(StatusModel status) async {
    try {
      final db = await database;
      await db.insert(
        _statusesTable,
        _statusToMap(status),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('💾 Status saved: ${status.id}');
    } catch (e) {
      debugPrint('❌ Error saving status: $e');
      throw StatusDatabaseException('Failed to save status', originalError: e);
    }
  }

  /// Batch insert statuses (more efficient)
  Future<void> batchInsertStatuses(List<StatusModel> statuses) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (final status in statuses) {
        batch.insert(
          _statusesTable,
          _statusToMap(status),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      debugPrint('💾 Batch inserted ${statuses.length} statuses');
    } catch (e) {
      debugPrint('❌ Error batch inserting statuses: $e');
      throw StatusDatabaseException('Failed to batch insert statuses', originalError: e);
    }
  }

  /// Get all active statuses (not expired)
  Future<List<StatusModel>> getAllStatuses() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final List<Map<String, dynamic>> maps = await db.query(
        _statusesTable,
        where: 'expires_at > ?',
        whereArgs: [now],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToStatus(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting statuses: $e');
      throw StatusDatabaseException('Failed to get statuses', originalError: e);
    }
  }

  /// Get statuses from specific user
  Future<List<StatusModel>> getUserStatuses(String userId) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final List<Map<String, dynamic>> maps = await db.query(
        _statusesTable,
        where: 'user_id = ? AND expires_at > ?',
        whereArgs: [userId, now],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => _mapToStatus(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting user statuses: $e');
      throw StatusDatabaseException('Failed to get user statuses', originalError: e);
    }
  }

  /// Get status by ID
  Future<StatusModel?> getStatusById(String statusId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _statusesTable,
        where: 'id = ?',
        whereArgs: [statusId],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _mapToStatus(maps.first);
    } catch (e) {
      debugPrint('❌ Error getting status: $e');
      throw StatusDatabaseException('Failed to get status', originalError: e);
    }
  }

  /// Delete status
  Future<void> deleteStatus(String statusId) async {
    try {
      final db = await database;
      await db.delete(
        _statusesTable,
        where: 'id = ?',
        whereArgs: [statusId],
      );
      debugPrint('🗑️ Status deleted: $statusId');
    } catch (e) {
      debugPrint('❌ Error deleting status: $e');
      throw StatusDatabaseException('Failed to delete status', originalError: e);
    }
  }

  /// Delete expired statuses (24-hour cleanup)
  Future<int> deleteExpiredStatuses() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final count = await db.delete(
        _statusesTable,
        where: 'expires_at <= ?',
        whereArgs: [now],
      );

      debugPrint('🗑️ Deleted $count expired statuses');
      return count;
    } catch (e) {
      debugPrint('❌ Error deleting expired statuses: $e');
      throw StatusDatabaseException('Failed to delete expired statuses', originalError: e);
    }
  }

  /// Increment view count
  Future<void> incrementViewCount(String statusId) async {
    try {
      final db = await database;
      await db.rawUpdate(
        'UPDATE $_statusesTable SET views_count = views_count + 1 WHERE id = ?',
        [statusId],
      );
      debugPrint('👁️ View count incremented for status: $statusId');
    } catch (e) {
      debugPrint('❌ Error incrementing view count: $e');
      throw StatusDatabaseException('Failed to increment view count', originalError: e);
    }
  }

  /// Get active status count for user
  Future<int> getActiveStatusCount(String userId) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_statusesTable WHERE user_id = ? AND expires_at > ?',
        [userId, now],
      );

      return result.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting active status count: $e');
      throw StatusDatabaseException('Failed to get active status count', originalError: e);
    }
  }

  /// Check if user has active statuses
  Future<bool> hasActiveStatuses(String userId) async {
    try {
      final count = await getActiveStatusCount(userId);
      return count > 0;
    } catch (e) {
      debugPrint('❌ Error checking active statuses: $e');
      return false;
    }
  }

  /// Get users with active statuses
  Future<List<String>> getUsersWithActiveStatuses() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT DISTINCT user_id FROM $_statusesTable WHERE expires_at > ?',
        [now],
      );

      return result.map((row) => row['user_id'] as String).toList();
    } catch (e) {
      debugPrint('❌ Error getting users with active statuses: $e');
      throw StatusDatabaseException('Failed to get users with active statuses', originalError: e);
    }
  }

  // ===============================
  // VIEWED STATUSES OPERATIONS
  // ===============================

  /// Mark status as viewed
  Future<void> markAsViewed(String statusId) async {
    try {
      final db = await database;
      await db.insert(
        _viewedStatusesTable,
        {
          'status_id': statusId,
          'viewed_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('👁️ Status marked as viewed: $statusId');
    } catch (e) {
      debugPrint('❌ Error marking status as viewed: $e');
      throw StatusDatabaseException('Failed to mark status as viewed', originalError: e);
    }
  }

  /// Check if status has been viewed
  Future<bool> hasViewed(String statusId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        _viewedStatusesTable,
        where: 'status_id = ?',
        whereArgs: [statusId],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking viewed status: $e');
      return false;
    }
  }

  /// Get unviewed statuses
  Future<List<StatusModel>> getUnviewedStatuses() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT s.* FROM $_statusesTable s
        LEFT JOIN $_viewedStatusesTable v ON s.id = v.status_id
        WHERE v.status_id IS NULL AND s.expires_at > ?
        ORDER BY s.created_at DESC
      ''', [now]);

      return maps.map((map) => _mapToStatus(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting unviewed statuses: $e');
      throw StatusDatabaseException('Failed to get unviewed statuses', originalError: e);
    }
  }

  // ===============================
  // MUTED USERS OPERATIONS
  // ===============================

  /// Mute user's status updates
  Future<void> muteUser(String userId) async {
    try {
      final db = await database;
      await db.insert(
        _mutedUsersTable,
        {
          'user_id': userId,
          'muted_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('🔇 User muted: $userId');
    } catch (e) {
      debugPrint('❌ Error muting user: $e');
      throw StatusDatabaseException('Failed to mute user', originalError: e);
    }
  }

  /// Unmute user's status updates
  Future<void> unmuteUser(String userId) async {
    try {
      final db = await database;
      await db.delete(
        _mutedUsersTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      debugPrint('🔊 User unmuted: $userId');
    } catch (e) {
      debugPrint('❌ Error unmuting user: $e');
      throw StatusDatabaseException('Failed to unmute user', originalError: e);
    }
  }

  /// Check if user is muted
  Future<bool> isUserMuted(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        _mutedUsersTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking muted user: $e');
      return false;
    }
  }

  /// Get list of muted users
  Future<List<String>> getMutedUsers() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        _mutedUsersTable,
        orderBy: 'muted_at DESC',
      );

      return result.map((row) => row['user_id'] as String).toList();
    } catch (e) {
      debugPrint('❌ Error getting muted users: $e');
      throw StatusDatabaseException('Failed to get muted users', originalError: e);
    }
  }

  /// Get statuses excluding muted users
  Future<List<StatusModel>> getStatusesExcludingMuted() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT s.* FROM $_statusesTable s
        LEFT JOIN $_mutedUsersTable m ON s.user_id = m.user_id
        WHERE m.user_id IS NULL AND s.expires_at > ?
        ORDER BY s.created_at DESC
      ''', [now]);

      return maps.map((map) => _mapToStatus(map)).toList();
    } catch (e) {
      debugPrint('❌ Error getting statuses excluding muted: $e');
      throw StatusDatabaseException('Failed to get statuses excluding muted', originalError: e);
    }
  }

  // ===============================
  // STATISTICS OPERATIONS
  // ===============================

  /// Get total view count for user's statuses
  Future<int> getTotalViewCount(String userId) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT SUM(views_count) as total FROM $_statusesTable WHERE user_id = ?',
        [userId],
      );

      return result.first['total'] as int? ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting total view count: $e');
      throw StatusDatabaseException('Failed to get total view count', originalError: e);
    }
  }

  /// Get most viewed status for user
  Future<StatusModel?> getMostViewedStatus(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _statusesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'views_count DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _mapToStatus(maps.first);
    } catch (e) {
      debugPrint('❌ Error getting most viewed status: $e');
      throw StatusDatabaseException('Failed to get most viewed status', originalError: e);
    }
  }

  // ===============================
  // CLEANUP OPERATIONS
  // ===============================

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete(_statusesTable);
      await db.delete(_viewedStatusesTable);
      await db.delete(_mutedUsersTable);
      debugPrint('🗑️ All status data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing all data: $e');
      throw StatusDatabaseException('Failed to clear all data', originalError: e);
    }
  }

  /// Clear cache for specific user
  Future<void> clearUserCache(String userId) async {
    try {
      final db = await database;
      await db.delete(
        _statusesTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      debugPrint('🗑️ User cache cleared: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing user cache: $e');
      throw StatusDatabaseException('Failed to clear user cache', originalError: e);
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
    debugPrint('🔒 Status database closed');
  }

  // ===============================
  // HELPER METHODS (MAPPING)
  // ===============================

  Map<String, dynamic> _statusToMap(StatusModel status) {
    return {
      'id': status.id,
      'user_id': status.userId,
      'user_name': status.userName,
      'user_image': status.userImage,
      'type': status.type.value,
      'media_url': status.mediaUrl,
      'thumbnail_url': status.thumbnailUrl,
      'caption': status.caption,
      'text_content': status.textContent,
      'background_color': status.backgroundColor,
      'text_color': status.textColor,
      'duration': status.duration,
      'file_size': status.fileSize,
      'privacy': status.privacy.value,
      'selected_contact_ids': status.selectedContactIds.isNotEmpty
          ? status.selectedContactIds.join(',')
          : null,
      'views_count': status.viewsCount,
      'is_muted': status.isMuted ? 1 : 0,
      'created_at': status.createdAt,
      'expires_at': status.expiresAt,
    };
  }

  StatusModel _mapToStatus(Map<String, dynamic> map) {
    return StatusModel(
      id: map['id'],
      userId: map['user_id'],
      userName: map['user_name'],
      userImage: map['user_image'],
      type: StatusType.fromString(map['type']),
      mediaUrl: map['media_url'],
      thumbnailUrl: map['thumbnail_url'],
      caption: map['caption'],
      textContent: map['text_content'],
      backgroundColor: map['background_color'],
      textColor: map['text_color'],
      duration: map['duration'],
      fileSize: map['file_size'],
      privacy: StatusPrivacy.fromString(map['privacy']),
      selectedContactIds: map['selected_contact_ids'] != null
          ? (map['selected_contact_ids'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      viewsCount: map['views_count'] ?? 0,
      isMuted: map['is_muted'] == 1,
      createdAt: map['created_at'],
      expiresAt: map['expires_at'],
    );
  }
}