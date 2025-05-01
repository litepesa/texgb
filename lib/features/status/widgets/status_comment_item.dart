// lib/features/status/presentation/widgets/status_comment_item.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:textgb/features/status/models/status_post_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:timeago/timeago.dart' as timeago;

class StatusCommentItem extends StatelessWidget {
  final StatusComment comment;
  final String currentUserId;

  const StatusCommentItem({
    Key? key,
    required this.comment,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final bool isOwnComment = comment.userId == currentUserId;
    final bool isLiked = comment.likes.contains(currentUserId);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[300],
            backgroundImage: comment.userImage.isNotEmpty
                ? CachedNetworkImageProvider(comment.userImage)
                : const AssetImage(AssetsManager.userImage) as ImageProvider,
          ),
          const SizedBox(width: 12),
          
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username
                Text(
                  comment.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: modernTheme.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Comment text
                Text(
                  comment.content,
                  style: TextStyle(
                    color: modernTheme.textColor,
                  ),
                ),
                
                // Comment info
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      // Time ago
                      Text(
                        timeago.format(DateTime.fromMillisecondsSinceEpoch(comment.timestamp)),
                        style: TextStyle(
                          fontSize: 12,
                          color: modernTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Like count
                      if (comment.likes.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.heart_fill,
                              size: 12,
                              color: modernTheme.textSecondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              comment.likes.length.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: modernTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      
                      const Spacer(),
                      
                      // Reply button
                      GestureDetector(
                        onTap: () {
                          // Handle reply
                        },
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: modernTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Like button
                      GestureDetector(
                        onTap: () {
                          // Handle like
                        },
                        child: Icon(
                          isLiked ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                          size: 14,
                          color: isLiked ? Colors.red : modernTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}