// lib/features/channels/screens/channel_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/core/router/app_router.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/models/channel_post_model.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/providers/channel_posts_provider.dart';
import 'package:textgb/features/channels/theme/channels_theme.dart';

/// Channel detail screen showing channel info and posts
class ChannelDetailScreen extends ConsumerStatefulWidget {
  final String channelId;

  const ChannelDetailScreen({
    super.key,
    required this.channelId,
  });

  @override
  ConsumerState<ChannelDetailScreen> createState() => _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends ConsumerState<ChannelDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    final notifier = ref.read(channelPostsProvider(widget.channelId).notifier);
    await notifier.loadMore();

    setState(() => _isLoadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final channelAsync = ref.watch(channelProvider(widget.channelId));
    final postsAsync = ref.watch(channelPostsProvider(widget.channelId));

    return Scaffold(
      backgroundColor: ChannelsTheme.screenBackground,
      body: channelAsync.when(
        data: (channel) {
          if (channel == null) {
            return _buildNotFoundState();
          }

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Channel Header
              _buildChannelHeader(channel),

              // Posts List
              postsAsync.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyPostsState(channel),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < posts.length) {
                          return _buildPostCard(posts[index]);
                        } else if (_isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return null;
                      },
                      childCount: posts.length + (_isLoadingMore ? 1 : 0),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: _buildErrorState(error.toString()),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
      floatingActionButton: channelAsync.maybeWhen(
        data: (channel) {
          if (channel == null) return null;

          // Show post button only for admins/moderators/owner
          if (channel.isAdmin == true || channel.isModerator == true) {
            return FloatingActionButton(
              onPressed: () => _navigateToCreatePost(channel),
              child: const Icon(Icons.add),
            );
          }
          return null;
        },
        orElse: () => null,
      ),
    );
  }

  Widget _buildChannelHeader(ChannelModel channel) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          children: [
            const SizedBox(height: 80), // Toolbar space
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ChannelsTheme.hoverColor,
                image: channel.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(channel.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: channel.avatarUrl == null
                  ? const Icon(
                      CupertinoIcons.tv_circle_fill,
                      size: 40,
                      color: ChannelsTheme.textSecondary,
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // Name + Verified Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    channel.name,
                    style: ChannelsTheme.headingMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (channel.isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified,
                    color: ChannelsTheme.facebookBlue,
                    size: 20,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                channel.description,
                style: ChannelsTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStat(
                  icon: CupertinoIcons.person_2_fill,
                  label: _formatCount(channel.subscriberCount),
                  subtitle: 'subscribers',
                ),
                const SizedBox(width: 24),
                _buildStat(
                  icon: CupertinoIcons.square_grid_2x2_fill,
                  label: '${channel.postCount}',
                  subtitle: 'posts',
                ),
                if (channel.unreadCount > 0) ...[
                  const SizedBox(width: 24),
                  _buildStat(
                    icon: CupertinoIcons.bell_fill,
                    label: '${channel.unreadCount}',
                    subtitle: 'unread',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildActionButtons(channel),
            ),
          ],
        ),
      ),
      actions: [
        if (channel.isAdmin == true || channel.isModerator == true)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToChannelSettings(channel),
          ),
      ],
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: ChannelsTheme.textSecondary),
        const SizedBox(height: 4),
        Text(
          label,
          style: ChannelsTheme.headingSmall.copyWith(fontSize: 16),
        ),
        Text(
          subtitle,
          style: ChannelsTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActionButtons(ChannelModel channel) {
    final isSubscribed = channel.isSubscribed ?? false;
    final isOwnerOrAdmin = channel.isAdmin == true;

    if (isOwnerOrAdmin) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _navigateToChannelSettings(channel),
              icon: const Icon(Icons.settings),
              label: const Text('Manage Channel'),
              style: ChannelsTheme.primaryButtonStyle.copyWith(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _toggleSubscription(channel),
            icon: Icon(isSubscribed ? Icons.check : Icons.add),
            label: Text(isSubscribed ? 'Subscribed' : 'Subscribe'),
            style: isSubscribed
                ? ChannelsTheme.secondaryButtonStyle.copyWith(
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                : ChannelsTheme.primaryButtonStyle.copyWith(
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
          ),
        ),
        if (channel.type == ChannelType.premium && !isSubscribed) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: ChannelsTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(ChannelsTheme.cardRadius),
              border: Border.all(color: ChannelsTheme.warning),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: ChannelsTheme.warning, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${channel.subscriptionPriceCoins} coins',
                  style: ChannelsTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ChannelsTheme.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPostCard(ChannelPost post) {
    // TODO: Replace with actual PostCard widget
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: ChannelsTheme.cardBackground,
      child: InkWell(
        onTap: () => _navigateToPostDetail(post),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.text != null) ...[
                Text(
                  post.text!,
                  style: ChannelsTheme.bodyLarge,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              if (post.isPremium) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ChannelsTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: ChannelsTheme.warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Premium - ${post.priceCoins} coins',
                        style: ChannelsTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ChannelsTheme.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  const Icon(Icons.thumb_up_outlined, size: 16, color: ChannelsTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likes}',
                    style: ChannelsTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.comment_outlined, size: 16, color: ChannelsTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: ChannelsTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPostsState(ChannelModel channel) {
    final canPost = channel.isAdmin == true || channel.isModerator == true;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add_outlined,
              size: 80,
              color: ChannelsTheme.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: ChannelsTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              canPost
                  ? 'Be the first to post in this channel'
                  : 'Check back later for new posts',
              style: ChannelsTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tv_off,
              size: 80,
              color: ChannelsTheme.textTertiary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Channel not found',
              style: ChannelsTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'This channel may have been deleted or is no longer available',
              style: ChannelsTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ChannelsTheme.primaryButtonStyle,
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: ChannelsTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: ChannelsTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: ChannelsTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(channelProvider(widget.channelId));
                ref.invalidate(channelPostsProvider(widget.channelId));
              },
              style: ChannelsTheme.primaryButtonStyle,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  Future<void> _toggleSubscription(ChannelModel channel) async {
    final isSubscribed = channel.isSubscribed ?? false;
    final actionsNotifier = ref.read(channelActionsProvider.notifier);

    final success = isSubscribed
        ? await actionsNotifier.unsubscribe(channel.id)
        : await actionsNotifier.subscribe(channel.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSubscribed
                ? 'Unsubscribed from ${channel.name}'
                : 'Subscribed to ${channel.name}',
          ),
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update subscription. Please try again.'),
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
