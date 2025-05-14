import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/repositories/status_repository.dart';
import 'package:textgb/models/user_model.dart';

part 'status_provider.g.dart';

// State class for status management
class StatusState {
  final bool isLoading;
  final List<StatusModel> myStatuses;
  final List<UserStatusSummary> contactsStatuses;
  final StatusModel? currentViewingStatus;
  final int currentViewingIndex;
  final String? currentViewingUserId;
  final List<StatusModel> currentUserStatuses;
  final String? error;
  final StatusPrivacyType selectedPrivacyType;
  final List<UserModel> selectedContacts; // For privacy settings

  const StatusState({
    this.isLoading = false,
    this.myStatuses = const [],
    this.contactsStatuses = const [],
    this.currentViewingStatus,
    this.currentViewingIndex = 0,
    this.currentViewingUserId,
    this.currentUserStatuses = const [],
    this.error,
    this.selectedPrivacyType = StatusPrivacyType.all_contacts,
    this.selectedContacts = const [],
  });

  StatusState copyWith({
    bool? isLoading,
    List<StatusModel>? myStatuses,
    List<UserStatusSummary>? contactsStatuses,
    StatusModel? currentViewingStatus,
    int? currentViewingIndex,
    String? currentViewingUserId,
    List<StatusModel>? currentUserStatuses,
    String? error,
    StatusPrivacyType? selectedPrivacyType,
    List<UserModel>? selectedContacts,
  }) {
    return StatusState(
      isLoading: isLoading ?? this.isLoading,
      myStatuses: myStatuses ?? this.myStatuses,
      contactsStatuses: contactsStatuses ?? this.contactsStatuses,
      currentViewingStatus: currentViewingStatus ?? this.currentViewingStatus,
      currentViewingIndex: currentViewingIndex ?? this.currentViewingIndex,
      currentViewingUserId: currentViewingUserId ?? this.currentViewingUserId,
      currentUserStatuses: currentUserStatuses ?? this.currentUserStatuses,
      error: error,
      selectedPrivacyType: selectedPrivacyType ?? this.selectedPrivacyType,
      selectedContacts: selectedContacts ?? this.selectedContacts,
    );
  }
}

@riverpod
class StatusNotifier extends _$StatusNotifier {
  late StatusRepository _statusRepository;

  @override
  FutureOr<StatusState> build() {
    _statusRepository = ref.read(statusRepositoryProvider);
    
    // Initialize stream listeners for my statuses and contacts' statuses
    _initStatusListeners();
    
    return const StatusState();
  }

  void _initStatusListeners() {
    // Listen to my statuses stream
    ref.listen(myStatusesStreamProvider, (previous, next) {
      if (next.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(
          myStatuses: next.value!,
        ));
      }
    });
    
    // Listen to contacts' statuses stream
    ref.listen(contactsStatusesStreamProvider, (previous, next) {
      if (next.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(
          contactsStatuses: next.value!,
        ));
      }
    });
  }

  // Create a text status
  Future<void> createTextStatus({
    required String text,
    StatusPrivacyType privacyType = StatusPrivacyType.all_contacts,
    List<String> visibleTo = const [],
    List<String> hiddenFrom = const [],
  }) async {
    if (text.trim().isEmpty) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));
    
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      await _statusRepository.createTextStatus(
        currentUser: currentUser,
        text: text,
        privacyType: privacyType,
        visibleTo: visibleTo,
        hiddenFrom: hiddenFrom,
      );
      
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        selectedPrivacyType: StatusPrivacyType.all_contacts, // Reset privacy
        selectedContacts: [], // Reset selected contacts
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Create a media status (image or video)
  Future<void> createMediaStatus({
    required File mediaFile,
    required StatusType mediaType,
    String caption = '',
    StatusPrivacyType privacyType = StatusPrivacyType.all_contacts,
    List<String> visibleTo = const [],
    List<String> hiddenFrom = const [],
  }) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));
    
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      await _statusRepository.createMediaStatus(
        currentUser: currentUser,
        mediaFile: mediaFile,
        mediaType: mediaType,
        caption: caption,
        privacyType: privacyType,
        visibleTo: visibleTo,
        hiddenFrom: hiddenFrom,
      );
      
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        selectedPrivacyType: StatusPrivacyType.all_contacts, // Reset privacy
        selectedContacts: [], // Reset selected contacts
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // View a status and mark it as seen
  Future<void> viewStatus(UserStatusSummary userStatus, [int startIndex = 0]) async {
    if (userStatus.statuses.isEmpty) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      currentViewingUserId: userStatus.userId,
      currentUserStatuses: userStatus.statuses,
      currentViewingIndex: startIndex,
      currentViewingStatus: userStatus.statuses[startIndex],
    ));
    
    // Mark the status as viewed
    try {
      await _statusRepository.markStatusAsViewed(
        userStatus.statuses[startIndex].statusId,
      );
    } catch (e) {
      debugPrint('Error marking status as viewed: $e');
    }
  }

  // Move to next status in the current user's status list
  Future<bool> nextStatus() async {
    if (!state.hasValue) return false;
    
    final currentState = state.value!;
    if (currentState.currentUserStatuses.isEmpty) return false;
    
    final nextIndex = currentState.currentViewingIndex + 1;
    if (nextIndex >= currentState.currentUserStatuses.length) {
      // No more statuses for this user
      return false;
    }
    
    state = AsyncValue.data(currentState.copyWith(
      currentViewingIndex: nextIndex,
      currentViewingStatus: currentState.currentUserStatuses[nextIndex],
    ));
    
    // Mark the status as viewed
    try {
      await _statusRepository.markStatusAsViewed(
        currentState.currentUserStatuses[nextIndex].statusId,
      );
    } catch (e) {
      debugPrint('Error marking status as viewed: $e');
    }
    
    return true;
  }

  // Move to previous status in the current user's status list
  Future<bool> previousStatus() async {
    if (!state.hasValue) return false;
    
    final currentState = state.value!;
    if (currentState.currentUserStatuses.isEmpty) return false;
    
    final prevIndex = currentState.currentViewingIndex - 1;
    if (prevIndex < 0) {
      // Already at the first status
      return false;
    }
    
    state = AsyncValue.data(currentState.copyWith(
      currentViewingIndex: prevIndex,
      currentViewingStatus: currentState.currentUserStatuses[prevIndex],
    ));
    
    return true;
  }

  // Close the status viewer
  void closeStatusViewer() {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      currentViewingUserId: null,
      currentUserStatuses: [],
      currentViewingIndex: 0,
      currentViewingStatus: null,
    ));
  }

  // Delete a status
  Future<void> deleteStatus(String statusId) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));
    
    try {
      await _statusRepository.deleteStatus(statusId);
      
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

  // Set privacy settings for new status
  void setPrivacySettings({
    required StatusPrivacyType privacyType,
    List<UserModel> selectedContacts = const [],
  }) {
    state = AsyncValue.data(state.value!.copyWith(
      selectedPrivacyType: privacyType,
      selectedContacts: selectedContacts,
    ));
  }

  // Update privacy for an existing status
  Future<void> updateStatusPrivacy({
    required String statusId,
    required StatusPrivacyType privacyType,
    List<String>? visibleTo,
    List<String>? hiddenFrom,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));
    
    try {
      await _statusRepository.updateStatusPrivacy(
        statusId: statusId,
        privacyType: privacyType,
        visibleTo: visibleTo,
        hiddenFrom: hiddenFrom,
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
}

// Stream provider for current user's statuses
@riverpod
Stream<List<StatusModel>> myStatusesStream(MyStatusesStreamRef ref) {
  final repository = ref.watch(statusRepositoryProvider);
  return repository.getMyStatuses();
}

// Stream provider for contacts' statuses
@riverpod
Stream<List<UserStatusSummary>> contactsStatusesStream(ContactsStatusesStreamRef ref) {
  final repository = ref.watch(statusRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return Stream.value([]);
  }
  
  // Get muted users from user's settings
  final mutedUsers = currentUser.statusMutedUsers ?? [];
  
  return repository.getContactsStatuses(currentUser.contactsUIDs, mutedUsers);
}

// Simple provider to check if user has active statuses
@riverpod
bool hasActiveStatus(HasActiveStatusRef ref) {
  final myStatuses = ref.watch(myStatusesStreamProvider);
  return myStatuses.hasValue && myStatuses.value!.isNotEmpty;
}

// Provider for the StatusNotifier
final statusProvider = statusNotifierProvider;