import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/widgets/status_text_content.dart';
import 'package:timeago/timeago.dart' as timeago;

class StatusPreviewCard extends StatelessWidget {
  final StatusModel status;
  final VoidCallback? onDelete;
  final bool showDeleteButton;
  final bool showMetrics;

  const StatusPreviewCard({
    Key? key,
    required this.status,
    this.onDelete,
    this.showDeleteButton = false,
    this.showMetrics = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    
    return Container(
      decoration: BoxDecoration(
        color: themeExtension?.receiverBubbleColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header with user info and timestamp
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Status privacy indicator
                Icon(
                  status.isPrivate ? Icons.lock_outline : Icons.public,
                  size: 16,
                  color: themeExtension?.greyColor,
                ),
                const SizedBox(width: 8),
                
                // Status timestamp
                Text(
                  timeago.format(status.createdAt),
                  style: TextStyle(
                    fontSize: 14,
                    color: themeExtension?.greyColor,
                  ),
                ),
                
                const Spacer(),
                
                // Status type indicator
                _buildStatusTypeIndicator(themeExtension),
                
                // Delete button if needed
                if (showDeleteButton && onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: Colors.red.withOpacity(0.7),
                    iconSize: 20,
                  ),
              ],
            ),
          ),
          
          // Status preview content
          _buildStatusPreview(context),
          
          // Status metrics if needed
          if (showMetrics)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // View count
                  Row(
                    children: [
                      Icon(
                        Icons.remove_red_eye,
                        size: 16,
                        color: themeExtension?.greyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${status.viewCount} views',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeExtension?.greyColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Like count
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 16,
                        color: status.likeCount > 0 
                            ? Colors.red.withOpacity(0.7) 
                            : themeExtension?.greyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${status.likeCount} likes',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeExtension?.greyColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Expiry indicator
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: themeExtension?.greyColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getExpiryText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: themeExtension?.greyColor,
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
  
  // Build the status type indicator icon
  Widget _buildStatusTypeIndicator(WeChatThemeExtension? themeExtension) {
    IconData icon;
    Color color;
    
    switch (status.type) {
      case StatusType.text:
        icon = Icons.text_fields;
        color = Colors.purple;
        break;
      case StatusType.image:
        icon = Icons.image;
        color = Colors.blue;
        break;
      case StatusType.video:
        icon = Icons.videocam;
        color = Colors.red;
        break;
      default:
        icon = Icons.question_mark;
        color = themeExtension?.greyColor ?? Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }
  
  // Build the status preview content based on type
  Widget _buildStatusPreview(BuildContext context) {
    switch (status.type) {
      case StatusType.text:
        // Scaled-down version of text status
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          height: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: StatusTextContent(
              text: status.text,
              backgroundInfo: status.backgroundInfo,
              previewMode: true,
            ),
          ),
        );
      case StatusType.image:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withOpacity(0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: status.mediaUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.error),
              ),
            ),
          ),
        );
      case StatusType.video:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black.withOpacity(0.1),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: status.mediaUrl + '?thumbnail=true', // Assuming thumbnail URL can be derived
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.black54,
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox(
          height: 100,
          child: Center(
            child: Text('Unsupported status type'),
          ),
        );
    }
  }
  
  // Get text for how much time left until expiry
  String _getExpiryText() {
    final now = DateTime.now();
    final difference = status.expiresAt.difference(now);
    
    if (difference.isNegative) {
      return 'Expired';
    }
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    
    if (hours > 0) {
      return 'Expires in ${hours}h ${minutes}m';
    } else {
      return 'Expires in ${minutes}m';
    }
  }
}