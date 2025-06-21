// lib/features/moments/widgets/moment_media_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/moments/screens/media_viewer_screen.dart';

class MomentMediaGrid extends StatelessWidget {
  final List<String> mediaUrls;
  final String mediaType;

  const MomentMediaGrid({
    super.key,
    required this.mediaUrls,
    required this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 400,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMediaLayout(context),
      ),
    );
  }

  Widget _buildMediaLayout(BuildContext context) {
    final count = mediaUrls.length;

    if (count == 1) {
      return _buildSingleMedia(context, mediaUrls[0], 0);
    } else if (count == 2) {
      return _buildTwoMedia(context);
    } else if (count == 3) {
      return _buildThreeMedia(context);
    } else if (count == 4) {
      return _buildFourMedia(context);
    } else {
      return _buildMoreThanFourMedia(context);
    }
  }

  Widget _buildSingleMedia(BuildContext context, String url, int index) {
    return GestureDetector(
      onTap: () => _openMediaViewer(context, index),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildMediaItem(url),
            if (_isVideo(url)) _buildVideoOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoMedia(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openMediaViewer(context, 0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildMediaItem(mediaUrls[0]),
                  if (_isVideo(mediaUrls[0])) _buildVideoOverlay(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: GestureDetector(
              onTap: () => _openMediaViewer(context, 1),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildMediaItem(mediaUrls[1]),
                  if (_isVideo(mediaUrls[1])) _buildVideoOverlay(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeMedia(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _openMediaViewer(context, 0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildMediaItem(mediaUrls[0]),
                  if (_isVideo(mediaUrls[0])) _buildVideoOverlay(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMediaViewer(context, 1),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaItem(mediaUrls[1]),
                        if (_isVideo(mediaUrls[1])) _buildVideoOverlay(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMediaViewer(context, 2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaItem(mediaUrls[2]),
                        if (_isVideo(mediaUrls[2])) _buildVideoOverlay(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFourMedia(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMediaViewer(context, 0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaItem(mediaUrls[0]),
                        if (_isVideo(mediaUrls[0])) _buildVideoOverlay(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMediaViewer(context, 1),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaItem(mediaUrls[1]),
                        if (_isVideo(mediaUrls[1])) _buildVideoOverlay(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMediaViewer(context, 2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaItem(mediaUrls[2]),
                        if (_isVideo(mediaUrls[2])) _buildVideoOverlay(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMediaViewer(context, 3),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaItem(mediaUrls[3]),
                        if (_isVideo(mediaUrls[3])) _buildVideoOverlay(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreThanFourMedia(BuildContext context) {
    final remainingCount = mediaUrls.length - 3;
    
    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMediaViewer(context, 0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaItem(mediaUrls[0]),
                        if (_isVideo(mediaUrls[0])) _buildVideoOverlay(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMediaViewer(context, 1),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaItem(mediaUrls[1]),
                        if (_isVideo(mediaUrls[1])) _buildVideoOverlay(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMediaViewer(context, 2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaItem(mediaUrls[2]),
                        if (_isVideo(mediaUrls[2])) _buildVideoOverlay(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openMediaViewer(context, 3),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaItem(mediaUrls[3]),
                        if (_isVideo(mediaUrls[3])) _buildVideoOverlay(),
                        // Overlay for remaining count
                        Container(
                          color: Colors.black.withOpacity(0.6),
                          child: Center(
                            child: Text(
                              '+$remainingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: const Color(0xFFF2F2F7),
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: const Color(0xFFF2F2F7),
        child: const Center(
          child: Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: Color(0xFF8E8E93),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Icon(
          CupertinoIcons.play_circle,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  bool _isVideo(String url) {
    return url.toLowerCase().contains('.mp4') ||
           url.toLowerCase().contains('.mov') ||
           url.toLowerCase().contains('.avi') ||
           url.toLowerCase().contains('video');
  }

  void _openMediaViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => MediaViewerScreen(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}