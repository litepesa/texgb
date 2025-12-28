// ===============================
// Moments Providers with Riverpod
// Comprehensive state management for moments feature
// ===============================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/models/moment_constants.dart';
import 'package:textgb/features/moments/repositories/moments_repository.dart';

part 'moments_providers.g.dart';

// ===============================
// REPOSITORY PROVIDER
// ===============================

@riverpod
MomentsRepository momentsRepository(Ref ref) {
  return HttpMomentsRepository();
}

// ===============================
// MOMENTS FEED STATE
// ===============================

class MomentsFeedState {
  final List<MomentModel> moments;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final DateTime? lastFetchTime;

  const MomentsFeedState({
    this.moments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
    this.lastFetchTime,
  });

  MomentsFeedState copyWith({
    List<MomentModel>? moments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
    DateTime? lastFetchTime,
  }) {
    return MomentsFeedState(
      moments: moments ?? this.moments,
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
    return diff > MomentConstants.feedCacheDuration;
  }
}

// ===============================
// MOMENTS FEED PROVIDER (Main Feed)
// ===============================

@riverpod
class MomentsFeed extends _$MomentsFeed {
  MomentsRepository get _repository => ref.read(momentsRepositoryProvider);
  SharedPreferences? _prefs;

  @override
  Future<MomentsFeedState> build() async {
    _prefs = await SharedPreferences.getInstance();

    // Load from cache first
    final cachedState = await _loadFromCache();
    if (cachedState != null && !cachedState.shouldRefresh) {
      // Return cached data and refresh in background
      _refreshInBackground();
      return cachedState;
    }

    // Fetch fresh data
    return await _fetchFeed(page: 1, isRefresh: true);
  }

  // Load cached feed
  Future<MomentsFeedState?> _loadFromCache() async {
    try {
      final cachedJson = _prefs?.getString(MomentConstants.feedCacheKey);
      if (cachedJson == null) return null;

      final data = jsonDecode(cachedJson) as Map<String, dynamic>;
      final moments = (data['moments'] as List?)
          ?.map((json) => MomentModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final lastFetchTime = data['lastFetchTime'] != null
          ? DateTime.parse(data['lastFetchTime'] as String)
          : null;

      return MomentsFeedState(
        moments: moments ?? [],
        lastFetchTime: lastFetchTime,
        currentPage: data['currentPage'] as int? ?? 1,
        hasMore: data['hasMore'] as bool? ?? true,
      );
    } catch (e) {
      return null;
    }
  }

  // Save to cache
  Future<void> _saveToCache(MomentsFeedState feedState) async {
    try {
      final data = {
        'moments': feedState.moments.map((m) => m.toJson()).toList(),
        'lastFetchTime': feedState.lastFetchTime?.toIso8601String(),
        'currentPage': feedState.currentPage,
        'hasMore': feedState.hasMore,
      };
      await _prefs?.setString(MomentConstants.feedCacheKey, jsonEncode(data));
    } catch (e) {
      // Cache save failed, continue without caching
    }
  }

  // Background refresh
  Future<void> _refreshInBackground() async {
    try {
      final newMoments = await _repository.getFeed(
        page: 1,
        limit: MomentConstants.feedPageSize,
      );

      if (newMoments.isNotEmpty) {
        final newState = MomentsFeedState(
          moments: newMoments,
          lastFetchTime: DateTime.now(),
          currentPage: 1,
          hasMore: newMoments.length >= MomentConstants.feedPageSize,
        );

        state = AsyncValue.data(newState);
        await _saveToCache(newState);
      }
    } catch (e) {
      // Silent fail for background refresh
    }
  }

  // Fetch feed
  Future<MomentsFeedState> _fetchFeed({
    required int page,
    required bool isRefresh,
  }) async {
    try {
      final moments = await _repository.getFeed(
        page: page,
        limit: MomentConstants.feedPageSize,
      );

      final newState = MomentsFeedState(
        moments: moments,
        lastFetchTime: DateTime.now(),
        currentPage: page,
        hasMore: moments.length >= MomentConstants.feedPageSize,
      );

      await _saveToCache(newState);
      return newState;
    } catch (e) {
      throw Exception('Failed to load feed: $e');
    }
  }

  // Refresh feed (pull to refresh)
  Future<void> refresh() async {
    try {
      state = const AsyncValue.loading();
      final newState = await _fetchFeed(page: 1, isRefresh: true);
      state = AsyncValue.data(newState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Load more (pagination)
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    try {
      final nextPage = currentState.currentPage + 1;
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

      final newMoments = await _repository.getFeed(
        page: nextPage,
        limit: MomentConstants.feedPageSize,
      );

      final updatedState = currentState.copyWith(
        moments: [...currentState.moments, ...newMoments],
        currentPage: nextPage,
        hasMore: newMoments.length >= MomentConstants.feedPageSize,
        isLoadingMore: false,
        lastFetchTime: DateTime.now(),
      );

      state = AsyncValue.data(updatedState);
      await _saveToCache(updatedState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Add new moment to feed
  void addMoment(MomentModel moment) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedState = currentState.copyWith(
      moments: [moment, ...currentState.moments],
    );
    state = AsyncValue.data(updatedState);
    _saveToCache(updatedState);
  }

  // Remove moment from feed
  void removeMoment(String momentId) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedState = currentState.copyWith(
      moments: currentState.moments.where((m) => m.id != momentId).toList(),
    );
    state = AsyncValue.data(updatedState);
    _saveToCache(updatedState);
  }

  // Update moment in feed (like, comment count changes)
  void updateMoment(MomentModel updatedMoment) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedMoments = currentState.moments.map((m) {
      return m.id == updatedMoment.id ? updatedMoment : m;
    }).toList();

    final updatedState = currentState.copyWith(moments: updatedMoments);
    state = AsyncValue.data(updatedState);
    _saveToCache(updatedState);
  }

  // Toggle like
  Future<void> toggleLike(String momentId, bool currentlyLiked) async {
    try {
      // Optimistic update
      final currentState = state.value;
      if (currentState != null) {
        final updatedMoments = currentState.moments.map((m) {
          if (m.id == momentId) {
            return m.copyWith(
              isLikedByMe: !currentlyLiked,
              likesCount: currentlyLiked ? m.likesCount - 1 : m.likesCount + 1,
            );
          }
          return m;
        }).toList();

        state = AsyncValue.data(currentState.copyWith(moments: updatedMoments));
      }

      // Make API call
      if (currentlyLiked) {
        await _repository.unlikeMoment(momentId);
      } else {
        await _repository.likeMoment(momentId);
      }
    } catch (e) {
      // Revert on error
      final currentState = state.value;
      if (currentState != null) {
        final revertedMoments = currentState.moments.map((m) {
          if (m.id == momentId) {
            return m.copyWith(
              isLikedByMe: currentlyLiked,
              likesCount: currentlyLiked ? m.likesCount + 1 : m.likesCount - 1,
            );
          }
          return m;
        }).toList();

        state = AsyncValue.data(currentState.copyWith(moments: revertedMoments));
      }
      rethrow;
    }
  }
}

// ===============================
// USER MOMENTS PROVIDER
// ===============================

@riverpod
class UserMoments extends _$UserMoments {
  MomentsRepository get _repository => ref.read(momentsRepositoryProvider);

  @override
  Future<List<MomentModel>> build(String userId) async {
    return await _repository.getUserMoments(userId, page: 1);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getUserMoments(userId, page: 1));
  }
}

// ===============================
// SINGLE MOMENT PROVIDER
// ===============================

@riverpod
Future<MomentModel?> moment(Ref ref, String momentId) async {
  final repository = ref.read(momentsRepositoryProvider);
  return await repository.getMoment(momentId);
}

// ===============================
// MOMENT COMMENTS PROVIDER
// ===============================

@riverpod
class MomentComments extends _$MomentComments {
  MomentsRepository get _repository => ref.read(momentsRepositoryProvider);

  @override
  Future<List<MomentCommentModel>> build(String momentId) async {
    return await _repository.getComments(momentId, page: 1);
  }

  Future<void> addComment(String content, {String? replyToUserId}) async {
    try {
      final newComment = await _repository.commentOnMoment(
        momentId,
        content,
        replyToUserId: replyToUserId,
      );

      final currentComments = state.value ?? [];
      state = AsyncValue.data([newComment, ...currentComments]);

      // Update moment's comment count in feed
      ref.read(momentsFeedProvider.notifier).updateMoment(
        (await ref.read(momentProvider(momentId).future))!.copyWith(
          commentsCount: currentComments.length + 1,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _repository.deleteComment(commentId);

      final currentComments = state.value ?? [];
      state = AsyncValue.data(
        currentComments.where((c) => c.id != commentId).toList(),
      );

      // Update moment's comment count
      ref.read(momentsFeedProvider.notifier).updateMoment(
        (await ref.read(momentProvider(momentId).future))!.copyWith(
          commentsCount: currentComments.length - 1,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ===============================
// MOMENT LIKES PROVIDER
// ===============================

@riverpod
Future<List<MomentLikerModel>> momentLikes(Ref ref, String momentId) async {
  final repository = ref.read(momentsRepositoryProvider);
  return await repository.getLikes(momentId, page: 1);
}

// ===============================
// PRIVACY SETTINGS PROVIDER
// ===============================

@riverpod
class MomentPrivacy extends _$MomentPrivacy {
  MomentsRepository get _repository => ref.read(momentsRepositoryProvider);

  @override
  Future<MomentPrivacySettings?> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) return null;

    return await _repository.getPrivacySettings(currentUser.id);
  }

  Future<void> updateSettings(UpdatePrivacyRequest request) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final updated = await _repository.updatePrivacySettings(
        currentUser.id,
        request,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ===============================
// CREATE MOMENT STATE PROVIDER
// ===============================

@riverpod
class CreateMoment extends _$CreateMoment {
  MomentsRepository get _repository => ref.read(momentsRepositoryProvider);

  @override
  FutureOr<MomentModel?> build() {
    return null;
  }

  Future<MomentModel> create(CreateMomentRequest request) async {
    print('[CREATE MOMENT PROVIDER] Starting create...');
    print('[CREATE MOMENT PROVIDER] Request: ${request.toJson()}');

    try {
      print('[CREATE MOMENT PROVIDER] Calling repository.createMoment...');
      final moment = await _repository.createMoment(request);
      print('[CREATE MOMENT PROVIDER] Moment created successfully: ${moment.id}');

      // Add to feed
      print('[CREATE MOMENT PROVIDER] Adding to feed...');
      ref.read(momentsFeedProvider.notifier).addMoment(moment);
      print('[CREATE MOMENT PROVIDER] Added to feed successfully');

      return moment;
    } catch (e, stackTrace) {
      print('[CREATE MOMENT PROVIDER] ERROR: $e');
      print('[CREATE MOMENT PROVIDER] Stack trace: $stackTrace');
      rethrow;
    }
  }
}

// ===============================
// DELETE MOMENT PROVIDER
// ===============================

@riverpod
class DeleteMoment extends _$DeleteMoment {
  MomentsRepository get _repository => ref.read(momentsRepositoryProvider);

  @override
  FutureOr<bool> build() {
    return false;
  }

  Future<bool> delete(String momentId) async {
    final success = await _repository.deleteMoment(momentId);

    if (success) {
      // Remove from feed
      ref.read(momentsFeedProvider.notifier).removeMoment(momentId);
    }

    return success;
  }
}
