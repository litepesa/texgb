// lib/features/groups/screens/groups_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/features/groups/repositories/group_repository.dart';
import 'package:textgb/features/groups/widgets/group_tile.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/models/user_model.dart';

// Provider to filter only group chats from the chat stream
final groupChatStreamProvider = Provider<AsyncValue<List<ChatModel>>>((ref) {
  final allChats = ref.watch(chatStreamProvider);
  
  return allChats.when(
    data: (chats) => AsyncValue.data(chats.where((chat) => chat.isGroup).toList()),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

class GroupsTab extends ConsumerStatefulWidget {
  const GroupsTab({super.key});

  @override
  ConsumerState<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends ConsumerState<GroupsTab> {
  final TextEditingController _searchController = TextEditingController();
  List<GroupModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Perform search
  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await ref.read(groupProvider.notifier).searchGroups(query);
    
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    // Watch user groups stream
    final userGroupsAsync = ref.watch(userGroupsStreamProvider);
    
    // Watch group chats stream
    final groupChatsAsync = ref.watch(groupChatStreamProvider);
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: Icon(Icons.search, color: theme.textSecondaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.borderColor!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.borderColor!),
                ),
                filled: true,
                fillColor: theme.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _performSearch,
            ),
          ),
          
          // Main content
          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildGroupsContent(userGroupsAsync, groupChatsAsync),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Join group by code button
          FloatingActionButton.small(
            heroTag: 'joinGroupButton',
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, Constants.joinGroupByCodeScreen);
            },
            child: const Icon(Icons.link),
            tooltip: 'Join group by code',
          ),
          const SizedBox(height: 16),
          // Create group button
          FloatingActionButton(
            heroTag: 'createGroupButton',
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, Constants.createGroupScreen);
            },
            child: const Icon(Icons.group_add),
            tooltip: 'Create new group',
          ),
        ],
      ),
    );
  }

  // Updated method to build combined groups content
  Widget _buildGroupsContent(
    AsyncValue<List<GroupModel>> userGroupsAsync, 
    AsyncValue<List<ChatModel>> groupChatsAsync
  ) {
    final theme = context.modernTheme;
    
    return userGroupsAsync.when(
      data: (userGroups) {
        return groupChatsAsync.when(
          data: (groupChats) {
            // If both are empty, show empty state
            if (userGroups.isEmpty && groupChats.isEmpty) {
              return _buildEmptyState();
            }
            
            // Create a unified list of groups
            final List<GroupModel> allGroups = List.from(userGroups);
            final Map<String, bool> groupIds = {};
            
            // Track existing group IDs
            for (final group in userGroups) {
              groupIds[group.groupId] = true;
            }
            
            // Add group chats that aren't in userGroups
            for (final chat in groupChats) {
              if (!groupIds.containsKey(chat.id)) {
                // Create a new group model from the chat
                final group = GroupModel(
                  groupId: chat.id,
                  groupName: chat.contactName,
                  groupDescription: '',
                  groupImage: chat.contactImage,
                  creatorUID: '',
                  isPrivate: true,
                  editSettings: false,
                  approveMembers: false,
                  lockMessages: false,
                  requestToJoin: false,
                  membersUIDs: const [],
                  adminsUIDs: const [],
                  awaitingApprovalUIDs: const [],
                  lastMessage: chat.lastMessage,
                  lastMessageSender: chat.lastMessageSender,
                  lastMessageTime: chat.lastMessageTime,
                  unreadCount: chat.unreadCount,
                  unreadCountByUser: Map<String, int>.from(chat.unreadCountByUser),
                  createdAt: '',
                );
                
                allGroups.add(group);
              } else {
                // Update existing group with latest message info
                final existingGroupIndex = allGroups.indexWhere((g) => g.groupId == chat.id);
                if (existingGroupIndex != -1) {
                  final existingGroup = allGroups[existingGroupIndex];
                  
                  // Only update if chat has more recent message
                  if (chat.lastMessageTime.isNotEmpty && 
                      (existingGroup.lastMessageTime.isEmpty || 
                       int.parse(chat.lastMessageTime) > int.parse(existingGroup.lastMessageTime))) {
                    
                    allGroups[existingGroupIndex] = existingGroup.copyWith(
                      lastMessage: chat.lastMessage,
                      lastMessageSender: chat.lastMessageSender,
                      lastMessageTime: chat.lastMessageTime,
                      unreadCount: chat.unreadCount,
                      unreadCountByUser: Map<String, int>.from(chat.unreadCountByUser),
                    );
                  }
                }
              }
            }
            
            // Sort by most recent message
            allGroups.sort((a, b) {
              if (a.lastMessageTime.isEmpty) return 1;
              if (b.lastMessageTime.isEmpty) return -1;
              return int.parse(b.lastMessageTime).compareTo(int.parse(a.lastMessageTime));
            });
            
            // Show a single unified list
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: allGroups.length,
              itemBuilder: (context, index) {
                final group = allGroups[index];
                
                // Check if this is from groupChats or userGroups
                final isFromChat = !groupIds.containsKey(group.groupId) || 
                  (groupIds.containsKey(group.groupId) && 
                   groupChats.any((c) => c.id == group.groupId && 
                                          c.lastMessageTime == group.lastMessageTime));
                
                if (isFromChat) {
                  // Find the original chat
                  final chat = groupChats.firstWhere((c) => c.id == group.groupId);
                  
                  return GroupTile(
                    group: group,
                    onTap: () {
                      _openGroupChat(chat);
                    },
                  );
                } else {
                  return GroupTile(
                    group: group,
                    onTap: () {
                      ref.read(groupProvider.notifier).openGroupChat(group, context);
                    },
                  );
                }
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: Text(
              'Error loading group chats: $e',
              style: TextStyle(color: theme.textColor),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Text(
          'Error loading groups: $e',
          style: TextStyle(color: context.modernTheme.textColor),
        ),
      ),
    );
  }
  
  // Method to handle opening a group chat from chat model
  void _openGroupChat(ChatModel chat) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;
      
      // First check if user is a member of this group
      final isUserMember = await ref.read(groupRepositoryProvider).isUserMemberOfGroup(
        currentUser.uid, 
        chat.id
      );
      
      if (!isUserMember) {
        if (mounted) {
          // Show dialog to join the group instead of directly opening chat
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Join Group'),
              content: const Text('You must be a member to view and send messages in this group. Would you like to join?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _joinGroup(chat.id);
                  },
                  child: const Text('Join Group'),
                ),
              ],
            ),
          );
          return;
        }
      }
      
      // Create temporary group model to pass to the screen
      final tempGroup = GroupModel(
        groupId: chat.id,
        groupName: chat.contactName,
        groupDescription: '',
        groupImage: chat.contactImage,
        creatorUID: '',
        isPrivate: true,
        editSettings: false,
        approveMembers: false,
        lockMessages: false,
        requestToJoin: false,
        membersUIDs: isUserMember ? [currentUser.uid] : [], // Add current user if they're a member
        adminsUIDs: const [],
        awaitingApprovalUIDs: const [],
        lastMessage: chat.lastMessage,
        lastMessageSender: chat.lastMessageSender,
        lastMessageTime: chat.lastMessageTime,
        unreadCount: chat.unreadCount,
        unreadCountByUser: Map<String, int>.from(chat.unreadCountByUser),
        createdAt: '',
      );
      
      // If user is a member, proceed with opening the chat
      if (isUserMember) {
        await ref.read(chatProvider.notifier).openGroupChat(
          chat.id, 
          [], 
        );
        
        if (mounted) {
          // Navigate to group chat screen
          Navigator.pushNamed(
            context,
            Constants.groupChatScreen,
            arguments: {
              'groupId': chat.id,
              'group': tempGroup,
              'isGroup': true,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error opening group chat: $e');
      }
    }
  }
  
  // Helper method to join a group
  Future<void> _joinGroup(String groupId) async {
    try {
      await ref.read(groupProvider.notifier).joinGroup(groupId);
      if (mounted) {
        final group = await ref.read(groupRepositoryProvider).getGroupById(groupId);
        if (group != null) {
          showSnackBar(context, 'You have joined the group');
          
          // Check if approval is required
          if (group.isPrivate && group.approveMembers) {
            showSnackBar(context, 'Your request is pending admin approval');
          } else {
            // Try opening the chat again after joining
            final chat = ChatModel(
              id: groupId,
              contactName: group.groupName,
              contactImage: group.groupImage,
              lastMessage: group.lastMessage,
              messageType: '',
              timeSent: group.lastMessageTime,
              unreadCount: 0,
              isGroup: true,
              lastMessageSender: '',
              contactUID: '',
              unreadCountByUser: {},
            );
            _openGroupChat(chat);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error joining group: $e');
      }
    }
  }

  // Empty state widget
  Widget _buildEmptyState() {
    final theme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No groups yet',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new group or join an existing one',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, Constants.createGroupScreen);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Group'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, Constants.joinGroupByCodeScreen);
                },
                icon: const Icon(Icons.link),
                label: const Text('Join by Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  side: BorderSide(color: theme.primaryColor!),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Search results widget
  Widget _buildSearchResults() {
    final theme = context.modernTheme;
    
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.textSecondaryColor?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No groups found',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term or create a new group',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final group = _searchResults[index];
        
        // Check if the current user is already a member
        final isMember = ref.read(groupProvider.notifier).isCurrentUserMember(group.groupId);
        
        return GroupTile(
          group: group,
          onTap: () {
            if (isMember) {
              // Open group directly if already a member
              ref.read(groupProvider.notifier).openGroupChat(group, context);
            } else {
              // Show join dialog if not a member
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Join ${group.groupName}'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('You need to join this group before viewing or sending messages.'),
                      const SizedBox(height: 8),
                      if (group.hasReachedMemberLimit())
                        Text(
                          'This group has reached its member limit of ${GroupModel.MAX_MEMBERS}.',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (group.isPrivate && group.approveMembers)
                        Text(
                          'This is a private group. Your request will need admin approval.',
                          style: TextStyle(
                            color: theme.textSecondaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    if (!group.hasReachedMemberLimit())
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await ref.read(groupProvider.notifier).joinGroup(group.groupId);
                            if (mounted) {
                              if (group.isPrivate && group.approveMembers) {
                                showSnackBar(context, 'Join request sent. Waiting for admin approval.');
                              } else {
                                showSnackBar(context, 'Joined group successfully!');
                                ref.read(groupProvider.notifier).openGroupChat(group, context);
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              showSnackBar(context, 'Error joining group: $e');
                            }
                          }
                        },
                        child: const Text('Join Group'),
                      ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }
}