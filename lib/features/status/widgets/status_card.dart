import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/features/status/screens/status_detail_screen.dart';
import 'package:textgb/features/status/widgets/media_grid_view.dart';
import 'package:textgb/models/status_model.dart';
import 'package:textgb/providers/status_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:timeago/timeago.dart' as timeago;

class StatusCard extends StatelessWidget {
  final StatusModel status;
  final String currentUserId;
  final bool showDeleteOption;
  final VoidCallback? onDelete;
  
  const StatusCard({
    Key? key,
    required this.status,
    required this.currentUserId,
    this.showDeleteOption = false,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? Colors.green;
    final backgroundColor = themeExtension?.backgroundColor ?? Colors.white;
    final isMyStatus = status.uid == currentUserId;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0.5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: InkWell(
        onTap: () => _navigateToStatusDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with avatar, name, time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User avatar with ripple effect on tap
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: () => _navigateToUserProfile(context),
                      child: userImageWidget(
                        imageUrl: status.userImage,
                        radius: 20,
                        onTap: () => _navigateToUserProfile(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Username, time, options column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username with tap to go to profile
                        GestureDetector(
                          onTap: () => _navigateToUserProfile(context),
                          child: Text(
                            status.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        
                        // Time ago
                        Text(
                          timeago.format(status.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Options menu
                  if (isMyStatus || showDeleteOption)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      splashRadius: 20,
                      onPressed: () => _showOptionsMenu(context),
                    ),
                ],
              ),
              
              // Caption content
              if (status.caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    status.caption,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              // Media content based on type
              if (status.statusType == StatusType.image)
                _buildSingleImage(status.statusUrl)
              else if (status.statusType == StatusType.video)
                _buildVideoThumbnail(status.statusUrl)
              else if (status.statusType == StatusType.multiImage && status.mediaUrls != null)
                MediaGridView(
                  mediaUrls: status.mediaUrls!,
                  caption: status.caption,
                ),
              
              // Location if available
              if (status.location != null && status.location!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.location!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Interaction statistics
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    // Likes count with icon
                    Row(
                      children: [
                        Icon(
                          status.likedBy.contains(currentUserId)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: status.likedBy.contains(currentUserId)
                              ? Colors.red
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${status.likedBy.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: status.likedBy.contains(currentUserId)
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Comments count with icon
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${status.comments.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    // Views count (only for post owner)
                    if (isMyStatus) ...[
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${status.viewedBy.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Interaction buttons (only for non-owners)
              if (!isMyStatus) ...[
                const Divider(height: 24),
                
                Row(
                  children: [
                    // Like button
                    Expanded(
                      child: InkWell(
                        onTap: () => _toggleLike(context),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                status.likedBy.contains(currentUserId)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: status.likedBy.contains(currentUserId)
                                    ? Colors.red
                                    : null,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                status.likedBy.contains(currentUserId) ? 'Liked' : 'Like',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: status.likedBy.contains(currentUserId)
                                      ? Colors.red
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Comment button
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToStatusDetail(context, focusComment: true),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.comment,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Comment',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToStatusDetail(BuildContext context, {bool focusComment = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusDetailScreen(
          status: status,
          currentUserId: currentUserId,
          focusComment: focusComment,
        ),
      ),
    );
  }

  void _navigateToUserProfile(BuildContext context) {
    // Navigate to user profile screen
    Navigator.pushNamed(
      context,
      '/userStatusScreen',
      arguments: status.uid,
    );
  }

  void _toggleLike(BuildContext context) {
    context.read<StatusProvider>().toggleLike(
      statusId: status.statusId,
      userId: currentUserId,
      statusOwnerUid: status.uid,
      onSuccess: () {},
      onError: (error) {
        showSnackBar(context, 'Error: $error');
      },
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final backgroundColor = themeExtension?.backgroundColor ?? Colors.white;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (onDelete != null || status.uid == currentUserId)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete status', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    if (onDelete != null) {
                      onDelete!();
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share status'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement share functionality
                  showSnackBar(context, 'Share feature coming soon');
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildSingleImage(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }
  
  Widget _buildVideoThumbnail(String videoUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                // For a real implementation, you would use a thumbnail extraction or video frame
                // Here we just use a placeholder
                'https://via.placeholder.com/800x450',
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            // Play button overlay
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}