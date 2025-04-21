import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/features/tiktoks/screens/moment_detail_screen.dart';
import 'package:textgb/features/tiktoks/widgets/media_grid_view.dart';
import 'package:textgb/models/moment_model.dart';
import 'package:textgb/providers/moments_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:timeago/timeago.dart' as timeago;

class MomentCard extends StatelessWidget {
  final MomentModel moment;
  final String currentUserId;
  final bool showDeleteOption;
  final VoidCallback? onDelete;
  
  const MomentCard({
    Key? key,
    required this.moment,
    required this.currentUserId,
    this.showDeleteOption = false,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? Colors.green;
    final backgroundColor = themeExtension?.backgroundColor ?? Colors.white;
    final isMyMoment = moment.uid == currentUserId;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0.5,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: InkWell(
        onTap: () => _navigateToMomentDetail(context),
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
                        imageUrl: moment.userImage,
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
                            moment.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        
                        // Time ago
                        Text(
                          timeago.format(moment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Options menu
                  if (isMyMoment || showDeleteOption)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      splashRadius: 20,
                      onPressed: () => _showOptionsMenu(context),
                    ),
                ],
              ),
              
              // Text content
              if (moment.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    moment.text,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              // Media grid - pass the description for media viewing
              if (moment.mediaUrls.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                  child: MediaGridView(
                    mediaUrls: moment.mediaUrls,
                    isVideo: moment.isVideo,
                    momentDescription: moment.text,
                  ),
                ),
              
              // Location if available
              if (moment.location.isNotEmpty)
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
                        moment.location,
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
                          moment.likedBy.contains(currentUserId)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: moment.likedBy.contains(currentUserId)
                              ? Colors.red
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${moment.likedBy.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: moment.likedBy.contains(currentUserId)
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
                          '${moment.comments.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    // Views count (only for post owner)
                    if (isMyMoment) ...[
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
                            '${moment.viewedBy.length}',
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
              if (!isMyMoment) ...[
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
                                moment.likedBy.contains(currentUserId)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: moment.likedBy.contains(currentUserId)
                                    ? Colors.red
                                    : null,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                moment.likedBy.contains(currentUserId) ? 'Liked' : 'Like',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: moment.likedBy.contains(currentUserId)
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
                        onTap: () => _navigateToMomentDetail(context, focusComment: true),
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

  void _navigateToMomentDetail(BuildContext context, {bool focusComment = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MomentDetailScreen(
          moment: moment,
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
      '/userMomentsScreen',
      arguments: moment.uid,
    );
  }

  void _toggleLike(BuildContext context) {
    context.read<MomentsProvider>().toggleLike(
      momentId: moment.momentId,
      userId: currentUserId,
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
              if (onDelete != null || moment.uid == currentUserId)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete moment', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    if (onDelete != null) {
                      onDelete!();
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share moment'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement share functionality
                  showSnackBar(context, 'Share feature coming soon');
                },
              ),
              if (moment.uid == currentUserId)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit moment'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement edit functionality
                    showSnackBar(context, 'Edit feature coming soon');
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}