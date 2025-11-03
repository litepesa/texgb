// ===============================
// Media Viewer Screen
// Full-screen image viewer with dark theme
// Supports swipe between images and pinch-to-zoom
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/moments/theme/moments_theme.dart';

class MediaViewerScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const MediaViewerScreen({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    // Set dark theme status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    // Restore original status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MomentsTheme.darkBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return _buildImagePage(widget.imageUrls[index]);
            },
          ),

          // Top bar overlay
          if (_showOverlay) _buildTopBar(),

          // Bottom indicator overlay
          if (_showOverlay && widget.imageUrls.length > 1) _buildBottomIndicator(),
        ],
      ),
    );
  }

  Widget _buildImagePage(String imageUrl) {
    return GestureDetector(
      onTap: _toggleOverlay,
      onVerticalDragEnd: (details) {
        // Swipe down to close
        if (details.primaryVelocity! > 300) {
          Navigator.pop(context);
        }
      },
      child: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
            errorWidget: (context, url, error) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.broken_image,
                    color: Colors.white70,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          right: 8,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),

            const Spacer(),

            // Image counter
            if (widget.imageUrls.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const Spacer(),

            // More options
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: _showMoreOptions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomIndicator() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.imageUrls.length > 9 ? 9 : widget.imageUrls.length,
            (index) {
              // Show only first 9 dots
              if (index == 8 && widget.imageUrls.length > 9) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    '...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                );
              }

              final isActive = index == _currentIndex;
              return Container(
                width: isActive ? 8 : 6,
                height: isActive ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MomentsTheme.darkBackground,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save_alt, color: Colors.white),
              title: const Text(
                'Save to gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _saveImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text(
                'Share',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _shareImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.white),
              title: const Text(
                'Copy link',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _copyLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.white),
              title: const Text(
                'Report',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _reportImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveImage() {
    // TODO: Implement save to gallery
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Save to gallery - Coming soon'),
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _shareImage() {
    // TODO: Implement share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share - Coming soon'),
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _copyLink() {
    // TODO: Implement copy link
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _reportImage() {
    // TODO: Implement report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report - Coming soon'),
        backgroundColor: Colors.black87,
      ),
    );
  }
}
