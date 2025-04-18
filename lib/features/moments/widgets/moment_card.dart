import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/features/moments/screens/moment_detail_screen.dart';
import 'package:textgb/features/moments/widgets/media_grid_view.dart';
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
    final isMyMoment = moment.uid == currentUserId;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MomentDetailScreen(
                moment: moment,
                currentUserId: currentUserId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with avatar, name, time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User avatar
                  userImageWidget(
                    imageUrl: moment.userImage,
                    radius: 20,
                    onTap: () {},
                  ),
                  const SizedBox(width: 12),
                  
                  // Username, time, options column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username
                        Text(
                          moment.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                  if (isMyMoment && showDeleteOption)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        _showOptionsMenu(context);
                      },
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
                  ),
                ),
              
              // Media grid
              if (moment.mediaUrls.isNotEmpty)
                MediaGridView(
                  mediaUrls: moment.mediaUrls,
                  isVideo: moment.isVideo,
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
              
              // Stats row (only visible to post owner)
              if (isMyMoment)
                Row(
                  children: [
                    // Views count
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
                    const SizedBox(width: 16),
                    
                    // Likes count
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${moment.likedBy.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Comments count
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
                  ],
                )
              else
                // Interaction row for non-owners
                Row(
                  children: [
                    // Like button
                    InkWell(
                      onTap: () {
                        context.read<MomentsProvider>().toggleLike(
                          momentId: moment.momentId,
                          userId: currentUserId,
                          onSuccess: () {},
                          onError: (error) {
                            showSnackBar(context, 'Error: $error');
                          },
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            moment.likedBy.contains(currentUserId)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: moment.likedBy.contains(currentUserId)
                                ? Colors.red
                                : null,
                          ),
                          const SizedBox(width: 4),
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
                    const SizedBox(width: 16),
                    
                    // Comment button
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MomentDetailScreen(
                              moment: moment,
                              currentUserId: currentUserId,
                              focusComment: true,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.comment,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Comment',
                            style: TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  if (onDelete != null) {
                    onDelete!();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}