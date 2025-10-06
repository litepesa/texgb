// lib/features/video_reactions/widgets/video_reaction_message_reply_preview.dart
// COPIED: Exact same UI as chat MessageReplyPreview but for video reactions
import 'package:flutter/material.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_message_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class VideoReactionMessageReplyPreview extends StatelessWidget {
  final VideoReactionMessageModel replyToMessage;
  final String? contactName;
  final VoidCallback? onCancel;
  final bool viewOnly;

  const VideoReactionMessageReplyPreview({
    super.key,
    required this.replyToMessage,
    this.contactName,
    this.onCancel,
    this.viewOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: viewOnly ? 0 : 12,
        vertical: viewOnly ? 0 : 4,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: viewOnly
              ? (modernTheme.surfaceVariantColor?.withOpacity(0.5) ?? Colors.grey.withOpacity(0.2))
              : (chatTheme.inputBackgroundColor?.withOpacity(0.8) ?? modernTheme.surfaceColor),
          borderRadius: BorderRadius.circular(viewOnly ? 8 : 16),
          border: Border.all(
            color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Reply indicator line
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: modernTheme.primaryColor ?? Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Reply content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender name
                  Text(
                    _getSenderName(),
                    style: TextStyle(
                      color: modernTheme.primaryColor ?? Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Message preview
                  Row(
                    children: [
                      // Message type icon (for media messages)
                      if (replyToMessage.type != MessageEnum.text) ...[
                        Icon(
                          _getMessageTypeIcon(replyToMessage.type),
                          size: 14,
                          color: modernTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 6),
                      ],
                      
                      // Message content preview
                      Expanded(
                        child: Text(
                          _getMessagePreview(),
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Cancel button (only show if not view-only)
            if (!viewOnly && onCancel != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: modernTheme.textSecondaryColor?.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: modernTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getSenderName() {
    // For video reaction messages, show appropriate sender name
    if (replyToMessage.isOriginalReaction && replyToMessage.videoReactionData != null) {
      return replyToMessage.videoReactionData!.userName;
    }
    return contactName ?? 'Contact';
  }

  String _getMessagePreview() {
    // Handle video reaction messages specially
    if (replyToMessage.isOriginalReaction && replyToMessage.videoReactionData != null) {
      final videoReaction = replyToMessage.videoReactionData!;
      if (videoReaction.hasReaction) {
        return videoReaction.reaction!;
      } else {
        return 'Shared a video';
      }
    }
    
    return replyToMessage.getDisplayContent();
  }

  IconData _getMessageTypeIcon(MessageEnum type) {
    switch (type) {
      case MessageEnum.image:
        return Icons.photo;
      case MessageEnum.video:
        return Icons.videocam;
      case MessageEnum.audio:
        return Icons.mic;
      case MessageEnum.file:
        return Icons.attach_file;
      case MessageEnum.location:
        return Icons.location_on;
      case MessageEnum.contact:
        return Icons.person;
      default:
        return Icons.message;
    }
  }
}