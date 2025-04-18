import 'package:flutter/material.dart';
import 'package:textgb/common/videoviewerscreen.dart';
import 'package:textgb/features/moments/screens/media_view_screen.dart';
import 'package:textgb/main_screen/media_viewer_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class MediaGridView extends StatefulWidget {
  final List<String> mediaUrls;
  final bool isVideo;

  const MediaGridView({
    Key? key,
    required this.mediaUrls,
    this.isVideo = false,
  }) : super(key: key);

  @override
  State<MediaGridView> createState() => _MediaGridViewState();
}

class _MediaGridViewState extends State<MediaGridView> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
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
      _videoController = VideoPlayerController.network(widget.mediaUrls.first);
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        // Get a single frame as thumbnail and then pause
        _videoController!.seekTo(const Duration(milliseconds: 500));
        _videoController!.pause();
      }
    } catch (e) {
      debugPrint('Error initializing video controller: $e');
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
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: () {
          _openMediaViewer(0);
        },
        child: Hero(
          tag: 'media_$imageUrl',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
    );
  }

  Widget _buildVideoThumbnail(String videoUrl) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: () {
          _openVideoPlayer(videoUrl);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _isVideoInitialized
                  ? VideoPlayer(_videoController!)
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
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
            
            // Video indicator
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    // Determine grid dimensions based on image count
    int crossAxisCount = 3;
    if (widget.mediaUrls.length == 2) {
      crossAxisCount = 2;
    } else if (widget.mediaUrls.length == 4) {
      crossAxisCount = 2;
    }

    return AspectRatio(
      aspectRatio: 1, // Square grid
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: widget.mediaUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _openMediaViewer(index);
            },
            child: Hero(
              tag: 'media_${widget.mediaUrls[index]}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: widget.mediaUrls[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openMediaViewer(int initialIndex) {
    Navigator.push(
      _getNavigationContext()!,
      MaterialPageRoute(
        builder: (context) => MediaViewScreen(
          mediaUrls: widget.mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _openVideoPlayer(String videoUrl) {
    // Stop video controller before navigating
    _videoController?.pause();
    
    Navigator.push(
      _getNavigationContext()!,
      VideoViewerScreen.route(
        videoUrl: videoUrl,
        videoTitle: 'Moment Video',
        allowOrientationChanges: true,
      ),
    );
  }

  // Helper to get the nearest BuildContext for navigation
  BuildContext? _getNavigationContext() {
    return globalNavigatorKey.currentContext;
  }
}

// For navigation without context
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();