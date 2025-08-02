// lib/features/status/providers/status_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/repositories/status_repository.dart';
import 'package:textgb/models/user_model.dart';

part 'status_provider.g.dart';

class StatusState {
  final bool isLoading;
  final bool isSuccessful;
  final String? error;
  final List<UserStatusGroup> statusGroups;
  final Map<String, dynamic> privacySettings;
  final bool isCreating;
  final bool isViewing;
  final int? currentViewingIndex;
  final String? currentViewingUserId;

  const StatusState({
    this.isLoading = false,
    this.isSuccessful = false,
    this.error,
    this.statusGroups = const [],
    this.privacySettings = const {},
    this.isCreating = false,
    this.isViewing = false,
    this.currentViewingIndex,
    this.currentViewingUserId,
  });

  StatusState copyWith({
    bool? isLoading,
    bool? isSuccessful,
    String? error,
    List<UserStatusGroup>? statusGroups,
    Map<String, dynamic>? privacySettings,
    bool? isCreating,
    bool? isViewing,
    int? currentViewingIndex,
    String? currentViewingUserId,
  }) {
    return StatusState(
      isLoading: isLoading ?? this.isLoading,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      error: error,
      statusGroups: statusGroups ?? this.statusGroups,
      privacySettings: privacySettings ?? this.privacySettings,
      isCreating: isCreating ?? this.isCreating,
      isViewing: isViewing ?? this.isViewing,
      currentViewingIndex: currentViewingIndex ?? this.currentViewingIndex,
      currentViewingUserId: currentViewingUserId ?? this.currentViewingUserId,
    );
  }

  // Helper getters
  UserStatusGroup? get myStatusGroup {
    return statusGroups.where((group) => group.isMyStatus).firstOrNull;
  }

  List<UserStatusGroup> get otherStatusGroups {
    return statusGroups.where((group) => !group.isMyStatus).toList();
  }

  List<UserStatusGroup> get recentUpdates {
    return otherStatusGroups.where((group) => 
      group.hasUnviewedStatuses(currentViewingUserId ?? '')
    ).toList();
  }

  List<UserStatusGroup> get viewedUpdates {
    return otherStatusGroups.where((group) => 
      !group.hasUnviewedStatuses(currentViewingUserId ?? '')
    ).toList();
  }
}

@riverpod
class StatusNotifier extends _$StatusNotifier {
  StatusRepository get _repository => ref.read(statusRepositoryProvider);

  @override
  FutureOr<StatusState> build() async {
    try {
      // Load initial privacy settings
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        return const StatusState();
      }

      final privacySettings = await _repository.getStatusPrivacySettings(
        authState.userModel!.uid
      );

      return StatusState(
        privacySettings: privacySettings,
        isSuccessful: true,
      );
    } catch (e) {
      return StatusState(error: e.toString());
    }
  }

  // Create a new status
  Future<String?> createStatus({
    required StatusType type,
    required String content,
    String? caption,
    String? backgroundColor,
    String? fontColor,
    String? fontFamily,
    StatusPrivacyType? privacyType,
    List<String>? allowedViewers,
    List<String>? excludedViewers,
    File? mediaFile,
    String? musicUrl,
    String? musicTitle,
    String? musicArtist,
    Duration? musicDuration,
  }) async {
    if (!state.hasValue) return null;

    state = AsyncValue.data(state.value!.copyWith(
      isCreating: true,
      error: null,
    ));

    try {
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      final currentState = state.value!;
      final user = authState.userModel!;

      // Use privacy settings or defaults
      final finalPrivacyType = privacyType ?? 
          StatusPrivacyTypeExtension.fromString(
            currentState.privacySettings['defaultPrivacy'] ?? 'all_contacts'
          );

      final finalAllowedViewers = allowedViewers ?? 
          List<String>.from(currentState.privacySettings['allowedViewers'] ?? []);
      
      final finalExcludedViewers = excludedViewers ?? 
          List<String>.from(currentState.privacySettings['excludedViewers'] ?? []);

      final statusId = await _repository.createStatus(
        userId: user.uid,
        userName: user.name,
        userImage: user.image,
        type: type,
        content: content,
        caption: caption,
        backgroundColor: backgroundColor,
        fontColor: fontColor,
        fontFamily: fontFamily,
        privacyType: finalPrivacyType,
        allowedViewers: finalAllowedViewers,
        excludedViewers: finalExcludedViewers,
        mediaFile: mediaFile,
        musicUrl: musicUrl,
        musicTitle: musicTitle,
        musicArtist: musicArtist,
        musicDuration: musicDuration,
      );

      state = AsyncValue.data(currentState.copyWith(
        isCreating: false,
        isSuccessful: true,
      ));

      return statusId;
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isCreating: false,
        error: e.toString(),
      ));
      debugPrint('Error creating status: $e');
      return null;
    }
  }

  // Delete a status
  Future<void> deleteStatus(String statusId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await _repository.deleteStatus(statusId);

      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        isSuccessful: true,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      debugPrint('Error deleting status: $e');
    }
  }

  // Mark status as viewed
  Future<void> markStatusAsViewed({
    required String statusId,
    required String viewerId,
  }) async {
    try {
      await _repository.markStatusAsViewed(
        statusId: statusId,
        viewerId: viewerId,
      );
    } catch (e) {
      debugPrint('Error marking status as viewed: $e');
    }
  }

  // Update privacy settings
  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      await _repository.updateStatusPrivacySettings(
        userId: authState.userModel!.uid,
        settings: settings,
      );

      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        privacySettings: settings,
        isSuccessful: true,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      debugPrint('Error updating privacy settings: $e');
    }
  }

  // Set viewing state
  void setViewingState({
    required bool isViewing,
    int? currentIndex,
    String? userId,
  }) {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isViewing: isViewing,
      currentViewingIndex: currentIndex,
      currentViewingUserId: userId,
    ));
  }

  // Get status viewers
  Future<List<UserModel>> getStatusViewers(String statusId) async {
    try {
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      return await _repository.getStatusViewers(
        statusId: statusId,
        userContacts: authState.userModel!.contactsUIDs,
      );
    } catch (e) {
      debugPrint('Error getting status viewers: $e');
      return [];
    }
  }

  // Clean up expired statuses
  Future<void> cleanupExpiredStatuses() async {
    try {
      await _repository.cleanupExpiredStatuses();
    } catch (e) {
      debugPrint('Error cleaning up statuses: $e');
    }
  }
}

// Stream provider for real-time status updates
@riverpod
Stream<List<UserStatusGroup>> statusStream(StatusStreamRef ref) async* {
  try {
    final authState = await ref.watch(authenticationProvider.future);
    if (authState.userModel == null) {
      yield [];
      return;
    }

    final repository = ref.read(statusRepositoryProvider);
    
    yield* repository.getStatusesStream(
      currentUserId: authState.userModel!.uid,
      userContacts: authState.userModel!.contactsUIDs,
    );
  } catch (e) {
    debugPrint('Error in status stream: $e');
    yield [];
  }
}

// Provider for specific user's statuses
@riverpod
Future<List<StatusModel>> userStatuses(UserStatusesRef ref, String userId) async {
  try {
    final repository = ref.read(statusRepositoryProvider);
    return await repository.getUserStatuses(userId);
  } catch (e) {
    debugPrint('Error getting user statuses: $e');
    return [];
  }
}

// Provider for status privacy settings
@riverpod
Future<Map<String, dynamic>> statusPrivacySettings(StatusPrivacySettingsRef ref) async {
  try {
    final authState = await ref.watch(authenticationProvider.future);
    if (authState.userModel == null) {
      return {};
    }

    final repository = ref.read(statusRepositoryProvider);
    return await repository.getStatusPrivacySettings(authState.userModel!.uid);
  } catch (e) {
    debugPrint('Error getting privacy settings: $e');
    return {};
  }
}