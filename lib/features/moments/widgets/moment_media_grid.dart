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
import 'package:textgb/features/moments/widgets/moment_video_player.dart';
import 'package:textgb/core/router/route_paths.dart';

class MomentMediaGrid extends StatelessWidget {
  final MomentModel moment;

  const MomentMediaGrid({
    super.key,
    required this.moment,
  });

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

  // Build single video player (Facebook-style autoplay on mute)
  Widget _buildVideoThumbnail(BuildContext context) {
    return MomentVideoPlayer(
      videoUrl: moment.mediaUrls.first,
      onTap: () => _openVideoViewer(context, 0),
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
