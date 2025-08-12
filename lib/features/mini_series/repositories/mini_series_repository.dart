// lib/features/mini_series/repositories/mini_series_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/mini_series_model.dart';
import '../models/episode_model.dart';
import '../models/comment_model.dart';
import '../models/analytics_model.dart';

abstract class MiniSeriesRepository {
  // Series operations
  Future<String> createSeries(MiniSeriesModel series, File? coverImage);
  Future<void> updateSeries(MiniSeriesModel series, File? coverImage);
  Future<void> deleteSeries(String seriesId);
  Future<MiniSeriesModel?> getSeriesById(String seriesId);
  Future<List<MiniSeriesModel>> getSeriesByCreator(String creatorUID);
  Future<List<MiniSeriesModel>> getPublishedSeries({int limit = 20, String? lastSeriesId});
  Future<List<MiniSeriesModel>> searchSeries(String query);
  
  // Episode operations
  Future<String> createEpisode(EpisodeModel episode, File videoFile, File? thumbnailFile);
  Future<void> updateEpisode(EpisodeModel episode, File? videoFile, File? thumbnailFile);
  Future<void> deleteEpisode(String episodeId);
  Future<EpisodeModel?> getEpisodeById(String episodeId);
  Future<List<EpisodeModel>> getEpisodesBySeries(String seriesId);
  Future<void> reorderEpisodes(String seriesId, List<String> episodeIds);
  
  // Interaction operations
  Future<void> likeEpisode(String episodeId, String userId);
  Future<void> unlikeEpisode(String episodeId, String userId);
  Future<void> incrementEpisodeView(String episodeId, String userId);
  
  // Comment operations
  Future<String> addComment(EpisodeCommentModel comment);
  Future<void> deleteComment(String commentId);
  Future<List<EpisodeCommentModel>> getEpisodeComments(String episodeId, {int limit = 50});
  Future<void> likeComment(String commentId, String userId);
  Future<void> unlikeComment(String commentId, String userId);
  
  // Analytics operations
  Future<SeriesAnalyticsModel> getSeriesAnalytics(String seriesId);
  Future<void> updateAnalytics(String seriesId, Map<String, dynamic> data);
  
  // File operations
  Future<String> uploadVideo(File file, String path);
  Future<String> uploadImage(File file, String path);
  Future<void> deleteFile(String url);
}

class FirebaseMiniSeriesRepository implements MiniSeriesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String _seriesCollection = 'mini_series';
  final String _episodesCollection = 'episodes';
  final String _commentsCollection = 'episode_comments';
  final String _analyticsCollection = 'series_analytics';

  FirebaseMiniSeriesRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> createSeries(MiniSeriesModel series, File? coverImage) async {
    try {
      String seriesId = series.seriesId.isEmpty ? const Uuid().v4() : series.seriesId;
      
      // Upload cover image if provided
      String coverImageUrl = series.coverImageUrl;
      if (coverImage != null) {
        coverImageUrl = await uploadImage(coverImage, 'mini_series/covers/$seriesId');
      }
      
      final updatedSeries = series.copyWith(
        seriesId: seriesId,
        coverImageUrl: coverImageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _firestore
          .collection(_seriesCollection)
          .doc(seriesId)
          .set(updatedSeries.toMap());
      
      return seriesId;
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to create series: ${e.message}');
    }
  }

  @override
  Future<void> updateSeries(MiniSeriesModel series, File? coverImage) async {
    try {
      String coverImageUrl = series.coverImageUrl;
      
      // Upload new cover image if provided
      if (coverImage != null) {
        // Delete old cover image if it exists
        if (series.coverImageUrl.isNotEmpty) {
          await deleteFile(series.coverImageUrl);
        }
        coverImageUrl = await uploadImage(coverImage, 'mini_series/covers/${series.seriesId}');
      }
      
      final updatedSeries = series.copyWith(
        coverImageUrl: coverImageUrl,
        updatedAt: DateTime.now(),
      );
      
      await _firestore
          .collection(_seriesCollection)
          .doc(series.seriesId)
          .update(updatedSeries.toMap());
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to update series: ${e.message}');
    }
  }

  @override
  Future<void> deleteSeries(String seriesId) async {
    try {
      // Get all episodes for this series
      final episodesSnapshot = await _firestore
          .collection(_episodesCollection)
          .where('seriesId', isEqualTo: seriesId)
          .get();
      
      // Delete all episodes and their files
      for (var doc in episodesSnapshot.docs) {
        final episode = EpisodeModel.fromMap(doc.data());
        await deleteEpisode(episode.episodeId);
      }
      
      // Get series data to delete cover image
      final seriesDoc = await _firestore
          .collection(_seriesCollection)
          .doc(seriesId)
          .get();
      
      if (seriesDoc.exists) {
        final series = MiniSeriesModel.fromMap(seriesDoc.data()!);
        if (series.coverImageUrl.isNotEmpty) {
          await deleteFile(series.coverImageUrl);
        }
      }
      
      // Delete comments
      final commentsSnapshot = await _firestore
          .collection(_commentsCollection)
          .where('seriesId', isEqualTo: seriesId)
          .get();
      
      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete analytics
      await _firestore
          .collection(_analyticsCollection)
          .doc(seriesId)
          .delete();
      
      // Delete series
      await _firestore
          .collection(_seriesCollection)
          .doc(seriesId)
          .delete();
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to delete series: ${e.message}');
    }
  }

  @override
  Future<MiniSeriesModel?> getSeriesById(String seriesId) async {
    try {
      final doc = await _firestore
          .collection(_seriesCollection)
          .doc(seriesId)
          .get();
      
      if (!doc.exists) return null;
      
      return MiniSeriesModel.fromMap(doc.data()!);
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to get series: ${e.message}');
    }
  }

  @override
  Future<List<MiniSeriesModel>> getSeriesByCreator(String creatorUID) async {
    try {
      final querySnapshot = await _firestore
          .collection(_seriesCollection)
          .where('creatorUID', isEqualTo: creatorUID)
          .orderBy('updatedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => MiniSeriesModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to get creator series: ${e.message}');
    }
  }

  @override
  Future<List<MiniSeriesModel>> getPublishedSeries({int limit = 20, String? lastSeriesId}) async {
    try {
      Query query = _firestore
          .collection(_seriesCollection)
          .where('isPublished', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .limit(limit);
      
      if (lastSeriesId != null) {
        final lastDoc = await _firestore
            .collection(_seriesCollection)
            .doc(lastSeriesId)
            .get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => MiniSeriesModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to get published series: ${e.message}');
    }
  }

  @override
  Future<List<MiniSeriesModel>> searchSeries(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(_seriesCollection)
          .where('isPublished', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();
      
      // Filter locally since Firestore doesn't support text search
      return querySnapshot.docs
          .map((doc) => MiniSeriesModel.fromMap(doc.data()))
          .where((series) =>
              series.title.toLowerCase().contains(query.toLowerCase()) ||
              series.description.toLowerCase().contains(query.toLowerCase()) ||
              series.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to search series: ${e.message}');
    }
  }

  @override
  Future<String> createEpisode(EpisodeModel episode, File videoFile, File? thumbnailFile) async {
    try {
      String episodeId = episode.episodeId.isEmpty ? const Uuid().v4() : episode.episodeId;
      
      // Upload video
      String videoUrl = await uploadVideo(videoFile, 'mini_series/videos/$episodeId');
      
      // Upload thumbnail
      String thumbnailUrl = episode.thumbnailUrl;
      if (thumbnailFile != null) {
        thumbnailUrl = await uploadImage(thumbnailFile, 'mini_series/thumbnails/$episodeId');
      }
      
      final updatedEpisode = episode.copyWith(
        episodeId: episodeId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        createdAt: DateTime.now(),
        publishedAt: episode.isPublished ? DateTime.now() : episode.publishedAt,
      );
      
      await _firestore
          .collection(_episodesCollection)
          .doc(episodeId)
          .set(updatedEpisode.toMap());
      
      // Update series episode count
      await _updateSeriesEpisodeCount(episode.seriesId);
      
      return episodeId;
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to create episode: ${e.message}');
    }
  }

  @override
  Future<void> updateEpisode(EpisodeModel episode, File? videoFile, File? thumbnailFile) async {
    try {
      String videoUrl = episode.videoUrl;
      String thumbnailUrl = episode.thumbnailUrl;
      
      // Upload new video if provided
      if (videoFile != null) {
        if (episode.videoUrl.isNotEmpty) {
          await deleteFile(episode.videoUrl);
        }
        videoUrl = await uploadVideo(videoFile, 'mini_series/videos/${episode.episodeId}');
      }
      
      // Upload new thumbnail if provided
      if (thumbnailFile != null) {
        if (episode.thumbnailUrl.isNotEmpty) {
          await deleteFile(episode.thumbnailUrl);
        }
        thumbnailUrl = await uploadImage(thumbnailFile, 'mini_series/thumbnails/${episode.episodeId}');
      }
      
      final updatedEpisode = episode.copyWith(
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        publishedAt: episode.isPublished && !episode.publishedAt.isAfter(DateTime.now()) 
            ? DateTime.now() : episode.publishedAt,
      );
      
      await _firestore
          .collection(_episodesCollection)
          .doc(episode.episodeId)
          .update(updatedEpisode.toMap());
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to update episode: ${e.message}');
    }
  }

  @override
  Future<void> deleteEpisode(String episodeId) async {
    try {
      // Get episode data to delete files
      final episodeDoc = await _firestore
          .collection(_episodesCollection)
          .doc(episodeId)
          .get();
      
      if (episodeDoc.exists) {
        final episode = EpisodeModel.fromMap(episodeDoc.data()!);
        
        // Delete video and thumbnail files
        if (episode.videoUrl.isNotEmpty) {
          await deleteFile(episode.videoUrl);
        }
        if (episode.thumbnailUrl.isNotEmpty) {
          await deleteFile(episode.thumbnailUrl);
        }
        
        // Delete episode comments
        final commentsSnapshot = await _firestore
            .collection(_commentsCollection)
            .where('episodeId', isEqualTo: episodeId)
            .get();
        
        for (var doc in commentsSnapshot.docs) {
          await doc.reference.delete();
        }
        
        // Delete episode document
        await _firestore
            .collection(_episodesCollection)
            .doc(episodeId)
            .delete();
        
        // Update series episode count
        await _updateSeriesEpisodeCount(episode.seriesId);
      }
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to delete episode: ${e.message}');
    }
  }

  @override
  Future<EpisodeModel?> getEpisodeById(String episodeId) async {
    try {
      final doc = await _firestore
          .collection(_episodesCollection)
          .doc(episodeId)
          .get();
      
      if (!doc.exists) return null;
      
      return EpisodeModel.fromMap(doc.data()!);
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to get episode: ${e.message}');
    }
  }

  @override
  Future<List<EpisodeModel>> getEpisodesBySeries(String seriesId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_episodesCollection)
          .where('seriesId', isEqualTo: seriesId)
          .orderBy('episodeNumber')
          .get();
      
      return querySnapshot.docs
          .map((doc) => EpisodeModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to get series episodes: ${e.message}');
    }
  }

  @override
  Future<void> reorderEpisodes(String seriesId, List<String> episodeIds) async {
    try {
      // Update episode numbers based on new order
      for (int i = 0; i < episodeIds.length; i++) {
        await _firestore
            .collection(_episodesCollection)
            .doc(episodeIds[i])
            .update({'episodeNumber': i + 1});
      }
      
      // Update series updated timestamp
      await _firestore
          .collection(_seriesCollection)
          .doc(seriesId)
          .update({'updatedAt': DateTime.now().millisecondsSinceEpoch.toString()});
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to reorder episodes: ${e.message}');
    }
  }

  @override
  Future<void> likeEpisode(String episodeId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final episodeRef = _firestore.collection(_episodesCollection).doc(episodeId);
        final episodeDoc = await transaction.get(episodeRef);
        
        if (!episodeDoc.exists) {
          throw MiniSeriesRepositoryException('Episode not found');
        }
        
        final episode = EpisodeModel.fromMap(episodeDoc.data()!);
        
        if (!episode.likedBy.contains(userId)) {
          transaction.update(episodeRef, {
            'likes': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([userId]),
          });
        }
      });
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to like episode: ${e.message}');
    }
  }

  @override
  Future<void> unlikeEpisode(String episodeId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final episodeRef = _firestore.collection(_episodesCollection).doc(episodeId);
        final episodeDoc = await transaction.get(episodeRef);
        
        if (!episodeDoc.exists) {
          throw MiniSeriesRepositoryException('Episode not found');
        }
        
        final episode = EpisodeModel.fromMap(episodeDoc.data()!);
        
        if (episode.likedBy.contains(userId)) {
          transaction.update(episodeRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([userId]),
          });
        }
      });
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to unlike episode: ${e.message}');
    }
  }

  @override
  Future<void> incrementEpisodeView(String episodeId, String userId) async {
    try {
      // Update episode view count
      await _firestore
          .collection(_episodesCollection)
          .doc(episodeId)
          .update({'views': FieldValue.increment(1)});
      
      // Update analytics (simplified - in production you'd want more sophisticated tracking)
      final episode = await getEpisodeById(episodeId);
      if (episode != null) {
        await updateAnalytics(episode.seriesId, {
          'totalViews': FieldValue.increment(1),
          'viewsByEpisode.${episodeId}': FieldValue.increment(1),
          'viewsByDate.${DateTime.now().toIso8601String().split('T')[0]}': FieldValue.increment(1),
        });
      }
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to increment view: ${e.message}');
    }
  }

  @override
  Future<String> addComment(EpisodeCommentModel comment) async {
    try {
      String commentId = comment.commentId.isEmpty ? const Uuid().v4() : comment.commentId;
      
      final updatedComment = comment.copyWith(
        commentId: commentId,
        createdAt: DateTime.now(),
      );
      
      await _firestore
          .collection(_commentsCollection)
          .doc(commentId)
          .set(updatedComment.toMap());
      
      // Update episode comment count
      await _firestore
          .collection(_episodesCollection)
          .doc(comment.episodeId)
          .update({'comments': FieldValue.increment(1)});
      
      return commentId;
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to add comment: ${e.message}');
    }
  }

  @override
  Future<void> deleteComment(String commentId) async {
    try {
      // Get comment data
      final commentDoc = await _firestore
          .collection(_commentsCollection)
          .doc(commentId)
          .get();
      
      if (commentDoc.exists) {
        final comment = EpisodeCommentModel.fromMap(commentDoc.data()!);
        
        // Delete comment
        await _firestore
            .collection(_commentsCollection)
            .doc(commentId)
            .delete();
        
        // Update episode comment count
        await _firestore
            .collection(_episodesCollection)
            .doc(comment.episodeId)
            .update({'comments': FieldValue.increment(-1)});
      }
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to delete comment: ${e.message}');
    }
  }

  @override
  Future<List<EpisodeCommentModel>> getEpisodeComments(String episodeId, {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_commentsCollection)
          .where('episodeId', isEqualTo: episodeId)
          .where('parentCommentId', isNull: true) // Only top-level comments
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => EpisodeCommentModel.fromMap(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to get comments: ${e.message}');
    }
  }

  @override
  Future<void> likeComment(String commentId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final commentRef = _firestore.collection(_commentsCollection).doc(commentId);
        final commentDoc = await transaction.get(commentRef);
        
        if (!commentDoc.exists) {
          throw MiniSeriesRepositoryException('Comment not found');
        }
        
        final comment = EpisodeCommentModel.fromMap(commentDoc.data()!);
        
        if (!comment.likedBy.contains(userId)) {
          transaction.update(commentRef, {
            'likes': FieldValue.increment(1),
            'likedBy': FieldValue.arrayUnion([userId]),
          });
        }
      });
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to like comment: ${e.message}');
    }
  }

  @override
  Future<void> unlikeComment(String commentId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final commentRef = _firestore.collection(_commentsCollection).doc(commentId);
        final commentDoc = await transaction.get(commentRef);
        
        if (!commentDoc.exists) {
          throw MiniSeriesRepositoryException('Comment not found');
        }
        
        final comment = EpisodeCommentModel.fromMap(commentDoc.data()!);
        
        if (comment.likedBy.contains(userId)) {
          transaction.update(commentRef, {
            'likes': FieldValue.increment(-1),
            'likedBy': FieldValue.arrayRemove([userId]),
          });
        }
      });
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to unlike comment: ${e.message}');
    }
  }

  @override
  Future<SeriesAnalyticsModel> getSeriesAnalytics(String seriesId) async {
    try {
      final doc = await _firestore
          .collection(_analyticsCollection)
          .doc(seriesId)
          .get();
      
      if (!doc.exists) {
        // Create initial analytics document
        final initialAnalytics = SeriesAnalyticsModel(
          seriesId: seriesId,
          lastUpdated: DateTime.now(),
        );
        
        await _firestore
            .collection(_analyticsCollection)
            .doc(seriesId)
            .set(initialAnalytics.toMap());
        
        return initialAnalytics;
      }
      
      return SeriesAnalyticsModel.fromMap(doc.data()!);
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to get analytics: ${e.message}');
    }
  }

  @override
  Future<void> updateAnalytics(String seriesId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(_analyticsCollection)
          .doc(seriesId)
          .set({
            ...data,
            'lastUpdated': DateTime.now().millisecondsSinceEpoch.toString(),
          }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to update analytics: ${e.message}');
    }
  }

  @override
  Future<String> uploadVideo(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to upload video: ${e.message}');
    }
  }

  @override
  Future<String> uploadImage(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw MiniSeriesRepositoryException('Failed to upload image: ${e.message}');
    }
  }

  @override
  Future<void> deleteFile(String url) async {
    try {
      if (url.isNotEmpty && url.contains('firebase')) {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      }
    } on FirebaseException catch (e) {
      // Don't throw error if file doesn't exist
      debugPrint('Warning: Could not delete file: ${e.message}');
    }
  }

  // Helper method to update series episode count
  Future<void> _updateSeriesEpisodeCount(String seriesId) async {
    try {
      final episodesSnapshot = await _firestore
          .collection(_episodesCollection)
          .where('seriesId', isEqualTo: seriesId)
          .get();
      
      await _firestore
          .collection(_seriesCollection)
          .doc(seriesId)
          .update({
            'totalEpisodes': episodesSnapshot.docs.length,
            'updatedAt': DateTime.now().millisecondsSinceEpoch.toString(),
          });
    } catch (e) {
      debugPrint('Warning: Could not update series episode count: $e');
    }
  }
}

class MiniSeriesRepositoryException implements Exception {
  final String message;
  const MiniSeriesRepositoryException(this.message);
  
  @override
  String toString() => 'MiniSeriesRepositoryException: $message';
}