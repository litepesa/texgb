// lib/features/public_groups/screens/my_public_groups_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/features/public_groups/repositories/public_group_repository.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class MyPublicGroupsScreen extends ConsumerStatefulWidget {
  const MyPublicGroupsScreen({super.key});

  @override
  ConsumerState<MyPublicGroupsScreen> createState() => _MyPublicGroupsScreenState();
}

class _MyPublicGroupsScreenState extends ConsumerState<MyPublicGroupsScreen>
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
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        title: Text(
          'My Public Groups',
          style: TextStyle(color: theme.textColor),
        ),
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: theme.textSecondaryColor,
          indicatorColor: theme.primaryColor,
          tabs: const [
            Tab(text: 'Following'),
            Tab(text: 'Created'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowingTab(),
          _buildCreatedTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(theme),
    );
  }

  Widget _buildFollowingTab() {
    final publicGroupsAsync = ref.watch(userPublicGroupsStreamProvider);
    
    return publicGroupsAsync.when(
      data: (publicGroups) {
        if (publicGroups.isEmpty) {
          return _buildEmptyFollowingState();
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userPublicGroupsStreamProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: publicGroups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final publicGroup = publicGroups[index];
              return _buildPublicGroupCard(publicGroup, isOwned: false);
            },
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildCreatedTab() {
    // TODO: This will need a separate provider for user's created groups
    return FutureBuilder<List<PublicGroupModel>>(
      future: _getUserCreatedGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        
        final createdGroups = snapshot.data ?? [];
        
        if (createdGroups.isEmpty) {
          return _buildEmptyCreatedState();
        }
        
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: createdGroups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final publicGroup = createdGroups[index];
              return _buildPublicGroupCard(publicGroup, isOwned: true);
            },
          ),
        );
      },
    );
  }

  Future<List<PublicGroupModel>> _getUserCreatedGroups() async {
    // This would call a repository method to get user's created groups
    // For now, returning empty list as placeholder
    try {
      return await ref.read(publicGroupRepositoryProvider).getUserCreatedPublicGroups();
    } catch (e) {
      return [];
    }
  }

  Widget _buildPublicGroupCard(PublicGroupModel publicGroup, {required bool isOwned}) {
    final theme = context.modernTheme;
    final currentUser = ref.watch(currentUserProvider);
    
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Group Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: theme.primaryColor!.withOpacity(0.1),
                      ),
                      child: publicGroup.groupImage.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
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
                    
                    // Group Info
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: theme.textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (publicGroup.isVerified)
                                Icon(
                                  Icons.verified,
                                  size: 20,
                                  color: theme.primaryColor,
                                ),
                              if (isOwned)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor!.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Owner',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          Text(
                            publicGroup.getSubscribersText(),
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Action Menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: theme.textSecondaryColor,
                      ),
                      onSelected: (value) => _handleMenuAction(value, publicGroup, isOwned),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              Icon(Icons.open_in_new, size: 20),
                              SizedBox(width: 12),
                              Text('Open'),
                            ],
                          ),
                        ),
                        if (isOwned) ...[
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 12),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'analytics',
                            child: Row(
                              children: [
                                Icon(Icons.analytics, size: 20),
                                SizedBox(width: 12),
                                Text('Analytics'),
                              ],
                            ),
                          ),
                        ],
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 20),
                              SizedBox(width: 12),
                              Text('Share'),
                            ],
                          ),
                        ),
                        if (!isOwned)
                          PopupMenuItem(
                            value: 'unfollow',
                            child: Row(
                              children: [
                                Icon(Icons.person_remove, size: 20, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Unfollow', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                
                if (publicGroup.groupDescription.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    publicGroup.groupDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Stats Row
                Row(
                  children: [
                    _buildStatItem(
                      icon: Icons.people_outline,
                      value: publicGroup.subscribersCount.toString(),
                      label: 'Followers',
                      theme: theme,
                    ),
                    const SizedBox(width: 24),
                    _buildStatItem(
                      icon: Icons.post_add,
                      value: '0', // TODO: Add posts count
                      label: 'Posts',
                      theme: theme,
                    ),
                    const Spacer(),
                    if (publicGroup.lastPostAt.isNotEmpty)
                      Text(
                        'Last post ${_formatTime(publicGroup.lastPostAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTertiaryColor,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required ModernThemeExtension theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.textTertiaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(
            fontSize: 13,
            color: theme.textTertiaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupAvatar(String groupName, ModernThemeExtension theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFollowingState() {
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
                Icons.group_outlined,
                size: 56,
                color: theme.textSecondaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No groups followed',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Follow public groups to see them here',
              style: TextStyle(
                fontSize: 16,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, Constants.explorePublicGroupsScreen);
              },
              icon: const Icon(Icons.explore),
              label: const Text('Explore Groups'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCreatedState() {
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
                Icons.add_circle_outline,
                size: 56,
                color: theme.textSecondaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'No groups created',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Create your first public group and start building a community',
              style: TextStyle(
                fontSize: 16,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, Constants.createPublicGroupScreen);
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
          CircularProgressIndicator(color: theme.primaryColor),
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
              style: TextStyle(color: theme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Trigger rebuild
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(ModernThemeExtension theme) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, Constants.createPublicGroupScreen);
      },
      backgroundColor: theme.primaryColor,
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }

  void _openPublicGroup(PublicGroupModel publicGroup) {
    Navigator.pushNamed(
      context,
      Constants.publicGroupFeedScreen,
      arguments: publicGroup,
    );
  }

  void _handleMenuAction(String action, PublicGroupModel publicGroup, bool isOwned) {
    switch (action) {
      case 'open':
        _openPublicGroup(publicGroup);
        break;
      case 'edit':
        Navigator.pushNamed(
          context,
          Constants.editPublicGroupScreen,
          arguments: publicGroup,
        );
        break;
      case 'analytics':
        // TODO: Navigate to analytics screen
        showSnackBar(context, 'Analytics coming soon');
        break;
      case 'share':
        // TODO: Implement sharing
        showSnackBar(context, 'Sharing coming soon');
        break;
      case 'unfollow':
        _showUnfollowDialog(publicGroup);
        break;
    }
  }

  void _showUnfollowDialog(PublicGroupModel publicGroup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unfollow ${publicGroup.groupName}?'),
        content: const Text('You will no longer see posts from this group in your feed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(publicGroupProvider.notifier)
                    .unsubscribeFromPublicGroup(publicGroup.groupId);
                if (mounted) {
                  showSnackBar(context, 'Unfollowed ${publicGroup.groupName}');
                }
              } catch (e) {
                if (mounted) {
                  showSnackBar(context, 'Error unfollowing: $e');
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeString) {
    if (timeString.isEmpty) return '';
    
    final timestamp = int.tryParse(timeString);
    if (timestamp == null) return '';
    
    final postTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(postTime);
    
    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'recently';
    }
  }
}