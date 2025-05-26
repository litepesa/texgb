// lib/features/groups/repositories/group_repository.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/services/group_security_service.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

class GroupRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final GroupSecurityService _securityService;
  final DefaultCacheManager _cacheManager;

  // Public getters for accessing firestore and auth
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;
  GroupSecurityService get securityService => _securityService;

  GroupRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth,
        _securityService = GroupSecurityService(firestore: firestore, auth: auth),
        _cacheManager = DefaultCacheManager();

  /// Create a new group with enhanced validation
  Future<GroupModel> createGroup({
    required String groupName,
    required String groupDescription,
    required List<String> membersUIDs,
    required List<String> adminsUIDs,
    required File? groupImage,
    required bool isPrivate,
    required bool editSettings,
    required bool approveMembers,
    required bool lockMessages,
    required bool requestToJoin,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate group name
      if (groupName.trim().isEmpty || groupName.trim().length < 3) {
        throw Exception('Group name must be at least 3 characters');
      }

      // Validate member count
      if (membersUIDs.isEmpty) {
        throw Exception('Group must have at least one member');
      }

      // Ensure unique members
      final uniqueMembers = membersUIDs.toSet().toList();
      final uniqueAdmins = adminsUIDs.toSet().toList();

      // Generate group ID
      final groupId = const Uuid().v4();
      final createdAt = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Upload group image if provided
      String imageUrl = '';
      if (groupImage != null) {
        imageUrl = await storeFileToStorage(
          file: groupImage,
          reference: '${Constants.groupImages}/$groupId',
        );
      }

      // Ensure creator is in members and admins lists
      if (!uniqueMembers.contains(currentUser.uid)) {
        uniqueMembers.add(currentUser.uid);
      }
      if (!uniqueAdmins.contains(currentUser.uid)) {
        uniqueAdmins.add(currentUser.uid);
      }

      // Create group model
      final group = GroupModel(
        groupId: groupId,
        groupName: groupName.trim(),
        groupDescription: groupDescription.trim(),
        groupImage: imageUrl,
        creatorUID: currentUser.uid,
        isPrivate: isPrivate,
        editSettings: editSettings,
        approveMembers: approveMembers,
        lockMessages: lockMessages,
        requestToJoin: requestToJoin,
        membersUIDs: uniqueMembers,
        adminsUIDs: uniqueAdmins,
        awaitingApprovalUIDs: [],
        createdAt: createdAt,
      );

      // Use transaction for atomic operation
      await _firestore.runTransaction((transaction) async {
        // Create group document
        transaction.set(
          _firestore.collection(Constants.groups).doc(groupId),
          group.toMap(),
        );

        // Initialize unreadCountByUser map
        Map<String, int> unreadCountByUser = {};
        for (String uid in uniqueMembers) {
          unreadCountByUser[uid] = 0;
        }

        // Create group chat entry
        transaction.set(
          _firestore.collection(Constants.chats).doc(groupId),
          {
            'id': groupId,
            'participants': uniqueMembers,
            Constants.groupId: groupId,
            Constants.groupName: groupName.trim(),
            Constants.groupImage: imageUrl,
            'isGroup': true,
            Constants.lastMessage: 'Group created',
            Constants.messageType: MessageEnum.text.name,
            Constants.timeSent: createdAt,
            'lastMessageSender': currentUser.uid,
            'unreadCount': 0,
            'unreadCountByUser': unreadCountByUser,
          },
        );

        // Add system message
        final messageId = const Uuid().v4();
        transaction.set(
          _firestore.collection(Constants.chats).doc(groupId)
              .collection(Constants.messages).doc(messageId),
          MessageModel(
            messageId: messageId,
            senderUID: currentUser.uid,
            senderName: 'System',
            senderImage: '',
            message: 'Group "$groupName" created. Welcome!',
            messageType: MessageEnum.text,
            timeSent: createdAt,
            messageStatus: MessageStatus.delivered,
            deletedBy: [],
          ).toMap(),
        );
      });

      // Clear relevant caches
      _securityService.clearGroupCache(groupId);

      return group;
    } catch (e) {
      debugPrint('Error creating group: $e');
      throw e.toString();
    }
  }

  /// Get groups for current user with security check
  Stream<List<GroupModel>> getUserGroups() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection(Constants.groups)
        .where(Constants.membersUIDs, arrayContains: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final groups = <GroupModel>[];
          
          for (final doc in snapshot.docs) {
            try {
              final group = GroupModel.fromMap(doc.data());
              
              // Double-check membership for security
              final isMember = await _securityService.isUserMember(group.groupId);
              if (isMember) {
                groups.add(group);
              }
            } catch (e) {
              debugPrint('Error parsing group ${doc.id}: $e');
            }
          }
          
          return groups;
        });
  }

  /// Get a group by ID with security validation
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      // Check if user can view this group
      final canView = await _securityService.canUserViewGroup(groupId);
      if (!canView) {
        debugPrint('User does not have permission to view group $groupId');
        return null;
      }

      final doc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!doc.exists) return null;

      return GroupModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('Error getting group: $e');
      return null;
    }
  }

  /// Update group details with security check
  Future<void> updateGroup(GroupModel updatedGroup, File? newGroupImage) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate permission to edit
      final actionResult = await _securityService.validateGroupAction(
        updatedGroup.groupId,
        GroupAction.editSettings,
      );
      
      if (!actionResult.isAllowed) {
        throw Exception(actionResult.reason ?? 'Cannot edit group settings');
      }

      // Upload new group image if provided
      if (newGroupImage != null) {
        final imageUrl = await storeFileToStorage(
          file: newGroupImage,
          reference: '${Constants.groupImages}/${updatedGroup.groupId}',
        );
        updatedGroup = updatedGroup.copyWith(groupImage: imageUrl);
      }

      await _firestore.runTransaction((transaction) async {
        // Update group document
        transaction.update(
          _firestore.collection(Constants.groups).doc(updatedGroup.groupId),
          updatedGroup.toMap(),
        );

        // Update chat entry
        transaction.update(
          _firestore.collection(Constants.chats).doc(updatedGroup.groupId),
          {
            Constants.groupName: updatedGroup.groupName,
            Constants.groupImage: updatedGroup.groupImage,
          },
        );
      });

      // Clear cache
      _securityService.clearGroupCache(updatedGroup.groupId);
    } catch (e) {
      debugPrint('Error updating group: $e');
      throw e.toString();
    }
  }

  /// Reset unread counter for a specific user in a group
  Future<void> resetGroupUnreadCounter(String groupId, String userId) async {
    try {
      // Validate user can access this group
      final canView = await _securityService.canUserViewGroup(groupId);
      if (!canView) {
        debugPrint('User does not have permission to access group $groupId');
        return;
      }

      final chatDoc = await _firestore.collection(Constants.chats).doc(groupId).get();
      
      if (chatDoc.exists) {
        Map<String, dynamic> unreadCountByUser = 
            Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
        
        unreadCountByUser[userId] = 0;
        
        await _firestore.collection(Constants.chats).doc(groupId).update({
          'unreadCountByUser': unreadCountByUser,
        });
      }
    } catch (e) {
      debugPrint('Error resetting group unread counter: $e');
    }
  }

  /// Join a group with enhanced security
  Future<void> joinGroup(String groupId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is already a member
      final isMember = await _securityService.isUserMember(groupId);
      if (isMember) {
        throw Exception('Already a member of this group');
      }

      final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = GroupModel.fromMap(groupDoc.data()!);

      await _firestore.runTransaction((transaction) async {
        if (group.isPrivate && group.approveMembers) {
          // Add to awaiting approval list
          transaction.update(
            _firestore.collection(Constants.groups).doc(groupId),
            {
              Constants.awaitingApprovalUIDs: FieldValue.arrayUnion([currentUser.uid]),
            },
          );
        } else {
          // Add directly to members
          transaction.update(
            _firestore.collection(Constants.groups).doc(groupId),
            {
              Constants.membersUIDs: FieldValue.arrayUnion([currentUser.uid]),
            },
          );

          // Update chat participants
          transaction.update(
            _firestore.collection(Constants.chats).doc(groupId),
            {
              'participants': FieldValue.arrayUnion([currentUser.uid]),
            },
          );
          
          // Initialize unread counter for new member
          final chatDoc = await _firestore.collection(Constants.chats).doc(groupId).get();
          if (chatDoc.exists) {
            Map<String, dynamic> unreadCountByUser = 
                Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
            unreadCountByUser[currentUser.uid] = 0;
            
            transaction.update(
              _firestore.collection(Constants.chats).doc(groupId),
              {'unreadCountByUser': unreadCountByUser},
            );
          }
        }
      });

      // Clear cache
      _securityService.clearGroupCache(groupId);
    } catch (e) {
      debugPrint('Error joining group: $e');
      throw e.toString();
    }
  }

  /// Leave group with proper cleanup
  Future<void> leaveGroup(String groupId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate user can leave
      final actionResult = await _securityService.validateGroupAction(
        groupId,
        GroupAction.leaveGroup,
      );
      
      if (!actionResult.isAllowed) {
        throw Exception(actionResult.reason ?? 'Cannot leave group');
      }

      final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = GroupModel.fromMap(groupDoc.data()!);

      await _firestore.runTransaction((transaction) async {
        if (group.creatorUID == currentUser.uid) {
          // Creator leaving - handle succession or deletion
          await _handleCreatorLeaving(transaction, group, currentUser.uid);
        } else {
          // Regular member leaving
          await _removeUserFromGroup(transaction, groupId, currentUser.uid);
        }
      });

      // Clear cache
      _securityService.clearGroupCache(groupId);
    } catch (e) {
      debugPrint('Error leaving group: $e');
      throw e.toString();
    }
  }

  /// Approve a user's request to join with security check
  Future<void> approveJoinRequest(String groupId, String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate admin permission
      final isAdmin = await _securityService.isUserAdmin(groupId);
      if (!isAdmin) {
        throw Exception('Only admins can approve join requests');
      }

      await _firestore.runTransaction((transaction) async {
        // Remove from awaiting approval
        transaction.update(
          _firestore.collection(Constants.groups).doc(groupId),
          {
            Constants.awaitingApprovalUIDs: FieldValue.arrayRemove([userId]),
          },
        );
        
        // Add to members
        transaction.update(
          _firestore.collection(Constants.groups).doc(groupId),
          {
            Constants.membersUIDs: FieldValue.arrayUnion([userId]),
          },
        );
        
        // Add to chat participants
        transaction.update(
          _firestore.collection(Constants.chats).doc(groupId),
          {
            'participants': FieldValue.arrayUnion([userId]),
          },
        );
        
        // Initialize unread counter
        final chatDoc = await _firestore.collection(Constants.chats).doc(groupId).get();
        if (chatDoc.exists) {
          Map<String, dynamic> unreadCountByUser = 
              Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
          unreadCountByUser[userId] = 0;
          
          transaction.update(
            _firestore.collection(Constants.chats).doc(groupId),
            {'unreadCountByUser': unreadCountByUser},
          );
        }
      });

      // Clear cache
      _securityService.clearGroupCache(groupId);
    } catch (e) {
      debugPrint('Error approving join request: $e');
      throw e.toString();
    }
  }

  /// Reject a user's request to join with security check
  Future<void> rejectJoinRequest(String groupId, String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate admin permission
      final isAdmin = await _securityService.isUserAdmin(groupId);
      if (!isAdmin) {
        throw Exception('Only admins can reject join requests');
      }

      await _firestore.collection(Constants.groups).doc(groupId).update({
        Constants.awaitingApprovalUIDs: FieldValue.arrayRemove([userId]),
      });

      // Clear cache
      _securityService.clearGroupCache(groupId);
    } catch (e) {
      debugPrint('Error rejecting join request: $e');
      throw e.toString();
    }
  }

  /// Add user as admin with security check
  Future<void> addAdmin(String groupId, String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate admin permission
      final isAdmin = await _securityService.isUserAdmin(groupId);
      if (!isAdmin) {
        throw Exception('Only admins can add other admins');
      }

      await _firestore.collection(Constants.groups).doc(groupId).update({
        Constants.adminsUIDs: FieldValue.arrayUnion([userId]),
      });

      // Clear cache
      _securityService.clearGroupCache(groupId);
    } catch (e) {
      debugPrint('Error adding admin: $e');
      throw e.toString();
    }
  }

  /// Remove user as admin with security check
  Future<void> removeAdmin(String groupId, String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get group to validate
      final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = GroupModel.fromMap(groupDoc.data()!);
      
      // Only creator can remove other admins, or admin can remove themselves
      if (group.creatorUID != currentUser.uid && currentUser.uid != userId) {
        throw Exception('Only the creator can remove other admins');
      }
      
      // Ensure we're not removing the last admin
      if (group.adminsUIDs.length <= 1) {
        throw Exception('Cannot remove the last admin');
      }
      
      // Don't allow removing the creator as admin
      if (group.creatorUID == userId) {
        throw Exception('Cannot remove the creator as admin');
      }

      await _firestore.collection(Constants.groups).doc(groupId).update({
        Constants.adminsUIDs: FieldValue.arrayRemove([userId]),
      });

      // Clear cache
      _securityService.clearGroupCache(groupId);
    } catch (e) {
      debugPrint('Error removing admin: $e');
      throw e.toString();
    }
  }

  /// Remove a member from the group with security check
  Future<void> removeMember(String groupId, String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate admin permission
      final isAdmin = await _securityService.isUserAdmin(groupId);
      if (!isAdmin) {
        throw Exception('Only admins can remove members');
      }

      await _firestore.runTransaction((transaction) async {
        await _removeUserFromGroup(transaction, groupId, userId);
      });

      // Clear cache
      _securityService.clearGroupCache(groupId);
    } catch (e) {
      debugPrint('Error removing member: $e');
      throw e.toString();
    }
  }

  /// Find public groups the user can join
  Stream<List<GroupModel>> findPublicGroups() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection(Constants.groups)
        .where(Constants.isPrivate, isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final groups = snapshot.docs.map((doc) {
            return GroupModel.fromMap(doc.data());
          }).toList();
          
          // Filter out groups the user is already in
          return groups.where((group) => !group.isMember(currentUser.uid)).toList();
        });
  }

  /// Get group members as UserModel list with security check
  Future<List<UserModel>> getGroupMembers(String groupId) async {
    try {
      // Validate user can view group members
      final canView = await _securityService.canUserViewGroup(groupId);
      if (!canView) {
        debugPrint('User does not have permission to view group members');
        return [];
      }

      final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = GroupModel.fromMap(groupDoc.data()!);
      final List<UserModel> members = [];

      // Fetch each member's user data
      for (final memberId in group.membersUIDs) {
        final userDoc = await _firestore.collection(Constants.users).doc(memberId).get();
        if (userDoc.exists) {
          members.add(UserModel.fromMap(userDoc.data() as Map<String, dynamic>));
        }
      }

      return members;
    } catch (e) {
      debugPrint('Error getting group members: $e');
      throw e.toString();
    }
  }

  /// Search for groups by name
  Future<List<GroupModel>> searchGroupsByName(String query) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      if (query.trim().isEmpty) return [];

      final querySnapshot = await _firestore
          .collection(Constants.groups)
          .where(Constants.groupName, isGreaterThanOrEqualTo: query)
          .where(Constants.groupName, isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return querySnapshot.docs.map((doc) {
        return GroupModel.fromMap(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('Error searching groups: $e');
      return [];
    }
  }

  /// Handle creator leaving the group
  Future<void> _handleCreatorLeaving(
    Transaction transaction,
    GroupModel group,
    String creatorUid,
  ) async {
    if (group.adminsUIDs.length > 1) {
      // Transfer ownership to another admin
      final newCreator = group.adminsUIDs.firstWhere(
        (uid) => uid != creatorUid,
        orElse: () => '',
      );
      
      if (newCreator.isNotEmpty) {
        transaction.update(
          _firestore.collection(Constants.groups).doc(group.groupId),
          {Constants.creatorUID: newCreator},
        );
        await _removeUserFromGroup(transaction, group.groupId, creatorUid);
      }
    } else if (group.membersUIDs.length > 1) {
      // Promote a member to admin and creator
      final newCreator = group.membersUIDs.firstWhere(
        (uid) => uid != creatorUid,
        orElse: () => '',
      );
      
      if (newCreator.isNotEmpty) {
        transaction.update(
          _firestore.collection(Constants.groups).doc(group.groupId),
          {
            Constants.creatorUID: newCreator,
            Constants.adminsUIDs: FieldValue.arrayUnion([newCreator]),
          },
        );
        await _removeUserFromGroup(transaction, group.groupId, creatorUid);
      }
    } else {
      // Delete the group if creator is the only member
      await _deleteGroup(transaction, group.groupId);
    }
  }

  /// Remove user from group
  Future<void> _removeUserFromGroup(
    Transaction transaction,
    String groupId,
    String userId,
  ) async {
    // Remove from members and admins
    transaction.update(
      _firestore.collection(Constants.groups).doc(groupId),
      {
        Constants.membersUIDs: FieldValue.arrayRemove([userId]),
        Constants.adminsUIDs: FieldValue.arrayRemove([userId]),
      },
    );
    
    // Remove from chat participants
    transaction.update(
      _firestore.collection(Constants.chats).doc(groupId),
      {'participants': FieldValue.arrayRemove([userId])},
    );
    
    // Remove from unread counts
    final chatDoc = await _firestore.collection(Constants.chats).doc(groupId).get();
    if (chatDoc.exists) {
      Map<String, dynamic> unreadCountByUser = 
          Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
      unreadCountByUser.remove(userId);
      
      transaction.update(
        _firestore.collection(Constants.chats).doc(groupId),
        {'unreadCountByUser': unreadCountByUser},
      );
    }
  }

  /// Delete group completely
  Future<void> _deleteGroup(Transaction transaction, String groupId) async {
    // Delete group document
    transaction.delete(_firestore.collection(Constants.groups).doc(groupId));
    
    // Delete chat document
    transaction.delete(_firestore.collection(Constants.chats).doc(groupId));
    
    // Note: Messages will be cleaned up by a cloud function or background task
  }

  /// Update unread counts when a new message is sent
  Future<void> updateUnreadCountsForGroupMessage({
    required String groupId,
    required String senderUid,
  }) async {
    try {
      // Validate sender can send messages
      final canSend = await _securityService.canUserSendMessages(groupId);
      if (!canSend) {
        debugPrint('User cannot send messages to group $groupId');
        return;
      }

      // Get the group members
      final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!groupDoc.exists) return;
      
      final group = GroupModel.fromMap(groupDoc.data()!);
      
      // Get current unread counts from chat
      final chatDoc = await _firestore.collection(Constants.chats).doc(groupId).get();
      if (!chatDoc.exists) return;
      
      Map<String, dynamic> unreadCountByUser = 
          Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
      
      // Update unread count for all members except the sender
      for (final memberId in group.membersUIDs) {
        if (memberId != senderUid) {
          unreadCountByUser[memberId] = (unreadCountByUser[memberId] as int? ?? 0) + 1;
        } else {
          unreadCountByUser[memberId] = 0;
        }
      }
      
      // Update the chat document
      await _firestore.collection(Constants.chats).doc(groupId).update({
        'unreadCountByUser': unreadCountByUser,
        'unreadCount': 1, // For backward compatibility
      });
    } catch (e) {
      debugPrint('Error updating unread counts for group message: $e');
    }
  }

  /// Get total unread count for all groups for a specific user
  Future<int> getTotalGroupUnreadCount(String userId) async {
    try {
      if (userId.isEmpty) return 0;
      
      // Get all the user's group chats
      final querySnapshot = await _firestore
          .collection(Constants.chats)
          .where('isGroup', isEqualTo: true)
          .where('participants', arrayContains: userId)
          .get();
      
      int totalUnread = 0;
      
      for (final doc in querySnapshot.docs) {
        // Validate user can access this group
        final canView = await _securityService.canUserViewGroup(doc.id);
        if (!canView) continue;

        final unreadCountByUser = doc.data()['unreadCountByUser'] as Map<String, dynamic>?;
        if (unreadCountByUser != null && unreadCountByUser.containsKey(userId)) {
          totalUnread += (unreadCountByUser[userId] as int? ?? 0);
        }
      }
      
      return totalUnread;
    } catch (e) {
      debugPrint('Error getting total group unread count: $e');
      return 0;
    }
  }
}

// Provider for the group repository
final groupRepositoryProvider = Provider((ref) {
  return GroupRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});