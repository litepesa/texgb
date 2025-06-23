// lib/features/moments/providers/moments_provider.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

part 'moments_provider.g.dart';

class MomentsState {
  final bool isLoading;
  final bool isSuccessful;
  final List<MomentModel> moments;
  final String? error;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final bool isInitialized;

  const MomentsState({
    this.isLoading = false,
    this.isSuccessful = false,
    this.moments = const [],
    this.error,
    this.hasMore = true,
    this.lastDocument,
    this.isInitialized = false,
  });

  MomentsState copyWith({
    bool? isLoading,
    bool? isSuccessful,
    List<MomentModel>? moments,
    String? error,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    bool? isInitialized,
  }) {
    return MomentsState(
      isLoading: isLoading ?? this.isLoading,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      moments: moments ?? this.moments,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

@riverpod
class MomentsNotifier extends _$MomentsNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _pageSize = 10;

  @override
  FutureOr<MomentsState> build() async {
    try {
      final authState = await ref.read(authenticationProvider.future);
      
      if (authState.userModel == null) {
        return const MomentsState(isInitialized: true);
      }

      final user = authState.userModel!;
      final contactUIDs = user.contactsUIDs;
      final allUIDs = [user.uid, ...contactUIDs];

      // Load moments in batches to handle Firestore's whereIn limitation (max 10 items)
      final List<MomentModel> allMoments = [];
      
      for (int i = 0; i < allUIDs.length; i += 10) {
        final batch = allUIDs.skip(i).take(10).toList();
        
        final snapshot = await _firestore
            .collection(Constants.moments) // Use moments collection instead
            .where('authorUID', whereIn: batch)
            .orderBy('createdAt', descending: true)
            .limit(_pageSize)
            .get();

        final batchMoments = snapshot.docs
            .map((doc) => MomentModel.fromMap(doc.data()))
            .toList();
            
        allMoments.addAll(batchMoments);
      }

      // Sort all moments by creation date
      allMoments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Take only the latest ones up to pageSize
      final finalMoments = allMoments.take(_pageSize).toList();

      return MomentsState(
        moments: finalMoments,
        isSuccessful: true,
        isInitialized: true,
        hasMore: allMoments.length >= _pageSize,
      );
    } catch (e) {
      return MomentsState(
        error: e.toString(),
        isInitialized: true,
      );
    }
  }

  // Create a new moment
  Future<void> createMoment({
    required String content,
    required List<File> mediaFiles,
    required MessageEnum mediaType,
    required MomentPrivacy privacy,
    Map<String, dynamic>? location,
    List<String>? taggedUsers,
  }) async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      final user = authState.userModel!;
      final momentId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload media files
      List<String> mediaUrls = [];
      if (mediaFiles.isNotEmpty) {
        for (int i = 0; i < mediaFiles.length; i++) {
          final file = mediaFiles[i];
          final extension = file.path.split('.').last;
          final fileName = '${momentId}_$i.$extension';
          final reference = 'moments/${user.uid}/$fileName';
          
          final downloadUrl = await storeFileToStorage(
            file: file,
            reference: reference,
          );
          mediaUrls.add(downloadUrl);
        }
      }

      // Create moment model
      final moment = MomentModel(
        momentId: momentId,
        authorUID: user.uid,
        authorName: user.name,
        authorImage: user.image,
        content: content,
        mediaUrls: mediaUrls,
        mediaType: mediaType,
        createdAt: DateTime.now(),
        likedBy: [],
        viewedBy: [],
        location: location ?? {},
        taggedUsers: taggedUsers ?? [],
        privacy: privacy,
      );

      // Save to Firestore
      await _firestore
          .collection(Constants.moments) // Use moments collection
          .doc(momentId)
          .set(moment.toMap());

      // Add to local state at the beginning
      final updatedMoments = [moment, ...state.value!.moments];
      
      state = AsyncValue.data(state.value!.copyWith(
        moments: updatedMoments,
        isLoading: false,
        isSuccessful: true,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Load moments feed
  Future<void> loadMomentsFeed({bool refresh = false}) async {
    if (!state.hasValue) return;
    
    // Don't load if already loading and not refreshing
    if (state.value!.isLoading && !refresh) return;

    // Update loading state
    if (refresh) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: true,
        error: null,
      ));
    } else {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: true,
        error: null,
      ));
    }

    try {
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      final user = authState.userModel!;
      final contactUIDs = user.contactsUIDs;
      final allUIDs = [user.uid, ...contactUIDs];

      // Load moments in batches to handle Firestore's whereIn limitation
      final List<MomentModel> allMoments = [];
      
      for (int i = 0; i < allUIDs.length; i += 10) {
        final batch = allUIDs.skip(i).take(10).toList();
        
        Query query = _firestore
            .collection(Constants.moments) // Use moments collection
            .where('authorUID', whereIn: batch)
            .orderBy('createdAt', descending: true);

        // Add pagination if not refreshing and we have a last document
        if (!refresh && state.value!.lastDocument != null) {
          query = query.startAfterDocument(state.value!.lastDocument!);
        }

        query = query.limit(_pageSize);
        
        final snapshot = await query.get();
        
        final batchMoments = snapshot.docs
            .map((doc) => MomentModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
            
        allMoments.addAll(batchMoments);
      }

      // Sort all moments by creation date
      allMoments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Handle pagination
      final currentMoments = refresh ? <MomentModel>[] : state.value!.moments;
      final updatedMoments = [...currentMoments, ...allMoments];
      
      // Remove duplicates based on momentId
      final uniqueMoments = <String, MomentModel>{};
      for (final moment in updatedMoments) {
        uniqueMoments[moment.momentId] = moment;
      }
      final finalMoments = uniqueMoments.values.toList();
      
      // Sort again after deduplication
      finalMoments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      state = AsyncValue.data(state.value!.copyWith(
        moments: finalMoments,
        isLoading: false,
        isSuccessful: true,
        hasMore: allMoments.length >= _pageSize,
        lastDocument: allMoments.isNotEmpty 
            ? null // We'll need to track this per batch if implementing proper pagination
            : state.value!.lastDocument,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Like/unlike a moment
  Future<void> toggleLikeMoment(String momentId) async {
    if (!state.hasValue) return;

    try {
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) return;

      final userId = authState.userModel!.uid;
      final momentRef = _firestore.collection(Constants.moments).doc(momentId); // Use moments collection

      // Find the moment in local state
      final momentIndex = state.value!.moments.indexWhere((m) => m.momentId == momentId);
      if (momentIndex == -1) return;

      final moment = state.value!.moments[momentIndex];
      final isLiked = moment.likedBy.contains(userId);

      // Update Firestore
      if (isLiked) {
        await momentRef.update({
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        await momentRef.update({
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }

      // Update local state
      final updatedLikedBy = List<String>.from(moment.likedBy);
      if (isLiked) {
        updatedLikedBy.remove(userId);
      } else {
        updatedLikedBy.add(userId);
      }

      final updatedMoment = moment.copyWith(likedBy: updatedLikedBy);
      final updatedMoments = List<MomentModel>.from(state.value!.moments);
      updatedMoments[momentIndex] = updatedMoment;

      state = AsyncValue.data(state.value!.copyWith(moments: updatedMoments));
    } catch (e) {
      // Silently handle error in production
      if (kDebugMode) {
        debugPrint('Error toggling like: $e');
      }
    }
  }

  // Add view to moment
  Future<void> addViewToMoment(String momentId) async {
    if (!state.hasValue) return;

    try {
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) return;

      final userId = authState.userModel!.uid;
      final momentRef = _firestore.collection(Constants.moments).doc(momentId); // Use moments collection

      // Find the moment in local state
      final momentIndex = state.value!.moments.indexWhere((m) => m.momentId == momentId);
      if (momentIndex == -1) return;

      final moment = state.value!.moments[momentIndex];
      
      // Don't add view if already viewed
      if (moment.viewedBy.contains(userId)) return;

      // Update Firestore
      await momentRef.update({
        'viewedBy': FieldValue.arrayUnion([userId]),
      });

      // Update local state
      final updatedViewedBy = [...moment.viewedBy, userId];
      final updatedMoment = moment.copyWith(viewedBy: updatedViewedBy);
      final updatedMoments = List<MomentModel>.from(state.value!.moments);
      updatedMoments[momentIndex] = updatedMoment;

      state = AsyncValue.data(state.value!.copyWith(moments: updatedMoments));
    } catch (e) {
      // Silently handle error in production
      if (kDebugMode) {
        debugPrint('Error adding view: $e');
      }
    }
  }

  // Delete a moment
  Future<void> deleteMoment(String momentId) async {
    if (!state.hasValue) return;

    try {
      // Delete from Firestore
      await _firestore.collection(Constants.moments).doc(momentId).delete(); // Use moments collection

      // Remove from local state
      final updatedMoments = state.value!.moments
          .where((moment) => moment.momentId != momentId)
          .toList();

      state = AsyncValue.data(state.value!.copyWith(moments: updatedMoments));
    } catch (e) {
      // Silently handle error in production
      if (kDebugMode) {
        debugPrint('Error deleting moment: $e');
      }
    }
  }

  // Get moments by user
  Future<List<MomentModel>> getUserMoments(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(Constants.moments) // Use moments collection
          .where('authorUID', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MomentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting user moments: $e');
      }
      return [];
    }
  }

  // Add comment to moment
  Future<void> addComment({
    required String momentId,
    required String content,
    String? replyToUID,
    String? replyToName,
  }) async {
    try {
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) return;

      final user = authState.userModel!;
      final commentId = DateTime.now().millisecondsSinceEpoch.toString();

      final comment = MomentComment(
        commentId: commentId,
        momentId: momentId,
        authorUID: user.uid,
        authorName: user.name,
        authorImage: user.image,
        content: content,
        createdAt: DateTime.now(),
        replyToUID: replyToUID,
        replyToName: replyToName,
      );

      await _firestore
          .collection(Constants.momentComments) // Use moment comments collection
          .doc(commentId)
          .set(comment.toMap());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding comment: $e');
      }
    }
  }

  // Get comments for a moment
  Stream<List<MomentComment>> getMomentComments(String momentId) {
    return _firestore
        .collection(Constants.momentComments) // Use moment comments collection
        .where('momentId', isEqualTo: momentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MomentComment.fromMap(doc.data()))
            .toList());
  }

  // Clear state
  void clearState() {
    state = AsyncValue.data(const MomentsState());
  }
}