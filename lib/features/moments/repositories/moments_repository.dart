// lib/features/moments/repositories/moments_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/models/moment_comment_model.dart';

class MomentsRepositoryException implements Exception {
  final String message;
  const MomentsRepositoryException(this.message);
  
  @override
  String toString() => 'MomentsRepositoryException: $message';
}

abstract class MomentsRepository {
  Future<String> createMoment(MomentModel moment, {File? videoFile, List<File>? imageFiles});
  Future<void> deleteMoment(String momentId, String authorId);
  Future<void> likeMoment(String momentId, String userId, bool isLiked);
  Future<void> addComment(MomentCommentModel comment);
  Future<void> deleteComment(String commentId, String authorId);
  Future<void> likeComment(String commentId, String userId, bool isLiked);
  Future<void> recordView(String momentId, String userId);
  Stream<List<MomentModel>> getMomentsStream(String userId, List<String> userContacts);
  Stream<List<MomentModel>> getUserMomentsStream(String userId);
  Stream<List<MomentCommentModel>> getMomentCommentsStream(String momentId);
  Future<List<MomentModel>> getExpiredMoments();
  Future<void> cleanupExpiredMoments();
}

class FirebaseMomentsRepository implements MomentsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<String> createMoment(
    MomentModel moment, {
    File? videoFile,
    List<File>? imageFiles,
  }) async {
    try {
      final momentId = const Uuid().v4();
      final batch = _firestore.batch();
      
      // Upload media files
      String? videoUrl;
      String? videoThumbnail;
      List<String> imageUrls = [];

      if (moment.type == MomentType.video && videoFile != null) {
        // Upload video
        videoUrl = await _uploadVideoFile(videoFile, momentId);
        
        // Generate and upload thumbnail
        videoThumbnail = await _generateAndUploadThumbnail(videoFile, momentId);
      } else if (moment.type == MomentType.images && imageFiles != null && imageFiles.isNotEmpty) {
        // Upload images
        imageUrls = await _uploadImageFiles(imageFiles, momentId);
      }

      // Create moment document
      final momentDoc = _firestore.collection(Constants.moments).doc(momentId);
      final updatedMoment = moment.copyWith(
        id: momentId,
        videoUrl: videoUrl,
        videoThumbnail: videoThumbnail,
        imageUrls: imageUrls,
      );

      batch.set(momentDoc, updatedMoment.toMap());

      // Update user's moments count (optional)
      final userDoc = _firestore.collection(Constants.users).doc(moment.authorId);
      batch.update(userDoc, {
        'momentsCount': FieldValue.increment(1),
      });

      await batch.commit();
      return momentId;
    } catch (e) {
      throw MomentsRepositoryException('Failed to create moment: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteMoment(String momentId, String authorId) async {
    try {
      final batch = _firestore.batch();
      
      // Get moment document
      final momentDoc = await _firestore.collection(Constants.moments).doc(momentId).get();
      if (!momentDoc.exists) {
        throw MomentsRepositoryException('Moment not found');
      }

      final moment = MomentModel.fromMap(momentDoc.data()!);
      
      // Check if user is authorized to delete
      if (moment.authorId != authorId) {
        throw MomentsRepositoryException('Not authorized to delete this moment');
      }

      // Mark moment as inactive instead of deleting (to preserve comments/likes data)
      batch.update(momentDoc.reference, {'isActive': false});

      // Delete media files from storage
      await _deleteMomentMedia(moment);

      // Update user's moments count
      final userDoc = _firestore.collection(Constants.users).doc(authorId);
      batch.update(userDoc, {
        'momentsCount': FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      throw MomentsRepositoryException('Failed to delete moment: ${e.toString()}');
    }
  }

  @override
  Future<void> likeMoment(String momentId, String userId, bool isLiked) async {
    try {
      final batch = _firestore.batch();
      final momentDoc = _firestore.collection(Constants.moments).doc(momentId);
      
      if (isLiked) {
        batch.update(momentDoc, {
          'likedBy': FieldValue.arrayUnion([userId]),
          Constants.momentLikesCount: FieldValue.increment(1),
        });
      } else {
        batch.update(momentDoc, {
          'likedBy': FieldValue.arrayRemove([userId]),
          Constants.momentLikesCount: FieldValue.increment(-1),
        });
      }

      await batch.commit();
    } catch (e) {
      throw MomentsRepositoryException('Failed to update like: ${e.toString()}');
    }
  }

  @override
  Future<void> addComment(MomentCommentModel comment) async {
    try {
      final batch = _firestore.batch();
      
      // Add comment
      final commentDoc = _firestore.collection(Constants.momentComments).doc(comment.id);
      batch.set(commentDoc, comment.toMap());

      // Update moment's comment count
      final momentDoc = _firestore.collection(Constants.moments).doc(comment.momentId);
      batch.update(momentDoc, {
        Constants.momentCommentsCount: FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      throw MomentsRepositoryException('Failed to add comment: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteComment(String commentId, String authorId) async {
    try {
      final commentDoc = await _firestore.collection(Constants.momentComments).doc(commentId).get();
      if (!commentDoc.exists) {
        throw MomentsRepositoryException('Comment not found');
      }

      final comment = MomentCommentModel.fromMap(commentDoc.data()!);
      
      // Check authorization
      if (comment.authorId != authorId) {
        throw MomentsRepositoryException('Not authorized to delete this comment');
      }

      final batch = _firestore.batch();
      
      // Delete comment
      batch.delete(commentDoc.reference);

      // Update moment's comment count
      final momentDoc = _firestore.collection(Constants.moments).doc(comment.momentId);
      batch.update(momentDoc, {
        Constants.momentCommentsCount: FieldValue.increment(-1),
      });

      await batch.commit();
    } catch (e) {
      throw MomentsRepositoryException('Failed to delete comment: ${e.toString()}');
    }
  }

  @override
  Future<void> likeComment(String commentId, String userId, bool isLiked) async {
    try {
      final commentDoc = _firestore.collection(Constants.momentComments).doc(commentId);
      
      if (isLiked) {
        await commentDoc.update({
          'likedBy': FieldValue.arrayUnion([userId]),
          Constants.likesCount: FieldValue.increment(1),
        });
      } else {
        await commentDoc.update({
          'likedBy': FieldValue.arrayRemove([userId]),
          Constants.likesCount: FieldValue.increment(-1),
        });
      }
    } catch (e) {
      throw MomentsRepositoryException('Failed to update comment like: ${e.toString()}');
    }
  }

  @override
  Future<void> recordView(String momentId, String userId) async {
    try {
      await _firestore.collection(Constants.moments).doc(momentId).update({
        'viewedBy': FieldValue.arrayUnion([userId]),
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Don't throw error for view recording failures
      print('Failed to record view: ${e.toString()}');
    }
  }

  @override
  Stream<List<MomentModel>> getMomentsStream(String userId, List<String> userContacts) {
    return _firestore
        .collection(Constants.moments)
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy(Constants.momentCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MomentModel.fromMap(doc.data()))
          .where((moment) => moment.isVisibleTo(userId, userContacts))
          .toList();
    });
  }

  @override
  Stream<List<MomentModel>> getUserMomentsStream(String userId) {
    return _firestore
        .collection(Constants.moments)
        .where(Constants.userId, isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy(Constants.momentCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MomentModel.fromMap(doc.data())).toList();
    });
  }

  @override
  Stream<List<MomentCommentModel>> getMomentCommentsStream(String momentId) {
    return _firestore
        .collection(Constants.momentComments)
        .where(Constants.momentId, isEqualTo: momentId)
        .orderBy(Constants.createdAt, descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MomentCommentModel.fromMap(doc.data())).toList();
    });
  }

  @override
  Future<List<MomentModel>> getExpiredMoments() async {
    try {
      final snapshot = await _firestore
          .collection(Constants.moments)
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      return snapshot.docs.map((doc) => MomentModel.fromMap(doc.data())).toList();
    } catch (e) {
      throw MomentsRepositoryException('Failed to get expired moments: ${e.toString()}');
    }
  }

  @override
  Future<void> cleanupExpiredMoments() async {
    try {
      final expiredMoments = await getExpiredMoments();
      final batch = _firestore.batch();

      for (final moment in expiredMoments) {
        final momentDoc = _firestore.collection(Constants.moments).doc(moment.id);
        batch.update(momentDoc, {'isActive': false});
        
        // Delete media files
        await _deleteMomentMedia(moment);
      }

      await batch.commit();
    } catch (e) {
      throw MomentsRepositoryException('Failed to cleanup expired moments: ${e.toString()}');
    }
  }

  // Helper methods

  Future<String> _uploadVideoFile(File videoFile, String momentId) async {
    try {
      final ref = _storage.ref().child('moments/videos/$momentId.mp4');
      await ref.putFile(videoFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw MomentsRepositoryException('Failed to upload video: ${e.toString()}');
    }
  }

  Future<List<String>> _uploadImageFiles(List<File> imageFiles, String momentId) async {
    try {
      final List<String> urls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final ref = _storage.ref().child('moments/images/${momentId}_$i.jpg');
        await ref.putFile(imageFiles[i]);
        final url = await ref.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw MomentsRepositoryException('Failed to upload images: ${e.toString()}');
    }
  }

  Future<String?> _generateAndUploadThumbnail(File videoFile, String momentId) async {
    try {
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
        timeMs: 1000,
      );

      if (thumbnailData != null) {
        final ref = _storage.ref().child('moments/thumbnails/$momentId.jpg');
        await ref.putData(thumbnailData);
        return await ref.getDownloadURL();
      }
      
      return null;
    } catch (e) {
      print('Failed to generate thumbnail: ${e.toString()}');
      return null;
    }
  }

  Future<void> _deleteMomentMedia(MomentModel moment) async {
    try {
      // Delete video
      if (moment.hasVideo) {
        try {
          await _storage.refFromURL(moment.videoUrl!).delete();
        } catch (e) {
          print('Failed to delete video: ${e.toString()}');
        }
        
        // Delete thumbnail
        if (moment.videoThumbnail != null) {
          try {
            await _storage.refFromURL(moment.videoThumbnail!).delete();
          } catch (e) {
            print('Failed to delete thumbnail: ${e.toString()}');
          }
        }
      }

      // Delete images
      for (final imageUrl in moment.imageUrls) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print('Failed to delete image: ${e.toString()}');
        }
      }
    } catch (e) {
      print('Error deleting moment media: ${e.toString()}');
    }
  }
}