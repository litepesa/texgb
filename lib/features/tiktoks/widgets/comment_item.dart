import 'package:flutter/material.dart';
import 'package:textgb/models/moment_model.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final bool isMyComment;
  final VoidCallback? onDelete;
  
  const CommentItem({
    Key? key,
    required this.comment,
    this.isMyComment = false,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          userImageWidget(
            imageUrl: comment.userImage,
            radius: 16,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and time
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    
                    // Show delete option for my comments
                    if (isMyComment && onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16),
                        color: Colors.grey[600],
                        onPressed: onDelete,
                      ),
                  ],
                ),
                
                // Comment text
                Text(
                  comment.text,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}