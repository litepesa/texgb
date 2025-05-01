// lib/features/status/presentation/widgets/status_post_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_post_model.dart';
import 'package:textgb/features/status/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:timeago/timeago.dart' as timeago;

class StatusPostCard extends StatelessWidget {
  final StatusPost post;
  final String currentUserId;
  final VoidCallback onTap;

  const StatusPostCard({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isVisible = context.watch<StatusProvider>().isStatusTabVisible;
    final bool isLiked = post.likes.contains(currentUserId);
    final bool isOwnPost = post.userId == currentUserId;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: modernTheme.surfaceColor,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: post.userImage.isNotEmpty
                          ? CachedNetworkImageProvider(post.userImage)
                          : const AssetImage(AssetsManager.userImage) as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    
                    // User name and time
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.userName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: modernTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeago.format(DateTime.fromMillisecondsSinceEpoch(post.timestamp)),
                            style: TextStyle(
                              fontSize: 12,
                              color: modernTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Options menu for own posts
                    if (isOwnPost)
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.ellipsis,
                          color: modernTheme.textSecondaryColor,
                        ),
                        onPressed: () => _showOptionsMenu(context),
                        splashRadius: 20,
                      ),
                  ],
                ),
              ),
              
              // Content
              if (post.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    post.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: modernTheme.textColor,
                    ),
                  ),
                ),
                
              const SizedBox(height: 8),
              
              // Media content
              if (post.mediaUrls.isNotEmpty)
                _buildMediaContent(context, isVisible),
                
              // Footer with actions
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Like counter
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.heart_fill,
                          size: 16,
                          color: modernTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.likes.length.toString(),
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                          ),
                        ),
                        // Comment counter
                        const SizedBox(width: 16),
                        Icon(
                          CupertinoIcons.chat_bubble,
                          size: 16,
                          color: modernTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.commentCount.toString(),
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    
                    // Action buttons
                    Row(
                      children: [
                        // Like button
                        IconButton(
                          icon: Icon(
                            isLiked
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            color: isLiked
                                ? Colors.red
                                : modernTheme.textSecondaryColor,
                          ),
                          onPressed: () {
                            context.read<StatusProvider>().toggleLike(
                                  postId: post.id,
                                  userId: currentUserId,
                                );
                          },
                          splashRadius: 20,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                        
                        // Comment button
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.chat_bubble,
                            color: modernTheme.textSecondaryColor,
                          ),
                          onPressed: onTap,
                          splashRadius: 20,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                        
                        // Share button
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.share,
                            color: modernTheme.textSecondaryColor,
                          ),
                          onPressed: () {
                            // Implement share functionality
                          },
                          splashRadius: 20,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Media content builder based on post type
  Widget _buildMediaContent(BuildContext context, bool isVisible) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (post.type) {
      case StatusType.image:
        if (post.mediaUrls.length == 1) {
          // Single image
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: post.mediaUrls[0],
              width: screenWidth,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
          );
        } else {
          // Multiple images grid
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: post.mediaUrls.length > 2 ? 3 : 2,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemCount: post.mediaUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: post.mediaUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              );
            },
          );
        }
        
      case StatusType.video:
        // Video thumbnail with play button
        return Stack(
          alignment: Alignment.center,
          children: [
            // Video thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: post.mediaUrls[0], // Assuming first URL is thumbnail or video URL
                width: screenWidth,
                height: 250,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            
            // Play button overlay
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
          ],
        );
      
      case StatusType.link:
        // Link preview
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Link preview image
              if (post.mediaUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: post.mediaUrls[0],
                    width: screenWidth,
                    height: 150,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: Colors.grey[300],
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.link),
                    ),
                  ),
                ),
              
              // Link info
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.content,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'tap to open link',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      
      case StatusType.text:
      default:
        // Text-only post, no media content
        return const SizedBox();
    }
  }
  
  // Show options menu for user's own posts
  void _showOptionsMenu(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  CupertinoIcons.pencil,
                  color: modernTheme.textColor,
                ),
                title: Text(
                  'Edit Post',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to edit screen
                },
              ),
              ListTile(
                leading: Icon(
                  CupertinoIcons.trash,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete Post',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePost(context);
                },
              ),
              ListTile(
                leading: Icon(
                  CupertinoIcons.eye_slash,
                  color: modernTheme.textColor,
                ),
                title: Text(
                  'Change Privacy',
                  style: TextStyle(color: modernTheme.textColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Show privacy options
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Confirm delete dialog
  void _confirmDeletePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post?'),
          content: const Text('This action cannot be undone. Are you sure you want to delete this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<StatusProvider>().deletePost(post.id).then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post deleted')),
                    );
                  }
                });
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}