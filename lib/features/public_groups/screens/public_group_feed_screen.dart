// lib/features/public_groups/screens/public_group_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/models/public_group_post_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/features/public_groups/widgets/public_group_app_bar.dart';
import 'package:textgb/features/public_groups/widgets/public_group_post_item.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class PublicGroupFeedScreen extends ConsumerStatefulWidget {
  final PublicGroupModel publicGroup;

  const PublicGroupFeedScreen({
    super.key,
    required this.publicGroup,
  });

  @override
  ConsumerState<PublicGroupFeedScreen> createState() => _PublicGroupFeedScreenState();
}

class _PublicGroupFeedScreenState extends ConsumerState<PublicGroupFeedScreen>
    with AutomaticKeepAliveClientMixin {
  
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _showCreatePostButton = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    _scrollController.addListener(_onScroll);
    
    // Load group details and posts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Show/hide create post button based on scroll position
    final showButton = _scrollController.offset > 100;
    if (showButton != _showCreatePostButton) {
      setState(() {
        _showCreatePostButton = showButton;
      });
    }
  }

  Future<void> _loadGroupData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(publicGroupProvider.notifier).getPublicGroupDetails(widget.publicGroup.groupId);
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error loading group: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshFeed() async {
    await _loadGroupData();
  }

  void _navigateToCreatePost() {
    Navigator.pushNamed(
      context,
      Constants.createPublicGroupPostScreen,
      arguments: widget.publicGroup,
    );
  }

  void _navigateToGroupInfo() {
    Navigator.pushNamed(
      context,
      Constants.publicGroupInfoScreen,
      arguments: widget.publicGroup,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final theme = context.modernTheme;
    final publicGroupState = ref.watch(publicGroupProvider);
    
    // Watch posts stream for current group
    final postsStream = ref.watch(publicGroupPostsStreamProvider(widget.publicGroup.groupId));
    
    final currentGroup = publicGroupState.valueOrNull?.currentPublicGroup ?? widget.publicGroup;
    final currentUser = ref.watch(currentUserProvider);
    
    final canPost = currentUser != null && currentGroup.canPost(currentUser.uid);
    final isSubscribed = currentUser != null && currentGroup.isSubscriber(currentUser.uid);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            PublicGroupAppBar(
              publicGroup: currentGroup,
              onBack: () => Navigator.pop(context),
              onInfo: _navigateToGroupInfo,
            ),
          ];
        },
        body: _isLoading
            ? _buildLoadingState(theme)
            : postsStream.when(
                data: (posts) => _buildFeedContent(posts, currentGroup, theme, isSubscribed),
                loading: () => _buildLoadingState(theme),
                error: (error, stack) => _buildErrorState(error.toString(), theme),
              ),
      ),
      floatingActionButton: canPost ? _buildFloatingActionButton(theme) : null,
    );
  }

  Widget _buildFeedContent(
    List<PublicGroupPostModel> posts,
    PublicGroupModel group,
    ModernThemeExtension theme,
    bool isSubscribed,
  ) {
    if (!isSubscribed) {
      return _buildSubscriptionPrompt(group, theme);
    }

    if (posts.isEmpty) {
      return _buildEmptyFeed(group, theme);
    }

    return RefreshIndicator(
      onRefresh: _refreshFeed,
      color: theme.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Group info header
          SliverToBoxAdapter(
            child: _buildGroupHeader(group, theme),
          ),
          
          // Posts list
          SliverList.separated(
            itemCount: posts.length,
            separatorBuilder: (context, index) => Container(
              height: 8,
              color: theme.surfaceVariantColor?.withOpacity(0.3),
            ),
            itemBuilder: (context, index) {
              final post = posts[index];
              return PublicGroupPostItem(
                post: post,
                publicGroup: group,
                onReaction: (emoji) => _handlePostReaction(post, emoji),
                onComment: () => _navigateToComments(post),
                onShare: () => _handlePostShare(post),
                onMenuAction: (action) => _handlePostMenuAction(post, action),
              );
            },
          ),
          
          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(PublicGroupModel group, ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor!.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Group avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: theme.primaryColor!.withOpacity(0.1),
            ),
            child: group.groupImage.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
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
          
          // Group info
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
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: theme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (group.isVerified)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.verified,
                          size: 24,
                          color: theme.primaryColor,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  group.getSubscribersText(),
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                if (group.groupDescription.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    group.groupDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildSubscriptionPrompt(PublicGroupModel group, ModernThemeExtension theme) {
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
                Icons.campaign_outlined,
                size: 56,
                color: theme.textSecondaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Subscribe to ${group.groupName}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Follow this public group to see posts and updates',
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
                  onTap: _handleSubscribe,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: Text(
                      'Subscribe',
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

  Widget _buildEmptyFeed(PublicGroupModel group, ModernThemeExtension theme) {
    final currentUser = ref.watch(currentUserProvider);
    final canPost = currentUser != null && group.canPost(currentUser.uid);
    
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
                Icons.post_add_outlined,
                size: 56,
                color: theme.textSecondaryColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              canPost ? 'No posts yet' : 'No posts to show',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.textColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              canPost 
                  ? 'Be the first to share something with your followers'
                  : 'Check back later for new posts from this group',
              style: TextStyle(
                fontSize: 16,
                color: theme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (canPost) ...[
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
                    onTap: _navigateToCreatePost,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Text(
                        'Create First Post',
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
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ModernThemeExtension theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading posts...',
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, ModernThemeExtension theme) {
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshFeed,
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
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      offset: _showCreatePostButton ? Offset.zero : const Offset(0, 2),
      child: Container(
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
        child: FloatingActionButton.extended(
          onPressed: _navigateToCreatePost,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(
            Icons.add_rounded,
            color: Colors.white,
          ),
          label: const Text(
            'Post',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // Event handlers
  Future<void> _handleSubscribe() async {
    try {
      await ref.read(publicGroupProvider.notifier).subscribeToPublicGroup(widget.publicGroup.groupId);
      if (mounted) {
        showSnackBar(context, 'Subscribed to ${widget.publicGroup.groupName}');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error subscribing: $e');
      }
    }
  }

  Future<void> _handlePostReaction(PublicGroupPostModel post, String emoji) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;
      
      final hasReaction = post.hasUserReacted(currentUser.uid);
      final hasSameReaction = hasReaction && post.getUserReaction(currentUser.uid) == emoji;
      
      if (hasSameReaction) {
        await ref.read(publicGroupProvider.notifier).removePostReaction(post.postId);
      } else {
        await ref.read(publicGroupProvider.notifier).addPostReaction(post.postId, emoji);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error reacting to post: $e');
      }
    }
  }

  void _navigateToComments(PublicGroupPostModel post) {
    Navigator.pushNamed(
      context,
      Constants.publicGroupPostCommentsScreen,
      arguments: {
        'post': post,
        'publicGroup': widget.publicGroup,
      },
    );
  }

  void _handlePostShare(PublicGroupPostModel post) {
    // TODO: Implement post sharing
    showSnackBar(context, 'Sharing functionality coming soon');
  }

  void _handlePostMenuAction(PublicGroupPostModel post, String action) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    switch (action) {
      case 'pin':
        _handleTogglePin(post);
        break;
      case 'edit':
        _handleEditPost(post);
        break;
      case 'delete':
        _handleDeletePost(post);
        break;
      case 'report':
        _handleReportPost(post);
        break;
      case 'copy_link':
        _handleCopyPostLink(post);
        break;
    }
  }

  Future<void> _handleTogglePin(PublicGroupPostModel post) async {
    try {
      await ref.read(publicGroupProvider.notifier).togglePostPin(post.postId, !post.isPinned);
      if (mounted) {
        showSnackBar(context, post.isPinned ? 'Post unpinned' : 'Post pinned');
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error ${post.isPinned ? 'unpinning' : 'pinning'} post: $e');
      }
    }
  }

  void _handleEditPost(PublicGroupPostModel post) {
    Navigator.pushNamed(
      context,
      Constants.editPublicGroupPostScreen,
      arguments: {
        'post': post,
        'publicGroup': widget.publicGroup,
      },
    );
  }

  Future<void> _handleDeletePost(PublicGroupPostModel post) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await ref.read(publicGroupProvider.notifier).deletePost(post.postId);
        if (mounted) {
          showSnackBar(context, 'Post deleted');
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Error deleting post: $e');
        }
      }
    }
  }

  void _handleReportPost(PublicGroupPostModel post) {
    // TODO: Implement post reporting
    showSnackBar(context, 'Reporting functionality coming soon');
  }

  void _handleCopyPostLink(PublicGroupPostModel post) {
    // TODO: Implement copy post link
    showSnackBar(context, 'Link copied to clipboard');
  }
}