// lib/features/channels/services/video_cache_service.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';

class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  // Custom cache manager for videos with optimized settings
  static final CacheManager _videoCacheManager = CacheManager(
    Config(
      'video_cache',
      stalePeriod: const Duration(days: 7), // Keep videos for 7 days
      maxNrOfCacheObjects: 200, // Cache up to 200 videos (~2-5GB)
      repo: JsonCacheInfoRepository(databaseName: 'video_cache'),
      fileSystem: IOFileSystem('video_cache'),
      fileService: HttpFileService(),
    ),
  );

  // Track preloading operations to avoid duplicates
  final Set<String> _preloadingUrls = <String>{};
  final Map<String, Completer<File?>> _preloadCompleters = {};
  
  // Priority queue for intelligent preloading
  final List<String> _preloadQueue = [];
  bool _isProcessingQueue = false;

  /// Get cached video file for immediate playback
  Future<File> getCachedVideo(String videoUrl) async {
    try {
      return await _videoCacheManager.getSingleFile(videoUrl);
    } catch (e) {
      debugPrint('Error getting cached video: $e');
      rethrow;
    }
  }

  /// Check if video is already cached
  Future<bool> isVideoCached(String videoUrl) async {
    try {
      final fileInfo = await _videoCacheManager.getFileFromCache(videoUrl);
      return fileInfo != null;
    } catch (e) {
      return false;
    }
  }

  /// Preload video in background with priority
  Future<File?> preloadVideo(String videoUrl, {int priority = 0}) async {
    if (videoUrl.isEmpty || _preloadingUrls.contains(videoUrl)) {
      return _preloadCompleters[videoUrl]?.future;
    }

    // Check if already cached
    if (await isVideoCached(videoUrl)) {
      try {
        return await getCachedVideo(videoUrl);
      } catch (e) {
        debugPrint('Error getting existing cached video: $e');
      }
    }

    // Add to preloading set and create completer
    _preloadingUrls.add(videoUrl);
    final completer = Completer<File?>();
    _preloadCompleters[videoUrl] = completer;

    try {
      debugPrint('Preloading video: $videoUrl');
      
      // Download and cache the video
      final file = await _videoCacheManager.getSingleFile(
        videoUrl,
        key: videoUrl,
        headers: {}, // Add auth headers if needed
      );
      
      debugPrint('Successfully preloaded video: $videoUrl');
      completer.complete(file);
      return file;
      
    } catch (e) {
      debugPrint('Failed to preload video $videoUrl: $e');
      completer.complete(null);
      return null;
    } finally {
      _preloadingUrls.remove(videoUrl);
      _preloadCompleters.remove(videoUrl);
    }
  }

  /// Intelligent preloading for TikTok-like experience
  /// Preloads current video + next 3 + previous 1
  Future<void> preloadVideosIntelligently(
    List<ChannelVideoModel> videos, 
    int currentIndex,
  ) async {
    if (videos.isEmpty || currentIndex < 0 || currentIndex >= videos.length) {
      return;
    }

    final videosToPreload = <String>[];
    
    // Current video (highest priority)
    if (!videos[currentIndex].isMultipleImages && 
        videos[currentIndex].videoUrl.isNotEmpty) {
      videosToPreload.add(videos[currentIndex].videoUrl);
    }

    // Next 3 videos
    for (int i = 1; i <= 3; i++) {
      final index = currentIndex + i;
      if (index < videos.length && 
          !videos[index].isMultipleImages && 
          videos[index].videoUrl.isNotEmpty) {
        videosToPreload.add(videos[index].videoUrl);
      }
    }

    // Previous 1 video
    if (currentIndex > 0) {
      final index = currentIndex - 1;
      if (!videos[index].isMultipleImages && 
          videos[index].videoUrl.isNotEmpty) {
        videosToPreload.add(videos[index].videoUrl);
      }
    }

    // Add to queue and process
    _addToPreloadQueue(videosToPreload);
    _processPreloadQueue();
  }

  /// Add videos to preload queue with deduplication
  void _addToPreloadQueue(List<String> videoUrls) {
    for (final url in videoUrls) {
      if (!_preloadQueue.contains(url) && !_preloadingUrls.contains(url)) {
        _preloadQueue.add(url);
      }
    }
  }

  /// Process preload queue with concurrency control
  Future<void> _processPreloadQueue() async {
    if (_isProcessingQueue || _preloadQueue.isEmpty) return;

    _isProcessingQueue = true;
    
    try {
      // Process up to 2 videos concurrently to avoid overwhelming the network
      const maxConcurrent = 2;
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
        Future.delayed(const Duration(milliseconds: 500), _processPreloadQueue);
      }
      
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Preload next batch when user is close to end of current batch
  Future<void> preloadNextBatch(
    List<ChannelVideoModel> videos, 
    int currentIndex,
  ) async {
    // Start preloading when user is 2 videos away from what we've cached
    const preloadTriggerDistance = 2;
    
    for (int i = currentIndex + preloadTriggerDistance; 
         i < currentIndex + preloadTriggerDistance + 3 && i < videos.length; 
         i++) {
      if (!videos[i].isMultipleImages && 
          videos[i].videoUrl.isNotEmpty &&
          !await isVideoCached(videos[i].videoUrl)) {
        preloadVideo(videos[i].videoUrl);
      }
    }
  }

  /// Clean up old cached videos to manage storage
  Future<void> cleanupOldCache() async {
    try {
      // Get all cached files
      final cacheDir = await getTemporaryDirectory();
      final videoCacheDir = Directory('${cacheDir.path}/video_cache');
      
      if (await videoCacheDir.exists()) {
        final files = videoCacheDir.listSync();
        
        // Sort by last accessed time and remove oldest if exceeding limit
        files.sort((a, b) {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return bStat.accessed.compareTo(aStat.accessed);
        });
        
        // Keep only the most recent 150 files (leave room for new ones)
        if (files.length > 150) {
          for (int i = 150; i < files.length; i++) {
            try {
              await files[i].delete();
            } catch (e) {
              debugPrint('Error deleting old cache file: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error during cache cleanup: $e');
    }
  }

  /// Get cache statistics for debugging
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final videoCacheDir = Directory('${cacheDir.path}/video_cache');
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
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Clear all cached videos
  Future<void> clearCache() async {
    try {
      await _videoCacheManager.emptyCache();
      _preloadQueue.clear();
      _preloadingUrls.clear();
      _preloadCompleters.clear();
      debugPrint('Video cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing video cache: $e');
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
  }

  void preloadVideoWithAudioProcessing(String videoUrl) {}
}