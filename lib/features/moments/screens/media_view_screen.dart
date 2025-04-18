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

class _MediaViewScreenState extends State<MediaViewScreen> {
  late int _currentIndex;
  late PageController _pageController;
  bool _isFullScreen = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
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
    super.dispose();
  }

  void _startHideControlsTimer() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _showControls = true;
      _isFullScreen = !_isFullScreen;
    });
    
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
      _startHideControlsTimer();
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
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing media...')),
    );
  }

  void _downloadMedia() {
    // Implement download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading media...')),
    );
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
                final isVideoItem = widget.mediaUrls[index].contains('video') || 
                                   widget.mediaUrls[index].endsWith('.mp4') || 
                                   widget.mediaUrls[index].endsWith('.mov');
                
                if (isVideoItem) {
                  // For video items, show a thumbnail with play button
                  return PhotoViewGalleryPageOptions.customChild(
                    child: GestureDetector(
                      onTap: () => _openVideoPlayer(widget.mediaUrls[index]),
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
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes: PhotoViewHeroAttributes(tag: 'media_${widget.mediaUrls[index]}'),
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
                _startHideControlsTimer();
              },
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
            
            // Top controls (header)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Visibility(
                visible: _showControls,
                child: Positioned(
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
                          ),
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.white),
                            onPressed: _downloadMedia,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom description if provided
            if (widget.description != null)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Visibility(
                  visible: _showControls,
                  child: Positioned(
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
                ),
              ),
              
            // Fullscreen toggle button
            Positioned(
              right: 16,
              bottom: widget.description != null ? 80 : 16,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Visibility(
                  visible: _showControls,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}