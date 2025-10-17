// lib/features/groups/repositories/group_repository.dart
// Abstract repository interface for group operations
// Defines contract for WebSocket + SQLite implementation

import 'dart:io';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/videos/models/video_model.dart';

/// Exception class for group repository errors
class GroupRepositoryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const GroupRepositoryException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'GroupRepositoryException: $message';
}

/// Abstract repository interface for all group operations
/// Implementation will use WebSocket for real-time + SQLite for local storage
abstract class GroupRepository {
  // ===============================
  // CONNECTION MANAGEMENT
  // ===============================
  
  /// Connect to WebSocket server
  Future<void> connect();
  
  /// Disconnect from WebSocket server
  Future<void> disconnect();
  
  /// Check if currently connected to WebSocket
  bool get isConnected;
  
  /// Listen to connection state changes
  Stream<bool> get connectionStateStream;
  
  /// Reconnect to WebSocket server
  Future<void> reconnect();

  // ===============================
  // GROUP OPERATIONS
  // ===============================
  
  /// Get all groups
  /// Returns groups from local DB immediately, then syncs with server
  Future<List<GroupModel>> getGroups();
  
  /// Get groups user is a member of
  Future<List<GroupModel>> getMyGroups();
  
  /// Get featured groups
  Future<List<GroupModel>> getFeaturedGroups();
  
  /// Get a specific group by ID
  Future<GroupModel?> getGroupById(String groupId);
  
  /// Create a new group
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
  });
  
  /// Update group info
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
  });
  
  /// Delete group (admin only)
  Future<void> deleteGroup(String groupId);
  
  /// Search groups
  Future<List<GroupModel>> searchGroups(String query);
  
  /// Listen to real-time group updates
  Stream<GroupModel> watchGroup(String groupId);
  
  /// Listen to all groups updates
  Stream<List<GroupModel>> watchAllGroups();

  // ===============================
  // MEMBER OPERATIONS
  // ===============================
  
  /// Get group members
  Future<List<GroupMember>> getGroupMembers(String groupId);
  
  /// Add member to group
  Future<void> addMember({
    required String groupId,
    required String userId,
    required String userName,
    required String userImage,
  });
  
  /// Remove member from group (admin/moderator only)
  Future<void> removeMember({
    required String groupId,
    required String userId,
  });
  
  /// Leave group
  Future<void> leaveGroup(String groupId);
  
  /// Promote member to admin
  Future<void> promoteToAdmin({
    required String groupId,
    required String userId,
  });
  
  /// Demote admin to member
  Future<void> demoteAdmin({
    required String groupId,
    required String userId,
  });
  
  /// Promote member to moderator
  Future<void> promoteToModerator({
    required String groupId,
    required String userId,
  });
  
  /// Demote moderator to member
  Future<void> demoteModerator({
    required String groupId,
    required String userId,
  });
  
  /// Mute member (prevent from posting)
  Future<void> muteMember({
    required String groupId,
    required String userId,
  });
  
  /// Unmute member
  Future<void> unmuteMember({
    required String groupId,
    required String userId,
  });
  
  /// Check if user is member of group
  Future<bool> isMember(String groupId);
  
  /// Check if user is admin of group
  Future<bool> isAdmin(String groupId);
  
  /// Check if user is moderator of group
  Future<bool> isModerator(String groupId);

  // ===============================
  // JOIN REQUEST OPERATIONS
  // ===============================
  
  /// Send join request (for approval-required groups)
  Future<void> sendJoinRequest(String groupId);
  
  /// Cancel join request
  Future<void> cancelJoinRequest(String groupId);
  
  /// Get pending join requests (admin only)
  Future<List<String>> getPendingRequests(String groupId);
  
  /// Approve join request (admin only)
  Future<void> approveJoinRequest({
    required String groupId,
    required String userId,
  });
  
  /// Reject join request (admin only)
  Future<void> rejectJoinRequest({
    required String groupId,
    required String userId,
  });
  
  /// Check if user has pending request
  Future<bool> hasPendingRequest(String groupId);

  // ===============================
  // GROUP POST OPERATIONS
  // ===============================
  
  /// Get posts in a group
  Future<List<VideoModel>> getGroupPosts({
    required String groupId,
    int limit = 20,
    String? before,
  });
  
  /// Create a post in group
  Future<VideoModel> createGroupPost({
    required String groupId,
    required File? videoFile,
    required List<File>? imageFiles,
    required String caption,
    List<String>? tags,
  });
  
  /// Delete group post (admin/moderator/author only)
  Future<void> deleteGroupPost({
    required String groupId,
    required String postId,
  });
  
  /// Get today's post count for user in group
  Future<int> getTodayPostCount({
    required String groupId,
    required String userId,
  });

  // ===============================
  // MEDIA OPERATIONS
  // ===============================
  
  /// Upload group image to server
  Future<String> uploadGroupImage(File file);
  
  /// Upload cover image to server
  Future<String> uploadCoverImage(File file);
  
  /// Get group media (posts with images/videos)
  Future<List<VideoModel>> getGroupMedia(String groupId);

  // ===============================
  // SYNC OPERATIONS
  // ===============================
  
  /// Sync local database with server
  Future<void> syncWithServer();
  
  /// Force refresh group from server
  Future<GroupModel?> refreshGroup(String groupId);
  
  /// Force refresh groups from server
  Future<List<GroupModel>> refreshGroups();

  // ===============================
  // CACHE OPERATIONS
  // ===============================
  
  /// Clear all local cache
  Future<void> clearCache();
  
  /// Clear cache for specific group
  Future<void> clearGroupCache(String groupId);
  
  /// Get cache size
  Future<int> getCacheSize();

  // ===============================
  // USER INFO OPERATIONS
  // ===============================
  
  /// Get current user ID
  String? get currentUserId;
  
  /// Get groups where user is admin
  Future<List<GroupModel>> getAdminGroups();
  
  /// Get groups where user is moderator
  Future<List<GroupModel>> getModeratorGroups();
  
  /// Get group statistics
  Future<Map<String, dynamic>> getGroupStatistics(String groupId);
}