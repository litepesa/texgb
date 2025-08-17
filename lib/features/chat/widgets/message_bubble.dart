// lib/features/chat/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/widgets/video_thumbnail_widget.dart';
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
  final VoidCallback? onVideoTap; // For video thumbnail tap
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
    this.onVideoTap,
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
          left: isCurrentUser ? 50 : 16, // Reduced left margin from 60 to 50 for current user
          right: isCurrentUser ? 16 : 50, // Reduced right margin from 60 to 50 for other user
          bottom: isLastInGroup ? 8 : 2, // Increased bottom margin to accommodate external timestamp
          top: 1,
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
          children: [
            if (message.isReply()) ...[
              _buildReplyIndicator(context, modernTheme),
              const SizedBox(height: 3),
            ],
            
            if (message.isPinned) ...[
              _buildPinIndicator(context, modernTheme),
              const SizedBox(height: 3),
            ],
            
            // Main message bubble
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85, // Further increased to 85% for even longer bubbles
              ),
              decoration: BoxDecoration(
                color: isCurrentUser 
                  ? chatTheme.senderBubbleColor 
                  : chatTheme.receiverBubbleColor,
                borderRadius: _getBubbleRadius(),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: _getBubbleRadius(),
                child: _buildMessageContent(context, modernTheme, chatTheme),
              ),
            ),
            
            // External timestamp and status
            const SizedBox(height: 2),
            _buildExternalTimestamp(context, modernTheme),
            
            if (message.isEdited) ...[
              const SizedBox(height: 1),
              _buildEditIndicator(context, modernTheme),
            ],
            
            if (message.status == MessageStatus.failed && isCurrentUser) ...[
              const SizedBox(height: 3),
              _buildRetryIndicator(context, modernTheme),
            ],
          ],
        ),
      ),
    );
  }

  BorderRadius _getBubbleRadius() {
    const radius = 28.0; // Even more rounded for ultra-modern look
    
    return BorderRadius.circular(radius);
  }

  Widget _buildExternalTimestamp(BuildContext context, ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: isCurrentUser 
          ? MainAxisAlignment.end 
          : MainAxisAlignment.start,
        children: [
          Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: modernTheme.textTertiaryColor,
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 3),
            _buildMessageStatusIcon(modernTheme),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyIndicator(BuildContext context, ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor?.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.reply,
            size: 12,
            color: modernTheme.textSecondaryColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Replying to ${message.replyToSender == message.senderId ? 'themselves' : (contactName ?? 'contact')}',
              style: TextStyle(
                fontSize: 11,
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
          fontSize: 10,
          color: modernTheme.textTertiaryColor,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildRetryIndicator(BuildContext context, ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: onLongPress,
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
              'Failed',
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
        return _buildImageContent(context, modernTheme, chatTheme);
      case MessageEnum.file:
        return _buildFileContent(context, modernTheme, chatTheme);
      case MessageEnum.video: // Handle video messages
        // Check if this is a shared video or regular video
        final isSharedVideo = message.mediaMetadata?['isSharedVideo'] == true;
        if (isSharedVideo) {
          return _buildSharedVideoContent(context, modernTheme, chatTheme);
        } else {
          return _buildRegularVideoContent(context, modernTheme, chatTheme);
        }
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4), // Further reduced vertical padding and increased horizontal
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isReply() && message.replyToContent != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isCurrentUser 
                  ? Colors.white.withOpacity(0.15)
                  : modernTheme.surfaceVariantColor?.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: modernTheme.primaryColor!,
                    width: 2,
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
            const SizedBox(height: 3), // Further reduced from 4 to 3
          ],
          
          SelectableText(
            message.content,
            style: TextStyle(
              fontSize: fontSize,
              color: isCurrentUser 
                ? chatTheme.senderTextColor
                : chatTheme.receiverTextColor,
              height: 1.15, // Further reduced line height from 1.2 to 1.15 for maximum compactness
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, ModernThemeExtension modernTheme, ChatThemeExtension chatTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28), // Updated to match new bubble radius
            topRight: Radius.circular(28), // Updated to match new bubble radius
          ),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: message.mediaUrl ?? '',
                width: double.infinity,
                height: 200, // Increased back to a tall height for better image viewing experience
                fit: BoxFit.cover,
                placeholder: (BuildContext context, String url) => Container(
                  height: 200, // Updated to match new tall height
                  color: modernTheme.surfaceVariantColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: modernTheme.primaryColor,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                errorWidget: (BuildContext context, String url, dynamic error) => Container(
                  height: 200, // Updated to match new height
                  color: modernTheme.surfaceVariantColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        color: modernTheme.textSecondaryColor,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Failed to load',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              if (message.mediaMetadata?['isUploading'] == true) ...[
                Container(
                  height: 200, // Updated to match new tall height
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Uploading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
        
        if (message.content.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 3, 16, 4), // Further reduced top padding from 4 to 3
            child: SelectableText(
              message.content,
              style: TextStyle(
                fontSize: fontSize,
                color: isCurrentUser 
                  ? chatTheme.senderTextColor
                  : chatTheme.receiverTextColor,
                height: 1.15, // Further reduced line height for ultra-compact text
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileContent(BuildContext context, ModernThemeExtension modernTheme, ChatThemeExtension chatTheme) {
    final fileName = message.mediaMetadata?['fileName'] ?? 'Unknown file';
    final fileSize = message.mediaMetadata?['fileSize'] ?? 0;
    final fileSizeText = _formatFileSize(fileSize);
    final isUploading = message.mediaMetadata?['isUploading'] == true;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4), // Further reduced and increased horizontal padding
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCurrentUser 
                ? Colors.white.withOpacity(0.2)
                : modernTheme.primaryColor?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: isUploading
                ? SizedBox(
                    width: 20,
                    height: 20,
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
                    size: 20,
                  ),
          ),
          const SizedBox(width: 10),
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
              size: 18,
            ),
          ],
        ],
      ),
    );
  }

  // ENHANCED: Build shared video content with generated thumbnails
  Widget _buildSharedVideoContent(BuildContext context, ModernThemeExtension modernTheme, ChatThemeExtension chatTheme) {
    final thumbnailUrl = message.mediaMetadata?['thumbnailUrl'] ?? '';
    final originalCaption = message.mediaMetadata?['originalCaption'];
    final channelName = message.mediaMetadata?['channelName'];
    final videoLink = message.mediaMetadata?['videoLink'] ?? message.mediaUrl;
    
    return GestureDetector(
      onTap: onVideoTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail with play overlay using VideoThumbnailWidget
          VideoThumbnailWidget(
            videoUrl: videoLink ?? '',
            fallbackThumbnailUrl: thumbnailUrl.isNotEmpty ? thumbnailUrl : null,
            width: double.infinity,
            height: 180,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            onTap: onVideoTap,
            showPlayButton: true,
            overlayWidget: Stack(
              children: [
                // Shared video indicator with channel name
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.video_library,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          channelName != null && channelName.isNotEmpty 
                            ? 'From $channelName'
                            : 'Shared Video',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Video details section
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main message content (descriptive text)
                if (message.content.isNotEmpty) ...[
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: isCurrentUser 
                        ? chatTheme.senderTextColor
                        : chatTheme.receiverTextColor,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Original video caption if available
                if (originalCaption != null && originalCaption.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCurrentUser 
                        ? Colors.white.withOpacity(0.1)
                        : modernTheme.surfaceVariantColor?.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: modernTheme.primaryColor!,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      originalCaption,
                      style: TextStyle(
                        fontSize: fontSize - 1,
                        color: isCurrentUser 
                          ? chatTheme.senderTextColor?.withOpacity(0.8)
                          : chatTheme.receiverTextColor?.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                
                // Video link action
                if (videoLink != null && videoLink.isNotEmpty) ...[
                  GestureDetector(
                    onTap: onVideoTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor?.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: modernTheme.primaryColor!.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            size: 16,
                            color: modernTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Play Video',
                            style: TextStyle(
                              fontSize: fontSize - 2,
                              color: modernTheme.primaryColor,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  // UPDATED: Build regular video content to use VideoThumbnailWidget
  Widget _buildRegularVideoContent(BuildContext context, ModernThemeExtension modernTheme, ChatThemeExtension chatTheme) {
    final videoUrl = message.mediaUrl ?? '';
    final isUploading = message.mediaMetadata?['isUploading'] == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video thumbnail/player section
        VideoThumbnailWidget(
          videoUrl: videoUrl,
          width: double.infinity,
          height: 200,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          onTap: onVideoTap,
          showPlayButton: !isUploading,
          overlayWidget: isUploading ? Container(
            height: 200,
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Uploading video...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ) : null,
        ),
        
        // Caption if present
        if (message.content.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 3, 16, 4),
            child: SelectableText(
              message.content,
              style: TextStyle(
                fontSize: fontSize,
                color: isCurrentUser 
                  ? chatTheme.senderTextColor
                  : chatTheme.receiverTextColor,
                height: 1.15,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Video placeholder widget
  Widget _buildVideoPlaceholder(ModernThemeExtension modernTheme) {
    return Container(
      height: 180,
      color: modernTheme.surfaceVariantColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: modernTheme.textSecondaryColor,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            'Video unavailable',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageStatusIcon(ModernThemeExtension modernTheme) {
    Color iconColor;
    IconData iconData = message.status.icon;
    
    switch (message.status) {
      case MessageStatus.sending:
        iconColor = modernTheme.textTertiaryColor ?? Colors.grey;
        break;
      case MessageStatus.sent:
        iconColor = modernTheme.textTertiaryColor ?? Colors.grey;
        break;
      case MessageStatus.delivered:
        iconColor = modernTheme.textTertiaryColor ?? Colors.grey;
        break;
      case MessageStatus.failed:
        iconColor = Colors.red.shade400;
        break;
      case MessageStatus.read:
        throw UnimplementedError();
    }
    
    return Icon(
      iconData,
      size: 12,
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