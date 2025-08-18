// lib/features/chat/widgets/message_reply_preview.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MessageReplyPreview extends StatelessWidget {
  final MessageModel replyToMessage;
  final String? contactName;
  final VoidCallback? onCancel;
  final bool viewOnly;

  const MessageReplyPreview({
    super.key,
    required this.replyToMessage,
    this.contactName,
    this.onCancel,
    this.viewOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    // Determine padding based on context
    final intrinsicPadding = onCancel != null
        ? const EdgeInsets.all(10)
        : const EdgeInsets.only(top: 5, right: 5, bottom: 5);

    // Determine decoration color based on context
    final decorationColor = onCancel != null
        ? modernTheme.textColor?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1)
        : modernTheme.primaryColor?.withOpacity(0.2) ?? Colors.blue.withOpacity(0.2);

    return IntrinsicHeight(
      child: Container(
        margin: onCancel != null 
          ? const EdgeInsets.symmetric(horizontal: 12)
          : EdgeInsets.zero,
        padding: intrinsicPadding,
        decoration: BoxDecoration(
          color: decorationColor,
          borderRadius: onCancel != null
              ? BorderRadius.circular(20)
              : BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Green vertical line indicator
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Name and message content
            Expanded(
              child: _buildNameAndMessage(context, modernTheme),
            ),
            
            // Media thumbnail (if applicable)
            if (_hasMediaThumbnail()) ...[
              const SizedBox(width: 8),
              _buildMediaThumbnail(context, modernTheme),
            ],
            
            // Spacer for input context
            onCancel != null ? const SizedBox(width: 8) : const SizedBox(),
            
            // Close button for input context
            onCancel != null
                ? _buildCloseButton(context, modernTheme)
                : const SizedBox(),
          ],
        ),
      ),
    );
  }

  bool _hasMediaThumbnail() {
    return (replyToMessage.type == MessageEnum.image || 
            replyToMessage.type == MessageEnum.video) && 
           replyToMessage.mediaUrl != null && 
           replyToMessage.mediaUrl!.isNotEmpty;
  }

  Widget _buildMediaThumbnail(BuildContext context, ModernThemeExtension modernTheme) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: modernTheme.surfaceVariantColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Thumbnail image
            if (replyToMessage.type == MessageEnum.image)
              CachedNetworkImage(
                imageUrl: replyToMessage.mediaUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: modernTheme.surfaceVariantColor,
                  child: Icon(
                    Icons.image,
                    size: 20,
                    color: modernTheme.textSecondaryColor,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: modernTheme.surfaceVariantColor,
                  child: Icon(
                    Icons.broken_image,
                    size: 20,
                    color: modernTheme.textSecondaryColor,
                  ),
                ),
              )
            else if (replyToMessage.type == MessageEnum.video)
              // For video, show a placeholder with play icon overlay
              Container(
                width: 40,
                height: 40,
                color: Colors.grey[800],
                child: Stack(
                  children: [
                    // Video thumbnail placeholder
                    Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.video_library,
                        size: 20,
                        color: Colors.grey[400],
                      ),
                    ),
                    // Small play icon overlay
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, ModernThemeExtension modernTheme) {
    return InkWell(
      onTap: onCancel,
      child: Container(
        decoration: BoxDecoration(
          color: modernTheme.textColor?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: modernTheme.textColor ?? Colors.grey,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: Icon(
          Icons.close,
          size: 16,
          color: modernTheme.textColor,
        ),
      ),
    );
  }

  Widget _buildNameAndMessage(BuildContext context, ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(modernTheme),
        const SizedBox(height: 5),
        _buildMessageContent(context, modernTheme),
      ],
    );
  }

  Widget _buildTitle(ModernThemeExtension modernTheme) {
    return Text(
      contactName ?? 'Contact',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.blue,
        fontSize: 12,
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, ModernThemeExtension modernTheme) {
    return _buildDisplayMessageType(
      message: replyToMessage.content,
      type: replyToMessage.type,
      color: modernTheme.textColor ?? Colors.black,
      isReply: true,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      viewOnly: viewOnly,
    );
  }

  Widget _buildDisplayMessageType({
    required String message,
    required MessageEnum type,
    required Color color,
    required bool isReply,
    int? maxLines,
    TextOverflow? overflow,
    required bool viewOnly,
  }) {
    switch (type) {
      case MessageEnum.text:
        return Text(
          message,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 13,
          ),
          maxLines: maxLines,
          overflow: overflow,
        );
        
      case MessageEnum.image:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image,
              size: 16,
              color: color.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message.isNotEmpty ? message : 'Photo',
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 13,
                ),
                maxLines: maxLines,
                overflow: overflow,
              ),
            ),
          ],
        );
        
      case MessageEnum.video:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam,
              size: 16,
              color: color.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message.isNotEmpty ? message : 'Video',
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 13,
                ),
                maxLines: maxLines,
                overflow: overflow,
              ),
            ),
          ],
        );
        
      case MessageEnum.file:
        final fileName = replyToMessage.mediaMetadata?['fileName'] ?? 'Document';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file,
              size: 16,
              color: color.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                fileName,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 13,
                ),
                maxLines: maxLines,
                overflow: overflow,
              ),
            ),
          ],
        );
        
      case MessageEnum.audio:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mic,
              size: 16,
              color: color.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Text(
              'Voice message',
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 13,
              ),
              maxLines: maxLines,
              overflow: overflow,
            ),
          ],
        );
        
      case MessageEnum.location:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: color.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Text(
              'Location',
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 13,
              ),
              maxLines: maxLines,
              overflow: overflow,
            ),
          ],
        );
        
      case MessageEnum.contact:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person,
              size: 16,
              color: color.withOpacity(0.8),
            ),
            const SizedBox(width: 6),
            Text(
              'Contact',
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 13,
              ),
              maxLines: maxLines,
              overflow: overflow,
            ),
          ],
        );
        
      default:
        return Text(
          replyToMessage.getDisplayContent(),
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 13,
          ),
          maxLines: maxLines,
          overflow: overflow,
        );
    }
  }
}