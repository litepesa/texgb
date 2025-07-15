// lib/features/groups/services/group_security_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/groups/models/group_model.dart';

/// Service to handle group security and member verification
class GroupSecurityService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  // Cache for group membership checks to avoid repeated queries
  final Map<String, Map<String, bool>> _membershipCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  GroupSecurityService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  /// Check if current user is a member of the group with caching
  Future<bool> isUserMember(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    return await _isUserMemberById(groupId, currentUser.uid);
  }

  /// Check if specific user is a member of the group with caching
  Future<bool> _isUserMemberById(String groupId, String userId) async {
    // Check cache first
    final cacheKey = '$groupId:$userId';
    final cachedResult = _getCachedMembership(cacheKey);
    if (cachedResult != null) {
      return cachedResult;
    }

    try {
      final groupDoc = await _firestore
          .collection(Constants.groups)
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        _cacheMembership(cacheKey, false);
        return false;
      }

      final group = GroupModel.fromMap(groupDoc.data()!);
      final isMember = group.isMember(userId);
      
      // Cache the result
      _cacheMembership(cacheKey, isMember);
      
      return isMember;
    } catch (e) {
      debugPrint('Error checking group membership: $e');
      return false;
    }
  }

  /// Check if current user is an admin of the group
  Future<bool> isUserAdmin(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final groupDoc = await _firestore
          .collection(Constants.groups)
          .doc(groupId)
          .get();

      if (!groupDoc.exists) return false;

      final group = GroupModel.fromMap(groupDoc.data()!);
      return group.isAdmin(currentUser.uid);
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Check if current user can send messages to the group
  Future<bool> canUserSendMessages(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final groupDoc = await _firestore
          .collection(Constants.groups)
          .doc(groupId)
          .get();

      if (!groupDoc.exists) return false;

      final group = GroupModel.fromMap(groupDoc.data()!);
      
      // Must be a member
      if (!group.isMember(currentUser.uid)) return false;
      
      // If messages are locked, only admins can send
      if (group.lockMessages) {
        return group.isAdmin(currentUser.uid);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking message permission: $e');
      return false;
    }
  }

  /// Check if current user can view the group
  Future<bool> canUserViewGroup(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final groupDoc = await _firestore
          .collection(Constants.groups)
          .doc(groupId)
          .get();

      if (!groupDoc.exists) return false;

      final group = GroupModel.fromMap(groupDoc.data()!);
      
      // Must be a member to view the group
      return group.isMember(currentUser.uid);
    } catch (e) {
      debugPrint('Error checking view permission: $e');
      return false;
    }
  }

  /// Validate group action permissions
  Future<GroupActionResult> validateGroupAction(
    String groupId,
    GroupAction action,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return GroupActionResult.unauthorized('User not authenticated');
    }

    try {
      final groupDoc = await _firestore
          .collection(Constants.groups)
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        return GroupActionResult.forbidden('Group not found');
      }

      final group = GroupModel.fromMap(groupDoc.data()!);
      
      // Check basic membership for most actions
      if (!group.isMember(currentUser.uid)) {
        return GroupActionResult.forbidden('Not a group member');
      }

      switch (action) {
        case GroupAction.viewMessages:
        case GroupAction.viewMembers:
          return GroupActionResult.allowed();
          
        case GroupAction.sendMessage:
          if (group.lockMessages && !group.isAdmin(currentUser.uid)) {
            return GroupActionResult.forbidden('Only admins can send messages');
          }
          return GroupActionResult.allowed();
          
        case GroupAction.addMember:
        case GroupAction.removeMember:
        case GroupAction.editSettings:
          if (!group.isAdmin(currentUser.uid)) {
            return GroupActionResult.forbidden('Admin permission required');
          }
          return GroupActionResult.allowed();
          
        case GroupAction.deleteGroup:
          if (!group.isCreator(currentUser.uid)) {
            return GroupActionResult.forbidden('Only creator can delete group');
          }
          return GroupActionResult.allowed();
          
        case GroupAction.leaveGroup:
          // Anyone can leave (except we handle creator leaving specially)
          return GroupActionResult.allowed();
      }
    } catch (e) {
      debugPrint('Error validating group action: $e');
      return GroupActionResult.error('Validation error: $e');
    }
  }

  /// Cache membership result
  void _cacheMembership(String cacheKey, bool isMember) {
    _membershipCache[cacheKey] = {cacheKey: isMember};
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  /// Get cached membership result if still valid
  bool? _getCachedMembership(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return null;
    
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      _membershipCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      return null;
    }
    
    return _membershipCache[cacheKey]?[cacheKey];
  }

  /// Clear cache for a specific group
  void clearGroupCache(String groupId) {
    final keysToRemove = <String>[];
    for (final key in _membershipCache.keys) {
      if (key.startsWith('$groupId:')) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      _membershipCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clear all cache
  void clearAllCache() {
    _membershipCache.clear();
    _cacheTimestamps.clear();
  }
}

/// Enum for different group actions
enum GroupAction {
  viewMessages,
  sendMessage,
  viewMembers,
  addMember,
  removeMember,
  editSettings,
  deleteGroup,
  leaveGroup,
}

/// Result of group action validation
class GroupActionResult {
  final bool isAllowed;
  final String? reason;
  final GroupActionResultType type;

  const GroupActionResult._({
    required this.isAllowed,
    this.reason,
    required this.type,
  });

  factory GroupActionResult.allowed() {
    return const GroupActionResult._(
      isAllowed: true,
      type: GroupActionResultType.allowed,
    );
  }

  factory GroupActionResult.forbidden(String reason) {
    return GroupActionResult._(
      isAllowed: false,
      reason: reason,
      type: GroupActionResultType.forbidden,
    );
  }

  factory GroupActionResult.unauthorized(String reason) {
    return GroupActionResult._(
      isAllowed: false,
      reason: reason,
      type: GroupActionResultType.unauthorized,
    );
  }

  factory GroupActionResult.error(String reason) {
    return GroupActionResult._(
      isAllowed: false,
      reason: reason,
      type: GroupActionResultType.error,
    );
  }
}

// Provider for GroupSecurityService
final groupSecurityServiceProvider = Provider<GroupSecurityService>((ref) {
  return GroupSecurityService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

enum GroupActionResultType {
  allowed,
  forbidden,
  unauthorized,
  error,
}