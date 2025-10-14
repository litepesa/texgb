// lib/features/status/repositories/status_repository_impl.dart
// Concrete implementation of StatusRepository
// Combines HTTP (REST API) + SQLite (local storage)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/repositories/status_repository.dart';
import 'package:textgb/features/status/services/status_database_service.dart';
import 'package:textgb/shared/services/http_client.dart';

/// Concrete implementation of StatusRepository
/// Uses HTTP for REST operations and SQLite for local caching
class StatusRepositoryImpl implements StatusRepository {
  final StatusDatabaseService _dbService;
  final HttpClientService _httpClient;

  // Stream controllers for real-time updates
  final _statusUpdateController = StreamController<StatusModel>.broadcast();
  final _userStatusesController = StreamController<List<StatusModel>>.broadcast();

  // Auto-cleanup timer for expired statuses
  Timer? _cleanupTimer;

  StatusRepositoryImpl({
    StatusDatabaseService? dbService,
    HttpClientService? httpClient,
  })  : _dbService = dbService ?? StatusDatabaseService(),
        _httpClient = httpClient ?? HttpClientService() {
    _startAutoCleanup();
  }

  // ===============================
  // INITIALIZATION
  // ===============================

  /// Start automatic cleanup of expired statuses every hour
  void _startAutoCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      try {
        await deleteExpiredStatuses();
      } catch (e) {
        debugPrint('Auto-cleanup failed: $e');
      }
    });
  }

  // ===============================
  // STATUS OPERATIONS
  // ===============================

  @override
  Future<List<StatusModel>> getStatuses() async {
    try {
      // Load from local DB first (instant)
      final localStatuses = await _dbService.getStatusesExcludingMuted();

      // Return local data immediately
      if (localStatuses.isNotEmpty) {
        return localStatuses;
      }

      // Fetch from server in background
      _syncStatusesInBackground();

      return localStatuses;
    } catch (e) {
      debugPrint('❌ Error getting statuses: $e');
      throw StatusRepositoryException('Failed to get statuses', originalError: e);
    }
  }

  Future<void> _syncStatusesInBackground() async {
    try {
      final response = await _httpClient.get('/statuses');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final statuses = (data['statuses'] as List)
            .map((s) => StatusModel.fromMap(s, s['id']))
            .toList();

        // Update local DB
        await _dbService.batchInsertStatuses(statuses);
      }
    } catch (e) {
      debugPrint('Background status sync failed: $e');
    }
  }

  @override
  Future<List<StatusModel>> getUserStatuses(String userId) async {
    try {
      // Check local DB first
      final localStatuses = await _dbService.getUserStatuses(userId);

      if (localStatuses.isNotEmpty) {
        return localStatuses;
      }

      // Fetch from server if empty
      final response = await _httpClient.get('/statuses/user/$userId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final statuses = (data['statuses'] as List)
            .map((s) => StatusModel.fromMap(s, s['id']))
            .toList();

        // Save to local DB
        await _dbService.batchInsertStatuses(statuses);
        return statuses;
      }

      return localStatuses;
    } catch (e) {
      debugPrint('❌ Error getting user statuses: $e');
      throw StatusRepositoryException('Failed to get user statuses', originalError: e);
    }
  }

  @override
  Future<List<StatusModel>> getMyStatuses() async {
    try {
      final userId = currentUserId;
      if (userId == null) throw StatusRepositoryException('User not authenticated');

      return await getUserStatuses(userId);
    } catch (e) {
      debugPrint('❌ Error getting my statuses: $e');
      throw StatusRepositoryException('Failed to get my statuses', originalError: e);
    }
  }

  @override
  Future<StatusModel?> getStatusById(String statusId) async {
    try {
      // Check local DB first
      final localStatus = await _dbService.getStatusById(statusId);

      if (localStatus != null) {
        return localStatus;
      }

      // Fetch from server if not found locally
      final response = await _httpClient.get('/statuses/$statusId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = StatusModel.fromMap(data, data['id']);
        await _dbService.upsertStatus(status);
        return status;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error getting status by ID: $e');
      throw StatusRepositoryException('Failed to get status', originalError: e);
    }
  }

  @override
  Future<StatusModel> createImageStatus({
    required File imageFile,
    String? caption,
    StatusPrivacy privacy = StatusPrivacy.everyone,
    List<String>? selectedContactIds,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StatusRepositoryException('User not authenticated');

      // Upload image first
      final imageUrl = await uploadStatusMedia(file: imageFile, type: 'image');

      // Create status via API
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final response = await _httpClient.post('/statuses', body: {
        'userId': user.uid,
        'userName': user.displayName ?? 'User',
        'userImage': user.photoURL ?? '',
        'type': 'image',
        'mediaUrl': imageUrl,
        'caption': caption,
        'privacy': privacy.value,
        'selectedContactIds': selectedContactIds ?? [],
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final status = StatusModel.fromMap(data['status'] ?? data, data['id']);
        await _dbService.upsertStatus(status);
        _statusUpdateController.add(status);
        return status;
      }

      throw StatusRepositoryException('Failed to create image status');
    } catch (e) {
      debugPrint('❌ Error creating image status: $e');
      throw StatusRepositoryException('Failed to create image status', originalError: e);
    }
  }

  @override
  Future<StatusModel> createVideoStatus({
    required File videoFile,
    String? caption,
    StatusPrivacy privacy = StatusPrivacy.everyone,
    List<String>? selectedContactIds,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StatusRepositoryException('User not authenticated');

      // Upload video first
      final videoUrl = await uploadStatusMedia(file: videoFile, type: 'video');

      // Create status via API
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final response = await _httpClient.post('/statuses', body: {
        'userId': user.uid,
        'userName': user.displayName ?? 'User',
        'userImage': user.photoURL ?? '',
        'type': 'video',
        'mediaUrl': videoUrl,
        'caption': caption,
        'privacy': privacy.value,
        'selectedContactIds': selectedContactIds ?? [],
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final status = StatusModel.fromMap(data['status'] ?? data, data['id']);
        await _dbService.upsertStatus(status);
        _statusUpdateController.add(status);
        return status;
      }

      throw StatusRepositoryException('Failed to create video status');
    } catch (e) {
      debugPrint('❌ Error creating video status: $e');
      throw StatusRepositoryException('Failed to create video status', originalError: e);
    }
  }

  @override
  Future<StatusModel> createTextStatus({
    required String text,
    required String backgroundColor,
    required String textColor,
    StatusPrivacy privacy = StatusPrivacy.everyone,
    List<String>? selectedContactIds,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StatusRepositoryException('User not authenticated');

      // Create text status via API
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final response = await _httpClient.post('/statuses', body: {
        'userId': user.uid,
        'userName': user.displayName ?? 'User',
        'userImage': user.photoURL ?? '',
        'type': 'text',
        'textContent': text,
        'backgroundColor': backgroundColor,
        'textColor': textColor,
        'privacy': privacy.value,
        'selectedContactIds': selectedContactIds ?? [],
        'createdAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final status = StatusModel.fromMap(data['status'] ?? data, data['id']);
        await _dbService.upsertStatus(status);
        _statusUpdateController.add(status);
        return status;
      }

      throw StatusRepositoryException('Failed to create text status');
    } catch (e) {
      debugPrint('❌ Error creating text status: $e');
      throw StatusRepositoryException('Failed to create text status', originalError: e);
    }
  }

  @override
  Future<void> deleteStatus(String statusId) async {
    try {
      await _dbService.deleteStatus(statusId);

      // Notify server
      await _httpClient.delete('/statuses/$statusId');
    } catch (e) {
      debugPrint('❌ Error deleting status: $e');
      throw StatusRepositoryException('Failed to delete status', originalError: e);
    }
  }

  @override
  Future<void> incrementViewCount(String statusId) async {
    try {
      // Update local DB
      await _dbService.incrementViewCount(statusId);

      // Notify server
      await _httpClient.post('/statuses/$statusId/view', body: {});
    } catch (e) {
      debugPrint('❌ Error incrementing view count: $e');
      throw StatusRepositoryException('Failed to increment view count', originalError: e);
    }
  }

  @override
  Future<bool> hasViewedStatus(String statusId) async {
    try {
      return await _dbService.hasViewed(statusId);
    } catch (e) {
      debugPrint('❌ Error checking viewed status: $e');
      return false;
    }
  }

  @override
  Future<void> markStatusAsViewed(String statusId) async {
    try {
      await _dbService.markAsViewed(statusId);
      await incrementViewCount(statusId);
    } catch (e) {
      debugPrint('❌ Error marking status as viewed: $e');
      throw StatusRepositoryException('Failed to mark status as viewed', originalError: e);
    }
  }

  @override
  Future<List<StatusModel>> getUnviewedStatuses() async {
    try {
      return await _dbService.getUnviewedStatuses();
    } catch (e) {
      debugPrint('❌ Error getting unviewed statuses: $e');
      throw StatusRepositoryException('Failed to get unviewed statuses', originalError: e);
    }
  }

  @override
  Stream<StatusModel> watchStatuses() {
    return _statusUpdateController.stream;
  }

  @override
  Stream<List<StatusModel>> watchUserStatuses(String userId) {
    return _userStatusesController.stream;
  }

  // ===============================
  // PRIVACY OPERATIONS
  // ===============================

  @override
  Future<void> updateStatusPrivacy({
    required String statusId,
    required StatusPrivacy privacy,
    List<String>? selectedContactIds,
  }) async {
    try {
      final response = await _httpClient.put('/statuses/$statusId/privacy', body: {
        'privacy': privacy.value,
        'selectedContactIds': selectedContactIds ?? [],
      });

      if (response.statusCode == 200) {
        // Update local cache
        final status = await _dbService.getStatusById(statusId);
        if (status != null) {
          final updatedStatus = status.copyWith(
            privacy: privacy,
            selectedContactIds: selectedContactIds ?? [],
          );
          await _dbService.upsertStatus(updatedStatus);
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating status privacy: $e');
      throw StatusRepositoryException('Failed to update status privacy', originalError: e);
    }
  }

  @override
  Future<List<String>> getStatusViewers(String statusId) async {
    try {
      final response = await _httpClient.get('/statuses/$statusId/viewers');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['viewers'] as List).cast<String>();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting status viewers: $e');
      throw StatusRepositoryException('Failed to get status viewers', originalError: e);
    }
  }

  @override
  Future<bool> canViewStatus(String statusId, String userId) async {
    try {
      final status = await getStatusById(statusId);
      if (status == null) return false;

      // Check privacy settings
      switch (status.privacy) {
        case StatusPrivacy.everyone:
          return true;
        case StatusPrivacy.contactsOnly:
          // Would need to check if user is a contact
          return true; // Simplified - implement contact check
        case StatusPrivacy.selectedContacts:
          return status.selectedContactIds.contains(userId);
        case StatusPrivacy.exceptContacts:
          return !status.selectedContactIds.contains(userId);
      }
    } catch (e) {
      debugPrint('❌ Error checking view permission: $e');
      return false;
    }
  }

  // ===============================
  // MUTE OPERATIONS
  // ===============================

  @override
  Future<void> muteUserStatus(String userId) async {
    try {
      await _dbService.muteUser(userId);

      // Notify server
      await _httpClient.post('/statuses/mute/$userId', body: {});
    } catch (e) {
      debugPrint('❌ Error muting user status: $e');
      throw StatusRepositoryException('Failed to mute user status', originalError: e);
    }
  }

  @override
  Future<void> unmuteUserStatus(String userId) async {
    try {
      await _dbService.unmuteUser(userId);

      // Notify server
      await _httpClient.delete('/statuses/mute/$userId');
    } catch (e) {
      debugPrint('❌ Error unmuting user status: $e');
      throw StatusRepositoryException('Failed to unmute user status', originalError: e);
    }
  }

  @override
  Future<bool> isUserStatusMuted(String userId) async {
    try {
      return await _dbService.isUserMuted(userId);
    } catch (e) {
      debugPrint('❌ Error checking muted status: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getMutedUsers() async {
    try {
      return await _dbService.getMutedUsers();
    } catch (e) {
      debugPrint('❌ Error getting muted users: $e');
      throw StatusRepositoryException('Failed to get muted users', originalError: e);
    }
  }

  // ===============================
  // MEDIA OPERATIONS
  // ===============================

  @override
  Future<String> uploadStatusMedia({
    required File file,
    required String type,
    Function(double progress)? onProgress,
  }) async {
    try {
      final response = await _httpClient.uploadFile(
        '/upload',
        file,
        'file',
        additionalFields: {'type': type},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }

      throw StatusRepositoryException('Failed to upload status media');
    } catch (e) {
      debugPrint('❌ Error uploading status media: $e');
      throw StatusRepositoryException('Failed to upload status media', originalError: e);
    }
  }

  @override
  Future<String> downloadStatusMedia({
    required String url,
    required String fileName,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Implementation for downloading media files
      throw UnimplementedError('Download status media not implemented yet');
    } catch (e) {
      debugPrint('❌ Error downloading status media: $e');
      throw StatusRepositoryException('Failed to download status media', originalError: e);
    }
  }

  // ===============================
  // SYNC OPERATIONS
  // ===============================

  @override
  Future<void> syncWithServer() async {
    try {
      debugPrint('🔄 Starting status sync with server...');

      // Delete expired statuses first
      await deleteExpiredStatuses();

      // Fetch fresh statuses from server
      await _syncStatusesInBackground();

      debugPrint('✅ Status sync completed');
    } catch (e) {
      debugPrint('❌ Error syncing with server: $e');
      throw StatusRepositoryException('Failed to sync with server', originalError: e);
    }
  }

  @override
  Future<List<StatusModel>> refreshStatuses() async {
    try {
      final response = await _httpClient.get('/statuses');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final statuses = (data['statuses'] as List)
            .map((s) => StatusModel.fromMap(s, s['id']))
            .toList();

        // Update local DB
        await _dbService.batchInsertStatuses(statuses);
        return statuses;
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error refreshing statuses: $e');
      throw StatusRepositoryException('Failed to refresh statuses', originalError: e);
    }
  }

  @override
  Future<void> deleteExpiredStatuses() async {
    try {
      final count = await _dbService.deleteExpiredStatuses();
      debugPrint('🗑️ Deleted $count expired statuses');
    } catch (e) {
      debugPrint('❌ Error deleting expired statuses: $e');
      throw StatusRepositoryException('Failed to delete expired statuses', originalError: e);
    }
  }

  // ===============================
  // CACHE OPERATIONS
  // ===============================

  @override
  Future<void> clearCache() async {
    try {
      await _dbService.clearAllData();
      debugPrint('✅ Status cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
      throw StatusRepositoryException('Failed to clear cache', originalError: e);
    }
  }

  @override
  Future<void> clearUserCache(String userId) async {
    try {
      await _dbService.clearUserCache(userId);
      debugPrint('✅ User status cache cleared: $userId');
    } catch (e) {
      debugPrint('❌ Error clearing user cache: $e');
      throw StatusRepositoryException('Failed to clear user cache', originalError: e);
    }
  }

  @override
  Future<int> getCacheSize() async {
    try {
      return await _dbService.getDatabaseSize();
    } catch (e) {
      debugPrint('❌ Error getting cache size: $e');
      throw StatusRepositoryException('Failed to get cache size', originalError: e);
    }
  }

  // ===============================
  // USER INFO OPERATIONS
  // ===============================

  @override
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<bool> hasActiveStatuses(String userId) async {
    try {
      return await _dbService.hasActiveStatuses(userId);
    } catch (e) {
      debugPrint('❌ Error checking active statuses: $e');
      return false;
    }
  }

  @override
  Future<int> getActiveStatusCount(String userId) async {
    try {
      return await _dbService.getActiveStatusCount(userId);
    } catch (e) {
      debugPrint('❌ Error getting active status count: $e');
      throw StatusRepositoryException('Failed to get active status count', originalError: e);
    }
  }

  @override
  Future<List<String>> getUsersWithActiveStatuses() async {
    try {
      return await _dbService.getUsersWithActiveStatuses();
    } catch (e) {
      debugPrint('❌ Error getting users with active statuses: $e');
      throw StatusRepositoryException('Failed to get users with active statuses', originalError: e);
    }
  }

  // ===============================
  // STATISTICS
  // ===============================

  @override
  Future<int> getTotalViewCount(String userId) async {
    try {
      return await _dbService.getTotalViewCount(userId);
    } catch (e) {
      debugPrint('❌ Error getting total view count: $e');
      throw StatusRepositoryException('Failed to get total view count', originalError: e);
    }
  }

  @override
  Future<int> getStatusViewCount(String statusId) async {
    try {
      final status = await getStatusById(statusId);
      return status?.viewsCount ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting status view count: $e');
      return 0;
    }
  }

  @override
  Future<StatusModel?> getMostViewedStatus(String userId) async {
    try {
      return await _dbService.getMostViewedStatus(userId);
    } catch (e) {
      debugPrint('❌ Error getting most viewed status: $e');
      throw StatusRepositoryException('Failed to get most viewed status', originalError: e);
    }
  }

  // ===============================
  // CLEANUP
  // ===============================

  Future<void> dispose() async {
    _cleanupTimer?.cancel();
    await _statusUpdateController.close();
    await _userStatusesController.close();
    await _dbService.close();
  }
}