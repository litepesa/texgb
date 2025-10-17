// lib/features/groups/providers/group_provider.dart
// Main group provider with state management
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/repositories/group_repository.dart';
import 'package:textgb/features/groups/repositories/group_repository_impl.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/videos/models/video_model.dart';

part 'group_provider.g.dart';

// ========================================
// GROUP STATE
// ========================================

class GroupState {
  final List<GroupModel> groups;
  final List<GroupModel> myGroups;
  final List<GroupModel> featuredGroups;
  final Map<String, List<VideoModel>> groupPosts; // groupId -> posts
  final bool isLoading;
  final bool isConnected;
  final String? error;
  final DateTime? lastSync;
  
  const GroupState({
    this.groups = const [],
    this.myGroups = const [],
    this.featuredGroups = const [],
    this.groupPosts = const {},
    this.isLoading = false,
    this.isConnected = false,
    this.error,
    this.lastSync,
  });

  GroupState copyWith({
    List<GroupModel>? groups,
    List<GroupModel>? myGroups,
    List<GroupModel>? featuredGroups,
    Map<String, List<VideoModel>>? groupPosts,
    bool? isLoading,
    bool? isConnected,
    String? error,
    DateTime? lastSync,
  }) {
    return GroupState(
      groups: groups ?? this.groups,
      myGroups: myGroups ?? this.myGroups,
      featuredGroups: featuredGroups ?? this.featuredGroups,
      groupPosts: groupPosts ?? this.groupPosts,
      isLoading: isLoading ?? this.isLoading,
      isConnected: isConnected ?? this.isConnected,
      error: error,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

// ========================================
// REPOSITORY PROVIDER
// ========================================

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryImpl();
});

// ========================================
// MAIN GROUP PROVIDER
// ========================================

@riverpod
class Groups extends _$Groups {
  late GroupRepository _repository;
  
  @override
  FutureOr<GroupState> build() async {
    _repository = ref.read(groupRepositoryProvider);
    
    // Initialize connection
    await _initialize();
    
    // Load groups
    final groups = await _repository.getGroups();
    final myGroups = await _repository.getMyGroups();
    final featuredGroups = await _repository.getFeaturedGroups();
    
    return GroupState(
      groups: groups,
      myGroups: myGroups,
      featuredGroups: featuredGroups,
      isConnected: _repository.isConnected,
      lastSync: DateTime.now(),
    );
  }

  // ===============================
  // INITIALIZATION
  // ===============================

  Future<void> _initialize() async {
    try {
      // Connect to WebSocket
      await _repository.connect();
      
      // Listen to connection state
      _repository.connectionStateStream.listen((isConnected) {
        if (state.hasValue) {
          state = AsyncValue.data(state.value!.copyWith(
            isConnected: isConnected,
          ));
        }
      });
      
      debugPrint('✅ Groups provider initialized');
    } catch (e) {
      debugPrint('❌ Groups initialization failed: $e');
    }
  }

  // ===============================
  // GROUP OPERATIONS
  // ===============================

  Future<void> loadGroups() async {
    if (!state.hasValue) return;
    
    state = AsyncValue.data(state.value!.copyWith(
      isLoading: true,
      error: null,
    ));

    try {
      final groups = await _repository.getGroups();
      
      state = AsyncValue.data(state.value!.copyWith(
        groups: groups,
        isLoading: false,
        lastSync: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('❌ Error loading groups: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadMyGroups() async {
    if (!state.hasValue) return;
    
    try {
      final myGroups = await _repository.getMyGroups();
      
      state = AsyncValue.data(state.value!.copyWith(
        myGroups: myGroups,
      ));
    } catch (e) {
      debugPrint('❌ Error loading my groups: $e');
    }
  }

  Future<void> loadFeaturedGroups() async {
    if (!state.hasValue) return;
    
    try {
      final featuredGroups = await _repository.getFeaturedGroups();
      
      state = AsyncValue.data(state.value!.copyWith(
        featuredGroups: featuredGroups,
      ));
    } catch (e) {
      debugPrint('❌ Error loading featured groups: $e');
    }
  }

  Future<void> refreshGroups() async {
    if (!state.hasValue) return;
    
    try {
      await _repository.syncWithServer();
      await loadGroups();
      await loadMyGroups();
      await loadFeaturedGroups();
    } catch (e) {
      debugPrint('❌ Error refreshing groups: $e');
    }
  }

  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      return await _repository.getGroupById(groupId);
    } catch (e) {
      debugPrint('❌ Error getting group: $e');
      return null;
    }
  }

  Future<GroupModel?> createGroup({
    required String name,
    required String description,
    required File? groupImage,
    required File? coverImage,
    required GroupPrivacy privacy,
    int? maxMembers,
    bool? allowMemberPosts,
    bool? requireApproval,
  }) async {
    if (!state.hasValue) return null;
    
    final authState = ref.read(authenticationProvider).value;
    if (authState?.currentUser == null) return null;
    
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final group = await _repository.createGroup(
        name: name,
        description: description,
        groupImage: groupImage,
        coverImage: coverImage,
        creatorId: authState!.currentUser!.uid,
        privacy: privacy,
        maxMembers: maxMembers,
        allowMemberPosts: allowMemberPosts,
        requireApproval: requireApproval,
      );
      
      // Add to groups lists
      final updatedGroups = List<GroupModel>.from(state.value!.groups);
      updatedGroups.insert(0, group);
      
      final updatedMyGroups = List<GroupModel>.from(state.value!.myGroups);
      updatedMyGroups.insert(0, group);
      
      state = AsyncValue.data(state.value!.copyWith(
        groups: updatedGroups,
        myGroups: updatedMyGroups,
        isLoading: false,
      ));
      
      return group;
    } catch (e) {
      debugPrint('❌ Error creating group: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      return null;
    }
  }

  Future<GroupModel?> updateGroup({
    required String groupId,
    String? name,
    String? description,
    File? groupImage,
    File? coverImage,
    GroupPrivacy? privacy,
    int? maxMembers,
    bool? allowMemberPosts,
    bool? requireApproval,
  }) async {
    if (!state.hasValue) return null;
    
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      final group = await _repository.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        groupImage: groupImage,
        coverImage: coverImage,
        privacy: privacy,
        maxMembers: maxMembers,
        allowMemberPosts: allowMemberPosts,
        requireApproval: requireApproval,
      );
      
      // Update in all lists
      final updatedGroups = state.value!.groups.map((g) {
        return g.id == groupId ? group : g;
      }).toList();
      
      final updatedMyGroups = state.value!.myGroups.map((g) {
        return g.id == groupId ? group : g;
      }).toList();
      
      final updatedFeatured = state.value!.featuredGroups.map((g) {
        return g.id == groupId ? group : g;
      }).toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        groups: updatedGroups,
        myGroups: updatedMyGroups,
        featuredGroups: updatedFeatured,
        isLoading: false,
      ));
      
      return group;
    } catch (e) {
      debugPrint('❌ Error updating group: $e');
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      return null;
    }
  }

  Future<void> deleteGroup(String groupId) async {
    if (!state.hasValue) return;
    
    try {
      await _repository.deleteGroup(groupId);
      
      // Remove from all lists
      final updatedGroups = state.value!.groups
          .where((g) => g.id != groupId)
          .toList();
      
      final updatedMyGroups = state.value!.myGroups
          .where((g) => g.id != groupId)
          .toList();
      
      final updatedFeatured = state.value!.featuredGroups
          .where((g) => g.id != groupId)
          .toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        groups: updatedGroups,
        myGroups: updatedMyGroups,
        featuredGroups: updatedFeatured,
      ));
    } catch (e) {
      debugPrint('❌ Error deleting group: $e');
    }
  }

  Future<List<GroupModel>> searchGroups(String query) async {
    try {
      return await _repository.searchGroups(query);
    } catch (e) {
      debugPrint('❌ Error searching groups: $e');
      return [];
    }
  }

  // ===============================
  // MEMBER OPERATIONS
  // ===============================

  Future<void> joinGroup(String groupId) async {
    if (!state.hasValue) return;
    
    final authState = ref.read(authenticationProvider).value;
    if (authState?.currentUser == null) return;
    
    try {
      final group = await getGroupById(groupId);
      if (group == null) return;
      
      if (group.requireApproval) {
        await _repository.sendJoinRequest(groupId);
      } else {
        await _repository.addMember(
          groupId: groupId,
          userId: authState!.currentUser!.uid,
          userName: authState.currentUser!.name,
          userImage: authState.currentUser!.profileImage,
        );
        
        // Add to my groups
        final updatedMyGroups = List<GroupModel>.from(state.value!.myGroups);
        if (!updatedMyGroups.any((g) => g.id == groupId)) {
          updatedMyGroups.add(group);
          state = AsyncValue.data(state.value!.copyWith(
            myGroups: updatedMyGroups,
          ));
        }
      }
    } catch (e) {
      debugPrint('❌ Error joining group: $e');
    }
  }

  Future<void> leaveGroup(String groupId) async {
    if (!state.hasValue) return;
    
    try {
      await _repository.leaveGroup(groupId);
      
      // Remove from my groups
      final updatedMyGroups = state.value!.myGroups
          .where((g) => g.id != groupId)
          .toList();
      
      state = AsyncValue.data(state.value!.copyWith(
        myGroups: updatedMyGroups,
      ));
    } catch (e) {
      debugPrint('❌ Error leaving group: $e');
    }
  }

  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _repository.removeMember(
        groupId: groupId,
        userId: userId,
      );
      
      // Refresh group to update member list
      final updatedGroup = await _repository.refreshGroup(groupId);
      if (updatedGroup != null) {
        _updateGroupInLists(updatedGroup);
      }
    } catch (e) {
      debugPrint('❌ Error removing member: $e');
    }
  }

  Future<void> promoteToAdmin({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _repository.promoteToAdmin(
        groupId: groupId,
        userId: userId,
      );
      
      // Refresh group
      final updatedGroup = await _repository.refreshGroup(groupId);
      if (updatedGroup != null) {
        _updateGroupInLists(updatedGroup);
      }
    } catch (e) {
      debugPrint('❌ Error promoting to admin: $e');
    }
  }

  Future<void> promoteToModerator({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _repository.promoteToModerator(
        groupId: groupId,
        userId: userId,
      );
      
      // Refresh group
      final updatedGroup = await _repository.refreshGroup(groupId);
      if (updatedGroup != null) {
        _updateGroupInLists(updatedGroup);
      }
    } catch (e) {
      debugPrint('❌ Error promoting to moderator: $e');
    }
  }

  Future<void> demoteAdmin({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _repository.demoteAdmin(
        groupId: groupId,
        userId: userId,
      );
      
      // Refresh group
      final updatedGroup = await _repository.refreshGroup(groupId);
      if (updatedGroup != null) {
        _updateGroupInLists(updatedGroup);
      }
    } catch (e) {
      debugPrint('❌ Error demoting admin: $e');
    }
  }

  Future<void> muteMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _repository.muteMember(
        groupId: groupId,
        userId: userId,
      );
      
      // Refresh group
      final updatedGroup = await _repository.refreshGroup(groupId);
      if (updatedGroup != null) {
        _updateGroupInLists(updatedGroup);
      }
    } catch (e) {
      debugPrint('❌ Error muting member: $e');
    }
  }

  Future<void> unmuteMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _repository.unmuteMember(
        groupId: groupId,
        userId: userId,
      );
      
      // Refresh group
      final updatedGroup = await _repository.refreshGroup(groupId);
      if (updatedGroup != null) {
        _updateGroupInLists(updatedGroup);
      }
    } catch (e) {
      debugPrint('❌ Error unmuting member: $e');
    }
  }

  // ===============================
  // JOIN REQUEST OPERATIONS
  // ===============================

  Future<void> sendJoinRequest(String groupId) async {
    try {
      await _repository.sendJoinRequest(groupId);
    } catch (e) {
      debugPrint('❌ Error sending join request: $e');
    }
  }

  Future<void> cancelJoinRequest(String groupId) async {
    try {
      await _repository.cancelJoinRequest(groupId);
    } catch (e) {
      debugPrint('❌ Error canceling join request: $e');
    }
  }

  Future<void> approveJoinRequest({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _repository.approveJoinRequest(
        groupId: groupId,
        userId: userId,
      );
      
      // Refresh group
      final updatedGroup = await _repository.refreshGroup(groupId);
      if (updatedGroup != null) {
        _updateGroupInLists(updatedGroup);
      }
    } catch (e) {
      debugPrint('❌ Error approving join request: $e');
    }
  }

  Future<void> rejectJoinRequest({
    required String groupId,
    required String userId,
  }) async {
    try {
      await _repository.rejectJoinRequest(
        groupId: groupId,
        userId: userId,
      );
      
      // Refresh group
      final updatedGroup = await _repository.refreshGroup(groupId);
      if (updatedGroup != null) {
        _updateGroupInLists(updatedGroup);
      }
    } catch (e) {
      debugPrint('❌ Error rejecting join request: $e');
    }
  }

  // ===============================
  // GROUP POST OPERATIONS
  // ===============================

  Future<void> loadGroupPosts(String groupId, {int limit = 20}) async {
    if (!state.hasValue) return;
    
    try {
      final posts = await _repository.getGroupPosts(
        groupId: groupId,
        limit: limit,
      );
      
      final updatedPosts = Map<String, List<VideoModel>>.from(state.value!.groupPosts);
      updatedPosts[groupId] = posts;
      
      state = AsyncValue.data(state.value!.copyWith(
        groupPosts: updatedPosts,
      ));
    } catch (e) {
      debugPrint('❌ Error loading group posts: $e');
    }
  }

  // ===============================
  // HELPER METHODS
  // ===============================

  void _updateGroupInLists(GroupModel group) {
    if (!state.hasValue) return;
    
    final updatedGroups = state.value!.groups.map((g) {
      return g.id == group.id ? group : g;
    }).toList();
    
    final updatedMyGroups = state.value!.myGroups.map((g) {
      return g.id == group.id ? group : g;
    }).toList();
    
    final updatedFeatured = state.value!.featuredGroups.map((g) {
      return g.id == group.id ? group : g;
    }).toList();
    
    state = AsyncValue.data(state.value!.copyWith(
      groups: updatedGroups,
      myGroups: updatedMyGroups,
      featuredGroups: updatedFeatured,
    ));
  }

  // ===============================
  // CLEANUP
  // ===============================

  Future<void> dispose() async {
    try {
      await _repository.disconnect();
    } catch (e) {
      debugPrint('❌ Error disposing groups provider: $e');
    }
  }
}