// lib/features/channels/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/models/channel_post_model.dart';
import 'package:textgb/features/channels/providers/channel_posts_provider.dart';
import 'package:textgb/features/channels/theme/channels_theme.dart';

/// Facebook-quality post card widget for channel posts
class PostCard extends ConsumerStatefulWidget {
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
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(
          horizontal: ChannelsTheme.spacingL,
          vertical: ChannelsTheme.spacingS,
        ),
        decoration: ChannelsTheme.cardDecoration(
          boxShadow: _isHovered ? ChannelsTheme.hoverShadow : ChannelsTheme.cardShadow,
        ),
        child: Material(
          color: ChannelsTheme.cardBackground,
          borderRadius: BorderRadius.circular(ChannelsTheme.cardRadius),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(ChannelsTheme.cardRadius),
            splashColor: ChannelsTheme.hoverColor.withOpacity(0.5),
            highlightColor: ChannelsTheme.hoverColor.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Header (author info, timestamp)
                _buildPostHeader(),

                // Post Content
                if (widget.post.text != null && widget.post.text!.isNotEmpty)
                  _buildTextContent(),

                // Media Content (images/videos)
                if (widget.post.mediaUrl != null) _buildMediaContent(),

                // Premium Badge/Unlock
                if (widget.post.isPremium) _buildPremiumSection(),

                // Divider before engagement
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ChannelsTheme.spacingL),
                  child: ChannelsTheme.dividerWidget,
                ),

                // Engagement Bar (likes, comments, shares)
                _buildEngagementBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(ChannelsTheme.spacingL),
      child: Row(
        children: [
          // Channel Avatar
          if (widget.showChannelInfo) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ChannelsTheme.avatarRadius),
                color: ChannelsTheme.hoverColor,
                image: widget.post.channelAvatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.post.channelAvatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.post.channelAvatarUrl == null
                  ? Icon(
                      CupertinoIcons.tv_circle_fill,
                      size: 20,
                      color: ChannelsTheme.textTertiary,
                    )
                  : null,
            ),
            const SizedBox(width: ChannelsTheme.spacingM),
          ],

          // Channel Name + Timestamp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showChannelInfo && widget.post.channelName != null) ...[
                  Text(
                    widget.post.channelName!,
                    style: ChannelsTheme.headingSmall.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  widget.post.timeAgo,
                  style: ChannelsTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Post Type Badge
          _buildContentTypeBadge(),

          // More Options
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: ChannelsTheme.textSecondary,
            ),
            onPressed: _showPostOptions,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildContentTypeBadge() {
    IconData? icon;
    Color? color;

    switch (widget.post.contentType) {
      case PostContentType.text:
        return const SizedBox.shrink();
      case PostContentType.image:
      case PostContentType.textImage:
        icon = Icons.image_outlined;
        color = ChannelsTheme.tiktokCyan;
        break;
      case PostContentType.video:
      case PostContentType.textVideo:
        icon = Icons.play_circle_outline;
        color = ChannelsTheme.tiktokPink;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ChannelsTheme.spacingL,
        0,
        ChannelsTheme.spacingL,
        ChannelsTheme.spacingM,
      ),
      child: Text(
        widget.post.text!,
        style: ChannelsTheme.bodyLarge,
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMediaContent() {
    final isVideo = widget.post.contentType == PostContentType.video ||
        widget.post.contentType == PostContentType.textVideo;
    final isLocked = widget.post.isPremium && widget.post.hasUnlocked != true;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(0),
        topRight: Radius.circular(0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Media thumbnail/preview
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: ChannelsTheme.hoverColor,
              child: widget.post.mediaUrl != null
                  ? Image.network(
                      widget.post.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          isVideo ? Icons.videocam_off : Icons.broken_image,
                          size: 48,
                          color: ChannelsTheme.textTertiary,
                        );
                      },
                    )
                  : Icon(
                      isVideo ? Icons.videocam : Icons.image,
                      size: 48,
                      color: ChannelsTheme.textTertiary,
                    ),
            ),
          ),

          // Video Play Overlay
          if (isVideo && !isLocked)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ChannelsTheme.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 40,
                color: ChannelsTheme.white,
              ),
            ),

          // Premium Lock Overlay (if not unlocked)
          if (isLocked)
            Container(
              color: ChannelsTheme.black.withOpacity(0.75),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 56,
                    color: ChannelsTheme.tiktokPink,
                  ),
                  const SizedBox(height: ChannelsTheme.spacingM),
                  const Text(
                    'Premium Content',
                    style: TextStyle(
                      color: ChannelsTheme.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: ChannelsTheme.spacingXs),
                  if (widget.post.previewDuration != null &&
                      widget.post.previewDuration! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ChannelsTheme.spacingM,
                        vertical: ChannelsTheme.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: ChannelsTheme.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Preview: ${_formatDuration(widget.post.previewDuration!)}',
                        style: ChannelsTheme.bodySmall.copyWith(
                          color: ChannelsTheme.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumSection() {
    final hasUnlocked = widget.post.hasUnlocked ?? false;

    return Container(
      margin: const EdgeInsets.all(ChannelsTheme.spacingL),
      padding: const EdgeInsets.all(ChannelsTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ChannelsTheme.tiktokPink.withOpacity(0.1),
            ChannelsTheme.tiktokCyan.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(ChannelsTheme.cardRadius),
        border: Border.all(
          color: hasUnlocked ? ChannelsTheme.success : ChannelsTheme.tiktokPink,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(ChannelsTheme.spacingS),
            decoration: BoxDecoration(
              color: hasUnlocked
                  ? ChannelsTheme.success
                  : ChannelsTheme.tiktokPink,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              hasUnlocked ? Icons.lock_open : Icons.star,
              color: ChannelsTheme.white,
              size: 20,
            ),
          ),
          const SizedBox(width: ChannelsTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUnlocked ? 'Premium Content Unlocked' : 'Premium Content',
                  style: ChannelsTheme.headingSmall.copyWith(
                    fontSize: 14,
                    color: hasUnlocked
                        ? ChannelsTheme.success
                        : ChannelsTheme.tiktokPink,
                  ),
                ),
                if (!hasUnlocked && widget.post.priceCoins != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${widget.post.priceCoins} coins to unlock full content',
                    style: ChannelsTheme.bodySmall,
                  ),
                ],
                if (widget.post.fileSize != null ||
                    widget.post.fullDuration != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (widget.post.fullDuration != null) ...[
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: ChannelsTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(widget.post.fullDuration!),
                          style: ChannelsTheme.caption,
                        ),
                      ],
                      if (widget.post.fileSize != null) ...[
                        if (widget.post.fullDuration != null)
                          const Text(' • ', style: ChannelsTheme.caption),
                        Icon(
                          Icons.file_present,
                          size: 12,
                          color: ChannelsTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.post.fileSizeFormatted,
                          style: ChannelsTheme.caption,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!hasUnlocked && widget.post.priceCoins != null) ...[
            const SizedBox(width: ChannelsTheme.spacingS),
            ElevatedButton(
              onPressed: _unlockPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: ChannelsTheme.tiktokPink,
                foregroundColor: ChannelsTheme.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: ChannelsTheme.spacingL,
                  vertical: ChannelsTheme.spacingS,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ChannelsTheme.buttonRadius),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_open, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Unlock',
                    style: ChannelsTheme.buttonText.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEngagementBar() {
    final isLiked = widget.post.hasLiked ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ChannelsTheme.spacingL,
        vertical: ChannelsTheme.spacingM,
      ),
      child: Row(
        children: [
          // Like Button
          ChannelsTheme.engagementButton(
            icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
            label: _formatCount(widget.post.likes),
            onTap: _toggleLike,
            isActive: isLiked,
            activeColor: ChannelsTheme.facebookBlue,
          ),

          // Comment Button
          ChannelsTheme.engagementButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(widget.post.commentsCount),
            onTap: widget.onTap ?? () {},
            isActive: false,
          ),

          // Share Button
          ChannelsTheme.engagementButton(
            icon: Icons.share_outlined,
            label: _formatCount(widget.post.shares),
            onTap: _sharePost,
            isActive: false,
          ),

          const Spacer(),

          // Views Count
          if (widget.post.views > 0) ...[
            Icon(
              Icons.visibility_outlined,
              size: 16,
              color: ChannelsTheme.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              _formatCount(widget.post.views),
              style: ChannelsTheme.bodySmall,
            ),
          ],

          // Unlocks Count (for premium)
          if (widget.post.isPremium && widget.post.unlocksCount > 0) ...[
            const SizedBox(width: ChannelsTheme.spacingM),
            Icon(
              Icons.lock_open,
              size: 16,
              color: ChannelsTheme.tiktokPink,
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.post.unlocksCount}',
              style: ChannelsTheme.bodySmall.copyWith(
                color: ChannelsTheme.tiktokPink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Action methods
  Future<void> _toggleLike() async {
    final isLiked = widget.post.hasLiked ?? false;
    final actionsNotifier = ref.read(channelPostActionsProvider.notifier);

    if (isLiked) {
      await actionsNotifier.unlikePost(widget.post.id, widget.channelId);
    } else {
      await actionsNotifier.likePost(widget.post.id, widget.channelId);
    }
  }

  Future<void> _unlockPost() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ChannelsTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChannelsTheme.cardRadius),
        ),
        title: Text(
          'Unlock Premium Content',
          style: ChannelsTheme.headingMedium,
        ),
        content: Text(
          'Unlock this post for ${widget.post.priceCoins} coins?\n\n'
          'This will deduct coins from your wallet.',
          style: ChannelsTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: ChannelsTheme.secondaryButtonStyle,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ChannelsTheme.accentButtonStyle,
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Unlock post
    final actionsNotifier = ref.read(channelPostActionsProvider.notifier);
    final success = await actionsNotifier.unlockPost(widget.post.id, widget.channelId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Content unlocked successfully!'
                : 'Failed to unlock content. Please try again.',
          ),
          backgroundColor: success
              ? ChannelsTheme.success
              : ChannelsTheme.error,
        ),
      );
    }
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ChannelsTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ChannelsTheme.cardRadius),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.share, color: ChannelsTheme.textPrimary),
              title: Text('Share', style: ChannelsTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _sharePost();
              },
            ),
            ListTile(
              leading: Icon(Icons.bookmark_outline, color: ChannelsTheme.textPrimary),
              title: Text('Save', style: ChannelsTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement save
              },
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: ChannelsTheme.error),
              title: Text('Report', style: ChannelsTheme.bodyLarge.copyWith(
                color: ChannelsTheme.error,
              )),
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

  void _sharePost() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: ChannelsTheme.textSecondary,
      ),
    );
  }

  // Helper methods
  String _formatCount(int count) {
    if (count >= 1000000) {
      final millions = count / 1000000;
      return millions % 1 == 0
          ? '${millions.toInt()}M'
          : '${millions.toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      final thousands = count / 1000;
      return thousands % 1 == 0
          ? '${thousands.toInt()}K'
          : '${thousands.toStringAsFixed(1)}K';
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
