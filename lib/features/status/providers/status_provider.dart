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
  final List<StatusModel> allStatuses;
  final List<StatusModel> myStatuses;
  final Map<String, List<StatusModel>> contactStatuses;
  final StatusPrivacyType defaultPrivacy;
  final List<String> privacyUIDs;
  final String? error;

  const StatusState({
    this.isLoading = false,
    this.allStatuses = const [],
    this.myStatuses = const [],
    this.contactStatuses = const {},
    this.defaultPrivacy = StatusPrivacyType.all_contacts,
    this.privacyUIDs = const [],
    this.error,
  });

  StatusState copyWith({
    bool? isLoading,
    List<StatusModel>? allStatuses,
    List<StatusModel>? myStatuses,
    Map<String, List<StatusModel>>? contactStatuses,
    StatusPrivacyType? defaultPrivacy,
    List<String>? privacyUIDs,
    String? error,
  }) {
    return StatusState(
      isLoading: isLoading ?? this.isLoading,
      allStatuses: allStatuses ?? this.allStatuses,
      myStatuses: myStatuses ?? this.myStatuses,
      contactStatuses: contactStatuses ?? this.contactStatuses,
      defaultPrivacy: defaultPrivacy ?? this.defaultPrivacy,
      privacyUIDs: privacyUIDs ?? this.privacyUIDs,
      error: error,
    );
  }
}

@riverpod
class StatusNotifier extends _$StatusNotifier {
  late StatusRepository _repository;

  @override
  FutureOr<StatusState> build() {
    _repository = ref.read(statusRepositoryProvider);
    
    // Initialize stream listeners
    _initStatusListeners();
    
    return const StatusState();
  }

  void _initStatusListeners() {
    // Listen to the statuses stream
    ref.listen(statusesStreamProvider, (previous, next) {
      if (next.hasValue) {
        final allStatuses = next.value!;
        final myStatuses = [];
        final contactStatusMap = <String, List<StatusModel>>{};
        final currentUser = ref.read(currentUserProvider);
        
        if (currentUser != null) {
          // Separate statuses by user
          for (var status in allStatuses) {
            if (status.uid == currentUser.uid) {
              myStatuses.add(status);
            } else {
              if (!contactStatusMap.containsKey(status.uid)) {
                contactStatusMap[status.uid] = [];
              }
              contactStatusMap[status.uid]!.add(status);
            }
          }
        }
        
        state = AsyncValue.data(state.value!.copyWith(
          allStatuses: allStatuses,
          myStatuses: myStatuses as List<StatusModel>?,
          contactStatuses: contactStatusMap,
        ));
      }
    });
  }

  // Create a new status
  Future<void> createStatus({
    required StatusType type, 
    required String content,
    File? mediaFile,
    String? caption,
    StatusPrivacyType? privacyType,
    List<String>? privacyUIDs,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    
    try {
      await _repository.createStatus(
        mediaFile: mediaFile,
        type: type,
        content: content,
        currentUser: currentUser,
        privacyType: privacyType ?? state.value!.defaultPrivacy,
        privacyUIDs: privacyUIDs ?? state.value!.privacyUIDs,
        caption: caption,
      );
      
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: 'Error creating status: $e',
      ));
    }
  }
  
  // Mark a status as seen
  Future<void> markStatusAsSeen(String statusId) async {
    try {
      await _repository.markStatusAsSeen(statusId);
    } catch (e) {
      debugPrint('Error marking status as seen: $e');
    }
  }
  
  // Reply to a status
  Future<void> replyToStatus({
    required StatusModel status,
    required String message,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    
    try {
      await _repository.replyToStatus(
        status: status,
        message: message,
        currentUser: currentUser,
      );
      
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: 'Error replying to status: $e',
      ));
    }
  }
  
  // Delete a status
  Future<void> deleteStatus(String statusId) async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    
    try {
      await _repository.deleteStatus(statusId);
      
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: 'Error deleting status: $e',
      ));
    }
  }
  
  // Update default privacy settings
  void updateDefaultPrivacy({
    required StatusPrivacyType privacyType,
    required List<String> privacyUIDs,
  }) {
    state = AsyncValue.data(state.value!.copyWith(
      defaultPrivacy: privacyType,
      privacyUIDs: privacyUIDs,
    ));
  }
  
  // Get statuses for a specific contact/user
  List<StatusModel> getStatusesForUser(String uid) {
    if (state.value == null) return [];
    return state.value!.contactStatuses[uid] ?? [];
  }
  
  // Check if a contact has any unviewed statuses
  bool hasUnviewedStatus(String uid) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;
    
    final userStatuses = getStatusesForUser(uid);
    for (var status in userStatuses) {
      if (!status.seenBy.contains(currentUser.uid)) {
        return true;
      }
    }
    return false;
  }
  
  // Get all contacts who have posted statuses, sorted by time
  List<String> getContactsWithStatus() {
    if (state.value == null) return [];
    
    final Map<String, DateTime> latestStatusMap = {};
    
    // Find latest status timestamp for each contact
    state.value!.contactStatuses.forEach((uid, statuses) {
      if (statuses.isNotEmpty) {
        final latestStatus = statuses.reduce((a, b) {
          final aTime = int.parse(a.timestamp);
          final bTime = int.parse(b.timestamp);
          return aTime > bTime ? a : b;
        });
        
        latestStatusMap[uid] = DateTime.fromMillisecondsSinceEpoch(
          int.parse(latestStatus.timestamp)
        );
      }
    });
    
    // Sort contacts by their latest status time (most recent first)
    final sortedContacts = latestStatusMap.keys.toList()
      ..sort((a, b) => latestStatusMap[b]!.compareTo(latestStatusMap[a]!));
    
    return sortedContacts;
  }
  
  // Get the most recent status for a contact (for preview)
  StatusModel? getLatestStatusForContact(String uid) {
    final userStatuses = getStatusesForUser(uid);
    if (userStatuses.isEmpty) return null;
    
    return userStatuses.reduce((a, b) {
      final aTime = int.parse(a.timestamp);
      final bTime = int.parse(b.timestamp);
      return aTime > bTime ? a : b;
    });
  }
}

// Stream provider for statuses
@riverpod
Stream<List<StatusModel>> statusesStream(StatusesStreamRef ref) {
  final repository = ref.watch(statusRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return Stream.value([]);
  }
  
  return repository.getStatusesForUser(currentUser);
}

// Stream provider for my statuses
@riverpod
Stream<List<StatusModel>> myStatusesStream(MyStatusesStreamRef ref) {
  final repository = ref.watch(statusRepositoryProvider);
  return repository.getMyStatuses();
}

// Use the auto-generated provider for StatusNotifier
final statusProvider = statusNotifierProvider;