// lib/features/video_reactions/widgets/video_reaction_reply_preview.dart
// COPIED: Exact same UI as chat reply preview but for video reaction messages
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/video_reactions/models/video_reaction_message_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class VideoReactionReplyPreview extends StatelessWidget {
  final VideoReactionMessageModel replyToMessage;
  final String? contactName;
  final VoidCallback? onCancel;
  final bool viewOnly;

  const VideoReactionReplyPreview({
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
      margin: EdgeInsets.only(
        left: viewOnly ? 0 : 16,
        right: viewOnly ? 0 : 16,
        bottom: viewOnly ? 0 : 8,
      ),
      decoration: BoxDecoration(
        color: viewOnly 
          ? modernTheme.surfaceVariantColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.1)
          : chatTheme.inputBackgroundColor?.withOpacity(0.8) ?? modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(viewOnly ? 8 : 16),
        border: Border.all(
          color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
          width: viewOnly ? 1 : 2,
        ),
        boxShadow: viewOnly ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(viewOnly ? 8 : 12),
        child: Row(
          children: [
            // Reply indicator line
            Container(
              width: 3,
              height: viewOnly ? 30 : 40,
              decoration: BoxDecoration(
                color: modernTheme.primaryColor ?? Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Media thumbnail (if applicable)
            if (_shouldShowMediaThumbnail()) ...[
              _buildMediaThumbnail(modernTheme),
              const SizedBox(width: 8),
            ],
            
            // Reply content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sender name
                  Text(
                    _getSenderDisplayName(),
                    style: TextStyle(
                      color: modernTheme.primaryColor ?? Colors.blue,
                      fontSize: viewOnly ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2),
                  
                  // Message preview
                  Text(
                    _getMessagePreview(),
                    style: TextStyle(
                      color: viewOnly 
                        ? modernTheme.textSecondaryColor?.withOpacity(0.8)
                        : modernTheme.textSecondaryColor,
                      fontSize: viewOnly ? 11 : 13,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: viewOnly ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Cancel button (only for non-view-only mode)
            if (!viewOnly && onCancel != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: modernTheme.textSecondaryColor?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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

  bool _shouldShowMediaThumbnail() {
    // Show thumbnail for media messages or original video reaction messages
    return replyToMessage.hasMedia() || 
           (replyToMessage.isOriginalReaction && replyToMessage.videoReactionData != null);
  }

  Widget _buildMediaThumbnail(ModernThemeExtension modernTheme) {
    final size = viewOnly ? 32.0 : 40.0;
    final borderRadius = viewOnly ? 6.0 : 8.0;
    
    // Handle original video reaction messages
    if (replyToMessage.isOriginalReaction && replyToMessage.videoReactionData != null) {
      final videoReaction = replyToMessage.videoReactionData!;
      final thumbnailUrl = videoReaction.thumbnailUrl.isNotEmpty 
          ? videoReaction.thumbnailUrl 
          : videoReaction.videoUrl;
      
      if (thumbnailUrl.isNotEmpty) {
        return _buildNetworkImageThumbnail(thumbnailUrl, size, borderRadius, modernTheme);
      } else {
        return _buildVideoPlaceholder(size, borderRadius, modernTheme);
      }
    }
    
    // Handle regular media messages
    switch (replyToMessage.type) {
      case MessageEnum.image:
        if (replyToMessage.mediaUrl?.isNotEmpty == true) {
          return _buildNetworkImageThumbnail(replyToMessage.mediaUrl!, size, borderRadius, modernTheme);
        }
        return _buildImagePlaceholder(size, borderRadius, modernTheme);
        
      case MessageEnum.video:
        if (replyToMessage.mediaUrl?.isNotEmpty == true) {
          return Stack(
            children: [
              _buildNetworkImageThumbnail(replyToMessage.mediaUrl!, size, borderRadius, modernTheme),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: size * 0.4,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return _buildVideoPlaceholder(size, borderRadius, modernTheme);
        
      case MessageEnum.file:
        return _buildFileThumbnail(size, borderRadius, modernTheme);
        
      case MessageEnum.audio:
        return _buildAudioThumbnail(size, borderRadius, modernTheme);
        
      case MessageEnum.location:
        return _buildLocationThumbnail(size, borderRadius, modernTheme);
        
      case MessageEnum.contact:
        return _buildContactThumbnail(size, borderRadius, modernTheme);
        
      default:
        return _buildDefaultThumbnail(size, borderRadius, modernTheme);
    }
  }

  Widget _buildNetworkImageThumbnail(String url, double size, double borderRadius, ModernThemeExtension modernTheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: modernTheme.surfaceVariantColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.2),
            child: Center(
              child: SizedBox(
                width: size * 0.4,
                height: size * 0.4,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: modernTheme.primaryColor,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: modernTheme.surfaceVariantColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.2),
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: modernTheme.textSecondaryColor,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(double size, double borderRadius, ModernThemeExtension modernTheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: modernTheme.textSecondaryColor,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder(double size, double borderRadius, ModernThemeExtension modernTheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              color: modernTheme.textSecondaryColor,
              size: size * 0.5,
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: size * 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileThumbnail(double size, double borderRadius, ModernThemeExtension modernTheme) {
    final fileName = replyToMessage.mediaMetadata?['fileName'] ?? '';
    final fileIcon = _getFileIcon(fileName);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: modernTheme.primaryColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          fileIcon,
          color: modernTheme.primaryColor ?? Colors.blue,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildAudioThumbnail(double size, double borderRadius, ModernThemeExtension modernTheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.mic,
          color: Colors.orange,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildLocationThumbnail(double size, double borderRadius, ModernThemeExtension modernTheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.location_on,
          color: Colors.green,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildContactThumbnail(double size, double borderRadius, ModernThemeExtension modernTheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: Colors.purple,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildDefaultThumbnail(double size, double borderRadius, ModernThemeExtension modernTheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: modernTheme.surfaceVariantColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          Icons.insert_drive_file_outlined,
          color: modernTheme.textSecondaryColor,
          size: size * 0.5,
        ),
      ),
    );
  }

  String _getSenderDisplayName() {
    // For original video reaction messages, use the video creator name
    if (replyToMessage.isOriginalReaction && replyToMessage.videoReactionData != null) {
      return replyToMessage.videoReactionData!.userName;
    }
    
    // For regular messages, use contact name or fallback
    return contactName ?? 'Contact';
  }

  String _getMessagePreview() {
    // For original video reaction messages, show the reaction or "shared a video"
    if (replyToMessage.isOriginalReaction && replyToMessage.videoReactionData != null) {
      final videoReaction = replyToMessage.videoReactionData!;
      if (videoReaction.hasReaction) {
        return videoReaction.reaction!;
      } else {
        return 'Shared a video';
      }
    }
    
    // For regular messages, use the display content
    return replyToMessage.getDisplayContent();
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.isEmpty) return Icons.insert_drive_file;
    
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
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}