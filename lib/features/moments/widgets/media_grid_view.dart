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

  @override
  Widget build(BuildContext context) {
    // No media
    if (widget.mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // Handle single video
    if (widget.isVideo && widget.mediaUrls.isNotEmpty) {
      return _buildVideoThumbnail(widget.mediaUrls.first);
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

  Widget _buildVideoThumbnail(String videoUrl) {
    // Determine the aspect ratio and layout based on video orientation
    final aspectRatio = _isVideoInitialized ? _videoAspectRatio : 16 / 9;
    final isVertical = _isVerticalVideo;
    
    // For vertical videos, we'll use a different container approach
    if (isVertical) {
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
        // Limit the height for vertical videos to not take too much space
        constraints: const BoxConstraints(maxHeight: 350),
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
                    children: _buildVideoStackChildren(videoUrl),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Standard 16:9 or similar horizontal videos
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
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
              color: Colors.black,
              child: InkWell(
                onTap: () => _openVideoPlayer(videoUrl),
                child: Stack(
                  fit: StackFit.expand,
                  children: _buildVideoStackChildren(videoUrl),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
  
  // Extracted the common stack children for video thumbnails
  List<Widget> _buildVideoStackChildren(String videoUrl) {
    return [
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
      
      // Play button overlay
      Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
      
      // Video type indicator badge (now shows format)
      Positioned(
        bottom: 8,
        right: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                _isVerticalVideo ? 'Vertical' : 'Video',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

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