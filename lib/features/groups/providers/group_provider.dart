// lib/features/groups/providers/group_provider.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/repositories/group_repository.dart';
import 'package:textgb/models/user_model.dart';

part 'group_provider.g.dart';

// State class for group management
class GroupState {
  final bool isLoading;
  final List<GroupModel> userGroups;
  final List<GroupModel> publicGroups;
  final GroupModel? currentGroup;
  final List<UserModel> currentGroupMembers;
  final String? error;

  const GroupState({
    this.isLoading = false,
    this.userGroups = const [],
    this.publicGroups = const [],
    this.currentGroup,
    this.currentGroupMembers = const [],
    this.error,
  });

  GroupState copyWith({
    bool? isLoading,
    List<GroupModel>? userGroups,
    List<GroupModel>? publicGroups,
    GroupModel? currentGroup,
    List<UserModel>? currentGroupMembers,
    String? error,
  }) {
    return GroupState(
      isLoading: isLoading ?? this.isLoading,
      userGroups: userGroups ?? this.userGroups,
      publicGroups: publicGroups ?? this.publicGroups,
      currentGroup: currentGroup ?? this.currentGroup,
      currentGroupMembers: currentGroupMembers ?? this.currentGroupMembers,
      error: error,
    );
  }
}

@riverpod
class GroupNotifier extends _$GroupNotifier {
  late GroupRepository _groupRepository;

  @override
  FutureOr<GroupState> build() {
    _groupRepository = ref.read(groupRepositoryProvider);
    
    // Initialize stream listeners
    _initGroupListeners();
    
    return const GroupState();
  }

  void _initGroupListeners() {
    // Listen to the user groups stream
    ref.listen(userGroupsStreamProvider, (previous, next) {
      if (next.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(userGroups: next.value!));
      }
    });
    
    // Listen to the public groups stream
    ref.listen(publicGroupsStreamProvider, (previous, next) {
      if (next.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(publicGroups: next.value!));
      }
    });
  }

  // Create a new group
  Future<void> createGroup({
    required String groupName,
    required String groupDescription,
    required List<String> membersUIDs,
    required List<String> adminsUIDs,
    required File? groupImage,
    required bool isPrivate,
    required bool editSettings,
    required bool approveMembers,
    required bool lockMessages,
    required bool requestToJoin,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await _groupRepository.createGroup(
        groupName: groupName,
        groupDescription: groupDescription,
        membersUIDs: membersUIDs,
        adminsUIDs: adminsUIDs,
        groupImage: groupImage,
        isPrivate: isPrivate,
        editSettings: editSettings,
        approveMembers: approveMembers,
        lockMessages: lockMessages,
        requestToJoin: requestToJoin,
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

  // Get a group by ID and load its members
  Future<void> getGroupDetails(String groupId) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      final group = await _groupRepository.getGroupById(groupId);
      
      if (group == null) {
        throw Exception('Group not found');
      }
      
      final members = await _groupRepository.getGroupMembers(groupId);
      
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        currentGroup: group,
        currentGroupMembers: members,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Update group details
  Future<void> updateGroup({
    required GroupModel updatedGroup,
    File? newGroupImage,
  }) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await _groupRepository.updateGroup(updatedGroup, newGroupImage);
      
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        currentGroup: updatedGroup,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Get current user ID
  String? getCurrentUserUid() {
    final currentUser = ref.read(currentUserProvider);
    return currentUser?.uid;
  }

  // Open a group chat
  void openGroupChat(GroupModel group, BuildContext context) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    // Reset unread counter in the store when opening the chat
    _groupRepository.resetGroupUnreadCounter(group.groupId, currentUser.uid);
    
    // Navigate to the dedicated group chat screen
    Navigator.pushNamed(
      context,
      Constants.groupChatScreen,
      arguments: {
        'groupId': group.groupId,
        'group': group,
      },
    );
  }

  // Join a group
  Future<void> joinGroup(String groupId) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await _groupRepository.joinGroup(groupId);
      
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

  // Leave a group
  Future<void> leaveGroup(String groupId) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await _groupRepository.leaveGroup(groupId);
      
      // Clear current group if it's the one we're leaving
      final currentGroup = state.value!.currentGroup;
      if (currentGroup != null && currentGroup.groupId == groupId) {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
          currentGroup: null,
          currentGroupMembers: [],
        ));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Approve a join request
  Future<void> approveJoinRequest(String groupId, String userId) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await _groupRepository.approveJoinRequest(groupId, userId);
      
      // Refresh group details if we're viewing this group
      final currentGroup = state.value!.currentGroup;
      if (currentGroup != null && currentGroup.groupId == groupId) {
        await getGroupDetails(groupId);
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Reject a join request
  Future<void> rejectJoinRequest(String groupId, String userId) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await _groupRepository.rejectJoinRequest(groupId, userId);
      
      // Refresh group details if we're viewing this group
      final currentGroup = state.value!.currentGroup;
      if (currentGroup != null && currentGroup.groupId == groupId) {
        await getGroupDetails(groupId);
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Add a user as admin
  Future<void> addAdmin(String groupId, String userId) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await _groupRepository.addAdmin(groupId, userId);
      
      // Refresh group details if we're viewing this group
      final currentGroup = state.value!.currentGroup;
      if (currentGroup != null && currentGroup.groupId == groupId) {
        await getGroupDetails(groupId);
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Remove a user as admin
  Future<void> removeAdmin(String groupId, String userId) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await _groupRepository.removeAdmin(groupId, userId);
      
      // Refresh group details if we're viewing this group
      final currentGroup = state.value!.currentGroup;
      if (currentGroup != null && currentGroup.groupId == groupId) {
        await getGroupDetails(groupId);
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Remove a member from the group
  Future<void> removeMember(String groupId, String userId) async {
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      await _groupRepository.removeMember(groupId, userId);
      
      // Refresh group details if we're viewing this group
      final currentGroup = state.value!.currentGroup;
      if (currentGroup != null && currentGroup.groupId == groupId) {
        await getGroupDetails(groupId);
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          isLoading: false,
        ));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Search for groups
  Future<List<GroupModel>> searchGroups(String query) async {
    if (query.isEmpty) return [];
    
    try {
      return await _groupRepository.searchGroupsByName(query);
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
      ));
      return [];
    }
  }

  // Check if current user is admin of given group
  bool isCurrentUserAdmin(String groupId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;
    
    final group = state.value?.userGroups.firstWhere(
      (group) => group.groupId == groupId,
      orElse: () => state.value?.currentGroup ?? GroupModel(
        groupId: '',
        groupName: '',
        groupDescription: '',
        groupImage: '',
        creatorUID: '',
        isPrivate: false,
        editSettings: false,
        approveMembers: false,
        lockMessages: false,
        requestToJoin: false,
        membersUIDs: [],
        adminsUIDs: [],
        awaitingApprovalUIDs: [],
        createdAt: '',
      ),
    );
    
    if (group == null) return false;
    
    return group.isAdmin(currentUser.uid);
  }

  // Check if current user is creator of given group
  bool isCurrentUserCreator(String groupId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;
    
    final group = state.value?.userGroups.firstWhere(
      (group) => group.groupId == groupId,
      orElse: () => state.value?.currentGroup ?? GroupModel(
        groupId: '',
        groupName: '',
        groupDescription: '',
        groupImage: '',
        creatorUID: '',
        isPrivate: false,
        editSettings: false,
        approveMembers: false,
        lockMessages: false,
        requestToJoin: false,
        membersUIDs: [],
        adminsUIDs: [],
        awaitingApprovalUIDs: [],
        createdAt: '',
      ),
    );
    
    if (group == null) return false;
    
    return group.isCreator(currentUser.uid);
  }

  // Calculate total unread messages for groups
  int getTotalUnreadCount() {
    final currentUserUid = getCurrentUserUid();
    if (currentUserUid == null) return 0;
    
    final groups = state.value?.userGroups ?? [];
    return groups.fold<int>(
      0, 
      (sum, group) => sum + group.getUnreadCountForUser(currentUserUid)
    );
  }

  // Count pending requests for groups where user is admin
  int getTotalPendingRequestsCount() {
    final currentUserUid = getCurrentUserUid();
    if (currentUserUid == null) return 0;
    
    final groups = state.value?.userGroups.where(
      (group) => group.isAdmin(currentUserUid)
    ).toList() ?? [];
    
    return groups.fold<int>(
      0, 
      (sum, group) => sum + group.awaitingApprovalUIDs.length
    );
  }
}

// Stream provider for user's groups
@riverpod
Stream<List<GroupModel>> userGroupsStream(UserGroupsStreamRef ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getUserGroups();
}

// Stream provider for public groups
@riverpod
Stream<List<GroupModel>> publicGroupsStream(PublicGroupsStreamRef ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.findPublicGroups();
}

// Use the auto-generated provider for GroupNotifier
final groupProvider = groupNotifierProvider;