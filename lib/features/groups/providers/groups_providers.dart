// lib/features/groups/providers/groups_providers.dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/models/group_member_model.dart';
import 'package:textgb/features/groups/models/group_message_model.dart';
import 'package:textgb/features/groups/services/group_api_service.dart';
import 'package:textgb/features/groups/services/group_websocket_service.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';

part 'groups_providers.g.dart';

// ==================== SERVICE PROVIDERS ====================

@riverpod
GroupApiService groupApiService(GroupApiServiceRef ref) {
  return GroupApiService();
}

@riverpod
GroupWebSocketService groupWebSocketService(GroupWebSocketServiceRef ref) {
  return GroupWebSocketService();
}

// ==================== GROUPS LIST PROVIDER ====================

@riverpod
class GroupsList extends _$GroupsList {
  late final GroupApiService _apiService;
  late final GroupWebSocketService _wsService;

  @override
  Future<List<GroupModel>> build() async {
    _apiService = ref.read(groupApiServiceProvider);
    _wsService = ref.read(groupWebSocketServiceProvider);

    // Connect to WebSocket
    try {
      await _wsService.connect();
    } catch (e) {
      debugPrint('Failed to connect to group WebSocket: $e');
    }

    // Fetch user's groups
    return _fetchGroups();
  }

  Future<List<GroupModel>> _fetchGroups() async {
    try {
      final groups = await _apiService.getUserGroups();

      // Sort by last message time (most recent first)
      groups.sort((a, b) {
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });

      return groups;
    } catch (e) {
      debugPrint('Error fetching groups: $e');
      rethrow;
    }
  }

  // Refresh groups list
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchGroups());
  }

  // Create new group
  Future<GroupModel?> createGroup({
    required String name,
    required String description,
    String? groupImageUrl,
    int maxMembers = 256,
  }) async {
    try {
      final group = await _apiService.createGroup(
        name: name,
        description: description,
        groupImageUrl: groupImageUrl,
        maxMembers: maxMembers,
      );

      // Add to local state
      final currentGroups = state.valueOrNull ?? [];
      state = AsyncValue.data([group, ...currentGroups]);

      return group;
    } catch (e) {
      debugPrint('Error creating group: $e');
      return null;
    }
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      await _apiService.deleteGroup(groupId);

      // Remove from local state
      final currentGroups = state.valueOrNull ?? [];
      state = AsyncValue.data(
        currentGroups.where((g) => g.id != groupId).toList(),
      );

      // Leave WebSocket channel
      await _wsService.leaveGroup(groupId);
    } catch (e) {
      debugPrint('Error deleting group: $e');
      rethrow;
    }
  }

  // Update group in local state
  void updateGroupLocally(GroupModel updatedGroup) {
    final currentGroups = state.valueOrNull ?? [];
    final index = currentGroups.indexWhere((g) => g.id == updatedGroup.id);

    if (index != -1) {
      final newGroups = [...currentGroups];
      newGroups[index] = updatedGroup;
      state = AsyncValue.data(newGroups);
    }
  }

  // Search groups
  Future<List<GroupModel>> searchGroups(String query) async {
    try {
      return await _apiService.searchGroups(query);
    } catch (e) {
      debugPrint('Error searching groups: $e');
      return [];
    }
  }
}

// ==================== GROUP DETAIL PROVIDER ====================

@riverpod
class GroupDetail extends _$GroupDetail {
  late final GroupApiService _apiService;
  late final GroupWebSocketService _wsService;

  @override
  Future<GroupModel> build(String groupId) async {
    _apiService = ref.read(groupApiServiceProvider);
    _wsService = ref.read(groupWebSocketServiceProvider);

    // Join group WebSocket channel
    try {
      await _wsService.joinGroup(groupId);

      // Listen to group updates
      _wsService.listenToGroupUpdates(groupId).listen((event) {
        _handleGroupUpdate(event);
      });
    } catch (e) {
      debugPrint('Failed to join group WebSocket: $e');
    }

    return _fetchGroupDetails(groupId);
  }

  Future<GroupModel> _fetchGroupDetails(String groupId) async {
    try {
      return await _apiService.getGroupDetails(groupId);
    } catch (e) {
      debugPrint('Error fetching group details: $e');
      rethrow;
    }
  }

  void _handleGroupUpdate(Map<String, dynamic> event) {
    final payload = event['payload'] as Map<String, dynamic>;
    final updatedGroup = GroupModel.fromJson(payload['group'] ?? payload);
    state = AsyncValue.data(updatedGroup);

    // Also update in groups list
    ref.read(groupsListProvider.notifier).updateGroupLocally(updatedGroup);
  }

  // Update group
  Future<void> updateGroup({
    String? name,
    String? description,
    String? groupImageUrl,
    int? maxMembers,
  }) async {
    final currentGroup = state.valueOrNull;
    if (currentGroup == null) return;

    try {
      final updatedGroup = await _apiService.updateGroup(
        groupId: currentGroup.id,
        name: name,
        description: description,
        groupImageUrl: groupImageUrl,
        maxMembers: maxMembers,
      );

      state = AsyncValue.data(updatedGroup);

      // Update in groups list
      ref.read(groupsListProvider.notifier).updateGroupLocally(updatedGroup);
    } catch (e) {
      debugPrint('Error updating group: $e');
      rethrow;
    }
  }

  // Refresh group details
  Future<void> refresh() async {
    final currentGroup = state.valueOrNull;
    if (currentGroup == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchGroupDetails(currentGroup.id));
  }
}

// ==================== GROUP MEMBERS PROVIDER ====================

@riverpod
class GroupMembers extends _$GroupMembers {
  late final GroupApiService _apiService;
  late final GroupWebSocketService _wsService;

  @override
  Future<List<GroupMemberModel>> build(String groupId) async {
    _apiService = ref.read(groupApiServiceProvider);
    _wsService = ref.read(groupWebSocketServiceProvider);

    // Listen to member changes
    _wsService.listenToMemberChanges(groupId).listen((event) {
      _handleMemberChange(event);
    });

    return _fetchMembers(groupId);
  }

  Future<List<GroupMemberModel>> _fetchMembers(String groupId) async {
    try {
      final members = await _apiService.getGroupMembers(groupId);

      // Sort by role (admins first) then by joined date
      members.sort((a, b) {
        if (a.isAdmin && !b.isAdmin) return -1;
        if (!a.isAdmin && b.isAdmin) return 1;
        return a.joinedAt.compareTo(b.joinedAt);
      });

      return members;
    } catch (e) {
      debugPrint('Error fetching members: $e');
      rethrow;
    }
  }

  void _handleMemberChange(Map<String, dynamic> event) {
    // Refresh members list on any member change
    ref.invalidateSelf();
  }

  // Add members
  Future<void> addMembers(List<String> userIds) async {
    final groupId = arg;

    try {
      await _apiService.addMembers(groupId: groupId, userIds: userIds);

      // Refresh members list
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Error adding members: $e');
      rethrow;
    }
  }

  // Remove member
  Future<void> removeMember(String userId) async {
    final groupId = arg;

    try {
      await _apiService.removeMember(groupId: groupId, userId: userId);

      // Remove from local state
      final currentMembers = state.valueOrNull ?? [];
      state = AsyncValue.data(
        currentMembers.where((m) => m.userId != userId).toList(),
      );
    } catch (e) {
      debugPrint('Error removing member: $e');
      rethrow;
    }
  }

  // Promote member
  Future<void> promoteMember(String userId) async {
    final groupId = arg;

    try {
      await _apiService.promoteMember(groupId: groupId, userId: userId);

      // Refresh members list
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Error promoting member: $e');
      rethrow;
    }
  }

  // Demote member
  Future<void> demoteMember(String userId) async {
    final groupId = arg;

    try {
      await _apiService.demoteMember(groupId: groupId, userId: userId);

      // Refresh members list
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Error demoting member: $e');
      rethrow;
    }
  }

  // Leave group
  Future<void> leaveGroup(String userId) async {
    return removeMember(userId);
  }

  // Check if user is admin
  bool isUserAdmin(String userId) {
    final members = state.valueOrNull ?? [];
    final member = members.where((m) => m.userId == userId).firstOrNull;
    return member?.isAdmin ?? false;
  }
}

// ==================== GROUP MESSAGES PROVIDER ====================

@riverpod
class GroupMessages extends _$GroupMessages {
  late final GroupApiService _apiService;
  late final GroupWebSocketService _wsService;

  @override
  Future<List<GroupMessageModel>> build(String groupId) async {
    _apiService = ref.read(groupApiServiceProvider);
    _wsService = ref.read(groupWebSocketServiceProvider);

    // Listen to new messages
    _wsService.listenToNewMessages(groupId).listen((message) {
      _handleNewMessage(message);
    });

    // Listen to deleted messages
    _wsService.listenToDeletedMessages(groupId).listen((messageId) {
      _handleDeletedMessage(messageId);
    });

    return _fetchMessages(groupId);
  }

  Future<List<GroupMessageModel>> _fetchMessages(String groupId) async {
    try {
      final messages = await _apiService.getGroupMessages(groupId, limit: 100);

      // Sort by timestamp (oldest first for chat display)
      messages.sort((a, b) => a.insertedAt.compareTo(b.insertedAt));

      return messages;
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      rethrow;
    }
  }

  void _handleNewMessage(GroupMessageModel message) {
    final currentMessages = state.valueOrNull ?? [];

    // Check if message already exists
    if (!currentMessages.any((m) => m.id == message.id)) {
      state = AsyncValue.data([...currentMessages, message]);
    }
  }

  void _handleDeletedMessage(String messageId) {
    final currentMessages = state.valueOrNull ?? [];
    state = AsyncValue.data(
      currentMessages.where((m) => m.id != messageId).toList(),
    );
  }

  // Send message
  Future<void> sendMessage({
    required String messageText,
    String? mediaUrl,
    MessageMediaType mediaType = MessageMediaType.text,
  }) async {
    final groupId = arg;

    try {
      // Optimistic update - add temporary message
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final tempMessage = GroupMessageModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          groupId: groupId,
          senderId: currentUser.uid,
          messageText: messageText,
          mediaUrl: mediaUrl,
          mediaType: mediaType,
          insertedAt: DateTime.now(),
          senderName: currentUser.name,
          senderImage: currentUser.profileImage,
        );

        final currentMessages = state.valueOrNull ?? [];
        state = AsyncValue.data([...currentMessages, tempMessage]);
      }

      // Send via API
      final sentMessage = await _apiService.sendMessage(
        groupId: groupId,
        messageText: messageText,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );

      // Replace temp message with real one
      final currentMessages = state.valueOrNull ?? [];
      final updatedMessages = currentMessages
          .where((m) => !m.id.startsWith('temp_'))
          .toList();

      // Add real message if not already added by WebSocket
      if (!updatedMessages.any((m) => m.id == sentMessage.id)) {
        updatedMessages.add(sentMessage);
      }

      state = AsyncValue.data(updatedMessages);
    } catch (e) {
      debugPrint('Error sending message: $e');

      // Remove temporary message on error
      final currentMessages = state.valueOrNull ?? [];
      state = AsyncValue.data(
        currentMessages.where((m) => !m.id.startsWith('temp_')).toList(),
      );

      rethrow;
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    final groupId = arg;

    try {
      await _apiService.deleteMessage(groupId: groupId, messageId: messageId);

      // Remove from local state (also handled by WebSocket)
      final currentMessages = state.valueOrNull ?? [];
      state = AsyncValue.data(
        currentMessages.where((m) => m.id != messageId).toList(),
      );
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  // Load more messages (pagination)
  Future<void> loadMore() async {
    final groupId = arg;
    final currentMessages = state.valueOrNull ?? [];

    if (currentMessages.isEmpty) return;

    try {
      final oldestMessage = currentMessages.first;
      final olderMessages = await _apiService.getGroupMessages(
        groupId,
        limit: 50,
        offset: currentMessages.length,
      );

      if (olderMessages.isNotEmpty) {
        final allMessages = [...olderMessages, ...currentMessages];
        allMessages.sort((a, b) => a.insertedAt.compareTo(b.insertedAt));
        state = AsyncValue.data(allMessages);
      }
    } catch (e) {
      debugPrint('Error loading more messages: $e');
    }
  }

  // Refresh messages
  Future<void> refresh() async {
    final groupId = arg;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMessages(groupId));
  }
}

// ==================== TYPING INDICATOR PROVIDER ====================

@riverpod
class TypingIndicator extends _$TypingIndicator {
  late final GroupWebSocketService _wsService;
  final Map<String, String> _typingUsers = {}; // userId -> userName

  @override
  Map<String, String> build(String groupId) {
    _wsService = ref.read(groupWebSocketServiceProvider);

    // Listen to typing events
    _wsService.listenToTyping(groupId).listen((event) {
      _handleTypingEvent(event);
    });

    return {};
  }

  void _handleTypingEvent(Map<String, dynamic> event) {
    final eventType = event['event'] as String;
    final payload = event['payload'] as Map<String, dynamic>;
    final userId = payload['user_id'] as String?;
    final userName = payload['user_name'] as String?;

    if (userId == null) return;

    // Don't show own typing
    final currentUser = ref.read(currentUserProvider);
    if (currentUser?.uid == userId) return;

    if (eventType == 'user_typing') {
      _typingUsers[userId] = userName ?? 'Someone';
    } else if (eventType == 'user_stopped_typing') {
      _typingUsers.remove(userId);
    }

    state = {..._typingUsers};
  }

  // Send typing indicator
  Future<void> sendTyping() async {
    final groupId = arg;
    try {
      await _wsService.sendTyping(groupId);
    } catch (e) {
      debugPrint('Error sending typing indicator: $e');
    }
  }

  // Send stop typing indicator
  Future<void> sendStopTyping() async {
    final groupId = arg;
    try {
      await _wsService.sendStopTyping(groupId);
    } catch (e) {
      debugPrint('Error sending stop typing indicator: $e');
    }
  }

  // Get typing text
  String getTypingText() {
    if (_typingUsers.isEmpty) return '';

    final names = _typingUsers.values.toList();
    if (names.length == 1) {
      return '${names[0]} is typing...';
    } else if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    } else {
      return '${names[0]} and ${names.length - 1} others are typing...';
    }
  }
}

// ==================== HELPER PROVIDERS ====================

// Check if current user is group admin
@riverpod
Future<bool> isGroupAdmin(IsGroupAdminRef ref, String groupId) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return false;

  final members = await ref.watch(groupMembersProvider(groupId).future);
  final member = members.where((m) => m.userId == currentUser.uid).firstOrNull;
  return member?.isAdmin ?? false;
}

// Get current user's membership status
@riverpod
Future<GroupMemberModel?> currentUserMembership(
  CurrentUserMembershipRef ref,
  String groupId,
) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final members = await ref.watch(groupMembersProvider(groupId).future);
  return members.where((m) => m.userId == currentUser.uid).firstOrNull;
}
