// ============================================================================

// lib/features/series/providers/series_episodes_provider.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/series/providers/series_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/series_episode_model.dart';
import '../repositories/series_repository.dart';

// Define the episodes state
class SeriesEpisodesState {
  final bool isLoading;
  final List<SeriesEpisodeModel> featuredEpisodes;    // Featured episodes for main feed
  final List<SeriesEpisodeModel> seriesEpisodes;      // Episodes for specific series
  final List<String> likedEpisodeIds;
  final String? error;
  final bool isUploading;
  final double uploadProgress;
  final String? currentSeriesId;                       // Currently viewing series

  const SeriesEpisodesState({
    this.isLoading = false,
    this.featuredEpisodes = const [],
    this.seriesEpisodes = const [],
    this.likedEpisodeIds = const [],
    this.error,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.currentSeriesId,
  });

  SeriesEpisodesState copyWith({
    bool? isLoading,
    List<SeriesEpisodeModel>? featuredEpisodes,
    List<SeriesEpisodeModel>? seriesEpisodes,
    List<String>? likedEpisodeIds,
    String? error,
    bool? isUploading,
    double? uploadProgress,
    String? currentSeriesId,
  }) {
    return SeriesEpisodesState(
      isLoading: isLoading ?? this.isLoading,
      featuredEpisodes: featuredEpisodes ?? this.featuredEpisodes,
      seriesEpisodes: seriesEpisodes ?? this.seriesEpisodes,
      likedEpisodeIds: likedEpisodeIds ?? this.likedEpisodeIds,
      error: error,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      currentSeriesId: currentSeriesId ?? this.currentSeriesId,
    );
  }
}

// Episodes provider
class SeriesEpisodesNotifier extends StateNotifier<SeriesEpisodesState> {
  final SeriesRepository _repository;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SeriesEpisodesNotifier(this._repository) : super(const SeriesEpisodesState()) {
    // Initialize with empty state and load featured episodes
    loadFeaturedEpisodes();
    loadLikedEpisodes();
  }

  // Load featured episodes (for main TikTok-style feed)
  Future<void> loadFeaturedEpisodes({bool forceRefresh = false}) async {
    if (!forceRefresh && state.featuredEpisodes.isNotEmpty) {
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final episodes = await _repository.getFeaturedEpisodes(forceRefresh: forceRefresh);
      
      // Update liked status for episodes
      final episodesWithLikedStatus = episodes.map((episode) {
        final isLiked = state.likedEpisodeIds.contains(episode.id);
        return episode.copyWith(isLiked: isLiked);
      }).toList();
      
      state = state.copyWith(
        featuredEpisodes: episodesWithLikedStatus,
        isLoading: false,
      );
    } on RepositoryException catch (e) {
      debugPrint('Error loading featured episodes: ${e.message}');
      state = state.copyWith(
        error: e.message,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading featured episodes: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Load episodes for a specific series
  Future<List<SeriesEpisodeModel>> loadSeriesEpisodes(String seriesId) async {
    try {
      final seriesEpisodes = await _repository.getSeriesEpisodes(seriesId);
      
      // Update liked status for episodes
      final episodesWithLikedStatus = seriesEpisodes.map((episode) {
        final isLiked = state.likedEpisodeIds.contains(episode.id);
        return episode.copyWith(isLiked: isLiked);
      }).toList();
      
      // Update state if this is the currently viewing series
      if (state.currentSeriesId == seriesId) {
        state = state.copyWith(seriesEpisodes: episodesWithLikedStatus);
      }
      
      return episodesWithLikedStatus;
    } on RepositoryException catch (e) {
      debugPrint('Error loading series episodes: ${e.message}');
      state = state.copyWith(error: e.message);
      return [];
    } catch (e) {
      debugPrint('Error loading series episodes: $e');
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Set current series for episode viewing
  void setCurrentSeries(String seriesId) {
    state = state.copyWith(currentSeriesId: seriesId);
    loadSeriesEpisodes(seriesId);
  }

  // Load user's liked episodes
  Future<void> loadLikedEpisodes() async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      final likedEpisodes = await _repository.getLikedEpisodes(uid);
      state = state.copyWith(likedEpisodeIds: likedEpisodes);
      
      // Update isLiked status for existing episodes
      final updatedFeaturedEpisodes = state.featuredEpisodes.map((episode) {
        return episode.copyWith(isLiked: likedEpisodes.contains(episode.id));
      }).toList();
      
      final updatedSeriesEpisodes = state.seriesEpisodes.map((episode) {
        return episode.copyWith(isLiked: likedEpisodes.contains(episode.id));
      }).toList();
      
      state = state.copyWith(
        featuredEpisodes: updatedFeaturedEpisodes,
        seriesEpisodes: updatedSeriesEpisodes,
      );
    } on RepositoryException catch (e) {
      debugPrint('Error loading liked episodes: ${e.message}');
      state = state.copyWith(error: e.message);
    } catch (e) {
      debugPrint('Error loading liked episodes: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Like or unlike an episode
  Future<void> likeEpisode(String episodeId) async {
    if (_auth.currentUser == null) return;
    
    try {
      final uid = _auth.currentUser!.uid;
      
      // Get current liked episodes
      List<String> likedEpisodes = List.from(state.likedEpisodeIds);
      bool isCurrentlyLiked = likedEpisodes.contains(episodeId);
      
      // Update local state first (optimistic update)
      if (isCurrentlyLiked) {
        likedEpisodes.remove(episodeId);
        await _repository.unlikeEpisode(episodeId, uid);
      } else {
        likedEpisodes.add(episodeId);
        await _repository.likeEpisode(episodeId, uid);
      }
      
      // Update featured episodes list with new like status
      final updatedFeaturedEpisodes = state.featuredEpisodes.map((episode) {
        if (episode.id == episodeId) {
          return episode.copyWith(
            isLiked: !isCurrentlyLiked,
            likes: isCurrentlyLiked ? episode.likes - 1 : episode.likes + 1,
          );
        }
        return episode;
      }).toList();
      
      // Update series episodes list with new like status
      final updatedSeriesEpisodes = state.seriesEpisodes.map((episode) {
        if (episode.id == episodeId) {
          return episode.copyWith(
            isLiked: !isCurrentlyLiked,
            likes: isCurrentlyLiked ? episode.likes - 1 : episode.likes + 1,
          );
        }
        return episode;
      }).toList();
      
      state = state.copyWith(
        featuredEpisodes: updatedFeaturedEpisodes,
        seriesEpisodes: updatedSeriesEpisodes,
        likedEpisodeIds: likedEpisodes,
      );
      
    } on RepositoryException catch (e) {
      debugPrint('Error toggling episode like: ${e.message}');
      state = state.copyWith(error: e.message);
      
      // Revert the optimistic update on error
      loadFeaturedEpisodes();
      loadLikedEpisodes();
    } catch (e) {
      debugPrint('Error toggling episode like: $e');
      state = state.copyWith(error: e.toString());
      
      // Revert the optimistic update on error
      loadFeaturedEpisodes();
      loadLikedEpisodes();
    }
  }

  // Upload a new episode to a series
  Future<void> uploadEpisode({
    required String seriesId,
    required File videoFile,
    required String episodeTitle,
    required String description,
    required bool isFeatured,
    List<String>? tags,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    state = state.copyWith(isUploading: true, uploadProgress: 0.0);
    
    try {
      final uid = _auth.currentUser!.uid;
      final episodeId = const Uuid().v4();
      
      // Get series info
      final series = await _repository.getSeriesById(seriesId);
      if (series == null) {
        throw RepositoryException('Series not found');
      }
      
      // Verify ownership
      if (series.creatorId != uid) {
        throw RepositoryException('You can only add episodes to your own series');
      }
      
      // Check episode limits
      if (series.episodeCount >= series.maxEpisodes) {
        throw RepositoryException('Maximum episodes reached for this series');
      }
      
      // Upload video to storage
      final videoUrl = await _repository.uploadVideo(
        videoFile,
        'episodeFiles/$episodeId.mp4',
        onProgress: (progress) {
          state = state.copyWith(uploadProgress: progress * 0.8); // 80% for upload
        },
      );
      
      // Generate thumbnail (placeholder - in real app, extract from video)
      const thumbnailUrl = '';
      
      // Get video duration (you'd implement this with a video processing library)
      final durationSeconds = await _getVideoDurationSeconds(videoFile);
      
      if (durationSeconds > 120) { // 2 minutes max
        throw RepositoryException('Episode duration cannot exceed 2 minutes');
      }
      
      state = state.copyWith(uploadProgress: 0.9);
      
      // Create episode
      final episodeData = await _repository.createEpisode(
        seriesId: seriesId,
        seriesTitle: series.title,
        seriesImage: series.thumbnailImage,
        userId: uid,
        episodeTitle: episodeTitle,
        description: description,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
        isFeatured: isFeatured,
        tags: tags ?? [],
      );
      
      // Update local state
      if (isFeatured) {
        List<SeriesEpisodeModel> updatedFeaturedEpisodes = [
          episodeData,
          ...state.featuredEpisodes,
        ];
        state = state.copyWith(featuredEpisodes: updatedFeaturedEpisodes);
      }
      
      // Update series episodes if currently viewing this series
      if (state.currentSeriesId == seriesId) {
        List<SeriesEpisodeModel> updatedSeriesEpisodes = [
          ...state.seriesEpisodes,
          episodeData,
        ];
        // Sort by episode number
        updatedSeriesEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
        state = state.copyWith(seriesEpisodes: updatedSeriesEpisodes);
      }
      
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
      );
      
      onSuccess('Episode uploaded successfully');
    } on RepositoryException catch (e) {
      debugPrint('Error uploading episode: ${e.message}');
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.message,
      );
      onError(e.message);
    } catch (e) {
      debugPrint('Error uploading episode: $e');
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.toString(),
      );
      onError(e.toString());
    }
  }

  // Placeholder method for getting video duration
  Future<int> _getVideoDurationSeconds(File videoFile) async {
    // TODO: Implement video duration extraction using video_player or similar
    // For now, return a placeholder duration
    return 60; // 1 minute placeholder
  }

  // Increment view count for an episode
  Future<void> incrementEpisodeViews(String episodeId) async {
    try {
      await _repository.incrementEpisodeViews(episodeId);
      
      // Update local state
      final updatedFeaturedEpisodes = state.featuredEpisodes.map((episode) {
        if (episode.id == episodeId) {
          return episode.copyWith(views: episode.views + 1);
        }
        return episode;
      }).toList();
      
      final updatedSeriesEpisodes = state.seriesEpisodes.map((episode) {
        if (episode.id == episodeId) {
          return episode.copyWith(views: episode.views + 1);
        }
        return episode;
      }).toList();
      
      state = state.copyWith(
        featuredEpisodes: updatedFeaturedEpisodes,
        seriesEpisodes: updatedSeriesEpisodes,
      );
    } on RepositoryException catch (e) {
      debugPrint('Error incrementing episode views: ${e.message}');
      state = state.copyWith(error: e.message);
    } catch (e) {
      debugPrint('Error incrementing episode views: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  // Delete an episode
  Future<void> deleteEpisode(String episodeId, Function(String) onError) async {
    if (_auth.currentUser == null) {
      onError('User not authenticated');
      return;
    }
    
    try {
      final uid = _auth.currentUser!.uid;
      await _repository.deleteEpisode(episodeId, uid);
      
      // Update local state
      final updatedFeaturedEpisodes = state.featuredEpisodes.where((episode) => episode.id != episodeId).toList();
      final updatedSeriesEpisodes = state.seriesEpisodes.where((episode) => episode.id != episodeId).toList();
      
      state = state.copyWith(
        featuredEpisodes: updatedFeaturedEpisodes,
        seriesEpisodes: updatedSeriesEpisodes,
      );
    } on RepositoryException catch (e) {
      debugPrint('Error deleting episode: ${e.message}');
      state = state.copyWith(error: e.message);
      onError(e.message);
    } catch (e) {
      debugPrint('Error deleting episode: $e');
      state = state.copyWith(error: e.toString());
      onError(e.toString());
    }
  }

  // Get a specific episode by ID
  Future<SeriesEpisodeModel?> getEpisodeById(String episodeId) async {
    try {
      final episode = await _repository.getEpisodeById(episodeId);
      if (episode != null) {
        final isLiked = state.likedEpisodeIds.contains(episodeId);
        return episode.copyWith(isLiked: isLiked);
      }
      return null;
    } on RepositoryException catch (e) {
      debugPrint('Error getting episode by ID: ${e.message}');
      state = state.copyWith(error: e.message);
      return null;
    } catch (e) {
      debugPrint('Error getting episode by ID: $e');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

// Provider definition
final seriesEpisodesProvider = StateNotifierProvider<SeriesEpisodesNotifier, SeriesEpisodesState>((ref) {
  final repository = ref.watch(seriesRepositoryProvider);
  return SeriesEpisodesNotifier(repository);
});

