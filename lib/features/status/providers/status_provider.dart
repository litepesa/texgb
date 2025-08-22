// lib/features/status/providers/status_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/repositories/status_repository.dart';

part 'status_provider.g.dart';

// Status State
class StatusState {
  final bool isLoading;
  final List<StatusModel> contactsStatus;
  final StatusModel? myStatus;
  final String? error;
  final bool isCreatingStatus;

  const StatusState({
    this.isLoading = false,
    this.contactsStatus = const [],
    this.myStatus,
    this.error,
    this.isCreatingStatus = false,
  });

  StatusState copyWith({
    bool? isLoading,
    List<StatusModel>? contactsStatus,
    StatusModel? myStatus,
    String? error,
    bool? isCreatingStatus,
    bool clearError = false,
    bool clearMyStatus = false,
  }) {
    return StatusState(
      isLoading: isLoading ?? this.isLoading,
      contactsStatus: contactsStatus ?? this.contactsStatus,
      myStatus: clearMyStatus ? null : (myStatus ?? this.myStatus),
      error: clearError ? null : (error ?? this.error),
      isCreatingStatus: isCreatingStatus ?? this.isCreatingStatus,
    );
  }

  // Helper getters
  List<StatusModel> get unviewedStatus => contactsStatus.where((status) => status.hasUnviewedUpdates).toList();
  List<StatusModel> get viewedStatus => contactsStatus.where((status) => !status.hasUnviewedUpdates).toList();
  int get totalUnviewedCount => unviewedStatus.fold(0, (sum, status) => sum + status.unviewedUpdateCount);
}

@riverpod
class StatusNotifier extends _$StatusNotifier {
  StatusRepository get _repository => ref.read(statusRepositoryProvider);

  @override
  FutureOr<StatusState> build() async {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const StatusState(error: 'User not authenticated');
    }

    // Start listening to status updates
    _subscribeToStatusUpdates(currentUser.uid);
    
    return const StatusState(isLoading: true);
  }

  void _subscribeToStatusUpdates(String currentUserId) {
    // Listen to user's own status
    _repository.getUserStatus(currentUserId).listen(
      (myStatus) {
        final currentState = state.valueOrNull ?? const StatusState();
        state = AsyncValue.data(currentState.copyWith(
          myStatus: myStatus,
          clearError: true,
        ));
      },
      onError: (error) {
        final currentState = state.valueOrNull ?? const StatusState();
        state = AsyncValue.data(currentState.copyWith(
          error: 'Failed to load your status: $error',
        ));
      },
    );

    // Listen to contacts' status
    _subscribeToContactsStatus(currentUserId);
  }

  void _subscribeToContactsStatus(String currentUserId) async {
    try {
      // Get user's contacts
      final contactsState = await ref.read(contactsNotifierProvider.future);
      final contactIds = contactsState.registeredContacts.map((c) => c.uid).toList();

      if (contactIds.isEmpty) {
        final currentState = state.valueOrNull ?? const StatusState();
        state = AsyncValue.data(currentState.copyWith(
          contactsStatus: [],
          isLoading: false,
        ));
        return;
      }

      // Listen to filtered contacts status
      _repository.getFilteredContactsStatus(
        contactIds: contactIds,
        currentUserId: currentUserId,
      ).listen(
        (contactsStatus) {
          final currentState = state.valueOrNull ?? const StatusState();
          state = AsyncValue.data(currentState.copyWith(
            contactsStatus: contactsStatus,
            isLoading: false,
            clearError: true,
          ));
        },
        onError: (error) {
          final currentState = state.valueOrNull ?? const StatusState();
          state = AsyncValue.data(currentState.copyWith(
            error: 'Failed to load contacts status: $error',
            isLoading: false,
          ));
        },
      );
    } catch (e) {
      final currentState = state.valueOrNull ?? const StatusState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to load contacts: $e',
        isLoading: false,
      ));
    }
  }

  // Create text status
  Future<void> createTextStatus({
    required String content,
    Color? backgroundColor,
    String? fontFamily,
    StatusPrivacyType privacy = StatusPrivacyType.all_contacts,
    List<String> allowedViewers = const [],
    List<String> excludedViewers = const [],
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final currentState = state.valueOrNull ?? const StatusState();
    state = AsyncValue.data(currentState.copyWith(isCreatingStatus: true));

    try {
      final request = CreateStatusRequest(
        type: StatusType.text,
        content: content,
        backgroundColor: backgroundColor,
        fontFamily: fontFamily,
        privacy: privacy,
        allowedViewers: allowedViewers,
        excludedViewers: excludedViewers,
      );

      await _repository.createStatus(user: currentUser, request: request);

      state = AsyncValue.data(currentState.copyWith(
        isCreatingStatus: false,
        clearError: true,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isCreatingStatus: false,
        error: 'Failed to create status: $e',
      ));
    }
  }

  // Create image status
  Future<void> createImageStatus({
    required File imageFile,
    String content = '',
    StatusPrivacyType privacy = StatusPrivacyType.all_contacts,
    List<String> allowedViewers = const [],
    List<String> excludedViewers = const [],
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final currentState = state.valueOrNull ?? const StatusState();
    state = AsyncValue.data(currentState.copyWith(isCreatingStatus: true));

    try {
      final request = CreateStatusRequest(
        type: StatusType.image,
        content: content,
        mediaPath: imageFile.path,
        privacy: privacy,
        allowedViewers: allowedViewers,
        excludedViewers: excludedViewers,
      );

      await _repository.createStatus(user: currentUser, request: request);

      state = AsyncValue.data(currentState.copyWith(
        isCreatingStatus: false,
        clearError: true,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isCreatingStatus: false,
        error: 'Failed to create image status: $e',
      ));
    }
  }

  // Create video status
  Future<void> createVideoStatus({
    required File videoFile,
    String content = '',
    Duration? duration,
    StatusPrivacyType privacy = StatusPrivacyType.all_contacts,
    List<String> allowedViewers = const [],
    List<String> excludedViewers = const [],
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final currentState = state.valueOrNull ?? const StatusState();
    state = AsyncValue.data(currentState.copyWith(isCreatingStatus: true));

    try {
      final request = CreateStatusRequest(
        type: StatusType.video,
        content: content,
        mediaPath: videoFile.path,
        duration: duration,
        privacy: privacy,
        allowedViewers: allowedViewers,
        excludedViewers: excludedViewers,
      );

      await _repository.createStatus(user: currentUser, request: request);

      state = AsyncValue.data(currentState.copyWith(
        isCreatingStatus: false,
        clearError: true,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isCreatingStatus: false,
        error: 'Failed to create video status: $e',
      ));
    }
  }

  // View a status update
  Future<void> viewStatus({
    required String statusOwnerId,
    required String updateId,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _repository.viewStatus(
        statusOwnerId: statusOwnerId,
        updateId: updateId,
        viewer: currentUser,
      );
    } catch (e) {
      debugPrint('Error viewing status: $e');
      // Don't show error to user for view failures
    }
  }

  // Delete status update
  Future<void> deleteStatusUpdate(String updateId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _repository.deleteStatusUpdate(
        userId: currentUser.uid,
        updateId: updateId,
      );
    } catch (e) {
      final currentState = state.valueOrNull ?? const StatusState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to delete status: $e',
      ));
    }
  }

  // Get status views for a specific update
  Future<List<StatusView>> getStatusViews(String updateId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return [];

    try {
      return await _repository.getStatusViews(
        statusOwnerId: currentUser.uid,
        updateId: updateId,
      );
    } catch (e) {
      debugPrint('Error getting status views: $e');
      return [];
    }
  }

  // Update status privacy
  Future<void> updateStatusPrivacy({
    required StatusPrivacyType privacy,
    List<String> allowedViewers = const [],
    List<String> excludedViewers = const [],
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _repository.updateStatusPrivacy(
        userId: currentUser.uid,
        privacy: privacy,
        allowedViewers: allowedViewers,
        excludedViewers: excludedViewers,
      );
    } catch (e) {
      final currentState = state.valueOrNull ?? const StatusState();
      state = AsyncValue.data(currentState.copyWith(
        error: 'Failed to update privacy settings: $e',
      ));
    }
  }

  // Clean up expired status
  Future<void> cleanupExpiredStatus() async {
    try {
      await _repository.cleanupExpiredStatus();
    } catch (e) {
      debugPrint('Error cleaning up expired status: $e');
    }
  }

  // Clear error
  void clearError() {
    final currentState = state.valueOrNull;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(clearError: true));
    }
  }

  // Refresh status
  void refreshStatus() {
    ref.invalidateSelf();
  }

  // Helper methods
  StatusModel? getStatusByUserId(String userId) {
    final currentState = state.valueOrNull;
    if (currentState == null) return null;

    if (currentState.myStatus?.uid == userId) {
      return currentState.myStatus;
    }

    try {
      return currentState.contactsStatus.firstWhere((status) => status.uid == userId);
    } catch (e) {
      return null;
    }
  }

  bool hasUnviewedStatus() {
    final currentState = state.valueOrNull;
    return currentState?.unviewedStatus.isNotEmpty ?? false;
  }

  int getUnviewedStatusCount() {
    final currentState = state.valueOrNull;
    return currentState?.totalUnviewedCount ?? 0;
  }

  List<StatusModel> getRecentStatus() {
    final currentState = state.valueOrNull;
    if (currentState == null) return [];

    final now = DateTime.now();
    return currentState.contactsStatus
        .where((status) => now.difference(status.lastUpdated).inHours < 24)
        .toList();
  }

  List<StatusModel> getViewedStatus() {
    final currentState = state.valueOrNull;
    return currentState?.viewedStatus ?? [];
  }

  // Check if user can create status
  bool get canCreateStatus {
    final currentUser = ref.read(currentUserProvider);
    return currentUser != null;
  }

  // Get status creation state
  bool get isCreatingStatus {
    final currentState = state.valueOrNull;
    return currentState?.isCreatingStatus ?? false;
  }
}