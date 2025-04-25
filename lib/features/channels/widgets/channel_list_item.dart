import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/channels/channel_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/assets_manager.dart';
import 'package:date_format/date_format.dart';

class ChannelListItem extends StatelessWidget {
  final ChannelModel channel;
  final VoidCallback onTap;
  final bool showSubscriberCount;

  const ChannelListItem({
    Key? key,
    required this.channel,
    required this.onTap,
    this.showSubscriberCount = true,
  }) : super(key: key);

  String _formatTimestamp(String timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      // Format as date if older than a week
      return formatDate(date, [M, ' ', d]);
    } else if (difference.inDays > 0) {
      // Format as days ago
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      // Format as hours ago
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      // Format as minutes ago
      return '${difference.inMinutes}m ago';
    } else {
      // Just now
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Channel image with fallback
    final channelImage = channel.image.isNotEmpty
        ? CachedNetworkImageProvider(channel.image) as ImageProvider
        : const AssetImage(AssetsManager.userImage);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: modernTheme.dividerColor!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Channel image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: channelImage,
                  fit: BoxFit.cover,
                ),
                border: Border.all(
                  color: modernTheme.dividerColor!,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Channel details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel name with verified badge if applicable
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          channel.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: modernTheme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (channel.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: Colors.blue,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Channel description
                  Text(
                    channel.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: modernTheme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Subscriber count and last update time
                  Row(
                    children: [
                      if (showSubscriberCount && channel.settings['showSubscriberCount'] == true) ...[
                        Icon(
                          Icons.people,
                          size: 14,
                          color: modernTheme.textSecondaryColor!.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${channel.subscribersUIDs.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: modernTheme.textSecondaryColor!.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: modernTheme.textSecondaryColor!.withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(channel.lastPostAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: modernTheme.textSecondaryColor!.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Right arrow indicator
            Icon(
              Icons.chevron_right,
              color: modernTheme.textSecondaryColor!.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}