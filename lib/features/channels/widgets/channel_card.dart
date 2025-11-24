// lib/features/channels/widgets/channel_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:textgb/features/channels/models/channel_model.dart';

/// Channel card widget for lists and grids
class ChannelCard extends StatelessWidget {
  final ChannelModel channel;
  final VoidCallback? onTap;
  final bool showSubscribeButton;

  const ChannelCard({
    super.key,
    required this.channel,
    this.onTap,
    this.showSubscribeButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Channel Avatar
              _buildAvatar(),
              const SizedBox(width: 12),

              // Channel Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel Name + Verified Badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            channel.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (channel.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      channel.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Stats Row
                    Row(
                      children: [
                        // Subscriber count
                        Icon(
                          CupertinoIcons.person_2_fill,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(channel.subscriberCount),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Post count
                        Icon(
                          CupertinoIcons.square_grid_2x2_fill,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${channel.postCount} posts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),

                        const Spacer(),

                        // Channel Type Badge
                        _buildTypeBadge(),
                      ],
                    ),
                  ],
                ),
              ),

              // Subscribe Button (if enabled)
              if (showSubscribeButton) ...[
                const SizedBox(width: 8),
                _buildSubscribeButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
        image: channel.avatarUrl != null
            ? DecorationImage(
                image: NetworkImage(channel.avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: channel.avatarUrl == null
          ? Icon(
              CupertinoIcons.tv_circle_fill,
              size: 28,
              color: Colors.grey[600],
            )
          : null,
    );
  }

  Widget _buildTypeBadge() {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (channel.type) {
      case ChannelType.premium:
        badgeColor = Colors.amber;
        badgeText = 'Premium';
        badgeIcon = Icons.star;
        break;
      case ChannelType.private:
        badgeColor = Colors.purple;
        badgeText = 'Private';
        badgeIcon = Icons.lock;
        break;
      case ChannelType.public:
      default:
        badgeColor = Colors.green;
        badgeText = 'Public';
        badgeIcon = Icons.public;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton(BuildContext context) {
    final isSubscribed = channel.isSubscribed ?? false;

    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () {
          // Will be handled by parent widget
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSubscribed ? Colors.grey[300] : Theme.of(context).primaryColor,
          foregroundColor: isSubscribed ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          isSubscribed ? 'Subscribed' : 'Subscribe',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
