// ===============================
// Moment Card Widget
// Single moment display in feed
// Uses GoRouter for navigation
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';
import 'package:textgb/features/moments/services/moments_time_service.dart';
import 'package:textgb/features/moments/widgets/moment_media_grid.dart';
import 'package:textgb/features/moments/widgets/moment_interactions.dart';
import 'package:textgb/features/moments/widgets/comment_list.dart';
import 'package:textgb/features/moments/providers/moments_providers.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/core/router/route_paths.dart';

class MomentCard extends ConsumerStatefulWidget {
  final MomentModel moment;
  final VoidCallback? onTap;
  final bool showComments;

  const MomentCard({
    super.key,
    required this.moment,
    this.onTap,
    this.showComments = true,
  });

  @override
  ConsumerState<MomentCard> createState() => _MomentCardState();
}

class _MomentCardState extends ConsumerState<MomentCard> {
  final bool _showAllComments = false;

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
          if (widget.moment.content != null &&
              widget.moment.content!.isNotEmpty)
            _buildContentText(),

          // Media (images/video)
          if (widget.moment.mediaUrls.isNotEmpty) _buildMedia(),

          // Location tag
          if (widget.moment.location != null) _buildLocation(),

          // Like/comment counts (Facebook style - before interactions)
          if (widget.moment.likesCount > 0 || widget.moment.commentsCount > 0)
            _buildEngagementCounts(),

          // Divider
          if (widget.moment.likesCount > 0 || widget.moment.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MomentsTheme.paddingLarge,
              ),
              child: Divider(
                color: MomentsTheme.lightDivider,
                height: 1,
              ),
            ),

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
            child: GestureDetector(
              onTap: () => _navigateToUserProfile(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.moment.userName,
                    style: MomentsTheme.userNameStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    MomentsTimeService.formatMomentTime(
                        widget.moment.createdAt),
                    style: MomentsTheme.timestampStyle,
                  ),
                ],
              ),
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
      padding: const EdgeInsets.only(
        left: MomentsTheme.paddingLarge,
        right: MomentsTheme.paddingLarge,
        top: MomentsTheme.paddingSmall,
        bottom: MomentsTheme.paddingMedium,
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: MomentsTheme.iconSizeSmall,
            color: MomentsTheme.lightTextSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            widget.moment.location!,
            style: MomentsTheme.timestampStyle.copyWith(
              color: MomentsTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Facebook-style engagement counts (likes and comments)
  Widget _buildEngagementCounts() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MomentsTheme.paddingLarge,
        vertical: MomentsTheme.paddingMedium,
      ),
      child: Row(
        children: [
          // Likes count
          if (widget.moment.likesCount > 0) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: MomentsTheme.likeRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.moment.likesCount}',
                  style: MomentsTheme.timestampStyle,
                ),
              ],
            ),
          ],
          const Spacer(),
          // Comments count
          if (widget.moment.commentsCount > 0)
            Text(
              '${widget.moment.commentsCount} ${widget.moment.commentsCount == 1 ? 'comment' : 'comments'}',
              style: MomentsTheme.timestampStyle,
            ),
        ],
      ),
    );
  }

  // Comments section - Facebook style
  Widget _buildCommentsSection() {
    return Container(
      padding: const EdgeInsets.only(
        left: MomentsTheme.paddingLarge,
        right: MomentsTheme.paddingLarge,
        bottom: MomentsTheme.paddingMedium,
        top: MomentsTheme.paddingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show more comments button
          if (widget.moment.commentsCount > 2 && !_showAllComments)
            GestureDetector(
              onTap: () => _navigateToComments(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'View all ${widget.moment.commentsCount} comments',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: MomentsTheme.lightTextSecondary,
                  ),
                ),
              ),
            ),

          // Comments preview
          CommentList(
            comments: _showAllComments
                ? widget.moment.commentsPreview
                : widget.moment.commentsPreview.take(2).toList(),
            momentId: widget.moment.id,
            compact: true,
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
    context.push('${RoutePaths.userProfile}/${widget.moment.userId}');
  }

  // Navigate to comments
  void _navigateToComments() {
    // For now, navigate to user's moments feed with this moment highlighted
    // In future, create a dedicated MomentDetailScreen
    context.push('${RoutePaths.userProfile}/${widget.moment.userId}');
  }

  // Show more options
  void _showMoreOptions() {
    final currentUser = ref.read(currentUserProvider);
    final isOwnPost = currentUser?.uid == widget.moment.userId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Copy text (if there's content)
            if (widget.moment.content != null &&
                widget.moment.content!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy text'),
                onTap: () {
                  context.pop();
                  _copyMomentText();
                },
              ),

            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                context.pop();
                _shareMoment();
              },
            ),

            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Copy link'),
              onTap: () {
                context.pop();
                _copyMomentLink();
              },
            ),

            // Hide posts from this user (only for other users' posts)
            if (!isOwnPost)
              ListTile(
                leading: const Icon(Icons.visibility_off_outlined),
                title: const Text('Hide posts from this user'),
                onTap: () {
                  context.pop();
                  _hidePostsFromUser();
                },
              ),

            // Report (only for other users' posts)
            if (!isOwnPost)
              ListTile(
                leading: const Icon(Icons.report_outlined),
                title: const Text('Report'),
                onTap: () {
                  context.pop();
                  _reportMoment();
                },
              ),

            // Delete (only for own posts)
            if (isOwnPost)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  context.pop();
                  _deleteMoment();
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Share moment
  void _shareMoment() {
    final text = '''
Check out this moment from ${widget.moment.userName}!

${widget.moment.content ?? ''}

View on WemaShop: wemachat://moment/${widget.moment.id}
    '''
        .trim();

    Share.share(text, subject: 'Moment from ${widget.moment.userName}');
  }

  // Copy moment link
  void _copyMomentLink() {
    final link = 'wemachat://moment/${widget.moment.id}';
    Clipboard.setData(ClipboardData(text: link));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link copied to clipboard')),
      );
    }
  }

  // Copy moment text
  void _copyMomentText() {
    if (widget.moment.content != null && widget.moment.content!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: widget.moment.content!));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text copied to clipboard')),
        );
      }
    }
  }

  // Hide posts from this user
  Future<void> _hidePostsFromUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hide posts'),
        content: Text(
          'You won\'t see posts from ${widget.moment.userName} in your Moments feed anymore. You can undo this from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hide'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(momentsFeedProvider.notifier)
            .hideUserPosts(widget.moment.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Posts from ${widget.moment.userName} hidden'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  ref
                      .read(momentsFeedProvider.notifier)
                      .unhideUserPosts(widget.moment.userId);
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to hide posts: $e')),
          );
        }
      }
    }
  }

  // Delete moment
  Future<void> _deleteMoment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete moment'),
        content: const Text(
          'Are you sure you want to delete this moment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(momentsFeedProvider.notifier)
            .deleteMoment(widget.moment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Moment deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete moment: $e')),
          );
        }
      }
    }
  }

  // Report moment
  Future<void> _reportMoment() async {
    final reasons = [
      'Spam or misleading',
      'Harassment or hate speech',
      'Violence or dangerous content',
      'Nudity or sexual content',
      'False information',
      'Other',
    ];

    String? selectedReason;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Moment'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you reporting this moment?'),
              const SizedBox(height: 16),
              ...reasons.map((reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() => selectedReason = value);
                    },
                    contentPadding: EdgeInsets.zero,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );

    if (confirmed == true && selectedReason != null && mounted) {
      // In a real app, send report to backend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Moment reported: $selectedReason')),
      );
    }
  }
}
