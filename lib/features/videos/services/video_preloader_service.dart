// lib/features/videos/services/video_preloader_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// Service responsible for preloading video chunks for instant playback
class VideoPreloaderService {
  static final VideoPreloaderService _instance = VideoPreloaderService._internal();
  factory VideoPreloaderService() => _instance;
  VideoPreloaderService._internal() {
    _dio = Dio();
    _setupDioOptions();
    _startPeriodicCleanup();
  }

  static const int PRELOAD_BYTES = 1572864; // 1.5MB
  static const int MAX_CACHE_SIZE = 10;
  static const Duration CACHE_LIFETIME = Duration(minutes: 10);
  static const Duration REQUEST_TIMEOUT = Duration(seconds: 15);
  static const int MAX_CONCURRENT_PRELOADS = 3;

  late Dio _dio;
  Timer? _cleanupTimer;

  final Map<String, _PreloadedVideo> _preloadCache = {};
  final Map<String, CancelToken> _activeRequests = {};
  final Set<String> _preloadQueue = {};

  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _totalPreloaded = 0;

  void _setupDioOptions() {
    _dio.options = BaseOptions(
      connectTimeout: REQUEST_TIMEOUT,
      receiveTimeout: REQUEST_TIMEOUT,
      responseType: ResponseType.bytes,
      followRedirects: true,
      maxRedirects: 3,
      headers: {
        'Accept': 'video/mp4,video/*;q=0.9,*/*;q=0.8',
        'User-Agent': 'TextGB/1.0 (Flutter Video Player)',
      },
    );
  }

  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _cleanupExpiredCache();
    });
  }

  Future<bool> preloadVideo(String videoUrl, String videoId) async {
    if (videoUrl.isEmpty || videoId.isEmpty) {
      return false;
    }

    if (_preloadCache.containsKey(videoId)) {
      return true;
    }

    if (_activeRequests.containsKey(videoId)) {
      return false;
    }

    if (_activeRequests.length >= MAX_CONCURRENT_PRELOADS) {
      _preloadQueue.add(videoId);
      return false;
    }

    return await _performPreload(videoUrl, videoId);
  }

  Future<bool> _performPreload(String videoUrl, String videoId) async {
    final cancelToken = CancelToken();
    _activeRequests[videoId] = cancelToken;

    try {
      final startTime = DateTime.now();

      final response = await _dio.get(
        videoUrl,
        cancelToken: cancelToken,
        options: Options(
          headers: {
            'Range': 'bytes=0-${PRELOAD_BYTES - 1}',
          },
        ),
      );

      if (response.statusCode == 206 || response.statusCode == 200) {
        final data = response.data as Uint8List;
        final actualSize = data.length;
        final downloadTime = DateTime.now().difference(startTime);

        _preloadCache[videoId] = _PreloadedVideo(
          data: data,
          originalUrl: videoUrl,
          timestamp: DateTime.now(),
          actualSize: actualSize,
          downloadTime: downloadTime,
        );

        _totalPreloaded++;
        _enforceMaxCacheSize();
        return true;
      } else {
        return false;
      }
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
        // Silent failure for production
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _activeRequests.remove(videoId);
      _processQueue();
    }
  }

  Uint8List? getPreloadedData(String videoId) {
    final cached = _preloadCache[videoId];
    
    if (cached == null) {
      _cacheMisses++;
      return null;
    }

    if (_isCacheExpired(cached)) {
      _preloadCache.remove(videoId);
      _cacheMisses++;
      return null;
    }

    _cacheHits++;
    return cached.data;
  }

  String? getOriginalUrl(String videoId) {
    final cached = _preloadCache[videoId];
    return cached?.originalUrl;
  }

  bool isPreloaded(String videoId) {
    final cached = _preloadCache[videoId];
    return cached != null && !_isCacheExpired(cached);
  }

  void cancelPreload(String videoId) {
    final cancelToken = _activeRequests[videoId];
    if (cancelToken != null) {
      cancelToken.cancel('User cancelled');
      _activeRequests.remove(videoId);
    }
    _preloadQueue.remove(videoId);
  }

  Future<void> preloadVideoList(List<MapEntry<String, String>> videoList) async {
    for (final entry in videoList) {
      final videoId = entry.key;
      final videoUrl = entry.value;
      
      if (_activeRequests.length >= MAX_CONCURRENT_PRELOADS) {
        for (int i = videoList.indexOf(entry); i < videoList.length; i++) {
          _preloadQueue.add(videoList[i].key);
        }
        break;
      }
      
      await preloadVideo(videoUrl, videoId);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _processQueue() {
    if (_preloadQueue.isEmpty || _activeRequests.length >= MAX_CONCURRENT_PRELOADS) {
      return;
    }

    final videoId = _preloadQueue.first;
    _preloadQueue.remove(videoId);
  }

  void _cleanupExpiredCache() {
    final expiredKeys = <String>[];

    for (final entry in _preloadCache.entries) {
      if (_isCacheExpired(entry.value)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _preloadCache.remove(key);
    }
  }

  void _enforceMaxCacheSize() {
    if (_preloadCache.length <= MAX_CACHE_SIZE) return;

    final sortedEntries = _preloadCache.entries.toList()
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

    final entriesToRemove = sortedEntries.length - MAX_CACHE_SIZE;
    for (int i = 0; i < entriesToRemove; i++) {
      final key = sortedEntries[i].key;
      _preloadCache.remove(key);
    }
  }

  bool _isCacheExpired(_PreloadedVideo cached) {
    return DateTime.now().difference(cached.timestamp) > CACHE_LIFETIME;
  }

  void clearCache() {
    for (final cancelToken in _activeRequests.values) {
      cancelToken.cancel('Cache cleared');
    }
    _activeRequests.clear();
    _preloadCache.clear();
    _preloadQueue.clear();
    
    _cacheHits = 0;
    _cacheMisses = 0;
    _totalPreloaded = 0;
  }

  Map<String, dynamic> getCacheStats() {
    final totalMemoryUsage = _preloadCache.values
        .fold<int>(0, (sum, cached) => sum + cached.actualSize);
    
    final hitRate = _cacheHits + _cacheMisses > 0 
        ? (_cacheHits / (_cacheHits + _cacheMisses) * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'cached_videos': _preloadCache.length,
      'active_downloads': _activeRequests.length,
      'queued_videos': _preloadQueue.length,
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'hit_rate_percent': hitRate,
      'total_preloaded': _totalPreloaded,
      'memory_usage_mb': (totalMemoryUsage / (1024 * 1024)).toStringAsFixed(2),
      'max_cache_size': MAX_CACHE_SIZE,
      'preload_size_mb': (PRELOAD_BYTES / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  void dispose() {
    _cleanupTimer?.cancel();
    clearCache();
    _dio.close();
  }

  Future<bool> testRangeRequestSupport(String videoUrl) async {
    try {
      final response = await _dio.head(
        videoUrl,
        options: Options(
          headers: {'Range': 'bytes=0-1023'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final supportsRange = response.statusCode == 206 || 
                           response.headers.value('accept-ranges')?.toLowerCase() == 'bytes';
      
      return supportsRange;
    } catch (e) {
      return false;
    }
  }
}

class _PreloadedVideo {
  final Uint8List data;
  final String originalUrl;
  final DateTime timestamp;
  final int actualSize;
  final Duration downloadTime;

  _PreloadedVideo({
    required this.data,
    required this.originalUrl,
    required this.timestamp,
    required this.actualSize,
    required this.downloadTime,
  });
}

extension VideoPreloaderExtension on VideoPreloaderService {
  Future<void> preloadFromVideoModels(List<dynamic> videos, {int maxVideos = 3}) async {
    final videoList = videos
        .take(maxVideos)
        .map((video) => MapEntry<String, String>(
              video.id as String,
              video.videoUrl as String,
            ))
        .toList();
    
    await preloadVideoList(videoList);
  }

  String getPreloadStatus(String videoId) {
    if (_activeRequests.containsKey(videoId)) {
      return 'Loading...';
    } else if (_preloadCache.containsKey(videoId)) {
      final cached = _preloadCache[videoId]!;
      final age = DateTime.now().difference(cached.timestamp);
      return 'Cached (${age.inSeconds}s ago, ${(cached.actualSize / 1024).toInt()}KB)';
    } else if (_preloadQueue.contains(videoId)) {
      return 'Queued';
    } else {
      return 'Not preloaded';
    }
  }
}