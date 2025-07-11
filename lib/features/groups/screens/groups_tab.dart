// lib/features/groups/screens/groups_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
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
    
    return Container(
      color: theme.surfaceColor, // Use surfaceColor for entire background
      child: Column(
        children: [
          // Search bar - WhatsApp style
          Container(
            color: theme.surfaceColor,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search groups...',
                  hintStyle: TextStyle(
                    color: theme.textSecondaryColor,
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.textSecondaryColor,
                    size: 22,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16,
                ),
                onChanged: _performSearch,
              ),
            ),
          ),
          
          // Main content
          Expanded(
            child: Container(
              color: theme.surfaceColor,
              child: _searchController.text.isNotEmpty
                  ? _buildSearchResults()
                  : _buildGroupsContent(userGroupsAsync, groupChatsAsync),
            ),
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
            
            // Show a single unified list - WhatsApp style
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
      
      // Create an empty list of members
      final List<UserModel> members = [];
      
      // Open the chat in the chat provider
      await ref.read(chatProvider.notifier).openGroupChat(
        chat.id, 
        members, // Pass empty member list
      );
      
      if (mounted) {
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
          membersUIDs: const [], // Empty list since we don't have participants
          adminsUIDs: const [],
          awaitingApprovalUIDs: const [],
          lastMessage: chat.lastMessage,
          lastMessageSender: chat.lastMessageSender,
          lastMessageTime: chat.lastMessageTime,
          unreadCount: chat.unreadCount,
          unreadCountByUser: Map<String, int>.from(chat.unreadCountByUser),
          createdAt: '',
        );
        
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
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error opening group chat: $e');
      }
    }
  }

  // Empty state widget - WhatsApp style
  Widget _buildEmptyState() {
    final theme = context.modernTheme;
    
    return Container(
      color: theme.surfaceColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 80,
              color: theme.textSecondaryColor!.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No groups yet',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Groups let you chat with multiple people at once. Create one to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Search results widget - WhatsApp style
  Widget _buildSearchResults() {
    final theme = context.modernTheme;
    
    if (_isSearching) {
      return Container(
        color: theme.surfaceColor,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        color: theme.surfaceColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: theme.textSecondaryColor!.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No groups found',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching with different keywords',
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: theme.surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final group = _searchResults[index];
          return GroupTile(
            group: group,
            onTap: () {
              // Open group
              ref.read(groupProvider.notifier).openGroupChat(group, context);
            },
          );
        },
      ),
    );
  }
}