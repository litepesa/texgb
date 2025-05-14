import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
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

  // Upload status to Firestore
  Future<void> createStatus({
    required File? mediaFile,
    required StatusType type,
    required String content,
    required UserModel currentUser,
    required StatusPrivacyType privacyType,
    required List<String> privacyUIDs,
    String? caption,
  }) async {
    try {
      String statusId = const Uuid().v4();
      String? mediaUrl;
      
      // Upload media file if provided
      if (mediaFile != null && type != StatusType.text) {
        mediaUrl = await _uploadStatusMedia(
          file: mediaFile,
          uid: currentUser.uid,
          statusId: statusId,
          type: type,
        );
      }

      // Create status metadata for different types
      Map<String, dynamic> metadata = {};
      if (type == StatusType.image || type == StatusType.video) {
        metadata = {
          'width': 0, // Will be updated with real values in the future
          'height': 0,
          'duration': type == StatusType.video ? 0 : null,
        };
      } else if (type == StatusType.link) {
        // For link type, additional metadata could be stored
        metadata = {
          'url': content,
          'title': '',
          'description': '',
        };
      }

      // Create status model
      final status = StatusModel(
        statusId: statusId,
        uid: currentUser.uid,
        username: currentUser.name,
        userImage: currentUser.image,
        content: mediaUrl ?? content, // Use media URL for media types
        type: type,
        timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
        seenBy: [currentUser.uid], // Creator has seen their own status
        privacyType: privacyType,
        privacyUIDs: privacyUIDs,
        metadata: metadata,
        caption: caption,
      );

      // Save to Firestore
      await firestore.collection(Constants.statusPosts).doc(statusId).set(status.toMap());
    } catch (e) {
      debugPrint('Error creating status: $e');
      rethrow;
    }
  }
  
  // Upload media file to Firebase Storage
  Future<String> _uploadStatusMedia({
    required File file, 
    required String uid, 
    required String statusId,
    required StatusType type,
  }) async {
    try {
      String path = '${Constants.statusFiles}/$uid/$statusId';
      if (type == StatusType.image) {
        path += '.jpg';
      } else if (type == StatusType.video) {
        path += '.mp4';
      }
      
      return await storeFileToStorage(file: file, reference: path);
    } catch (e) {
      debugPrint('Error uploading status media: $e');
      rethrow;
    }
  }

  // Get statuses that a user can view
  Stream<List<StatusModel>> getStatusesForUser(UserModel currentUser) {
    return firestore
        .collection(Constants.statusPosts)
        .where('timestamp', isGreaterThan: _getStatusCutoffTime())
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          List<StatusModel> statuses = [];
          
          for (var doc in snapshot.docs) {
            final status = StatusModel.fromMap(doc.data());
            
            // Check if user can view this status
            if (status.canViewStatus(currentUser.uid, currentUser.contactsUIDs)) {
              statuses.add(status);
            }
          }
          
          return statuses;
        });
  }
  
  // Get statuses for a specific user 
  Stream<List<StatusModel>> getUserStatuses(String userId) {
    return firestore
        .collection(Constants.statusPosts)
        .where(Constants.uid, isEqualTo: userId)
        .where('timestamp', isGreaterThan: _getStatusCutoffTime())
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          List<StatusModel> statuses = [];
          
          for (var doc in snapshot.docs) {
            statuses.add(StatusModel.fromMap(doc.data()));
          }
          
          return statuses;
        });
  }
  
  // Get current user's statuses
  Stream<List<StatusModel>> getMyStatuses() {
    final userId = auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    
    return getUserStatuses(userId);
  }
  
  // Get timestamp for 24 hours ago (for status expiry)
  String _getStatusCutoffTime() {
    final DateTime cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return cutoff.millisecondsSinceEpoch.toString();
  }
  
  // Mark a status as seen by current user
  Future<void> markStatusAsSeen(String statusId) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) return;
    
    try {
      await firestore.collection(Constants.statusPosts).doc(statusId).update({
        'seenBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error marking status as seen: $e');
    }
  }
  
  // Delete a status
  Future<void> deleteStatus(String statusId) async {
    try {
      await firestore.collection(Constants.statusPosts).doc(statusId).delete();
    } catch (e) {
      debugPrint('Error deleting status: $e');
      rethrow;
    }
  }
  
  // Send a direct reply to a status
  Future<void> replyToStatus({
    required StatusModel status, 
    required String message,
    required UserModel currentUser,
  }) async {
    try {
      final chatId = _generateChatId(currentUser.uid, status.uid);
      
      // Create the message with status context
      final Map<String, dynamic> messageData = {
        Constants.messageId: const Uuid().v4(),
        Constants.senderUID: currentUser.uid,
        Constants.senderName: currentUser.name,
        Constants.senderImage: currentUser.image,
        Constants.message: message,
        Constants.messageType: MessageEnum.text.name,
        Constants.timeSent: DateTime.now().millisecondsSinceEpoch.toString(),
        Constants.isSeen: false,
        'statusContext': {
          'statusId': status.statusId,
          'statusType': status.type.name,
          'statusContent': status.content,
          'statusCaption': status.caption,
        },
        Constants.isSeenBy: [currentUser.uid],
        Constants.deletedBy: [],
      };
      
      // Store the message in the chat
      await firestore
          .collection(Constants.chats)
          .doc(chatId)
          .collection(Constants.messages)
          .doc(messageData[Constants.messageId])
          .set(messageData);
          
      // Update chat with latest message
      await firestore.collection(Constants.chats).doc(chatId).set({
        'id': chatId,
        Constants.contactUID: status.uid,
        Constants.contactName: status.username,
        Constants.contactImage: status.userImage,
        Constants.lastMessage: message,
        Constants.messageType: MessageEnum.text.name,
        Constants.timeSent: messageData[Constants.timeSent],
        'unreadCount': FieldValue.increment(1),
        'isGroup': false,
      }, SetOptions(merge: true));
      
    } catch (e) {
      debugPrint('Error replying to status: $e');
      rethrow;
    }
  }
  
  // Generate chat ID between two users
  String _generateChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort(); // Sort to ensure the same chat ID regardless of who initiates
    return '${ids[0]}_${ids[1]}';
  }
}