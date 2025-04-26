import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/chat/screens/media_viewer_screen.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;

class MediaMessageDisplay extends StatefulWidget {
  final String mediaUrl;
  final bool isImage;
  final bool viewOnly;
  final double maxWidth;
  final double maxHeight;
  final String? caption;
  
  const MediaMessageDisplay({
    Key? key,
    required this.mediaUrl,
    required this.isImage,
    this.viewOnly = false,
    this.maxWidth = 220,
    this.maxHeight = 200,
    this.caption,
  }) : super(key: key);

  @override
  State<MediaMessageDisplay> createState() => _MediaMessageDisplayState();
}

class _MediaMessageDisplayState extends State<MediaMessageDisplay> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
  @override
  void initState() {
    super.initState();
    if (!widget.isImage) {
      _initializeVideoController();
    }
  }
  
  Future<void> _initializeVideoController() async {
    _videoController = VideoPlayerController.network(widget.mediaUrl);
    
    try {
      await _videoController!.initialize();
      // Ensure the first frame is shown
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      // Video failed to initialize
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.viewOnly 
          ? null 
          : () => _openMediaViewer(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
          maxHeight: widget.maxHeight,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.responsiveTheme.compactRadius / 2),
          child: widget.isImage
              ? _buildImagePreview(context)
              : _buildVideoPreview(context),
        ),
      ),
    );
  }
  
  Widget _buildImagePreview(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Stack(
      children: [
        // Image
        CachedNetworkImage(
          imageUrl: widget.mediaUrl,
          fit: BoxFit.cover,
          width: widget.maxWidth,
          height: isSquareImage() ? widget.maxWidth : null,
          placeholder: (context, url) => Container(
            width: widget.maxWidth,
            height: widget.maxWidth * 0.75,
            color: modernTheme.surfaceVariantColor,
            child: Center(
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: widget.maxWidth,
            height: widget.maxWidth * 0.75,
            color: modernTheme.surfaceVariantColor,
            child: Center(
              child: Icon(
                Icons.error,
                color: modernTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
        
        // Caption if provided
        if (widget.caption != null && widget.caption!.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: context.responsiveTheme.compactSpacing * 0.75,
                horizontal: context.responsiveTheme.compactSpacing * 1.25,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Text(
                widget.caption!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildVideoPreview(BuildContext context) {
    final modernTheme = context.modernTheme;
    final animationTheme = context.animationTheme;
    
    return Stack(
      children: [
        // Video thumbnail using video_player with adaptive sizing for different aspect ratios
        Container(
          constraints: BoxConstraints(
            maxWidth: widget.maxWidth,
            // Minimum height to avoid tiny vertical videos
            minHeight: 120,
            // Maximum height for tall videos
            maxHeight: _isVideoInitialized && _videoController != null
                ? _calculateOptimalVideoHeight()
                : widget.maxWidth * 1.5, // Default max height for loading state
          ),
          color: modernTheme.surfaceVariantColor,
          child: _isVideoInitialized && _videoController != null
              ? FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              : Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: modernTheme.primaryColor,
                    ),
                  ),
                ),
        ),
        
        // Play button overlay
        Positioned.fill(
          child: Center(
            child: AnimatedContainer(
              duration: animationTheme.shortDuration,
              curve: animationTheme.standardCurve,
              padding: EdgeInsets.all(context.responsiveTheme.compactSpacing * 1.5),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor?.withOpacity(0.7) ?? Colors.black.withOpacity(0.5),
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
        
        // Video duration indicator
        if (_isVideoInitialized && _videoController != null)
          Positioned(
            right: context.responsiveTheme.compactSpacing,
            bottom: context.responsiveTheme.compactSpacing,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveTheme.compactSpacing * 0.75,
                vertical: context.responsiveTheme.compactSpacing * 0.25,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(context.responsiveTheme.compactRadius / 2),
              ),
              child: Text(
                _formatDuration(_videoController!.value.duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
  
  // Calculate the optimal height based on the video's aspect ratio
  double _calculateOptimalVideoHeight() {
    if (_videoController == null || !_isVideoInitialized) {
      return widget.maxWidth * 0.75; // Default fallback ratio
    }
    
    final videoRatio = _videoController!.value.aspectRatio;
    
    // For vertical videos (ratio < 1)
    if (videoRatio < 1) {
      // Use a taller container, but not too tall
      return math.min(widget.maxWidth / videoRatio, widget.maxWidth * 1.8);
    } 
    // For square or horizontal videos (ratio >= 1)
    else {
      // Use standard height calculation, but ensure minimum height
      return math.max(widget.maxWidth / videoRatio, 120);
    }
  }
  
  bool isSquareImage() {
    // In practice, we would check the actual image dimensions
    // For now, we're just assuming a default aspect ratio
    return false;
  }
  
  void _openMediaViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(
          mediaUrl: widget.mediaUrl,
          isImage: widget.isImage,
          caption: widget.caption,
        ),
      ),
    );
  }
}