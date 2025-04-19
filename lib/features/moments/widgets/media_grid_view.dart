// Updated MediaGridView in lib/features/moments/widgets/media_grid_view.dart

import 'package:flutter/material.dart';
import 'package:textgb/common/videoviewerscreen.dart';
import 'package:textgb/features/moments/screens/media_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class MediaGridView extends StatefulWidget {
  final List<String> mediaUrls;
  final bool isVideo;
  final String? momentDescription;

  const MediaGridView({
    Key? key,
    required this.mediaUrls,
    this.isVideo = false,
    this.momentDescription,
  }) : super(key: key);

  @override
  State<MediaGridView> createState() => _MediaGridViewState();
}

class _MediaGridViewState extends State<MediaGridView> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isLoading = true;
  double _videoAspectRatio = 16 / 9; // Default aspect ratio
  
  @override
  void initState() {
    super.initState();
    if (widget.isVideo && widget.mediaUrls.isNotEmpty) {
      _initializeVideoController();
    }
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeVideoController() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      _videoController = VideoPlayerController.network(widget.mediaUrls.first);
      await _videoController!.initialize();
      
      if (mounted) {
        // Set actual video aspect ratio
        setState(() {
          _isVideoInitialized = true;
          _isLoading = false;
          _videoAspectRatio = _videoController!.value.aspectRatio;
        });
        
        // Get a single frame as thumbnail and then pause
        _videoController!.seekTo(const Duration(milliseconds: 500));
        _videoController!.pause();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error initializing video controller: $e');
    }
  }

  // Determine if video is in portrait/vertical format
  bool get _isVerticalVideo {
    if (!_isVideoInitialized || _videoController == null) return false;
    return _videoController!.value.aspectRatio < 1.0;
  }

  // Get relative aspect ratio category for consistent sizing
  VideoAspectRatioType get _videoAspectRatioType {
    if (!_isVideoInitialized || _videoController == null) {
      return VideoAspectRatioType.widescreen; // Default
    }
    
    final ratio = _videoController!.value.aspectRatio;
    
    if (ratio < 0.6) {
      return VideoAspectRatioType.ultraTall; // Very tall video like 9:16+
    } else if (ratio < 1.0) {
      return VideoAspectRatioType.vertical; // Standard vertical like 3:4, 9:16
    } else if (ratio > 2.0) {
      return VideoAspectRatioType.ultraWide; // Extra wide video like CinemaScope
    } else if (ratio > 1.7) {
      return VideoAspectRatioType.widescreen; // 16:9 or similar
    } else {
      return VideoAspectRatioType.standard; // 4:3, 5:4, 1:1, etc.
    }
  }

  // Get the display height constraint based on aspect ratio type
  double _getVideoHeightConstraint(BuildContext context) {
    // Calculate relative to screen size for better adaptation to device
    final screenWidth = MediaQuery.of(context).size.width;
    
    switch (_videoAspectRatioType) {
      case VideoAspectRatioType.ultraTall:
        return screenWidth * 1.5; // Cap ultra tall videos
      case VideoAspectRatioType.vertical:
        return screenWidth * 1.2; // Cap vertical videos
      case VideoAspectRatioType.standard:
        return screenWidth * 0.75; // 4:3 or similar
      case VideoAspectRatioType.widescreen:
        return screenWidth * 0.56; // 16:9 (9/16 of width)
      case VideoAspectRatioType.ultraWide:
        return screenWidth * 0.4; // Extra wide formats
    }
  }

  @override
  Widget build(BuildContext context) {
    // No media
    if (widget.mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // Handle single video
    if (widget.isVideo && widget.mediaUrls.isNotEmpty) {
      return _buildVideoThumbnail(widget.mediaUrls.first, context);
    }

    // Single image
    if (widget.mediaUrls.length == 1) {
      return _buildSingleImage(widget.mediaUrls.first);
    }

    // Multiple images grid
    return _buildImageGrid();
  }

  Widget _buildSingleImage(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openMediaViewer(0),
              child: Hero(
                tag: 'media_$imageUrl',
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(String videoUrl, BuildContext context) {
    // Get aspect ratio and constraints
    final aspectRatio = _isVideoInitialized ? _videoAspectRatio : 16 / 9;
    final heightConstraint = _getVideoHeightConstraint(context);
    final isVertical = _isVerticalVideo;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // Apply appropriate height constraint based on video type
      constraints: BoxConstraints(maxHeight: heightConstraint),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.black,
            child: InkWell(
              onTap: () => _openVideoPlayer(videoUrl),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Video thumbnail or loading indicator
                    if (_isVideoInitialized)
                      VideoPlayer(_videoController!)
                    else if (_isLoading)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: Icon(
                            Icons.videocam_off,
                            color: Colors.white70,
                            size: 40,
                          ),
                        ),
                      ),
                    
                    // Improved play button overlay with more subtle design
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    
                    // No video icon badge - the play button is sufficient
                    
                    // Add subtle gradient overlay at bottom for better text visibility
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method no longer needed since we're not showing text labels
  // String _getVideoFormatLabel() {
  //   // Simply return "Video" for all types
  //   return "Video";
  // }

  Widget _buildImageGrid() {
    // Determine grid dimensions based on image count
    int crossAxisCount = 3;
    double aspectRatio = 1.0; // Square by default
    
    if (widget.mediaUrls.length == 2) {
      crossAxisCount = 2;
      aspectRatio = 1.5; // More rectangular for 2 images
    } else if (widget.mediaUrls.length == 4) {
      crossAxisCount = 2;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: widget.mediaUrls.length > 9 ? 9 : widget.mediaUrls.length,
          itemBuilder: (context, index) {
            // Show "+X more" indicator for images beyond 9
            if (index == 8 && widget.mediaUrls.length > 9) {
              return _buildMoreImagesIndicator(widget.mediaUrls.length - 8);
            }
            
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Material(
                color: Colors.grey[200],
                child: InkWell(
                  onTap: () => _openMediaViewer(index),
                  child: Hero(
                    tag: 'media_${widget.mediaUrls[index]}',
                    child: CachedNetworkImage(
                      imageUrl: widget.mediaUrls[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildMoreImagesIndicator(int moreCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openMediaViewer(8),
          child: Center(
            child: Text(
              '+$moreCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openMediaViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewScreen(
          mediaUrls: widget.mediaUrls,
          initialIndex: initialIndex,
          isVideo: widget.isVideo,
          description: widget.momentDescription,
        ),
      ),
    );
  }

  void _openVideoPlayer(String videoUrl) {
    // Stop video controller before navigating
    _videoController?.pause();
    
    Navigator.push(
      context,
      VideoViewerScreen.route(
        videoUrl: videoUrl,
        videoTitle: widget.momentDescription ?? 'Moment Video',
        allowOrientationChanges: true,
      ),
    );
  }
}

// Enum to categorize video aspect ratios for consistent UI presentation
enum VideoAspectRatioType {
  ultraTall,   // Very tall videos like 9:20
  vertical,    // Standard vertical videos like 9:16
  standard,    // 4:3, 1:1, etc
  widescreen,  // 16:9 or similar
  ultraWide,   // 21:9 or wider
}