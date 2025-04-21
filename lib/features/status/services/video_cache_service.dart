import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// A service that handles caching of video files to improve loading performance
class VideoCacheService {
  static final VideoCacheService _instance = VideoCacheService._internal();
  
  factory VideoCacheService() {
    return _instance;
  }
  
  VideoCacheService._internal();
  
  /// Cache directory
  Directory? _cacheDir;
  
  /// Map of URL to cached file paths
  final Map<String, String> _cachedVideos = {};
  
  /// Maximum cache size in bytes (100MB)
  final int _maxCacheSize = 100 * 1024 * 1024;
  
  /// Initialize the cache service
  Future<void> initialize() async {
    if (_cacheDir != null) return;
    
    try {
      final tempDir = await getTemporaryDirectory();
      _cacheDir = Directory('${tempDir.path}/video_cache');
      
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
      
      // Load existing cached files
      await _loadExistingCache();
      
      // Clean up old cache files if needed
      _cleanupCache();
    } catch (e) {
      debugPrint('Error initializing video cache: $e');
    }
  }
  
  /// Load existing cached files
  Future<void> _loadExistingCache() async {
    try {
      if (_cacheDir == null) return;
      
      final files = await _cacheDir!.list().toList();
      
      for (var file in files) {
        if (file is File) {
          // Get filename which should be the URL hash
          final filename = file.path.split('/').last;
          
          // Add to cache map
          _cachedVideos[filename] = file.path;
        }
      }
    } catch (e) {
      debugPrint('Error loading existing cache: $e');
    }
  }
  
  /// Get URL hash for filename
  String _getUrlHash(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
  
  /// Get cached video file path for URL, or null if not cached
  Future<String?> getCachedVideo(String url) async {
    await initialize();
    
    final urlHash = _getUrlHash(url);
    
    // Check if video is already cached
    if (_cachedVideos.containsKey(urlHash)) {
      final file = File(_cachedVideos[urlHash]!);
      if (await file.exists()) {
        // Touch the file to update last accessed time
        await file.setLastModified(DateTime.now());
        return file.path;
      } else {
        // Remove from cache if file doesn't exist
        _cachedVideos.remove(urlHash);
      }
    }
    
    return null;
  }
  
  /// Cache a video from URL
  Future<String?> cacheVideo(String url) async {
    await initialize();
    
    try {
      final urlHash = _getUrlHash(url);
      final cachePath = '${_cacheDir!.path}/$urlHash';
      final cacheFile = File(cachePath);
      
      // Check if already cached
      if (await cacheFile.exists()) {
        _cachedVideos[urlHash] = cachePath;
        await cacheFile.setLastModified(DateTime.now());
        return cachePath;
      }
      
      // Download the file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await cacheFile.writeAsBytes(response.bodyBytes);
        _cachedVideos[urlHash] = cachePath;
        
        // Clean up cache if needed
        _cleanupCache();
        
        return cachePath;
      }
    } catch (e) {
      debugPrint('Error caching video: $e');
    }
    
    return null;
  }
  
  /// Clean up old cache files if total size exceeds maximum
  Future<void> _cleanupCache() async {
    try {
      if (_cacheDir == null) return;
      
      int totalSize = 0;
      List<MapEntry<File, FileStat>> fileStats = [];
      
      // Get all files and their stats
      for (var filePath in _cachedVideos.values) {
        final file = File(filePath);
        if (await file.exists()) {
          final stat = await file.stat();
          totalSize += stat.size;
          fileStats.add(MapEntry(file, stat));
        }
      }
      
      // If total size exceeds maximum, delete oldest files until under limit
      if (totalSize > _maxCacheSize) {
        // Sort by last accessed time (oldest first)
        fileStats.sort((a, b) => a.value.accessed.compareTo(b.value.accessed));
        
        for (var entry in fileStats) {
          if (totalSize <= _maxCacheSize) break;
          
          final file = entry.key;
          final size = entry.value.size;
          
          // Remove from cache and delete file
          final urlHash = file.path.split('/').last;
          _cachedVideos.remove(urlHash);
          await file.delete();
          
          totalSize -= size;
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up cache: $e');
    }
  }
  
  /// Clear all cached videos
  Future<void> clearCache() async {
    try {
      if (_cacheDir == null) return;
      
      // Delete all files in cache directory
      await _cacheDir!.delete(recursive: true);
      
      // Recreate directory
      await _cacheDir!.create(recursive: true);
      
      // Clear cache map
      _cachedVideos.clear();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }
}