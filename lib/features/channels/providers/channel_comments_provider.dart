// lib/features/channels/providers/channel_comments_provider.dart
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/channels/models/channel_comment_model.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';

part 'channel_comments_provider.g.dart';

// ============================
// COMMENTS LIST (Multi-threaded)
// ============================

/// Get comments for a post (top-level comments only initially)
@riverpod
class PostComments extends _$PostComments {
  @override
  Future<List<ChannelComment>> build(String postId) async {
    final repository = ref.read(channelRepositoryProvider);
    return repository.getPostComments(postId, page: 1, perPage: 50);
  }

  /// Load more comments (pagination)
  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = const AsyncValue.loading();

    final repository = ref.read(channelRepositoryProvider);
    final nextPage = (currentState.length ~/ 50) + 1;

    final newComments = await repository.getPostComments(
      postId,
      page: nextPage,
      perPage: 50,
    );

    state = AsyncValue.data([...currentState, ...newComments]);
  }

  /// Refresh comments
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Add new comment to top of list (after creation)
  void prependComment(ChannelComment comment) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data([comment, ...currentState]);
  }

  /// Update comment in list (e.g., after liking)
  void updateComment(ChannelComment updatedComment) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedList = _updateCommentRecursive(currentState, updatedComment);
    state = AsyncValue.data(updatedList);
  }

  /// Remove comment from list (soft delete)
  void removeComment(String commentId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedList = _removeCommentRecursive(currentState, commentId);
    state = AsyncValue.data(updatedList);
  }

  /// Add reply to a comment
  void addReply(String parentCommentId, ChannelComment reply) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedList =
        _addReplyRecursive(currentState, parentCommentId, reply);
    state = AsyncValue.data(updatedList);
  }

  // Helper: Update comment recursively in nested structure
  List<ChannelComment> _updateCommentRecursive(
    List<ChannelComment> comments,
    ChannelComment updatedComment,
  ) {
    return comments.map((comment) {
      if (comment.id == updatedComment.id) {
        return updatedComment;
      } else if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _updateCommentRecursive(comment.replies, updatedComment),
        );
      }
      return comment;
    }).toList();
  }

  // Helper: Remove comment recursively (soft delete - mark as deleted)
  List<ChannelComment> _removeCommentRecursive(
    List<ChannelComment> comments,
    String commentId,
  ) {
    return comments.map((comment) {
      if (comment.id == commentId) {
        return comment.copyWith(isDeleted: true, text: '[Comment deleted]');
      } else if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _removeCommentRecursive(comment.replies, commentId),
        );
      }
      return comment;
    }).toList();
  }

  // Helper: Add reply to parent comment recursively
  List<ChannelComment> _addReplyRecursive(
    List<ChannelComment> comments,
    String parentCommentId,
    ChannelComment reply,
  ) {
    return comments.map((comment) {
      if (comment.id == parentCommentId) {
        return comment.copyWith(
          replies: [reply, ...comment.replies],
          repliesCount: comment.repliesCount + 1,
        );
      } else if (comment.replies.isNotEmpty) {
        return comment.copyWith(
          replies: _addReplyRecursive(comment.replies, parentCommentId, reply),
        );
      }
      return comment;
    }).toList();
  }
}

/// Get replies for a specific comment (load more replies)
@riverpod
Future<List<ChannelComment>> commentReplies(
  CommentRepliesRef ref,
  String postId,
  String parentCommentId,
) async {
  final repository = ref.read(channelRepositoryProvider);
  return repository.getPostComments(
    postId,
    parentCommentId: parentCommentId,
    page: 1,
    perPage: 50,
  );
}

// ============================
// COMMENT ACTIONS
// ============================

/// Comment actions (create, delete, like, pin)
@riverpod
class CommentActions extends _$CommentActions {
  @override
  FutureOr<void> build() {
    // No initial state
  }

  /// Create new comment or reply
  Future<ChannelComment?> createComment({
    required String postId,
    required String text,
    String? parentCommentId,
    File? mediaFile,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(channelRepositoryProvider);
      final comment = await repository.createComment(
        postId: postId,
        text: text,
        parentCommentId: parentCommentId,
        mediaFile: mediaFile,
      );

      if (comment != null) {
        // Update comments list
        final commentsNotifier =
            ref.read(postCommentsProvider(postId).notifier);

        if (parentCommentId == null) {
          // Top-level comment
          commentsNotifier.prependComment(comment);
        } else {
          // Reply to existing comment
          commentsNotifier.addReply(parentCommentId, comment);
        }
      }

      state = const AsyncValue.data(null);
      return comment;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Delete comment
  Future<bool> deleteComment(String commentId, String postId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.deleteComment(commentId);

      if (success) {
        // Update comments list (soft delete)
        final commentsNotifier =
            ref.read(postCommentsProvider(postId).notifier);
        commentsNotifier.removeComment(commentId);
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Like comment
  Future<bool> likeComment(String commentId, String postId) async {
    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.likeComment(commentId);

      if (success) {
        // Optimistically update - would need current comment to increment likes
        // In production, fetch updated comment or increment locally
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Pin comment (admin/mod only)
  Future<bool> pinComment(String commentId, String postId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.pinComment(commentId);

      if (success) {
        // Refresh comments to show pinned state
        ref.invalidate(postCommentsProvider(postId));
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

// ============================
// COMMENT SORTING
// ============================

/// Comment sort type state
@riverpod
class CommentSort extends _$CommentSort {
  @override
  CommentSortType build() {
    return CommentSortType.top; // Default to top comments
  }

  void setSortType(CommentSortType sortType) {
    state = sortType;
  }
}

/// Sorted comments based on current sort type
@riverpod
Future<List<ChannelComment>> sortedComments(
  SortedCommentsRef ref,
  String postId,
) async {
  final comments = await ref.watch(postCommentsProvider(postId).future);
  final sortType = ref.watch(commentSortProvider);

  final sorted = List<ChannelComment>.from(comments);

  switch (sortType) {
    case CommentSortType.top:
      sorted.sort((a, b) => b.likes.compareTo(a.likes));
      break;
    case CommentSortType.new_:
      sorted.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      break;
    case CommentSortType.old:
      sorted.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return a.createdAt!.compareTo(b.createdAt!);
      });
      break;
  }

  return sorted;
}
