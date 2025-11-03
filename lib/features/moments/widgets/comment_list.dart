// ===============================
// Comment List Widget
// Display comments with WeChat-style formatting
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';
import 'package:textgb/features/moments/services/moments_time_service.dart';
import 'package:textgb/features/moments/providers/moments_providers.dart';

class CommentList extends ConsumerWidget {
  final List<MomentCommentModel> comments;
  final String momentId;
  final bool compact;
  final VoidCallback? onReply;

  const CommentList({
    Key? key,
    required this.comments,
    required this.momentId,
    this.compact = false,
    this.onReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (comments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: comments.map((comment) {
        return _buildCommentItem(context, ref, comment);
      }).toList(),
    );
  }

  Widget _buildCommentItem(
    BuildContext context,
    WidgetRef ref,
    MomentCommentModel comment,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: compact ? 6 : 12,
      ),
      child: GestureDetector(
        onLongPress: () => _showCommentOptions(context, ref, comment),
        child: compact
            ? _buildCompactComment(context, comment)
            : _buildFullComment(context, comment),
      ),
    );
  }

  // Compact comment (for preview in feed)
  Widget _buildCompactComment(BuildContext context, MomentCommentModel comment) {
    return RichText(
      text: TextSpan(
        children: [
          // Commenter name
          TextSpan(
            text: comment.userName,
            style: MomentsTheme.commentStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: MomentsTheme.primaryBlue,
            ),
          ),

          // Reply indicator
          if (comment.replyToUserName != null) ...[
            TextSpan(
              text: ' replied to ',
              style: MomentsTheme.commentStyle.copyWith(
                color: MomentsTheme.lightTextSecondary,
              ),
            ),
            TextSpan(
              text: comment.replyToUserName,
              style: MomentsTheme.commentStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: MomentsTheme.primaryBlue,
              ),
            ),
          ],

          // Comment content
          TextSpan(
            text: comment.replyToUserName != null
                ? ': ${comment.content}'
                : ': ${comment.content}',
            style: MomentsTheme.commentStyle,
          ),
        ],
      ),
      maxLines: compact ? 3 : null,
      overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
    );
  }

  // Full comment (for detail view)
  Widget _buildFullComment(BuildContext context, MomentCommentModel comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar (optional, can be added if needed)
        // CircleAvatar(
        //   radius: 16,
        //   backgroundImage: CachedNetworkImageProvider(comment.userAvatar),
        // ),
        // const SizedBox(width: 8),

        // Comment content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Comment text
              _buildCompactComment(context, comment),

              const SizedBox(height: 4),

              // Timestamp
              Text(
                MomentsTimeService.formatMomentTime(comment.createdAt),
                style: MomentsTheme.timestampStyle.copyWith(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Reply button
        IconButton(
          icon: const Icon(
            Icons.reply,
            size: 18,
          ),
          color: MomentsTheme.lightTextTertiary,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => _handleReply(context, comment),
        ),
      ],
    );
  }

  void _handleReply(BuildContext context, MomentCommentModel comment) {
    if (onReply != null) {
      onReply!();
    } else {
      // TODO: Show reply input
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reply to ${comment.userName}'),
        ),
      );
    }
  }

  void _showCommentOptions(
    BuildContext context,
    WidgetRef ref,
    MomentCommentModel comment,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                _handleReply(context, comment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                _copyComment(context, comment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                _reportComment(context, comment);
              },
            ),
            // Show delete if owner
            // TODO: Check if current user is comment owner
            // if (comment.userId == currentUserId)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteComment(context, ref, comment);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copyComment(BuildContext context, MomentCommentModel comment) {
    // TODO: Implement copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment copied to clipboard')),
    );
  }

  void _reportComment(BuildContext context, MomentCommentModel comment) {
    // TODO: Implement report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment reported')),
    );
  }

  Future<void> _deleteComment(
    BuildContext context,
    WidgetRef ref,
    MomentCommentModel comment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(momentCommentsProvider(momentId).notifier).deleteComment(
              comment.id,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete comment: $e')),
          );
        }
      }
    }
  }
}
