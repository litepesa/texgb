// lib/features/moments/providers/moments_provider.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/models/user_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

part 'moments_provider.g.dart';

@riverpod
class MomentsNotifier extends _$MomentsNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  FutureOr<List<MomentModel>> build() {
    return <MomentModel>[];
  }

  // Load moments from Firestore
  Future<void> loadMoments() async {
    state = const AsyncValue.loading();
    
    try {
      final querySnapshot = await _firestore
          .collection(Constants.statusPosts) // Using statusPosts collection for moments
          .orderBy(Constants.createdAt, descending: true)
          .limit(50)
          .get();

      final moments = querySnapshot.docs
          .map((doc) => MomentModel.fromMap(doc.data()))
          .toList();

      state = AsyncValue.data(moments);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Refresh moments
  Future<void> refreshMoments() async {
    await loadMoments();
  }

  // Create a new moment
  Future<void> createMoment({
    required UserModel user,
    required String content,
    required List<File> images,
    required StatusPrivacyType privacyType,
    required List<String> excludedUsers,
    required List<String> onlyUsers,
  }) async {
    try {
      final momentId = _firestore.collection(Constants.statusPosts).doc().id;
      final mediaUrls = <String>[];

      // Upload images if any
      for (int i = 0; i < images.length; i++) {
        final imageUrl = await storeFileToStorage(
          file: images[i],
          reference: '${Constants.statusFiles}/$momentId/image_$i',
        );
        mediaUrls.add(imageUrl);
      }

      // Determine moment type
      StatusType momentType = StatusType.text;
      if (mediaUrls.isNotEmpty) {
        momentType = StatusType.image;
      }

      // Create moment model
      final moment = MomentModel(
        momentId: momentId,
        userId: user.uid,
        userName: user.name,
        userImage: user.image,
        content: content,
        mediaUrls: mediaUrls,
        momentType: momentType,
        createdAt: DateTime.now(),
        likedBy: [],
        comments: [],
        viewCount: 0,
        privacyType: privacyType,
        excludedUsers: excludedUsers,
        onlyUsers: onlyUsers,
      );

      // Save to Firestore
      await _firestore
          .collection(Constants.statusPosts)
          .doc(momentId)
          .set(moment.toMap());

      // Update local state
      final currentMoments = state.value ?? [];
      state = AsyncValue.data([moment, ...currentMoments]);
    } catch (e) {
      debugPrint('Error creating moment: $e');
      throw e.toString();
    }
  }

  // Toggle like on a moment
  Future<void> toggleLike(String momentId, String userId) async {
    try {
      final currentState = state.value ?? [];
      final momentIndex = currentState.indexWhere((m) => m.momentId == momentId);
      
      if (momentIndex == -1) return;

      final moment = currentState[momentIndex];
      final isLiked = moment.isLikedBy(userId);
      
      List<String> updatedLikedBy = List<String>.from(moment.likedBy);
      
      if (isLiked) {
        updatedLikedBy.remove(userId);
      } else {
        updatedLikedBy.add(userId);
      }

      // Update Firestore
      await _firestore
          .collection(Constants.statusPosts)
          .doc(momentId)
          .update({
        Constants.likedBy: updatedLikedBy,
      });

      // Update local state
      final updatedMoment = moment.copyWith(likedBy: updatedLikedBy);
      final updatedMoments = List<MomentModel>.from(currentState);
      updatedMoments[momentIndex] = updatedMoment;
      
      state = AsyncValue.data(updatedMoments);
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  // Add comment to a moment
  Future<void> addComment(String momentId, UserModel user, String content) async {
    try {
      final commentId = _firestore.collection('temp').doc().id;
      
      final comment = MomentComment(
        commentId: commentId,
        userId: user.uid,
        userName: user.name,
        userImage: user.image,
        content: content,
        createdAt: DateTime.now(),
        likedBy: [],
      );

      // Update Firestore
      await _firestore
          .collection(Constants.statusPosts)
          .doc(momentId)
          .update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });

      // Update local state
      final currentState = state.value ?? [];
      final momentIndex = currentState.indexWhere((m) => m.momentId == momentId);
      
      if (momentIndex != -1) {
        final moment = currentState[momentIndex];
        final updatedComments = List<MomentComment>.from(moment.comments);
        updatedComments.add(comment);
        
        final updatedMoment = moment.copyWith(comments: updatedComments);
        final updatedMoments = List<MomentModel>.from(currentState);
        updatedMoments[momentIndex] = updatedMoment;
        
        state = AsyncValue.data(updatedMoments);
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  // Delete a moment
  Future<void> deleteMoment(String momentId) async {
    try {
      // Delete from Firestore
      await _firestore
          .collection(Constants.statusPosts)
          .doc(momentId)
          .delete();

      // Update local state
      final currentState = state.value ?? [];
      final updatedMoments = currentState.where((m) => m.momentId != momentId).toList();
      
      state = AsyncValue.data(updatedMoments);
    } catch (e) {
      debugPrint('Error deleting moment: $e');
      throw e.toString();
    }
  }

  // Get moments stream for real-time updates
  Stream<List<MomentModel>> getMomentsStream() {
    return _firestore
        .collection(Constants.statusPosts)
        .orderBy(Constants.createdAt, descending: true)
        .limit(50)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => MomentModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Get user moments
  Future<List<MomentModel>> getUserMoments(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(Constants.statusPosts)
          .where(Constants.userId, isEqualTo: userId)
          .orderBy(Constants.createdAt, descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => MomentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting user moments: $e');
      return [];
    }
  }

  // Update moment view count
  Future<void> updateViewCount(String momentId) async {
    try {
      await _firestore
          .collection(Constants.statusPosts)
          .doc(momentId)
          .update({
        Constants.viewCount: FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error updating view count: $e');
    }
  }

  // Search moments
  Future<List<MomentModel>> searchMoments(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection(Constants.statusPosts)
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('content')
          .orderBy(Constants.createdAt, descending: true)
          .limit(20)
          .get();

      return querySnapshot.docs
          .map((doc) => MomentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error searching moments: $e');
      return [];
    }
  }
}