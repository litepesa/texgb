// lib/shared/services/group_database_service.dart
// SQLite service for local group storage
// Provides offline support and caching for groups

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';

/// Exception class for database errors
class GroupDatabaseException implements Exception {
  final String message;
  final dynamic originalError;

  const GroupDatabaseException(this.message, {this.originalError});

  @override
  String toString() => 'GroupDatabaseException: $message';
}

/// SQLite service for group database operations
class GroupDatabaseService {
  // Singleton pattern
  static final GroupDatabaseService _instance = GroupDatabaseService._internal();
  factory GroupDatabaseService() => _instance;
  GroupDatabaseService._internal();

  // Database instance
  Database? _database;
  
  // Database configuration
  static const String _databaseName = 'textgb_groups.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _groupsTable = 'groups';
  static const String _membersTable = 'group_members';
  static const String _pendingRequestsTable = 'pending_requests';
  static const String _groupPostsTable = 'group_posts';

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

      debugPrint('📂 Initializing groups database at: $path');

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );
    } catch (e) {
      debugPrint('❌ Groups database initialization failed: $e');
      throw GroupDatabaseException('Failed to initialize database', originalError: e);
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    debugPrint('📊 Creating groups database tables...');

    // Create groups table
    await db.execute('''
      CREATE TABLE $_groupsTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        group_image TEXT NOT NULL,
        cover_image TEXT NOT NULL,
        privacy TEXT NOT NULL,
        max_members INTEGER DEFAULT 1024,
        allow_member_posts INTEGER DEFAULT 1,
        require_approval INTEGER DEFAULT 0,
        creator_id TEXT NOT NULL,
        creator_name TEXT NOT NULL,
        members_count INTEGER DEFAULT 0,
        posts_count INTEGER DEFAULT 0,
        today_posts_count INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        is_featured INTEGER DEFAULT 0,
        is_verified INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_activity_at TEXT
      )
    ''');

    // Create group members table
    await db.execute('''
      CREATE TABLE $_membersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        user_image TEXT NOT NULL,
        role TEXT NOT NULL,
        is_muted INTEGER DEFAULT 0,
        joined_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES $_groupsTable (id) ON DELETE CASCADE,
        UNIQUE(group_id, user_id)
      )
    ''');

    // Create pending requests table
    await db.execute('''
      CREATE TABLE $_pendingRequestsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        requested_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES $_groupsTable (id) ON DELETE CASCADE,
        UNIQUE(group_id, user_id)
      )
    ''');

    // Create group posts table (simplified - references video posts)
    await db.execute('''
      CREATE TABLE $_groupPostsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id TEXT NOT NULL,
        post_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        posted_at TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES $_groupsTable (id) ON DELETE CASCADE,
        UNIQUE(group_id, post_id)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_groups_privacy ON $_groupsTable (privacy)');
    await db.execute('CREATE INDEX idx_groups_featured ON $_groupsTable (is_featured)');
    await db.execute('CREATE INDEX idx_groups_updated_at ON $_groupsTable (updated_at DESC)');
    await db.execute('CREATE INDEX idx_members_group_id ON $_membersTable (group_id)');
    await db.execute('CREATE INDEX idx_members_user_id ON $_membersTable (user_id)');
    await db.execute('CREATE INDEX idx_members_role ON $_membersTable (role)');
    await db.execute('CREATE INDEX idx_pending_group_id ON $_pendingRequestsTable (group_id)');
    await db.execute('CREATE INDEX idx_posts_group_id ON $_groupPostsTable (group_id)');

    debugPrint('✅ Groups database tables created successfully');
  }

  /// Upgrade database (for future versions)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Upgrading groups database from v$oldVersion to v$newVersion');
    // Handle database migrations here in future versions
  }

  /// On database open
  Future<void> _onOpen(Database db) async {
    debugPrint('✅ Groups database opened successfully');
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ===============================
  // GROUP OPERATIONS
  // ===============================

  /// Insert or update a group
  Future<void> upsertGroup(GroupModel group) async {
    try {
      final db = await database;
      
      // Insert/update group
      await db.insert(
        _groupsTable,
        _groupToMap(group),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Update members
      await _updateGroupMembers(group.id, group.members);
      
      debugPrint('💾 Group saved: ${group.id}');
    } catch (e) {
      debugPrint('❌ Error saving group: $e');
      throw GroupDatabaseException('Failed to save group', originalError: e);
    }
  }

  /// Update group members in database
  Future<void> _updateGroupMembers(String groupId, List<GroupMember> members) async {
    final db = await database;
    
    // Delete existing members for this group
    await db.delete(
      _membersTable,
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    
    // Insert new members
    for (final member in members) {
      await db.insert(
        _membersTable,
        {
          'group_id': groupId,
          'user_id': member.userId,
          'user_name': member.userName,
          'user_image': member.userImage,
          'role': member.role.value,
          'is_muted': member.isMuted ? 1 : 0,
          'joined_at': member.joinedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Get all groups
  Future<List<GroupModel>> getAllGroups() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _groupsTable,
        orderBy: 'is_featured DESC, updated_at DESC',
      );
      
      final groups = <GroupModel>[];
      for (final map in maps) {
        final members = await _getGroupMembers(map['id']);
        groups.add(_mapToGroup(map, members));
      }
      
      return groups;
    } catch (e) {
      debugPrint('❌ Error getting groups: $e');
      throw GroupDatabaseException('Failed to get groups', originalError: e);
    }
  }

  /// Get groups where user is a member
  Future<List<GroupModel>> getMyGroups(String userId) async {
    try {
      final db = await database;
      
      // Get group IDs where user is a member
      final memberMaps = await db.query(
        _membersTable,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      final groupIds = memberMaps.map((m) => m['group_id'] as String).toList();
      
      if (groupIds.isEmpty) return [];
      
      // Get groups
      final groups = <GroupModel>[];
      for (final groupId in groupIds) {
        final group = await getGroupById(groupId);
        if (group != null) groups.add(group);
      }
      
      return groups;
    } catch (e) {
      debugPrint('❌ Error getting my groups: $e');
      throw GroupDatabaseException('Failed to get my groups', originalError: e);
    }
  }

  /// Get featured groups
  Future<List<GroupModel>> getFeaturedGroups() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _groupsTable,
        where: 'is_featured = 1',
        orderBy: 'members_count DESC',
      );
      
      final groups = <GroupModel>[];
      for (final map in maps) {
        final members = await _getGroupMembers(map['id']);
        groups.add(_mapToGroup(map, members));
      }
      
      return groups;
    } catch (e) {
      debugPrint('❌ Error getting featured groups: $e');
      throw GroupDatabaseException('Failed to get featured groups', originalError: e);
    }
  }

  /// Get group by ID
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _groupsTable,
        where: 'id = ?',
        whereArgs: [groupId],
        limit: 1,
      );
      
      if (maps.isEmpty) return null;
      
      final members = await _getGroupMembers(groupId);
      return _mapToGroup(maps.first, members);
    } catch (e) {
      debugPrint('❌ Error getting group: $e');
      throw GroupDatabaseException('Failed to get group', originalError: e);
    }
  }

  /// Get group members
  Future<List<GroupMember>> _getGroupMembers(String groupId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _membersTable,
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    
    return maps.map((map) => GroupMember(
      userId: map['user_id'],
      userName: map['user_name'],
      userImage: map['user_image'],
      role: MemberRole.fromString(map['role']),
      joinedAt: map['joined_at'],
      isMuted: map['is_muted'] == 1,
    )).toList();
  }

  /// Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      final db = await database;
      await db.delete(
        _groupsTable,
        where: 'id = ?',
        whereArgs: [groupId],
      );
      debugPrint('🗑️ Group deleted: $groupId');
    } catch (e) {
      debugPrint('❌ Error deleting group: $e');
      throw GroupDatabaseException('Failed to delete group', originalError: e);
    }
  }

  /// Search groups
  Future<List<GroupModel>> searchGroups(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _groupsTable,
        where: 'name LIKE ? OR description LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'members_count DESC',
      );
      
      final groups = <GroupModel>[];
      for (final map in maps) {
        final members = await _getGroupMembers(map['id']);
        groups.add(_mapToGroup(map, members));
      }
      
      return groups;
    } catch (e) {
      debugPrint('❌ Error searching groups: $e');
      throw GroupDatabaseException('Failed to search groups', originalError: e);
    }
  }

  // ===============================
  // MEMBER OPERATIONS
  // ===============================

  /// Get members of a group
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      return await _getGroupMembers(groupId);
    } catch (e) {
      debugPrint('❌ Error getting group members: $e');
      throw GroupDatabaseException('Failed to get group members', originalError: e);
    }
  }

  /// Add member to group
  Future<void> addMember({
    required String groupId,
    required String userId,
    required String userName,
    required String userImage,
    required MemberRole role,
  }) async {
    try {
      final db = await database;
      await db.insert(
        _membersTable,
        {
          'group_id': groupId,
          'user_id': userId,
          'user_name': userName,
          'user_image': userImage,
          'role': role.value,
          'is_muted': 0,
          'joined_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Update members count
      await db.rawUpdate(
        'UPDATE $_groupsTable SET members_count = members_count + 1 WHERE id = ?',
        [groupId],
      );
      
      debugPrint('💾 Member added to group: $groupId');
    } catch (e) {
      debugPrint('❌ Error adding member: $e');
      throw GroupDatabaseException('Failed to add member', originalError: e);
    }
  }

  /// Remove member from group
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final db = await database;
      await db.delete(
        _membersTable,
        where: 'group_id = ? AND user_id = ?',
        whereArgs: [groupId, userId],
      );
      
      // Update members count
      await db.rawUpdate(
        'UPDATE $_groupsTable SET members_count = members_count - 1 WHERE id = ?',
        [groupId],
      );
      
      debugPrint('🗑️ Member removed from group: $groupId');
    } catch (e) {
      debugPrint('❌ Error removing member: $e');
      throw GroupDatabaseException('Failed to remove member', originalError: e);
    }
  }

  /// Update member role
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required MemberRole role,
  }) async {
    try {
      final db = await database;
      await db.update(
        _membersTable,
        {'role': role.value},
        where: 'group_id = ? AND user_id = ?',
        whereArgs: [groupId, userId],
      );
      debugPrint('💾 Member role updated: $groupId');
    } catch (e) {
      debugPrint('❌ Error updating member role: $e');
      throw GroupDatabaseException('Failed to update member role', originalError: e);
    }
  }

  /// Mute/unmute member
  Future<void> setMemberMuted({
    required String groupId,
    required String userId,
    required bool isMuted,
  }) async {
    try {
      final db = await database;
      await db.update(
        _membersTable,
        {'is_muted': isMuted ? 1 : 0},
        where: 'group_id = ? AND user_id = ?',
        whereArgs: [groupId, userId],
      );
      debugPrint('💾 Member mute status updated: $groupId');
    } catch (e) {
      debugPrint('❌ Error updating member mute status: $e');
      throw GroupDatabaseException('Failed to update member mute status', originalError: e);
    }
  }

  /// Check if user is member
  Future<bool> isMember(String groupId, String userId) async {
    try {
      final db = await database;
      final result = await db.query(
        _membersTable,
        where: 'group_id = ? AND user_id = ?',
        whereArgs: [groupId, userId],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking member status: $e');
      return false;
    }
  }

  /// Check if user is admin
  Future<bool> isAdmin(String groupId, String userId) async {
    try {
      final db = await database;
      final result = await db.query(
        _membersTable,
        where: 'group_id = ? AND user_id = ? AND role = ?',
        whereArgs: [groupId, userId, MemberRole.admin.value],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
      return false;
    }
  }

  // ===============================
  // PENDING REQUESTS OPERATIONS
  // ===============================

  /// Add pending request
  Future<void> addPendingRequest(String groupId, String userId) async {
    try {
      final db = await database;
      await db.insert(
        _pendingRequestsTable,
        {
          'group_id': groupId,
          'user_id': userId,
          'requested_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('💾 Pending request added: $groupId');
    } catch (e) {
      debugPrint('❌ Error adding pending request: $e');
      throw GroupDatabaseException('Failed to add pending request', originalError: e);
    }
  }

  /// Remove pending request
  Future<void> removePendingRequest(String groupId, String userId) async {
    try {
      final db = await database;
      await db.delete(
        _pendingRequestsTable,
        where: 'group_id = ? AND user_id = ?',
        whereArgs: [groupId, userId],
      );
      debugPrint('🗑️ Pending request removed: $groupId');
    } catch (e) {
      debugPrint('❌ Error removing pending request: $e');
      throw GroupDatabaseException('Failed to remove pending request', originalError: e);
    }
  }

  /// Get pending requests
  Future<List<String>> getPendingRequests(String groupId) async {
    try {
      final db = await database;
      final maps = await db.query(
        _pendingRequestsTable,
        where: 'group_id = ?',
        whereArgs: [groupId],
      );
      return maps.map((m) => m['user_id'] as String).toList();
    } catch (e) {
      debugPrint('❌ Error getting pending requests: $e');
      throw GroupDatabaseException('Failed to get pending requests', originalError: e);
    }
  }

  /// Check if user has pending request
  Future<bool> hasPendingRequest(String groupId, String userId) async {
    try {
      final db = await database;
      final result = await db.query(
        _pendingRequestsTable,
        where: 'group_id = ? AND user_id = ?',
        whereArgs: [groupId, userId],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Error checking pending request: $e');
      return false;
    }
  }

  // ===============================
  // GROUP POSTS OPERATIONS
  // ===============================

  /// Add group post reference
  Future<void> addGroupPost({
    required String groupId,
    required String postId,
    required String userId,
  }) async {
    try {
      final db = await database;
      await db.insert(
        _groupPostsTable,
        {
          'group_id': groupId,
          'post_id': postId,
          'user_id': userId,
          'posted_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Update posts count
      await db.rawUpdate(
        'UPDATE $_groupsTable SET posts_count = posts_count + 1 WHERE id = ?',
        [groupId],
      );
      
      debugPrint('💾 Group post added: $groupId');
    } catch (e) {
      debugPrint('❌ Error adding group post: $e');
      throw GroupDatabaseException('Failed to add group post', originalError: e);
    }
  }

  /// Remove group post reference
  Future<void> removeGroupPost(String groupId, String postId) async {
    try {
      final db = await database;
      await db.delete(
        _groupPostsTable,
        where: 'group_id = ? AND post_id = ?',
        whereArgs: [groupId, postId],
      );
      
      // Update posts count
      await db.rawUpdate(
        'UPDATE $_groupsTable SET posts_count = posts_count - 1 WHERE id = ? AND posts_count > 0',
        [groupId],
      );
      
      debugPrint('🗑️ Group post removed: $groupId');
    } catch (e) {
      debugPrint('❌ Error removing group post: $e');
      throw GroupDatabaseException('Failed to remove group post', originalError: e);
    }
  }

  /// Get today's post count for user
  Future<int> getTodayPostCount(String groupId, String userId) async {
    try {
      final db = await database;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
      
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_groupPostsTable WHERE group_id = ? AND user_id = ? AND posted_at >= ?',
        [groupId, userId, startOfDay],
      );
      
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting today post count: $e');
      return 0;
    }
  }

  // ===============================
  // CLEANUP OPERATIONS
  // ===============================

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete(_groupPostsTable);
      await db.delete(_pendingRequestsTable);
      await db.delete(_membersTable);
      await db.delete(_groupsTable);
      debugPrint('🗑️ All groups data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing all data: $e');
      throw GroupDatabaseException('Failed to clear all data', originalError: e);
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
    debugPrint('🔒 Groups database closed');
  }

  // ===============================
  // HELPER METHODS (MAPPING)
  // ===============================

  Map<String, dynamic> _groupToMap(GroupModel group) {
    return {
      'id': group.id,
      'name': group.name,
      'description': group.description,
      'group_image': group.groupImage,
      'cover_image': group.coverImage,
      'privacy': group.privacy.value,
      'max_members': group.maxMembers,
      'allow_member_posts': group.allowMemberPosts ? 1 : 0,
      'require_approval': group.requireApproval ? 1 : 0,
      'creator_id': group.creatorId,
      'creator_name': group.creatorName,
      'members_count': group.membersCount,
      'posts_count': group.postsCount,
      'today_posts_count': group.todayPostsCount,
      'is_active': group.isActive ? 1 : 0,
      'is_featured': group.isFeatured ? 1 : 0,
      'is_verified': group.isVerified ? 1 : 0,
      'created_at': group.createdAt,
      'updated_at': group.updatedAt,
      'last_activity_at': group.lastActivityAt,
    };
  }

  GroupModel _mapToGroup(Map<String, dynamic> map, List<GroupMember> members) {
    return GroupModel(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      groupImage: map['group_image'],
      coverImage: map['cover_image'],
      privacy: GroupPrivacy.fromString(map['privacy']),
      maxMembers: map['max_members'],
      allowMemberPosts: map['allow_member_posts'] == 1,
      requireApproval: map['require_approval'] == 1,
      creatorId: map['creator_id'],
      creatorName: map['creator_name'],
      members: members,
      memberIds: members.map((m) => m.userId).toList(),
      adminIds: members.where((m) => m.isAdmin).map((m) => m.userId).toList(),
      moderatorIds: members.where((m) => m.isModerator).map((m) => m.userId).toList(),
      pendingRequestIds: [], // Will be loaded separately if needed
      membersCount: map['members_count'],
      postsCount: map['posts_count'],
      todayPostsCount: map['today_posts_count'],
      isActive: map['is_active'] == 1,
      isFeatured: map['is_featured'] == 1,
      isVerified: map['is_verified'] == 1,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      lastActivityAt: map['last_activity_at'],
    );
  }
}