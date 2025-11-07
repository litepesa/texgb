// ===============================
// Channel Providers with Riverpod
// State management for channels feature
// ===============================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/models/video_model.dart';
import 'package:textgb/features/channels/models/channel_constants.dart';
import 'package:textgb/features/channels/repositories/channel_repository.dart';

part 'channel_provider.g.dart';

// ===============================
// REPOSITORY PROVIDER
// ===============================

@riverpod
ChannelRepository channelRepository(Ref ref) {
  return HttpChannelRepository();
}

// ===============================
// VIDEO FEED STATE
// ===============================

class VideoFeedState {
  final List<VideoModel> videos;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final DateTime? lastFetchTime;

  const VideoFeedState({
    this.videos = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.lastFetchTime,
  });

  VideoFeedState copyWith({
    List<VideoModel>? videos,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    DateTime? lastFetchTime,
  }) {
    return VideoFeedState(
      videos: videos ?? this.videos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      lastFetchTime: lastFetchTime ?? this.lastFetchTime,
    );
  }

  bool get shouldRefresh {
    if (lastFetchTime == null) return true;
    final diff = DateTime.now().difference(lastFetchTime!);
    return diff > ChannelConstants.feedCacheDuration;
  }
}

// ===============================
// VIDEO FEED PROVIDER (Following Feed)
// ===============================

@riverpod
class VideoFeed extends _$VideoFeed {
  ChannelRepository get _repository => ref.read(channelRepositoryProvider);
  SharedPreferences? _prefs;

  @override
  Future<VideoFeedState> build() async {
    _prefs = await SharedPreferences.getInstance();

    // Load from cache first
    final cachedState = await _loadFromCache();
    if (cachedState != null && !cachedState.shouldRefresh) {
      _refreshInBackground();
      return cachedState;
    }

    // Fetch fresh data
    return await _fetchFeed(page: 1, isRefresh: true);
  }

  Future<VideoFeedState?> _loadFromCache() async {
    try {
      final cachedJson = _prefs?.getString(ChannelConstants.feedCacheKey);
      if (cachedJson == null) return null;

      final data = jsonDecode(cachedJson) as Map<String, dynamic>;
      final videos = (data['videos'] as List?)
          ?.map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final lastFetchTime = data['lastFetchTime'] != null
          ? DateTime.parse(data['lastFetchTime'] as String)
          : null;

      return VideoFeedState(
        videos: videos ?? [],
        lastFetchTime: lastFetchTime,
        currentPage: data['currentPage'] as int? ?? 1,
        hasMore: data['hasMore'] as bool? ?? true,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveToCache(VideoFeedState feedState) async {
    try {
      final data = {
        'videos': feedState.videos.map((v) => v.toJson()).toList(),
        'lastFetchTime': feedState.lastFetchTime?.toIso8601String(),
        'currentPage': feedState.currentPage,
        'hasMore': feedState.hasMore,
      };
      await _prefs?.setString(ChannelConstants.feedCacheKey, jsonEncode(data));
    } catch (e) {
      // Cache save failed
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final newVideos = await _repository.getFeed(page: 1, limit: ChannelConstants.feedPageSize);

      if (newVideos.isNotEmpty) {
        final newState = VideoFeedState(
          videos: newVideos,
          lastFetchTime: DateTime.now(),
          currentPage: 1,
          hasMore: newVideos.length >= ChannelConstants.feedPageSize,
        );

        state = AsyncValue.data(newState);
        await _saveToCache(newState);
      }
    } catch (e) {
      // Silent fail for background refresh
    }
  }

  Future<VideoFeedState> _fetchFeed({required int page, required bool isRefresh}) async {
    try {
      final videos = await _repository.getFeed(page: page, limit: ChannelConstants.feedPageSize);

      final newState = VideoFeedState(
        videos: videos,
        lastFetchTime: DateTime.now(),
        currentPage: page,
        hasMore: videos.length >= ChannelConstants.feedPageSize,
      );

      await _saveToCache(newState);
      return newState;
    } catch (e) {
      throw Exception('Failed to load feed: $e');
    }
  }

  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      final newState = await _fetchFeed(page: 1, isRefresh: true);
      state = AsyncValue.data(newState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    try {
      final nextPage = currentState.currentPage + 1;
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

      final newVideos = await _repository.getFeed(page: nextPage, limit: ChannelConstants.feedPageSize);

      final updatedState = currentState.copyWith(
        videos: [...currentState.videos, ...newVideos],
        currentPage: nextPage,
        hasMore: newVideos.length >= ChannelConstants.feedPageSize,
        isLoadingMore: false,
        lastFetchTime: DateTime.now(),
      );

      state = AsyncValue.data(updatedState);
      await _saveToCache(updatedState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateVideo(VideoModel updatedVideo) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedVideos = currentState.videos.map((v) {
      return v.id == updatedVideo.id ? updatedVideo : v;
    }).toList();

    final updatedState = currentState.copyWith(videos: updatedVideos);
    state = AsyncValue.data(updatedState);
    _saveToCache(updatedState);
  }

  Future<void> toggleLike(String videoId, bool currentlyLiked) async {
    try {
      final currentState = state.value;
      if (currentState != null) {
        final updatedVideos = currentState.videos.map((v) {
          if (v.id == videoId) {
            return v.copyWith(
              isLiked: !currentlyLiked,
              likes: currentlyLiked ? v.likes - 1 : v.likes + 1,
            );
          }
          return v;
        }).toList();

        state = AsyncValue.data(currentState.copyWith(videos: updatedVideos));
      }

      // TODO: Make API call to like/unlike
      // await _repository.likeVideo(videoId);
    } catch (e) {
      // Revert on error
      final currentState = state.value;
      if (currentState != null) {
        final revertedVideos = currentState.videos.map((v) {
          if (v.id == videoId) {
            return v.copyWith(
              isLiked: currentlyLiked,
              likes: currentlyLiked ? v.likes + 1 : v.likes - 1,
            );
          }
          return v;
        }).toList();

        state = AsyncValue.data(currentState.copyWith(videos: revertedVideos));
      }
      rethrow;
    }
  }
}

// ===============================
// DISCOVER FEED PROVIDER
// ===============================

@riverpod
class DiscoverFeed extends _$DiscoverFeed {
  ChannelRepository get _repository => ref.read(channelRepositoryProvider);

  @override
  Future<VideoFeedState> build() async {
    return await _fetchFeed(page: 1);
  }

  Future<VideoFeedState> _fetchFeed({required int page}) async {
    try {
      final videos = await _repository.getDiscoverFeed(page: page, limit: ChannelConstants.feedPageSize);

      return VideoFeedState(
        videos: videos,
        lastFetchTime: DateTime.now(),
        currentPage: page,
        hasMore: videos.length >= ChannelConstants.feedPageSize,
      );
    } catch (e) {
      throw Exception('Failed to load discover feed: $e');
    }
  }

  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      final newState = await _fetchFeed(page: 1);
      state = AsyncValue.data(newState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    try {
      final nextPage = currentState.currentPage + 1;
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

      final newVideos = await _repository.getDiscoverFeed(page: nextPage, limit: ChannelConstants.feedPageSize);

      final updatedState = currentState.copyWith(
        videos: [...currentState.videos, ...newVideos],
        currentPage: nextPage,
        hasMore: newVideos.length >= ChannelConstants.feedPageSize,
        isLoadingMore: false,
        lastFetchTime: DateTime.now(),
      );

      state = AsyncValue.data(updatedState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ===============================
// MY CHANNEL PROVIDER
// ===============================

@riverpod
class MyChannel extends _$MyChannel {
  ChannelRepository get _repository => ref.read(channelRepositoryProvider);

  @override
  Future<ChannelModel?> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return null;

    return await _repository.getUserChannel(currentUser.id);
  }

  Future<void> refresh() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getUserChannel(currentUser.id));
  }
}

// ===============================
// CHANNEL DETAIL PROVIDER
// ===============================

@riverpod
Future<ChannelModel> channel(Ref ref, String channelId) async {
  final repository = ref.read(channelRepositoryProvider);
  return await repository.getChannel(channelId);
}

// ===============================
// CHANNEL VIDEOS PROVIDER
// ===============================

@riverpod
class ChannelVideos extends _$ChannelVideos {
  ChannelRepository get _repository => ref.read(channelRepositoryProvider);

  @override
  Future<List<VideoModel>> build(String channelId) async {
    return await _repository.getChannelVideos(channelId, page: 1, limit: ChannelConstants.profileVideosPageSize);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getChannelVideos(channelId, page: 1, limit: ChannelConstants.profileVideosPageSize));
  }
}

// ===============================
// CREATE CHANNEL PROVIDER
// ===============================

@riverpod
class CreateChannel extends _$CreateChannel {
  ChannelRepository get _repository => ref.read(channelRepositoryProvider);

  @override
  FutureOr<ChannelModel?> build() {
    return null;
  }

  Future<ChannelModel> create(CreateChannelRequest request) async {
    try {
      state = const AsyncValue.loading();

      final channel = await _repository.createChannel(request);

      // Update myChannel provider
      ref.invalidate(myChannelProvider);

      state = AsyncValue.data(channel);
      return channel;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// ===============================
// UPDATE CHANNEL PROVIDER
// ===============================

@riverpod
class UpdateChannel extends _$UpdateChannel {
  ChannelRepository get _repository => ref.read(channelRepositoryProvider);

  @override
  FutureOr<ChannelModel?> build() {
    return null;
  }

  Future<ChannelModel> updateChannel(String channelId, UpdateChannelRequest request) async {
    try {
      state = const AsyncValue.loading();

      final channel = await _repository.updateChannel(channelId, request);

      // Update myChannel provider
      ref.invalidate(myChannelProvider);
      ref.invalidate(channelProvider(channelId));

      state = AsyncValue.data(channel);
      return channel;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// ===============================
// FOLLOW CHANNEL PROVIDER
// ===============================

@riverpod
class FollowChannel extends _$FollowChannel {
  ChannelRepository get _repository => ref.read(channelRepositoryProvider);

  @override
  FutureOr<bool> build() {
    return false;
  }

  Future<void> toggle(String channelId, bool currentlyFollowing) async {
    try {
      // Optimistic update
      state = AsyncValue.data(!currentlyFollowing);

      if (currentlyFollowing) {
        await _repository.unfollowChannel(channelId);
      } else {
        await _repository.followChannel(channelId);
      }

      // Invalidate channel to refresh follower count
      ref.invalidate(channelProvider(channelId));
    } catch (e, st) {
      // Revert on error
      state = AsyncValue.data(currentlyFollowing);
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
