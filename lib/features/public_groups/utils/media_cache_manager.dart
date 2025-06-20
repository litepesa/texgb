// lib/features/public_groups/utils/media_cache_manager.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class MediaCacheManager {
  static const String _cacheKey = 'publicGroupMediaCache';
  
  static final CacheManager _instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: _cacheKey),
      fileService: HttpFileService(),
    ),
  );

  static CacheManager get instance => _instance;

  // Cache an image and return the cached file
  static Future<File?> cacheImage(String url) async {
    try {
      final file = await _instance.getSingleFile(url);
      return file;
    } catch (e) {
      debugPrint('Error caching image: $e');
      return null;
    }
  }

  // Cache a video and return the cached file
  static Future<File?> cacheVideo(String url) async {
    try {
      final file = await _instance.getSingleFile(url);
      return file;
    } catch (e) {
      debugPrint('Error caching video: $e');
      return null;
    }
  }

  // Generate and cache video thumbnail
  static Future<Uint8List?> generateVideoThumbnail(String videoUrl) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );
      return thumbnail;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  // Check if file is cached
  static Future<bool> isFileCached(String url) async {
    try {
      final fileInfo = await _instance.getFileFromCache(url);
      return fileInfo?.file != null;
    } catch (e) {
      return false;
    }
  }

  // Get cache size
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFiles = cacheDir.listSync(recursive: true);
      int totalSize = 0;
      
      for (final file in cacheFiles) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0;
    }
  }

  // Clear cache
  static Future<void> clearCache() async {
    try {
      await _instance.emptyCache();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Remove specific file from cache
  static Future<void> removeFromCache(String url) async {
    try {
      await _instance.removeFile(url);
    } catch (e) {
      debugPrint('Error removing file from cache: $e');
    }
  }

  // Preload media files for better performance
  static Future<void> preloadMedia(List<String> urls) async {
    for (final url in urls) {
      try {
        _instance.getSingleFile(url);
      } catch (e) {
        debugPrint('Error preloading media: $e');
      }
    }
  }

  // Format cache size for display
  static String formatCacheSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
