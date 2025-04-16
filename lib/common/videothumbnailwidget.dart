import 'package:flutter/material.dart';
import 'package:textgb/common/videoviewerscreen.dart';

class VideoThumbnailWidget extends StatelessWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final String? title;
  final Color accentColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final VoidCallback? onTap;

  const VideoThumbnailWidget({
    Key? key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.title,
    this.accentColor = const Color(0xFF2196F3),
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // If an onTap callback is provided, use it
        if (onTap != null) {
          onTap!();
        } else {
          // Otherwise, navigate to the VideoViewerScreen
          Navigator.of(context).push(
            VideoViewerScreen.route(
              videoUrl: videoUrl,
              videoTitle: title,
              accentColor: accentColor,
            ),
          );
        }
      },
      child: Container(
        width: width,
        height: height ?? 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video thumbnail
            thumbnailUrl != null
                ? Image.network(
                    thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.video_file,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[900],
                    child: const Icon(
                      Icons.video_file,
                      color: Colors.white54,
                      size: 48,
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
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            // Duration indicator (optional placeholder)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "Video",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Title overlay (if provided)
            if (title != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Make sure to import your VideoViewerScreen class
// import 'video_viewer_screen.dart';