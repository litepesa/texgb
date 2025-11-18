// ===============================
// Status Upload Service
// Handles media compression and upload for statuses
// ===============================

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:textgb/features/status/models/status_constants.dart';
import 'package:textgb/features/status/models/status_enums.dart';
import 'package:textgb/features/status/services/status_api_service.dart';

class StatusUploadService {
  final StatusApiService _apiService;
  final ImagePicker _imagePicker;

  StatusUploadService({
    StatusApiService? apiService,
    ImagePicker? imagePicker,
  })  : _apiService = apiService ?? StatusApiService(),
        _imagePicker = imagePicker ?? ImagePicker();

  // ===============================
  // PICK MEDIA
  // ===============================

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: StatusConstants.imageQuality,
      );

      if (image != null) {
        return File(image.path);
      }

      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      rethrow;
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: StatusConstants.imageQuality,
      );

      if (image != null) {
        return File(image.path);
      }

      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      rethrow;
    }
  }

  /// Pick video from camera
  Future<File?> pickVideoFromCamera() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: StatusConstants.videoStatusMaxDuration),
      );

      if (video != null) {
        return File(video.path);
      }

      return null;
    } catch (e) {
      print('Error picking video from camera: $e');
      rethrow;
    }
  }

  /// Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: StatusConstants.videoStatusMaxDuration),
      );

      if (video != null) {
        return File(video.path);
      }

      return null;
    } catch (e) {
      print('Error picking video from gallery: $e');
      rethrow;
    }
  }

  // ===============================
  // COMPRESS MEDIA
  // ===============================

  /// Compress image
  Future<File> compressImage(File imageFile) async {
    try {
      // Check file size
      final fileSize = await imageFile.length();
      if (fileSize > StatusConstants.maxImageSizeBytes) {
        throw Exception(StatusConstants.errorTooLarge);
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Compress
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: StatusConstants.imageQuality,
      );

      if (compressedFile != null) {
        return File(compressedFile.path);
      }

      // If compression failed, return original
      return imageFile;
    } catch (e) {
      print('Error compressing image: $e');
      rethrow;
    }
  }

  /// Compress video
  Future<File?> compressVideo(File videoFile) async {
    try {
      // Check file size
      final fileSize = await videoFile.length();
      if (fileSize > StatusConstants.maxVideoSizeBytes) {
        throw Exception(StatusConstants.errorTooLarge);
      }

      // Compress video
      final MediaInfo? info = await VideoCompress.compressVideo(
        videoFile.path,
        quality: _getVideoQuality(),
        deleteOrigin: false,
      );

      if (info != null && info.file != null) {
        return info.file!;
      }

      // If compression failed, return original
      return videoFile;
    } catch (e) {
      print('Error compressing video: $e');
      rethrow;
    }
  }

  /// Get video compression quality enum
  VideoQuality _getVideoQuality() {
    switch (StatusConstants.videoQuality) {
      case 'low':
        return VideoQuality.LowQuality;
      case 'medium':
        return VideoQuality.MediumQuality;
      case 'high':
        return VideoQuality.HighestQuality;
      default:
        return VideoQuality.MediumQuality;
    }
  }

  // ===============================
  // GENERATE THUMBNAIL
  // ===============================

  /// Generate thumbnail for video
  Future<File?> generateVideoThumbnail(File videoFile) async {
    try {
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoFile.path,
        quality: StatusConstants.thumbnailQuality,
      );

      return thumbnailFile;
    } catch (e) {
      print('Error generating video thumbnail: $e');
      return null;
    }
  }

  // ===============================
  // UPLOAD WORKFLOW
  // ===============================

  /// Complete upload workflow for image status
  Future<Map<String, String>> uploadImageStatus(File imageFile) async {
    try {
      // Compress image
      final compressedImage = await compressImage(imageFile);

      // Upload to server
      final mediaUrl = await _apiService.uploadMedia(
        compressedImage.path,
        isVideo: false,
      );

      return {
        'mediaUrl': mediaUrl,
      };
    } catch (e) {
      print('Error uploading image status: $e');
      rethrow;
    }
  }

  /// Complete upload workflow for video status
  Future<Map<String, String>> uploadVideoStatus(File videoFile) async {
    try {
      // Compress video
      final compressedVideo = await compressVideo(videoFile);

      if (compressedVideo == null) {
        throw Exception('Video compression failed');
      }

      // Generate thumbnail
      final thumbnail = await generateVideoThumbnail(compressedVideo);

      // Upload video
      final mediaUrl = await _apiService.uploadMedia(
        compressedVideo.path,
        isVideo: true,
      );

      // Upload thumbnail if available
      String? thumbnailUrl;
      if (thumbnail != null) {
        thumbnailUrl = await _apiService.uploadMedia(
          thumbnail.path,
          isVideo: false,
        );
      }

      return {
        'mediaUrl': mediaUrl,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      };
    } catch (e) {
      print('Error uploading video status: $e');
      rethrow;
    }
  }

  // ===============================
  // VALIDATION
  // ===============================

  /// Validate image file
  bool isValidImage(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Validate video file
  bool isValidVideo(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
  }

  /// Get file size in bytes
  Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// Check if file size is within limits
  Future<bool> isFileSizeValid(File file, StatusMediaType mediaType) async {
    final size = await getFileSize(file);

    if (mediaType == StatusMediaType.image) {
      return size <= StatusConstants.maxImageSizeBytes;
    } else if (mediaType == StatusMediaType.video) {
      return size <= StatusConstants.maxVideoSizeBytes;
    }

    return true;
  }

  // ===============================
  // CLEANUP
  // ===============================

  /// Cancel all video compression operations
  void cancelVideoCompression() {
    VideoCompress.cancelCompression();
  }

  /// Delete subscription (for video compress progress)
  void dispose() {
    VideoCompress.dispose();
  }
}
