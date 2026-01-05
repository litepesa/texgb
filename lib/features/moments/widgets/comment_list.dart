// ===============================
// Comment List Widget
// Display comments with WeChat-style formatting
// Uses GoRouter for navigation
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';
import 'package:textgb/features/moments/services/moments_time_service.dart';
import 'package:textgb/features/moments/providers/moments_providers.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';

class CommentList extends ConsumerWidget {
  final List<MomentCommentModel> comments;
  final String momentId;
  final bool compact;
  final VoidCallback? onReply;

  const CommentList({
    super.key,
    required this.comments,
    required this.momentId,
    this.compact = false,
    this.onReply,
  });

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
            : _buildFullComment(context, ref, comment),
      ),
    );
  }

  // Compact comment (for preview in feed)
  Widget _buildCompactComment(
      BuildContext context, MomentCommentModel comment) {
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
  Widget _buildFullComment(
      BuildContext context, WidgetRef ref, MomentCommentModel comment) {
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
          onPressed: () => _handleReply(context, ref, comment),
        ),
      ],
    );
  }

  void _handleReply(
      BuildContext context, WidgetRef ref, MomentCommentModel comment) {
    if (onReply != null) {
      onReply!();
    } else {
      // Show reply input dialog
      _showReplyDialog(context, ref, comment);
    }
  }

  Future<void> _showReplyDialog(
    BuildContext context,
    WidgetRef ref,
    MomentCommentModel comment,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${comment.userName}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Write your reply...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              try {
                await ref
                    .read(momentCommentsProvider(momentId).notifier)
                    .addComment(
                      controller.text.trim(),
                      replyToUserId: comment.userId,
                    );

                if (context.mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reply posted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to post reply: $e')),
                  );
                }
              }
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  void _showCommentOptions(
    BuildContext context,
    WidgetRef ref,
    MomentCommentModel comment,
  ) {
    // Get current user ID
    final currentUser = ref.read(authenticationProvider).value?.currentUser;
    final isOwner = currentUser?.uid == comment.userId;

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
                context.pop();
                _handleReply(context, ref, comment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                context.pop();
                _copyComment(context, comment);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Report'),
              onTap: () {
                context.pop();
                _reportComment(context, ref, comment);
              },
            ),
            // Show delete only if current user is the comment owner
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  context.pop();
                  _deleteComment(context, ref, comment);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _copyComment(BuildContext context, MomentCommentModel comment) {
    Clipboard.setData(ClipboardData(text: comment.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment copied to clipboard')),
    );
  }

  Future<void> _reportComment(
    BuildContext context,
    WidgetRef ref,
    MomentCommentModel comment,
  ) async {
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
        title: const Text('Report Comment'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you reporting this comment?'),
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

    if (confirmed == true && selectedReason != null && context.mounted) {
      // In a real app, send report to backend
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment reported: $selectedReason')),
      );
    }
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
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
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
