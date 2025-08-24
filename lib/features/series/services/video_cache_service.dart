// lib/features/series/services/video_cache_service.dart
// UPDATED from channels/services/video_cache_service.dart for Series Episodes

import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:textgb/features/series/models/series_episode_model.dart';

class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  // Custom cache manager for series episodes with optimized settings
  static final CacheManager _videoCacheManager = CacheManager(
    Config(
      'series_video_cache',
      stalePeriod: const Duration(days: 7), // Keep videos for 7 days
      maxNrOfCacheObjects: 300, // Cache up to 300 episodes (~3-6GB, episodes are shorter)
      repo: JsonCacheInfoRepository(databaseName: 'series_video_cache'),
      fileSystem: IOFileSystem('series_video_cache'),
      fileService: HttpFileService(),
    ),
  );

  // Track preloading operations to avoid duplicates
  final Set<String> _preloadingUrls = <String>{};
  final Map<String, Completer<File?>> _preloadCompleters = {};
  
  // Priority queue for intelligent preloading
  final List<String> _preloadQueue = [];
  bool _isProcessingQueue = false;
  
  // Series-specific caching metadata
  final Map<String, String> _episodeToSeriesMap = {}; // episodeId -> seriesId
  final Map<String, Set<String>> _seriesToEpisodesMap = {}; // seriesId -> Set<episodeId>

  /// Get cached video file for immediate playback
  Future<File> getCachedVideo(String videoUrl) async {
    try {
      return await _videoCacheManager.getSingleFile(videoUrl);
    } catch (e) {
      debugPrint('Error getting cached series episode: $e');
      rethrow;
    }
  }

  /// Check if episode video is already cached
  Future<bool> isVideoCached(String videoUrl) async {
    try {
      final fileInfo = await _videoCacheManager.getFileFromCache(videoUrl);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  /// Preload episode video in background with priority
  Future<File?> preloadVideo(String videoUrl, {int priority = 0, String? episodeId, String? seriesId}) async {
    if (videoUrl.isEmpty || _preloadingUrls.contains(videoUrl)) {
      return _preloadCompleters[videoUrl]?.future;
    }

    // Store series mapping for cache organization
    if (episodeId != null && seriesId != null) {
      _episodeToSeriesMap[episodeId] = seriesId;
      _seriesToEpisodesMap.putIfAbsent(seriesId, () => <String>{}).add(episodeId);
    }

    // Check if already cached
    if (await isVideoCached(videoUrl)) {
      try {
        return await getCachedVideo(videoUrl);
      } catch (e) {
        debugPrint('Error getting existing cached episode: $e');
      }
    }

    // Add to preloading set and create completer
    _preloadingUrls.add(videoUrl);
    final completer = Completer<File?>();
    _preloadCompleters[videoUrl] = completer;

    try {
      debugPrint('Preloading series episode: $videoUrl');
      
      // Download and cache the episode
      final file = await _videoCacheManager.getSingleFile(
        videoUrl,
        key: videoUrl,
        headers: {
          'Accept': 'video/mp4,video/*',
          'User-Agent': 'SeriesApp/1.0',
        },
      );
      
      debugPrint('Successfully preloaded episode: $videoUrl');
      completer.complete(file);
      return file;
      
    } catch (e) {
      debugPrint('Failed to preload episode $videoUrl: $e');
      completer.complete(null);
      return null;
    } finally {
      _preloadingUrls.remove(videoUrl);
      _preloadCompleters.remove(videoUrl);
    }
  }

  /// Intelligent preloading for TikTok-like experience with series episodes
  /// Preloads current episode + next 3 + previous 1 (optimized for 2-minute episodes)
  Future<void> preloadVideosIntelligently(
    List<SeriesEpisodeModel> episodes, 
    int currentIndex,
  ) async {
    if (episodes.isEmpty || currentIndex < 0 || currentIndex >= episodes.length) {
      return;
    }

    final videosToPreload = <Map<String, String>>[];
    
    // Current episode (highest priority)
    if (!episodes[currentIndex].isMultipleImages && 
        episodes[currentIndex].videoUrl.isNotEmpty) {
      videosToPreload.add({
        'url': episodes[currentIndex].videoUrl,
        'episodeId': episodes[currentIndex].id,
        'seriesId': episodes[currentIndex].seriesId,
      });
    }

    // Next 3 episodes (higher preload count due to shorter episode length)
    for (int i = 1; i <= 3; i++) {
      final index = currentIndex + i;
      if (index < episodes.length && 
          !episodes[index].isMultipleImages && 
          episodes[index].videoUrl.isNotEmpty) {
        videosToPreload.add({
          'url': episodes[index].videoUrl,
          'episodeId': episodes[index].id,
          'seriesId': episodes[index].seriesId,
        });
      }
    }

    // Previous 1 episode (for easy back navigation)
    if (currentIndex > 0) {
      final index = currentIndex - 1;
      if (!episodes[index].isMultipleImages && 
          episodes[index].videoUrl.isNotEmpty) {
        videosToPreload.add({
          'url': episodes[index].videoUrl,
          'episodeId': episodes[index].id,
          'seriesId': episodes[index].seriesId,
        });
      }
    }

    // Add to queue and process
    _addToPreloadQueue(videosToPreload);
    _processPreloadQueue();
  }

  /// Preload episodes for series binge-watching
  /// When user is watching episodes sequentially, preload more aggressively
  Future<void> preloadForBingeWatching(
    List<SeriesEpisodeModel> episodes,
    int currentIndex,
  ) async {
    if (episodes.isEmpty || currentIndex < 0 || currentIndex >= episodes.length) {
      return;
    }

    final videosToPreload = <Map<String, String>>[];
    
    // Preload next 5 episodes for smooth binge-watching experience
    for (int i = 1; i <= 5; i++) {
      final index = currentIndex + i;
      if (index < episodes.length && 
          !episodes[index].isMultipleImages && 
          episodes[index].videoUrl.isNotEmpty &&
          !await isVideoCached(episodes[index].videoUrl)) {
        videosToPreload.add({
          'url': episodes[index].videoUrl,
          'episodeId': episodes[index].id,
          'seriesId': episodes[index].seriesId,
        });
      }
    }

    _addToPreloadQueue(videosToPreload);
    _processPreloadQueue();
  }

  /// Add episodes to preload queue with deduplication and metadata
  void _addToPreloadQueue(List<Map<String, String>> episodeData) {
    for (final data in episodeData) {
      final url = data['url']!;
      if (!_preloadQueue.contains(url) && !_preloadingUrls.contains(url)) {
        _preloadQueue.add(url);
        
        // Store metadata for organization
        final episodeId = data['episodeId'];
        final seriesId = data['seriesId'];
        if (episodeId != null && seriesId != null) {
          _episodeToSeriesMap[episodeId] = seriesId;
          _seriesToEpisodesMap.putIfAbsent(seriesId, () => <String>{}).add(episodeId);
        }
      }
    }
  }

  /// Process preload queue with concurrency control (optimized for episodes)
  Future<void> _processPreloadQueue() async {
    if (_isProcessingQueue || _preloadQueue.isEmpty) return;

    _isProcessingQueue = true;
    
    try {
      // Process up to 3 episodes concurrently (episodes are smaller than full videos)
      const maxConcurrent = 3;
      final futures = <Future<File?>>[];
      
      while (_preloadQueue.isNotEmpty && futures.length < maxConcurrent) {
        final url = _preloadQueue.removeAt(0);
        futures.add(preloadVideo(url));
      }
      
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
      
      // Continue processing if more items in queue
      if (_preloadQueue.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), _processPreloadQueue); // Faster processing for short episodes
      }
      
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Preload next batch when user approaches end of current cache
  Future<void> preloadNextBatch(
    List<SeriesEpisodeModel> episodes, 
    int currentIndex,
  ) async {
    // Start preloading when user is 2 episodes away (closer trigger for short content)
    const preloadTriggerDistance = 2;
    
    for (int i = currentIndex + preloadTriggerDistance; 
         i < currentIndex + preloadTriggerDistance + 4 && i < episodes.length; 
         i++) {
      if (!episodes[i].isMultipleImages && 
          episodes[i].videoUrl.isNotEmpty &&
          !await isVideoCached(episodes[i].videoUrl)) {
        preloadVideo(
          episodes[i].videoUrl,
          episodeId: episodes[i].id,
          seriesId: episodes[i].seriesId,
        );
      }
    }
  }

  /// Clean up old cached episodes to manage storage
  Future<void> cleanupOldCache() async {
    try {
      // Get all cached files
      final cacheDir = await getTemporaryDirectory();
      final videoCacheDir = Directory('${cacheDir.path}/series_video_cache');
      
      if (await videoCacheDir.exists()) {
        final files = videoCacheDir.listSync();
        
        // Sort by last accessed time and remove oldest if exceeding limit
        files.sort((a, b) {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return bStat.accessed.compareTo(aStat.accessed);
        });
        
        // Keep only the most recent 200 files (more room for episodes)
        if (files.length > 200) {
          for (int i = 200; i < files.length; i++) {
            try {
              await files[i].delete();
            } catch (e) {
              debugPrint('Error deleting old cached episode: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error during episode cache cleanup: $e');
    }
  }

  /// Clear cache for a specific series (useful when series is removed/updated)
  Future<void> clearSeriesCache(String seriesId) async {
    try {
      final episodeIds = _seriesToEpisodesMap[seriesId];
      if (episodeIds != null) {
        for (final episodeId in episodeIds) {
          // Remove from cache manager (if we stored by episodeId)
          // This is simplified - in practice you'd need to map episodeId to videoUrl
          _episodeToSeriesMap.remove(episodeId);
        }
        _seriesToEpisodesMap.remove(seriesId);
      }
    } catch (e) {
      debugPrint('Error clearing series cache: $e');
    }
  }

  /// Get cache statistics for debugging (series-specific)
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final videoCacheDir = Directory('${cacheDir.path}/series_video_cache');
      int fileCount = 0;
      int totalSize = 0;
      
      if (await videoCacheDir.exists()) {
        final files = videoCacheDir.listSync();
        fileCount = files.length;
        
        for (final file in files) {
          try {
            if (file is File) {
              totalSize += await file.length();
            }
          } catch (e) {
            // Ignore errors for individual files
          }
        }
      }
      
      return {
        'fileCount': fileCount,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'preloadingCount': _preloadingUrls.length,
        'queueLength': _preloadQueue.length,
        'cachedSeriesCount': _seriesToEpisodesMap.length,
        'totalEpisodesTracked': _episodeToSeriesMap.length,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Get cache info for specific series
  Future<Map<String, dynamic>> getSeriesCacheStats(String seriesId) async {
    final episodeIds = _seriesToEpisodesMap[seriesId];
    if (episodeIds == null) {
      return {
        'seriesId': seriesId,
        'episodesTracked': 0,
        'cachedEpisodes': 0,
      };
    }

    int cachedCount = 0;
    for (final episodeId in episodeIds) {
      // In practice, you'd check if the episode's video URL is cached
      // This is simplified for the example
    }

    return {
      'seriesId': seriesId,
      'episodesTracked': episodeIds.length,
      'cachedEpisodes': cachedCount,
    };
  }

  /// Clear all cached episodes
  Future<void> clearCache() async {
    try {
      await _videoCacheManager.emptyCache();
      _preloadQueue.clear();
      _preloadingUrls.clear();
      _preloadCompleters.clear();
      _episodeToSeriesMap.clear();
      _seriesToEpisodesMap.clear();
      debugPrint('Series episode cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing series episode cache: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _preloadQueue.clear();
    _preloadingUrls.clear();
    for (final completer in _preloadCompleters.values) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    _preloadCompleters.clear();
    _episodeToSeriesMap.clear();
    _seriesToEpisodesMap.clear();
  }

  /// Enhanced preloading for episode auto-play in series viewer
  /// Optimizes for sequential viewing patterns
  Future<void> preloadForAutoPlay(
    List<SeriesEpisodeModel> episodes,
    int currentIndex,
  ) async {
    if (episodes.isEmpty || currentIndex < 0) return;

    // Preload the next episode immediately for seamless auto-play
    final nextIndex = currentIndex + 1;
    if (nextIndex < episodes.length && 
        !episodes[nextIndex].isMultipleImages &&
        episodes[nextIndex].videoUrl.isNotEmpty) {
      
      // High priority preload for immediate next episode
      preloadVideo(
        episodes[nextIndex].videoUrl,
        priority: 10,
        episodeId: episodes[nextIndex].id,
        seriesId: episodes[nextIndex].seriesId,
      );
    }

    // Then preload the following episodes with lower priority
    preloadVideosIntelligently(episodes, currentIndex);
  }
}