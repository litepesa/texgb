// lib/features/chat/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/features/chat/widgets/video_thumbnail_widget.dart';
import 'package:textgb/features/chat/widgets/message_reply_preview.dart';
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
            if (message.isPinned) ...[
              _buildPinIndicator(context, modernTheme),
              const SizedBox(height: 3),
            ],
            
            // Main message bubble
            Container(
              constraints: BoxConstraints(
                maxWidth: _isMediaMessage() 
                  ? MediaQuery.of(context).size.width * 0.60 // Even narrower for standing rectangle look
                  : MediaQuery.of(context).size.width * 0.85, // Wider for text messages
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

  // Helper method to check if message is media type
  bool _isMediaMessage() {
    return message.type == MessageEnum.image || 
           message.type == MessageEnum.video;
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
        return _buildVideoContent(context, modernTheme, chatTheme);
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
          // Reply preview inside the bubble - shows the message we're replying TO
          if (message.isReply()) ...[
            _buildInnerReplyPreview(context, modernTheme),
            const SizedBox(height: 8),
          ],
          
          // The actual reply content (our new message)
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

  // Build the inner reply preview showing the message we're replying TO
  Widget _buildInnerReplyPreview(BuildContext context, ModernThemeExtension modernTheme) {
    // Create a mock MessageModel for the replied-to message using the reply fields
    final repliedToMessage = MessageModel(
      messageId: message.replyToMessageId ?? '',
      chatId: message.chatId,
      senderId: message.replyToSender ?? '',
      content: message.replyToContent ?? '',
      type: _getReplyMessageType(), // Convert from stored reply type
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      // For media replies, we'd need to store the mediaUrl in reply metadata
      mediaUrl: _getReplyMediaUrl(),
    );

    return MessageReplyPreview(
      replyToMessage: repliedToMessage,
      contactName: _getReplyToContactName(),
      viewOnly: true, // No cancel button inside bubble
    );
  }

  // Helper method to get reply message type
  MessageEnum _getReplyMessageType() {
    // If we have replyToContent and it indicates a media type, return that type
    // Otherwise default to text
    // In a real implementation, you'd store the original message type in the reply metadata
    if (message.replyToContent?.startsWith('📷') == true) {
      return MessageEnum.image;
    } else if (message.replyToContent?.startsWith('📹') == true) {
      return MessageEnum.video;
    } else if (message.replyToContent?.startsWith('📎') == true) {
      return MessageEnum.file;
    } else if (message.replyToContent?.startsWith('🎤') == true) {
      return MessageEnum.audio;
    } else if (message.replyToContent?.startsWith('📍') == true) {
      return MessageEnum.location;
    } else if (message.replyToContent?.startsWith('👤') == true) {
      return MessageEnum.contact;
    }
    return MessageEnum.text;
  }

  // Helper method to get reply media URL
  String? _getReplyMediaUrl() {
    // In a real implementation, you'd store the original media URL in reply metadata
    // For now, return null since we don't have this data structure
    return null;
  }

  // Helper method to get reply-to contact name
  String? _getReplyToContactName() {
    // Use the replyToSender field, or fall back to contactName, or 'Contact'
    if (message.replyToSender != null && message.replyToSender!.isNotEmpty) {
      // In a real implementation, you'd resolve sender ID to contact name
      return message.replyToSender == message.senderId ? 'You' : contactName;
    }
    return contactName ?? 'Contact';
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
                height: 320, // Even taller for standing rounded rectangle look
                fit: BoxFit.cover,
                placeholder: (BuildContext context, String url) => Container(
                  height: 320, // Updated to match new taller height
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
                  height: 320, // Updated to match new taller height
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
                  height: 320, // Updated to match new taller height
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
        
        // Content section with reply preview and caption
        if (message.isReply() || message.content.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reply preview for media messages - shows the message we're replying TO
                if (message.isReply()) ...[
                  _buildInnerReplyPreview(context, modernTheme),
                  const SizedBox(height: 8),
                ],
                
                // Caption if present (our new message content)
                if (message.content.isNotEmpty) ...[
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: isCurrentUser 
                        ? chatTheme.senderTextColor
                        : chatTheme.receiverTextColor,
                      height: 1.15,
                    ),
                  ),
                ],
              ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply preview for file messages - shows the message we're replying TO
          if (message.isReply()) ...[
            _buildInnerReplyPreview(context, modernTheme),
            const SizedBox(height: 8),
          ],
          
          // File content
          Row(
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
        ],
      ),
    );
  }

  // CLEAN: Simple video content like image bubble - just thumbnail with play button
  Widget _buildVideoContent(BuildContext context, ModernThemeExtension modernTheme, ChatThemeExtension chatTheme) {
    final videoUrl = message.mediaUrl ?? '';
    final isUploading = message.mediaMetadata?['isUploading'] == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clean video thumbnail with just play button overlay
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: Stack(
            children: [
              // Video thumbnail using VideoThumbnailWidget
              VideoThumbnailWidget(
                videoUrl: videoUrl,
                width: double.infinity,
                height: 320, // Taller height for standing rounded rectangle look
                borderRadius: BorderRadius.zero, // No additional border radius since parent handles it
                onTap: onVideoTap,
                showPlayButton: false, // We'll add our own clean play button
              ),
              
              // Clean play button overlay (only if not uploading)
              if (!isUploading)
                Positioned.fill(
                  child: Center(
                    child: GestureDetector(
                      onTap: onVideoTap,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Upload overlay (same as image)
              if (isUploading)
                Container(
                  height: 320, // Updated to match taller height
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
          ),
        ),
        
        // Content section with reply preview and caption (same as image)
        if (message.isReply() || message.content.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reply preview for video messages - shows the message we're replying TO
                if (message.isReply()) ...[
                  _buildInnerReplyPreview(context, modernTheme),
                  const SizedBox(height: 8),
                ],
                
                // Caption if present (our new message content)
                if (message.content.isNotEmpty) ...[
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: isCurrentUser 
                        ? chatTheme.senderTextColor
                        : chatTheme.receiverTextColor,
                      height: 1.15,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
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