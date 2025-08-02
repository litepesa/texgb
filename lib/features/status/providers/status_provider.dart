// lib/features/status/providers/status_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/repositories/status_repository.dart';
import 'package:textgb/models/user_model.dart';

part 'status_provider.g.dart';

// Status state for managing UI state
class StatusState {
  final bool isLoading;
  final bool isCreatingStatus;
  final bool isUploadingMedia;
  final String? error;
  final List<UserStatusGroup> contactsStatuses;
  final List<StatusModel> myStatuses;
  final StatusModel? currentViewingStatus;
  final int currentStatusIndex;
  final bool isViewingMyStatus;

  const StatusState({
    this.isLoading = false,
    this.isCreatingStatus = false,
    this.isUploadingMedia = false,
    this.error,
    this.contactsStatuses = const [],
    this.myStatuses = const [],
    this.currentViewingStatus,
    this.currentStatusIndex = 0,
    this.isViewingMyStatus = false,
  });

  StatusState copyWith({
    bool? isLoading,
    bool? isCreatingStatus,
    bool? isUploadingMedia,
    String? error,
    List<UserStatusGroup>? contactsStatuses,
    List<StatusModel>? myStatuses,
    StatusModel? currentViewingStatus,
    int? currentStatusIndex,
    bool? isViewingMyStatus,
  }) {
    return StatusState(
      isLoading: isLoading ?? this.isLoading,
      isCreatingStatus: isCreatingStatus ?? this.isCreatingStatus,
      isUploadingMedia: isUploadingMedia ?? this.isUploadingMedia,
      error: error,
      contactsStatuses: contactsStatuses ?? this.contactsStatuses,
      myStatuses: myStatuses ?? this.myStatuses,
      currentViewingStatus: currentViewingStatus ?? this.currentViewingStatus,
      currentStatusIndex: currentStatusIndex ?? this.currentStatusIndex,
      isViewingMyStatus: isViewingMyStatus ?? this.isViewingMyStatus,
    );
  }

  // Helper getters
  bool get hasMyStatuses => myStatuses.isNotEmpty;
  bool get hasContactsStatuses => contactsStatuses.isNotEmpty;
  int get totalUnviewedStatuses => contactsStatuses
      .fold(0, (sum, group) => sum + group.unviewedCount);
}

@riverpod
class StatusNotifier extends _$StatusNotifier {
  late StatusRepository _repository;

  @override
  FutureOr<StatusState> build() async {
    _repository = ref.read(statusRepositoryProvider);
    
    // Start listening to status updates
    _listenToStatusUpdates();
    
    return const StatusState();
  }

  // Listen to real-time status updates
  void _listenToStatusUpdates() {
    ref.listen(authenticationProvider, (previous, next) {
      next.when(
        data: (authState) {
          if (authState.userModel != null) {
            _startStatusStreams(authState.userModel!);
          }
        },
        loading: () {},
        error: (error, stack) {},
      );
    });
  }

  // Start status streams
  void _startStatusStreams(UserModel user) {
    // Listen to contacts statuses
    final contactsState = ref.read(contactsNotifierProvider);
    contactsState.when(
      data: (contacts) {
        final contactIds = contacts.registeredContacts.map((c) => c.uid).toList();
        
        _repository.getContactsStatuses(
          currentUserId: user.uid,
          contactIds: contactIds,
        ).listen((statusGroups) {
          if (state.hasValue) {
            state = AsyncValue.data(
              state.value!.copyWith(contactsStatuses: statusGroups),
            );
          }
        });
      },
      loading: () {},
      error: (error, stack) {},
    );

    // Listen to my statuses
    _repository.getMyStatuses(user.uid).listen((myStatuses) {
      if (state.hasValue) {
        state = AsyncValue.data(
          state.value!.copyWith(myStatuses: myStatuses),
        );
      }
    });
  }

  // Create text status
  Future<void> createTextStatus({
    required String content,
    String? backgroundColor,
    String? textColor,
    String? font,
    String privacyLevel = Constants.statusPrivacyContacts,
    List<String> allowedViewers = const [],
    List<String> excludedViewers = const [],
    int duration = Constants.statusDefaultDuration,
  }) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.copyWith(
      isCreatingStatus: true,
      error: null,
    ));

    try {
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      await _repository.createStatus(
        user: authState.userModel!,
        statusType: Constants.statusTypeText,
        content: content,
        backgroundColor: backgroundColor,
        textColor: textColor,
        font: font,
        privacyLevel: privacyLevel,
        allowedViewers: allowedViewers,
        excludedViewers: excludedViewers,
        duration: duration,
      );

      state = AsyncValue.data(state.value!.copyWith(
        isCreatingStatus: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isCreatingStatus: false,
        error: e.toString(),
      ));
    }
  }

  // Create media status (image/video)
  Future<void> createMediaStatus({
    required XFile mediaFile,
    required String statusType,
    String content = '',
    String privacyLevel = Constants.statusPrivacyContacts,
    List<String> allowedViewers = const [],
    List<String> excludedViewers = const [],
    int duration = Constants.statusDefaultDuration,
  }) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.copyWith(
      isCreatingStatus: true,
      isUploadingMedia: true,
      error: null,
    ));

    try {
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel == null) {
        throw Exception('User not authenticated');
      }

      await _repository.createStatus(
        user: authState.userModel!,
        statusType: statusType,
        content: content,
        mediaFile: mediaFile,
        privacyLevel: privacyLevel,
        allowedViewers: allowedViewers,
        excludedViewers: excludedViewers,
        duration: duration,
      );

      state = AsyncValue.data(state.value!.copyWith(
        isCreatingStatus: false,
        isUploadingMedia: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isCreatingStatus: false,
        isUploadingMedia: false,
        error: e.toString(),
      ));
    }
  }

  // View status
  Future<void> viewStatus(StatusModel status, {bool isMyStatus = false}) async {
    if (!state.hasValue) return;

    try {
      // Mark as viewed if not my status and not already viewed
      final authState = await ref.read(authenticationProvider.future);
      if (authState.userModel != null && 
          !isMyStatus && 
          !status.hasUserViewed(authState.userModel!.uid)) {
        await _repository.markStatusAsViewed(
          statusId: status.statusId,
          viewerId: authState.userModel!.uid,
        );
      }

      state = AsyncValue.data(state.value!.copyWith(
        currentViewingStatus: status,
        isViewingMyStatus: isMyStatus,
      ));
    } catch (e) {
      debugPrint('Error viewing status: $e');
    }
  }

  // Clear current viewing status
  void clearCurrentStatus() {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.copyWith(
      currentViewingStatus: null,
      currentStatusIndex: 0,
      isViewingMyStatus: false,
    ));
  }

  // Delete status
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
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Update status privacy
  Future<void> updateStatusPrivacy({
    required String statusId,
    required String privacyLevel,
    List<String> allowedViewers = const [],
    List<String> excludedViewers = const [],
  }) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await _repository.updateStatusPrivacy(
        statusId: statusId,
        privacyLevel: privacyLevel,
        allowedViewers: allowedViewers,
        excludedViewers: excludedViewers,
      );

      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Get status viewers
  Future<List<String>> getStatusViewers(String statusId) async {
    try {
      return await _repository.getStatusViewers(statusId);
    } catch (e) {
      debugPrint('Error getting status viewers: $e');
      return [];
    }
  }

  // Navigate to next status in group
  void nextStatus(List<StatusModel> statusGroup) {
    if (!state.hasValue) return;

    final currentIndex = state.value!.currentStatusIndex;
    if (currentIndex < statusGroup.length - 1) {
      final nextStatus = statusGroup[currentIndex + 1];
      state = AsyncValue.data(state.value!.copyWith(
        currentViewingStatus: nextStatus,
        currentStatusIndex: currentIndex + 1,
      ));
    }
  }

  // Navigate to previous status in group
  void previousStatus(List<StatusModel> statusGroup) {
    if (!state.hasValue) return;

    final currentIndex = state.value!.currentStatusIndex;
    if (currentIndex > 0) {
      final previousStatus = statusGroup[currentIndex - 1];
      state = AsyncValue.data(state.value!.copyWith(
        currentViewingStatus: previousStatus,
        currentStatusIndex: currentIndex - 1,
      ));
    }
  }

  // Set current status index
  void setCurrentStatusIndex(int index) {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.copyWith(
      currentStatusIndex: index,
    ));
  }

  // Clear error
  void clearError() {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.copyWith(error: null));
  }

  // Refresh statuses
  Future<void> refreshStatuses() async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      // Trigger repository cleanup
      await _repository.cleanupExpiredStatuses();

      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Get user status group by uid
  UserStatusGroup? getUserStatusGroup(String uid) {
    if (!state.hasValue) return null;

    try {
      return state.value!.contactsStatuses
          .firstWhere((group) => group.uid == uid);
    } catch (e) {
      return null;
    }
  }

  // Check if user has unviewed statuses
  bool hasUnviewedStatusesFromUser(String uid) {
    final group = getUserStatusGroup(uid);
    if (group == null) return false;

    final authState = ref.read(authenticationProvider).valueOrNull;
    if (authState?.userModel == null) return false;

    return group.hasUnviewedStatusForUser(authState!.userModel!.uid);
  }

  // Get unviewed status count from user
  int getUnviewedStatusCount(String uid) {
    final group = getUserStatusGroup(uid);
    if (group == null) return 0;

    final authState = ref.read(authenticationProvider).valueOrNull;
    if (authState?.userModel == null) return 0;

    return group.getUnviewedCountForUser(authState!.userModel!.uid);
  }
}

// Stream provider for contacts statuses
@riverpod
Stream<List<UserStatusGroup>> contactsStatusesStream(ContactsStatusesStreamRef ref) async* {
  final authState = await ref.watch(authenticationProvider.future);
  final contactsState = await ref.watch(contactsNotifierProvider.future);
  
  if (authState.userModel == null) {
    yield [];
    return;
  }

  final contactIds = contactsState.registeredContacts.map((c) => c.uid).toList();
  final repository = ref.read(statusRepositoryProvider);

  yield* repository.getContactsStatuses(
    currentUserId: authState.userModel!.uid,
    contactIds: contactIds,
  );
}

// Stream provider for my statuses
@riverpod
Stream<List<StatusModel>> myStatusesStream(MyStatusesStreamRef ref) async* {
  final authState = await ref.watch(authenticationProvider.future);
  
  if (authState.userModel == null) {
    yield [];
    return;
  }

  final repository = ref.read(statusRepositoryProvider);
  yield* repository.getMyStatuses(authState.userModel!.uid);
}

// Provider for single status
@riverpod
Future<StatusModel?> singleStatus(SingleStatusRef ref, String statusId) async {
  final repository = ref.read(statusRepositoryProvider);
  return repository.getStatus(statusId);
}