// lib/features/channels/services/post_creation_service.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class PostCreationService extends ChangeNotifier {
  // Upload progress tracking
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  bool _isUploading = false;
  bool _canCancel = true;
  int _uploadSpeed = 0; // bytes per second
  Duration _estimatedTimeRemaining = Duration.zero;
  DateTime? _uploadStartTime;
  int _totalBytes = 0;
  int _uploadedBytes = 0;

  // Getters
  double get uploadProgress => _uploadProgress;
  String get uploadStatus => _uploadStatus;
  bool get isUploading => _isUploading;
  bool get canCancel => _canCancel;
  int get uploadSpeed => _uploadSpeed;
  Duration get estimatedTimeRemaining => _estimatedTimeRemaining;
  String get uploadSpeedFormatted => _formatSpeed(_uploadSpeed);

  // Media processing state
  bool _isProcessing = false;
  String _processingStatus = '';
  
  bool get isProcessing => _isProcessing;
  String get processingStatus => _processingStatus;

  // Cancel token for uploads
  bool _isCancelled = false;

  /// Optimize image before upload
  Future<File> optimizeImage(File imageFile, {
    int maxWidth = 1080,
    int maxHeight = 1080,
    int quality = 85,
  }) async {
    try {
      _setProcessingStatus(true, 'Optimizing image...');
      
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) throw Exception('Invalid image format');

      // Calculate new dimensions maintaining aspect ratio
      final aspectRatio = image.width / image.height;
      int newWidth = image.width;
      int newHeight = image.height;

      if (image.width > maxWidth || image.height > maxHeight) {
        if (aspectRatio > 1) {
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
      }

      // Resize image
      final resized = img.copyResize(image, width: newWidth, height: newHeight);
      
      // Encode with quality
      final optimizedBytes = img.encodeJpg(resized, quality: quality);
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final optimizedFile = File('${tempDir.path}/optimized_$timestamp.jpg');
      await optimizedFile.writeAsBytes(optimizedBytes);
      
      _setProcessingStatus(false, '');
      return optimizedFile;
    } catch (e) {
      _setProcessingStatus(false, '');
      debugPrint('Error optimizing image: $e');
      return imageFile; // Return original if optimization fails
    }
  }

  /// Generate thumbnail for video
  Future<String> generateVideoThumbnail(File videoFile) async {
    try {
      _setProcessingStatus(true, 'Generating thumbnail...');
      
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final thumbnailPath = '${tempDir.path}/thumb_$timestamp.jpg';
      
      // Use FFmpeg to extract thumbnail at 1 second
      final command = '-i "${videoFile.path}" -ss 00:00:01.000 -vframes 1 -vf "scale=300:300:force_original_aspect_ratio=decrease,pad=300:300:(ow-iw)/2:(oh-ih)/2" "$thumbnailPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        _setProcessingStatus(false, '');
        return thumbnailPath;
      } else {
        throw Exception('Failed to generate thumbnail');
      }
    } catch (e) {
      _setProcessingStatus(false, '');
      debugPrint('Error generating thumbnail: $e');
      return ''; // Return empty string if thumbnail generation fails
    }
  }

  /// Trim video using FFmpeg
  Future<File> trimVideo(
    File videoFile,
    Duration startTime,
    Duration endTime,
  ) async {
    try {
      _setProcessingStatus(true, 'Trimming video...');
      
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${tempDir.path}/trimmed_$timestamp.mp4';
      
      final startSeconds = startTime.inMilliseconds / 1000;
      final duration = (endTime - startTime).inMilliseconds / 1000;
      
      // FFmpeg command to trim video
      final command = '-i "${videoFile.path}" -ss $startSeconds -t $duration -c copy "$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        _setProcessingStatus(false, '');
        return File(outputPath);
      } else {
        throw Exception('Failed to trim video');
      }
    } catch (e) {
      _setProcessingStatus(false, '');
      debugPrint('Error trimming video: $e');
      rethrow;
    }
  }

  /// Compress video for upload
  Future<File> compressVideo(File videoFile) async {
    try {
      _setProcessingStatus(true, 'Compressing video...');
      
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${tempDir.path}/compressed_$timestamp.mp4';
      
      // FFmpeg command for compression
      final command = '-i "${videoFile.path}" -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k -movflags +faststart "$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        _setProcessingStatus(false, '');
        return File(outputPath);
      } else {
        throw Exception('Failed to compress video');
      }
    } catch (e) {
      _setProcessingStatus(false, '');
      debugPrint('Error compressing video: $e');
      return videoFile; // Return original if compression fails
    }
  }

  /// Validate file size and format
  ValidationResult validateMediaFile(File file, bool isVideo) {
    final extension = file.path.split('.').last.toLowerCase();
    final fileSize = file.lengthSync();
    
    if (isVideo) {
      // Video validation
      final allowedVideoFormats = ['mp4', 'mov', 'avi', 'mkv'];
      if (!allowedVideoFormats.contains(extension)) {
        return ValidationResult(false, 'Unsupported video format. Please use MP4, MOV, AVI, or MKV.');
      }
      
      const maxVideoSize = 500 * 1024 * 1024; // 500MB
      if (fileSize > maxVideoSize) {
        return ValidationResult(false, 'Video file is too large. Maximum size is 500MB.');
      }
    } else {
      // Image validation
      final allowedImageFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      if (!allowedImageFormats.contains(extension)) {
        return ValidationResult(false, 'Unsupported image format. Please use JPG, PNG, GIF, or WebP.');
      }
      
      const maxImageSize = 50 * 1024 * 1024; // 50MB
      if (fileSize > maxImageSize) {
        return ValidationResult(false, 'Image file is too large. Maximum size is 50MB.');
      }
    }
    
    return ValidationResult(true, '');
  }

  /// Start upload with progress tracking
  void startUpload() {
    _isUploading = true;
    _isCancelled = false;
    _uploadProgress = 0.0;
    _uploadStatus = 'Preparing upload...';
    _uploadStartTime = DateTime.now();
    _uploadSpeed = 0;
    _estimatedTimeRemaining = Duration.zero;
    notifyListeners();
  }

  /// Update upload progress
  void updateUploadProgress(int uploaded, int total) {
    if (_isCancelled) return;
    
    _uploadedBytes = uploaded;
    _totalBytes = total;
    _uploadProgress = total > 0 ? uploaded / total : 0.0;
    
    // Calculate upload speed and ETA
    if (_uploadStartTime != null) {
      final elapsed = DateTime.now().difference(_uploadStartTime!);
      if (elapsed.inSeconds > 0) {
        _uploadSpeed = (uploaded / elapsed.inSeconds).round();
        
        if (_uploadSpeed > 0) {
          final remainingBytes = total - uploaded;
          final remainingSeconds = remainingBytes / _uploadSpeed;
          _estimatedTimeRemaining = Duration(seconds: remainingSeconds.round());
        }
      }
    }
    
    // Update status message
    if (_uploadProgress < 1.0) {
      _uploadStatus = 'Uploading... ${(_uploadProgress * 100).toInt()}%';
    } else {
      _uploadStatus = 'Processing...';
    }
    
    notifyListeners();
  }

  /// Complete upload
  void completeUpload() {
    _isUploading = false;
    _uploadProgress = 1.0;
    _uploadStatus = 'Upload completed!';
    _canCancel = false;
    notifyListeners();
  }

  /// Cancel upload
  void cancelUpload() {
    _isCancelled = true;
    _isUploading = false;
    _uploadStatus = 'Upload cancelled';
    _canCancel = false;
    notifyListeners();
  }

  /// Reset upload state
  void resetUpload() {
    _isUploading = false;
    _uploadProgress = 0.0;
    _uploadStatus = '';
    _canCancel = true;
    _uploadSpeed = 0;
    _estimatedTimeRemaining = Duration.zero;
    _uploadStartTime = null;
    _totalBytes = 0;
    _uploadedBytes = 0;
    _isCancelled = false;
    notifyListeners();
  }

  /// Set processing status
  void _setProcessingStatus(bool processing, String status) {
    _isProcessing = processing;
    _processingStatus = status;
    notifyListeners();
  }

  /// Format upload speed
  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond} B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          if (fileName.startsWith('optimized_') || 
              fileName.startsWith('trimmed_') || 
              fileName.startsWith('compressed_') ||
              fileName.startsWith('thumb_')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }

  @override
  void dispose() {
    cleanupTempFiles();
    super.dispose();
  }
}

class ValidationResult {
  final bool isValid;
  final String message;
  
  ValidationResult(this.isValid, this.message);
}