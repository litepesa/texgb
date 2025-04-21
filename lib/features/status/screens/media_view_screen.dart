import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:textgb/common/videoviewerscreen.dart';

class MediaViewScreen extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;
  final String? caption;

  const MediaViewScreen({
    Key? key,
    required this.mediaUrls,
    this.initialIndex = 0,
    this.caption,
  }) : super(key: key);

  @override
  State<MediaViewScreen> createState() => _MediaViewScreenState();
}

class _MediaViewScreenState extends State<MediaViewScreen> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  AnimationController? _controlsAnimationController;
  Animation<double>? _controlsOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Animation controller for showing/hiding controls
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _controlsOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlsAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
    
    // Show controls initially
    _controlsAnimationController!.value = 1.0;
    
    // Hide system UI for a more immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Auto-hide controls after delay
    _startHideControlsTimer();
  }

  @override
  void dispose() {
    // Restore system UI when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    _pageController.dispose();
    _controlsAnimationController?.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
        _controlsAnimationController!.reverse();
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _controlsAnimationController!.forward();
      _startHideControlsTimer();
    } else {
      _controlsAnimationController!.reverse();
    }
  }

  void _openVideoPlayer(String videoUrl) {
    // Always use portrait orientation
    Navigator.of(context).push(
      VideoViewerScreen.route(
        videoUrl: videoUrl,
        videoTitle: widget.caption ?? 'Video',
        allowOrientationChanges: false, 
      ),
    );
  }

  bool _isVideoFile(String url) {
    return url.contains('video') || 
           url.endsWith('.mp4') || 
           url.endsWith('.mov') ||
           url.endsWith('.avi') ||
           url.endsWith('.mkv');
  }

  @override
  Widget build(BuildContext context) {
    // Handle single video case
    if (_isVideoFile(widget.mediaUrls[_currentIndex])) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openVideoPlayer(widget.mediaUrls[_currentIndex]);
        if (mounted) Navigator.pop(context);
      });
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image gallery
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                final isVideoItem = _isVideoFile(widget.mediaUrls[index]);
                
                if (isVideoItem) {
                  // For video items, show a thumbnail with play button
                  return PhotoViewGalleryPageOptions.customChild(
                    child: GestureDetector(
                      onTap: () {
                        if (_showControls) {
                          _toggleControls();
                        } else {
                          _openVideoPlayer(widget.mediaUrls[index]);
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Video thumbnail
                          CachedNetworkImage(
                            imageUrl: widget.mediaUrls[index],
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.videocam, color: Colors.white, size: 48),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to play video',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Simple play button overlay
                          Container(
                            width: 60,
                            height: 60,
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
                        ],
                      ),
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    heroAttributes: PhotoViewHeroAttributes(tag: 'media_${widget.mediaUrls[index]}'),
                  );
                }
                
                // For images
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(widget.mediaUrls[index]),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2.5,
                  heroAttributes: PhotoViewHeroAttributes(tag: 'media_${widget.mediaUrls[index]}'),
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.broken_image, color: Colors.white, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              itemCount: widget.mediaUrls.length,
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _showControls = true;
                });
                _controlsAnimationController!.forward();
                _startHideControlsTimer();
              },
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
            
            // Minimalist controls overlay
            FadeTransition(
              opacity: _controlsOpacityAnimation!,
              child: Visibility(
                visible: _showControls,
                child: _buildMinimalistControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMinimalistControls() {
    return Stack(
      children: [
        // Back button - top left
        Positioned(
          top: 20,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        
        // Caption - if available
        if (widget.caption != null && widget.caption!.isNotEmpty)
          Positioned(
            top: 20,
            left: 70,
            right: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.caption!,
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        
        // Left navigation button (if not the first item)
        if (_currentIndex > 0)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          ),
          
        // Right navigation button (if not the last item)
        if (_currentIndex < widget.mediaUrls.length - 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          ),
        
        // Counter indicator
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.mediaUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}