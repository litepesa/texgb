// lib/features/marketplace/services/marketplace_cache_service.dart
// CLEAN VERSION - Based on working version, progress tracking removed

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_video_caching/flutter_video_caching.dart';

/// Singleton service for managing video caching with flutter_video_caching
/// Provides TikTok-like instant video playback through intelligent preloading
class MarketplaceCacheService {
  static final MarketplaceCacheService _instance = MarketplaceCacheService._internal();
  factory MarketplaceCacheService() => _instance;
  MarketplaceCacheService._internal();

  // Initialization state
  bool _isInitialized = false;

  // Store the proxy port (default is 0, which auto-assigns)
  int _proxyPort = 45678; // Default port, will be set during init

  // Track which videos are currently being precached
  final Set<String> _cachingMarketplaceItems = {};

  // Cache for converted local URIs
  final Map<String, Uri> _localUriCache = {};

  // Track all cached video URLs for management
  final Set<String> _cachedMarketplaceItemUrls = {};

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
      debugPrint('MarketplaceCacheService: Already initialized');
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
      debugPrint('MarketplaceCacheService: Initialized successfully on port $_proxyPort');
    } catch (e) {
      debugPrint('MarketplaceCacheService: Initialization failed - $e');
      rethrow;
    }
  }

  /// Convert video URL to local proxy URI for playback
  /// This enables caching through the local proxy server
  Uri getLocalUri(String marketplaceItemUrl) {
    if (!_isInitialized) {
      debugPrint('MarketplaceCacheService: Warning - not initialized, returning original URL');
      return Uri.parse(marketplaceItemUrl);
    }

    // Check cache first
    if (_localUriCache.containsKey(marketplaceItemUrl)) {
      return _localUriCache[marketplaceItemUrl]!;
    }

    try {
      // Parse the URL string to Uri
      final uri = Uri.parse(marketplaceItemUrl);

      // Use the package's built-in extension method to convert to local proxy URI
      // This should handle the proxy port and URL format correctly
      final localUri = marketplaceItemUrl.toLocalUri();

      // Cache the conversion
      _localUriCache[marketplaceItemUrl] = localUri;

      debugPrint('MarketplaceCacheService: Converted $marketplaceItemUrl to $localUri');

      return localUri;
    } catch (e) {
      debugPrint('MarketplaceCacheService: Failed to convert URL - $e');
      // Fallback to original URL if conversion fails
      return Uri.parse(marketplaceItemUrl);
    }
  }

  /// Precache a video for instant playback
  /// Downloads silently in background - no progress tracking
  /// Returns true if precaching started successfully
  Future<bool> precacheMarketplaceItem(
    String marketplaceItemUrl, {
    int cacheSegments = 3, // Cache first 3 segments (6MB with default 2MB segments)
    bool downloadImmediately = true,
  }) async {
    if (!_isInitialized) {
      debugPrint('MarketplaceCacheService: Not initialized. Call initialize() first.');
      return false;
    }

    if (_cachingMarketplaceItems.contains(marketplaceItemUrl)) {
      debugPrint('MarketplaceCacheService: Already precaching $marketplaceItemUrl');
      return false;
    }

    try {
      _cachingMarketplaceItems.add(marketplaceItemUrl);

      // Start silent background precaching - no progress tracking
      await VideoCaching.precache(
        marketplaceItemUrl,
        cacheSegments: cacheSegments,
        downloadNow: downloadImmediately,
        progressListen: false, // No progress tracking
      );

      // Track this as a cached video
      _cachedMarketplaceItemUrls.add(marketplaceItemUrl);

      debugPrint('MarketplaceCacheService: Started precaching $marketplaceItemUrl');
      return true;
    } catch (e) {
      debugPrint('MarketplaceCacheService: Failed to precache $marketplaceItemUrl - $e');
      _cachingMarketplaceItems.remove(marketplaceItemUrl);
      return false;
    } finally {
      // Remove from caching set after a delay (assume caching completes)
      Future.delayed(const Duration(seconds: 30), () {
        _cachingMarketplaceItems.remove(marketplaceItemUrl);
      });
    }
  }

  /// Precache multiple videos in sequence
  /// Perfect for preloading next videos in a feed
  Future<void> precacheMultiple(
    List<String> marketplaceItemUrls, {
    int cacheSegmentsPerMarketplaceItem = 2,
    int maxConcurrent = 3,
  }) async {
    if (!_isInitialized || marketplaceItemUrls.isEmpty) return;

    debugPrint('MarketplaceCacheService: Precaching ${marketplaceItemUrls.length} videos');

    // Process videos in chunks to avoid overwhelming the system
    for (var i = 0; i < marketplaceItemUrls.length; i += maxConcurrent) {
      final chunk = marketplaceItemUrls.skip(i).take(maxConcurrent).toList();

      await Future.wait(
        chunk.map((url) => precacheMarketplaceItem(
          url,
          cacheSegments: cacheSegmentsPerMarketplaceItem,
          downloadImmediately: false, // Queue for background download
        )),
      );
    }
  }

  /// Intelligent preloading strategy for PageView/Feed scenarios
  /// Preloads next N videos based on current index
  Future<void> intelligentPreload({
    required List<String> marketplaceItemUrls,
    required int currentIndex,
    int preloadNext = 2,
    int preloadPrevious = 1,
    int cacheSegmentsPerMarketplaceItem = 2,
  }) async {
    if (!_isInitialized || marketplaceItemUrls.isEmpty) return;

    final marketplaceItemsToPreload = <String>[];

    // Preload next videos
    for (var i = 1; i <= preloadNext; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex < marketplaceItemUrls.length) {
        marketplaceItemsToPreload.add(marketplaceItemUrls[nextIndex]);
      }
    }

    // Preload previous videos (for scroll back)
    for (var i = 1; i <= preloadPrevious; i++) {
      final prevIndex = currentIndex - i;
      if (prevIndex >= 0) {
        marketplaceItemsToPreload.add(marketplaceItemUrls[prevIndex]);
      }
    }

    if (marketplaceItemsToPreload.isEmpty) return;

    debugPrint('MarketplaceCacheService: Intelligent preload - current: $currentIndex, preloading ${marketplaceItemsToPreload.length} videos');

    // Preload in background
    await precacheMultiple(
      marketplaceItemsToPreload,
      cacheSegmentsPerMarketplaceItem: cacheSegmentsPerMarketplaceItem,
      maxConcurrent: 2,
    );
  }

  /// Check if a video is currently being cached
  bool isMarketplaceItemCaching(String marketplaceItemUrl) {
    return _cachingMarketplaceItems.contains(marketplaceItemUrl);
  }

  /// Check if a video has been cached (best effort tracking)
  bool isMarketplaceItemCached(String marketplaceItemUrl) {
    return _cachedMarketplaceItemUrls.contains(marketplaceItemUrl);
  }

  /// Get all tracked cached video URLs
  Set<String> getCachedMarketplaceItemUrls() {
    return Set.from(_cachedMarketplaceItemUrls);
  }

  /// Clear tracking for a specific video
  /// Note: This only clears tracking, actual cache is managed by the package
  void clearMarketplaceItemTracking(String marketplaceItemUrl) {
    _cachingMarketplaceItems.remove(marketplaceItemUrl);
    _localUriCache.remove(marketplaceItemUrl);
    _cachedMarketplaceItemUrls.remove(marketplaceItemUrl);

    debugPrint('MarketplaceCacheService: Cleared tracking for $marketplaceItemUrl');
  }

  /// Clear all caches and reset state
  void clearAllCaches() {
    _cachingMarketplaceItems.clear();
    _localUriCache.clear();
    _cachedMarketplaceItemUrls.clear();

    debugPrint('MarketplaceCacheService: Cleared all cache tracking');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'isInitialized': _isInitialized,
      'currentlyCaching': _cachingMarketplaceItems.length,
      'totalCached': _cachedMarketplaceItemUrls.length,
      'uriCacheSize': _localUriCache.length,
    };
  }

  /// Dispose resources
  void dispose() {
    _cachingMarketplaceItems.clear();
    _localUriCache.clear();
    _cachedMarketplaceItemUrls.clear();

    debugPrint('MarketplaceCacheService: Disposed');
  }
}

/// Extension on String URLs for convenience
extension MarketplaceCachingStringExtension on String {
  /// Convert video URL string to local proxy URI
  Uri toLocalCacheUri() {
    return MarketplaceCacheService().getLocalUri(this);
  }

  /// Precache this video URL
  Future<bool> precache({
    int cacheSegments = 2,
  }) async {
    return MarketplaceCacheService().precacheMarketplaceItem(
      this,
      cacheSegments: cacheSegments,
    );
  }
}
