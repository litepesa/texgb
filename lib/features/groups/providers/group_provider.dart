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
import 'package:textgb/features/groups/services/group_security_service.dart';
import 'package:textgb/models/user_model.dart';

part 'group_provider.g.dart';

// Enhanced state class for group management
class GroupState {
  final bool isLoading;
  final List<GroupModel> userGroups;
  final List<GroupModel> publicGroups;
  final GroupModel? currentGroup;
  final List<UserModel> currentGroupMembers;
  final String? error;
  final bool hasPermissionError;
  final Map<String, bool> loadingStates; // Track loading states for different operations

  const GroupState({
    this.isLoading = false,
    this.userGroups = const [],
    this.publicGroups = const [],
    this.currentGroup,
    this.currentGroupMembers = const [],
    this.error,
    this.hasPermissionError = false,
    this.loadingStates = const {},
  });

  GroupState copyWith({
    bool? isLoading,
    List<GroupModel>? userGroups,
    List<GroupModel>? publicGroups,
    GroupModel? currentGroup,
    List<UserModel>? currentGroupMembers,
    String? error,
    bool? hasPermissionError,
    Map<String, bool>? loadingStates,
  }) {
    return GroupState(
      isLoading: isLoading ?? this.isLoading,
      userGroups: userGroups ?? this.userGroups,
      publicGroups: publicGroups ?? this.publicGroups,
      currentGroup: currentGroup ?? this.currentGroup,
      currentGroupMembers: currentGroupMembers ?? this.currentGroupMembers,
      error: error,
      hasPermissionError: hasPermissionError ?? this.hasPermissionError,
      loadingStates: loadingStates ?? this.loadingStates,
    );
  }

  // Helper methods for checking loading states
  bool isOperationLoading(String operation) {
    return loadingStates[operation] ?? false;
  }

  GroupState withLoadingState(String operation, bool loading) {
    final newLoadingStates = Map<String, bool>.from(loadingStates);
    if (loading) {
      newLoadingStates[operation] = true;
    } else {
      newLoadingStates.remove(operation);
    }
    return copyWith(loadingStates: newLoadingStates);
  }
}

@riverpod
class GroupNotifier extends _$GroupNotifier {
  late GroupRepository _groupRepository;
  late GroupSecurityService _securityService;

  @override
  FutureOr<GroupState> build() {
    _groupRepository = ref.read(groupRepositoryProvider);
    _securityService = _groupRepository.securityService;
    
    // Initialize stream listeners
    _initGroupListeners();
    
    return const GroupState();
  }

  void _initGroupListeners() {
    // Listen to the user groups stream
    ref.listen(userGroupsStreamProvider, (previous, next) {
      if (next.hasValue && state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(userGroups: next.value!));
      }
    });
    
    // Listen to the public groups stream
    ref.listen(publicGroupsStreamProvider, (previous, next) {
      if (next.hasValue && state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(publicGroups: next.value!));
      }
    });
  }

  // Create a new group with enhanced validation
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
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('createGroup', true));

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
      
      state = AsyncValue.data(state.value!.withLoadingState('createGroup', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('createGroup', false));
      rethrow;
    }
  }

  // Get a group by ID and load its members with security validation
  Future<void> getGroupDetails(String groupId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('getGroupDetails', true));

    try {
      // Check permission first
      final canView = await _securityService.canUserViewGroup(groupId);
      if (!canView) {
        state = AsyncValue.data(state.value!.copyWith(
          error: 'You do not have permission to view this group',
          hasPermissionError: true,
        ).withLoadingState('getGroupDetails', false));
        return;
      }

      final group = await _groupRepository.getGroupById(groupId);
      
      if (group == null) {
        state = AsyncValue.data(state.value!.copyWith(
          error: 'Group not found',
        ).withLoadingState('getGroupDetails', false));
        return;
      }
      
      final members = await _groupRepository.getGroupMembers(groupId);
      
      state = AsyncValue.data(state.value!.copyWith(
        currentGroup: group,
        currentGroupMembers: members,
        error: null,
        hasPermissionError: false,
      ).withLoadingState('getGroupDetails', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('getGroupDetails', false));
    }
  }

  // Update group details with security check
  Future<void> updateGroup({
    required GroupModel updatedGroup,
    File? newGroupImage,
  }) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('updateGroup', true));

    try {
      await _groupRepository.updateGroup(updatedGroup, newGroupImage);
      
      state = AsyncValue.data(state.value!.copyWith(
        currentGroup: updatedGroup,
        error: null,
        hasPermissionError: false,
      ).withLoadingState('updateGroup', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('updateGroup', false));
      rethrow;
    }
  }

  // Get current user ID safely
  String? getCurrentUserUid() {
    final currentUser = ref.read(currentUserProvider);
    return currentUser?.uid;
  }

  // Open a group chat with security validation
  Future<void> openGroupChat(GroupModel group, BuildContext context) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate permission to view group
      final canView = await _securityService.canUserViewGroup(group.groupId);
      if (!canView) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You do not have permission to access this group')),
          );
        }
        return;
      }
      
      // Reset unread counter when opening the chat
      await _groupRepository.resetGroupUnreadCounter(group.groupId, currentUser.uid);
      
      // Navigate to the group chat screen
      if (context.mounted) {
        Navigator.pushNamed(
          context,
          Constants.groupChatScreen,
          arguments: {
            'groupId': group.groupId,
            'group': group,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening group chat: $e')),
        );
      }
    }
  }

  // Join a group with enhanced security
  Future<void> joinGroup(String groupId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('joinGroup', true));

    try {
      await _groupRepository.joinGroup(groupId);
      
      state = AsyncValue.data(state.value!.copyWith(
        error: null,
        hasPermissionError: false,
      ).withLoadingState('joinGroup', false));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('joinGroup', false));
      rethrow;
    }
  }

  // Leave a group with proper cleanup
  Future<void> leaveGroup(String groupId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('leaveGroup', true));

    try {
      await _groupRepository.leaveGroup(groupId);
      
      // Clear current group if it's the one we're leaving
      final currentGroup = state.value!.currentGroup;
      if (currentGroup != null && currentGroup.groupId == groupId) {
        state = AsyncValue.data(state.value!.copyWith(
          currentGroup: null,
          currentGroupMembers: [],
          error: null,
          hasPermissionError: false,
        ).withLoadingState('leaveGroup', false));
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          error: null,
          hasPermissionError: false,
        ).withLoadingState('leaveGroup', false));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('leaveGroup', false));
      rethrow;
    }
  }

  // Approve a join request with security validation
  Future<void> approveJoinRequest(String groupId, String userId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('approveRequest', true));

    try {
      await _groupRepository.approveJoinRequest(groupId, userId);
      
      // Refresh group details if we're viewing this group
      final currentGroup = state.value!.currentGroup;
      if (currentGroup != null && currentGroup.groupId == groupId) {
        await getGroupDetails(groupId);
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          error: null,
          hasPermissionError: false,
        ).withLoadingState('approveRequest', false));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('approveRequest', false));
      rethrow;
    }
  }

  // Reject a join request with security validation
  Future<void> rejectJoinRequest(String groupId, String userId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('rejectRequest', true));

    try {
      await _groupRepository.rejectJoinRequest(groupId, userId);
      
      // Refresh group details if we're viewing this group
      final currentGroup = state.value!.currentGroup;
      if (currentGroup != null && currentGroup.groupId == groupId) {
        await getGroupDetails(groupId);
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          error: null,
          hasPermissionError: false,
        ).withLoadingState('rejectRequest', false));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('rejectRequest', false));
      rethrow;
    }
  }

  // Add a user as admin with security validation
  Future<void> addAdmin(String groupId, String userId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('addAdmin', true));

    try {
      await _groupRepository.addAdmin(groupId, userId);
      
      // Refresh group details if we're viewing this group
      final currentGroup = state.value!.currentGroup;
      if (currentGroup != null && currentGroup.groupId == groupId) {
        await getGroupDetails(groupId);
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          error: null,
          hasPermissionError: false,
        ).withLoadingState('addAdmin', false));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('addAdmin', false));
      rethrow;
    }
  }

  // Remove a user as admin with security validation
  Future<void> removeAdmin(String groupId, String userId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('removeAdmin', true));

    try {
      await _groupRepository.removeAdmin(groupId, userId);
      
      // Refresh group details if we're viewing this group
      final currentGroup = state.value!.currentGroup;
      if (currentGroup != null && currentGroup.groupId == groupId) {
        await getGroupDetails(groupId);
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          error: null,
          hasPermissionError: false,
        ).withLoadingState('removeAdmin', false));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('removeAdmin', false));
      rethrow;
    }
  }

  // Remove a member from the group with security validation
  Future<void> removeMember(String groupId, String userId) async {
    if (!state.hasValue) return;

    state = AsyncValue.data(state.value!.withLoadingState('removeMember', true));

    try {
      await _groupRepository.removeMember(groupId, userId);
      
      // Refresh group details if we're viewing this group
      final currentGroup = state.value!.currentGroup;
      if (currentGroup != null && currentGroup.groupId == groupId) {
        await getGroupDetails(groupId);
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          error: null,
          hasPermissionError: false,
        ).withLoadingState('removeMember', false));
      }
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        error: e.toString(),
        hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
      ).withLoadingState('removeMember', false));
      rethrow;
    }
  }

  // Search for groups with caching
  Future<List<GroupModel>> searchGroups(String query) async {
    if (query.isEmpty) return [];
    
    try {
      return await _groupRepository.searchGroupsByName(query);
    } catch (e) {
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(
          error: e.toString(),
          hasPermissionError: e.toString().contains('permission') || e.toString().contains('authenticated'),
        ));
      }
      return [];
    }
  }

  // Check if current user is admin of given group with caching
  Future<bool> isCurrentUserAdmin(String groupId) async {
    try {
      return await _securityService.isUserAdmin(groupId);
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  // Check if current user is creator of given group
  bool isCurrentUserCreator(String groupId) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return false;
    
    final group = state.value?.userGroups.firstWhere(
      (group) => group.groupId == groupId,
      orElse: () => state.value?.currentGroup ?? _createEmptyGroup(),
    );
    
    if (group == null || group.groupId.isEmpty) return false;
    
    return group.isCreator(currentUser.uid);
  }

  // Helper method to create empty group for fallback
  GroupModel _createEmptyGroup() {
    return GroupModel(
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
    );
  }

  // Calculate total unread messages for groups
  Future<int> getTotalUnreadCount() async {
    final currentUserUid = getCurrentUserUid();
    if (currentUserUid == null) return 0;
    
    try {
      return await _groupRepository.getTotalGroupUnreadCount(currentUserUid);
    } catch (e) {
      debugPrint('Error getting total unread count: $e');
      return 0;
    }
  }

  // Count pending requests for groups where user is admin
  int getTotalPendingRequestsCount() {
    final currentUserUid = getCurrentUserUid();
    if (currentUserUid == null || !state.hasValue) return 0;
    
    final groups = state.value?.userGroups ?? [];
    
    return groups.fold<int>(
      0, 
      (sum, group) {
        // Only count if user is admin
        if (group.isAdmin(currentUserUid)) {
          return sum + group.awaitingApprovalUIDs.length;
        }
        return sum;
      }
    );
  }

  // Clear error state
  void clearError() {
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(
        error: null,
        hasPermissionError: false,
      ));
    }
  }

  // Check if user can send messages to a group
  Future<bool> canUserSendMessages(String groupId) async {
    try {
      return await _securityService.canUserSendMessages(groupId);
    } catch (e) {
      debugPrint('Error checking message permission: $e');
      return false;
    }
  }

  // Validate group action before performing it
  Future<bool> validateGroupAction(String groupId, GroupAction action) async {
    try {
      final result = await _securityService.validateGroupAction(groupId, action);
      
      if (!result.isAllowed && state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(
          error: result.reason,
          hasPermissionError: result.type == GroupActionResultType.forbidden || 
                              result.type == GroupActionResultType.unauthorized,
        ));
      }
      
      return result.isAllowed;
    } catch (e) {
      debugPrint('Error validating group action: $e');
      return false;
    }
  }
}

// Stream provider for user's groups with error handling
@riverpod
Stream<List<GroupModel>> userGroupsStream(UserGroupsStreamRef ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getUserGroups().handleError((error) {
    debugPrint('Error in user groups stream: $error');
    return <GroupModel>[];
  });
}

// Stream provider for public groups with error handling
@riverpod
Stream<List<GroupModel>> publicGroupsStream(PublicGroupsStreamRef ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.findPublicGroups().handleError((error) {
    debugPrint('Error in public groups stream: $error');
    return <GroupModel>[];
  });
}

// Use the auto-generated provider for GroupNotifier
final groupProvider = groupNotifierProvider;