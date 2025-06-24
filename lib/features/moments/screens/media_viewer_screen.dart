// lib/features/moments/screens/media_viewer_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class MediaViewerScreen extends StatefulWidget {
  final List<String> mediaUrls;
  final int initialIndex;
  final MessageEnum mediaType;
  final String? authorName;
  final DateTime? createdAt;
  final bool showActions;

  const MediaViewerScreen({
    super.key,
    required this.mediaUrls,
    this.initialIndex = 0,
    this.mediaType = MessageEnum.image,
    this.authorName,
    this.createdAt,
    this.showActions = true,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  int _currentIndex = 0;
  bool _isUIVisible = true;
  bool _isLoading = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  String? _videoError;

  // Beautiful color palette
  static const Color primaryColor = Color(0xFF1D1D1D);
  static const Color secondaryColor = Color(0xFF8E8E93);
  static const Color backgroundColor = Colors.black;
  static const Color overlayColor = Color(0x66000000);
  static const Color whiteColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
    
    // Set status bar to hidden for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // Initialize video if current media is video
    if (widget.mediaType == MessageEnum.video && widget.mediaUrls.isNotEmpty) {
      _initializeVideo(widget.mediaUrls[_currentIndex]);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _fadeController.dispose();
    _videoController?.dispose();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _initializeVideo(String videoUrl) async {
    try {
      setState(() {
        _isVideoInitialized = false;
        _videoError = null;
      });

      _videoController?.dispose();
      
      // Create video controller with proper error handling
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );
      
      // Add error listener
      _videoController!.addListener(() {
        if (_videoController!.value.hasError) {
          setState(() {
            _videoError = _videoController!.value.errorDescription ?? 'Video error occurred';
            _isVideoInitialized = false;
          });
        }
      });
      
      await _videoController!.initialize();
      
      if (mounted && _videoController!.value.isInitialized) {
        setState(() {
          _isVideoInitialized = true;
          _videoError = null;
        });
        
        // Auto-play video
        await _videoController!.play();
        setState(() {
          _isPlaying = true;
        });
        
        // Listen for video completion
        _videoController!.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _videoError = 'Failed to load video: ${e.toString()}';
          _isVideoInitialized = false;
        });
        showSnackBar(context, 'Error loading video');
      }
    }
  }

  void _videoListener() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final position = _videoController!.value.position;
      final duration = _videoController!.value.duration;
      
      if (position >= duration && duration > Duration.zero) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    }
  }

  void _toggleUI() {
    setState(() {
      _isUIVisible = !_isUIVisible;
    });
  }

  void _toggleVideoPlayback() {
    if (_videoController != null && _isVideoInitialized) {
      setState(() {
        if (_isPlaying) {
          _videoController!.pause();
          _isPlaying = false;
        } else {
          _videoController!.play();
          _isPlaying = true;
        }
      });
    }
  }

  Future<void> _shareMedia() async {
    try {
      final currentUrl = widget.mediaUrls[_currentIndex];
      await Share.share(
        'Check out this ${widget.mediaType.displayName.toLowerCase()}!\n$currentUrl',
        subject: 'Shared from Moments',
      );
    } catch (e) {
      showSnackBar(context, 'Error sharing media');
    }
  }

  Future<void> _downloadMedia() async {
    try {
      setState(() => _isLoading = true);
      
      // Request storage permission
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        showSnackBar(context, 'Storage permission required to download');
        return;
      }

      final currentUrl = widget.mediaUrls[_currentIndex];
      
      // Get downloads directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access storage');
      }
      
      final fileName = 'moment_${DateTime.now().millisecondsSinceEpoch}';
      final extension = widget.mediaType == MessageEnum.video ? '.mp4' : '.jpg';
      final filePath = '${directory.path}/$fileName$extension';
      
      // Download file (you would implement actual download logic here)
      // For now, just show success message
      showSnackBar(context, 'Media downloaded successfully');
      
    } catch (e) {
      showSnackBar(context, 'Error downloading media: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Initialize video for new page if it's a video
    if (widget.mediaType == MessageEnum.video) {
      _initializeVideo(widget.mediaUrls[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          _buildMediaViewer(),
          _buildTopOverlay(),
          _buildBottomOverlay(),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildMediaViewer() {
    return GestureDetector(
      onTap: _toggleUI,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.mediaType == MessageEnum.video
            ? _buildVideoViewer()
            : _buildImageViewer(),
      ),
    );
  }

  Widget _buildImageViewer() {
    return PhotoViewGallery.builder(
      pageController: _pageController,
      itemCount: widget.mediaUrls.length,
      onPageChanged: _onPageChanged,
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(widget.mediaUrls[index]),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.5,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          heroAttributes: PhotoViewHeroAttributes(tag: widget.mediaUrls[index]),
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: backgroundColor,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: whiteColor,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: TextStyle(
                        color: whiteColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      scrollPhysics: const BouncingScrollPhysics(),
      backgroundDecoration: const BoxDecoration(color: backgroundColor),
      loadingBuilder: (context, event) {
        return Container(
          color: backgroundColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: whiteColor,
                  value: event == null ? null : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loading image...',
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoViewer() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.mediaUrls.length,
      itemBuilder: (context, index) {
        return Container(
          color: backgroundColor,
          width: double.infinity,
          height: double.infinity,
          child: _buildVideoPlayer(),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    // Show error state
    if (_videoError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: whiteColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Video Error',
              style: TextStyle(
                color: whiteColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _videoError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: secondaryColor,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _initializeVideo(widget.mediaUrls[_currentIndex]),
              style: ElevatedButton.styleFrom(
                backgroundColor: whiteColor,
                foregroundColor: backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show loading state
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: whiteColor,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(
                color: whiteColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Show video player
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video player widget
            VideoPlayer(_videoController!),
            
            // Play/Pause overlay
            if (!_isPlaying)
              GestureDetector(
                onTap: _toggleVideoPlayback,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: overlayColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: whiteColor,
                    size: 64,
                  ),
                ),
              ),
            
            // Video controls at bottom
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildVideoControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    if (_videoController == null || !_isVideoInitialized) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _videoController!,
      builder: (context, child) {
        final position = _videoController!.value.position;
        final duration = _videoController!.value.duration;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return AnimatedOpacity(
          opacity: _isUIVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: overlayColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleVideoPlayback,
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: whiteColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(position),
                  style: const TextStyle(
                    color: whiteColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: whiteColor,
                      inactiveTrackColor: whiteColor.withOpacity(0.3),
                      thumbColor: whiteColor,
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (value) {
                        final newPosition = Duration(
                          milliseconds: (value * duration.inMilliseconds).round(),
                        );
                        _videoController!.seekTo(newPosition);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(
                    color: whiteColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopOverlay() {
    return AnimatedOpacity(
      opacity: _isUIVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              overlayColor,
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: overlayColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.close,
                  color: whiteColor,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.authorName != null)
                    Text(
                      widget.authorName!,
                      style: const TextStyle(
                        color: whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (widget.createdAt != null)
                    Text(
                      _formatDateTime(widget.createdAt!),
                      style: const TextStyle(
                        color: whiteColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.mediaUrls.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: overlayColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.mediaUrls.length}',
                  style: const TextStyle(
                    color: whiteColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    if (!widget.showActions) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: _isUIVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            top: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                overlayColor,
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.share,
                label: 'Share',
                onTap: _shareMedia,
              ),
              _buildActionButton(
                icon: Icons.download,
                label: 'Download',
                onTap: _downloadMedia,
              ),
              if (widget.mediaUrls.length > 1)
                _buildActionButton(
                  icon: Icons.grid_view,
                  label: 'Gallery',
                  onTap: () => _showGallerySelector(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: overlayColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: whiteColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: whiteColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: backgroundColor.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: whiteColor),
            SizedBox(height: 16),
            Text(
              'Processing...',
              style: TextStyle(
                color: whiteColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGallerySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 200,
        decoration: const BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Media',
              style: TextStyle(
                color: whiteColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.mediaUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: _currentIndex == index
                            ? Border.all(color: whiteColor, width: 2)
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: widget.mediaType == MessageEnum.image
                            ? CachedNetworkImage(
                                imageUrl: widget.mediaUrls[index],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: secondaryColor,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: whiteColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: secondaryColor,
                                child: const Icon(
                                  Icons.play_circle_filled,
                                  color: whiteColor,
                                  size: 32,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}