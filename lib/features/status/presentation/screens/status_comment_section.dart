import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/models/status_comment.dart';
import '../../application/providers/status_providers.dart';

class StatusCommentSection extends ConsumerWidget {
  final List<StatusComment> comments;
  final Function(String) onDeleteComment;
  
  const StatusCommentSection({
    Key? key,
    required this.comments,
    required this.onDeleteComment,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sort comments: newest first for parent comments,
    // but replies should be chronological after their parent
    final sortedComments = _getSortedComments(comments);
    
    if (sortedComments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No comments yet. Be the first to comment!',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sortedComments.length,
      itemBuilder: (context, index) {
        final comment = sortedComments[index];
        return _CommentItem(
          comment: comment,
          onDelete: () => onDeleteComment(comment.id),
          onReply: (comment) {
            // Implement reply functionality
          },
        );
      },
    );
  }
  
  List<StatusComment> _getSortedComments(List<StatusComment> comments) {
    // First, separate parent comments and replies
    final parentComments = comments.where((c) => !c.isReply).toList();
    final replies = comments.where((c) => c.isReply).toList();
    
    // Sort parent comments by timestamp (newest first)
    parentComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Create a list to hold the organized comments
    final result = <StatusComment>[];
    
    // Add each parent followed by its replies
    for (final parent in parentComments) {
      result.add(parent);
      
      // Find all replies to this parent and sort them chronologically
      final parentReplies = replies
          .where((r) => r.replyToCommentId == parent.id)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      result.addAll(parentReplies);
    }
    
    return result;
  }
}

class _CommentItem extends ConsumerWidget {
  final StatusComment comment;
  final VoidCallback onDelete;
  final Function(StatusComment) onReply;
  
  const _CommentItem({
    Key? key,
    required this.comment,
    required this.onDelete,
    required this.onReply,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return FutureBuilder(
      future: ref.read(userProvider.future),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        final isCurrentUserComment = currentUser != null && comment.userId == currentUser.uid;
        
        return Container(
          margin: EdgeInsets.only(
            left: comment.isReply ? 36 : 8,
            right: 8,
            top: 8,
            bottom: 4,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: comment.isReply ? Colors.grey[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Comment header: author info and actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: comment.userImage.isNotEmpty
                        ? CachedNetworkImageProvider(comment.userImage)
                        : null,
                    child: comment.userImage.isEmpty
                        ? Text(comment.userName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              comment.userName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (comment.isReply) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.reply, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                comment.replyToUserName ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          timeago.format(comment.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action menu for comment
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
                    itemBuilder: (context) => [
                      if (isCurrentUserComment)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      if (!comment.isReply)
                        const PopupMenuItem(
                          value: 'reply',
                          child: Text('Reply'),
                        ),
                      const PopupMenuItem(
                        value: 'report',
                        child: Text('Report'),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'delete':
                          onDelete();
                          break;
                        case 'reply':
                          onReply(comment);
                          break;
                        case 'report':
                          _reportComment(context);
                          break;
                      }
                    },
                  ),
                ],
              ),
              
              // Comment content
              Padding(
                padding: const EdgeInsets.only(left: 40, top: 4, right: 8),
                child: Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              
              // Comment actions
              if (!comment.isReply)
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 8),
                  child: InkWell(
                    onTap: () => onReply(comment),
                    child: Text(
                      'Reply',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  void _reportComment(BuildContext context) {
    // Implement report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for reporting this comment. We will review it.'),
      ),
    );
  }
}