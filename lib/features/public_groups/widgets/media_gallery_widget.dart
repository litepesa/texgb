
// lib/features/public_groups/widgets/media_gallery_widget.dart
import 'package:flutter/material.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/public_groups/widgets/cached_network_image.dart';
import '../models/public_group_post_model.dart';
import '../utils/media_cache_manager.dart';
import 'video_thumbnail_widget.dart';


class MediaGalleryWidget extends StatelessWidget {
  final PublicGroupPostModel post;
  final VoidCallback? onMediaTap;

  const MediaGalleryWidget({
    super.key,
    required this.post,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    if (post.mediaUrls.isEmpty) return const SizedBox.shrink();

    final mediaCount = post.mediaUrls.length;
    
    if (mediaCount == 1) {
      return _buildSingleMedia(post.mediaUrls[0]);
    } else if (mediaCount == 2) {
      return _buildTwoMediaGrid();
    } else if (mediaCount == 3) {
      return _buildThreeMediaGrid();
    } else {
      return _buildFourPlusMediaGrid();
    }
  }

  Widget _buildSingleMedia(String mediaUrl) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMediaWidget(mediaUrl, isFullSize: true),
      ),
    );
  }

  Widget _buildTwoMediaGrid() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMediaWidget(post.mediaUrls[0]),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildMediaWidget(post.mediaUrls[1]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreeMediaGrid() {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildMediaWidget(post.mediaUrls[0]),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMediaWidget(post.mediaUrls[1]),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMediaWidget(post.mediaUrls[2]),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFourPlusMediaGrid() {
    final remainingCount = post.mediaUrls.length - 3;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMediaWidget(post.mediaUrls[0]),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMediaWidget(post.mediaUrls[1]),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMediaWidget(post.mediaUrls[2]),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildMediaWidget(post.mediaUrls[3]),
                      if (remainingCount > 0)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '+$remainingCount',
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
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMediaWidget(String mediaUrl, {bool isFullSize = false}) {
    if (post.postType == MessageEnum.video) {
      return VideoThumbnailWidget(
        videoUrl: mediaUrl,
        fit: BoxFit.cover,
        onTap: onMediaTap,
        duration: _getVideoDuration(mediaUrl),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: mediaUrl,
        fit: BoxFit.cover,
      );
    }
  }

  String? _getVideoDuration(String videoUrl) {
    // Get duration from post metadata if available
    final duration = post.metadata['duration'];
    if (duration != null && duration is int) {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return null;
  }
}