// lib/features/moments/providers/moments_provider.dart - Simplified with chronological logic
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/models/moment_comment_model.dart';
import 'package:textgb/features/moments/repositories/moments_repository.dart';

part 'moments_provider.g.dart';

// Repository provider
final momentsRepositoryProvider = Provider<MomentsRepository>((ref) {
  return FirebaseMomentsRepository();
});

// State class for moments management
class MomentsState {
  final List<MomentModel> moments;
  final List<MomentModel> userMoments;
  final List<UserMomentGroup> userGroups; // User-grouped moments
  final bool isLoading;
  final bool isCreating;
  final String? error;

  const MomentsState({
    this.moments = const [],
    this.userMoments = const [],
    this.userGroups = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.error,
  });

  MomentsState copyWith({
    List<MomentModel>? moments,
    List<MomentModel>? userMoments,
    List<UserMomentGroup>? userGroups,
    bool? isLoading,
    bool? isCreating,
    String? error,
  }) {
    return MomentsState(
      moments: moments ?? this.moments,
      userMoments: userMoments ?? this.userMoments,
      userGroups: userGroups ?? this.userGroups,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      error: error,
    );
  }
}

@riverpod
class Moments extends _$Moments {
  MomentsRepository get _repository => ref.read(momentsRepositoryProvider);

  @override
  MomentsState build() {
    return const MomentsState();
  }

  // Create a new moment (24h expiration)
  Future<String?> createMoment({
    required String content,
    required MomentType type,
    required MomentPrivacy privacy,
    required List<String> selectedContacts,
    File? videoFile,
    List<File>? imageFiles,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      state = state.copyWith(error: 'User not authenticated');
      return null;
    }

    state = state.copyWith(isCreating: true, error: null);

    try {
      final momentId = const Uuid().v4();
      final now = DateTime.now();
      
      final moment = MomentModel(
        id: momentId,
        authorId: currentUser.uid,
        authorName: currentUser.name,
        authorImage: currentUser.image,
        content: content,
        type: type,
        imageUrls: const [],
        privacy: privacy,
        selectedContacts: selectedContacts,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)), // Changed to 24h
        likesCount: 0,
        commentsCount: 0,
        viewsCount: 0,
        likedBy: const [],
        viewedBy: const [],
        isActive: true,
        metadata: _buildMetadata(type, videoFile, imageFiles),
      );

      final createdMomentId = await _repository.createMoment(
        moment,
        videoFile: videoFile,
        imageFiles: imageFiles,
      );

      state = state.copyWith(isCreating: false);
      return createdMomentId;
    } on MomentsRepositoryException catch (e) {
      state = state.copyWith(isCreating: false, error: e.message);
      return null;
    } catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());
      return null;
    }
  }

  // Delete a moment
  Future<bool> deleteMoment(String momentId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      state = state.copyWith(error: 'User not authenticated');
      return false;
    }

    try {
      await _repository.deleteMoment(momentId, currentUser.uid);
      
      // Remove from local state
      final updatedMoments = state.moments.where((m) => m.id != momentId).toList();
      final updatedUserMoments = state.userMoments.where((m) => m.id != momentId).toList();
      
      state = state.copyWith(
        moments: updatedMoments,
        userMoments: updatedUserMoments,
      );
      
      return true;
    } on MomentsRepositoryException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Like/unlike a moment
  Future<void> toggleLikeMoment(String momentId, bool isCurrentlyLiked) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _repository.likeMoment(momentId, currentUser.uid, !isCurrentlyLiked);
      
      // Update local state optimistically
      final updatedMoments = state.moments.map((moment) {
        if (moment.id == momentId) {
          final newLikedBy = List<String>.from(moment.likedBy);
          if (isCurrentlyLiked) {
            newLikedBy.remove(currentUser.uid);
          } else {
            newLikedBy.add(currentUser.uid);
          }
          
          return moment.copyWith(
            likedBy: newLikedBy,
            likesCount: newLikedBy.length,
          );
        }
        return moment;
      }).toList();

      state = state.copyWith(moments: updatedMoments);
    } on MomentsRepositoryException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  // Record a view
  Future<void> recordView(String momentId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _repository.recordView(momentId, currentUser.uid);
    } catch (e) {
      // Don't show error for view recording failures
      debugPrint('Failed to record view: $e');
    }
  }

  // Cleanup expired moments
  Future<void> cleanupExpiredMoments() async {
    try {
      await _repository.cleanupExpiredMoments();
    } catch (e) {
      debugPrint('Failed to cleanup expired moments: $e');
    }
  }

  // Helper method to build metadata
  Map<String, dynamic> _buildMetadata(MomentType type, File? videoFile, List<File>? imageFiles) {
    final metadata = <String, dynamic>{};
    
    if (type == MomentType.video && videoFile != null) {
      metadata['originalVideoPath'] = videoFile.path;
      metadata['videoSize'] = videoFile.lengthSync();
    } else if (type == MomentType.images && imageFiles != null) {
      metadata['imageCount'] = imageFiles.length;
      metadata['totalSize'] = imageFiles.fold<int>(0, (sum, file) => sum + file.lengthSync());
    }
    
    return metadata;
  }
}

// Simplified stream provider for user-grouped moments (chronological)
@riverpod
Stream<List<UserMomentGroup>> userGroupedMomentsStream(UserGroupedMomentsStreamRef ref) {
  final currentUser = ref.watch(currentUserProvider);
  final repository = ref.watch(momentsRepositoryProvider);
  
  if (currentUser == null) {
    return Stream.value([]);
  }

  return repository.getMomentsStreamChronological(currentUser.uid, currentUser.contactsUIDs)
      .map((moments) => _groupMomentsByUserChronological(moments, currentUser.uid));
}

// Helper function to group moments by user with chronological logic
List<UserMomentGroup> _groupMomentsByUserChronological(List<MomentModel> moments, String currentUserId) {
  // Group moments by author
  final Map<String, List<MomentModel>> groupedMoments = {};
  
  for (final moment in moments) {
    if (!groupedMoments.containsKey(moment.authorId)) {
      groupedMoments[moment.authorId] = [];
    }
    groupedMoments[moment.authorId]!.add(moment);
  }

  // Convert to UserMomentGroup list
  final List<UserMomentGroup> userGroups = [];
  
  for (final entry in groupedMoments.entries) {
    final userId = entry.key;
    final userMoments = entry.value;
    
    if (userMoments.isNotEmpty) {
      // Sort user's moments chronologically (earliest first)
      userMoments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      final firstMoment = userMoments.first;
      userGroups.add(UserMomentGroup(
        userId: userId,
        userName: firstMoment.authorName,
        userImage: firstMoment.authorImage,
        moments: userMoments,
        isMyMoments: userId == currentUserId,
      ));
    }
  }

  // Sort user groups by earliest moment time (pure chronological)
  userGroups.sort((a, b) {
    final aEarliest = a.earliestMoment?.createdAt ?? DateTime(1970);
    final bEarliest = b.earliestMoment?.createdAt ?? DateTime(1970);
    return aEarliest.compareTo(bEarliest);
  });

  return userGroups;
}

// Stream provider for moments feed (pure chronological)
@riverpod
Stream<List<MomentModel>> momentsFeedStream(MomentsFeedStreamRef ref) {
  final currentUser = ref.watch(currentUserProvider);
  final repository = ref.watch(momentsRepositoryProvider);
  
  if (currentUser == null) {
    return Stream.value([]);
  }

  return repository.getMomentsStreamChronological(currentUser.uid, currentUser.contactsUIDs);
}

// Stream provider for user's moments (chronological)
@riverpod
Stream<List<MomentModel>> userMomentsStream(UserMomentsStreamRef ref, String userId) {
  final repository = ref.watch(momentsRepositoryProvider);
  return repository.getUserMomentsStreamChronological(userId);
}

// Stream provider for moment comments
@riverpod
Stream<List<MomentCommentModel>> momentCommentsStream(MomentCommentsStreamRef ref, String momentId) {
  final repository = ref.watch(momentsRepositoryProvider);
  return repository.getMomentCommentsStream(momentId);
}

// Simple comment actions provider (not a family provider)
final momentCommentActionsProvider = Provider<MomentCommentActions>((ref) {
  return MomentCommentActions(ref);
});

class MomentCommentActions {
  final Ref ref;
  
  MomentCommentActions(this.ref);

  // Add a comment
  Future<bool> addComment({
    required String momentId,
    required String content,
    String? repliedToCommentId,
    String? repliedToAuthorName,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;

    try {
      final repository = ref.read(momentsRepositoryProvider);
      final commentId = const Uuid().v4();
      final comment = MomentCommentModel(
        id: commentId,
        momentId: momentId,
        authorId: currentUser.uid,
        authorName: currentUser.name,
        authorImage: currentUser.image,
        content: content,
        createdAt: DateTime.now(),
        repliedToCommentId: repliedToCommentId,
        repliedToAuthorName: repliedToAuthorName,
        likesCount: 0,
        likedBy: const [],
      );

      await repository.addComment(comment);
      return true;
    } on MomentsRepositoryException catch (e) {
      debugPrint('Failed to add comment: ${e.message}');
      return false;
    }
  }

  // Delete a comment
  Future<bool> deleteComment(String commentId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;

    try {
      final repository = ref.read(momentsRepositoryProvider);
      await repository.deleteComment(commentId, currentUser.uid);
      return true;
    } on MomentsRepositoryException catch (e) {
      debugPrint('Failed to delete comment: ${e.message}');
      return false;
    }
  }

  // Like/unlike a comment
  Future<void> toggleLikeComment(String commentId, bool isCurrentlyLiked) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final repository = ref.read(momentsRepositoryProvider);
      await repository.likeComment(commentId, currentUser.uid, !isCurrentlyLiked);
    } on MomentsRepositoryException catch (e) {
      debugPrint('Failed to toggle comment like: ${e.message}');
    }
  }
}