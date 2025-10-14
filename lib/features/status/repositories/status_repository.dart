// lib/features/status/repositories/status_repository.dart
// Abstract repository interface for status operations
// Defines contract for HTTP + SQLite implementation

import 'dart:io';
import 'package:textgb/features/status/models/status_model.dart';

/// Exception class for status repository errors
class StatusRepositoryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const StatusRepositoryException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'StatusRepositoryException: $message';
}

/// Abstract repository interface for all status operations
/// Implementation will use HTTP for server + SQLite for local caching
abstract class StatusRepository {
  // ===============================
  // STATUS OPERATIONS
  // ===============================

  /// Get all active statuses (not expired)
  /// Returns statuses from local cache first, then syncs with server
  Future<List<StatusModel>> getStatuses();

  /// Get statuses from specific user
  Future<List<StatusModel>> getUserStatuses(String userId);

  /// Get current user's statuses
  Future<List<StatusModel>> getMyStatuses();

  /// Get a specific status by ID
  Future<StatusModel?> getStatusById(String statusId);

  /// Create a new image status
  Future<StatusModel> createImageStatus({
    required File imageFile,
    String? caption,
    StatusPrivacy privacy = StatusPrivacy.everyone,
    List<String>? selectedContactIds,
  });

  /// Create a new video status
  Future<StatusModel> createVideoStatus({
    required File videoFile,
    String? caption,
    StatusPrivacy privacy = StatusPrivacy.everyone,
    List<String>? selectedContactIds,
  });

  /// Create a new text status
  Future<StatusModel> createTextStatus({
    required String text,
    required String backgroundColor,
    required String textColor,
    StatusPrivacy privacy = StatusPrivacy.everyone,
    List<String>? selectedContactIds,
  });

  /// Delete a status
  Future<void> deleteStatus(String statusId);

  /// Increment view count for a status
  Future<void> incrementViewCount(String statusId);

  /// Check if user has viewed a status
  Future<bool> hasViewedStatus(String statusId);

  /// Mark status as viewed
  Future<void> markStatusAsViewed(String statusId);

  /// Get statuses that user hasn't viewed yet
  Future<List<StatusModel>> getUnviewedStatuses();

  /// Listen to real-time status updates
  Stream<StatusModel> watchStatuses();

  /// Listen to specific user's status updates
  Stream<List<StatusModel>> watchUserStatuses(String userId);

  // ===============================
  // PRIVACY OPERATIONS
  // ===============================

  /// Update status privacy settings
  Future<void> updateStatusPrivacy({
    required String statusId,
    required StatusPrivacy privacy,
    List<String>? selectedContactIds,
  });

  /// Get users who can view a status based on privacy settings
  Future<List<String>> getStatusViewers(String statusId);

  /// Check if a user can view a specific status
  Future<bool> canViewStatus(String statusId, String userId);

  // ===============================
  // MUTE OPERATIONS
  // ===============================

  /// Mute status updates from a user
  Future<void> muteUserStatus(String userId);

  /// Unmute status updates from a user
  Future<void> unmuteUserStatus(String userId);

  /// Check if user's statuses are muted
  Future<bool> isUserStatusMuted(String userId);

  /// Get list of muted users
  Future<List<String>> getMutedUsers();

  // ===============================
  // MEDIA OPERATIONS
  // ===============================

  /// Upload status media file to server
  /// Returns URL of uploaded file
  Future<String> uploadStatusMedia({
    required File file,
    required String type, // 'image' or 'video'
    Function(double progress)? onProgress,
  });

  /// Download status media file
  /// Returns local file path
  Future<String> downloadStatusMedia({
    required String url,
    required String fileName,
    Function(double progress)? onProgress,
  });

  // ===============================
  // SYNC OPERATIONS
  // ===============================

  /// Sync local database with server
  /// Removes expired statuses and fetches new ones
  Future<void> syncWithServer();

  /// Force refresh statuses from server
  Future<List<StatusModel>> refreshStatuses();

  /// Delete expired statuses from local storage
  Future<void> deleteExpiredStatuses();

  // ===============================
  // CACHE OPERATIONS
  // ===============================

  /// Clear all local status cache
  Future<void> clearCache();

  /// Clear cache for specific user
  Future<void> clearUserCache(String userId);

  /// Get cache size
  Future<int> getCacheSize();

  // ===============================
  // USER INFO OPERATIONS
  // ===============================

  /// Get current user ID
  String? get currentUserId;

  /// Check if user has any active statuses
  Future<bool> hasActiveStatuses(String userId);

  /// Get count of user's active statuses
  Future<int> getActiveStatusCount(String userId);

  /// Get users with active statuses
  Future<List<String>> getUsersWithActiveStatuses();

  // ===============================
  // STATISTICS
  // ===============================

  /// Get total view count for user's statuses
  Future<int> getTotalViewCount(String userId);

  /// Get view count for specific status
  Future<int> getStatusViewCount(String statusId);

  /// Get most viewed status for user
  Future<StatusModel?> getMostViewedStatus(String userId);
}

/// Implementation hint: Concrete implementation will:
/// 1. Use HTTP for CRUD operations with backend
/// 2. Use SQLite for local caching and offline access
/// 3. Implement 24-hour expiration logic
/// 4. Handle privacy settings for status visibility
/// 5. Track view counts and muted users
/// 6. Provide streams for real-time UI updates
/// 7. Auto-cleanup expired statuses