import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/models/status_reply_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:uuid/uuid.dart';

// Provider for the repository
final statusRepositoryProvider = Provider((ref) => StatusRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
      storage: FirebaseStorage.instance,
    ));

class StatusRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FirebaseStorage storage;

  StatusRepository({
    required this.firestore,
    required this.auth,
    required this.storage,
  });

  // Create a text status
  Future<StatusModel> createTextStatus({
    required UserModel currentUser,
    required String text,
    required StatusPrivacyType privacyType,
    List<String> visibleTo = const [],
    List<String> hiddenFrom = const [],
  }) async {
    try {
      final statusId = const Uuid().v4();
      final createdAt = DateTime.now().millisecondsSinceEpoch.toString();
      // Status expires after 24 hours
      final expiresAt = DateTime.now()
          .add(const Duration(hours: 24))
          .millisecondsSinceEpoch
          .toString();

      final status = StatusModel(
        statusId: statusId,
        userId: currentUser.uid,
        userName: currentUser.name,
        userImage: currentUser.image,
        content: text,
        type: StatusType.text,
        createdAt: createdAt,
        expiresAt: expiresAt,
        viewedBy: [], // Initially no one has viewed it
        privacyType: privacyType,
        visibleTo: visibleTo,
        hiddenFrom: hiddenFrom,
      );

      // Add status to Firestore
      await firestore
          .collection(Constants.statusPosts)
          .doc(statusId)
          .set(status.toMap());

      return status;
    } catch (e) {
      debugPrint('Error creating text status: $e');
      throw Exception('Failed to create status: $e');
    }
  }

  // Create a media status (image or video)
  Future<StatusModel> createMediaStatus({
    required UserModel currentUser,
    required File mediaFile,
    required StatusType mediaType,
    String caption = '',
    required StatusPrivacyType privacyType,
    List<String> visibleTo = const [],
    List<String> hiddenFrom = const [],
  }) async {
    try {
      final statusId = const Uuid().v4();
      final createdAt = DateTime.now().millisecondsSinceEpoch.toString();
      final expiresAt = DateTime.now()
          .add(const Duration(hours: 24))
          .millisecondsSinceEpoch
          .toString();

      // Upload media file to storage
      final mediaUrl = await storeFileToStorage(
        file: mediaFile,
        reference: '${Constants.statusFiles}/${currentUser.uid}/$statusId',
      );

      final status = StatusModel(
        statusId: statusId,
        userId: currentUser.uid,
        userName: currentUser.name,
        userImage: currentUser.image,
        content: mediaUrl,
        type: mediaType,
        caption: caption,
        createdAt: createdAt,
        expiresAt: expiresAt,
        viewedBy: [],
        privacyType: privacyType,
        visibleTo: visibleTo,
        hiddenFrom: hiddenFrom,
      );

      // Add status to Firestore
      await firestore
          .collection(Constants.statusPosts)
          .doc(statusId)
          .set(status.toMap());

      return status;
    } catch (e) {
      debugPrint('Error creating media status: $e');
      throw Exception('Failed to create status: $e');
    }
  }

  // Get all active statuses for the current user
  Stream<List<StatusModel>> getMyStatuses() {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    // Get only statuses that haven't expired
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    return firestore
        .collection(Constants.statusPosts)
        .where(Constants.userId, isEqualTo: userId)
        .where('expiresAt', isGreaterThan: now)
        .where('isActive', isEqualTo: true)
        .orderBy('expiresAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StatusModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get statuses from contacts
  Stream<List<UserStatusSummary>> getContactsStatuses(
      List<String> contactsUIDs, List<String> mutedUsers) {
    if (contactsUIDs.isEmpty) {
      return Stream.value([]);
    }

    // Filter out muted users
    final visibleContacts =
        contactsUIDs.where((uid) => !mutedUsers.contains(uid)).toList();

    if (visibleContacts.isEmpty) {
      return Stream.value([]);
    }

    final now = DateTime.now().millisecondsSinceEpoch.toString();
    return firestore
        .collection(Constants.statusPosts)
        .where(Constants.userId, whereIn: visibleContacts)
        .where('expiresAt', isGreaterThan: now)
        .where('isActive', isEqualTo: true)
        .orderBy('expiresAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // Convert status posts to status models
      final allStatuses =
          snapshot.docs.map((doc) => StatusModel.fromMap(doc.data())).toList();

      // Group statuses by userId
      final Map<String, List<StatusModel>> statusesByUser = {};
      for (final status in allStatuses) {
        if (!statusesByUser.containsKey(status.userId)) {
          statusesByUser[status.userId] = [];
        }
        statusesByUser[status.userId]!.add(status);
      }

      // Convert to UserStatusSummary list
      List<UserStatusSummary> summaries = [];
      statusesByUser.forEach((userId, statuses) {
        // Skip if no statuses for this user
        if (statuses.isEmpty) return;

        // Get latest status time
        final latestTimestamp = statuses.map((s) => int.parse(s.createdAt)).reduce((max, time) => time > max ? time : max);
        final latestTime = DateTime.fromMillisecondsSinceEpoch(latestTimestamp);

        // Check if user has any unviewed statuses
        final currentUserId = auth.currentUser?.uid ?? '';
        final hasUnviewed = statuses.any((status) => !status.viewedBy.contains(currentUserId));

        summaries.add(UserStatusSummary(
          userId: userId,
          userName: statuses.first.userName,
          userImage: statuses.first.userImage,
          statuses: statuses,
          hasUnviewed: hasUnviewed,
          latestStatusTime: latestTime,
        ));
      });

      // Sort summaries by whether they have unviewed statuses and then by latest status time
      summaries.sort((a, b) {
        if (a.hasUnviewed && !b.hasUnviewed) return -1;
        if (!a.hasUnviewed && b.hasUnviewed) return 1;
        return b.latestStatusTime.compareTo(a.latestStatusTime);
      });

      return summaries;
    });
  }

  // Mark status as viewed
  Future<void> markStatusAsViewed(String statusId) async {
    final currentUserId = auth.currentUser?.uid;
    if (currentUserId == null) return;

    await firestore.collection(Constants.statusPosts).doc(statusId).update({
      'viewedBy': FieldValue.arrayUnion([currentUserId]),
      Constants.statusViewCount: FieldValue.increment(1),
    });
  }

  // Delete a status
  Future<void> deleteStatus(String statusId) async {
    final currentUserId = auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Check if status belongs to current user
    final statusDoc = await firestore.collection(Constants.statusPosts).doc(statusId).get();
    if (statusDoc.exists) {
      final status = StatusModel.fromMap(statusDoc.data()!);
      if (status.userId == currentUserId) {
        // Set status as inactive rather than deleting
        await firestore.collection(Constants.statusPosts).doc(statusId).update({
          'isActive': false,
        });
      } else {
        throw Exception('You can only delete your own statuses');
      }
    }
  }

  // Get statuses by ID (for viewing a specific status)
  Future<StatusModel?> getStatusById(String statusId) async {
    try {
      final statusDoc = await firestore.collection(Constants.statusPosts).doc(statusId).get();
      if (statusDoc.exists) {
        return StatusModel.fromMap(statusDoc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting status by ID: $e');
      return null;
    }
  }
  
  // Update status privacy settings
  Future<void> updateStatusPrivacy({
    required String statusId,
    required StatusPrivacyType privacyType,
    List<String>? visibleTo,
    List<String>? hiddenFrom,
  }) async {
    try {
      final currentUserId = auth.currentUser?.uid;
      if (currentUserId == null) return;
      
      // Check if status belongs to current user
      final statusDoc = await firestore.collection(Constants.statusPosts).doc(statusId).get();
      if (statusDoc.exists) {
        final status = StatusModel.fromMap(statusDoc.data()!);
        if (status.userId == currentUserId) {
          final Map<String, dynamic> updateData = {
            'privacyType': privacyType.toString().split('.').last,
          };
          
          if (visibleTo != null) {
            updateData['visibleTo'] = visibleTo;
          }
          
          if (hiddenFrom != null) {
            updateData['hiddenFrom'] = hiddenFrom;
          }
          
          await firestore.collection(Constants.statusPosts).doc(statusId).update(updateData);
        } else {
          throw Exception('You can only update your own statuses');
        }
      }
    } catch (e) {
      debugPrint('Error updating status privacy: $e');
      throw Exception('Failed to update status privacy: $e');
    }
  }

  // Send a reply to a status
  Future<void> sendStatusReply({
    required String statusId,
    required String receiverId,
    required String message,
    required MessageEnum messageType,
    required UserModel currentUser,
    required String statusThumbnail,
    required StatusType statusType,
  }) async {
    try {
      final replyId = const Uuid().v4();
      final timeSent = DateTime.now().millisecondsSinceEpoch.toString();

      // Create reply model
      final reply = StatusReplyModel(
        replyId: replyId,
        statusId: statusId,
        senderId: currentUser.uid,
        senderName: currentUser.name,
        senderImage: currentUser.image,
        receiverId: receiverId,
        message: message,
        messageType: messageType,
        timeSent: timeSent,
        statusThumbnail: statusThumbnail,
        statusType: statusType,
      );

      // Step 1: Add reply to Firestore - complete this first
      await firestore
          .collection(Constants.statusReplies)
          .doc(replyId)
          .set(reply.toMap());
      
      // Create or get existing chat ID for direct message
      final chatId = generateChatId(currentUser.uid, receiverId);
      
      // Get recipient user data with error handling
      DocumentSnapshot? recipientDoc;
      try {
        recipientDoc = await firestore.collection(Constants.users).doc(receiverId).get();
        
        if (!recipientDoc.exists) {
          throw Exception('Recipient user not found');
        }
      } catch (e) {
        debugPrint('Error fetching recipient user: $e');
        // Create a basic reply without the chat functionality
        return;
      }
      
      final receiverUser = UserModel.fromMap(recipientDoc!.data()! as Map<String, dynamic>);
      
      // Prepare status preview text
      String statusPreview = 'Replied to your status';
      
      try {
        if (statusType == StatusType.text) {
          // For text statuses, include part of the text
          final statusDoc = await firestore.collection(Constants.statusPosts).doc(statusId).get();
          if (statusDoc.exists) {
            final status = StatusModel.fromMap(statusDoc.data()!);
            // Get first 20 chars of text status
            final previewText = status.content.length > 20 
                ? '${status.content.substring(0, 20)}...' 
                : status.content;
            statusPreview = 'Replied to your status: "$previewText"';
          }
        } else {
          // For media statuses
          statusPreview = 'Replied to your ${statusType.displayName.toLowerCase()} status';
        }
      } catch (e) {
        // If error occurs while getting status content, use the default preview
        debugPrint('Error getting status content: $e');
      }
      
      // Check if chat exists - wrap in try/catch to prevent errors
      try {
        final chatDoc = await firestore.collection(Constants.chats).doc(chatId).get();
        
        if (!chatDoc.exists) {
          // Create a new chat with status reply context
          await firestore.collection(Constants.chats).doc(chatId).set({
            'id': chatId,
            'participants': [currentUser.uid, receiverId],
            Constants.contactUID: receiverId,
            Constants.contactName: receiverUser.name,
            Constants.contactImage: receiverUser.image,
            Constants.lastMessage: statusPreview,
            Constants.messageType: MessageEnum.text.name,
            Constants.timeSent: timeSent,
            'unreadCount': 1,
            'isGroup': false,
          });
        } else {
          // Update existing chat with status reply context
          await firestore.collection(Constants.chats).doc(chatId).update({
            Constants.lastMessage: statusPreview,
            Constants.messageType: MessageEnum.text.name,
            Constants.timeSent: timeSent,
            'unreadCount': FieldValue.increment(1),
          });
        }
        
        // Now add the actual message to the chat
        final messageId = const Uuid().v4();
        
        // Create a message with status reply context
        final messageModel = MessageModel(
          messageId: messageId,
          senderUID: currentUser.uid,
          senderName: currentUser.name,
          senderImage: currentUser.image,
          message: message,
          messageType: messageType,
          timeSent: timeSent,
          //isSeen: false,
          repliedMessage: statusPreview, // Include context about the status
          repliedTo: receiverId,
          repliedMessageType: MessageEnum.text, // Status preview is always text
          //seenBy: [currentUser.uid],
          deletedBy: [],
        );
        
        // Add message to chat
        await firestore
            .collection(Constants.chats)
            .doc(chatId)
            .collection(Constants.messages)
            .doc(messageId)
            .set(messageModel.toMap());
      } catch (e) {
        // If chat creation fails, log but don't stop the process
        // We've already created the status reply, which is the main operation
        debugPrint('Error creating chat for status reply: $e');
      }
    } catch (e) {
      debugPrint('Error sending status reply: $e');
      throw Exception('Failed to send status reply: $e');
    }
  }

  // Helper method to generate a chat ID
  String generateChatId(String userId1, String userId2) {
    // Sort the IDs to ensure consistency
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}