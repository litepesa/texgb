import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/status/screens/media_view_screen.dart';

class MediaGridView extends StatelessWidget {
  final List<String> mediaUrls;
  final String? caption;

  const MediaGridView({
    Key? key,
    required this.mediaUrls,
    this.caption,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

  Widget _buildImageGrid() {
    // Determine grid dimensions based on image count
    int crossAxisCount = 3;
    double aspectRatio = 1.0; // Square by default
    
    if (mediaUrls.length == 2) {
      crossAxisCount = 2;
      aspectRatio = 1.5; // More rectangular for 2 images
    } else if (mediaUrls.length == 4) {
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
          itemCount: mediaUrls.length > 9 ? 9 : mediaUrls.length,
          itemBuilder: (context, index) {
            // Show "+X more" indicator for images beyond 9
            if (index == 8 && mediaUrls.length > 9) {
              return _buildMoreImagesIndicator(mediaUrls.length - 8);
            }
            
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Material(
                color: Colors.grey[200],
                child: InkWell(
                  onTap: () => _openMediaViewer(index),
                  child: Hero(
                    tag: 'media_${mediaUrls[index]}',
                    child: CachedNetworkImage(
                      imageUrl: mediaUrls[index],
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

  // Open fullscreen media viewer
  void _openMediaViewer(int initialIndex) {
    // To be implemented
    // This would normally open a fullscreen gallery
    Navigator.push(
      builder.context,
      MaterialPageRoute(
        builder: (context) => MediaViewScreen(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
          caption: caption,
        ),
      ),
    );
  }
}