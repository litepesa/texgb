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
            
            // Failed message retry option
            if (message.status == MessageStatus.failed && isCurrentUser) ...[
              const SizedBox(height: 4),
              _buildRetryIndicator(context, modernTheme),
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

  Widget _buildRetryIndicator(BuildContext context, ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: () {
        // Trigger retry - this would be handled by the parent widget
        if (onLongPress != null) onLongPress!();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 12,
              color: Colors.red,
            ),
            const SizedBox(width: 4),
            const Text(
              'Failed to send',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Tap to retry',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
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
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: message.mediaUrl ?? '',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: modernTheme.surfaceVariantColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: modernTheme.primaryColor,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Loading image...',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                      const SizedBox(height: 4),
                      Text(
                        'Tap to retry',
                        style: TextStyle(
                          color: modernTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Upload progress indicator
              if (message.mediaMetadata?['isUploading'] == true) ...[
                Container(
                  height: 200,
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Uploading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
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
    final isUploading = message.mediaMetadata?['isUploading'] == true;
    
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
            child: isUploading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: isCurrentUser 
                        ? Colors.white
                        : modernTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
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
                Row(
                  children: [
                    Text(
                      fileSizeText,
                      style: TextStyle(
                        fontSize: fontSize - 2,
                        color: isCurrentUser 
                          ? Colors.white70
                          : modernTheme.textSecondaryColor,
                      ),
                    ),
                    if (isUploading) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• Uploading...',
                        style: TextStyle(
                          fontSize: fontSize - 2,
                          color: isCurrentUser 
                            ? Colors.white70
                            : modernTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isUploading) ...[
            Icon(
              Icons.download,
              color: isCurrentUser 
                ? Colors.white70
                : modernTheme.textSecondaryColor,
              size: 20,
            ),
          ],
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
            _buildMessageStatusIcon(modernTheme),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageStatusIcon(ModernThemeExtension modernTheme) {
    Color iconColor;
    IconData iconData = message.status.icon;
    
    switch (message.status) {
      case MessageStatus.sending:
        iconColor = Colors.white54;
        break;
      case MessageStatus.sent:
        iconColor = Colors.white70; // Single grey tick
        break;
      case MessageStatus.delivered:
        iconColor = Colors.white70; // Double grey ticks
        break;
      case MessageStatus.failed:
        iconColor = Colors.red.shade300;
        break;
      case MessageStatus.read:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
    
    return Icon(
      iconData,
      size: 14,
      color: iconColor,
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
      case '7z':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return Icons.video_file;
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