// lib/features/chat/widgets/status_reply_bubble.dart

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/models/message_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusReplyBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  const StatusReplyBubble({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  State<StatusReplyBubble> createState() => _StatusReplyBubbleState();
}

class _StatusReplyBubbleState extends State<StatusReplyBubble> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLoadingVideo = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoIfNeeded();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoIfNeeded() async {
    // Check if this is a video status
    final MessageEnum repliedType = widget.message.repliedMessageType ?? MessageEnum.text;
    
    if (repliedType == MessageEnum.video && 
        widget.message.statusThumbnailUrl != null && 
        widget.message.statusThumbnailUrl!.isNotEmpty) {
      
      setState(() {
        _isLoadingVideo = true;
      });
      
      try {
        _videoController = VideoPlayerController.network(
          widget.message.statusThumbnailUrl!,
        );
        
        await _videoController!.initialize();
        
        // Ensure video is ready
        if (_videoController!.value.isInitialized) {
          // Move to a specific position for the thumbnail (1 second in)
          await _videoController!.seekTo(const Duration(seconds: 1));
          
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
              _isLoadingVideo = false;
            });
          }
        } else {
          // Video couldn't be initialized
          if (mounted) {
            setState(() {
              _isLoadingVideo = false;
            });
          }
        }
      } catch (e) {
        debugPrint('Error initializing video for thumbnail: $e');
        if (mounted) {
          setState(() {
            _isLoadingVideo = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;

    // Get replied message type and convert to StatusType
    final MessageEnum repliedType = widget.message.repliedMessageType ?? MessageEnum.text;
    final StatusType statusType = _messageEnumToStatusType(repliedType);
    
    // Get username from the message
    final String username = widget.message.repliedTo == 'You' ? 'You' : widget.message.repliedTo;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status thumbnail on the left
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 60,
              height: 60,
              child: _buildStatusThumbnail(statusType, modernTheme),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Status info on the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with username only (removed status indicator)
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Status caption if available
                if (widget.message.statusCaption != null && widget.message.statusCaption!.isNotEmpty)
                  Text(
                    widget.message.statusCaption!,
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    _getStatusTypeText(statusType),
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusThumbnail(StatusType statusType, ModernThemeExtension modernTheme) {
    // For video with initialized controller
    if (statusType == StatusType.video && _isVideoInitialized && _videoController != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // Video frame as thumbnail
          VideoPlayer(_videoController!),
          
          // Play button overlay
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      );
    }
    
    // For video still loading
    if (statusType == StatusType.video && _isLoadingVideo) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: modernTheme.primaryColor,
          ),
        ),
      );
    }
    
    // For image or other media types with thumbnail URL
    if (widget.message.statusThumbnailUrl != null && widget.message.statusThumbnailUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.message.statusThumbnailUrl!,
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: modernTheme.primaryColor,
              ),
            ),
            errorWidget: (context, url, error) => _buildPlaceholder(statusType, modernTheme),
          ),
          
          if (statusType == StatusType.video)
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      );
    }
    
    // Fallback placeholder when no thumbnail
    return _buildPlaceholder(statusType, modernTheme);
  }
  
  Widget _buildPlaceholder(StatusType statusType, ModernThemeExtension modernTheme) {
    return Container(
      color: widget.isMe 
          ? modernTheme.secondaryColor!.withOpacity(0.1)
          : modernTheme.primaryColor!.withOpacity(0.05),
      child: Center(
        child: Icon(
          _getStatusTypeIcon(statusType),
          size: 24,
          color: modernTheme.textSecondaryColor!.withOpacity(0.5),
        ),
      ),
    );
  }
  
  StatusType _messageEnumToStatusType(MessageEnum messageType) {
    switch (messageType) {
      case MessageEnum.image:
        return StatusType.image;
      case MessageEnum.video:
        return StatusType.video;
      case MessageEnum.text:
        return StatusType.text;
      default:
        return StatusType.image;
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