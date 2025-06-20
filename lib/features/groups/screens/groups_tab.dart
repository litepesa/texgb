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
import 'package:textgb/features/public_groups/screens/public_groups_screen.dart';
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

class _GroupsTabState extends ConsumerState<GroupsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Column(
        children: [
          // Custom app bar with safe area
          Container(
            padding: EdgeInsets.only(
              top: topPadding + 16,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor!.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTitle(theme),
                    ),
                    const SizedBox(width: 16),
                    _buildActionButtons(theme),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Tab Bar
                _buildTabBar(theme),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PrivateGroupsScreen(),
                const PublicGroupsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(ModernThemeExtension theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Groups',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Connect and communicate',
          style: TextStyle(
            fontSize: 15,
            color: theme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () => _showCreateGroupOptions(context),
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 22,
        ),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
      ),
    );
  }

  Widget _buildTabBar(ModernThemeExtension theme) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(2),
        labelColor: Colors.white,
        unselectedLabelColor: theme.textSecondaryColor,
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Private'),
          Tab(text: 'Public'),
        ],
      ),
    );
  }

  void _showCreateGroupOptions(BuildContext context) {
    final theme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textTertiaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Create New Group',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                _buildCreateOption(
                  icon: Icons.lock_outline,
                  title: 'Private Group',
                  subtitle: 'Chat with invited members only',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, Constants.createGroupScreen);
                  },
                ),
                
                const SizedBox(height: 16),
                
                _buildCreateOption(
                  icon: Icons.campaign_outlined,
                  title: 'Public Group',
                  subtitle: 'Share posts with followers',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, Constants.createPublicGroupScreen);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.primaryColor!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.textTertiaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Private Groups Screen (extracted from the old implementation)
class _PrivateGroupsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PrivateGroupsScreen> createState() => _PrivateGroupsScreenState();
}

class _PrivateGroupsScreenState extends ConsumerState<_PrivateGroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<GroupModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final userGroupsAsync = ref.watch(userGroupsStreamProvider);
    final groupChatsAsync = ref.watch(groupChatStreamProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search private groups...',
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
              ? _buildSearchResults(bottomPadding)
              : _buildGroupsContent(userGroupsAsync, groupChatsAsync, bottomPadding),
        ),
      ],
    );
  }

  Widget _buildGroupsContent(
    AsyncValue<List<GroupModel>> userGroupsAsync, 
    AsyncValue<List<ChatModel>> groupChatsAsync,
    double bottomPadding,
  ) {
    final theme = context.modernTheme;
    
    return userGroupsAsync.when(
      data: (userGroups) {
        return groupChatsAsync.when(
          data: (groupChats) {
            final allGroups = _combinePrivateGroups(userGroups, groupChats);
            
            if (allGroups.isEmpty) {
              return _buildEmptyState();
            }
            
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 100),
              itemCount: allGroups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final group = allGroups[index];
                return GroupTile(
                  group: group,
                  onTap: () {
                    ref.read(groupProvider.notifier).openGroupChat(group, context);
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Error loading group chats: $e',
                style: TextStyle(color: theme.textColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Error loading groups: $e',
            style: TextStyle(color: context.modernTheme.textColor),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = context.modernTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_outlined, 
              size: 80, 
              color: theme.textTertiaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No private groups yet',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new group or join an existing one',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, Constants.createGroupScreen);
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create Private Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(double bottomPadding) {
    final theme = context.modernTheme;
    
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: theme.textTertiaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No groups found',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 100),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final group = _searchResults[index];
        return GroupTile(
          group: group,
          onTap: () {
            ref.read(groupProvider.notifier).openGroupChat(group, context);
          },
        );
      },
    );
  }

  List<GroupModel> _combinePrivateGroups(
    List<GroupModel> userGroups,
    List<ChatModel> groupChats,
  ) {
    final allGroups = List<GroupModel>.from(userGroups);
    final groupIds = <String>{};
    
    for (final group in userGroups) {
      groupIds.add(group.groupId);
    }
    
    for (final chat in groupChats) {
      if (!groupIds.contains(chat.id)) {
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
      }
    }
    
    allGroups.sort((a, b) {
      if (a.lastMessageTime.isEmpty) return 1;
      if (b.lastMessageTime.isEmpty) return -1;
      return int.parse(b.lastMessageTime).compareTo(int.parse(a.lastMessageTime));
    });
    
    return allGroups;
  }
}