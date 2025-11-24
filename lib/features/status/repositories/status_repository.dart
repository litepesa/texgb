// ===============================
// Status Repository
// Abstract interface for status data operations
// ===============================

import 'dart:io';
import 'package:textgb/features/status/models/status_model.dart';

/// Abstract repository interface for status operations
/// Follows the repository pattern used across the app
abstract class StatusRepository {
  // ===============================
  // FETCH OPERATIONS
  // ===============================

  /// Get all statuses from contacts
  Future<List<StatusGroup>> getAllStatuses();

  /// Get current user's statuses
  Future<List<StatusModel>> getMyStatuses();

  /// Get specific user's statuses
  Future<List<StatusModel>> getUserStatuses(String userId);

  // ===============================
  // CREATE/DELETE OPERATIONS
  // ===============================

  /// Create a new status
  Future<StatusModel> createStatus(CreateStatusRequest request);

  /// Delete a status (owner only)
  Future<bool> deleteStatus(String statusId);

  // ===============================
  // INTERACTIONS
  // ===============================

  /// Mark status as viewed
  Future<bool> viewStatus(String statusId);

  /// Like a status
  Future<bool> likeStatus(String statusId);

  /// Unlike a status
  Future<bool> unlikeStatus(String statusId);

  /// Send gift to status owner
  Future<bool> sendGift({
    required String statusId,
    required String recipientId,
    required String giftId,
  });

  // ===============================
  // UPLOAD OPERATIONS
  // ===============================

  /// Upload media file for status (image or video)
  Future<String> uploadMedia({
    required File file,
    required bool isVideo,
  });

  /// Upload image status with file
  Future<Map<String, String?>> uploadImageStatus(File imageFile);

  /// Upload video status with file (includes thumbnail generation)
  Future<Map<String, String?>> uploadVideoStatus(File videoFile);
}

// ===============================
// REPOSITORY EXCEPTION
// ===============================

class StatusRepositoryException implements Exception {
  final String message;
  const StatusRepositoryException(this.message);

  @override
  String toString() => 'StatusRepositoryException: $message';
}
