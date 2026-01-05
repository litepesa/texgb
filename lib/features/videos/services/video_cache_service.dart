// lib/features/videos/services/video_cache_service.dart
// CLEAN VERSION - Based on working version, progress tracking removed

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_video_caching/flutter_video_caching.dart';

/// Singleton service for managing video caching with flutter_video_caching
/// Provides TikTok-like instant video playback through intelligent preloading
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  // Initialization state
  bool _isInitialized = false;

  // Store the proxy port (default is 0, which auto-assigns)
  int _proxyPort = 45678; // Default port, will be set during init

  // Track which videos are currently being precached
  final Set<String> _cachingVideos = {};

  // Cache for converted local URIs
  final Map<String, Uri> _localUriCache = {};

  // Track all cached video URLs for management
  final Set<String> _cachedVideoUrls = {};

  /// Initialize the video caching proxy
  /// Call this in main() before runApp()
  Future<void> initialize({
    String? ip,
    int? port,
    int maxMemoryCacheMB = 100,
    int maxStorageCacheMB = 1024,
    int segmentSizeMB = 10,
    int maxConcurrentDownloads = 2,
    bool enableLogging = false,
  }) async {
    if (_isInitialized) {
      debugPrint('VideoCacheService: Already initialized');
      return;
    }

    try {
      await VideoProxy.init(
        ip: ip,
        port: port,
        maxMemoryCacheSize: maxMemoryCacheMB,
        maxStorageCacheSize: maxStorageCacheMB,
        segmentSize: segmentSizeMB,
        maxConcurrentDownloads: maxConcurrentDownloads,
        logPrint: enableLogging,
      );

      // Store the port if provided, otherwise use default
      if (port != null) {
        _proxyPort = port;
      }

      _isInitialized = true;
      debugPrint(
          'VideoCacheService: Initialized successfully on port $_proxyPort');
    } catch (e) {
      debugPrint('VideoCacheService: Initialization failed - $e');
      rethrow;
    }
  }

  /// Convert video URL to local proxy URI for playback
  /// This enables caching through the local proxy server
  Uri getLocalUri(String videoUrl) {
    if (!_isInitialized) {
      debugPrint(
          'VideoCacheService: Warning - not initialized, returning original URL');
      return Uri.parse(videoUrl);
    }

    // Check cache first
    if (_localUriCache.containsKey(videoUrl)) {
      return _localUriCache[videoUrl]!;
    }

    try {
      // Parse the URL string to Uri
      final uri = Uri.parse(videoUrl);

      // Use the package's built-in extension method to convert to local proxy URI
      // This should handle the proxy port and URL format correctly
      final localUri = videoUrl.toLocalUri();

      // Cache the conversion
      _localUriCache[videoUrl] = localUri;

      debugPrint('VideoCacheService: Converted $videoUrl to $localUri');

      return localUri;
    } catch (e) {
      debugPrint('VideoCacheService: Failed to convert URL - $e');
      // Fallback to original URL if conversion fails
      return Uri.parse(videoUrl);
    }
  }

  /// Precache a video for instant playback
  /// Downloads silently in background - no progress tracking
  /// Returns true if precaching started successfully
  Future<bool> precacheVideo(
    String videoUrl, {
    int cacheSegments =
        3, // Cache first 3 segments (6MB with default 2MB segments)
    bool downloadImmediately = true,
  }) async {
    if (!_isInitialized) {
      debugPrint(
          'VideoCacheService: Not initialized. Call initialize() first.');
      return false;
    }

    if (_cachingVideos.contains(videoUrl)) {
      debugPrint('VideoCacheService: Already precaching $videoUrl');
      return false;
    }

    try {
      _cachingVideos.add(videoUrl);

      // Start silent background precaching - no progress tracking
      await VideoCaching.precache(
        videoUrl,
        cacheSegments: cacheSegments,
        downloadNow: downloadImmediately,
        progressListen: false, // No progress tracking
      );

      // Track this as a cached video
      _cachedVideoUrls.add(videoUrl);

      debugPrint('VideoCacheService: Started precaching $videoUrl');
      return true;
    } catch (e) {
      debugPrint('VideoCacheService: Failed to precache $videoUrl - $e');
      _cachingVideos.remove(videoUrl);
      return false;
    } finally {
      // Remove from caching set after a delay (assume caching completes)
      Future.delayed(const Duration(seconds: 30), () {
        _cachingVideos.remove(videoUrl);
      });
    }
  }

  /// Precache multiple videos in sequence
  /// Perfect for preloading next videos in a feed
  Future<void> precacheMultiple(
    List<String> videoUrls, {
    int cacheSegmentsPerVideo = 2,
    int maxConcurrent = 3,
  }) async {
    if (!_isInitialized || videoUrls.isEmpty) return;

    debugPrint('VideoCacheService: Precaching ${videoUrls.length} videos');

    // Process videos in chunks to avoid overwhelming the system
    for (var i = 0; i < videoUrls.length; i += maxConcurrent) {
      final chunk = videoUrls.skip(i).take(maxConcurrent).toList();

      await Future.wait(
        chunk.map((url) => precacheVideo(
              url,
              cacheSegments: cacheSegmentsPerVideo,
              downloadImmediately: false, // Queue for background download
            )),
      );
    }
  }

  /// Intelligent preloading strategy for PageView/Feed scenarios
  /// Preloads next N videos based on current index
  Future<void> intelligentPreload({
    required List<String> videoUrls,
    required int currentIndex,
    int preloadNext = 2,
    int preloadPrevious = 1,
    int cacheSegmentsPerVideo = 2,
  }) async {
    if (!_isInitialized || videoUrls.isEmpty) return;

    final videosToPreload = <String>[];

    // Preload next videos
    for (var i = 1; i <= preloadNext; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex < videoUrls.length) {
        videosToPreload.add(videoUrls[nextIndex]);
      }
    }

    // Preload previous videos (for scroll back)
    for (var i = 1; i <= preloadPrevious; i++) {
      final prevIndex = currentIndex - i;
      if (prevIndex >= 0) {
        videosToPreload.add(videoUrls[prevIndex]);
      }
    }

    if (videosToPreload.isEmpty) return;

    debugPrint(
        'VideoCacheService: Intelligent preload - current: $currentIndex, preloading ${videosToPreload.length} videos');

    // Preload in background
    await precacheMultiple(
      videosToPreload,
      cacheSegmentsPerVideo: cacheSegmentsPerVideo,
      maxConcurrent: 2,
    );
  }

  /// Check if a video is currently being cached
  bool isVideoCaching(String videoUrl) {
    return _cachingVideos.contains(videoUrl);
  }

  /// Check if a video has been cached (best effort tracking)
  bool isVideoCached(String videoUrl) {
    return _cachedVideoUrls.contains(videoUrl);
  }

  /// Get all tracked cached video URLs
  Set<String> getCachedVideoUrls() {
    return Set.from(_cachedVideoUrls);
  }

  /// Clear tracking for a specific video
  /// Note: This only clears tracking, actual cache is managed by the package
  void clearVideoTracking(String videoUrl) {
    _cachingVideos.remove(videoUrl);
    _localUriCache.remove(videoUrl);
    _cachedVideoUrls.remove(videoUrl);

    debugPrint('VideoCacheService: Cleared tracking for $videoUrl');
  }

  /// Clear all caches and reset state
  void clearAllCaches() {
    _cachingVideos.clear();
    _localUriCache.clear();
    _cachedVideoUrls.clear();

    debugPrint('VideoCacheService: Cleared all cache tracking');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'isInitialized': _isInitialized,
      'currentlyCaching': _cachingVideos.length,
      'totalCached': _cachedVideoUrls.length,
      'uriCacheSize': _localUriCache.length,
    };
  }

  /// Dispose resources
  void dispose() {
    _cachingVideos.clear();
    _localUriCache.clear();
    _cachedVideoUrls.clear();

    debugPrint('VideoCacheService: Disposed');
  }
}

/// Extension on String URLs for convenience
extension VideoCachingStringExtension on String {
  /// Convert video URL string to local proxy URI
  Uri toLocalCacheUri() {
    return VideoCacheService().getLocalUri(this);
  }

  /// Precache this video URL
  Future<bool> precache({
    int cacheSegments = 2,
  }) async {
    return VideoCacheService().precacheVideo(
      this,
      cacheSegments: cacheSegments,
    );
  }
}
