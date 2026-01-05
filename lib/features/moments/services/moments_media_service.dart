// ===============================
// Moments Media Service
// Handle image/video selection, compression, and validation
// ===============================

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:textgb/features/moments/models/moment_constants.dart';
import 'package:textgb/features/moments/models/moment_enums.dart';

class MomentsMediaService {
  final ImagePicker _picker = ImagePicker();

  // ===============================
  // IMAGE OPERATIONS
  // ===============================

  /// Pick images from gallery (up to 9)
  Future<List<File>> pickImages(
      {int maxImages = MomentConstants.maxImages}) async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: MomentConstants.imageQuality,
      );

      if (pickedFiles.isEmpty) {
        return [];
      }

      // Limit to max images
      final limited = pickedFiles.take(maxImages).toList();

      // Convert to File list
      return limited.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      throw MediaException('Failed to pick images: $e');
    }
  }

  /// Take photo with camera
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: MomentConstants.imageQuality,
      );

      if (photo == null) return null;

      return File(photo.path);
    } catch (e) {
      throw MediaException('Failed to take photo: $e');
    }
  }

  /// Compress image
  Future<File> compressImage(File imageFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: MomentConstants.imageQuality,
        minWidth: MomentConstants.maxImageDimension,
        minHeight: MomentConstants.maxImageDimension,
      );

      if (result == null) {
        throw MediaException('Image compression failed');
      }

      return File(result.path);
    } catch (e) {
      throw MediaException('Failed to compress image: $e');
    }
  }

  /// Validate image file
  Future<ImageValidationResult> validateImage(File imageFile) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        return ImageValidationResult(
          isValid: false,
          error: 'Image file does not exist',
        );
      }

      // Check file size
      final fileSizeInBytes = await imageFile.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > MomentConstants.maxImageSizeMB) {
        return ImageValidationResult(
          isValid: false,
          error: 'Image size exceeds ${MomentConstants.maxImageSizeMB}MB',
          fileSizeMB: fileSizeInMB,
        );
      }

      return ImageValidationResult(
        isValid: true,
        fileSizeMB: fileSizeInMB,
      );
    } catch (e) {
      return ImageValidationResult(
        isValid: false,
        error: 'Failed to validate image: $e',
      );
    }
  }

  // ===============================
  // VIDEO OPERATIONS
  // ===============================

  /// Pick video from gallery
  Future<File?> pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration:
            const Duration(seconds: MomentConstants.maxVideoDurationSeconds),
      );

      if (video == null) return null;

      return File(video.path);
    } catch (e) {
      throw MediaException('Failed to pick video: $e');
    }
  }

  /// Record video with camera
  Future<File?> recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration:
            const Duration(seconds: MomentConstants.maxVideoDurationSeconds),
      );

      if (video == null) return null;

      return File(video.path);
    } catch (e) {
      throw MediaException('Failed to record video: $e');
    }
  }

  /// Validate video file
  Future<VideoValidationResult> validateVideo(File videoFile) async {
    try {
      // Check if file exists
      if (!await videoFile.exists()) {
        return VideoValidationResult(
          isValid: false,
          error: 'Video file does not exist',
        );
      }

      // Check file size
      final fileSizeInBytes = await videoFile.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > MomentConstants.maxVideoSizeMB) {
        return VideoValidationResult(
          isValid: false,
          error: 'Video size exceeds ${MomentConstants.maxVideoSizeMB}MB',
          fileSizeMB: fileSizeInMB,
        );
      }

      // Check video duration
      final controller = VideoPlayerController.file(videoFile);
      try {
        await controller.initialize();
        final duration = controller.value.duration;

        if (duration.inSeconds > MomentConstants.maxVideoDurationSeconds) {
          return VideoValidationResult(
            isValid: false,
            error:
                'Video duration exceeds ${MomentConstants.maxVideoDurationSeconds} seconds',
            durationSeconds: duration.inSeconds,
            fileSizeMB: fileSizeInMB,
          );
        }

        return VideoValidationResult(
          isValid: true,
          durationSeconds: duration.inSeconds,
          fileSizeMB: fileSizeInMB,
        );
      } finally {
        await controller.dispose();
      }
    } catch (e) {
      return VideoValidationResult(
        isValid: false,
        error: 'Failed to validate video: $e',
      );
    }
  }

  /// Get video thumbnail
  Future<File?> getVideoThumbnail(File videoFile) async {
    try {
      // This is a placeholder - you'll need to implement actual thumbnail extraction
      // Using packages like video_thumbnail or ffmpeg_kit_flutter_new
      // For now, return null and handle in UI
      return null;
    } catch (e) {
      throw MediaException('Failed to get video thumbnail: $e');
    }
  }

  // ===============================
  // MEDIA TYPE DETECTION
  // ===============================

  /// Determine media type from files
  MomentMediaType getMediaType(List<File> files) {
    if (files.isEmpty) {
      return MomentMediaType.text;
    }

    final firstFile = files.first;
    final extension = path.extension(firstFile.path).toLowerCase();

    if (_isVideoExtension(extension)) {
      return MomentMediaType.video;
    } else if (_isImageExtension(extension)) {
      return MomentMediaType.images;
    }

    return MomentMediaType.text;
  }

  bool _isVideoExtension(String extension) {
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(extension);
  }

  bool _isImageExtension(String extension) {
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic']
        .contains(extension);
  }

  // ===============================
  // GRID LAYOUT HELPER
  // ===============================

  /// Calculate grid layout for images
  GridLayout calculateGridLayout(int imageCount) {
    if (imageCount <= 0) {
      return GridLayout(rows: 0, columns: 0);
    } else if (imageCount == 1) {
      return GridLayout(rows: 1, columns: 1);
    } else if (imageCount == 2) {
      return GridLayout(rows: 1, columns: 2);
    } else if (imageCount <= 4) {
      return GridLayout(rows: 2, columns: 2);
    } else if (imageCount <= 6) {
      return GridLayout(rows: 2, columns: 3);
    } else {
      return GridLayout(rows: 3, columns: 3);
    }
  }
}

// ===============================
// VALIDATION RESULTS
// ===============================

class ImageValidationResult {
  final bool isValid;
  final String? error;
  final double? fileSizeMB;

  ImageValidationResult({
    required this.isValid,
    this.error,
    this.fileSizeMB,
  });
}

class VideoValidationResult {
  final bool isValid;
  final String? error;
  final int? durationSeconds;
  final double? fileSizeMB;

  VideoValidationResult({
    required this.isValid,
    this.error,
    this.durationSeconds,
    this.fileSizeMB,
  });
}

class GridLayout {
  final int rows;
  final int columns;

  GridLayout({required this.rows, required this.columns});

  int get totalCells => rows * columns;
}

// ===============================
// EXCEPTIONS
// ===============================

class MediaException implements Exception {
  final String message;
  MediaException(this.message);

  @override
  String toString() => 'MediaException: $message';
}
