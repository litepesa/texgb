// lib/features/status/repositories/status_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';

class StatusRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  StatusRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  // Create a new status
  Future<StatusModel> createStatus({
    required UserModel user,
    required String statusType,
    required String content,
    XFile? mediaFile,
    String? backgroundColor,
    String? textColor,
    String? font,
    String privacyLevel = Constants.statusPrivacyContacts,
    List<String> allowedViewers = const [],
    List<String> excludedViewers = const [],
    int duration = Constants.statusDefaultDuration,
  }) async {
    try {
      final statusId = const Uuid().v4();
      final now = DateTime.now();
      final expiresAt = now.add(Duration(hours: duration));

      String? mediaUrl;
      String? thumbnailUrl;

      // Upload media if provided
      if (mediaFile != null) {
        mediaUrl = await _uploadStatusMedia(statusId, mediaFile, statusType);
        
        // Generate thumbnail for videos
        if (statusType == Constants.statusTypeVideo) {
          thumbnailUrl = await _generateVideoThumbnail(statusId, mediaFile);
        }
      }

      final status = StatusModel(
        statusId: statusId,
        uid: user.uid,
        userName: user.name,
        userImage: user.image,
        statusType: statusType,
        statusContent: content,
        statusMediaUrl: mediaUrl,
        statusThumbnail: thumbnailUrl,
        statusBackgroundColor: backgroundColor,
        statusTextColor: textColor,
        statusFont: font,
        statusCreatedAt: now,
        statusExpiresAt: expiresAt,
        statusPrivacyLevel: privacyLevel,
        statusAllowedViewers: allowedViewers,
        statusExcludedViewers: excludedViewers,
        statusViewsCount: 0,
        statusViewers: [],
        statusIsActive: true,
        statusMetadata: _generateMetadata(statusType, mediaFile),
      );

      await _firestore
          .collection(Constants.statuses)
          .doc(statusId)
          .set(status.toMap());

      debugPrint('Status created successfully: $statusId');
      return status;
    } catch (e) {
      debugPrint('Error creating status: $e');
      throw Exception('Failed to create status: $e');
    }
  }

  // Upload status media to Firebase Storage
  Future<String> _uploadStatusMedia(String statusId, XFile mediaFile, String statusType) async {
    try {
      final fileName = '${statusId}_${DateTime.now().millisecondsSinceEpoch}';
      final extension = mediaFile.path.split('.').last;
      
      String folderPath;
      switch (statusType) {
        case Constants.statusTypeImage:
          folderPath = Constants.statusImages;
          break;
        case Constants.statusTypeVideo:
          folderPath = Constants.statusVideos;
          break;
        default:
          throw Exception('Unsupported media type for upload');
      }

      final ref = _storage.ref().child(folderPath).child('$fileName.$extension');
      
      final uploadTask = await ref.putFile(File(mediaFile.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      debugPrint('Media uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading media: $e');
      throw Exception('Failed to upload media: $e');
    }
  }

  // Generate video thumbnail
  Future<String?> _generateVideoThumbnail(String statusId, XFile videoFile) async {
    try {
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );

      if (thumbnailData != null) {
        final fileName = '${statusId}_thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child(Constants.statusImages).child(fileName);
        
        final uploadTask = await ref.putData(thumbnailData);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        
        debugPrint('Thumbnail uploaded successfully: $downloadUrl');
        return downloadUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  // Generate metadata for status
  Map<String, dynamic> _generateMetadata(String statusType, XFile? mediaFile) {
    final metadata = <String, dynamic>{
      'createdBy': 'mobile_app',
      'version': '1.0',
    };

    if (mediaFile != null) {
      metadata['originalFileName'] = mediaFile.name;
      metadata['fileSize'] = File(mediaFile.path).lengthSync();
    }

    return metadata;
  }

  // Get statuses for contacts (stream)
  Stream<List<UserStatusGroup>> getContactsStatuses({
    required String currentUserId,
    required List<String> contactIds,
  }) {
    return _firestore
        .collection(Constants.statuses)
        .where(Constants.uid, whereIn: contactIds.isEmpty ? ['dummy'] : contactIds)
        .where(Constants.statusIsActive, isEqualTo: true)
        .orderBy(Constants.statusCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) {
          return _groupStatusesByUser(snapshot.docs, currentUserId);
        });
  }

  // Get my statuses (stream)
  Stream<List<StatusModel>> getMyStatuses(String userId) {
    return _firestore
        .collection(Constants.statuses)
        .where(Constants.uid, isEqualTo: userId)
        .where(Constants.statusIsActive, isEqualTo: true)
        .orderBy(Constants.statusCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => StatusModel.fromMap(doc.data()))
              .where((status) => !status.isExpired)
              .toList();
        });
  }

  // Get single status
  Future<StatusModel?> getStatus(String statusId) async {
    try {
      final doc = await _firestore
          .collection(Constants.statuses)
          .doc(statusId)
          .get();

      if (doc.exists) {
        return StatusModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting status: $e');
      return null;
    }
  }

  // Mark status as viewed
  Future<void> markStatusAsViewed({
    required String statusId,
    required String viewerId,
  }) async {
    try {
      await _firestore
          .collection(Constants.statuses)
          .doc(statusId)
          .update({
        Constants.statusViewers: FieldValue.arrayUnion([viewerId]),
        Constants.statusViewsCount: FieldValue.increment(1),
      });

      // Add to status views collection for analytics
      await _firestore
          .collection(Constants.statusViews)
          .add({
        Constants.statusId: statusId,
        Constants.uid: viewerId,
        Constants.timeSent: FieldValue.serverTimestamp(),
      });

      debugPrint('Status marked as viewed: $statusId by $viewerId');
    } catch (e) {
      debugPrint('Error marking status as viewed: $e');
    }
  }

  // Delete status
  Future<void> deleteStatus(String statusId) async {
    try {
      await _firestore
          .collection(Constants.statuses)
          .doc(statusId)
          .update({
        Constants.statusIsActive: false,
      });

      debugPrint('Status deleted: $statusId');
    } catch (e) {
      debugPrint('Error deleting status: $e');
      throw Exception('Failed to delete status: $e');
    }
  }

  // Update status privacy
  Future<void> updateStatusPrivacy({
    required String statusId,
    required String privacyLevel,
    List<String> allowedViewers = const [],
    List<String> excludedViewers = const [],
  }) async {
    try {
      await _firestore
          .collection(Constants.statuses)
          .doc(statusId)
          .update({
        Constants.statusPrivacyLevel: privacyLevel,
        Constants.statusAllowedViewers: allowedViewers,
        Constants.statusExcludedViewers: excludedViewers,
      });

      debugPrint('Status privacy updated: $statusId');
    } catch (e) {
      debugPrint('Error updating status privacy: $e');
      throw Exception('Failed to update status privacy: $e');
    }
  }

  // Get status viewers
  Future<List<String>> getStatusViewers(String statusId) async {
    try {
      final doc = await _firestore
          .collection(Constants.statuses)
          .doc(statusId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return List<String>.from(data[Constants.statusViewers] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Error getting status viewers: $e');
      return [];
    }
  }

  // Clean up expired statuses (call periodically)
  Future<void> cleanupExpiredStatuses() async {
    try {
      final now = DateTime.now();
      final expiredStatuses = await _firestore
          .collection(Constants.statuses)
          .where(Constants.statusExpiresAt, isLessThan: Timestamp.fromDate(now))
          .where(Constants.statusIsActive, isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredStatuses.docs) {
        batch.update(doc.reference, {Constants.statusIsActive: false});
      }

      await batch.commit();
      debugPrint('Cleaned up ${expiredStatuses.docs.length} expired statuses');
    } catch (e) {
      debugPrint('Error cleaning up expired statuses: $e');
    }
  }

  // Group statuses by user
  List<UserStatusGroup> _groupStatusesByUser(List<QueryDocumentSnapshot> docs, String currentUserId) {
    final Map<String, List<StatusModel>> userStatusMap = {};
    
    for (final doc in docs) {
      final status = StatusModel.fromMap(doc.data() as Map<String, dynamic>);
      
      // Skip expired statuses
      if (status.isExpired) continue;
      
      if (!userStatusMap.containsKey(status.uid)) {
        userStatusMap[status.uid] = [];
      }
      userStatusMap[status.uid]!.add(status);
    }

    return userStatusMap.entries.map((entry) {
      final statuses = entry.value;
      statuses.sort((a, b) => a.statusCreatedAt.compareTo(b.statusCreatedAt));
      
      final latestStatus = statuses.last;
      final hasUnviewed = statuses.any((status) => !status.hasUserViewed(currentUserId));
      final unviewedCount = statuses.where((status) => !status.hasUserViewed(currentUserId)).length;

      return UserStatusGroup(
        uid: entry.key,
        userName: latestStatus.userName,
        userImage: latestStatus.userImage,
        statuses: statuses,
        lastStatusTime: latestStatus.statusCreatedAt,
        hasUnviewedStatus: hasUnviewed,
        unviewedCount: unviewedCount,
      );
    }).toList()
      ..sort((a, b) {
        // Sort by unviewed first, then by latest status time
        if (a.hasUnviewedStatus && !b.hasUnviewedStatus) return -1;
        if (!a.hasUnviewedStatus && b.hasUnviewedStatus) return 1;
        return b.lastStatusTime.compareTo(a.lastStatusTime);
      });
  }

  // Search statuses (for admin purposes)
  Future<List<StatusModel>> searchStatuses({
    String? userId,
    String? statusType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection(Constants.statuses);
      
      if (userId != null) {
        query = query.where(Constants.uid, isEqualTo: userId);
      }
      
      if (statusType != null) {
        query = query.where(Constants.statusType, isEqualTo: statusType);
      }
      
      if (startDate != null) {
        query = query.where(Constants.statusCreatedAt, 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where(Constants.statusCreatedAt, 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy(Constants.statusCreatedAt, descending: true);
      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => StatusModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error searching statuses: $e');
      return [];
    }
  }
}

// Provider for StatusRepository
final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  return StatusRepository(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
});