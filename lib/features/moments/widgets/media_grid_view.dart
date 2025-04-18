import 'package:flutter/material.dart';
import 'package:textgb/common/videoviewerscreen.dart';
import 'package:textgb/features/moments/screens/media_view_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MediaGridView extends StatelessWidget {
  final List<String> mediaUrls;
  final bool isVideo;

  const MediaGridView({
    Key? key,
    required this.mediaUrls,
    this.isVideo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle single video
    if (isVideo && mediaUrls.isNotEmpty) {
      return _buildVideoThumbnail(mediaUrls.first);
    }

    // No media
    if (mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // Single image
    if (mediaUrls.length == 1) {
      return _buildSingleImage(mediaUrls.first);
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
            // Video thumbnail (here we use a placeholder, but ideally would use an actual thumbnail)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                color: Colors.black,
                child: CachedNetworkImage(
                  imageUrl: videoUrl + '?thumbnail=true', // This is a placeholder, in reality you'd have a separate thumbnail URL
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(Icons.video_library, color: Colors.white, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            
            // Play button overlay
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
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
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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
    if (mediaUrls.length == 2) {
      crossAxisCount = 2;
    } else if (mediaUrls.length == 4) {
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
        itemCount: mediaUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _openMediaViewer(index);
            },
            child: Hero(
              tag: 'media_${mediaUrls[index]}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: mediaUrls[index],
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
    // In a real app, you'd navigate to an image gallery viewer
    // For this example, we'll create a placeholder
    Navigator.push(
      _getNavigationContext()!,
      MaterialPageRoute(
        builder: (context) => MediaViewScreen(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _openVideoPlayer(String videoUrl) {
    Navigator.push(
      _getNavigationContext()!,
      VideoViewerScreen.route(
        videoUrl: videoUrl,
        videoTitle: 'Video',
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