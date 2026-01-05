// lib/features/marketplace/services/marketplace_thumbnail_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class MarketplaceThumbnailService {
  static final MarketplaceThumbnailService _instance =
      MarketplaceThumbnailService._internal();
  factory MarketplaceThumbnailService() => _instance;
  MarketplaceThumbnailService._internal();

  // Cache for generated thumbnails
  final Map<String, String> _thumbnailCache = {};

  // Generate unique cache key for video URL
  String _generateCacheKey(String videoUrl) {
    return md5.convert(utf8.encode(videoUrl)).toString();
  }

  // Get cache directory for thumbnails
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final thumbnailDir =
        Directory('${appDir.path}/marketplace_video_thumbnails');

    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }

    return thumbnailDir;
  }

  // 🆕 NEW: Generate thumbnail from local video file for upload
  Future<File?> generateThumbnailFile({
    required File videoFile,
    int maxWidth = 400,
    int maxHeight = 600,
    int quality = 85,
    int timeMs = 2000,
  }) async {
    try {
      debugPrint('🎬 Generating thumbnail from video file: ${videoFile.path}');

      final cacheDir = await _getCacheDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final thumbnailPath = '${cacheDir.path}/thumbnail_$timestamp.jpg';

      // Generate high-quality thumbnail from local video file
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
        timeMs: timeMs,
      );

      if (thumbnail != null && await File(thumbnail).exists()) {
        debugPrint('✅ Thumbnail generated successfully: $thumbnail');
        return File(thumbnail);
      } else {
        debugPrint('❌ Failed to generate thumbnail');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error generating thumbnail from file: $e');
      return null;
    }
  }

  // 🆕 NEW: Generate thumbnail with multiple attempts for better quality
  Future<File?> generateBestThumbnailFile({
    required File videoFile,
    int maxWidth = 400,
    int maxHeight = 600,
    int quality = 85,
  }) async {
    try {
      debugPrint(
          '🎬 Generating best quality thumbnail from video file: ${videoFile.path}');

      // Try multiple time positions to get the best frame
      final timePositions = [
        2000,
        1000,
        3000,
        5000,
        500
      ]; // Try different seconds

      for (final timeMs in timePositions) {
        try {
          final thumbnailFile = await generateThumbnailFile(
            videoFile: videoFile,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            quality: quality,
            timeMs: timeMs,
          );

          if (thumbnailFile != null && await thumbnailFile.exists()) {
            // Verify file size is reasonable (not corrupted)
            final fileSize = await thumbnailFile.length();
            if (fileSize > 1000) {
              // At least 1KB
              debugPrint(
                  '✅ Best thumbnail generated at ${timeMs}ms (size: $fileSize bytes)');
              return thumbnailFile;
            } else {
              debugPrint(
                  '⚠️ Thumbnail too small at ${timeMs}ms, trying next position...');
              await thumbnailFile.delete(); // Clean up small file
            }
          }
        } catch (e) {
          debugPrint('⚠️ Failed to generate thumbnail at ${timeMs}ms: $e');
          continue;
        }
      }

      debugPrint('❌ Failed to generate thumbnail at any time position');
      return null;
    } catch (e) {
      debugPrint('❌ Error generating best thumbnail: $e');
      return null;
    }
  }

  // 🆕 NEW: Generate thumbnail data (bytes) from local video file
  Future<Uint8List?> generateThumbnailDataFromFile({
    required File videoFile,
    int maxWidth = 400,
    int maxHeight = 600,
    int quality = 85,
    int timeMs = 2000,
  }) async {
    try {
      debugPrint(
          '🎬 Generating thumbnail data from video file: ${videoFile.path}');

      // Generate high-quality thumbnail as bytes
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
        timeMs: timeMs,
      );

      if (thumbnailData != null && thumbnailData.isNotEmpty) {
        debugPrint(
            '✅ Thumbnail data generated successfully (${thumbnailData.length} bytes)');
        return thumbnailData;
      } else {
        debugPrint('❌ Failed to generate thumbnail data');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error generating thumbnail data from file: $e');
      return null;
    }
  }

  // Generate high-quality thumbnail from video URL (similar to recommended posts)
  Future<String?> generateThumbnail(String videoUrl) async {
    if (videoUrl.isEmpty) return null;

    final cacheKey = _generateCacheKey(videoUrl);

    // Check if thumbnail is already cached
    if (_thumbnailCache.containsKey(cacheKey)) {
      final cachedPath = _thumbnailCache[cacheKey]!;
      if (await File(cachedPath).exists()) {
        return cachedPath;
      } else {
        // Remove invalid cache entry
        _thumbnailCache.remove(cacheKey);
      }
    }

    try {
      debugPrint('Generating high-quality thumbnail for video: $videoUrl');

      final cacheDir = await _getCacheDirectory();
      final thumbnailPath = '${cacheDir.path}/$cacheKey.jpg';

      // Generate high-quality thumbnail using enhanced settings like recommended posts
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth:
            400, // Increased width for better quality (matching recommended posts)
        maxHeight: 600, // Increased height for 9:16 aspect ratio videos
        quality: 85, // Higher quality (matching recommended posts quality)
        timeMs: 2000, // Get thumbnail at 2 second mark for better frame
      );

      if (thumbnail != null && await File(thumbnail).exists()) {
        _thumbnailCache[cacheKey] = thumbnail;
        debugPrint('High-quality thumbnail generated successfully: $thumbnail');
        return thumbnail;
      } else {
        debugPrint('Failed to generate thumbnail for: $videoUrl');
        return null;
      }
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  // Generate high-quality thumbnail as bytes (for immediate use)
  Future<Uint8List?> generateThumbnailData(String videoUrl) async {
    if (videoUrl.isEmpty) return null;

    try {
      debugPrint('Generating high-quality thumbnail data for video: $videoUrl');

      // Generate high-quality thumbnail as bytes with enhanced settings
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 400, // Increased width for better quality
        maxHeight: 600, // Increased height for 9:16 aspect ratio videos
        quality: 85, // Higher quality setting
        timeMs: 2000, // Get thumbnail at 2 second mark for better frame
      );

      if (thumbnailData != null) {
        debugPrint('High-quality thumbnail data generated successfully');
        return thumbnailData;
      } else {
        debugPrint('Failed to generate thumbnail data for: $videoUrl');
        return null;
      }
    } catch (e) {
      debugPrint('Error generating thumbnail data: $e');
      return null;
    }
  }

  // Generate multiple thumbnails at different time positions for better frame selection
  Future<Uint8List?> generateBestThumbnailData(String videoUrl) async {
    if (videoUrl.isEmpty) return null;

    try {
      debugPrint('Generating best quality thumbnail for video: $videoUrl');

      // Try multiple time positions to get the best frame
      final timePositions = [2000, 1000, 3000, 5000]; // Try different seconds

      for (final timeMs in timePositions) {
        try {
          final thumbnailData = await VideoThumbnail.thumbnailData(
            video: videoUrl,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 400,
            maxHeight: 600,
            quality: 85,
            timeMs: timeMs,
          );

          if (thumbnailData != null && thumbnailData.isNotEmpty) {
            debugPrint('Best thumbnail generated at ${timeMs}ms');
            return thumbnailData;
          }
        } catch (e) {
          debugPrint('Failed to generate thumbnail at ${timeMs}ms: $e');
          continue;
        }
      }

      debugPrint(
          'Failed to generate thumbnail at any time position for: $videoUrl');
      return null;
    } catch (e) {
      debugPrint('Error generating best thumbnail: $e');
      return null;
    }
  }

  // 🆕 NEW: Clean up temporary thumbnail file
  Future<void> deleteThumbnailFile(File thumbnailFile) async {
    try {
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
        debugPrint(
            '🗑️ Deleted temporary thumbnail file: ${thumbnailFile.path}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting thumbnail file: $e');
    }
  }

  // Clear thumbnail cache
  Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }

      _thumbnailCache.clear();
      debugPrint('Video thumbnail cache cleared');
    } catch (e) {
      debugPrint('Error clearing thumbnail cache: $e');
    }
  }

  // Get cache size in MB
  Future<double> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();

      if (!await cacheDir.exists()) return 0.0;

      int totalSize = 0;
      await for (final file in cacheDir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      return totalSize / (1024 * 1024); // Convert to MB
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
      return 0.0;
    }
  }

  // Clean old cache files (older than 7 days)
  Future<void> cleanOldCache() async {
    try {
      final cacheDir = await _getCacheDirectory();

      if (!await cacheDir.exists()) return;

      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 7));

      await for (final file in cacheDir.list()) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();

            // Remove from memory cache if exists
            final fileName = file.path.split('/').last.replaceAll('.jpg', '');
            _thumbnailCache.remove(fileName);
          }
        }
      }

      debugPrint('Old video thumbnails cleaned');
    } catch (e) {
      debugPrint('Error cleaning old cache: $e');
    }
  }

  // Check if video URL is valid for thumbnail generation
  bool isValidVideoUrl(String url) {
    if (url.isEmpty) return false;

    // Check for common video file extensions
    final videoExtensions = [
      '.mp4',
      '.avi',
      '.mov',
      '.mkv',
      '.webm',
      '.flv',
      '.m4v'
    ];
    final lowerUrl = url.toLowerCase();

    return videoExtensions.any((ext) => lowerUrl.contains(ext)) ||
        lowerUrl.startsWith('http') || // Network URLs
        lowerUrl.startsWith('file://'); // Local file URLs
  }

  // Check if video file is valid for thumbnail generation
  bool isValidVideoFile(File file) {
    if (!file.existsSync()) return false;

    final videoExtensions = [
      '.mp4',
      '.avi',
      '.mov',
      '.mkv',
      '.webm',
      '.flv',
      '.m4v'
    ];
    final lowerPath = file.path.toLowerCase();

    return videoExtensions.any((ext) => lowerPath.endsWith(ext));
  }

  // Preload thumbnail for better performance
  Future<void> preloadThumbnail(String videoUrl) async {
    if (!isValidVideoUrl(videoUrl)) return;

    // Generate thumbnail in background without waiting
    generateThumbnail(videoUrl).catchError((e) {
      debugPrint('Error preloading thumbnail: $e');
    });
  }

  // Dispose service and clear memory cache
  void dispose() {
    _thumbnailCache.clear();
  }
}
