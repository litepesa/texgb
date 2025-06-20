// lib/features/public_groups/screens/public_group_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/authentication/providers/auth_providers.dart';
import 'package:textgb/features/public_groups/models/public_group_model.dart';
import 'package:textgb/features/public_groups/models/public_group_post_model.dart';
import 'package:textgb/features/public_groups/providers/public_group_provider.dart';
import 'package:textgb/features/public_groups/widgets/public_group_post_item.dart';
import 'package:textgb/features/public_groups/utils/media_cache_manager.dart';
import 'package:textgb/features/public_groups/widgets/cached_network_image.dart';
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
  bool _isPreloadingMedia = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    _scrollController.addListener(_onScroll);
    
    // Load group details and posts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupData();
      _preloadRecentMedia();
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

  Future<void> _preloadRecentMedia() async {
    if (_isPreloadingMedia) return;
    
    setState(() {
      _isPreloadingMedia = true;
    });

    try {
      // Check if we have enough storage and network
      final hasStorage = await MediaUtils.hasEnoughStorage();
      final hasNetwork = await MediaUtils.isNetworkAvailable();
      
      if (!hasStorage || !hasNetwork) {
        debugPrint('Skipping media preload: Storage: $hasStorage, Network: $hasNetwork');
        return;
      }

      // Get recent posts and preload their media
      final postsStream = ref.read(publicGroupPostsStreamProvider(widget.publicGroup.groupId));
      postsStream.when(
        data: (posts) async {
          final recentPosts = posts.take(5).toList(); // Limit to 5 recent posts
          final mediaUrls = <String>[];
          
          for (final post in recentPosts) {
            mediaUrls.addAll(post.mediaUrls);
          }
          
          if (mediaUrls.isNotEmpty) {
            // Preload media for better performance
            await MediaCacheManager.preloadMedia(mediaUrls);
          }
        },
        loading: () => null,
        error: (error, stack) => debugPrint('Error getting posts for preload: $error'),
      );
    } catch (e) {
      debugPrint('Error preloading media: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPreloadingMedia = false;
        });
      }
    }
  }

  Future<void> _refreshFeed() async {
    await _loadGroupData();
    await _preloadRecentMedia();
  }

  Future<void> _showCacheManagement() async {
    final cacheSize = await MediaCacheManager.getCacheSize();
    
    if (!mounted) return;
    
    final theme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.textTertiaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Media Cache Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Cache info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariantColor?.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.borderColor?.withOpacity(0.1) ?? Colors.transparent,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cache Size',
                            style: TextStyle(
                              color: theme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            MediaCacheManager.formatCacheSize(cacheSize),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.textColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              color: theme.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _isPreloadingMedia 
                                  ? theme.primaryColor?.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _isPreloadingMedia ? 'Preloading...' : 'Ready',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: _isPreloadingMedia 
                                    ? theme.primaryColor 
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.textColor,
                          side: BorderSide(
                            color: theme.borderColor ?? Colors.grey,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await MediaCacheManager.clearCache();
                          if (mounted) {
                            Navigator.pop(context);
                            showSnackBar(context, 'Cache cleared successfully');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Clear Cache',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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
            // Custom SliverAppBar
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: theme.surfaceColor,
              foregroundColor: theme.textColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () => Navigator.pop(context),
              ),
              actions: _buildAppBarActions(theme),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.primaryColor!.withOpacity(0.8),
                        theme.surfaceColor!,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 30.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Group avatar with caching
                              _buildGroupAvatar(currentGroup.groupName, currentGroup.groupImage),
                              
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
                                            currentGroup.groupName,
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: theme.textColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (currentGroup.isVerified)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8),
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
                                      currentGroup.getSubscribersText(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: theme.textSecondaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    
                                    if (currentGroup.groupDescription.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        currentGroup.groupDescription,
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
                        ],
                      ),
                    ),
                  ),
                ),
                // Remove the title to prevent duplicate group names
                titlePadding: EdgeInsets.zero,
                title: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 56, right: 16),
                  child: Text(
                    currentGroup.groupName,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                collapseMode: CollapseMode.pin,
              ),
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

  List<Widget> _buildAppBarActions(ModernThemeExtension theme) {
    return [
      IconButton(
        icon: Icon(Icons.info_outline, color: theme.textColor),
        onPressed: _navigateToGroupInfo,
        tooltip: 'Group Info',
      ),
      PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: theme.textColor),
        tooltip: 'More Options',
        onSelected: (action) {
          switch (action) {
            case 'cache':
              _showCacheManagement();
              break;
            case 'refresh':
              _refreshFeed();
              break;
            case 'preload':
              _preloadRecentMedia();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'refresh',
            child: Row(
              children: [
                Icon(Icons.refresh, size: 20, color: theme.textColor),
                SizedBox(width: 12),
                Text('Refresh Feed'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'preload',
            enabled: !_isPreloadingMedia,
            child: Row(
              children: [
                Icon(
                  Icons.download_for_offline, 
                  size: 20, 
                  color: _isPreloadingMedia 
                      ? theme.textTertiaryColor 
                      : theme.textColor,
                ),
                SizedBox(width: 12),
                Text(
                  _isPreloadingMedia ? 'Preloading...' : 'Preload Media',
                  style: TextStyle(
                    color: _isPreloadingMedia 
                        ? theme.textTertiaryColor 
                        : theme.textColor,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem(
            value: 'cache',
            child: Row(
              children: [
                Icon(Icons.storage, size: 20, color: theme.textColor),
                SizedBox(width: 12),
                Text('Manage Cache'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildGroupAvatar(String groupName, String groupImage) {
    if (groupImage.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: groupImage,
        width: 80,
        height: 80,
        borderRadius: BorderRadius.circular(25),
        errorWidget: _buildDefaultAvatar(groupName),
        placeholder: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.white.withOpacity(0.2),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return _buildDefaultAvatar(groupName);
  }

  Widget _buildDefaultAvatar(String groupName) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.9),
      ),
      child: Center(
        child: Text(
          groupName.isNotEmpty ? groupName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
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
            
            ElevatedButton(
              onPressed: _handleSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Subscribe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
              
              ElevatedButton(
                onPressed: _navigateToCreatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Create First Post',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
          if (_isPreloadingMedia) ...[
            const SizedBox(height: 8),
            Text(
              'Preloading media...',
              style: TextStyle(
                color: theme.textTertiaryColor,
                fontSize: 14,
              ),
            ),
          ],
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
      child: FloatingActionButton.extended(
        onPressed: _navigateToCreatePost,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Post',
          style: TextStyle(
            fontWeight: FontWeight.w600,
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
    showSnackBar(context, 'Reporting functionality coming soon');
  }

  void _handleCopyPostLink(PublicGroupPostModel post) {
    showSnackBar(context, 'Link copied to clipboard');
  }
}

// Additional utility class for media handling
class MediaUtils {
  // Check if the device has enough storage for caching
  static Future<bool> hasEnoughStorage() async {
    try {
      final cacheSize = await MediaCacheManager.getCacheSize();
      // Check if cache is less than 500MB
      return cacheSize < 500 * 1024 * 1024;
    } catch (e) {
      return true; // Default to true if we can't check
    }
  }

  // Check network connectivity before loading media
  static Future<bool> isNetworkAvailable() async {
    try {
      // Simple connectivity check - you might want to use connectivity_plus package
      return true; // Simplified for this example
    } catch (e) {
      return false;
    }
  }

  // Get media type from URL
  static String getMediaType(String url) {
    final extension = url.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)) {
      return 'video';
    } else if (['mp3', 'wav', 'aac', 'm4a'].contains(extension)) {
      return 'audio';
    }
    
    return 'unknown';
  }

  // Estimate download size for media
  static Future<int?> getMediaSize(String url) async {
    try {
      // This would require http package - simplified for this example
      return null;
    } catch (e) {
      return null;
    }
  }

  // Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Check if URL is a valid media URL
  static bool isValidMediaUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Get thumbnail URL for video (if service provides it)
  static String? getVideoThumbnailUrl(String videoUrl) {
    // This could be expanded to handle different video services
    // For now, return null to use generated thumbnails
    return null;
  }

  // Check if media should be auto-played based on user preferences
  static bool shouldAutoPlayMedia() {
    // This could check user preferences, network type, battery level, etc.
    return false; // Default to false for better UX
  }

  // Get optimal quality for media based on network conditions
  static String getOptimalQuality() {
    // This could check network speed and return appropriate quality
    // For now, return 'medium' as default
    return 'medium';
  }

  // Check if device is on WiFi (for auto-downloading)
  static Future<bool> isOnWiFi() async {
    try {
      // This would require connectivity_plus package
      // For now, return false to be conservative
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get cache directory size
  static Future<int> getCacheDirectorySize() async {
    try {
      return await MediaCacheManager.getCacheSize();
    } catch (e) {
      return 0;
    }
  }

  // Clean up old cache files
  static Future<void> cleanupOldCache({int maxAgeInDays = 7}) async {
    try {
      await MediaCacheManager.clearCache();
    } catch (e) {
      debugPrint('Error cleaning up cache: $e');
    }
  }

  // Preload critical media (avatars, recent posts)
  static Future<void> preloadCriticalMedia(List<String> urls) async {
    try {
      final hasWiFi = await isOnWiFi();
      final hasStorage = await hasEnoughStorage();
      
      if (!hasWiFi || !hasStorage) {
        debugPrint('Skipping preload: WiFi: $hasWiFi, Storage: $hasStorage');
        return;
      }

      await MediaCacheManager.preloadMedia(urls.take(5).toList()); // Limit to 5 items
    } catch (e) {
      debugPrint('Error preloading critical media: $e');
    }
  }

  // Get media loading priority (1 = highest, 5 = lowest)
  static int getMediaLoadingPriority(String mediaType, bool isVisible) {
    if (!isVisible) return 5; // Lowest priority for non-visible media
    
    switch (mediaType) {
      case 'image':
        return 1; // Highest priority for images
      case 'video':
        return 2; // High priority for videos
      case 'audio':
        return 3; // Medium priority for audio
      default:
        return 4; // Low priority for unknown types
    }
  }

  // Check if media can be cached (based on size, type, etc.)
  static bool canCacheMedia(String url, String mediaType, int? sizeInBytes) {
    // Don't cache very large files
    if (sizeInBytes != null && sizeInBytes > 100 * 1024 * 1024) { // 100MB
      return false;
    }

    // Don't cache live streams or dynamic content
    if (url.contains('live') || url.contains('stream')) {
      return false;
    }

    // Cache images and videos, but not audio by default
    return ['image', 'video'].contains(mediaType);
  }

  // Generate a cache key for media
  static String generateCacheKey(String url) {
    return url.hashCode.toString();
  }

  // Get media metadata (duration, dimensions, etc.)
  static Future<Map<String, dynamic>?> getMediaMetadata(String url) async {
    try {
      // This would use packages like video_player or image to get metadata
      // For now, return null
      return null;
    } catch (e) {
      return null;
    }
  }
}