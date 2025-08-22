// lib/features/status/repositories/status_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:uuid/uuid.dart';

class StatusRepositoryException implements Exception {
  final String message;
  final String? code;
  
  StatusRepositoryException(this.message, {this.code});
  
  @override
  String toString() => 'StatusRepositoryException: $message';
}

class StatusRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const Uuid _uuid = Uuid();
  
  // Collection names
  static const String _statusCollection = 'status';
  static const String _statusViewsCollection = 'statusViews';
  
  StatusRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  // Create a new status update
  Future<void> createStatus({
    required UserModel user,
    required CreateStatusRequest request,
  }) async {
    try {
      final statusId = _uuid.v4();
      final updateId = _uuid.v4();
      
      String? mediaUrl;
      String? thumbnailUrl;
      
      // Upload media if provided
      if (request.mediaPath != null) {
        final file = File(request.mediaPath!);
        mediaUrl = await _uploadStatusMedia(file, updateId, request.type);
        
        // Generate thumbnail for videos
        if (request.type == StatusType.video) {
          thumbnailUrl = await _generateVideoThumbnail(file, updateId);
        } else if (request.type == StatusType.image) {
          thumbnailUrl = mediaUrl; // Use same URL for images
        }
      }
      
      final statusUpdate = StatusUpdate(
        id: updateId,
        type: request.type,
        content: request.content,
        mediaUrl: mediaUrl,
        thumbnailUrl: thumbnailUrl,
        timestamp: DateTime.now(),
        duration: request.duration ?? const Duration(seconds: 30),
        backgroundColor: request.backgroundColor,
        fontFamily: request.fontFamily,
        views: [],
        isExpired: false,
      );
      
      // Check if user already has a status document
      final statusDoc = await _firestore
          .collection(_statusCollection)
          .doc(user.uid)
          .get();
      
      if (statusDoc.exists) {
        // Add to existing status
        final existingStatus = StatusModel.fromMap(statusDoc.data()!);
        final updatedStatus = existingStatus.copyWith(
          updates: [...existingStatus.updates, statusUpdate],
          lastUpdated: DateTime.now(),
          privacy: request.privacy,
          allowedViewers: request.allowedViewers,
          excludedViewers: request.excludedViewers,
        );
        
        await _firestore
            .collection(_statusCollection)
            .doc(user.uid)
            .update(updatedStatus.toMap());
      } else {
        // Create new status document
        final newStatus = StatusModel(
          id: statusId,
          uid: user.uid,
          userName: user.name,
          userImage: user.image,
          phoneNumber: user.phoneNumber,
          updates: [statusUpdate],
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          privacy: request.privacy,
          allowedViewers: request.allowedViewers,
          excludedViewers: request.excludedViewers,
        );
        
        await _firestore
            .collection(_statusCollection)
            .doc(user.uid)
            .set(newStatus.toMap());
      }
      
      debugPrint('Status created successfully');
    } catch (e) {
      debugPrint('Error creating status: $e');
      throw StatusRepositoryException('Failed to create status: $e');
    }
  }

  // Get status updates for contacts
  Stream<List<StatusModel>> getContactsStatus(List<String> contactIds) {
    try {
      if (contactIds.isEmpty) {
        return Stream.value([]);
      }
      
      // Firestore 'in' query limitation - max 10 items
      if (contactIds.length <= 10) {
        return _firestore
            .collection(_statusCollection)
            .where('uid', whereIn: contactIds)
            .orderBy('lastUpdated', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => StatusModel.fromMap(doc.data()))
                .where((status) => status.activeUpdates.isNotEmpty)
                .toList());
      } else {
        // Handle more than 10 contacts by batching queries
        return _getBatchedContactsStatus(contactIds);
      }
    } catch (e) {
      debugPrint('Error getting contacts status: $e');
      throw StatusRepositoryException('Failed to get contacts status: $e');
    }
  }

  // Handle batched queries for more than 10 contacts
  Stream<List<StatusModel>> _getBatchedContactsStatus(List<String> contactIds) {
    const batchSize = 10;
    final batches = <List<String>>[];
    
    for (int i = 0; i < contactIds.length; i += batchSize) {
      final end = (i + batchSize < contactIds.length) ? i + batchSize : contactIds.length;
      batches.add(contactIds.sublist(i, end));
    }
    
    final streams = batches.map((batch) => 
      _firestore
          .collection(_statusCollection)
          .where('uid', whereIn: batch)
          .orderBy('lastUpdated', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => StatusModel.fromMap(doc.data()))
              .where((status) => status.activeUpdates.isNotEmpty)
              .toList())
    ).toList();
    
    // Combine all streams
    return streams.length == 1 
        ? streams.first
        : streams.reduce((stream1, stream2) => 
            stream1.asyncMap((list1) => 
              stream2.first.then((list2) => [...list1, ...list2])));
  }

  // Get user's own status
  Stream<StatusModel?> getUserStatus(String userId) {
    try {
      return _firestore
          .collection(_statusCollection)
          .doc(userId)
          .snapshots()
          .map((doc) => doc.exists ? StatusModel.fromMap(doc.data()!) : null);
    } catch (e) {
      debugPrint('Error getting user status: $e');
      throw StatusRepositoryException('Failed to get user status: $e');
    }
  }

  // View a status update
  Future<void> viewStatus({
    required String statusOwnerId,
    required String updateId,
    required UserModel viewer,
  }) async {
    try {
      final statusRef = _firestore.collection(_statusCollection).doc(statusOwnerId);
      
      await _firestore.runTransaction((transaction) async {
        final statusDoc = await transaction.get(statusRef);
        
        if (!statusDoc.exists) {
          throw StatusRepositoryException('Status not found');
        }
        
        final status = StatusModel.fromMap(statusDoc.data()!);
        final updateIndex = status.updates.indexWhere((u) => u.id == updateId);
        
        if (updateIndex == -1) {
          throw StatusRepositoryException('Status update not found');
        }
        
        final update = status.updates[updateIndex];
        
        // Check if user already viewed this update
        if (update.hasViewedBy(viewer.uid)) {
          return; // Already viewed
        }
        
        // Add view
        final newView = StatusView(
          viewerId: viewer.uid,
          viewerName: viewer.name,
          viewerImage: viewer.image,
          viewedAt: DateTime.now(),
        );
        
        final updatedUpdate = update.copyWith(
          views: [...update.views, newView],
        );
        
        final updatedUpdates = List<StatusUpdate>.from(status.updates);
        updatedUpdates[updateIndex] = updatedUpdate;
        
        final updatedStatus = status.copyWith(updates: updatedUpdates);
        
        transaction.update(statusRef, updatedStatus.toMap());
      });
      
      debugPrint('Status viewed successfully');
    } catch (e) {
      debugPrint('Error viewing status: $e');
      throw StatusRepositoryException('Failed to view status: $e');
    }
  }

  // Delete a status update
  Future<void> deleteStatusUpdate({
    required String userId,
    required String updateId,
  }) async {
    try {
      final statusRef = _firestore.collection(_statusCollection).doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final statusDoc = await transaction.get(statusRef);
        
        if (!statusDoc.exists) {
          throw StatusRepositoryException('Status not found');
        }
        
        final status = StatusModel.fromMap(statusDoc.data()!);
        final updateToDelete = status.updates.firstWhere(
          (u) => u.id == updateId,
          orElse: () => throw StatusRepositoryException('Update not found'),
        );
        
        // Delete media from storage if exists
        if (updateToDelete.mediaUrl != null) {
          await _deleteStatusMedia(updateToDelete.mediaUrl!);
        }
        
        // Remove update from list
        final updatedUpdates = status.updates.where((u) => u.id != updateId).toList();
        
        if (updatedUpdates.isEmpty) {
          // Delete entire status document if no updates left
          transaction.delete(statusRef);
        } else {
          // Update with remaining updates
          final updatedStatus = status.copyWith(
            updates: updatedUpdates,
            lastUpdated: DateTime.now(),
          );
          transaction.update(statusRef, updatedStatus.toMap());
        }
      });
      
      debugPrint('Status update deleted successfully');
    } catch (e) {
      debugPrint('Error deleting status update: $e');
      throw StatusRepositoryException('Failed to delete status update: $e');
    }
  }

  // Clean up expired status updates
  Future<void> cleanupExpiredStatus() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      
      final statusDocs = await _firestore
          .collection(_statusCollection)
          .where('lastUpdated', isLessThan: cutoffTime.millisecondsSinceEpoch)
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in statusDocs.docs) {
        final status = StatusModel.fromMap(doc.data());
        final activeUpdates = status.updates
            .where((update) => !update.hasExpired)
            .toList();
        
        if (activeUpdates.isEmpty) {
          // Delete entire status if no active updates
          batch.delete(doc.reference);
          
          // Delete associated media
          for (final update in status.updates) {
            if (update.mediaUrl != null) {
              await _deleteStatusMedia(update.mediaUrl!);
            }
          }
        } else {
          // Update with only active updates
          final updatedStatus = status.copyWith(
            updates: activeUpdates,
            lastUpdated: DateTime.now(),
          );
          batch.update(doc.reference, updatedStatus.toMap());
          
          // Delete expired media
          final expiredUpdates = status.updates
              .where((update) => update.hasExpired)
              .toList();
          
          for (final update in expiredUpdates) {
            if (update.mediaUrl != null) {
              await _deleteStatusMedia(update.mediaUrl!);
            }
          }
        }
      }
      
      await batch.commit();
      debugPrint('Expired status cleanup completed');
    } catch (e) {
      debugPrint('Error cleaning up expired status: $e');
    }
  }

  // Upload status media to Firebase Storage
  Future<String> _uploadStatusMedia(File file, String updateId, StatusType type) async {
    try {
      final fileName = '${updateId}_${DateTime.now().millisecondsSinceEpoch}';
      final storageRef = _storage.ref().child('status').child(fileName);
      
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading status media: $e');
      throw StatusRepositoryException('Failed to upload media: $e');
    }
  }

  // Generate video thumbnail (placeholder - would need video processing)
  Future<String?> _generateVideoThumbnail(File videoFile, String updateId) async {
    try {
      // This is a placeholder. In a real implementation, you would:
      // 1. Extract a frame from the video
      // 2. Upload the thumbnail to storage
      // 3. Return the download URL
      
      // For now, return null and handle in UI
      return null;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  // Delete media from Firebase Storage
  Future<void> _deleteStatusMedia(String mediaUrl) async {
    try {
      final ref = _storage.refFromURL(mediaUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting status media: $e');
      // Don't throw error for media deletion failures
    }
  }

  // Get status views for a specific update
  Future<List<StatusView>> getStatusViews({
    required String statusOwnerId,
    required String updateId,
  }) async {
    try {
      final statusDoc = await _firestore
          .collection(_statusCollection)
          .doc(statusOwnerId)
          .get();
      
      if (!statusDoc.exists) {
        return [];
      }
      
      final status = StatusModel.fromMap(statusDoc.data()!);
      final update = status.updates.firstWhere(
        (u) => u.id == updateId,
        orElse: () => throw StatusRepositoryException('Update not found'),
      );
      
      return update.views;
    } catch (e) {
      debugPrint('Error getting status views: $e');
      throw StatusRepositoryException('Failed to get status views: $e');
    }
  }

  // Add status reaction
  Future<void> addStatusReaction(StatusReaction reaction) async {
    try {
      // Store reactions in a separate collection for better querying
      await _firestore
          .collection('statusReactions')
          .doc(reaction.id)
          .set(reaction.toMap());
      
      debugPrint('Status reaction added successfully');
    } catch (e) {
      debugPrint('Error adding status reaction: $e');
      throw StatusRepositoryException('Failed to add status reaction: $e');
    }
  }

  // Remove status reaction
  Future<void> removeStatusReaction({
    required String statusId,
    required String statusUpdateId,
    required String userId,
  }) async {
    try {
      // Find and delete the user's reaction for this status update
      final reactionsQuery = await _firestore
          .collection('statusReactions')
          .where('statusUpdateId', isEqualTo: statusUpdateId)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in reactionsQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      debugPrint('Status reaction removed successfully');
    } catch (e) {
      debugPrint('Error removing status reaction: $e');
      throw StatusRepositoryException('Failed to remove status reaction: $e');
    }
  }

  // Get status reactions for a specific update
  Future<List<StatusReaction>> getStatusReactions(String statusUpdateId) async {
    try {
      final reactionsSnapshot = await _firestore
          .collection('statusReactions')
          .where('statusUpdateId', isEqualTo: statusUpdateId)
          .orderBy('timestamp', descending: false)
          .get();

      return reactionsSnapshot.docs
          .map((doc) => StatusReaction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting status reactions: $e');
      throw StatusRepositoryException('Failed to get status reactions: $e');
    }
  }

  // Get status reactions stream for real-time updates
  Stream<List<StatusReaction>> getStatusReactionsStream(String statusUpdateId) {
    try {
      return _firestore
          .collection('statusReactions')
          .where('statusUpdateId', isEqualTo: statusUpdateId)
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => StatusReaction.fromMap(doc.data()))
              .toList());
    } catch (e) {
      debugPrint('Error streaming status reactions: $e');
      return Stream.error(StatusRepositoryException('Failed to stream status reactions: $e'));
    }
  }

  // Update status privacy settings
  Future<void> updateStatusPrivacy({
    required String userId,
    required StatusPrivacyType privacy,
    List<String> allowedViewers = const [],
    List<String> excludedViewers = const [],
  }) async {
    try {
      final statusRef = _firestore.collection(_statusCollection).doc(userId);
      
      await statusRef.update({
        'privacy': privacy.name,
        'allowedViewers': allowedViewers,
        'excludedViewers': excludedViewers,
      });
      
      debugPrint('Status privacy updated successfully');
    } catch (e) {
      debugPrint('Error updating status privacy: $e');
      throw StatusRepositoryException('Failed to update status privacy: $e');
    }
  }

  // Check if user can view status based on privacy settings
  bool canViewStatus(StatusModel status, String viewerId, List<String> userContacts) {
    // Owner can always view their own status
    if (status.uid == viewerId) {
      return true;
    }
    
    switch (status.privacy) {
      case StatusPrivacyType.all_contacts:
        return userContacts.contains(status.uid);
      
      case StatusPrivacyType.except:
        return userContacts.contains(status.uid) && 
               !status.excludedViewers.contains(viewerId);
      
      case StatusPrivacyType.only:
        return status.allowedViewers.contains(viewerId);
    }
  }

  // Get filtered status based on privacy
  Stream<List<StatusModel>> getFilteredContactsStatus({
    required List<String> contactIds,
    required String currentUserId,
  }) {
    return getContactsStatus(contactIds).map((statusList) {
      return statusList.where((status) => 
        canViewStatus(status, currentUserId, contactIds)).toList();
    });
  }
}

// Provider for StatusRepository
final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  return StatusRepository(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});