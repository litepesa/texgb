// lib/features/groups/providers/group_convenience_providers.dart
// Convenience providers for easy access to group data
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/videos/models/video_model.dart';

part 'group_convenience_providers.g.dart';

// ========================================
// GROUP LIST PROVIDERS
// ========================================

/// Get all groups
@riverpod
List<GroupModel> allGroups(AllGroupsRef ref) {
  final groupState = ref.watch(groupsProvider);
  return groupState.value?.groups ?? [];
}

/// Get my groups (where user is a member)
@riverpod
List<GroupModel> myGroups(MyGroupsRef ref) {
  final groupState = ref.watch(groupsProvider);
  return groupState.value?.myGroups ?? [];
}

/// Get featured groups
@riverpod
List<GroupModel> featuredGroups(FeaturedGroupsRef ref) {
  final groupState = ref.watch(groupsProvider);
  return groupState.value?.featuredGroups ?? [];
}

/// Get public groups
@riverpod
List<GroupModel> publicGroups(PublicGroupsRef ref) {
  final groups = ref.watch(allGroupsProvider);
  return groups.where((group) => group.isPublic).toList();
}

/// Get private groups
@riverpod
List<GroupModel> privateGroups(PrivateGroupsRef ref) {
  final groups = ref.watch(allGroupsProvider);
  return groups.where((group) => group.isPrivate).toList();
}

/// Get verified groups
@riverpod
List<GroupModel> verifiedGroups(VerifiedGroupsRef ref) {
  final groups = ref.watch(allGroupsProvider);
  return groups.where((group) => group.isVerified).toList();
}

/// Get active groups
@riverpod
List<GroupModel> activeGroups(ActiveGroupsRef ref) {
  final groups = ref.watch(allGroupsProvider);
  return groups.where((group) => group.isActive).toList();
}

/// Get filtered groups (search)
@riverpod
List<GroupModel> filteredGroups(FilteredGroupsRef ref, String query) {
  final groups = ref.watch(allGroupsProvider);
  
  if (query.isEmpty) return groups;
  
  final lowerQuery = query.toLowerCase();
  return groups.where((group) {
    final name = group.name.toLowerCase();
    final description = group.description.toLowerCase();
    
    return name.contains(lowerQuery) || description.contains(lowerQuery);
  }).toList();
}

// ========================================
// SPECIFIC GROUP PROVIDERS
// ========================================

/// Get specific group by ID
@riverpod
Future<GroupModel?> groupById(GroupByIdRef ref, String groupId) async {
  final groupsNotifier = ref.read(groupsProvider.notifier);
  return await groupsNotifier.getGroupById(groupId);
}

/// Get group name
@riverpod
String groupName(GroupNameRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  return group.name;
}

/// Get group description
@riverpod
String groupDescription(GroupDescriptionRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  return group.description;
}

// ========================================
// MEMBERSHIP PROVIDERS
// ========================================

/// Check if current user is a member of a group
@riverpod
bool isGroupMember(IsGroupMemberRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  
  return group.isMember(currentUserId);
}

/// Check if current user is admin of a group
@riverpod
bool isGroupAdmin(IsGroupAdminRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  
  return group.isAdmin(currentUserId);
}

/// Check if current user is moderator of a group
@riverpod
bool isGroupModerator(IsGroupModeratorRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  
  return group.isModerator(currentUserId);
}

/// Check if current user can manage a group
@riverpod
bool canManageGroup(CanManageGroupRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  
  return group.canManageGroup(currentUserId);
}

/// Check if current user can moderate a group
@riverpod
bool canModerateGroup(CanModerateGroupRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  
  return group.canModerate(currentUserId);
}

/// Check if current user can post in a group
@riverpod
bool canPostInGroup(CanPostInGroupRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  
  return group.canPost(currentUserId);
}

/// Get member role in a group
@riverpod
MemberRole groupMemberRole(GroupMemberRoleRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  
  return group.getMemberRole(currentUserId);
}

// ========================================
// GROUP STATISTICS PROVIDERS
// ========================================

/// Get group members count
@riverpod
int groupMembersCount(GroupMembersCountRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  return group.membersCount;
}

/// Get group posts count
@riverpod
int groupPostsCount(GroupPostsCountRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  return group.postsCount;
}

/// Check if group is at max capacity
@riverpod
bool isGroupAtMaxCapacity(IsGroupAtMaxCapacityRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  return group.isAtMaxCapacity;
}

/// Get formatted members count text
@riverpod
String groupMembersCountText(GroupMembersCountTextRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  return group.membersCountText;
}

/// Get formatted posts count text
@riverpod
String groupPostsCountText(GroupPostsCountTextRef ref, String groupId) {
  final groups = ref.watch(allGroupsProvider);
  final group = groups.firstWhere(
    (g) => g.id == groupId,
    orElse: () => GroupModel(
      id: '',
      name: '',
      description: '',
      groupImage: '',
      coverImage: '',
      privacy: GroupPrivacy.public,
      creatorId: '',
      creatorName: '',
      members: [],
      memberIds: [],
      adminIds: [],
      moderatorIds: [],
      membersCount: 0,
      postsCount: 0,
      createdAt: '',
      updatedAt: '',
    ),
  );
  return group.postsCountText;
}

// ========================================
// GROUP POST PROVIDERS
// ========================================

/// Get posts for a specific group
@riverpod
List<VideoModel> groupPosts(GroupPostsRef ref, String groupId) {
  final groupState = ref.watch(groupsProvider);
  return groupState.value?.groupPosts[groupId] ?? [];
}

/// Get post count for a group
@riverpod
int groupPostCount(GroupPostCountRef ref, String groupId) {
  final posts = ref.watch(groupPostsProvider(groupId));
  return posts.length;
}

// ========================================
// CONNECTION STATE PROVIDERS
// ========================================

/// Check if groups are connected
@riverpod
bool isGroupsConnected(IsGroupsConnectedRef ref) {
  final groupState = ref.watch(groupsProvider);
  return groupState.value?.isConnected ?? false;
}

/// Check if groups are loading
@riverpod
bool isGroupsLoading(IsGroupsLoadingRef ref) {
  final groupState = ref.watch(groupsProvider);
  return groupState.value?.isLoading ?? false;
}

/// Get groups error if any
@riverpod
String? groupsError(GroupsErrorRef ref) {
  final groupState = ref.watch(groupsProvider);
  return groupState.value?.error;
}

/// Get last sync time
@riverpod
DateTime? lastGroupsSync(LastGroupsSyncRef ref) {
  final groupState = ref.watch(groupsProvider);
  return groupState.value?.lastSync;
}

// ========================================
// ADMIN SPECIFIC PROVIDERS
// ========================================

/// Get groups where user is admin
@riverpod
List<GroupModel> adminGroups(AdminGroupsRef ref) {
  final myGroups = ref.watch(myGroupsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  return myGroups.where((group) => group.isAdmin(currentUserId)).toList();
}

/// Get groups where user is moderator
@riverpod
List<GroupModel> moderatorGroups(ModeratorGroupsRef ref) {
  final myGroups = ref.watch(myGroupsProvider);
  final authState = ref.read(authenticationProvider).value;
  final currentUserId = authState?.currentUser?.uid ?? '';
  
  return myGroups.where((group) => group.isModerator(currentUserId)).toList();
}

// ========================================
// STATISTICS PROVIDERS
// ========================================

/// Get total group count
@riverpod
int totalGroupCount(TotalGroupCountRef ref) {
  final groups = ref.watch(allGroupsProvider);
  return groups.length;
}

/// Get my group count
@riverpod
int myGroupCount(MyGroupCountRef ref) {
  final myGroups = ref.watch(myGroupsProvider);
  return myGroups.length;
}

/// Get featured group count
@riverpod
int featuredGroupCount(FeaturedGroupCountRef ref) {
  final featuredGroups = ref.watch(featuredGroupsProvider);
  return featuredGroups.length;
}

/// Get public group count
@riverpod
int publicGroupCount(PublicGroupCountRef ref) {
  final publicGroups = ref.watch(publicGroupsProvider);
  return publicGroups.length;
}