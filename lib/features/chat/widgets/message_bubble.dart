// lib/features/chat/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final bool showAvatar;
  final bool isLastInGroup;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final double fontSize;
  final String? contactName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.showAvatar = false,
    this.isLastInGroup = true,
    this.onLongPress,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.fontSize = 16.0,
    this.contactName,
  });

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    final chatTheme = context.chatTheme;
    
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.only(
          left: isCurrentUser ? 60 : 16,
          right: isCurrentUser ? 16 : 60,
          bottom: isLastInGroup ? 8 : 2,
          top: 2,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
          children: [
            // Reply indicator
            if (message.isReply()) ...[
              _buildReplyIndicator(context, modernTheme),
              const SizedBox(height: 4),
            ],
            
            // Pin indicator
            if (message.isPinned) ...[
              _buildPinIndicator(context, modernTheme),
              const SizedBox(height: 4),
            ],
            
            // Main message bubble
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser 
                  ? chatTheme.senderBubbleColor 
                  : chatTheme.receiverBubbleColor,
                borderRadius: _getBubbleRadius(),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: _getBubbleRadius(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content
                    _buildMessageContent(context, modernTheme, chatTheme),
                    
                    // Timestamp and status
                    _buildMessageFooter(context, modernTheme),
                  ],
                ),
              ),
            ),
            
            // Edit indicator
            if (message.isEdited) ...[
              const SizedBox(height: 2),
              _buildEditIndicator(context, modernTheme),
            ],
          ],
        ),
      ),
    );
  }

  BorderRadius _getBubbleRadius() {
    const radius = 20.0;
    const smallRadius = 6.0;
    
    if (isCurrentUser) {
      return BorderRadius.only(
        topLeft: const Radius.circular(radius),
        topRight: const Radius.circular(radius),
        bottomLeft: const Radius.circular(radius),
        bottomRight: isLastInGroup 
          ? const Radius.circular(smallRadius)
          : const Radius.circular(radius),
      );
    } else {
      return BorderRadius.only(
        topLeft: const Radius.circular(radius),
        topRight: const Radius.circular(radius),
        bottomLeft: isLastInGroup 
          ? const Radius.circular(smallRadius)
          : const Radius.circular(radius),
        bottomRight: const Radius.circular(radius),
      );
    }
  }

  Widget _buildReplyIndicator(BuildContext context, ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor?.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.reply,
            size: 14,
            color: modernTheme.textSecondaryColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Replying to ${message.replyToSender == message.senderId ? 'themselves' : (contactName ?? 'contact')}',
              style: TextStyle(
                fontSize: 12,
                color: modernTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinIndicator(BuildContext context, ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: modernTheme.primaryColor?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.push_pin,
            size: 12,
            color: modernTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Pinned',
            style: TextStyle(
              fontSize: 11,
              color: modernTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditIndicator(BuildContext context, ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'edited',
        style: TextStyle(
          fontSize: 11,
          color: modernTheme.textTertiaryColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildMessageContent(
    BuildContext context, 
    ModernThemeExtension modernTheme,
    ChatThemeExtension chatTheme,
  ) {
    switch (message.type) {
      case MessageEnum.text:
        return _buildTextContent(context, modernTheme, chatTheme);
      case MessageEnum.image:
        return _buildImageContent(context, modernTheme);
      case MessageEnum.file:
        return _buildFileContent(context, modernTheme);
      default:
        return _buildTextContent(context, modernTheme, chatTheme);
    }
  }

  Widget _buildTextContent(
    BuildContext context,
    ModernThemeExtension modernTheme,
    ChatThemeExtension chatTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply content preview
          if (message.isReply() && message.replyToContent != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCurrentUser 
                  ? Colors.white.withOpacity(0.15)
                  : modernTheme.surfaceVariantColor?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: modernTheme.primaryColor!,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                message.replyToContent!,
                style: TextStyle(
                  fontSize: fontSize - 2,
                  color: isCurrentUser 
                    ? Colors.white70
                    : modernTheme.textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Main message text
          SelectableText(
            message.content,
            style: TextStyle(
              fontSize: fontSize,
              color: isCurrentUser 
                ? chatTheme.senderTextColor
                : chatTheme.receiverTextColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: CachedNetworkImage(
            imageUrl: message.mediaUrl!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: modernTheme.surfaceVariantColor,
              child: Center(
                child: CircularProgressIndicator(
                  color: modernTheme.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 200,
              color: modernTheme.surfaceVariantColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    color: modernTheme.textSecondaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Caption if present
        if (message.content.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SelectableText(
              message.content,
              style: TextStyle(
                fontSize: fontSize,
                color: isCurrentUser 
                  ? Colors.white
                  : modernTheme.textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileContent(BuildContext context, ModernThemeExtension modernTheme) {
    final fileName = message.mediaMetadata?['fileName'] ?? 'Unknown file';
    final fileSize = message.mediaMetadata?['fileSize'] ?? 0;
    final fileSizeText = _formatFileSize(fileSize);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser 
                ? Colors.white.withOpacity(0.2)
                : modernTheme.primaryColor?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getFileIcon(fileName),
              color: isCurrentUser 
                ? Colors.white
                : modernTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: isCurrentUser 
                      ? Colors.white
                      : modernTheme.textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fileSizeText,
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    color: isCurrentUser 
                      ? Colors.white70
                      : modernTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.download,
            color: isCurrentUser 
              ? Colors.white70
              : modernTheme.textSecondaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context, ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: TextStyle(
              fontSize: 11,
              color: isCurrentUser 
                ? Colors.white70
                : modernTheme.textTertiaryColor,
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 4),
            Icon(
              message.status.icon,
              size: 14,
              color: message.status == MessageStatus.read 
                ? modernTheme.primaryColor
                : (isCurrentUser ? Colors.white70 : modernTheme.textTertiaryColor),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

