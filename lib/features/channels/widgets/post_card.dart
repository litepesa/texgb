// lib/features/channels/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/models/channel_post_model.dart';
import 'package:textgb/features/channels/providers/channel_posts_provider.dart';

/// Post card widget for channel posts
class PostCard extends ConsumerWidget {
  final ChannelPost post;
  final String channelId;
  final VoidCallback? onTap;
  final bool showChannelInfo;

  const PostCard({
    super.key,
    required this.post,
    required this.channelId,
    this.onTap,
    this.showChannelInfo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header (author info, timestamp)
            _buildPostHeader(context),

            // Post Content
            if (post.text != null && post.text!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  post.text!,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Media Content (images/videos)
            if (post.mediaUrl != null) _buildMediaContent(context),

            // Premium Badge/Unlock
            if (post.isPremium) _buildPremiumSection(context, ref),

            // Engagement Bar (likes, comments, shares)
            _buildEngagementBar(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Channel Avatar
          if (showChannelInfo) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                image: post.channelAvatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(post.channelAvatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: post.channelAvatarUrl == null
                  ? Icon(
                      CupertinoIcons.tv_circle_fill,
                      size: 20,
                      color: Colors.grey[600],
                    )
                  : null,
            ),
            const SizedBox(width: 12),
          ],

          // Channel Name + Timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showChannelInfo && post.channelName != null) ...[
                  Text(
                    post.channelName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  post.timeAgo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Post Type Badge
          _buildContentTypeBadge(),

          // More Options
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showPostOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeBadge() {
    IconData icon;
    Color color;

    switch (post.contentType) {
      case PostContentType.text:
        return const SizedBox.shrink();
      case PostContentType.image:
        icon = Icons.image;
        color = Colors.blue;
        break;
      case PostContentType.video:
        icon = Icons.play_circle_outline;
        color = Colors.red;
        break;
      case PostContentType.textImage:
        icon = Icons.image;
        color = Colors.blue;
        break;
      case PostContentType.textVideo:
        icon = Icons.play_circle_outline;
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildMediaContent(BuildContext context) {
    final isVideo = post.contentType == PostContentType.video ||
        post.contentType == PostContentType.textVideo;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Media thumbnail/preview
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.grey[300],
            child: post.mediaUrl != null
                ? Image.network(
                    post.mediaUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        isVideo ? Icons.videocam_off : Icons.broken_image,
                        size: 40,
                        color: Colors.grey[600],
                      );
                    },
                  )
                : Icon(
                    isVideo ? Icons.videocam : Icons.image,
                    size: 40,
                    color: Colors.grey[600],
                  ),
          ),
        ),

        // Video Play Overlay
        if (isVideo)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              size: 40,
              color: Colors.white,
            ),
          ),

        // Premium Lock Overlay (if not unlocked)
        if (post.isPremium && post.hasUnlocked != true)
          Container(
            color: Colors.black.withOpacity(0.6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock,
                  size: 48,
                  color: Colors.amber,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Premium Content',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (post.previewDuration != null && post.previewDuration! > 0)
                  Text(
                    'Preview: ${_formatDuration(post.previewDuration!)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumSection(BuildContext context, WidgetRef ref) {
    final hasUnlocked = post.hasUnlocked ?? false;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUnlocked
                      ? 'Premium Content (Unlocked)'
                      : 'Premium Content',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                if (!hasUnlocked && post.priceCoins != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${post.priceCoins} coins to unlock',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                if (post.fileSize != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Size: ${post.fileSizeFormatted}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (post.fullDuration != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Duration: ${_formatDuration(post.fullDuration!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!hasUnlocked && post.priceCoins != null) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _unlockPost(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Unlock'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEngagementBar(BuildContext context, WidgetRef ref) {
    final isLiked = post.hasLiked ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          // Like Button
          IconButton(
            onPressed: () => _toggleLike(ref),
            icon: Icon(
              isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
              color:
                  isLiked ? Theme.of(context).primaryColor : Colors.grey[600],
            ),
          ),
          Text(
            '${post.likes}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),

          // Comment Button
          IconButton(
            onPressed: onTap,
            icon: Icon(Icons.comment_outlined, color: Colors.grey[600]),
          ),
          Text(
            '${post.commentsCount}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),

          // Share Button
          IconButton(
            onPressed: () => _sharePost(context),
            icon: Icon(Icons.share_outlined, color: Colors.grey[600]),
          ),
          Text(
            '${post.shares}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),

          const Spacer(),

          // Views Count
          if (post.views > 0) ...[
            Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              _formatCount(post.views),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],

          // Unlocks Count (for premium)
          if (post.isPremium && post.unlocksCount > 0) ...[
            const SizedBox(width: 12),
            Icon(Icons.lock_open, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${post.unlocksCount}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  // Action methods
  Future<void> _toggleLike(WidgetRef ref) async {
    final isLiked = post.hasLiked ?? false;
    final actionsNotifier = ref.read(channelPostActionsProvider.notifier);

    if (isLiked) {
      await actionsNotifier.unlikePost(post.id, channelId);
    } else {
      await actionsNotifier.likePost(post.id, channelId);
    }
  }

  Future<void> _unlockPost(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Premium Content'),
        content: Text(
          'Unlock this post for ${post.priceCoins} coins?\n\n'
          'This will deduct coins from your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Unlock post
    final actionsNotifier = ref.read(channelPostActionsProvider.notifier);
    final success = await actionsNotifier.unlockPost(post.id, channelId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Content unlocked successfully!'
                : 'Failed to unlock content. Please try again.',
          ),
        ),
      );
    }
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                _sharePost(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Save'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement save
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement report
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  // Helper methods
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}
