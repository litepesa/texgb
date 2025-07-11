import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MediaUtil {
  // Singleton pattern
  static final MediaUtil _instance = MediaUtil._internal();
  factory MediaUtil() => _instance;
  MediaUtil._internal();

  // Cache for already generated thumbnails
  final Map<String, String> _thumbnailCache = {};
  
  // Custom cache manager for video files
  final CacheManager _cacheManager = CacheManager(
    Config(
      'videoCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  );

  /// Generate a thumbnail for a video from a URL
  /// Returns the file path to the generated thumbnail
  Future<String?> generateVideoThumbnail(String videoUrl) async {
    try {
      // Check if thumbnail already exists in cache
      if (_thumbnailCache.containsKey(videoUrl)) {
        // Verify that the cached thumbnail file still exists
        final File thumbnailFile = File(_thumbnailCache[videoUrl]!);
        if (await thumbnailFile.exists()) {
          return _thumbnailCache[videoUrl];
        }
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = '${tempDir.path}/${videoUrl.hashCode}.jpg';
      
      // Generate the thumbnail
      final thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
      );
      
      if (thumbnailBytes != null) {
        // Save thumbnail to file
        final thumbnailFile = File(thumbnailPath);
        await thumbnailFile.writeAsBytes(thumbnailBytes);
        
        // Cache the thumbnail path
        _thumbnailCache[videoUrl] = thumbnailPath;
        
        return thumbnailPath;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }
  
  /// Download a file from URL and store in cache
  /// Returns the file when it's ready
  Future<File?> getFileFromUrl(String url) async {
    try {
      // Download and cache the file
      final fileInfo = await _cacheManager.getFileFromCache(url);
      
      if (fileInfo != null) {
        return fileInfo.file;
      }
      
      // If not in cache, download it
      final fileInfo2 = await _cacheManager.downloadFile(url);
      return fileInfo2.file;
    } catch (e) {
      debugPrint('Error downloading media file: $e');
      return null;
    }
  }
  
  /// Upload a media file to Firebase Storage and get download URL
  Future<String?> uploadMediaToStorage(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading media to storage: $e');
      return null;
    }
  }
  
  /// Get the MIME type of a file
  String getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
  
  /// Extract video metadata (duration, dimensions)
  Future<Map<String, dynamic>> getVideoMetadata(String videoUrl) async {
    try {
      final file = await getFileFromUrl(videoUrl);
      if (file == null) {
        return {'error': 'Could not download video file'};
      }
      
      // Use video_player to get metadata - this is a simplified approach
      // For production, you might want to use a more robust solution
      final VideoPlayerController controller = VideoPlayerController.file(file);
      await controller.initialize();
      
      final metadata = {
        'duration': controller.value.duration.inMilliseconds,
        'width': controller.value.size.width,
        'height': controller.value.size.height,
        'aspectRatio': controller.value.aspectRatio,
      };
      
      await controller.dispose();
      return metadata;
    } catch (e) {
      debugPrint('Error extracting video metadata: $e');
      return {'error': e.toString()};
    }
  }
  
  /// Clear the thumbnail cache
  Future<void> clearThumbnailCache() async {
    try {
      for (final path in _thumbnailCache.values) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _thumbnailCache.clear();
    } catch (e) {
      debugPrint('Error clearing thumbnail cache: $e');
    }
  }
}