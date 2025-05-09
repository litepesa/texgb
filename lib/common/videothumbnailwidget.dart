import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final String? durationText;

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
    this.durationText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // If an onTap callback is provided, use it
        if (onTap != null) {
          onTap!();
        } else {
          // Use direct navigation instead of named routes to avoid null issues
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VideoViewerScreen(
                videoUrl: videoUrl,
                videoTitle: title,
                accentColor: accentColor,
              ),
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
            // Simplified thumbnail handling
            if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: thumbnailUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                      strokeWidth: 2.0,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(
                    Icons.video_file,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              )
            else
              Container(
                color: Colors.grey[900],
                child: const Icon(
                  Icons.video_file,
                  color: Colors.white54,
                  size: 48,
                ),
              ),

            // Play button overlay with improved design
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            // Duration indicator
            if (durationText != null)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    durationText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Title overlay (if provided)
            if (title != null && title!.isNotEmpty)
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
                        Colors.black.withOpacity(0.8),
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