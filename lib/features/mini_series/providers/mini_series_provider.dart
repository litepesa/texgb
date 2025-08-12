// lib/features/mini_series/providers/mini_series_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/mini_series_model.dart';
import '../models/episode_model.dart';
import '../models/comment_model.dart';
import '../models/analytics_model.dart';
import '../repositories/mini_series_repository.dart';
import '../../authentication/providers/auth_providers.dart';

part 'mini_series_provider.g.dart';

// Repository provider
final miniSeriesRepositoryProvider = Provider<MiniSeriesRepository>((ref) {
  return FirebaseMiniSeriesRepository();
});

// State classes
class MiniSeriesState {
  final bool isLoading;
  final String? error;
  final List<MiniSeriesModel> series;
  final MiniSeriesModel? currentSeries;
  final List<EpisodeModel> episodes;
  final EpisodeModel? currentEpisode;
  final List<EpisodeCommentModel> comments;
  final SeriesAnalyticsModel? analytics;

  const MiniSeriesState({
    this.isLoading = false,
    this.error,
    this.series = const [],
    this.currentSeries,
    this.episodes = const [],
    this.currentEpisode,
    this.comments = const [],
    this.analytics,
  });

  MiniSeriesState copyWith({
    bool? isLoading,
    String? error,
    List<MiniSeriesModel>? series,
    MiniSeriesModel? currentSeries,
    List<EpisodeModel>? episodes,
    EpisodeModel? currentEpisode,
    List<EpisodeCommentModel>? comments,
    SeriesAnalyticsModel? analytics,
  }) {
    return MiniSeriesState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      series: series ?? this.series,
      currentSeries: currentSeries ?? this.currentSeries,
      episodes: episodes ?? this.episodes,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      comments: comments ?? this.comments,
      analytics: analytics ?? this.analytics,
    );
  }
}

// Main mini-series provider
@riverpod
class MiniSeries extends _$MiniSeries {
  MiniSeriesRepository get _repository => ref.read(miniSeriesRepositoryProvider);

  @override
  FutureOr<MiniSeriesState> build() async {
    return const MiniSeriesState();
  }

  // Series operations
  Future<String?> createSeries({
    required String title,
    required String description,
    required String category,
    required List<String> tags,
    File? coverImage,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      state = AsyncValue.error('User not authenticated', StackTrace.current);
      return null;
    }

    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final series = MiniSeriesModel(
        seriesId: '',
        title: title,
        description: description,
        coverImageUrl: '',
        creatorUID: currentUser.uid,
        creatorName: currentUser.name,
        creatorImage: currentUser.image,
        tags: tags,
        category: category,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final seriesId = await _repository.createSeries(series, coverImage);
      
      // Refresh user's series list
      await loadUserSeries();
      
      state = AsyncValue.data(state.value!.copyWith(isLoading: false));
      return seriesId;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return null;
    }
  }

  Future<void> updateSeries(MiniSeriesModel series, {File? coverImage}) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      await _repository.updateSeries(series, coverImage);
      
      // Update local state
      final currentState = state.value!;
      final updatedSeries = currentState.series.map((s) =>
          s.seriesId == series.seriesId ? series : s).toList();
      
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        series: updatedSeries,
        currentSeries: series,
      ));
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> deleteSeries(String seriesId) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      await _repository.deleteSeries(seriesId);
      
      // Update local state
      final currentState = state.value!;
      final updatedSeries = currentState.series
          .where((s) => s.seriesId != seriesId)
          .toList();
      
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        series: updatedSeries,
        currentSeries: currentState.currentSeries?.seriesId == seriesId
            ? null
            : currentState.currentSeries,
      ));
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> loadSeries(String seriesId) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final series = await _repository.getSeriesById(seriesId);
      if (series != null) {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          currentSeries: series,
        ));
      } else {
        state = AsyncValue.error('Series not found', StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> loadUserSeries() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final userSeries = await _repository.getSeriesByCreator(currentUser.uid);
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        series: userSeries,
      ));
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> loadPublishedSeries({String? lastSeriesId}) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final publishedSeries = await _repository.getPublishedSeries(
        limit: 20,
        lastSeriesId: lastSeriesId,
      );
      
      final currentState = state.value!;
      final updatedSeries = lastSeriesId == null
          ? publishedSeries
          : [...currentState.series, ...publishedSeries];
      
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        series: updatedSeries,
      ));
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> searchSeries(String query) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final searchResults = await _repository.searchSeries(query);
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        series: searchResults,
      ));
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  // Episode operations
  Future<String?> createEpisode({
    required String seriesId,
    required String title,
    required String description,
    required int episodeNumber,
    required File videoFile,
    File? thumbnailFile,
    required Duration duration,
    bool isPublished = false,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final episode = EpisodeModel(
        episodeId: '',
        seriesId: seriesId,
        title: title,
        description: description,
        videoUrl: '',
        thumbnailUrl: '',
        episodeNumber: episodeNumber,
        duration: duration,
        createdAt: DateTime.now(),
        publishedAt: isPublished ? DateTime.now() : DateTime.now(),
        isPublished: isPublished,
      );

      final episodeId = await _repository.createEpisode(
        episode,
        videoFile,
        thumbnailFile,
      );
      
      // Refresh episodes for this series
      await loadEpisodes(seriesId);
      
      state = AsyncValue.data(state.value!.copyWith(isLoading: false));
      return episodeId;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return null;
    }
  }

  Future<void> updateEpisode(
    EpisodeModel episode, {
    File? videoFile,
    File? thumbnailFile,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      await _repository.updateEpisode(episode, videoFile, thumbnailFile);
      
      // Update local state
      final currentState = state.value!;
      final updatedEpisodes = currentState.episodes.map((e) =>
          e.episodeId == episode.episodeId ? episode : e).toList();
      
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        episodes: updatedEpisodes,
        currentEpisode: episode,
      ));
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> deleteEpisode(String episodeId) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      await _repository.deleteEpisode(episodeId);
      
      // Update local state
      final currentState = state.value!;
      final updatedEpisodes = currentState.episodes
          .where((e) => e.episodeId != episodeId)
          .toList();
      
      state = AsyncValue.data(currentState.copyWith(
        isLoading: false,
        episodes: updatedEpisodes,
        currentEpisode: currentState.currentEpisode?.episodeId == episodeId
            ? null
            : currentState.currentEpisode,
      ));
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> loadEpisodes(String seriesId) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final episodes = await _repository.getEpisodesBySeries(seriesId);
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        episodes: episodes,
      ));
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> loadEpisode(String episodeId) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final episode = await _repository.getEpisodeById(episodeId);
      if (episode != null) {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          currentEpisode: episode,
        ));
      } else {
        state = AsyncValue.error('Episode not found', StackTrace.current);
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> reorderEpisodes(String seriesId, List<String> episodeIds) async {
    try {
      await _repository.reorderEpisodes(seriesId, episodeIds);
      await loadEpisodes(seriesId);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  // Interaction operations
  Future<void> likeEpisode(String episodeId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _repository.likeEpisode(episodeId, currentUser.uid);
      
      // Update local state
      final currentState = state.value!;
      final updatedEpisodes = currentState.episodes.map((episode) {
        if (episode.episodeId == episodeId) {
          return episode.copyWith(
            likes: episode.likes + 1,
            likedBy: [...episode.likedBy, currentUser.uid],
          );
        }
        return episode;
      }).toList();
      
      state = AsyncValue.data(currentState.copyWith(episodes: updatedEpisodes));
    } catch (e) {
      debugPrint('Error liking episode: $e');
    }
  }

  Future<void> unlikeEpisode(String episodeId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _repository.unlikeEpisode(episodeId, currentUser.uid);
      
      // Update local state
      final currentState = state.value!;
      final updatedEpisodes = currentState.episodes.map((episode) {
        if (episode.episodeId == episodeId) {
          final updatedLikedBy = episode.likedBy.where((id) => id != currentUser.uid).toList();
          return episode.copyWith(
            likes: episode.likes - 1,
            likedBy: updatedLikedBy,
          );
        }
        return episode;
      }).toList();
      
      state = AsyncValue.data(currentState.copyWith(episodes: updatedEpisodes));
    } catch (e) {
      debugPrint('Error unliking episode: $e');
    }
  }

  Future<void> incrementView(String episodeId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _repository.incrementEpisodeView(episodeId, currentUser.uid);
      
      // Update local state
      final currentState = state.value!;
      final updatedEpisodes = currentState.episodes.map((episode) {
        if (episode.episodeId == episodeId) {
          return episode.copyWith(views: episode.views + 1);
        }
        return episode;
      }).toList();
      
      state = AsyncValue.data(currentState.copyWith(episodes: updatedEpisodes));
    } catch (e) {
      debugPrint('Error incrementing view: $e');
    }
  }

  // Comment operations
  Future<void> addComment({
    required String episodeId,
    required String seriesId,
    required String content,
    String? parentCommentId,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final comment = EpisodeCommentModel(
        commentId: '',
        episodeId: episodeId,
        seriesId: seriesId,
        authorUID: currentUser.uid,
        authorName: currentUser.name,
        authorImage: currentUser.image,
        content: content,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
      );

      await _repository.addComment(comment);
      await loadComments(episodeId);
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _repository.deleteComment(commentId);
      
      // Update local state
      final currentState = state.value!;
      final updatedComments = currentState.comments
          .where((c) => c.commentId != commentId)
          .toList();
      
      state = AsyncValue.data(currentState.copyWith(comments: updatedComments));
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> loadComments(String episodeId) async {
    try {
      final comments = await _repository.getEpisodeComments(episodeId);
      state = AsyncValue.data(state.value!.copyWith(comments: comments));
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> likeComment(String commentId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _repository.likeComment(commentId, currentUser.uid);
      
      // Update local state
      final currentState = state.value!;
      final updatedComments = currentState.comments.map((comment) {
        if (comment.commentId == commentId) {
          return comment.copyWith(
            likes: comment.likes + 1,
            likedBy: [...comment.likedBy, currentUser.uid],
          );
        }
        return comment;
      }).toList();
      
      state = AsyncValue.data(currentState.copyWith(comments: updatedComments));
    } catch (e) {
      debugPrint('Error liking comment: $e');
    }
  }

  Future<void> unlikeComment(String commentId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _repository.unlikeComment(commentId, currentUser.uid);
      
      // Update local state
      final currentState = state.value!;
      final updatedComments = currentState.comments.map((comment) {
        if (comment.commentId == commentId) {
          final updatedLikedBy = comment.likedBy.where((id) => id != currentUser.uid).toList();
          return comment.copyWith(
            likes: comment.likes - 1,
            likedBy: updatedLikedBy,
          );
        }
        return comment;
      }).toList();
      
      state = AsyncValue.data(currentState.copyWith(comments: updatedComments));
    } catch (e) {
      debugPrint('Error unliking comment: $e');
    }
  }

  // Analytics operations
  Future<void> loadAnalytics(String seriesId) async {
    try {
      final analytics = await _repository.getSeriesAnalytics(seriesId);
      state = AsyncValue.data(state.value!.copyWith(analytics: analytics));
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }
}

// Generated part file would be here
// part 'mini_series_provider.g.dart';

// Convenience providers
@riverpod
List<MiniSeriesModel> userSeries(UserSeriesRef ref) {
  final miniSeriesState = ref.watch(miniSeriesProvider);
  return miniSeriesState.when(
    data: (state) => state.series,
    loading: () => [],
    error: (_, __) => [],
  );
}

@riverpod
MiniSeriesModel? currentSeries(CurrentSeriesRef ref) {
  final miniSeriesState = ref.watch(miniSeriesProvider);
  return miniSeriesState.when(
    data: (state) => state.currentSeries,
    loading: () => null,
    error: (_, __) => null,
  );
}

@riverpod
List<EpisodeModel> seriesEpisodes(SeriesEpisodesRef ref) {
  final miniSeriesState = ref.watch(miniSeriesProvider);
  return miniSeriesState.when(
    data: (state) => state.episodes,
    loading: () => [],
    error: (_, __) => [],
  );
}

@riverpod
EpisodeModel? currentEpisode(CurrentEpisodeRef ref) {
  final miniSeriesState = ref.watch(miniSeriesProvider);
  return miniSeriesState.when(
    data: (state) => state.currentEpisode,
    loading: () => null,
    error: (_, __) => null,
  );
}

@riverpod
List<EpisodeCommentModel> episodeComments(EpisodeCommentsRef ref) {
  final miniSeriesState = ref.watch(miniSeriesProvider);
  return miniSeriesState.when(
    data: (state) => state.comments,
    loading: () => [],
    error: (_, __) => [],
  );
}

@riverpod
SeriesAnalyticsModel? seriesAnalytics(SeriesAnalyticsRef ref) {
  final miniSeriesState = ref.watch(miniSeriesProvider);
  return miniSeriesState.when(
    data: (state) => state.analytics,
    loading: () => null,
    error: (_, __) => null,
  );
}

// Search provider
@riverpod
class SeriesSearch extends _$SeriesSearch {
  @override
  FutureOr<List<MiniSeriesModel>> build(String query) async {
    if (query.isEmpty) return [];
    
    final repository = ref.read(miniSeriesRepositoryProvider);
    return await repository.searchSeries(query);
  }
}

// Featured series provider
@riverpod
class FeaturedSeries extends _$FeaturedSeries {
  @override
  FutureOr<List<MiniSeriesModel>> build() async {
    final repository = ref.read(miniSeriesRepositoryProvider);
    return await repository.getPublishedSeries(limit: 10);
  }
}

// Categories provider
@riverpod
List<String> seriesCategories(SeriesCategoriesRef ref) {
  return [
    'Drama',
    'Comedy',
    'Romance',
    'Action',
    'Thriller',
    'Horror',
    'Fantasy',
    'Sci-Fi',
    'Documentary',
    'Educational',
    'Lifestyle',
    'Music',
    'Other',
  ];
}