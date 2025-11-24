// ===============================
// HTTP Status Repository
// HTTP backend implementation for status operations
// Combines API calls and upload logic
// ===============================

import 'dart:convert';
import 'dart:io';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/models/status_constants.dart';
import 'package:textgb/features/status/repositories/status_repository.dart';
import 'package:textgb/features/videos/services/video_thumbnail_service.dart';
import 'package:textgb/shared/services/http_client.dart';

/// HTTP implementation of StatusRepository for Elixir/Phoenix backend
class HttpStatusRepository implements StatusRepository {
  final HttpClientService _httpClient;

  HttpStatusRepository({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  // ===============================
  // FETCH OPERATIONS
  // ===============================

  @override
  Future<List<StatusGroup>> getAllStatuses() async {
    try {
      final response = await _httpClient.get(StatusConstants.apiGetStatuses);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final statusGroups = data['statusGroups'] as List<dynamic>? ??
            data['status_groups'] as List<dynamic>?;

        if (statusGroups != null) {
          return statusGroups
              .map((json) => StatusGroup.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } catch (e) {
      throw StatusRepositoryException('Failed to fetch statuses: $e');
    }
  }

  @override
  Future<List<StatusModel>> getMyStatuses() async {
    try {
      final response = await _httpClient.get(StatusConstants.apiGetMyStatuses);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final statuses = data['statuses'] as List<dynamic>?;

        if (statuses != null) {
          return statuses
              .map((json) => StatusModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } catch (e) {
      throw StatusRepositoryException('Failed to fetch my statuses: $e');
    }
  }

  @override
  Future<List<StatusModel>> getUserStatuses(String userId) async {
    try {
      final response = await _httpClient
          .get('${StatusConstants.apiGetUserStatuses}/$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final statuses = data['statuses'] as List<dynamic>?;

        if (statuses != null) {
          return statuses
              .map((json) => StatusModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      return [];
    } catch (e) {
      throw StatusRepositoryException('Failed to fetch user statuses: $e');
    }
  }

  // ===============================
  // CREATE/DELETE OPERATIONS
  // ===============================

  @override
  Future<StatusModel> createStatus(CreateStatusRequest request) async {
    try {
      final response = await _httpClient.post(
        StatusConstants.apiCreateStatus,
        body: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'] as Map<String, dynamic>? ?? data;
        return StatusModel.fromJson(status);
      }

      throw StatusRepositoryException(
          'Failed to create status: ${response.statusCode}');
    } catch (e) {
      throw StatusRepositoryException('Failed to create status: $e');
    }
  }

  @override
  Future<bool> deleteStatus(String statusId) async {
    try {
      final response = await _httpClient
          .delete('${StatusConstants.apiDeleteStatus}/$statusId');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw StatusRepositoryException('Failed to delete status: $e');
    }
  }

  // ===============================
  // INTERACTIONS
  // ===============================

  @override
  Future<bool> viewStatus(String statusId) async {
    try {
      final endpoint =
          StatusConstants.apiViewStatus.replaceAll('{id}', statusId);
      final response = await _httpClient.post(endpoint, body: {});

      return response.statusCode == 200;
    } catch (e) {
      throw StatusRepositoryException('Failed to view status: $e');
    }
  }

  @override
  Future<bool> likeStatus(String statusId) async {
    try {
      final endpoint =
          StatusConstants.apiLikeStatus.replaceAll('{id}', statusId);
      final response = await _httpClient.post(endpoint, body: {});

      return response.statusCode == 200;
    } catch (e) {
      throw StatusRepositoryException('Failed to like status: $e');
    }
  }

  @override
  Future<bool> unlikeStatus(String statusId) async {
    try {
      final endpoint =
          StatusConstants.apiUnlikeStatus.replaceAll('{id}', statusId);
      final response = await _httpClient.delete(endpoint);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw StatusRepositoryException('Failed to unlike status: $e');
    }
  }

  @override
  Future<bool> sendGift({
    required String statusId,
    required String recipientId,
    required String giftId,
  }) async {
    try {
      final response = await _httpClient.post(
        StatusConstants.apiSendGift,
        body: {
          'recipientId': recipientId,
          'giftId': giftId,
          'source': 'status',
          'sourceId': statusId,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw StatusRepositoryException('Failed to send gift: $e');
    }
  }

  // ===============================
  // UPLOAD OPERATIONS
  // ===============================

  @override
  Future<String> uploadMedia({
    required File file,
    required bool isVideo,
  }) async {
    try {
      print('🔼 Uploading ${isVideo ? 'video' : 'image'} to ${StatusConstants.apiUploadMedia}');
      print('📁 File path: ${file.path}');
      print('📦 File size: ${await file.length()} bytes');

      // Backend expects field name "file" and type parameter
      final response = await _httpClient.uploadFile(
        StatusConstants.apiUploadMedia,
        file,
        'file', // Field name must be "file"
        additionalFields: {
          'type': isVideo ? 'video' : 'post', // "post" for images, "video" for videos
        },
      );

      print('📡 Upload response status: ${response.statusCode}');
      print('📡 Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          print('📦 Parsed response data: $data');

          // Backend returns "url" field
          final mediaUrl = data['url'];

          if (mediaUrl == null) {
            throw StatusRepositoryException(
              'Upload response missing URL. Response: ${response.body}'
            );
          }

          if (mediaUrl is! String) {
            throw StatusRepositoryException(
              'Upload URL is not a string. Got: ${mediaUrl.runtimeType}. Response: ${response.body}'
            );
          }

          print('✅ Upload successful: $mediaUrl');
          return mediaUrl;
        } catch (e) {
          throw StatusRepositoryException(
            'Failed to parse upload response: $e. Body: ${response.body}'
          );
        }
      }

      // Handle error responses
      String errorMessage = 'Upload failed with status ${response.statusCode}';
      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = errorData['error'] as String? ??
                      errorData['message'] as String? ??
                      errorMessage;
      } catch (_) {
        errorMessage += ': ${response.body}';
      }

      throw StatusRepositoryException(errorMessage);
    } catch (e) {
      if (e is StatusRepositoryException) rethrow;
      throw StatusRepositoryException('Upload failed: $e');
    }
  }

  @override
  Future<Map<String, String?>> uploadImageStatus(File imageFile) async {
    try {
      // Validate file size
      final fileSize = await imageFile.length();
      if (fileSize > 100 * 1024 * 1024) {
        // 100MB
        throw StatusRepositoryException('Image file size exceeds 100MB limit');
      }

      // Validate file format
      final extension = imageFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
        throw StatusRepositoryException(
            'Invalid image format. Supported: JPG, PNG, GIF, WEBP');
      }

      // Upload image
      final mediaUrl = await uploadMedia(file: imageFile, isVideo: false);

      return {
        'mediaUrl': mediaUrl,
      };
    } catch (e) {
      if (e is StatusRepositoryException) rethrow;
      throw StatusRepositoryException('Failed to upload image status: $e');
    }
  }

  @override
  Future<Map<String, String?>> uploadVideoStatus(File videoFile) async {
    try {
      // Validate file size
      final fileSize = await videoFile.length();
      if (fileSize > 100 * 1024 * 1024) {
        // 100MB
        throw StatusRepositoryException('Video file size exceeds 100MB limit');
      }

      // Validate file format
      final extension = videoFile.path.split('.').last.toLowerCase();
      if (!['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
        throw StatusRepositoryException(
            'Invalid video format. Supported: MP4, MOV, AVI, MKV, WEBM');
      }

      // Generate thumbnail from video
      final thumbnailService = VideoThumbnailService();
      final thumbnailFile = await thumbnailService.generateBestThumbnailFile(
        videoFile: videoFile,
        maxWidth: 400,
        maxHeight: 600,
        quality: 85,
      );

      // Upload video
      final mediaUrl = await uploadMedia(file: videoFile, isVideo: true);

      // Upload thumbnail if generated
      String? thumbnailUrl;
      if (thumbnailFile != null) {
        try {
          // Upload thumbnail with "thumbnail" type
          final response = await _httpClient.uploadFile(
            StatusConstants.apiUploadMedia,
            thumbnailFile,
            'file',
            additionalFields: {
              'type': 'thumbnail',
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            thumbnailUrl = data['url'] as String?;
          }
        } catch (e) {
          // Continue without thumbnail if upload fails
        }
      }

      return {
        'mediaUrl': mediaUrl,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      };
    } catch (e) {
      if (e is StatusRepositoryException) rethrow;
      throw StatusRepositoryException('Failed to upload video status: $e');
    }
  }
}
