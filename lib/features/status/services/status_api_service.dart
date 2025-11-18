// ===============================
// Status API Service
// Handles all API calls for status feature
// ===============================

import 'dart:convert';
import 'package:textgb/shared/services/http_client.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/models/status_constants.dart';

class StatusApiService {
  final HttpClientService _httpClient;

  StatusApiService({HttpClientService? httpClient})
      : _httpClient = httpClient ?? HttpClientService();

  // ===============================
  // GET STATUSES
  // ===============================

  /// Get all statuses from contacts
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
      print('Error fetching statuses: $e');
      rethrow;
    }
  }

  /// Get my statuses
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
      print('Error fetching my statuses: $e');
      rethrow;
    }
  }

  /// Get specific user's statuses
  Future<List<StatusModel>> getUserStatuses(String userId) async {
    try {
      final response = await _httpClient.get('${StatusConstants.apiGetUserStatuses}/$userId');

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
      print('Error fetching user statuses: $e');
      rethrow;
    }
  }

  // ===============================
  // CREATE STATUS
  // ===============================

  /// Create a new status
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

      throw Exception('Failed to create status: ${response.statusCode}');
    } catch (e) {
      print('Error creating status: $e');
      rethrow;
    }
  }

  // ===============================
  // DELETE STATUS
  // ===============================

  /// Delete a status
  Future<bool> deleteStatus(String statusId) async {
    try {
      final response = await _httpClient.delete('${StatusConstants.apiDeleteStatus}/$statusId');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting status: $e');
      rethrow;
    }
  }

  // ===============================
  // INTERACTIONS
  // ===============================

  /// Mark status as viewed
  Future<bool> viewStatus(String statusId) async {
    try {
      final endpoint = StatusConstants.apiViewStatus.replaceAll('{id}', statusId);
      final response = await _httpClient.post(endpoint, body: {});

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking status as viewed: $e');
      rethrow;
    }
  }

  /// Like a status
  Future<bool> likeStatus(String statusId) async {
    try {
      final endpoint = StatusConstants.apiLikeStatus.replaceAll('{id}', statusId);
      final response = await _httpClient.post(endpoint, body: {});

      return response.statusCode == 200;
    } catch (e) {
      print('Error liking status: $e');
      rethrow;
    }
  }

  /// Unlike a status
  Future<bool> unlikeStatus(String statusId) async {
    try {
      final endpoint = StatusConstants.apiUnlikeStatus.replaceAll('{id}', statusId);
      final response = await _httpClient.delete(endpoint);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error unliking status: $e');
      rethrow;
    }
  }

  /// Send gift to status owner
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
      print('Error sending gift: $e');
      rethrow;
    }
  }

  // ===============================
  // UPLOAD MEDIA
  // ===============================

  /// Upload media file for status (returns media URL)
  Future<String> uploadMedia(String filePath, {required bool isVideo}) async {
    try {
      // Note: Actual multipart upload implementation depends on backend
      // This is a simplified version
      final response = await _httpClient.post(
        StatusConstants.apiUploadMedia,
        body: {
          'filePath': filePath,
          'type': isVideo ? 'video' : 'image',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final mediaUrl = data['mediaUrl'] as String? ??
                        data['media_url'] as String? ??
                        data['url'] as String;
        return mediaUrl;
      }

      throw Exception('Failed to upload media');
    } catch (e) {
      print('Error uploading media: $e');
      rethrow;
    }
  }
}
