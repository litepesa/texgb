// lib/features/public_groups/providers/public_group_provider.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/models/public_group_post_model.dart';
import 'package:textgb/features/public_groups/models/post_comment_model.dart';
import 'package:textgb/features/public_groups/repositories/public_group_repository.dart';
import 'package:textgb/models/user_model.dart';

part 'public_group_provider.g.dart';

// Enhanced state class for public group management
class PublicGroupState {
  final bool isLoading;
  final List<PublicGroupModel> userPublicGroups;
  final List<PublicGroupModel> discoveredPublicGroups;
  final PublicGroupModel? currentPublicGroup;
  final List<PublicGroupPostModel> currentGroupPosts;
  final String? error;
  final bool hasPermissionError;
  final Map<String, bool> loadingStates;

  const PublicGroupState({
    this.isLoading = false,
    this.userPublicGroups = const [],
    this.discoveredPublicGroups = const [],
    this.currentPublicGroup,
    this.currentGroupPosts = const [],
    this.error,
    this.hasPermissionError = false,
    this.loadingStates = const {},
  });

  PublicGroupState copyWith({
    bool? isLoading,
    List<PublicGroupModel>? userPublicGroups,
    List<PublicGroupModel>? discoveredPublicGroups,
    PublicGroupModel? currentPublicGroup,
    List<PublicGroupPostModel>? currentGroupPosts,
    String? error,
    bool? hasPermissionError,
    Map<String, bool>? loadingStates,
  }) {
    return PublicGroupState(
      isLoading: isLoading ?? this.isLoading,
      userPublicGroups: userPublicGroups ?? this.userPublicGroups,
      discoveredPublicGroups: discoveredPublicGroups ?? this.discoveredPublicGroups,
      currentPublicGroup: currentPublicGroup ?? this.currentPublicGroup,
      currentGroupPosts: currentGroupPosts ?? this.currentGroupPosts,
      error: error,
      hasPermissionError: hasPermissionError ?? this.hasPermissionError,
      loadingStates: loadingStates ?? this.loadingStates,
    );
  }

  // Helper methods for checking loading states
  bool isOperationLoading(String operation) {
    return loadingStates[operation] ?? false;
  }

  PublicGroupState withLoadingState(String operation, bool loading) {
    final newLoadingStates = Map<String, bool>.from(loadingStates);
    if (loading) {
      newLoadingStates[operation] = true;
    } else {
      newLoadingStates.remove(operation);
    }
    return copyWith(loadingStates: newLoadingStates);
  }
}

@riverpod
class PublicGroupNotifier extends _$PublicGroupNotifier {
  late PublicGroupRepository _repository;

  @override
  FutureOr<PublicGroupState> build() {
    _repository = ref.read(publicGroupRepositoryProvider);
    
    // Initialize stream listeners
    _initPublicGroupListeners();
    
    return const PublicGroupState();
  }

  void _initPublicGroupListeners() {
    // Listen to the user public groups stream
    ref.listen(userPublicGroupsStreamProvider, (previous, next) {
      if (next.hasValue && state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(userPublicGroups: next.value!));
      }
    });
  }

  // Create a new public group
  Future<void> createPublicGroup({
    required String groupName,
    required String groupDescription,
    required File? groupImage,
    Map<String, dynamic>? settings,
  }) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('createPublicGroup', true));

    try {
      await _repository.createPublicGroup(
        groupName: groupName,
        groupDescription: groupDescription,
        groupImage: groupImage,
        settings: settings ?? {},
      );
      
      state = AsyncValue.data(state.value!.withLoadingState('createPublicGroup', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('createPublicGroup', false));
      rethrow;
    }
  }

  // Get public group details and posts
  Future<void> getPublicGroupDetails(String groupId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('getPublicGroupDetails', true));

    try {
      final publicGroup = await _repository.getPublicGroupById(groupId);
      
      if (publicGroup == null) {
        state = AsyncValue.data(state.value!.copyWith(
          error: 'Public group not found',
        ).withLoadingState('getPublicGroupDetails', false));
        return;
      }
      
      final posts = await _repository.getPublicGroupPosts(groupId);
      
      state = AsyncValue.data(state.value!.copyWith(
        currentPublicGroup: publicGroup,
        currentGroupPosts: posts,
        error: null,
        hasPermissionError: false,
      ).withLoadingState('getPublicGroupDetails', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('getPublicGroupDetails', false));
    }
  }

  // Subscribe to a public group
  Future<void> subscribeToPublicGroup(String groupId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('subscribe', true));

    try {
      await _repository.subscribeToPublicGroup(groupId);
      
      state = AsyncValue.data(state.value!.copyWith(
        error: null,
        hasPermissionError: false,
      ).withLoadingState('subscribe', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('subscribe', false));
      rethrow;
    }
  }

  // Unsubscribe from a public group
  Future<void> unsubscribeFromPublicGroup(String groupId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('unsubscribe', true));

    try {
      await _repository.unsubscribeFromPublicGroup(groupId);
      
      state = AsyncValue.data(state.value!.copyWith(
        error: null,
        hasPermissionError: false,
      ).withLoadingState('unsubscribe', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('unsubscribe', false));
      rethrow;
    }
  }

  // Create a post in public group
  Future<void> createPost({
    required String groupId,
    required String content,
    required MessageEnum postType,
    List<File>? mediaFiles,
    bool isPinned = false,
  }) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('createPost', true));

    try {
      await _repository.createPost(
        groupId: groupId,
        content: content,
        postType: postType,
        mediaFiles: mediaFiles,
        isPinned: isPinned,
      );
      
      // Refresh posts
      await getPublicGroupDetails(groupId);
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('createPost', false));
      rethrow;
    }
  }

  // Add reaction to post
  Future<void> addPostReaction(String postId, String emoji) async {
    if (!state.hasValue) return;

    try {
      await _repository.addPostReaction(postId, emoji);
      
      // Update current posts if we have them
      final currentPosts = state.value!.currentGroupPosts;
      final updatedPosts = currentPosts.map((post) {
        if (post.postId == postId) {
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            final updatedReactions = Map<String, dynamic>.from(post.reactions);
            updatedReactions[currentUser.uid] = {
              'emoji': emoji,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };
            return post.copyWith(
              reactions: updatedReactions,
              reactionsCount: updatedReactions.length,
            );
          }
        }
        return post;
      }).toList();
      
      state = AsyncValue.data(state.value!.copyWith(currentGroupPosts: updatedPosts));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ));
      rethrow;
    }
  }

  // Remove reaction from post
  Future<void> removePostReaction(String postId) async {
    if (!state.hasValue) return;

    try {
      await _repository.removePostReaction(postId);
      
      // Update current posts if we have them
      final currentPosts = state.value!.currentGroupPosts;
      final updatedPosts = currentPosts.map((post) {
        if (post.postId == postId) {
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            final updatedReactions = Map<String, dynamic>.from(post.reactions);
            updatedReactions.remove(currentUser.uid);
            return post.copyWith(
              reactions: updatedReactions,
              reactionsCount: updatedReactions.length,
            );
          }
        }
        return post;
      }).toList();
      
      state = AsyncValue.data(state.value!.copyWith(currentGroupPosts: updatedPosts));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ));
      rethrow;
    }
  }

  // Add comment to post
  Future<void> addComment({
    required String postId,
    required String content,
    String? repliedToCommentId,
  }) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('addComment', true));

    try {
      await _repository.addComment(
        postId: postId,
        content: content,
        repliedToCommentId: repliedToCommentId,
      );
      
      // Update the comments count for the post
      final currentPosts = state.value!.currentGroupPosts;
      final updatedPosts = currentPosts.map((post) {
        if (post.postId == postId) {
          return post.copyWith(commentsCount: post.commentsCount + 1);
        }
        return post;
      }).toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        currentGroupPosts: updatedPosts,
        error: null,
        hasPermissionError: false,
      ).withLoadingState('addComment', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('addComment', false));
      rethrow;
    }
  }

  // Get comments for a post
  Future<List<PostCommentModel>> getPostComments(String postId) async {
    try {
      return await _repository.getPostComments(postId);
    } catch (e) {
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(
          error: e.toString(),
          hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
        ));
      }
      return [];
    }
  }

  // Search public groups
  Future<List<PublicGroupModel>> searchPublicGroups(String query) async {
    if (query.isEmpty) return [];
    
    try {
      return await _repository.searchPublicGroups(query);
    } catch (e) {
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(
          error: e.toString(),
          hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
        ));
      }
      return [];
    }
  }

  // Get trending public groups
  Future<void> getTrendingPublicGroups() async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('getTrending', true));

    try {
      final trendingGroups = await _repository.getTrendingPublicGroups();
      
      state = AsyncValue.data(state.value!.copyWith(
        discoveredPublicGroups: trendingGroups,
        error: null,
        hasPermissionError: false,
      ).withLoadingState('getTrending', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('getTrending', false));
    }
  }

  // Update public group
  Future<void> updatePublicGroup({
    required PublicGroupModel updatedGroup,
    File? newGroupImage,
  }) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('updatePublicGroup', true));

    try {
      await _repository.updatePublicGroup(updatedGroup, newGroupImage);
      
      state = AsyncValue.data(state.value!.copyWith(
        currentPublicGroup: updatedGroup,
        error: null,
        hasPermissionError: false,
      ).withLoadingState('updatePublicGroup', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('updatePublicGroup', false));
      rethrow;
    }
  }

  // Pin/Unpin post
  Future<void> togglePostPin(String postId, bool isPinned) async {
    if (!state.hasValue) return;

    try {
      await _repository.togglePostPin(postId, isPinned);
      
      // Update current posts if we have them
      final currentPosts = state.value!.currentGroupPosts;
      final updatedPosts = currentPosts.map((post) {
        if (post.postId == postId) {
          return post.copyWith(isPinned: isPinned);
        }
        return post;
      }).toList();
      
      state = AsyncValue.data(state.value!.copyWith(currentGroupPosts: updatedPosts));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ));
      rethrow;
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('deletePost', true));

    try {
      await _repository.deletePost(postId);
      
      // Remove post from current posts
      final currentPosts = state.value!.currentGroupPosts;
      final updatedPosts = currentPosts.where((post) => post.postId != postId).toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        currentGroupPosts: updatedPosts,
        error: null,
        hasPermissionError: false,
      ).withLoadingState('deletePost', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('deletePost', false));
      rethrow;
    }
  }

  // Check if current user can post
  bool canCurrentUserPost(String groupId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;
    
    final currentGroup = state.value?.currentPublicGroup;
    if (currentGroup != null && currentGroup.groupId == groupId) {
      return currentGroup.canPost(currentUser.uid);
    }
    
    return false;
  }

  // Check if current user is subscribed
  bool isCurrentUserSubscribed(String groupId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;
    
    final currentGroup = state.value?.currentPublicGroup;
    if (currentGroup != null && currentGroup.groupId == groupId) {
      return currentGroup.isSubscriber(currentUser.uid);
    }
    
    return false;
  }

  // Clear error state
  void clearError() {
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(
        error: null,
        hasPermissionError: false,
      ));
    }
  }

  // Get current user ID safely
  String? getCurrentUserUid() {
    final currentUser = ref.read(currentUserProvider);
    return currentUser?.uid;
  }
}

// Stream provider for user's public groups
@riverpod
Stream<List<PublicGroupModel>> userPublicGroupsStream(UserPublicGroupsStreamRef ref) {
  final repository = ref.watch(publicGroupRepositoryProvider);
  return repository.getUserPublicGroups().handleError((error) {
    debugPrint('Error in user public groups stream: $error');
    return <PublicGroupModel>[];
  });
}

// Stream provider for public group posts
@riverpod
Stream<List<PublicGroupPostModel>> publicGroupPostsStream(
  PublicGroupPostsStreamRef ref,
  String groupId,
) {
  final repository = ref.watch(publicGroupRepositoryProvider);
  return repository.getPublicGroupPostsStream(groupId).handleError((error) {
    debugPrint('Error in public group posts stream: $error');
    return <PublicGroupPostModel>[];
  });
}

// Stream provider for post comments
@riverpod
Stream<List<PostCommentModel>> postCommentsStream(
  PostCommentsStreamRef ref,
  String postId,
) {
  final repository = ref.watch(publicGroupRepositoryProvider);
  return repository.getPostCommentsStream(postId).handleError((error) {
    debugPrint('Error in post comments stream: $error');
    return <PostCommentModel>[];
  });
}

// Use the auto-generated provider for PublicGroupNotifier
final publicGroupProvider = publicGroupNotifierProvider;