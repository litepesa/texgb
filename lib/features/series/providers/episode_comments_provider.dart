// ============================================================================

// lib/features/series/providers/episode_comments_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/episode_comment_model.dart';
import '../../../features/authentication/providers/auth_providers.dart';
import '../../../constants.dart';

// Stream provider for episode comments
final episodeCommentsStreamProvider = StreamProvider.family<List<EpisodeCommentModel>, String>((ref, episodeId) {
  return FirebaseFirestore.instance
      .collection(Constants.episodeComments)
      .where('episodeId', isEqualTo: episodeId)
      .orderBy('createdAt', descending: false) // Oldest first for better threading
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return EpisodeCommentModel.fromMap(doc.data(), doc.id);
    }).toList();
  });
});

// Comment actions provider
final episodeCommentActionsProvider = Provider<EpisodeCommentActions>((ref) {
  return EpisodeCommentActions(ref);
});

class EpisodeCommentActions {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  EpisodeCommentActions(this._ref);

  Future<bool> addComment({
    required String episodeId,
    required String seriesId,
    required String content,
    String? repliedToCommentId,
    String? repliedToAuthorName,
  }) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final commentData = {
        'episodeId': episodeId,
        'seriesId': seriesId,
        'authorId': currentUser.uid,
        'authorName': currentUser.name,
        'authorImage': currentUser.image,
        'content': content.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'likedBy': <String>[],
        'likesCount': 0,
        'isReply': repliedToCommentId != null,
        if (repliedToCommentId != null) 'repliedToCommentId': repliedToCommentId,
        if (repliedToAuthorName != null) 'repliedToAuthorName': repliedToAuthorName,
      };

      // Add comment to Firestore
      await _firestore.collection(Constants.episodeComments).add(commentData);

      // Update episode comment count
      await _firestore.collection(Constants.seriesEpisodes).doc(episodeId).update({
        'comments': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      debugPrint('Error adding episode comment: $e');
      return false;
    }
  }

  Future<bool> toggleLikeComment(String commentId, bool isCurrentlyLiked) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final commentRef = _firestore.collection(Constants.episodeComments).doc(commentId);

      if (isCurrentlyLiked) {
        // Unlike the comment
        await commentRef.update({
          'likedBy': FieldValue.arrayRemove([currentUser.uid]),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like the comment
        await commentRef.update({
          'likedBy': FieldValue.arrayUnion([currentUser.uid]),
          'likesCount': FieldValue.increment(1),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error toggling episode comment like: $e');
      return false;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the comment to check ownership
      final commentDoc = await _firestore.collection(Constants.episodeComments).doc(commentId).get();
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data()!;
      
      // Check if user owns the comment
      if (commentData['authorId'] != currentUser.uid) {
        throw Exception('Not authorized to delete this comment');
      }

      final episodeId = commentData['episodeId'];

      // Delete the comment
      await _firestore.collection(Constants.episodeComments).doc(commentId).delete();

      // Update episode comment count
      await _firestore.collection(Constants.seriesEpisodes).doc(episodeId).update({
        'comments': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      debugPrint('Error deleting episode comment: $e');
      return false;
    }
  }

  Future<bool> reportComment(String commentId, String reason) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection(Constants.reports).add({
        'type': 'episode_comment',
        'targetId': commentId,
        'reporterId': currentUser.uid,
        'reporterName': currentUser.name,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      return true;
    } catch (e) {
      debugPrint('Error reporting episode comment: $e');
      return false;
    }
  }
}