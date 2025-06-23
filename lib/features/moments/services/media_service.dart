// lib/features/moments/services/media_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:textgb/enums/enums.dart';

class MediaService {
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int jpegQuality = 85;
  static const int maxVideoSizeMB = 50;

  /// Optimize image for better performance and storage
  static Future<File?> optimizeImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;
      
      // Resize if too large
      img.Image resizedImage = image;
      if (image.width > maxImageWidth || image.height > maxImageHeight) {
        if (image.width > image.height) {
          resizedImage = img.copyResize(image, width: maxImageWidth);
        } else {
          resizedImage = img.copyResize(image, height: maxImageHeight);
        }
      }
      
      // Convert to JPEG and compress
      final compressedBytes = img.encodeJpg(resizedImage, quality: jpegQuality);
      
      // Save optimized image
      final tempDir = await getTemporaryDirectory();
      final optimizedFile = File(
        '${tempDir.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.jpg'
      );
      await optimizedFile.writeAsBytes(compressedBytes);
      
      debugPrint('Image optimized: ${imageFile.lengthSync()} -> ${optimizedFile.lengthSync()} bytes');
      
      return optimizedFile;
    } catch (e) {
      debugPrint('Error optimizing image: $e');
      return null;
    }
  }

  /// Check if video file size is within limits
  static Future<bool> isVideoSizeValid(File videoFile) async {
    try {
      final sizeInBytes = await videoFile.length();
      final sizeInMB = sizeInBytes / (1024 * 1024);
      return sizeInMB <= maxVideoSizeMB;
    } catch (e) {
      debugPrint('Error checking video size: $e');
      return false;
    }
  }

  /// Get media file metadata
  static Future<Map<String, dynamic>> getMediaMetadata(File file, MessageEnum mediaType) async {
    try {
      final stats = await file.stat();
      final metadata = {
        'size': stats.size,
        'created': stats.changed,
        'modified': stats.modified,
        'type': mediaType.name,
      };

      if (mediaType == MessageEnum.image) {
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image != null) {
          metadata['width'] = image.width;
          metadata['height'] = image.height;
        }
      }

      return metadata;
    } catch (e) {
      debugPrint('Error getting media metadata: $e');
      return {};
    }
  }

  /// Request necessary permissions for media access
  static Future<bool> requestPermissions() async {
    try {
      final Map<Permission, PermissionStatus> permissions = await [
        Permission.camera,
        Permission.photos,
        Permission.storage,
        Permission.microphone, // For video recording
      ].request();

      final allGranted = permissions.values.every(
        (status) => status == PermissionStatus.granted
      );

      if (!allGranted) {
        debugPrint('Some permissions were denied');
      }

      return allGranted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Clean up temporary files
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      for (final file in files) {
        if (file is File && file.path.contains('optimized_')) {
          await file.delete();
        }
      }
      
      debugPrint('Cleaned up ${files.length} temporary files');
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }
}

// lib/features/moments/utils/content_validator.dart
class ContentValidator {
  static const List<String> bannedWords = [
    'spam', 'fake', 'scam', 'hate', 'abuse'
  ];

  static const int maxContentLength = 2000;
  static const int maxMediaCount = 9;

  /// Validate moment content for appropriateness
  static bool isContentAppropriate(String content) {
    if (content.isEmpty || content.length > maxContentLength) {
      return false;
    }

    final lowerContent = content.toLowerCase();
    
    // Check for banned words
    for (final word in bannedWords) {
      if (lowerContent.contains(word)) {
        return false;
      }
    }

    // Check for suspicious patterns
    if (_containsSuspiciousPatterns(content)) {
      return false;
    }

    return true;
  }

  /// Sanitize content by removing harmful elements
  static String sanitizeContent(String content) {
    String sanitized = content;
    
    // Remove HTML tags
    sanitized = sanitized.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Remove excessive whitespace
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Limit length
    if (sanitized.length > maxContentLength) {
      sanitized = sanitized.substring(0, maxContentLength);
    }
    
    return sanitized;
  }

  /// Validate media URLs for security
  static bool isValidMediaUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    // Check if it's from trusted domains
    final trustedDomains = [
      'firebasestorage.googleapis.com',
      'storage.googleapis.com',
    ];
    
    return trustedDomains.any((domain) => uri.host.contains(domain));
  }

  /// Check for suspicious content patterns
  static bool _containsSuspiciousPatterns(String content) {
    // Check for repeated characters (like "aaaaaaa")
    if (RegExp(r'(.)\1{10,}').hasMatch(content)) {
      return true;
    }

    // Check for excessive capitals
    final capitals = content.replaceAll(RegExp(r'[^A-Z]'), '');
    if (capitals.length > content.length * 0.7) {
      return true;
    }

    // Check for suspicious URLs
    if (RegExp(r'https?://[^\s]+\.(?:tk|ml|ga|cf)').hasMatch(content)) {
      return true;
    }

    return false;
  }

  /// Validate media files before upload
  static Future<ValidationResult> validateMediaFiles(List<File> files) async {
    if (files.isEmpty) {
      return ValidationResult(isValid: true);
    }

    if (files.length > maxMediaCount) {
      return ValidationResult(
        isValid: false,
        error: 'Maximum $maxMediaCount media files allowed',
      );
    }

    for (final file in files) {
      final isValid = await _validateSingleFile(file);
      if (!isValid.isValid) {
        return isValid;
      }
    }

    return ValidationResult(isValid: true);
  }

  static Future<ValidationResult> _validateSingleFile(File file) async {
    try {
      // Check file size
      final sizeInMB = await file.length() / (1024 * 1024);
      if (sizeInMB > 50) {
        return ValidationResult(
          isValid: false,
          error: 'File size must be less than 50MB',
        );
      }

      // Check file extension
      final extension = file.path.split('.').last.toLowerCase();
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi'];
      
      if (!validExtensions.contains(extension)) {
        return ValidationResult(
          isValid: false,
          error: 'Unsupported file format: $extension',
        );
      }

      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: 'Error validating file: ${e.toString()}',
      );
    }
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({required this.isValid, this.error});
}

// lib/features/moments/utils/analytics_helper.dart
class MomentsAnalytics {
  /// Track moment creation
  static void trackMomentCreated({
    required String momentId,
    required String mediaType,
    required int mediaCount,
    required String privacy,
  }) {
    debugPrint('Analytics: Moment created - $momentId');
    // Implementation for analytics service
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'moment_created',
    //   parameters: {
    //     'moment_id': momentId,
    //     'media_type': mediaType,
    //     'media_count': mediaCount,
    //     'privacy': privacy,
    //   },
    // );
  }

  /// Track moment view
  static void trackMomentViewed(String momentId, String viewerId) {
    debugPrint('Analytics: Moment viewed - $momentId by $viewerId');
    // Implementation for analytics service
  }

  /// Track moment interaction
  static void trackMomentLiked(String momentId, String likerId) {
    debugPrint('Analytics: Moment liked - $momentId by $likerId');
    // Implementation for analytics service
  }

  /// Track moment sharing
  static void trackMomentShared(String momentId, String sharerId) {
    debugPrint('Analytics: Moment shared - $momentId by $sharerId');
    // Implementation for analytics service
  }

  /// Track comment added
  static void trackCommentAdded(String momentId, String commenterId) {
    debugPrint('Analytics: Comment added to $momentId by $commenterId');
    // Implementation for analytics service
  }

  /// Track performance metrics
  static void trackPerformance(String operation, int durationMs) {
    debugPrint('Performance [$operation]: ${durationMs}ms');
    // Implementation for performance monitoring
  }
}

// lib/features/moments/utils/error_handler.dart
class MomentsErrorHandler {
  /// Handle and categorize errors
  static void handleError(String operation, dynamic error, {StackTrace? stackTrace}) {
    debugPrint('Moments Error [$operation]: $error');
    
    // Log to crash reporting service
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
    
    // Categorize error for better handling
    final errorType = _categorizeError(error);
    debugPrint('Error type: $errorType');
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission')) {
      return 'Permission denied. Please check your app permissions.';
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('storage') || errorString.contains('space')) {
      return 'Storage error. Please free up some space on your device.';
    } else if (errorString.contains('unauthorized') || errorString.contains('auth')) {
      return 'Authentication error. Please log in again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'Something went wrong. Please try again later.';
    }
  }

  /// Categorize error for analytics
  static String _categorizeError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('permission')) return 'permission';
    if (errorString.contains('network')) return 'network';
    if (errorString.contains('storage')) return 'storage';
    if (errorString.contains('auth')) return 'authentication';
    if (errorString.contains('timeout')) return 'timeout';
    if (errorString.contains('validation')) return 'validation';
    
    return 'unknown';
  }

  /// Check if error is recoverable
  static bool isRecoverable(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network and timeout errors are usually recoverable
    if (errorString.contains('network') || 
        errorString.contains('timeout') ||
        errorString.contains('connection')) {
      return true;
    }
    
    // Permission errors might be recoverable if user grants permission
    if (errorString.contains('permission')) {
      return true;
    }
    
    return false;
  }
}

// lib/features/moments/utils/cache_manager.dart
class MomentsCacheManager {
  static const String _momentsKey = 'cached_moments';
  static const String _commentsKey = 'cached_comments';
  static const int maxCacheSize = 100;
  static const Duration cacheExpiry = Duration(hours: 6);

  /// Cache moments for offline viewing
  static Future<void> cacheMoments(List<dynamic> moments) async {
    try {
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': moments,
      };
      
      // In a real implementation, use SharedPreferences, Hive, or SQLite
      debugPrint('Cached ${moments.length} moments');
      
      // Trim cache if too large
      if (moments.length > maxCacheSize) {
        final trimmedData = moments.take(maxCacheSize).toList();
        debugPrint('Trimmed cache to $maxCacheSize items');
      }
    } catch (e) {
      debugPrint('Error caching moments: $e');
    }
  }

  /// Get cached moments if available and not expired
  static Future<List<dynamic>?> getCachedMoments() async {
    try {
      // Implementation would retrieve from local storage
      // Check if cache is expired
      // Return cached data if valid
      
      debugPrint('Retrieved cached moments');
      return null; // Placeholder
    } catch (e) {
      debugPrint('Error getting cached moments: $e');
      return null;
    }
  }

  /// Clear expired cache entries
  static Future<void> clearExpiredCache() async {
    try {
      // Implementation would check timestamps and remove expired entries
      debugPrint('Cleared expired cache entries');
    } catch (e) {
      debugPrint('Error clearing expired cache: $e');
    }
  }

  /// Get cache size and statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      // Implementation would return cache statistics
      return {
        'size': 0,
        'entries': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return {};
    }
  }
}

// lib/features/moments/utils/privacy_helper.dart
class PrivacyHelper {
  /// Check if user can view moment based on privacy settings
  static bool canViewMoment({
    required String momentAuthorId,
    required String currentUserId,
    required String privacy,
    required List<String> userContacts,
    List<String>? visibleTo,
    List<String>? hiddenFrom,
  }) {
    // Owner can always view their own moments
    if (momentAuthorId == currentUserId) {
      return true;
    }

    switch (privacy) {
      case 'all_contacts':
        if (hiddenFrom != null && hiddenFrom.contains(currentUserId)) {
          return false;
        }
        return userContacts.contains(momentAuthorId);
        
      case 'only_me':
        return false;
        
      case 'custom_list':
        if (visibleTo != null) {
          return visibleTo.contains(currentUserId);
        }
        return userContacts.contains(momentAuthorId);
        
      default:
        return false;
    }
  }

  /// Get privacy level description
  static String getPrivacyDescription(String privacy) {
    switch (privacy) {
      case 'all_contacts':
        return 'Visible to all contacts';
      case 'only_me':
        return 'Only visible to you';
      case 'custom_list':
        return 'Visible to selected contacts';
      default:
        return 'Unknown privacy setting';
    }
  }

  /// Validate privacy settings
  static bool isValidPrivacySetting(String privacy) {
    return ['all_contacts', 'only_me', 'custom_list'].contains(privacy);
  }
}