// lib/features/chat/widgets/status_reply_bubble.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/status/widgets/status_enums.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusReplyBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const StatusReplyBubble({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    // Status type indicators based on thumbnail or caption
    StatusType statusType = _determineStatusType();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe 
            ? modernTheme.secondaryColor!.withOpacity(0.2)
            : modernTheme.primaryColor!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMe 
              ? modernTheme.secondaryColor!.withOpacity(0.3)
              : modernTheme.primaryColor!.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status reply header
          Row(
            children: [
              Icon(
                _getStatusTypeIcon(statusType),
                size: 16,
                color: modernTheme.textSecondaryColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Status',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Status preview
          Row(
            children: [
              // Left side - thumbnail if available
              if (message.statusThumbnailUrl != null && message.statusThumbnailUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CachedNetworkImage(
                      imageUrl: message.statusThumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.photo, size: 20, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: Icon(
                          _getStatusTypeIcon(statusType),
                          size: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              
              if (message.statusThumbnailUrl != null && message.statusThumbnailUrl!.isNotEmpty)
                const SizedBox(width: 8),
              
              // Right side - caption or type indicator
              Expanded(
                child: Text(
                  message.statusCaption?.isNotEmpty == true
                      ? message.statusCaption!
                      : _getStatusTypeText(statusType),
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  StatusType _determineStatusType() {
    // Try to determine status type from thumbnail URL pattern
    final thumbnailUrl = message.statusThumbnailUrl ?? '';
    
    if (thumbnailUrl.contains('_video/')) {
      return StatusType.video;
    } else if (thumbnailUrl.contains('_image/')) {
      return StatusType.image;
    } else if (thumbnailUrl.contains('link_preview')) {
      return StatusType.link;
    } else if (message.statusCaption != null && message.statusCaption!.isNotEmpty) {
      return StatusType.text;
    } else {
      return StatusType.image; // Default assumption
    }
  }
  
  IconData _getStatusTypeIcon(StatusType type) {
    switch (type) {
      case StatusType.video:
        return Icons.videocam_outlined;
      case StatusType.text:
        return Icons.format_quote_outlined;
      case StatusType.link:
        return Icons.link;
      case StatusType.image:
      default:
        return Icons.photo_outlined;
    }
  }
  
  String _getStatusTypeText(StatusType type) {
    switch (type) {
      case StatusType.video:
        return 'Video status';
      case StatusType.text:
        return 'Text status';
      case StatusType.link:
        return 'Link status';
      case StatusType.image:
      default:
        return 'Photo status';
    }
  }
}