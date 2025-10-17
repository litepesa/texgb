// lib/features/groups/repositories/group_repository_impl.dart
// Concrete implementation of GroupRepository
// Combines WebSocket (real-time) + SQLite (local storage) + HTTP (REST API)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/repositories/group_repository.dart';
import 'package:textgb/features/groups/services/group_database_service.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/shared/services/websocket_service.dart';
import 'package:textgb/shared/services/http_client.dart';

/// Concrete implementation of GroupRepository
/// Uses WebSocket for real-time, SQLite for offline, and HTTP for REST operations
class GroupRepositoryImpl implements GroupRepository {
  final WebSocketService _wsService;
  final GroupDatabaseService _dbService;
  final HttpClientService _httpClient;

  // Stream controllers for real-time updates
  final _groupUpdateController = StreamController<GroupModel>.broadcast();
  final _allGroupsController = StreamController<List<GroupModel>>.broadcast();

  // Subscriptions
  StreamSubscription<WSMessage>? _wsMessageSubscription;

  GroupRepositoryImpl({
    WebSocketService? wsService,
    GroupDatabaseService? dbService,
    HttpClientService? httpClient,
  })  : _wsService = wsService ?? WebSocketService(),
        _dbService = dbService ?? GroupDatabaseService(),
        _httpClient = httpClient ?? HttpClientService() {
    _initializeWebSocketListeners();
  }

  // ===============================
  // INITIALIZATION
  // ===============================

  void _initializeWebSocketListeners() {
    _wsMessageSubscription = _wsService.messageStream.listen((wsMessage) {
      _handleWebSocketMessage(wsMessage);
    });
  }

  void _handleWebSocketMessage(WSMessage wsMessage) {
    try {
      switch (wsMessage.type) {
        case WSMessageType.participantAdded:
          _handleParticipantAdded(wsMessage.data);
          break;
        case WSMessageType.participantRemoved:
          _handleParticipantRemoved(wsMessage.data);
          break;
        case WSMessageType.participantPromoted:
        case WSMessageType.participantDemoted:
          _handleParticipantRoleChanged(wsMessage.data);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  void _handleParticipantAdded(Map<String, dynamic> data) async {
    try {
      final groupId = data['groupId'] ?? data['group_id'];
      final userId = data['userId'] ?? data['user_id'];
      final userName = data['userName'] ?? data['user_name'];
      final userImage = data['userImage'] ?? data['user_image'];
      
      await _dbService.addMember(
        groupId: groupId,
        userId: userId,
        userName: userName,
        userImage: userImage,
        role: MemberRole.member,
      );
      
      // Refresh group
      final group = await _dbService.getGroupById(groupId);
      if (group != null) {
        _groupUpdateController.add(group);
      }
    } catch (e) {
      debugPrint('Error handling participant added: $e');
    }
  }

  void _handleParticipantRemoved(Map<String, dynamic> data) async {
    try {
      final groupId = data['groupId'] ?? data['group_id'];
      final userId = data['userId'] ?? data['user_id'];
      
      await _dbService.removeMember(groupId: groupId, userId: userId);
      
      // Refresh group
      final group = await _dbService.getGroupById(groupId);
      if (group != null) {
        _groupUpdateController.add(group);
      }
    } catch (e) {
      debugPrint('Error handling participant removed: $e');
    }
  }

  void _handleParticipantRoleChanged(Map<String, dynamic> data) async {
    try {
      final groupId = data['groupId'] ?? data['group_id'];
      final userId = data['userId'] ?? data['user_id'];
      final role = MemberRole.fromString(data['role']);
      
      await _dbService.updateMemberRole(
        groupId: groupId,
        userId: userId,
        role: role,
      );
      
      // Refresh group
      final group = await _dbService.getGroupById(groupId);
      if (group != null) {
        _groupUpdateController.add(group);
      }
    } catch (e) {
      debugPrint('Error handling participant role changed: $e');
    }
  }

  // ===============================
  // CONNECTION MANAGEMENT
  // ===============================

  @override
  Future<void> connect() async {
    try {
      await _wsService.connect();
      debugPrint('✅ Group repository connected');
    } catch (e) {
      debugPrint('❌ Failed to connect group repository: $e');
      throw GroupRepositoryException('Failed to connect', originalError: e);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _wsService.disconnect();
      debugPrint('✅ Group repository disconnected');
    } catch (e) {
      debugPrint('❌ Failed to disconnect group repository: $e');
      throw GroupRepositoryException('Failed to disconnect', originalError: e);
    }
  }

  @override
  bool get isConnected => _wsService.isConnected;

  @override
  Stream<bool> get connectionStateStream =>
      _wsService.connectionStateStream.map((state) => state == WSConnectionState.connected);

  @override
  Future<void> reconnect() async {
    await _wsService.reconnect();
  }

  // ===============================
  // GROUP OPERATIONS
  // ===============================

  @override
  Future<List<GroupModel>> getGroups() async {
    try {
      // Load from local DB first (instant)
      final localGroups = await _dbService.getAllGroups();
      
      // Return local data immediately
      if (localGroups.isNotEmpty) {
        _allGroupsController.add(localGroups);
      }
      
      // Sync with server in background if connected
      if (isConnected) {
        _syncGroupsInBackground();
      }
      
      return localGroups;
    } catch (e) {
      debugPrint('❌ Error getting groups: $e');
      throw GroupRepositoryException('Failed to get groups', originalError: e);
    }
  }

  Future<void> _syncGroupsInBackground() async {
    try {
      final response = await _httpClient.get('/groups');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final groups = (data['groups'] as List)
            .map((g) => GroupModel.fromMap(g, g['id']))
            .toList();
        
        // Update local DB
        for (final group in groups) {
          await _dbService.upsertGroup(group);
        }
        
        // Broadcast updated groups
        _allGroupsController.add(groups);
      }
    } catch (e) {
      debugPrint('Background group sync failed: $e');
    }
  }

  @override
  Future<List<GroupModel>> getMyGroups() async {
    try {
      if (currentUserId == null) return [];
      
      // Load from local DB first
      final localGroups = await _dbService.getMyGroups(currentUserId!);
      
      // Sync with server if connected
      if (isConnected) {
        try {
          final response = await _httpClient.get('/groups/my');
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final groups = (data['groups'] as List)
                .map((g) => GroupModel.fromMap(g, g['id']))
                .toList();
            
            // Update local DB
            for (final group in groups) {
              await _dbService.upsertGroup(group);
            }
            
            return groups;
          }
        } catch (e) {
          debugPrint('Failed to sync my groups: $e');
        }
      }
      
      return localGroups;
    } catch (e) {
      debugPrint('❌ Error getting my groups: $e');
      throw GroupRepositoryException('Failed to get my groups', originalError: e);
    }
  }

  @override
  Future<List<GroupModel>> getFeaturedGroups() async {
    try {
      // Load from local DB first
      final localGroups = await _dbService.getFeaturedGroups();
      
      // Sync with server if connected
      if (isConnected) {
        try {
          final response = await _httpClient.get('/groups/featured');
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final groups = (data['groups'] as List)
                .map((g) => GroupModel.fromMap(g, g['id']))
                .toList();
            
            // Update local DB
            for (final group in groups) {
              await _dbService.upsertGroup(group);
            }
            
            return groups;
          }
        } catch (e) {
          debugPrint('Failed to sync featured groups: $e');
        }
      }
      
      return localGroups;
    } catch (e) {
      debugPrint('❌ Error getting featured groups: $e');
      throw GroupRepositoryException('Failed to get featured groups', originalError: e);
    }
  }

  @override
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      // Check local DB first
      final localGroup = await _dbService.getGroupById(groupId);
      
      if (localGroup != null) {
        return localGroup;
      }
      
      // Fetch from server if not found locally
      if (isConnected) {
        final response = await _httpClient.get('/groups/$groupId');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final group = GroupModel.fromMap(data, data['id']);
          await _dbService.upsertGroup(group);
          return group;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error getting group by ID: $e');
      throw GroupRepositoryException('Failed to get group', originalError: e);
    }
  }

  @override
  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required File? groupImage,
    required File? coverImage,
    required String creatorId,
    required GroupPrivacy privacy,
    int? maxMembers,
    bool? allowMemberPosts,
    bool? requireApproval,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw GroupRepositoryException('User not authenticated');
      
      // Upload images if provided
      String groupImageUrl = '';
      String coverImageUrl = '';
      
      if (groupImage != null) {
        groupImageUrl = await uploadGroupImage(groupImage);
      }
      
      if (coverImage != null) {
        coverImageUrl = await uploadCoverImage(coverImage);
      }
      
      // Create group via API
      final response = await _httpClient.post('/groups', body: {
        'name': name,
        'description': description,
        'groupImage': groupImageUrl,
        'coverImage': coverImageUrl,
        'creatorId': creatorId,
        'privacy': privacy.value,
        'maxMembers': maxMembers ?? 1024,
        'allowMemberPosts': allowMemberPosts ?? true,
        'requireApproval': requireApproval ?? false,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final group = GroupModel.fromMap(data['group'] ?? data, data['id']);
        await _dbService.upsertGroup(group);
        return group;
      }
      
      throw GroupRepositoryException('Failed to create group');
    } catch (e) {
      debugPrint('❌ Error creating group: $e');
      throw GroupRepositoryException('Failed to create group', originalError: e);
    }
  }

  @override
  Future<GroupModel> updateGroup({
    required String groupId,
    String? name,
    String? description,
    File? groupImage,
    File? coverImage,
    GroupPrivacy? privacy,
    int? maxMembers,
    bool? allowMemberPosts,
    bool? requireApproval,
  }) async {
    try {
      // Upload images if provided
      String? groupImageUrl;
      String? coverImageUrl;
      
      if (groupImage != null) {
        groupImageUrl = await uploadGroupImage(groupImage);
      }
      
      if (coverImage != null) {
        coverImageUrl = await uploadCoverImage(coverImage);
      }
      
      // Update group via API
      final response = await _httpClient.put('/groups/$groupId', body: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (groupImageUrl != null) 'groupImage': groupImageUrl,
        if (coverImageUrl != null) 'coverImage': coverImageUrl,
        if (privacy != null) 'privacy': privacy.value,
        if (maxMembers != null) 'maxMembers': maxMembers,
        if (allowMemberPosts != null) 'allowMemberPosts': allowMemberPosts,
        if (requireApproval != null) 'requireApproval': requireApproval,
      });
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final group = GroupModel.fromMap(data['group'] ?? data, data['id']);
        await _dbService.upsertGroup(group);
        return group;
      }
      
      throw GroupRepositoryException('Failed to update group');
    } catch (e) {
      debugPrint('❌ Error updating group: $e');
      throw GroupRepositoryException('Failed to update group', originalError: e);
    }
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    try {
      await _dbService.deleteGroup(groupId);
      
      // Notify server if connected
      if (isConnected) {
        await _httpClient.delete('/groups/$groupId');
      }
    } catch (e) {
      debugPrint('❌ Error deleting group: $e');
      throw GroupRepositoryException('Failed to delete group', originalError: e);
    }
  }

  @override
  Future<List<GroupModel>> searchGroups(String query) async {
    try {
      // Search local DB first
      final localResults = await _dbService.searchGroups(query);
      
      // Search server if connected
      if (isConnected) {
        try {
          final response = await _httpClient.get('/groups/search?q=${Uri.encodeComponent(query)}');
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final groups = (data['groups'] as List)
                .map((g) => GroupModel.fromMap(g, g['id']))
                .toList();
            
            // Update local DB
            for (final group in groups) {
              await _dbService.upsertGroup(group);
            }
            
            return groups;
          }
        } catch (e) {
          debugPrint('Failed to search groups on server: $e');
        }
      }
      
      return localResults;
    } catch (e) {
      debugPrint('❌ Error searching groups: $e');
      throw GroupRepositoryException('Failed to search groups', originalError: e);
    }
  }

  @override
  Stream<GroupModel> watchGroup(String groupId) {
    return _groupUpdateController.stream.where((group) => group.id == groupId);
  }

  @override
  Stream<List<GroupModel>> watchAllGroups() {
    return _allGroupsController.stream;
  }

  // ===============================
  // MEMBER OPERATIONS
  // ===============================

  @override
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      return await _dbService.getGroupMembers(groupId);
    } catch (e) {
      debugPrint('❌ Error getting group members: $e');
      throw GroupRepositoryException('Failed to get group members', originalError: e);
    }
  }

  @override
  Future<void> addMember({
    required String groupId,
    required String userId,
    required String userName,
    required String userImage,
  }) async {
    try {
      final response = await _httpClient.post('/groups/$groupId/members', body: {
        'userId': userId,
        'userName': userName,
        'userImage': userImage,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _dbService.addMember(
          groupId: groupId,
          userId: userId,
          userName: userName,
          userImage: userImage,
          role: MemberRole.member,
        );
      }
    } catch (e) {
      debugPrint('❌ Error adding member: $e');
      throw GroupRepositoryException('Failed to add member', originalError: e);
    }
  }

  @override
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _httpClient.delete('/groups/$groupId/members/$userId');
      await _dbService.removeMember(groupId: groupId, userId: userId);
    } catch (e) {
      debugPrint('❌ Error removing member: $e');
      throw GroupRepositoryException('Failed to remove member', originalError: e);
    }
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    try {
      if (currentUserId == null) return;
      
      await removeMember(groupId: groupId, userId: currentUserId!);
      await _dbService.deleteGroup(groupId);
    } catch (e) {
      debugPrint('❌ Error leaving group: $e');
      throw GroupRepositoryException('Failed to leave group', originalError: e);
    }
  }

  @override
  Future<void> promoteToAdmin({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.put('/groups/$groupId/members/$userId/role', body: {
        'role': 'admin',
      });
      
      if (response.statusCode == 200) {
        await _dbService.updateMemberRole(
          groupId: groupId,
          userId: userId,
          role: MemberRole.admin,
        );
      }
    } catch (e) {
      debugPrint('❌ Error promoting to admin: $e');
      throw GroupRepositoryException('Failed to promote to admin', originalError: e);
    }
  }

  @override
  Future<void> demoteAdmin({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.put('/groups/$groupId/members/$userId/role', body: {
        'role': 'member',
      });
      
      if (response.statusCode == 200) {
        await _dbService.updateMemberRole(
          groupId: groupId,
          userId: userId,
          role: MemberRole.member,
        );
      }
    } catch (e) {
      debugPrint('❌ Error demoting admin: $e');
      throw GroupRepositoryException('Failed to demote admin', originalError: e);
    }
  }

  @override
  Future<void> promoteToModerator({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.put('/groups/$groupId/members/$userId/role', body: {
        'role': 'moderator',
      });
      
      if (response.statusCode == 200) {
        await _dbService.updateMemberRole(
          groupId: groupId,
          userId: userId,
          role: MemberRole.moderator,
        );
      }
    } catch (e) {
      debugPrint('❌ Error promoting to moderator: $e');
      throw GroupRepositoryException('Failed to promote to moderator', originalError: e);
    }
  }

  @override
  Future<void> demoteModerator({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.put('/groups/$groupId/members/$userId/role', body: {
        'role': 'member',
      });
      
      if (response.statusCode == 200) {
        await _dbService.updateMemberRole(
          groupId: groupId,
          userId: userId,
          role: MemberRole.member,
        );
      }
    } catch (e) {
      debugPrint('❌ Error demoting moderator: $e');
      throw GroupRepositoryException('Failed to demote moderator', originalError: e);
    }
  }

  @override
  Future<void> muteMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.put('/groups/$groupId/members/$userId/mute', body: {
        'isMuted': true,
      });
      
      if (response.statusCode == 200) {
        await _dbService.setMemberMuted(
          groupId: groupId,
          userId: userId,
          isMuted: true,
        );
      }
    } catch (e) {
      debugPrint('❌ Error muting member: $e');
      throw GroupRepositoryException('Failed to mute member', originalError: e);
    }
  }

  @override
  Future<void> unmuteMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.put('/groups/$groupId/members/$userId/mute', body: {
        'isMuted': false,
      });
      
      if (response.statusCode == 200) {
        await _dbService.setMemberMuted(
          groupId: groupId,
          userId: userId,
          isMuted: false,
        );
      }
    } catch (e) {
      debugPrint('❌ Error unmuting member: $e');
      throw GroupRepositoryException('Failed to unmute member', originalError: e);
    }
  }

  @override
  Future<bool> isMember(String groupId) async {
    try {
      if (currentUserId == null) return false;
      return await _dbService.isMember(groupId, currentUserId!);
    } catch (e) {
      debugPrint('❌ Error checking member status: $e');
      return false;
    }
  }

  @override
  Future<bool> isAdmin(String groupId) async {
    try {
      if (currentUserId == null) return false;
      return await _dbService.isAdmin(groupId, currentUserId!);
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
      return false;
    }
  }

  @override
  Future<bool> isModerator(String groupId) async {
    try {
      if (currentUserId == null) return false;
      final members = await _dbService.getGroupMembers(groupId);
      final member = members.firstWhere(
        (m) => m.userId == currentUserId,
        orElse: () => GroupMember(
          userId: '',
          userName: '',
          userImage: '',
          role: MemberRole.member,
          joinedAt: '',
        ),
      );
      return member.isModerator;
    } catch (e) {
      debugPrint('❌ Error checking moderator status: $e');
      return false;
    }
  }

  // ===============================
  // JOIN REQUEST OPERATIONS
  // ===============================

  @override
  Future<void> sendJoinRequest(String groupId) async {
    try {
      if (currentUserId == null) return;
      
      final response = await _httpClient.post('/groups/$groupId/requests', body: {
        'userId': currentUserId,
      });
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        await _dbService.addPendingRequest(groupId, currentUserId!);
      }
    } catch (e) {
      debugPrint('❌ Error sending join request: $e');
      throw GroupRepositoryException('Failed to send join request', originalError: e);
    }
  }

  @override
  Future<void> cancelJoinRequest(String groupId) async {
    try {
      if (currentUserId == null) return;
      
      await _httpClient.delete('/groups/$groupId/requests/$currentUserId');
      await _dbService.removePendingRequest(groupId, currentUserId!);
    } catch (e) {
      debugPrint('❌ Error canceling join request: $e');
      throw GroupRepositoryException('Failed to cancel join request', originalError: e);
    }
  }

  @override
  Future<List<String>> getPendingRequests(String groupId) async {
    try {
      return await _dbService.getPendingRequests(groupId);
    } catch (e) {
      debugPrint('❌ Error getting pending requests: $e');
      throw GroupRepositoryException('Failed to get pending requests', originalError: e);
    }
  }

  @override
  Future<void> approveJoinRequest({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.put('/groups/$groupId/requests/$userId', body: {
        'action': 'approve',
      });
      
      if (response.statusCode == 200) {
        await _dbService.removePendingRequest(groupId, userId);
        // Member will be added via WebSocket event
      }
    } catch (e) {
      debugPrint('❌ Error approving join request: $e');
      throw GroupRepositoryException('Failed to approve join request', originalError: e);
    }
  }

  @override
  Future<void> rejectJoinRequest({
    required String groupId,
    required String userId,
  }) async {
    try {
      final response = await _httpClient.put('/groups/$groupId/requests/$userId', body: {
        'action': 'reject',
      });
      
      if (response.statusCode == 200) {
        await _dbService.removePendingRequest(groupId, userId);
      }
    } catch (e) {
      debugPrint('❌ Error rejecting join request: $e');
      throw GroupRepositoryException('Failed to reject join request', originalError: e);
    }
  }

  @override
  Future<bool> hasPendingRequest(String groupId) async {
    try {
      if (currentUserId == null) return false;
      return await _dbService.hasPendingRequest(groupId, currentUserId!);
    } catch (e) {
      debugPrint('❌ Error checking pending request: $e');
      return false;
    }
  }

  // ===============================
  // GROUP POST OPERATIONS
  // ===============================

  @override
  Future<List<VideoModel>> getGroupPosts({
    required String groupId,
    int limit = 20,
    String? before,
  }) async {
    try {
      String endpoint = '/groups/$groupId/posts?limit=$limit';
      if (before != null) {
        endpoint += '&before=$before';
      }
      
      final response = await _httpClient.get(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final posts = (data['posts'] as List)
            .map((p) => VideoModel.fromJson(p))
            .toList();
        return posts;
      }
      
      return [];
    } catch (e) {
      debugPrint('❌ Error getting group posts: $e');
      throw GroupRepositoryException('Failed to get group posts', originalError: e);
    }
  }

  @override
  Future<VideoModel> createGroupPost({
    required String groupId,
    required File? videoFile,
    required List<File>? imageFiles,
    required String caption,
    List<String>? tags,
  }) async {
    try {
      // This would integrate with existing video upload logic
      // For now, throw unimplemented
      throw UnimplementedError('Create group post not fully implemented yet');
    } catch (e) {
      debugPrint('❌ Error creating group post: $e');
      throw GroupRepositoryException('Failed to create group post', originalError: e);
    }
  }

  @override
  Future<void> deleteGroupPost({
    required String groupId,
    required String postId,
  }) async {
    try {
      await _httpClient.delete('/groups/$groupId/posts/$postId');
      await _dbService.removeGroupPost(groupId, postId);
    } catch (e) {
      debugPrint('❌ Error deleting group post: $e');
      throw GroupRepositoryException('Failed to delete group post', originalError: e);
    }
  }

  @override
  Future<int> getTodayPostCount({
    required String groupId,
    required String userId,
  }) async {
    try {
      return await _dbService.getTodayPostCount(groupId, userId);
    } catch (e) {
      debugPrint('❌ Error getting today post count: $e');
      return 0;
    }
  }

  // ===============================
  // MEDIA OPERATIONS
  // ===============================

  @override
  Future<String> uploadGroupImage(File file) async {
    try {
      final response = await _httpClient.uploadFile(
        '/upload',
        file,
        'file',
        additionalFields: {'type': 'group_image'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      
      throw GroupRepositoryException('Failed to upload group image');
    } catch (e) {
      debugPrint('❌ Error uploading group image: $e');
      throw GroupRepositoryException('Failed to upload group image', originalError: e);
    }
  }

  @override
  Future<String> uploadCoverImage(File file) async {
    try {
      final response = await _httpClient.uploadFile(
        '/upload',
        file,
        'file',
        additionalFields: {'type': 'cover_image'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      
      throw GroupRepositoryException('Failed to upload cover image');
    } catch (e) {
      debugPrint('❌ Error uploading cover image: $e');
      throw GroupRepositoryException('Failed to upload cover image', originalError: e);
    }
  }

  @override
  Future<List<VideoModel>> getGroupMedia(String groupId) async {
    try {
      final response = await _httpClient.get('/groups/$groupId/media');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final media = (data['media'] as List)
            .map((m) => VideoModel.fromJson(m))
            .toList();
        return media;
      }
      
      return [];
    } catch (e) {
      debugPrint('❌ Error getting group media: $e');
      throw GroupRepositoryException('Failed to get group media', originalError: e);
    }
  }

  // ===============================
  // SYNC OPERATIONS
  // ===============================

  @override
  Future<void> syncWithServer() async {
    try {
      debugPrint('🔄 Starting sync with server...');
      
      // Sync groups
      await _syncGroupsInBackground();
      
      debugPrint('✅ Sync completed');
    } catch (e) {
      debugPrint('❌ Error syncing with server: $e');
      throw GroupRepositoryException('Failed to sync with server', originalError: e);
    }
  }

  @override
  Future<GroupModel?> refreshGroup(String groupId) async {
    try {
      if (!isConnected) return await getGroupById(groupId);
      
      final response = await _httpClient.get('/groups/$groupId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final group = GroupModel.fromMap(data, data['id']);
        await _dbService.upsertGroup(group);
        return group;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error refreshing group: $e');
      throw GroupRepositoryException('Failed to refresh group', originalError: e);
    }
  }

  @override
  Future<List<GroupModel>> refreshGroups() async {
    try {
      if (!isConnected) return await getGroups();
      
      final response = await _httpClient.get('/groups');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final groups = (data['groups'] as List)
            .map((g) => GroupModel.fromMap(g, g['id']))
            .toList();
        
        // Update local DB
        for (final group in groups) {
          await _dbService.upsertGroup(group);
        }
        
        return groups;
      }
      
      return [];
    } catch (e) {
      debugPrint('❌ Error refreshing groups: $e');
      throw GroupRepositoryException('Failed to refresh groups', originalError: e);
    }
  }

  // ===============================
  // CACHE OPERATIONS
  // ===============================

  @override
  Future<void> clearCache() async {
    try {
      await _dbService.clearAllData();
      debugPrint('✅ Cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
      throw GroupRepositoryException('Failed to clear cache', originalError: e);
    }
  }

  @override
  Future<void> clearGroupCache(String groupId) async {
    try {
      await _dbService.deleteGroup(groupId);
      debugPrint('✅ Group cache cleared: $groupId');
    } catch (e) {
      debugPrint('❌ Error clearing group cache: $e');
      throw GroupRepositoryException('Failed to clear group cache', originalError: e);
    }
  }

  @override
  Future<int> getCacheSize() async {
    try {
      return await _dbService.getDatabaseSize();
    } catch (e) {
      debugPrint('❌ Error getting cache size: $e');
      throw GroupRepositoryException('Failed to get cache size', originalError: e);
    }
  }

  // ===============================
  // USER INFO OPERATIONS
  // ===============================

  @override
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<List<GroupModel>> getAdminGroups() async {
    try {
      if (currentUserId == null) return [];
      
      final myGroups = await getMyGroups();
      return myGroups.where((group) => group.isAdmin(currentUserId!)).toList();
    } catch (e) {
      debugPrint('❌ Error getting admin groups: $e');
      throw GroupRepositoryException('Failed to get admin groups', originalError: e);
    }
  }

  @override
  Future<List<GroupModel>> getModeratorGroups() async {
    try {
      if (currentUserId == null) return [];
      
      final myGroups = await getMyGroups();
      return myGroups.where((group) => group.isModerator(currentUserId!)).toList();
    } catch (e) {
      debugPrint('❌ Error getting moderator groups: $e');
      throw GroupRepositoryException('Failed to get moderator groups', originalError: e);
    }
  }

  @override
  Future<Map<String, dynamic>> getGroupStatistics(String groupId) async {
    try {
      final response = await _httpClient.get('/groups/$groupId/statistics');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      
      return {};
    } catch (e) {
      debugPrint('❌ Error getting group statistics: $e');
      throw GroupRepositoryException('Failed to get group statistics', originalError: e);
    }
  }

  // ===============================
  // CLEANUP
  // ===============================

  Future<void> dispose() async {
    await _wsMessageSubscription?.cancel();
    await _groupUpdateController.close();
    await _allGroupsController.close();
    await _dbService.close();
  }
}