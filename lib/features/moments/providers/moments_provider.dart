// lib/features/moments/providers/moments_provider.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

part 'moments_provider.g.dart';

class MomentsState {
  final bool isLoading;
  final bool isPosting;
  final List<MomentModel> moments;
  final List<MomentModel> myMoments;
  final String? error;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final bool isLoadingMore;

  const MomentsState({
    this.isLoading = false,
    this.isPosting = false,
    this.moments = const [],
    this.myMoments = const [],
    this.error,
    this.hasMore = true,
    this.lastDocument,
    this.isLoadingMore = false,
  });

  MomentsState copyWith({
    bool? isLoading,
    bool? isPosting,
    List<MomentModel>? moments,
    List<MomentModel>? myMoments,
    String? error,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    bool? isLoadingMore,
  }) {
    return MomentsState(
      isLoading: isLoading ?? this.isLoading,
      isPosting: isPosting ?? this.isPosting,
      moments: moments ?? this.moments,
      myMoments: myMoments ?? this.myMoments,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

@riverpod
class MomentsNotifier extends _$MomentsNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _pageSize = 10;

  @override
  FutureOr<MomentsState> build() async {
    return const MomentsState();
  }

  // Load moments feed with pagination
  Future<void> loadMomentsFeed({bool refresh = false}) async {
    if (!state.hasValue) return;

    final currentState = state.value!;
    
    // Don't load if already loading or no more data (unless refreshing)
    if ((currentState.isLoading || currentState.isLoadingMore) && !refresh) return;
    if (!currentState.hasMore && !refresh) return;

    // Set loading state
    if (refresh) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: true,
        error: null,
      ));
    } else {
      state = AsyncValue.data(currentState.copyWith(
        isLoadingMore: true,
        error: null,
      ));
    }

    try {
      final authState = await ref.read(authenticationProvider.future);
      final currentUser = authState.userModel;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Build query
      Query query = _firestore
          .collection(Constants.statusPosts)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      // Add pagination if not refreshing
      if (!refresh && currentState.lastDocument != null) {
        query = query.startAfterDocument(currentState.lastDocument!);
      }

      final querySnapshot = await query.get();
      final documents = querySnapshot.docs;

      // Parse moments with privacy filtering
      List<MomentModel> newMoments = [];
      for (var doc in documents) {
        try {
          final moment = MomentModel.fromMap(doc.data() as Map<String, dynamic>);
          
          // Apply privacy filtering
          if (_canViewMoment(moment, currentUser.uid, currentUser.contactsUIDs)) {
            newMoments.add(moment);
          }
        } catch (e) {
          debugPrint('Error parsing moment: $e');
        }
      }

      // Update state
      final updatedMoments = refresh 
          ? newMoments 
          : [...currentState.moments, ...newMoments];

      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        isLoadingMore: false,
        moments: updatedMoments,
        hasMore: documents.length == _pageSize,
        lastDocument: documents.isNotEmpty ? documents.last : null,
      ));

    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  // Load user's own moments
  Future<void> loadMyMoments() async {
    if (!state.hasValue) return;

    final currentState = state.value!;
    
    state = AsyncValue.data(currentState.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      final authState = await ref.read(authenticationProvider.future);
      final currentUser = authState.userModel;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection(Constants.statusPosts)
          .where('authorUID', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final myMoments = querySnapshot.docs
          .map((doc) => MomentModel.fromMap(doc.data()))
          .toList();

      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        myMoments: myMoments,
      ));

    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Post a new moment
  Future<void> postMoment({
    required String content,
    required List<File> mediaFiles,
    required MomentPrivacy privacy,
    required List<String> visibleTo,
    required List<String> hiddenFrom,
    String? location,
  }) async {
    if (!state.hasValue) return;

    final currentState = state.value!;
    
    state = AsyncValue.data(currentState.copyWith(
      isPosting: true,
      error: null,
    ));

    try {
      final authState = await ref.read(authenticationProvider.future);
      final currentUser = authState.userModel;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final momentId = _firestore.collection(Constants.statusPosts).doc().id;
      
      // Upload media files
      List<String> mediaUrls = [];
      String mediaType = 'text';
      
      if (mediaFiles.isNotEmpty) {
        for (int i = 0; i < mediaFiles.length; i++) {
          final file = mediaFiles[i];
          final fileName = '${momentId}_$i.${file.path.split('.').last}';
          final reference = '${Constants.statusFiles}/$momentId/$fileName';
          
          final downloadUrl = await storeFileToStorage(
            file: file,
            reference: reference,
          );
          mediaUrls.add(downloadUrl);
        }
        
        // Determine media type
        final hasImages = mediaFiles.any((f) => 
            f.path.toLowerCase().endsWith('.jpg') ||
            f.path.toLowerCase().endsWith('.jpeg') ||
            f.path.toLowerCase().endsWith('.png') ||
            f.path.toLowerCase().endsWith('.gif'));
        
        final hasVideos = mediaFiles.any((f) => 
            f.path.toLowerCase().endsWith('.mp4') ||
            f.path.toLowerCase().endsWith('.mov') ||
            f.path.toLowerCase().endsWith('.avi'));
        
        if (hasImages && hasVideos) {
          mediaType = 'mixed';
        } else if (hasVideos) {
          mediaType = 'video';
        } else if (hasImages) {
          mediaType = 'image';
        }
      }

      // Create moment model
      final moment = MomentModel(
        momentId: momentId,
        authorUID: currentUser.uid,
        authorName: currentUser.name,
        authorImage: currentUser.image,
        content: content,
        mediaUrls: mediaUrls,
        mediaType: mediaType,
        createdAt: DateTime.now(),
        likedBy: [],
        likesCount: 0,
        commentsCount: 0,
        location: location,
        privacy: privacy,
        visibleTo: visibleTo,
        hiddenFrom: hiddenFrom,
        isEdited: false,
      );

      // Save to Firestore
      await _firestore
          .collection(Constants.statusPosts)
          .doc(momentId)
          .set(moment.toMap());

      // Add to local state (optimistic update)
      final updatedMoments = [moment, ...currentState.moments];
      final updatedMyMoments = [moment, ...currentState.myMoments];

      state = AsyncValue.data(currentState.copyWith(
        isPosting: false,
        moments: updatedMoments,
        myMoments: updatedMyMoments,
      ));

    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isPosting: false,
        error: e.toString(),
      ));
      throw e;
    }
  }

  // Like/unlike a moment
  Future<void> toggleLikeMoment(String momentId) async {
    if (!state.hasValue) return;

    try {
      final authState = await ref.read(authenticationProvider.future);
      final currentUser = authState.userModel;
      
      if (currentUser == null) return;

      final momentRef = _firestore.collection(Constants.statusPosts).doc(momentId);
      
      await _firestore.runTransaction((transaction) async {
        final momentDoc = await transaction.get(momentRef);
        
        if (!momentDoc.exists) return;
        
        final moment = MomentModel.fromMap(momentDoc.data()!);
        final isLiked = moment.likedBy.contains(currentUser.uid);
        
        List<String> updatedLikedBy = List.from(moment.likedBy);
        int updatedLikesCount = moment.likesCount;
        
        if (isLiked) {
          updatedLikedBy.remove(currentUser.uid);
          updatedLikesCount = (updatedLikesCount - 1).clamp(0, double.infinity).toInt();
        } else {
          updatedLikedBy.add(currentUser.uid);
          updatedLikesCount += 1;
        }
        
        transaction.update(momentRef, {
          'likedBy': updatedLikedBy,
          'likesCount': updatedLikesCount,
        });
        
        // Update local state
        _updateLocalMoment(momentId, (moment) => moment.copyWith(
          likedBy: updatedLikedBy,
          likesCount: updatedLikesCount,
        ));
      });

    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  // Delete a moment
  Future<void> deleteMoment(String momentId) async {
    if (!state.hasValue) return;

    try {
      final authState = await ref.read(authenticationProvider.future);
      final currentUser = authState.userModel;
      
      if (currentUser == null) return;

      // Delete from Firestore
      await _firestore.collection(Constants.statusPosts).doc(momentId).delete();
      
      // Delete comments
      final commentsSnapshot = await _firestore
          .collection(Constants.statusComments)
          .where('momentId', isEqualTo: momentId)
          .get();
      
      final batch = _firestore.batch();
      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Update local state
      final currentState = state.value!;
      final updatedMoments = currentState.moments
          .where((m) => m.momentId != momentId)
          .toList();
      final updatedMyMoments = currentState.myMoments
          .where((m) => m.momentId != momentId)
          .toList();

      state = AsyncValue.data(currentState.copyWith(
        moments: updatedMoments,
        myMoments: updatedMyMoments,
      ));

    } catch (e) {
      debugPrint('Error deleting moment: $e');
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
      final currentUser = authState.userModel;
      
      if (currentUser == null) return;

      final commentId = _firestore.collection(Constants.statusComments).doc().id;
      
      final comment = MomentCommentModel(
        commentId: commentId,
        momentId: momentId,
        authorUID: currentUser.uid,
        authorName: currentUser.name,
        authorImage: currentUser.image,
        content: content,
        createdAt: DateTime.now(),
        replyToUID: replyToUID,
        replyToName: replyToName,
        likedBy: [],
        likesCount: 0,
      );

      // Add comment to Firestore
      await _firestore
          .collection(Constants.statusComments)
          .doc(commentId)
          .set(comment.toMap());

      // Update moment's comment count
      await _firestore
          .collection(Constants.statusPosts)
          .doc(momentId)
          .update({
        'commentsCount': FieldValue.increment(1),
      });

      // Update local state
      _updateLocalMoment(momentId, (moment) => moment.copyWith(
        commentsCount: moment.commentsCount + 1,
      ));

    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  // Get comments for a moment
  Stream<List<MomentCommentModel>> getCommentsStream(String momentId) {
    return _firestore
        .collection(Constants.statusComments)
        .where('momentId', isEqualTo: momentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MomentCommentModel.fromMap(doc.data()))
            .toList());
  }

  // Privacy check helper
  bool _canViewMoment(MomentModel moment, String viewerUID, List<String> viewerContacts) {
    // Author can always see their own moments
    if (moment.authorUID == viewerUID) return true;

    switch (moment.privacy) {
      case MomentPrivacy.public:
        return true;
      
      case MomentPrivacy.allContacts:
        return viewerContacts.contains(moment.authorUID);
      
      case MomentPrivacy.except:
        return viewerContacts.contains(moment.authorUID) && 
               !moment.hiddenFrom.contains(viewerUID);
      
      case MomentPrivacy.only:
        return moment.visibleTo.contains(viewerUID);
    }
  }

  // Update local moment helper
  void _updateLocalMoment(String momentId, MomentModel Function(MomentModel) updater) {
    if (!state.hasValue) return;

    final currentState = state.value!;
    
    final updatedMoments = currentState.moments.map((moment) {
      if (moment.momentId == momentId) {
        return updater(moment);
      }
      return moment;
    }).toList();

    final updatedMyMoments = currentState.myMoments.map((moment) {
      if (moment.momentId == momentId) {
        return updater(moment);
      }
      return moment;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(
      moments: updatedMoments,
      myMoments: updatedMyMoments,
    ));
  }

  // Clear error
  void clearError() {
    if (!state.hasValue) return;
    state = AsyncValue.data(state.value!.copyWith(error: null));
  }
}