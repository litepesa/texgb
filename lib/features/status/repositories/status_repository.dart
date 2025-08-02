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

class StatusRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const String _statusCollection = 'status';
  static const String _statusStoragePath = 'status';

  StatusRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  // Create a new status
  Future<String> createStatus({
    required String userId,
    required String userName,
    required String userImage,
    required StatusType type,
    required String content,
    String? caption,
    String? backgroundColor,
    String? fontColor,
    String? fontFamily,
    StatusPrivacyType privacyType = StatusPrivacyType.all_contacts,
    List<String> allowedViewers = const [],
    List<String> excludedViewers = const [],
    File? mediaFile,
    String? musicUrl,
    String? musicTitle,
    String? musicArtist,
    Duration? musicDuration,
  }) async {
    try {
      final statusId = _firestore.collection(_statusCollection).doc().id;
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      String finalContent = content;
      Map<String, dynamic>? metadata;

      // Upload media file if provided
      if (mediaFile != null) {
        final extension = mediaFile.path.split('.').last.toLowerCase();
        final storageRef = _storage.ref().child(
          '$_statusStoragePath/$userId/$statusId.$extension'
        );

        // Add metadata for media files
        SettableMetadata? uploadMetadata;
        if (type == StatusType.video) {
          uploadMetadata = SettableMetadata(contentType: 'video/$extension');
        } else if (type == StatusType.image) {
          uploadMetadata = SettableMetadata(contentType: 'image/$extension');
        }

        final uploadTask = uploadMetadata != null 
            ? storageRef.putFile(mediaFile, uploadMetadata)
            : storageRef.putFile(mediaFile);

        final snapshot = await uploadTask;
        finalContent = await snapshot.ref.getDownloadURL();

        // Get file metadata
        final fileSize = await mediaFile.length();
        metadata = {
          'fileSize': fileSize,
          'fileName': mediaFile.path.split('/').last,
          'contentType': uploadMetadata?.contentType,
        };

        // Add video-specific metadata
        if (type == StatusType.video) {
          // You could add video duration, resolution, etc. here if needed
          metadata['isVideo'] = true;
        }
      }

      final status = StatusModel(
        statusId: statusId,
        userId: userId,
        userName: userName,
        userImage: userImage,
        type: type,
        content: finalContent,
        caption: caption,
        backgroundColor: backgroundColor,
        fontColor: fontColor,
        fontFamily: fontFamily,
        createdAt: now,
        expiresAt: expiresAt,
        privacyType: privacyType,
        allowedViewers: allowedViewers,
        excludedViewers: excludedViewers,
        musicUrl: musicUrl,
        musicTitle: musicTitle,
        musicArtist: musicArtist,
        musicDuration: musicDuration,
        metadata: metadata,
      );

      await _firestore
          .collection(_statusCollection)
          .doc(statusId)
          .set(status.toMap());

      return statusId;
    } catch (e) {
      debugPrint('Error creating status: $e');
      throw Exception('Failed to create status: $e');
    }
  }

  // Get all visible statuses for a user
  Stream<List<UserStatusGroup>> getStatusesStream({
    required String currentUserId,
    required List<String> userContacts,
  }) {
    return _firestore
        .collection(_statusCollection)
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: DateTime.now().millisecondsSinceEpoch)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final allStatuses = snapshot.docs
          .map((doc) => StatusModel.fromMap(doc.data()))
          .where((status) => 
            status.userId == currentUserId || // Include own statuses
            status.canUserView(currentUserId, userContacts) // Include visible statuses
          )
          .toList();

      // Group statuses by user
      final Map<String, List<StatusModel>> groupedStatuses = {};
      for (final status in allStatuses) {
        if (!groupedStatuses.containsKey(status.userId)) {
          groupedStatuses[status.userId] = [];
        }
        groupedStatuses[status.userId]!.add(status);
      }

      // Convert to UserStatusGroup list
      final List<UserStatusGroup> statusGroups = [];
      for (final entry in groupedStatuses.entries) {
        final userId = entry.key;
        final statuses = entry.value;
        
        if (statuses.isNotEmpty) {
          final firstStatus = statuses.first;
          statusGroups.add(UserStatusGroup(
            userId: userId,
            userName: firstStatus.userName,
            userImage: firstStatus.userImage,
            statuses: statuses,
            isMyStatus: userId == currentUserId,
          ));
        }
      }

      // Sort: My status first, then by latest status time
      statusGroups.sort((a, b) {
        if (a.isMyStatus && !b.isMyStatus) return -1;
        if (!a.isMyStatus && b.isMyStatus) return 1;
        
        final aLatest = a.latestStatus?.createdAt ?? DateTime(1970);
        final bLatest = b.latestStatus?.createdAt ?? DateTime(1970);
        return bLatest.compareTo(aLatest);
      });

      return statusGroups;
    });
  }

  // Get statuses for a specific user
  Future<List<StatusModel>> getUserStatuses(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_statusCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThan: DateTime.now().millisecondsSinceEpoch)
          .orderBy('expiresAt')
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => StatusModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting user statuses: $e');
      throw Exception('Failed to get user statuses: $e');
    }
  }

  // Mark status as viewed
  Future<void> markStatusAsViewed({
    required String statusId,
    required String viewerId,
  }) async {
    try {
      await _firestore
          .collection(_statusCollection)
          .doc(statusId)
          .update({
        'viewedBy': FieldValue.arrayUnion([viewerId]),
      });
    } catch (e) {
      debugPrint('Error marking status as viewed: $e');
      throw Exception('Failed to mark status as viewed: $e');
    }
  }

  // Delete a status
  Future<void> deleteStatus(String statusId) async {
    try {
      // Get status data first to delete associated files
      final statusDoc = await _firestore
          .collection(_statusCollection)
          .doc(statusId)
          .get();

      if (statusDoc.exists) {
        final status = StatusModel.fromMap(statusDoc.data()!);
        
        // Delete associated media files
        if (status.type == StatusType.image || status.type == StatusType.video) {
          try {
            final ref = _storage.refFromURL(status.content);
            await ref.delete();
          } catch (e) {
            debugPrint('Error deleting media file: $e');
            // Continue with status deletion even if file deletion fails
          }
        }

        // Mark status as inactive instead of deleting the document
        await _firestore
            .collection(_statusCollection)
            .doc(statusId)
            .update({'isActive': false});
      }
    } catch (e) {
      debugPrint('Error deleting status: $e');
      throw Exception('Failed to delete status: $e');
    }
  }

  // Get status privacy settings for a user
  Future<Map<String, dynamic>> getStatusPrivacySettings(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(Constants.users)
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return userData['statusPrivacySettings'] ?? {
          'defaultPrivacy': StatusPrivacyType.all_contacts.name,
          'allowedViewers': <String>[],
          'excludedViewers': <String>[],
          'mutedUsers': <String>[],
        };
      }
      
      return {
        'defaultPrivacy': StatusPrivacyType.all_contacts.name,
        'allowedViewers': <String>[],
        'excludedViewers': <String>[],
        'mutedUsers': <String>[],
      };
    } catch (e) {
      debugPrint('Error getting privacy settings: $e');
      throw Exception('Failed to get privacy settings: $e');
    }
  }

  // Update status privacy settings
  Future<void> updateStatusPrivacySettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await _firestore
          .collection(Constants.users)
          .doc(userId)
          .update({
        'statusPrivacySettings': settings,
      });
    } catch (e) {
      debugPrint('Error updating privacy settings: $e');
      throw Exception('Failed to update privacy settings: $e');
    }
  }

  // Clean up expired statuses (can be called periodically)
  Future<void> cleanupExpiredStatuses() async {
    try {
      final now = DateTime.now();
      final expiredQuery = await _firestore
          .collection(_statusCollection)
          .where('expiresAt', isLessThan: now.millisecondsSinceEpoch)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      
      for (final doc in expiredQuery.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      if (expiredQuery.docs.isNotEmpty) {
        await batch.commit();
        debugPrint('Cleaned up ${expiredQuery.docs.length} expired statuses');
      }
    } catch (e) {
      debugPrint('Error cleaning up expired statuses: $e');
    }
  }

  // Get status viewers
  Future<List<UserModel>> getStatusViewers({
    required String statusId,
    required List<String> userContacts,
  }) async {
    try {
      final statusDoc = await _firestore
          .collection(_statusCollection)
          .doc(statusId)
          .get();

      if (!statusDoc.exists) {
        throw Exception('Status not found');
      }

      final status = StatusModel.fromMap(statusDoc.data()!);
      final viewerIds = status.viewedBy;

      if (viewerIds.isEmpty) return [];

      // Get viewer details (batch query for better performance)
      final viewers = <UserModel>[];
      
      // Process in chunks to avoid Firestore limit
      for (int i = 0; i < viewerIds.length; i += 10) {
        final chunk = viewerIds.skip(i).take(10).toList();
        final userDocs = await _firestore
            .collection(Constants.users)
            .where('uid', whereIn: chunk)
            .get();
        
        viewers.addAll(
          userDocs.docs.map((doc) => UserModel.fromMap(doc.data()))
        );
      }

      return viewers;
    } catch (e) {
      debugPrint('Error getting status viewers: $e');
      throw Exception('Failed to get status viewers: $e');
    }
  }

  // Search statuses by content (for debugging/admin purposes)
  Future<List<StatusModel>> searchStatuses({
    required String query,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_statusCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final statuses = snapshot.docs
          .map((doc) => StatusModel.fromMap(doc.data()))
          .where((status) => 
            status.content.toLowerCase().contains(query.toLowerCase()) ||
            (status.caption?.toLowerCase().contains(query.toLowerCase()) ?? false)
          )
          .toList();

      return statuses;
    } catch (e) {
      debugPrint('Error searching statuses: $e');
      throw Exception('Failed to search statuses: $e');
    }
  }
}

// Repository provider
final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  return StatusRepository(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});