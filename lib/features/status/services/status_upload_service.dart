// ===============================
// Status Upload Service
// Handles media validation and upload for statuses
// No compression - uploads original files with size/duration validation
// ===============================

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/features/status/models/status_enums.dart';
import 'package:textgb/features/status/services/status_api_service.dart';
import 'package:textgb/features/videos/services/video_thumbnail_service.dart';

class StatusUploadService {
  final StatusApiService _apiService;
  final ImagePicker _imagePicker;

  // Validation constants
  static const int maxFileSizeBytes = 100 * 1024 * 1024; // 100MB
  static const int maxVideoDurationSeconds = 120; // 2 minutes

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
        maxDuration: const Duration(seconds: maxVideoDurationSeconds),
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
  // VALIDATION
  // ===============================

  /// Validate image file size
  Future<void> validateImageFile(File imageFile) async {
    final fileSize = await imageFile.length();

    if (fileSize > maxFileSizeBytes) {
      throw Exception('Image file size exceeds 100MB limit');
    }

    if (!isValidImage(imageFile)) {
      throw Exception('Invalid image format. Supported: JPG, PNG, GIF, WEBP');
    }
  }

  /// Validate video file size and duration
  Future<void> validateVideoFile(File videoFile) async {
    final fileSize = await videoFile.length();

    if (fileSize > maxFileSizeBytes) {
      throw Exception('Video file size exceeds 100MB limit');
    }

    if (!isValidVideo(videoFile)) {
      throw Exception('Invalid video format. Supported: MP4, MOV, AVI, MKV, WEBM');
    }

    // Note: Duration validation would require video_player or similar
    // For now, we rely on the picker's maxDuration parameter
  }

  // ===============================
  // UPLOAD WORKFLOW
  // ===============================

  /// Upload image status (no compression - uploads original)
  Future<Map<String, String>> uploadImageStatus(File imageFile) async {
    try {
      // Validate file
      await validateImageFile(imageFile);

      // Upload original file to server
      final mediaUrl = await _apiService.uploadMedia(
        imageFile.path,
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

  /// Upload video status (no compression - uploads original)
  Future<Map<String, String>> uploadVideoStatus(File videoFile) async {
    try {
      // Validate file
      await validateVideoFile(videoFile);

      // Generate thumbnail from video
      final thumbnailService = VideoThumbnailService();
      final thumbnailFile = await thumbnailService.generateBestThumbnailFile(
        videoFile: videoFile,
        maxWidth: 400,
        maxHeight: 600,
        quality: 85,
      );

      // Upload original video to server
      final mediaUrl = await _apiService.uploadMedia(
        videoFile.path,
        isVideo: true,
      );

      // Upload thumbnail if generated
      String? thumbnailUrl;
      if (thumbnailFile != null) {
        try {
          thumbnailUrl = await _apiService.uploadMedia(
            thumbnailFile.path,
            isVideo: false,
          );
          print('Thumbnail uploaded: $thumbnailUrl');
        } catch (e) {
          print('Warning: Failed to upload thumbnail: $e');
          // Continue without thumbnail
        }
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
  // FILE FORMAT VALIDATION
  // ===============================

  /// Validate image file format
  bool isValidImage(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Validate video file format
  bool isValidVideo(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
  }

  /// Get file size in bytes
  Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// Check if file size is within 100MB limit
  Future<bool> isFileSizeValid(File file, StatusMediaType mediaType) async {
    final size = await getFileSize(file);
    return size <= maxFileSizeBytes;
  }
}
