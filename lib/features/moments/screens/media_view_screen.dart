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
  final bool isVideo;
  final String? description;

  const MediaViewScreen({
    Key? key,
    required this.mediaUrls,
    this.initialIndex = 0,
    this.isVideo = false,
    this.description,
  }) : super(key: key);

  @override
  State<MediaViewScreen> createState() => _MediaViewScreenState();
}

class _MediaViewScreenState extends State<MediaViewScreen> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  bool _isFullScreen = false;
  bool _showControls = true;
  bool _isVideoPlaying = false;
  Timer? _hideControlsTimer;
  AnimationController? _controlsAnimationController;
  Animation<double>? _controlsOpacityAnimation;

  // Keep track of tap positions for double-tap zoom
  Offset? _doubleTapPosition;

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
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
        _controlsAnimationController!.reverse();
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      _showControls = true;
    });
    
    _controlsAnimationController!.forward();
    
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    
    _startHideControlsTimer();
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
    Navigator.of(context).push(
      VideoViewerScreen.route(
        videoUrl: videoUrl,
        videoTitle: widget.description ?? 'Video',
        allowOrientationChanges: true,
      ),
    );
  }

  void _shareMedia() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing media...')),
    );
  }

  void _downloadMedia() {
    // TODO: Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading media...')),
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
    if (widget.isVideo && widget.mediaUrls.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openVideoPlayer(widget.mediaUrls.first);
        if (mounted) Navigator.pop(context);
      });
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        // Handle back button press - exit fullscreen mode first if active
        if (_isFullScreen) {
          _toggleFullScreen();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          onDoubleTapDown: (details) {
            _doubleTapPosition = details.localPosition;
          },
          onDoubleTap: () {
            // Handle double-tap zoom here if needed
          },
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
                            
                            // Play button overlay
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 50,
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
              
              // Animated controls overlay
              FadeTransition(
                opacity: _controlsOpacityAnimation!,
                child: Visibility(
                  visible: _showControls,
                  child: _buildControlsOverlay(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildControlsOverlay() {
    return Stack(
      children: [
        // Top controls (header)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.8],
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  
                  // Page indicator
                  Expanded(
                    child: Text(
                      '${_currentIndex + 1}/${widget.mediaUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Action buttons
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _shareMedia,
                    tooltip: 'Share',
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.white),
                    onPressed: _downloadMedia,
                    tooltip: 'Download',
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Bottom description if provided
        if (widget.description != null && widget.description!.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.8],
                ),
              ),
              child: Text(
                widget.description!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
        // Fullscreen toggle button
        Positioned(
          right: 16,
          bottom: widget.description != null && widget.description!.isNotEmpty ? 80 : 16,
          child: FloatingActionButton.small(
            heroTag: 'fullscreen_btn',
            backgroundColor: Colors.black.withOpacity(0.7),
            onPressed: _toggleFullScreen,
            child: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
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
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
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
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
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
      ],
    );
  }
}