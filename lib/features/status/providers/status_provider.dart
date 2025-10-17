// lib/features/status/providers/status_provider.dart
// Main status provider with state management
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/repositories/status_repository.dart';
import 'package:textgb/features/status/repositories/status_repository_impl.dart';

part 'status_provider.g.dart';

// ========================================
// STATUS STATE
// ========================================

class StatusState {
  final List<StatusModel> statuses;
  final List<StatusModel> myStatuses;
  final List<StatusModel> unviewedStatuses;
  final List<String> mutedUsers;
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final String? error;
  final DateTime? lastSync;
  
  const StatusState({
    this.statuses = const [],
    this.myStatuses = const [],
    this.unviewedStatuses = const [],
    this.mutedUsers = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.error,
    this.lastSync,
  });

  StatusState copyWith({
    List<StatusModel>? statuses,
    List<StatusModel>? myStatuses,
    List<StatusModel>? unviewedStatuses,
    List<String>? mutedUsers,
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    String? error,
    DateTime? lastSync,
  }) {
    return StatusState(
      statuses: statuses ?? this.statuses,
      myStatuses: myStatuses ?? this.myStatuses,
      unviewedStatuses: unviewedStatuses ?? this.unviewedStatuses,
      mutedUsers: mutedUsers ?? this.mutedUsers,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

// ========================================
// REPOSITORY PROVIDER
// ========================================

final statusRepositoryProvider = Provider<StatusRepository>((ref) {
  return StatusRepositoryImpl();
});

// ========================================
// MAIN STATUS PROVIDER
// ========================================

@riverpod
class Status extends _$Status {
  late StatusRepository _repository;
  
  @override
  FutureOr<StatusState> build() async {
    _repository = ref.read(statusRepositoryProvider);
    
    // Load statuses
    final statuses = await _repository.getStatuses();
    final myStatuses = await _repository.getMyStatuses();
    final unviewedStatuses = await _repository.getUnviewedStatuses();
    final mutedUsers = await _repository.getMutedUsers();
    
    // Auto-cleanup expired statuses on load
    await _repository.deleteExpiredStatuses();
    
    return StatusState(
      statuses: statuses,
      myStatuses: myStatuses,
      unviewedStatuses: unviewedStatuses,
      mutedUsers: mutedUsers,
      lastSync: DateTime.now(),
    );
  }

  // ===============================
  // STATUS OPERATIONS
  // ===============================

  Future<void> loadStatuses() async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      final statuses = await _repository.getStatuses();
      
      state = AsyncValue.data(state.value!.copyWith(
        statuses: statuses,
        isLoading: false,
        lastSync: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('❌ Error loading statuses: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadMyStatuses() async {
    if (!state.hasValue) return;
    
    try {
      final myStatuses = await _repository.getMyStatuses();
      
      state = AsyncValue.data(state.value!.copyWith(
        myStatuses: myStatuses,
      ));
    } catch (e) {
      debugPrint('❌ Error loading my statuses: $e');
    }
  }

  Future<void> loadUnviewedStatuses() async {
    if (!state.hasValue) return;
    
    try {
      final unviewedStatuses = await _repository.getUnviewedStatuses();
      
      state = AsyncValue.data(state.value!.copyWith(
        unviewedStatuses: unviewedStatuses,
      ));
    } catch (e) {
      debugPrint('❌ Error loading unviewed statuses: $e');
    }
  }

  Future<void> refreshStatuses() async {
    if (!state.hasValue) return;
    
    try {
      await _repository.syncWithServer();
      await loadStatuses();
      await loadMyStatuses();
      await loadUnviewedStatuses();
    } catch (e) {
      debugPrint('❌ Error refreshing statuses: $e');
    }
  }

  Future<StatusModel?> getStatusById(String statusId) async {
    try {
      return await _repository.getStatusById(statusId);
    } catch (e) {
      debugPrint('❌ Error getting status: $e');
      return null;
    }
  }

  Future<List<StatusModel>> getUserStatuses(String userId) async {
    try {
      return await _repository.getUserStatuses(userId);
    } catch (e) {
      debugPrint('❌ Error getting user statuses: $e');
      return [];
    }
  }

  // ===============================
  // CREATE STATUS OPERATIONS
  // ===============================

  Future<StatusModel?> createImageStatus({
    required File imageFile,
    String? caption,
    StatusPrivacy privacy = StatusPrivacy.everyone,
    List<String>? selectedContactIds,
  }) async {
    if (!state.hasValue) return null;
    
    state = AsyncValue.data(state.value!.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
    ));

    try {
      final status = await _repository.createImageStatus(
        imageFile: imageFile,
        caption: caption,
        privacy: privacy,
        selectedContactIds: selectedContactIds,
      );
      
      // Add to statuses lists
      final updatedStatuses = List<StatusModel>.from(state.value!.statuses);
      updatedStatuses.insert(0, status);
      
      final updatedMyStatuses = List<StatusModel>.from(state.value!.myStatuses);
      updatedMyStatuses.insert(0, status);
      
      state = AsyncValue.data(state.value!.copyWith(
        statuses: updatedStatuses,
        myStatuses: updatedMyStatuses,
        isUploading: false,
        uploadProgress: 1.0,
      ));
      
      return status;
    } catch (e) {
      debugPrint('❌ Error creating image status: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.toString(),
      ));
      return null;
    }
  }

  Future<StatusModel?> createVideoStatus({
    required File videoFile,
    String? caption,
    StatusPrivacy privacy = StatusPrivacy.everyone,
    List<String>? selectedContactIds,
  }) async {
    if (!state.hasValue) return null;
    
    state = AsyncValue.data(state.value!.copyWith(
      isUploading: true,
      uploadProgress: 0.0,
    ));

    try {
      final status = await _repository.createVideoStatus(
        videoFile: videoFile,
        caption: caption,
        privacy: privacy,
        selectedContactIds: selectedContactIds,
      );
      
      // Add to statuses lists
      final updatedStatuses = List<StatusModel>.from(state.value!.statuses);
      updatedStatuses.insert(0, status);
      
      final updatedMyStatuses = List<StatusModel>.from(state.value!.myStatuses);
      updatedMyStatuses.insert(0, status);
      
      state = AsyncValue.data(state.value!.copyWith(
        statuses: updatedStatuses,
        myStatuses: updatedMyStatuses,
        isUploading: false,
        uploadProgress: 1.0,
      ));
      
      return status;
    } catch (e) {
      debugPrint('❌ Error creating video status: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: e.toString(),
      ));
      return null;
    }
  }

  Future<StatusModel?> createTextStatus({
    required String text,
    required String backgroundColor,
    required String textColor,
    StatusPrivacy privacy = StatusPrivacy.everyone,
    List<String>? selectedContactIds,
  }) async {
    if (!state.hasValue) return null;
    
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final status = await _repository.createTextStatus(
        text: text,
        backgroundColor: backgroundColor,
        textColor: textColor,
        privacy: privacy,
        selectedContactIds: selectedContactIds,
      );
      
      // Add to statuses lists
      final updatedStatuses = List<StatusModel>.from(state.value!.statuses);
      updatedStatuses.insert(0, status);
      
      final updatedMyStatuses = List<StatusModel>.from(state.value!.myStatuses);
      updatedMyStatuses.insert(0, status);
      
      state = AsyncValue.data(state.value!.copyWith(
        statuses: updatedStatuses,
        myStatuses: updatedMyStatuses,
        isLoading: false,
      ));
      
      return status;
    } catch (e) {
      debugPrint('❌ Error creating text status: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      return null;
    }
  }

  // ===============================
  // DELETE STATUS OPERATIONS
  // ===============================

  Future<void> deleteStatus(String statusId) async {
    if (!state.hasValue) return;
    
    try {
      await _repository.deleteStatus(statusId);
      
      // Remove from all lists
      final updatedStatuses = state.value!.statuses
          .where((s) => s.id != statusId)
          .toList();
      
      final updatedMyStatuses = state.value!.myStatuses
          .where((s) => s.id != statusId)
          .toList();
      
      final updatedUnviewed = state.value!.unviewedStatuses
          .where((s) => s.id != statusId)
          .toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        statuses: updatedStatuses,
        myStatuses: updatedMyStatuses,
        unviewedStatuses: updatedUnviewed,
      ));
    } catch (e) {
      debugPrint('❌ Error deleting status: $e');
    }
  }

  // ===============================
  // VIEW STATUS OPERATIONS
  // ===============================

  Future<void> viewStatus(String statusId) async {
    if (!state.hasValue) return;
    
    try {
      await _repository.markStatusAsViewed(statusId);
      
      // Remove from unviewed statuses
      final updatedUnviewed = state.value!.unviewedStatuses
          .where((s) => s.id != statusId)
          .toList();
      
      // Update view count in statuses list
      final updatedStatuses = state.value!.statuses.map((s) {
        if (s.id == statusId) {
          return s.copyWith(viewsCount: s.viewsCount + 1);
        }
        return s;
      }).toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        statuses: updatedStatuses,
        unviewedStatuses: updatedUnviewed,
      ));
    } catch (e) {
      debugPrint('❌ Error viewing status: $e');
    }
  }

  Future<bool> hasViewedStatus(String statusId) async {
    try {
      return await _repository.hasViewedStatus(statusId);
    } catch (e) {
      debugPrint('❌ Error checking viewed status: $e');
      return false;
    }
  }

  // ===============================
  // PRIVACY OPERATIONS
  // ===============================

  Future<void> updateStatusPrivacy({
    required String statusId,
    required StatusPrivacy privacy,
    List<String>? selectedContactIds,
  }) async {
    if (!state.hasValue) return;
    
    try {
      await _repository.updateStatusPrivacy(
        statusId: statusId,
        privacy: privacy,
        selectedContactIds: selectedContactIds,
      );
      
      // Update in all lists
      final updatedStatuses = state.value!.statuses.map((s) {
        if (s.id == statusId) {
          return s.copyWith(
            privacy: privacy,
            selectedContactIds: selectedContactIds ?? [],
          );
        }
        return s;
      }).toList();
      
      final updatedMyStatuses = state.value!.myStatuses.map((s) {
        if (s.id == statusId) {
          return s.copyWith(
            privacy: privacy,
            selectedContactIds: selectedContactIds ?? [],
          );
        }
        return s;
      }).toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        statuses: updatedStatuses,
        myStatuses: updatedMyStatuses,
      ));
    } catch (e) {
      debugPrint('❌ Error updating status privacy: $e');
    }
  }

  Future<bool> canViewStatus(String statusId, String userId) async {
    try {
      return await _repository.canViewStatus(statusId, userId);
    } catch (e) {
      debugPrint('❌ Error checking view permission: $e');
      return false;
    }
  }

  // ===============================
  // MUTE OPERATIONS
  // ===============================

  Future<void> muteUser(String userId) async {
    if (!state.hasValue) return;
    
    try {
      await _repository.muteUserStatus(userId);
      
      // Add to muted users list
      final updatedMuted = List<String>.from(state.value!.mutedUsers);
      if (!updatedMuted.contains(userId)) {
        updatedMuted.add(userId);
      }
      
      // Remove this user's statuses from main list
      final updatedStatuses = state.value!.statuses
          .where((s) => s.userId != userId)
          .toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        mutedUsers: updatedMuted,
        statuses: updatedStatuses,
      ));
    } catch (e) {
      debugPrint('❌ Error muting user: $e');
    }
  }

  Future<void> unmuteUser(String userId) async {
    if (!state.hasValue) return;
    
    try {
      await _repository.unmuteUserStatus(userId);
      
      // Remove from muted users list
      final updatedMuted = state.value!.mutedUsers
          .where((id) => id != userId)
          .toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        mutedUsers: updatedMuted,
      ));
      
      // Reload statuses to show this user's statuses again
      await loadStatuses();
    } catch (e) {
      debugPrint('❌ Error unmuting user: $e');
    }
  }

  Future<bool> isUserMuted(String userId) async {
    try {
      return await _repository.isUserStatusMuted(userId);
    } catch (e) {
      debugPrint('❌ Error checking muted status: $e');
      return false;
    }
  }

  // ===============================
  // STATISTICS OPERATIONS
  // ===============================

  Future<int> getTotalViewCount(String userId) async {
    try {
      return await _repository.getTotalViewCount(userId);
    } catch (e) {
      debugPrint('❌ Error getting total view count: $e');
      return 0;
    }
  }

  Future<int> getStatusViewCount(String statusId) async {
    try {
      return await _repository.getStatusViewCount(statusId);
    } catch (e) {
      debugPrint('❌ Error getting status view count: $e');
      return 0;
    }
  }

  Future<StatusModel?> getMostViewedStatus(String userId) async {
    try {
      return await _repository.getMostViewedStatus(userId);
    } catch (e) {
      debugPrint('❌ Error getting most viewed status: $e');
      return null;
    }
  }

  Future<bool> hasActiveStatuses(String userId) async {
    try {
      return await _repository.hasActiveStatuses(userId);
    } catch (e) {
      debugPrint('❌ Error checking active statuses: $e');
      return false;
    }
  }

  Future<int> getActiveStatusCount(String userId) async {
    try {
      return await _repository.getActiveStatusCount(userId);
    } catch (e) {
      debugPrint('❌ Error getting active status count: $e');
      return 0;
    }
  }

  Future<List<String>> getUsersWithActiveStatuses() async {
    try {
      return await _repository.getUsersWithActiveStatuses();
    } catch (e) {
      debugPrint('❌ Error getting users with active statuses: $e');
      return [];
    }
  }

  // ===============================
  // CLEANUP OPERATIONS
  // ===============================

  Future<void> deleteExpiredStatuses() async {
    try {
      await _repository.deleteExpiredStatuses();
      
      // Reload statuses after cleanup
      await loadStatuses();
      await loadMyStatuses();
    } catch (e) {
      debugPrint('❌ Error deleting expired statuses: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      await _repository.clearCache();
      
      // Reset state
      state = AsyncValue.data(const StatusState());
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }

  // ===============================
  // CLEANUP
  // ===============================

  Future<void> dispose() async {
    // Nothing to dispose for now
  }
}