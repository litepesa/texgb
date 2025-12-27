// ===============================
// Moments Upload Service
// Handle media uploads to backend/storage
// ===============================

import 'dart:io';
import 'dart:convert';
import 'package:textgb/shared/services/http_client.dart';

class MomentsUploadService {
  final HttpClientService _httpClient;

  MomentsUploadService({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  /// Upload images and return URLs
  Future<List<String>> uploadImages(
    List<File> images, {
    Function(double)? onProgress,
  }) async {
    try {
      final List<String> uploadedUrls = [];
      double totalProgress = 0;

      for (int i = 0; i < images.length; i++) {
        final url = await _uploadSingleImage(images[i]);
        uploadedUrls.add(url);

        // Update progress
        totalProgress = (i + 1) / images.length;
        onProgress?.call(totalProgress);
      }

      return uploadedUrls;
    } catch (e) {
      throw UploadException('Failed to upload images: $e');
    }
  }

  /// Upload single image using HttpClientService
  Future<String> _uploadSingleImage(File imageFile) async {
    try {
      final response = await _httpClient.uploadFile(
        '/upload',
        imageFile,
        'file',
        additionalFields: {
          'type': 'moment_image',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['url'] as String;
      } else {
        throw UploadException('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw UploadException('Failed to upload image: $e');
    }
  }

  /// Upload video and return URL
  Future<String> uploadVideo(
    File videoFile, {
    Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.0);

      final response = await _httpClient.uploadFile(
        '/upload',
        videoFile,
        'file',
        additionalFields: {
          'type': 'moment_video',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        onProgress?.call(1.0);
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['url'] as String;
      } else {
        throw UploadException('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw UploadException('Failed to upload video: $e');
    }
  }

  /// Upload cover photo for timeline
  Future<String> uploadCoverPhoto(File imageFile) async {
    try {
      final response = await _httpClient.uploadFile(
        '/upload',
        imageFile,
        'file',
        additionalFields: {
          'type': 'moment_cover',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['url'] as String;
      } else {
        throw UploadException('Upload failed with status ${response.statusCode}');
      }
    } catch (e) {
      throw UploadException('Failed to upload cover photo: $e');
    }
  }

  /// Upload multiple files (batch upload) - if backend supports it
  Future<List<String>> uploadMultipleFiles(
    List<File> files, {
    String type = 'moment_image',
    Function(double)? onProgress,
  }) async {
    try {
      final List<String> urls = [];
      for (int i = 0; i < files.length; i++) {
        final response = await _httpClient.uploadFile(
          '/upload',
          files[i],
          'file',
          additionalFields: {'type': type},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          urls.add(data['url'] as String);
        }

        // Update progress
        onProgress?.call((i + 1) / files.length);
      }

      return urls;
    } catch (e) {
      throw UploadException('Failed to upload files: $e');
    }
  }
}

/// Upload progress state
class UploadProgress {
  final double progress;
  final String? message;
  final bool isComplete;

  UploadProgress({
    required this.progress,
    this.message,
    this.isComplete = false,
  });

  double get percentage => progress * 100;
}

/// Upload exception
class UploadException implements Exception {
  final String message;
  UploadException(this.message);

  @override
  String toString() => 'UploadException: $message';
}
