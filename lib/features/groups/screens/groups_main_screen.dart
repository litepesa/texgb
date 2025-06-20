// lib/features/groups/screens/groups_main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/chat/models/chat_model.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/groups/models/group_model.dart';
import 'package:textgb/features/groups/providers/group_provider.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/models/user_model.dart';

class GroupsMainScreen extends ConsumerStatefulWidget {
  const GroupsMainScreen({super.key});

  @override
  ConsumerState<GroupsMainScreen> createState() => _GroupsMainScreenState();
}

class _GroupsMainScreenState extends ConsumerState<GroupsMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: theme.backgroundColor,
              elevation: 0,
              floating: true,
              pinned: true,
              expandedHeight: _isSearchActive ? 140 : 100,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: theme.backgroundColor,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor!.withOpacity(0.1),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Header Row
                          Row(
                            children: [
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _isSearchActive
                                      ? _buildSearchField(theme)
                                      : _buildTitle(theme),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildActionButtons(theme),
                            ],
                          ),
                          
                          // Tab Bar
                          if (!_isSearchActive) ...[
                            const SizedBox(height: 20),
                            _buildTabBar(theme),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _isSearchActive
            ? _buildSearchResults()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildPrivateGroupsList(),
                  _buildPublicGroupsList(),
                ],
              ),
      ),
      floatingActionButton: _buildFloatingActionButton(theme),
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

  Widget _buildSearchField(ModernThemeExtension theme) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.surfaceVariantColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search groups...',
          hintStyle: TextStyle(
            color: theme.textSecondaryColor,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
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
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildActionButtons(ModernThemeExtension theme) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.surfaceVariantColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
              color: theme.textColor,
              size: 22,
            ),
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
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
        ),
      ],
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

  Widget _buildPrivateGroupsList() {
    final groupChatsAsync = ref.watch(groupChatStreamProvider);
    final userGroupsAsync = ref.watch(userGroupsStreamProvider);
    
    return userGroupsAsync.when(
      data: (userGroups) {
        return groupChatsAsync.when(
          data: (groupChats) {
            final privateGroups = _combinePrivateGroups(userGroups, groupChats);
            
            if (privateGroups.isEmpty) {
              return _buildEmptyState(
                icon: Icons.group_outlined,
                title: 'No private groups',
                subtitle: 'Create or join a private group to start chatting',
                actionText: 'Create Private Group',
                onAction: () => Navigator.pushNamed(context, Constants.createGroupScreen),
              );
            }
            
            return _buildGroupsList(privateGroups, isPrivate: true);
          },
          loading: () => _buildLoadingState(),
          error: (e, s) => _buildErrorState('Error loading group chats: $e'),
        );
      },
      loading: () => _buildLoadingState(),
      error: (e, s) => _buildErrorState('Error loading groups: $e'),
    );
  }

  Widget _buildPublicGroupsList() {
    final publicGroupsAsync = ref.watch(userPublicGroupsStreamProvider);
    
    return publicGroupsAsync.when(
      data: (publicGroups) {
        if (publicGroups.isEmpty) {
          return _buildEmptyState(
            icon: Icons.campaign_outlined,
            title: 'No public groups',
            subtitle: 'Join public groups to see posts and updates',
            actionText: 'Explore Public Groups',
            onAction: () => Navigator.pushNamed(context, Constants.explorePublicGroupsScreen),
          );
        }
        
        return _buildPublicGroupsList(publicGroups);
      },
      loading: () => _buildLoadingState(),
      error: (e, s) => _buildErrorState('Error loading public groups: $e'),
    );
  }

  Widget _buildGroupsList(List<GroupModel> groups, {required bool isPrivate}) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: groups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final group = groups[index];
        return _buildGroupItem(group, isPrivate: isPrivate);
      },
    );
  }

  Widget _buildPublicGroupsList(List<PublicGroupModel> publicGroups) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: publicGroups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final publicGroup = publicGroups[index];
        return _buildPublicGroupItem(publicGroup);
      },
    );
  }

  Widget _buildGroupItem(GroupModel group, {required bool isPrivate}) {
    final theme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    
    final unreadCount = currentUser != null 
        ? group.getUnreadCountForUser(currentUser.uid)
        : 0;
    final hasUnread = unreadCount > 0;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnread 
              ? theme.primaryColor!.withOpacity(0.3)
              : theme.borderColor!.withOpacity(0.1),
          width: hasUnread ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openGroup(group, isPrivate: isPrivate),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Group Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.primaryColor!.withOpacity(0.1),
                  ),
                  child: group.groupImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            group.groupImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildGroupAvatar(group.groupName, theme);
                            },
                          ),
                        )
                      : _buildGroupAvatar(group.groupName, theme),
                ),
                
                const SizedBox(width: 16),
                
                // Group Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.groupName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                                color: theme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        group.lastMessage.isNotEmpty
                            ? group.getLastMessagePreview()
                            : group.groupDescription.isNotEmpty
                                ? group.groupDescription
                                : '${group.membersUIDs.length} members',
                        style: TextStyle(
                          fontSize: 15,
                          color: hasUnread 
                              ? theme.textColor!.withOpacity(0.8)
                              : theme.textSecondaryColor,
                          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 6),
                      
                      Row(
                        children: [
                          Icon(
                            isPrivate ? Icons.lock_outline : Icons.public,
                            size: 14,
                            color: theme.textTertiaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${group.membersUIDs.length} members',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTertiaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (group.lastMessageTime.isNotEmpty)
                            Text(
                              _formatTime(group.lastMessageTime),
                              style: TextStyle(
                                fontSize: 13,
                                color: hasUnread 
                                    ? theme.primaryColor
                                    : theme.textTertiaryColor,
                                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPublicGroupItem(PublicGroupModel publicGroup) {
    final theme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.borderColor!.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPublicGroup(publicGroup),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Public Group Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.primaryColor!.withOpacity(0.1),
                  ),
                  child: publicGroup.groupImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            publicGroup.groupImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildGroupAvatar(publicGroup.groupName, theme);
                            },
                          ),
                        )
                      : _buildGroupAvatar(publicGroup.groupName, theme),
                ),
                
                const SizedBox(width: 16),
                
                // Public Group Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              publicGroup.groupName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: theme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (publicGroup.isVerified)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.verified,
                                size: 20,
                                color: theme.primaryColor,
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        publicGroup.groupDescription.isNotEmpty
                            ? publicGroup.groupDescription
                            : 'Public group',
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.textSecondaryColor,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 6),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            size: 14,
                            color: theme.textTertiaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${publicGroup.subscribersCount} followers',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textTertiaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (publicGroup.lastPostAt.isNotEmpty)
                            Text(
                              _formatTime(publicGroup.lastPostAt),
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textTertiaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupAvatar(String groupName, ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor!,
            theme.primaryColor!.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          groupName.isNotEmpty ? groupName[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    final theme = context.modernTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.surfaceVariantColor,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                icon,
                size: 56,
                color: theme.textSecondaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: theme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor!,
                    theme.primaryColor!.withOpacity(0.8),
                  ],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Text(
                      actionText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading groups...',
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = context.modernTheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    // TODO: Implement search results
    return const Center(
      child: Text('Search functionality coming soon'),
    );
  }

  Widget _buildFloatingActionButton(ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.primaryColor!,
            theme.primaryColor!.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor!.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showCreateGroupOptions(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  // Helper methods
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

  void _openGroup(GroupModel group, {required bool isPrivate}) {
    if (isPrivate) {
      ref.read(groupProvider.notifier).openGroupChat(group, context);
    }
  }

  void _openPublicGroup(PublicGroupModel publicGroup) {
    Navigator.pushNamed(
      context,
      Constants.publicGroupFeedScreen,
      arguments: publicGroup,
    );
  }

  String _formatTime(String timeString) {
    if (timeString.isEmpty) return '';
    
    final timestamp = int.tryParse(timeString);
    if (timestamp == null) return '';
    
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(messageTime);
    
    if (difference.inDays > 7) {
      return '${messageTime.day}/${messageTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
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

// Provider to filter only group chats from the chat stream
final groupChatStreamProvider = Provider<AsyncValue<List<ChatModel>>>((ref) {
  final allChats = ref.watch(chatStreamProvider);
  
  return allChats.when(
    data: (chats) => AsyncValue.data(chats.where((chat) => chat.isGroup).toList()),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});