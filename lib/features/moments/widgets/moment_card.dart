// ===============================
// Moment Card Widget
// Single moment display in feed
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';
import 'package:textgb/features/moments/services/moments_time_service.dart';
import 'package:textgb/features/moments/widgets/moment_media_grid.dart';
import 'package:textgb/features/moments/widgets/moment_interactions.dart';
import 'package:textgb/features/moments/widgets/comment_list.dart';
import 'package:textgb/features/moments/providers/moments_providers.dart';

class MomentCard extends ConsumerStatefulWidget {
  final MomentModel moment;
  final VoidCallback? onTap;
  final bool showComments;

  const MomentCard({
    Key? key,
    required this.moment,
    this.onTap,
    this.showComments = true,
  }) : super(key: key);

  @override
  ConsumerState<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends ConsumerState<MomentCard> {
  bool _showAllComments = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: MomentsTheme.momentCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          _buildUserHeader(),

          // Content text
          if (widget.moment.content != null && widget.moment.content!.isNotEmpty)
            _buildContentText(),

          // Media (images/video)
          if (widget.moment.mediaUrls.isNotEmpty) _buildMedia(),

          // Location tag
          if (widget.moment.location != null) _buildLocation(),

          // Interactions (likes, comments)
          MomentInteractions(
            moment: widget.moment,
            onLike: () => _handleLike(),
            onComment: () => _handleComment(),
          ),

          // Comments preview
          if (widget.showComments && widget.moment.commentsPreview.isNotEmpty)
            _buildCommentsSection(),
        ],
      ),
    );
  }

  // User header with avatar and name
  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.all(MomentsTheme.paddingLarge),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _navigateToUserProfile(),
            child: CircleAvatar(
              radius: MomentsTheme.avatarSizeMedium / 2,
              backgroundImage: CachedNetworkImageProvider(
                widget.moment.userAvatar,
              ),
            ),
          ),
          const SizedBox(width: MomentsTheme.paddingMedium),

          // Name and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.moment.userName,
                  style: MomentsTheme.userNameStyle,
                ),
                const SizedBox(height: 2),
                Text(
                  MomentsTimeService.formatMomentTime(widget.moment.createdAt),
                  style: MomentsTheme.timestampStyle,
                ),
              ],
            ),
          ),

          // More options
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _showMoreOptions(),
            iconSize: MomentsTheme.iconSizeMedium,
            color: MomentsTheme.lightTextSecondary,
          ),
        ],
      ),
    );
  }

  // Content text
  Widget _buildContentText() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MomentsTheme.paddingLarge,
        vertical: MomentsTheme.paddingSmall,
      ),
      child: Text(
        widget.moment.content!,
        style: MomentsTheme.contentStyle,
      ),
    );
  }

  // Media (images or video)
  Widget _buildMedia() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: MomentsTheme.paddingSmall,
      ),
      child: MomentMediaGrid(
        moment: widget.moment,
      ),
    );
  }

  // Location tag
  Widget _buildLocation() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MomentsTheme.paddingLarge,
        vertical: MomentsTheme.paddingSmall,
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: MomentsTheme.iconSizeSmall,
            color: MomentsTheme.lightTextTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            widget.moment.location!,
            style: MomentsTheme.timestampStyle,
          ),
        ],
      ),
    );
  }

  // Comments section
  Widget _buildCommentsSection() {
    return Container(
      margin: const EdgeInsets.only(
        left: MomentsTheme.paddingLarge,
        right: MomentsTheme.paddingLarge,
        bottom: MomentsTheme.paddingMedium,
        top: MomentsTheme.paddingSmall,
      ),
      padding: const EdgeInsets.all(MomentsTheme.paddingMedium),
      decoration: BoxDecoration(
        color: MomentsTheme.lightBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Likes preview
          if (widget.moment.likesPreview.isNotEmpty) _buildLikesPreview(),

          // Comments preview
          CommentList(
            comments: _showAllComments
                ? widget.moment.commentsPreview
                : widget.moment.commentsPreview.take(2).toList(),
            momentId: widget.moment.id,
            compact: true,
          ),

          // Show more comments
          if (widget.moment.commentsCount > 2 && !_showAllComments)
            GestureDetector(
              onTap: () => _navigateToComments(),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'View all ${widget.moment.commentsCount} comments',
                  style: MomentsTheme.timestampStyle.copyWith(
                    color: MomentsTheme.primaryBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Likes preview
  Widget _buildLikesPreview() {
    final likers = widget.moment.likesPreview.take(3).toList();
    final names = likers.map((l) => l.userName).join(', ');
    final remaining = widget.moment.likesCount - likers.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.favorite,
            size: 14,
            color: MomentsTheme.likeRed,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              remaining > 0
                  ? '$names and $remaining ${remaining == 1 ? 'other' : 'others'}'
                  : names,
              style: MomentsTheme.commentStyle.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Handle like
  Future<void> _handleLike() async {
    try {
      await ref.read(momentsFeedProvider.notifier).toggleLike(
            widget.moment.id,
            widget.moment.isLikedByMe,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like: $e')),
        );
      }
    }
  }

  // Handle comment
  void _handleComment() {
    _navigateToComments();
  }

  // Navigate to user profile
  void _navigateToUserProfile() {
    // TODO: Navigate to user profile
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => UserMomentsScreen(userId: widget.moment.userId),
    // ));
  }

  // Navigate to comments
  void _navigateToComments() {
    // TODO: Navigate to moment detail with comments
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (context) => MomentDetailScreen(momentId: widget.moment.id),
    // ));
  }

  // Show more options
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy link'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Copy link
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Report moment
              },
            ),
            // Show delete if owner
            // if (widget.moment.userId == currentUserId)
            //   ListTile(
            //     leading: const Icon(Icons.delete_outline, color: Colors.red),
            //     title: const Text('Delete', style: TextStyle(color: Colors.red)),
            //     onTap: () => _handleDelete(),
            //   ),
          ],
        ),
      ),
    );
  }
}
