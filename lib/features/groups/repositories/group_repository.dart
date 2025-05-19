// lib/features/groups/repositories/group_repository.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

class GroupRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GroupRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // Create a new group
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

      // Ensure the member count doesn't exceed the limit
      if (membersUIDs.length > GroupModel.MAX_MEMBERS) {
        throw Exception('Group cannot have more than ${GroupModel.MAX_MEMBERS} members');
      }

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
      if (!membersUIDs.contains(currentUser.uid)) {
        membersUIDs.add(currentUser.uid);
      }
      if (!adminsUIDs.contains(currentUser.uid)) {
        adminsUIDs.add(currentUser.uid);
      }

      // Create group model
      final group = GroupModel(
        groupId: groupId,
        groupName: groupName,
        groupDescription: groupDescription,
        groupImage: imageUrl,
        creatorUID: currentUser.uid,
        isPrivate: isPrivate,
        editSettings: editSettings,
        approveMembers: approveMembers,
        lockMessages: lockMessages,
        requestToJoin: requestToJoin,
        membersUIDs: membersUIDs,
        adminsUIDs: adminsUIDs,
        awaitingApprovalUIDs: [],
        createdAt: createdAt,
      );

      // Save to Firestore
      await _firestore.collection(Constants.groups).doc(groupId).set(group.toMap());

      // Update user's groups in a batch
      final batch = _firestore.batch();
      
      // Initialize unreadCountByUser map
      Map<String, int> unreadCountByUser = {};
      for (String uid in membersUIDs) {
        unreadCountByUser[uid] = 0;
      }

      // Create group chat entry in chats collection
      batch.set(_firestore.collection(Constants.chats).doc(groupId), {
        'id': groupId,
        'participants': membersUIDs,
        Constants.groupId: groupId,
        Constants.groupName: groupName,
        Constants.groupImage: imageUrl,
        'isGroup': true,
        Constants.lastMessage: 'Group created',
        Constants.messageType: MessageEnum.text.name,
        Constants.timeSent: createdAt,
        'lastMessageSender': currentUser.uid,
        'unreadCount': 0,
        'unreadCountByUser': unreadCountByUser,
      });

      // Add welcome message
      final messageId = const Uuid().v4();
      batch.set(
        _firestore.collection(Constants.chats).doc(groupId).collection(Constants.messages).doc(messageId),
        MessageModel(
          messageId: messageId,
          senderUID: currentUser.uid,
          senderName: 'System',
          senderImage: '',
          message: 'Group created. Welcome to $groupName!',
          messageType: MessageEnum.text,
          timeSent: createdAt,
          messageStatus: MessageStatus.delivered,
          deletedBy: [],
        ).toMap(),
      );

      await batch.commit();

      return group;
    } catch (e) {
      debugPrint('Error creating group: $e');
      throw e.toString();
    }
  }

  // Get all groups for the current user
  Stream<List<GroupModel>> getUserGroups() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection(Constants.groups)
        .where(Constants.membersUIDs, arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return GroupModel.fromMap(doc.data());
          }).toList();
        });
  }

  // Get a single group by ID
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final doc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (doc.exists) {
        return GroupModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting group: $e');
      throw e.toString();
    }
  }

  // Update group details
  Future<void> updateGroup(GroupModel updatedGroup, File? newGroupImage) async {
    try {
      // Ensure the member count doesn't exceed the limit
      if (updatedGroup.membersUIDs.length > GroupModel.MAX_MEMBERS) {
        throw Exception('Group cannot have more than ${GroupModel.MAX_MEMBERS} members');
      }
      
      // Upload new group image if provided
      if (newGroupImage != null) {
        final imageUrl = await storeFileToStorage(
          file: newGroupImage,
          reference: '${Constants.groupImages}/${updatedGroup.groupId}',
        );
        updatedGroup = updatedGroup.copyWith(groupImage: imageUrl);
      }

      // Update in Firestore
      await _firestore
          .collection(Constants.groups)
          .doc(updatedGroup.groupId)
          .update(updatedGroup.toMap());

      // Also update the chat entry for the group
      await _firestore.collection(Constants.chats).doc(updatedGroup.groupId).update({
        Constants.groupName: updatedGroup.groupName,
        Constants.groupImage: updatedGroup.groupImage,
      });
    } catch (e) {
      debugPrint('Error updating group: $e');
      throw e.toString();
    }
  }

  // Reset unread counter for a specific user in a group
  Future<void> resetGroupUnreadCounter(String groupId, String userId) async {
    try {
      // Get the chat document for this group
      final chatDoc = await _firestore.collection(Constants.chats).doc(groupId).get();
      
      if (chatDoc.exists) {
        // Get current unread counts or initialize empty map
        Map<String, dynamic> unreadCountByUser = 
            Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
        
        // Reset unread count for current user only
        unreadCountByUser[userId] = 0;
        
        // Update the chat document
        await _firestore.collection(Constants.chats).doc(groupId).update({
          'unreadCountByUser': unreadCountByUser,
        });
      }
    } catch (e) {
      debugPrint('Error resetting group unread counter: $e');
    }
  }

  // Join a group (for public groups)
  Future<void> joinGroup(String groupId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = GroupModel.fromMap(groupDoc.data()!);
      
      // Check if the group has reached its member limit
      if (group.hasReachedMemberLimit()) {
        throw Exception('This group has reached its maximum member limit of ${GroupModel.MAX_MEMBERS}');
      }

      // Check if it's a private group with approval required
      if (group.isPrivate && group.approveMembers) {
        // Add user to awaiting approval list
        await _firestore.collection(Constants.groups).doc(groupId).update({
          Constants.awaitingApprovalUIDs: FieldValue.arrayUnion([currentUser.uid]),
        });
      } else {
        // Add user directly to members list
        await _firestore.collection(Constants.groups).doc(groupId).update({
          Constants.membersUIDs: FieldValue.arrayUnion([currentUser.uid]),
        });

        // Update the chat participants too
        await _firestore.collection(Constants.chats).doc(groupId).update({
          'participants': FieldValue.arrayUnion([currentUser.uid]),
        });
        
        // Initialize unread counter for this user
        final chatDoc = await _firestore.collection(Constants.chats).doc(groupId).get();
        if (chatDoc.exists) {
          Map<String, dynamic> unreadCountByUser = 
              Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
          
          // Set initial unread count to 0 for the new member
          unreadCountByUser[currentUser.uid] = 0;
          
          await _firestore.collection(Constants.chats).doc(groupId).update({
            'unreadCountByUser': unreadCountByUser,
          });
        }
      }
    } catch (e) {
      debugPrint('Error joining group: $e');
      throw e.toString();
    }
  }

  // Join a group using a join code
  Future<void> joinGroupByCode(String joinCode) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // First, find the group with this joining code
      final querySnapshot = await _firestore
          .collection(Constants.groups)
          .get();
      
      // Filter groups that start with this code (first 8 chars of groupId)
      final matchingGroups = querySnapshot.docs.where((doc) {
        final groupId = doc.id;
        if (groupId.length < 8) return false;
        final codePrefix = groupId.substring(0, 8);
        return codePrefix == joinCode;
      }).toList();
      
      if (matchingGroups.isEmpty) {
        throw Exception('Invalid group code or group does not exist');
      }
      
      // Get the first matching group
      final groupDoc = matchingGroups.first;
      final groupId = groupDoc.id;
      
      // Check if user is already a member
      final group = GroupModel.fromMap(groupDoc.data());
      if (group.isMember(currentUser.uid)) {
        throw Exception('You are already a member of this group');
      }
      
      // Join the group using the existing method
      await joinGroup(groupId);
      
      return;
    } catch (e) {
      debugPrint('Error joining group by code: $e');
      rethrow;
    }
  }

  // Check if a user is a member of a group
  Future<bool> isUserMemberOfGroup(String userId, String groupId) async {
    try {
      if (userId.isEmpty) return false;
      
      final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!groupDoc.exists) return false;
      
      final group = GroupModel.fromMap(groupDoc.data()!);
      return group.isMember(userId);
    } catch (e) {
      debugPrint('Error checking group membership: $e');
      return false;
    }
  }

  // Enforce group membership - throws exception if not a member
  Future<void> enforceGroupMembership(String userId, String groupId) async {
    final isMember = await isUserMemberOfGroup(userId, groupId);
    if (!isMember) {
      throw Exception('User is not a member of this group');
    }
  }

  // Check if a user can send messages (based on membership and lock status)
  Future<bool> canUserSendMessagesToGroup(String userId, String groupId) async {
    try {
      if (userId.isEmpty) return false;
      
      final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!groupDoc.exists) return false;
      
      final group = GroupModel.fromMap(groupDoc.data()!);
      // Must be a member first
      if (!group.isMember(userId)) return false;
      
      // If messages are locked, must be an admin
      if (group.lockMessages) {
        return group.isAdmin(userId);
      }
      
      // Otherwise, any member can send
      return true;
    } catch (e) {
      debugPrint('Error checking messaging permissions: $e');
      return false;
    }
  }

  // Leave a group
  Future<void> leaveGroup(String groupId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get group to check if user is the creator
      final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = GroupModel.fromMap(groupDoc.data()!);

      // Check if user is the creator
      if (group.creatorUID == currentUser.uid) {
        // If creator wants to leave, check if there are other admins
        if (group.adminsUIDs.length > 1) {
          // There are other admins, just leave
          await _removeUserFromGroup(groupId, currentUser.uid);
        } else if (group.membersUIDs.length > 1) {
          // No other admins but there are members, promote someone
          final newAdmin = group.membersUIDs.firstWhere(
            (uid) => uid != currentUser.uid,
            orElse: () => '',
          );
          
          if (newAdmin.isNotEmpty) {
            // Promote a member to admin and creator
            await _firestore.collection(Constants.groups).doc(groupId).update({
              Constants.adminsUIDs: FieldValue.arrayUnion([newAdmin]),
              Constants.creatorUID: newAdmin,
            });
            
            // Then leave the group
            await _removeUserFromGroup(groupId, currentUser.uid);
          }
        } else {
          // User is the only one in the group, so we can delete it
          await _deleteGroup(groupId);
        }
      } else {
        // Not the creator, just leave
        await _removeUserFromGroup(groupId, currentUser.uid);
      }
    } catch (e) {
      debugPrint('Error leaving group: $e');
      throw e.toString();
    }
  }

  // Helper method to remove a user from a group
  Future<void> _removeUserFromGroup(String groupId, String userId) async {
    final batch = _firestore.batch();
    
    // Remove from members list
    batch.update(_firestore.collection(Constants.groups).doc(groupId), {
      Constants.membersUIDs: FieldValue.arrayRemove([userId]),
    });
    
    // Remove from admins list
    batch.update(_firestore.collection(Constants.groups).doc(groupId), {
      Constants.adminsUIDs: FieldValue.arrayRemove([userId]),
    });
    
    // Remove from chat participants
    batch.update(_firestore.collection(Constants.chats).doc(groupId), {
      'participants': FieldValue.arrayRemove([userId]),
    });
    
    // Remove user from unreadCountByUser map in chat document
    final chatDoc = await _firestore.collection(Constants.chats).doc(groupId).get();
    if (chatDoc.exists) {
      Map<String, dynamic> unreadCountByUser = 
          Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
      
      // Remove the user's entry from the map
      unreadCountByUser.remove(userId);
      
      batch.update(_firestore.collection(Constants.chats).doc(groupId), {
        'unreadCountByUser': unreadCountByUser,
      });
    }
    
    await batch.commit();
  }

  // Delete a group completely
  Future<void> _deleteGroup(String groupId) async {
    final batch = _firestore.batch();
    
    // Delete group document
    batch.delete(_firestore.collection(Constants.groups).doc(groupId));
    
    // Delete chat document
    batch.delete(_firestore.collection(Constants.chats).doc(groupId));
    
    await batch.commit();
    
    // Delete all messages in the chat (we can't include this in the batch as we don't know all the message IDs)
    final messages = await _firestore
        .collection(Constants.chats)
        .doc(groupId)
        .collection(Constants.messages)
        .get();
    
    for (final message in messages.docs) {
      await message.reference.delete();
    }
  }

  // Approve a user's request to join
  Future<void> approveJoinRequest(String groupId, String userId) async {
    try {
      // First get the group to check member limit
      final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = GroupModel.fromMap(groupDoc.data()!);
      
      // Check if the group has reached its member limit
      if (group.hasReachedMemberLimit()) {
        throw Exception('This group has reached its maximum member limit of ${GroupModel.MAX_MEMBERS}');
      }
      
      final batch = _firestore.batch();
      
      // Remove from awaiting approval
      batch.update(_firestore.collection(Constants.groups).doc(groupId), {
        Constants.awaitingApprovalUIDs: FieldValue.arrayRemove([userId]),
      });
      
      // Add to members
      batch.update(_firestore.collection(Constants.groups).doc(groupId), {
        Constants.membersUIDs: FieldValue.arrayUnion([userId]),
      });
      
      // Add to chat participants
      batch.update(_firestore.collection(Constants.chats).doc(groupId), {
        'participants': FieldValue.arrayUnion([userId]),
      });
      
      // Get the chat document to update unreadCountByUser
      final chatDoc = await _firestore.collection(Constants.chats).doc(groupId).get();
      if (chatDoc.exists) {
        Map<String, dynamic> unreadCountByUser = 
            Map<String, dynamic>.from(chatDoc.data()?['unreadCountByUser'] ?? {});
        
        // Initialize unread count for the new member
        unreadCountByUser[userId] = 0;
        
        batch.update(_firestore.collection(Constants.chats).doc(groupId), {
          'unreadCountByUser': unreadCountByUser,
        });
      }
      
      await batch.commit();
      
      // Send a welcome message to the group
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Get user data to send a formatted welcome message
        final userDoc = await _firestore.collection(Constants.users).doc(userId).get();
        String userName = 'New member';
        if (userDoc.exists) {
          userName = userDoc.data()?[Constants.name] as String? ?? 'New member';
        }
        
        final messageId = const Uuid().v4();
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        
        await _firestore
            .collection(Constants.chats)
            .doc(groupId)
            .collection(Constants.messages)
            .doc(messageId)
            .set(MessageModel(
              messageId: messageId,
              senderUID: currentUser.uid,
              senderName: 'System',
              senderImage: '',
              message: '$userName joined the group',
              messageType: MessageEnum.text,
              timeSent: timestamp,
              messageStatus: MessageStatus.delivered,
              deletedBy: [],
            ).toMap());
        
        // Update last message in the chat
        await _firestore.collection(Constants.chats).doc(groupId).update({
          Constants.lastMessage: '$userName joined the group',
          Constants.messageType: MessageEnum.text.name,
          Constants.timeSent: timestamp,
          'lastMessageSender': currentUser.uid,
        });
      }
    } catch (e) {
      debugPrint('Error approving join request: $e');
      throw e.toString();
    }
  }

  // Reject a user's request to join
  Future<void> rejectJoinRequest(String groupId, String userId) async {
    try {
      await _firestore.collection(Constants.groups).doc(groupId).update({
        Constants.awaitingApprovalUIDs: FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('Error rejecting join request: $e');
      throw e.toString();
    }
  }

  // Add user as admin
  Future<void> addAdmin(String groupId, String userId) async {
    try {
      await _firestore.collection(Constants.groups).doc(groupId).update({
        Constants.adminsUIDs: FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error adding admin: $e');
      throw e.toString();
    }
  }

  // Remove user as admin
  Future<void> removeAdmin(String groupId, String userId) async {
    try {
      // Get group to check if there will be admins left
      final groupDoc = await _firestore.collection(Constants.groups).doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final group = GroupModel.fromMap(groupDoc.data()!);
      
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
    } catch (e) {
      debugPrint('Error removing admin: $e');
      throw e.toString();
    }
  }

  // Remove a member from the group
  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _removeUserFromGroup(groupId, userId);
      
      // Send a notification message to the group
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Get user data to send a formatted removal message
        final userDoc = await _firestore.collection(Constants.users).doc(userId).get();
        String userName = 'A member';
        if (userDoc.exists) {
          userName = userDoc.data()?[Constants.name] as String? ?? 'A member';
        }
        
        final messageId = const Uuid().v4();
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        
        await _firestore
            .collection(Constants.chats)
            .doc(groupId)
            .collection(Constants.messages)
            .doc(messageId)
            .set(MessageModel(
              messageId: messageId,
              senderUID: currentUser.uid,
              senderName: 'System',
              senderImage: '',
              message: '$userName was removed from the group',
              messageType: MessageEnum.text,
              timeSent: timestamp,
              messageStatus: MessageStatus.delivered,
              deletedBy: [],
            ).toMap());
        
        // Update last message in the chat
        await _firestore.collection(Constants.chats).doc(groupId).update({
          Constants.lastMessage: '$userName was removed from the group',
          Constants.messageType: MessageEnum.text.name,
          Constants.timeSent: timestamp,
          'lastMessageSender': currentUser.uid,
        });
      }
    } catch (e) {
      debugPrint('Error removing member: $e');
      throw e.toString();
    }
  }

  // Find public groups the user can join
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

  // Get group members as UserModel list
  Future<List<UserModel>> getGroupMembers(String groupId) async {
    try {
      // Get the group first
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

  // Get total unread count for all groups for a specific user
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
        // Get unread count from unreadCountByUser map
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

  // Update unread counts when a new message is sent
  Future<void> updateUnreadCountsForGroupMessage({
    required String groupId,
    required String senderUid,
  }) async {
    try {
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
          // Initialize with 0 if not present
          if (!unreadCountByUser.containsKey(memberId)) {
            unreadCountByUser[memberId] = 0;
          }
          // Increment the count
          unreadCountByUser[memberId] = (unreadCountByUser[memberId] as int? ?? 0) + 1;
        } else {
          // Ensure sender's count is 0
          unreadCountByUser[memberId] = 0;
        }
      }
      
      // Update the chat document
      await _firestore.collection(Constants.chats).doc(groupId).update({
        'unreadCountByUser': unreadCountByUser,
        // For backward compatibility
        'unreadCount': 1,
      });
    } catch (e) {
      debugPrint('Error updating unread counts for group message: $e');
    }
  }

  // Search for groups by name
  Future<List<GroupModel>> searchGroupsByName(String query) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Unfortunately Firestore doesn't support case insensitive search directly
      // We'll need to fetch groups that start with the query (case sensitive)
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
}

// Provider for the group repository
final groupRepositoryProvider = Provider((ref) {
  return GroupRepository(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});