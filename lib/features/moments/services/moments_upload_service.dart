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
      print('[MOMENTS UPLOAD] Uploading image: ${imageFile.path}');
      print('[MOMENTS UPLOAD] File size: ${await imageFile.length()} bytes');

      final response = await _httpClient.uploadFile(
        '/upload',
        imageFile,
        'file',
        additionalFields: {
          'type': 'moment',
        },
      );

      print('[MOMENTS UPLOAD] Upload response status: ${response.statusCode}');
      print('[MOMENTS UPLOAD] Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final url = data['url'] as String;
        print('[MOMENTS UPLOAD] Upload successful! URL: $url');
        return url;
      } else {
        print('[MOMENTS UPLOAD] Upload failed with status ${response.statusCode}');
        throw UploadException('Upload failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('[MOMENTS UPLOAD] ERROR uploading image: $e');
      print('[MOMENTS UPLOAD] Stack trace: $stackTrace');
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
          'type': 'moment',
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
          'type': 'profile',
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
    String type = 'post',
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
