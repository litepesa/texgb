// lib/features/channels/services/post_creation_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class PostCreationService extends ChangeNotifier {
  // Upload state
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  
  // Getters
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get uploadStatus => _uploadStatus;
  
  // File validation
  MediaValidation validateMediaFile(File file, bool isVideo) {
    final fileSize = file.lengthSync();
    final extension = path.extension(file.path).toLowerCase();
    
    if (isVideo) {
      // Video validation
      if (!{'.mp4', '.mov', '.avi', '.mkv'}.contains(extension)) {
        return MediaValidation(
          isValid: false,
          message: 'Invalid video format. Please use MP4, MOV, AVI, or MKV.',
        );
      }
      
      if (fileSize > 500 * 1024 * 1024) { // 500MB limit
        return MediaValidation(
          isValid: false,
          message: 'Video size must be less than 500MB.',
        );
      }
    } else {
      // Image validation
      if (!{'.jpg', '.jpeg', '.png', '.gif', '.webp'}.contains(extension)) {
        return MediaValidation(
          isValid: false,
          message: 'Invalid image format. Please use JPG, PNG, GIF, or WEBP.',
        );
      }
      
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit per image
        return MediaValidation(
          isValid: false,
          message: 'Image size must be less than 10MB.',
        );
      }
    }
    
    return MediaValidation(isValid: true, message: 'Valid');
  }
  
  // Validate multiple images
  MediaValidation validateImages(List<File> images) {
    if (images.isEmpty) {
      return MediaValidation(
        isValid: false,
        message: 'Please select at least one image.',
      );
    }
    
    if (images.length > 10) {
      return MediaValidation(
        isValid: false,
        message: 'You can only upload up to 10 images at once.',
      );
    }
    
    for (final image in images) {
      final validation = validateMediaFile(image, false);
      if (!validation.isValid) {
        return validation;
      }
    }
    
    return MediaValidation(isValid: true, message: 'Valid');
  }
  
  // Upload management
  void startUpload() {
    _isUploading = true;
    _uploadProgress = 0.0;
    _uploadStatus = 'Preparing upload...';
    notifyListeners();
  }
  
  void updateUploadProgress(double progress, String status) {
    _uploadProgress = progress;
    _uploadStatus = status;
    notifyListeners();
  }
  
  void completeUpload() {
    _isUploading = false;
    _uploadProgress = 1.0;
    _uploadStatus = 'Upload complete!';
    notifyListeners();
  }
  
  void resetUpload() {
    _isUploading = false;
    _uploadProgress = 0.0;
    _uploadStatus = '';
    notifyListeners();
  }
  
  // Helper method to format file size
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class MediaValidation {
  final bool isValid;
  final String message;
  
  MediaValidation({
    required this.isValid,
    required this.message,
  });
}