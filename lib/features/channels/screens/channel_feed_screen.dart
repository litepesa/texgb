// lib/features/channels/screens/channel_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/core/router/app_router.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/models/channel_post_model.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/providers/channel_posts_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

/// Channel feed screen - WhatsApp/Telegram channels style
class ChannelFeedScreen extends ConsumerStatefulWidget {
  final String channelId;

  const ChannelFeedScreen({
    super.key,
    required this.channelId,
  });

  @override
  ConsumerState<ChannelFeedScreen> createState() => _ChannelFeedScreenState();
}

class _ChannelFeedScreenState extends ConsumerState<ChannelFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    final notifier = ref.read(channelPostsProvider(widget.channelId).notifier);
    await notifier.loadMore();

    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refreshFeed() async {
    ref.invalidate(channelProvider(widget.channelId));
    ref.invalidate(channelPostsProvider(widget.channelId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<ModernThemeExtension>()!;
    final channelAsync = ref.watch(channelProvider(widget.channelId));
    final postsAsync = ref.watch(channelPostsProvider(widget.channelId));

    return channelAsync.when(
      data: (channel) {
        if (channel == null) {
          return _buildNotFoundState(theme);
        }

        final isAdmin = channel.isAdmin == true || channel.isOwner == true;

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: _buildAppBar(channel, theme),
          body: RefreshIndicator(
            onRefresh: _refreshFeed,
            color: theme.primaryColor,
            child: postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return _buildEmptyPostsState(channel, theme);
                }

                return ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: posts.length + (_isLoadingMore ? 1 : 0),
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: theme.dividerColor?.withOpacity(0.1),
                  ),
                  itemBuilder: (context, index) {
                    if (index < posts.length) {
                      return _buildPostItem(posts[index], theme);
                    } else if (_isLoadingMore) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: theme.primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              ),
              error: (error, stack) =>
                  _buildErrorState(error.toString(), theme),
            ),
          ),
          floatingActionButton: isAdmin
              ? FloatingActionButton(
                  onPressed: () => _navigateToCreatePost(channel),
                  backgroundColor: theme.primaryColor,
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                )
              : null,
        );
      },
      loading: () => Scaffold(
        backgroundColor: theme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      ),
      error: (error, stack) => _buildNotFoundState(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(
      ChannelModel channel, ModernThemeExtension theme) {
    final isAdmin = channel.isAdmin == true || channel.isOwner == true;

    return AppBar(
      backgroundColor: theme.appBarColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.textColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: InkWell(
        onTap: () => _showChannelInfo(channel, theme),
        child: Row(
          children: [
            // Channel Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.dividerColor?.withOpacity(0.1),
              ),
              child: ClipOval(
                child: channel.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: channel.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.dividerColor?.withOpacity(0.1),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.tv_rounded,
                          size: 18,
                          color: theme.textTertiaryColor,
                        ),
                      )
                    : Icon(
                        Icons.tv_rounded,
                        size: 18,
                        color: theme.textTertiaryColor,
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // Channel Name + Verified
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          channel.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (channel.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '${_formatCount(channel.subscriberCount)} subscribers',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (isAdmin)
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.textColor),
            onPressed: () => _navigateToChannelSettings(channel),
          ),
      ],
    );
  }

  Widget _buildPostItem(ChannelPost post, ModernThemeExtension theme) {
    return InkWell(
      onTap: () => _navigateToPostDetail(post),
      child: Container(
        color: theme.surfaceColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Row(
              children: [
                // Author Info
                Expanded(
                  child: Text(
                    post.authorName ?? 'Unknown Author',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  post.timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTertiaryColor,
                  ),
                ),
                if (post.isPinned) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.push_pin,
                    size: 14,
                    color: theme.textTertiaryColor,
                  ),
                ],
              ],
            ),

            // Post Content
            if (post.text != null && post.text!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                post.text!,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textColor,
                  height: 1.4,
                ),
              ),
            ],

            // Media
            if (post.hasMedia) ...[
              const SizedBox(height: 10),
              _buildMediaPreview(post, theme),
            ],

            // Premium Badge
            if (post.isPremium) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      post.hasUnlocked == true
                          ? Icons.lock_open
                          : Icons.lock_outline,
                      size: 12,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      post.hasUnlocked == true
                          ? 'Unlocked'
                          : '${post.priceCoins} coins to unlock',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Engagement Row
            const SizedBox(height: 10),
            Row(
              children: [
                _buildEngagementStat(
                  Icons.visibility_outlined,
                  _formatCount(post.views),
                  theme,
                ),
                const SizedBox(width: 16),
                _buildEngagementStat(
                  post.hasLiked == true
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  _formatCount(post.likes),
                  theme,
                  isActive: post.hasLiked == true,
                ),
                const SizedBox(width: 16),
                _buildEngagementStat(
                  Icons.comment_outlined,
                  _formatCount(post.commentsCount),
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(ChannelPost post, ModernThemeExtension theme) {
    if (post.isVideo && post.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: post.thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.black12,
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.black12,
                  child: const Icon(Icons.play_circle_outline, size: 50),
                ),
              ),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              if (post.fullDuration != null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      post.formattedDuration,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else if (post.hasImages) {
      final images = post.imageUrls ?? [];
      if (images.isEmpty) return const SizedBox.shrink();

      if (images.length == 1) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: images[0],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: Colors.black12,
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: Colors.black12,
              child: const Icon(Icons.image_outlined, size: 50),
            ),
          ),
        );
      } else {
        return SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  width: 180,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 180,
                    color: Colors.black12,
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 180,
                    color: Colors.black12,
                    child: const Icon(Icons.image_outlined, size: 40),
                  ),
                ),
              );
            },
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildEngagementStat(
    IconData icon,
    String count,
    ModernThemeExtension theme, {
    bool isActive = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isActive ? theme.primaryColor : theme.textTertiaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? theme.primaryColor : theme.textSecondaryColor,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPostsState(
      ChannelModel channel, ModernThemeExtension theme) {
    final canPost = channel.isAdmin == true || channel.isOwner == true;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: theme.textTertiaryColor?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canPost
                  ? 'Share your first update with subscribers'
                  : 'This channel hasn\'t posted anything yet',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(ModernThemeExtension theme) {
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.textTertiaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Channel not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This channel may have been deleted',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
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
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 13,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChannelInfo(ChannelModel channel, ModernThemeExtension theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.dividerColor?.withOpacity(0.1),
              ),
              child: ClipOval(
                child: channel.avatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: channel.avatarUrl!,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.tv_rounded,
                        size: 36,
                        color: theme.textTertiaryColor,
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Name + Verified
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  channel.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                if (channel.isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 20,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              channel.description,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(
                  _formatCount(channel.subscriberCount),
                  'Subscribers',
                  theme,
                ),
                _buildStatColumn(
                  '${channel.postCount}',
                  'Posts',
                  theme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      String value, String label, ModernThemeExtension theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: theme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleSubscription(ChannelModel channel) async {
    HapticFeedback.lightImpact();

    final isSubscribed = channel.isSubscribed ?? false;
    final actionsNotifier = ref.read(channelActionsProvider.notifier);

    final success = isSubscribed
        ? await actionsNotifier.unsubscribe(channel.id)
        : await actionsNotifier.subscribe(channel.id);

    if (success && mounted) {
      ref.invalidate(channelProvider(widget.channelId));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSubscribed
                ? 'Unsubscribed from ${channel.name}'
                : 'Subscribed to ${channel.name}',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update subscription'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToPostDetail(ChannelPost post) {
    context.goToChannelPost(post.id, widget.channelId);
  }

  void _navigateToCreatePost(ChannelModel channel) {
    context.push('/channel/${channel.id}/create-post');
  }

  void _navigateToChannelSettings(ChannelModel channel) {
    context.push('/channel/${channel.id}/settings');
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
