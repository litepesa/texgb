// lib/features/moments/widgets/comment_item.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentItem extends StatelessWidget {
  final MomentCommentModel comment;
  final String currentUserUID;
  final VoidCallback onReply;
  final VoidCallback onLike;

  const CommentItem({
    super.key,
    required this.comment,
    required this.currentUserUID,
    required this.onReply,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final isMyComment = comment.authorUID == currentUserUID;
    final isLiked = comment.likedBy.contains(currentUserUID);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture
          userImageWidget(
            imageUrl: comment.authorImage,
            radius: 16,
            onTap: () {
              // TODO: Navigate to user profile
            },
          ),
          
          const SizedBox(width: 12),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Author name
                      Text(
                        comment.authorName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      
                      // Reply indicator
                      if (comment.isReply) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.reply,
                              size: 12,
                              color: Color(0xFF007AFF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              comment.replyToName!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF007AFF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 4),
                      
                      // Comment content
                      Text(
                        comment.content,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Actions row
                Row(
                  children: [
                    // Time
                    Text(
                      timeago.format(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Like button
                    GestureDetector(
                      onTap: onLike,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                              size: 16,
                              color: isLiked ? const Color(0xFFFF3B30) : const Color(0xFF8E8E93),
                            ),
                            if (comment.likesCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likesCount}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isLiked ? const Color(0xFFFF3B30) : const Color(0xFF8E8E93),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Reply button
                    GestureDetector(
                      onTap: onReply,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: const Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // More options for own comments
                    if (isMyComment)
                      GestureDetector(
                        onTap: () => _showMoreOptions(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            CupertinoIcons.ellipsis,
                            color: Color(0xFF8E8E93),
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement edit comment
              showSnackBar(context, 'Edit comment feature coming soon');
            },
            child: const Text('Edit Comment'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete comment
              showSnackBar(context, 'Delete comment feature coming soon');
            },
            isDestructiveAction: true,
            child: const Text('Delete Comment'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}