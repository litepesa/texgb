// ===============================
// Moment Media Grid Widget
// Display images/video in grid layout (up to 9 images)
// Uses GoRouter for navigation
// ===============================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/models/moment_enums.dart';
import 'package:textgb/features/moments/models/moment_constants.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';
import 'package:textgb/features/moments/services/moments_media_service.dart';
import 'package:textgb/core/router/route_paths.dart';

class MomentMediaGrid extends StatelessWidget {
  final MomentModel moment;

  const MomentMediaGrid({
    Key? key,
    required this.moment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (moment.mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // Video type - single video display
    if (moment.mediaType == MomentMediaType.video) {
      return _buildVideoThumbnail(context);
    }

    // Images - grid layout
    return _buildImageGrid(context);
  }

  // Build single video thumbnail
  Widget _buildVideoThumbnail(BuildContext context) {
    return GestureDetector(
      onTap: () => _openVideoViewer(context, 0),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video thumbnail
            CachedNetworkImage(
              imageUrl: moment.mediaUrls.first,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.black26,
                child: const Icon(
                  Icons.videocam_outlined,
                  size: 64,
                  color: Colors.white70,
                ),
              ),
            ),

            // Play button overlay
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

            // Duration badge (if available)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.videocam,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  // Build image grid
  Widget _buildImageGrid(BuildContext context) {
    final imageCount = moment.mediaUrls.length;
    final mediaService = MomentsMediaService();
    final layout = mediaService.calculateGridLayout(imageCount);

    // Single image - larger display
    if (imageCount == 1) {
      return _buildSingleImage(context, 0);
    }

    // Multiple images - grid layout
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MomentsTheme.paddingLarge,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: layout.columns,
          crossAxisSpacing: MomentsTheme.imageGridSpacing,
          mainAxisSpacing: MomentsTheme.imageGridSpacing,
          childAspectRatio: 1.0,
        ),
        itemCount: imageCount,
        itemBuilder: (context, index) {
          return _buildGridImage(context, index);
        },
      ),
    );
  }

  // Build single image (full width)
  Widget _buildSingleImage(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, index),
      child: CachedNetworkImage(
        imageUrl: moment.mediaUrls[index],
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 64),
        ),
      ),
    );
  }

  // Build grid image item
  Widget _buildGridImage(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _openImageViewer(context, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MomentsTheme.imageGridRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: moment.mediaUrls[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 32),
              ),
            ),

            // Show "+N" overlay for last image if more than 9
            if (index == MomentConstants.maxImages - 1 &&
                moment.mediaUrls.length > MomentConstants.maxImages)
              Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Text(
                    '+${moment.mediaUrls.length - MomentConstants.maxImages}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Open image viewer
  void _openImageViewer(BuildContext context, int initialIndex) {
    context.push(
      RoutePaths.momentMediaViewer(moment.id, initialIndex),
      extra: {'imageUrls': moment.mediaUrls},
    );
  }

  // Open video viewer
  void _openVideoViewer(BuildContext context, int index) {
    context.push(
      RoutePaths.momentVideoViewer(moment.id),
      extra: {'videoUrl': moment.mediaUrls[index], 'moment': moment},
    );
  }
}
