import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/status_repository.dart';
import '../../domain/models/status_post.dart';
import '../../domain/models/status_privacy.dart';
import '../../domain/models/status_comment.dart';
import '../../domain/models/status_reaction.dart';
import '../../core/failures.dart';
import '../state/status_state.dart';

/// Controller for all status-related operations
class StatusController {
  final StatusRepository _repository;
  
  StatusController({required StatusRepository repository}) : _repository = repository;
  
  /// Create a new status post
  Future<Either<Failure, StatusPost>> createStatusPost({
    required String authorId,
    required String authorName,
    required String authorImage,
    required String content,
    required StatusPrivacy privacy,
    List<File>? mediaFiles,
    String? location,
    String? linkUrl,
  }) async {
    return _repository.createStatusPost(
      authorId: authorId,
      authorName: authorName,
      authorImage: authorImage,
      content: content,
      privacy: privacy,
      mediaFiles: mediaFiles,
      location: location,
      linkUrl: linkUrl,
    );
  }
  
  /// Delete a status post
  Future<Either<Failure, Unit>> deleteStatusPost({
    required String postId,
    required String authorId,
  }) async {
    return _repository.deleteStatusPost(
      postId: postId,
      authorId: authorId,
    );
  }
  
  /// Add a comment to a status post
  Future<Either<Failure, StatusComment>> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String userImage,
    required String content,
    String? replyToCommentId,
    String? replyToUserId,
    String? replyToUserName,
  }) async {
    return _repository.addComment(
      postId: postId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      content: content,
      replyToCommentId: replyToCommentId,
      replyToUserId: replyToUserId,
      replyToUserName: replyToUserName,
    );
  }
  
  /// Add a reaction to a status post
  Future<Either<Failure, StatusReaction>> addReaction({
    required String postId,
    required String userId,
    required String userName,
    required String userImage,
    required ReactionType reactionType,
  }) async {
    return _repository.addReaction(
      postId: postId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      reactionType: reactionType,
    );
  }
  
  /// Remove a reaction from a status post
  Future<Either<Failure, Unit>> removeReaction({
    required String reactionId,
    required String postId,
    required String userId,
  }) async {
    return _repository.removeReaction(
      reactionId: reactionId,
      postId: postId,
      userId: userId,
    );
  }
  
  /// Update muted users list
  Future<Either<Failure, Unit>> updateMutedUsers({
    required String userId,
    required List<String> mutedUserIds,
  }) async {
    return _repository.updateMutedUsers(
      userId: userId,
      mutedUserIds: mutedUserIds,
    );
  }
  
  /// Check if user has posted recently
  Future<Either<Failure, bool>> hasUserPostedRecently(String userId) async {
    return _repository.hasUserPostedRecently(userId);
  }
}

/// Notifier for muted users
class MutedUsersNotifier extends StateNotifier<List<String>> {
  final StatusRepository _repository;
  
  MutedUsersNotifier(this._repository) : super([]) {
    // State is initially empty, loaded when needed
  }
  
  /// Load muted users for a user
  Future<void> loadMutedUsers(String userId) async {
    final result = await _repository.getMutedUsers(userId);
    result.fold(
      (failure) => state = [],
      (mutedUsers) => state = mutedUsers,
    );
  }
  
  /// Mute a user
  Future<void> muteUser(String userId, String userToMuteId) async {
    if (state.contains(userToMuteId)) return;
    
    final newMutedUsers = [...state, userToMuteId];
    state = newMutedUsers;
    
    await _repository.updateMutedUsers(
      userId: userId,
      mutedUserIds: newMutedUsers,
    );
  }
  
  /// Unmute a user
  Future<void> unmuteUser(String userId, String userToUnmuteId) async {
    if (!state.contains(userToUnmuteId)) return;
    
    final newMutedUsers = state.where((id) => id != userToUnmuteId).toList();
    state = newMutedUsers;
    
    await _repository.updateMutedUsers(
      userId: userId,
      mutedUserIds: newMutedUsers,
    );
  }
}

/// Notifier for status feed
class StatusFeedNotifier extends StateNotifier<StatusFeedState> {
  final StatusRepository _repository;
  static const int _pageSize = 10;
  
  StatusFeedNotifier({required StatusRepository repository})
      : _repository = repository,
        super(StatusFeedState.initial());
  
  /// Load initial status feed
  Future<void> loadStatusFeed({
    required String userId,
    required List<String> contactIds,
    required List<String> mutedUserIds,
  }) async {
    state = StatusFeedState.loading();
    
    final result = await _repository.getStatusFeed(
      userId: userId,
      contactIds: contactIds,
      mutedUserIds: mutedUserIds,
      limit: _pageSize,
    );
    
    state = result.fold(
      (failure) => StatusFeedState.error(failure),
      (posts) {
        final hasMore = posts.length >= _pageSize;
        final lastPostId = posts.isNotEmpty ? posts.last.id : null;
        
        return StatusFeedState.loaded(
          posts: posts,
          hasMore: hasMore,
          lastPostId: lastPostId,
        );
      },
    );
  }
  
  /// Load more posts (pagination)
  Future<void> loadMorePosts({
    required String userId,
    required List<String> contactIds,
    required List<String> mutedUserIds,
  }) async {
    if (!state.hasMore || state.isLoading) return;
    
    final currentPosts = state.posts;
    final lastPostId = state.lastPostId;
    
    if (lastPostId == null) return;
    
    state = state.copyWith(isLoading: true);
    
    final result = await _repository.getStatusFeed(
      userId: userId,
      contactIds: contactIds,
      mutedUserIds: mutedUserIds,
      limit: _pageSize,
      lastPostId: lastPostId,
    );
    
    state = result.fold(
      (failure) => state.copyWith(failure: failure, isLoading: false),
      (newPosts) {
        final allPosts = [...currentPosts, ...newPosts];
        final hasMore = newPosts.length >= _pageSize;
        final lastPostId = newPosts.isNotEmpty ? newPosts.last.id : state.lastPostId;
        
        return StatusFeedState.loaded(
          posts: allPosts,
          hasMore: hasMore,
          lastPostId: lastPostId,
        );
      },
    );
  }
  
  /// Refresh the feed
  Future<void> refreshFeed({
    required String userId,
    required List<String> contactIds,
    required List<String> mutedUserIds,
  }) async {
    await loadStatusFeed(
      userId: userId,
      contactIds: contactIds,
      mutedUserIds: mutedUserIds,
    );
  }
  
  /// Add a new post to the feed
  void addPost(StatusPost post) {
    final updatedPosts = [post, ...state.posts];
    state = state.copyWith(posts: updatedPosts);
  }
  
  /// Remove a post from the feed
  void removePost(String postId) {
    final updatedPosts = state.posts.where((post) => post.id != postId).toList();
    state = state.copyWith(posts: updatedPosts);
  }
  
  /// Update a post in the feed
  void updatePost(StatusPost updatedPost) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == updatedPost.id) {
        return updatedPost;
      }
      return post;
    }).toList();
    
    state = state.copyWith(posts: updatedPosts);
  }
}

/// Notifier for current user's posts
class MyStatusPostsNotifier extends StateNotifier<StatusPostsState> {
  final StatusRepository _repository;
  
  MyStatusPostsNotifier({required StatusRepository repository})
      : _repository = repository,
        super(StatusPostsState.initial());
  
  /// Load user's own posts
  Future<void> loadMyPosts({
    required String userId,
    required List<String> contactIds,
  }) async {
    state = StatusPostsState.loading();
    
    final result = await _repository.getStatusFeed(
      userId: userId,
      contactIds: contactIds,
      mutedUserIds: [], // No muted users for own posts
    );
    
    state = result.fold(
      (failure) => StatusPostsState.error(failure),
      (posts) {
        // Filter to get only the user's own posts
        final myPosts = posts.where((post) => post.authorId == userId).toList();
        return StatusPostsState.loaded(myPosts);
      },
    );
  }
  
  /// Add a new post
  void addPost(StatusPost post) {
    final updatedPosts = [post, ...state.posts];
    state = state.copyWith(posts: updatedPosts);
  }
  
  /// Remove a post
  void removePost(String postId) {
    final updatedPosts = state.posts.where((post) => post.id != postId).toList();
    state = state.copyWith(posts: updatedPosts);
  }
  
  /// Update a post
  void updatePost(StatusPost updatedPost) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == updatedPost.id) {
        return updatedPost;
      }
      return post;
    }).toList();
    
    state = state.copyWith(posts: updatedPosts);
  }
}

/// Notifier for a single status post with comments
class StatusDetailNotifier extends StateNotifier<StatusDetailState> {
  final StatusRepository _repository;
  final String _postId;
  
  StatusDetailNotifier({
    required StatusRepository repository,
    required String postId,
  }) : _repository = repository,
       _postId = postId,
       super(StatusDetailState.initial());
  
  /// Load a status post and its comments
  Future<void> loadPost() async {
    state = StatusDetailState.loading();
    
    final result = await _repository.getStatusPost(_postId);
    
    state = result.fold(
      (failure) => StatusDetailState.error(failure),
      (post) => StatusDetailState.loaded(
        post: post,
        comments: post.comments,
      ),
    );
  }
  
  /// Mark post as viewed
  Future<void> viewPost(String viewerId) async {
    if (state.post == null) return;
    
    // Only view if not already viewed
    if (!state.post!.viewerIds.contains(viewerId)) {
      await _repository.viewStatusPost(
        postId: _postId,
        viewerId: viewerId,
      );
      
      // Update local state
      if (state.post != null) {
        final updatedViewerIds = [...state.post!.viewerIds, viewerId];
        final updatedViewCount = state.post!.viewCount + 1;
        
        state = state.copyWith(
          post: state.post!.copyWith(
            viewerIds: updatedViewerIds,
            viewCount: updatedViewCount,
          ),
        );
      }
    }
  }
  
  /// Add a comment
  Future<void> addComment({
    required String userId,
    required String userName,
    required String userImage,
    required String content,
    String? replyToCommentId,
    String? replyToUserId,
    String? replyToUserName,
  }) async {
    if (state.post == null) return;
    
    final result = await _repository.addComment(
      postId: _postId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      content: content,
      replyToCommentId: replyToCommentId,
      replyToUserId: replyToUserId,
      replyToUserName: replyToUserName,
    );
    
    result.fold(
      (failure) => state = state.copyWith(failure: failure),
      (comment) {
        final updatedComments = [...state.comments, comment];
        state = state.copyWith(comments: updatedComments);
      },
    );
  }
  
  /// Delete a comment
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    if (state.post == null) return;
    
    final result = await _repository.deleteComment(
      commentId: commentId,
      postId: _postId,
      userId: userId,
    );
    
    result.fold(
      (failure) => state = state.copyWith(failure: failure),
      (_) {
        final updatedComments = state.comments
            .where((comment) => comment.id != commentId)
            .toList();
        state = state.copyWith(comments: updatedComments);
      },
    );
  }
  
  /// Add a reaction
  Future<void> addReaction({
    required String userId,
    required String userName,
    required String userImage,
    required ReactionType reactionType,
  }) async {
    if (state.post == null) return;
    
    final result = await _repository.addReaction(
      postId: _postId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      reactionType: reactionType,
    );
    
    result.fold(
      (failure) => state = state.copyWith(failure: failure),
      (reaction) {
        // Remove existing reaction by this user if any
        final reactions = state.post!.reactions
            .where((r) => r.userId != userId)
            .toList();
        
        // Add the new reaction
        reactions.add(reaction);
        
        state = state.copyWith(
          post: state.post!.copyWith(reactions: reactions),
        );
      },
    );
  }
  
  /// Remove a reaction
  Future<void> removeReaction({
    required String reactionId,
    required String userId,
  }) async {
    if (state.post == null) return;
    
    final result = await _repository.removeReaction(
      reactionId: reactionId,
      postId: _postId,
      userId: userId,
    );
    
    result.fold(
      (failure) => state = state.copyWith(failure: failure),
      (_) {
        final updatedReactions = state.post!.reactions
            .where((reaction) => reaction.id != reactionId)
            .toList();
        
        state = state.copyWith(
          post: state.post!.copyWith(reactions: updatedReactions),
        );
      },
    );
  }
}

/// Notifier for selected media files
class SelectedMediaNotifier extends StateNotifier<List<File>> {
  SelectedMediaNotifier() : super([]);
  
  /// Add a media file
  void addMedia(File file) {
    state = [...state, file];
  }
  
  /// Remove a media file
  void removeMedia(File file) {
    state = state.where((f) => f.path != file.path).toList();
  }
  
  /// Clear all media
  void clearMedia() {
    state = [];
  }
  
  /// Replace all media with a new list
  void setMedia(List<File> files) {
    state = files;
  }
}