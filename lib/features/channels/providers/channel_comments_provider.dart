// lib/features/channels/providers/channel_comments_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/features/channels/models/channel_comment_model.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/constants.dart';

// Stream provider for channel comments
final channelCommentsStreamProvider = StreamProvider.family<List<ChannelCommentModel>, String>((ref, videoId) {
  return FirebaseFirestore.instance
      .collection(Constants.channelComments)
      .where('videoId', isEqualTo: videoId)
      .orderBy('createdAt', descending: false) // Oldest first for better threading
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return ChannelCommentModel.fromMap(doc.data(), doc.id);
    }).toList();
  });
});

// Comment actions provider
final channelCommentActionsProvider = Provider<ChannelCommentActions>((ref) {
  return ChannelCommentActions(ref);
});

class ChannelCommentActions {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ChannelCommentActions(this._ref);

  Future<bool> addComment({
    required String videoId,
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
        'videoId': videoId,
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
      await _firestore.collection(Constants.channelComments).add(commentData);

      // Update video comment count
      await _firestore.collection(Constants.channelVideos).doc(videoId).update({
        'comments': FieldValue.increment(1),
      });

      // If it's a reply, increment the parent comment's reply count
      if (repliedToCommentId != null) {
        await _firestore.collection(Constants.channelComments).doc(repliedToCommentId).update({
          'replyCount': FieldValue.increment(1),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return false;
    }
  }

  Future<bool> toggleLikeComment(String commentId, bool isCurrentlyLiked) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final commentRef = _firestore.collection(Constants.channelComments).doc(commentId);

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
      debugPrint('Error toggling comment like: $e');
      return false;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      final currentUser = _ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the comment to check ownership and get video ID
      final commentDoc = await _firestore.collection(Constants.channelComments).doc(commentId).get();
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data()!;
      
      // Check if user owns the comment
      if (commentData['authorId'] != currentUser.uid) {
        throw Exception('Not authorized to delete this comment');
      }

      final videoId = commentData['videoId'];
      final isReply = commentData['isReply'] ?? false;
      final repliedToCommentId = commentData['repliedToCommentId'];

      // Delete the comment
      await _firestore.collection(Constants.channelComments).doc(commentId).delete();

      // Update video comment count
      await _firestore.collection(Constants.channelVideos).doc(videoId).update({
        'comments': FieldValue.increment(-1),
      });

      // If it was a reply, decrement the parent comment's reply count
      if (isReply && repliedToCommentId != null) {
        await _firestore.collection(Constants.channelComments).doc(repliedToCommentId).update({
          'replyCount': FieldValue.increment(-1),
        });
      }

      // Also delete any replies to this comment
      final repliesQuery = await _firestore
          .collection(Constants.channelComments)
          .where('repliedToCommentId', isEqualTo: commentId)
          .get();

      if (repliesQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();
        
        for (final replyDoc in repliesQuery.docs) {
          batch.delete(replyDoc.reference);
        }
        
        await batch.commit();

        // Update video comment count for deleted replies
        await _firestore.collection(Constants.channelVideos).doc(videoId).update({
          'comments': FieldValue.increment(-repliesQuery.docs.length),
        });
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting comment: $e');
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
        'type': 'channel_comment',
        'targetId': commentId,
        'reporterId': currentUser.uid,
        'reporterName': currentUser.name,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      return true;
    } catch (e) {
      debugPrint('Error reporting comment: $e');
      return false;
    }
  }

  // Get comment count for a video
  Future<int> getCommentCount(String videoId) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.channelComments)
          .where('videoId', isEqualTo: videoId)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting comment count: $e');
      return 0;
    }
  }

  // Get replies for a specific comment
  Stream<List<ChannelCommentModel>> getRepliesStream(String parentCommentId) {
    return _firestore
        .collection(Constants.channelComments)
        .where('repliedToCommentId', isEqualTo: parentCommentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChannelCommentModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get a specific comment by ID
  Future<ChannelCommentModel?> getCommentById(String commentId) async {
    try {
      final doc = await _firestore.collection(Constants.channelComments).doc(commentId).get();
      if (doc.exists) {
        return ChannelCommentModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting comment by ID: $e');
      return null;
    }
  }
}