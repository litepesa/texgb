// lib/features/channels/providers/channel_posts_provider.dart
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/channels/models/channel_post_model.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';

part 'channel_posts_provider.g.dart';

// ============================
// CHANNEL POSTS LIST
// ============================

/// Get posts for a channel
@riverpod
class ChannelPosts extends _$ChannelPosts {
  @override
  Future<List<ChannelPost>> build(String channelId) async {
    final repository = ref.read(channelRepositoryProvider);
    return repository.getChannelPosts(channelId, page: 1, perPage: 20);
  }

  /// Load more posts (pagination)
  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = const AsyncValue.loading();

    final repository = ref.read(channelRepositoryProvider);
    final nextPage = (currentState.length ~/ 20) + 1;

    final newPosts = await repository.getChannelPosts(
      channelId,
      page: nextPage,
      perPage: 20,
    );

    state = AsyncValue.data([...currentState, ...newPosts]);
  }

  /// Refresh posts
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Add new post to top of list (after creation)
  void prependPost(ChannelPost post) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    state = AsyncValue.data([post, ...currentState]);
  }

  /// Update post in list
  void updatePost(ChannelPost updatedPost) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedList = currentState.map((post) {
      return post.id == updatedPost.id ? updatedPost : post;
    }).toList();

    state = AsyncValue.data(updatedList);
  }

  /// Remove post from list
  void removePost(String postId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final updatedList =
        currentState.where((post) => post.id != postId).toList();
    state = AsyncValue.data(updatedList);
  }
}

// ============================
// SINGLE POST PROVIDER
// ============================

/// Get single post by ID
@riverpod
Future<ChannelPost?> channelPost(ChannelPostRef ref, String postId) async {
  final repository = ref.read(channelRepositoryProvider);
  return repository.getPost(postId);
}

// ============================
// POST ACTIONS
// ============================

/// Post actions (create, delete, like, unlock)
@riverpod
class ChannelPostActions extends _$ChannelPostActions {
  @override
  FutureOr<void> build() {
    // No initial state
  }

  /// Create new post
  Future<ChannelPost?> createPost({
    required String channelId,
    required PostContentType contentType,
    String? text,
    File? mediaFile,
    List<File>? imageFiles,
    bool isPremium = false,
    int? priceCoins,
    int? previewDuration,
    Function(double)? onUploadProgress,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(channelRepositoryProvider);
      final post = await repository.createPost(
        channelId: channelId,
        contentType: contentType,
        text: text,
        mediaFile: mediaFile,
        imageFiles: imageFiles,
        isPremium: isPremium,
        priceCoins: priceCoins,
        previewDuration: previewDuration,
        onUploadProgress: onUploadProgress,
      );

      if (post != null) {
        // Invalidate channel posts to refresh
        ref.invalidate(channelPostsProvider(channelId));
      }

      state = const AsyncValue.data(null);
      return post;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Delete post
  Future<bool> deletePost(String postId, String channelId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.deletePost(postId);

      if (success) {
        // Invalidate channel posts
        ref.invalidate(channelPostsProvider(channelId));
        ref.invalidate(channelPostProvider(postId));
      }

      state = const AsyncValue.data(null);
      return success;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Like post
  Future<bool> likePost(String postId, String channelId) async {
    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.likePost(postId);

      if (success) {
        // Optimistically update the post
        ref.invalidate(channelPostProvider(postId));
        // Could also update in-place in the list for better UX
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Unlike post
  Future<bool> unlikePost(String postId, String channelId) async {
    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.unlikePost(postId);

      if (success) {
        ref.invalidate(channelPostProvider(postId));
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Unlock premium post (pay with coins)
  Future<bool> unlockPost(String postId, String channelId) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(channelRepositoryProvider);
      final success = await repository.unlockPost(postId);

      if (success) {
        // Invalidate post to show unlocked state
        ref.invalidate(channelPostProvider(postId));
        // Also invalidate user's wallet since coins were spent
        // ref.invalidate(walletProvider); // Assuming wallet provider exists
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
// UPLOAD PROGRESS PROVIDER
// ============================

/// Track upload progress for chunked uploads
@riverpod
class UploadProgress extends _$UploadProgress {
  @override
  double build() {
    return 0.0;
  }

  void updateProgress(double progress) {
    state = progress;
  }

  void reset() {
    state = 0.0;
  }
}
