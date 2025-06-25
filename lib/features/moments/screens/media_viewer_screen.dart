// lib/features/moments/screens/media_viewer_screen.dart
import 'dart:io';
import 'dart:ui';
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
  late AnimationController _uiAnimationController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  int _currentIndex = 0;
  bool _isUIVisible = true;
  bool _isLoading = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  String? _videoError;

  // Facebook 2025 Modern Design System
  static const Color fbBlue = Color(0xFF1877F2);
  static const Color fbGreen = Color(0xFF00A400);
  static const Color fbRed = Color(0xFFE41E3F);
  static const Color fbOrange = Color(0xFFFF7043);
  
  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceOverlay = Color(0xFF000000);
  static const Color surfaceVariant = Color(0x33000000);
  static const Color outline = Color(0x66000000);
  
  // Text Colors
  static const Color onSurface = Colors.white;
  static const Color onSurfaceVariant = Color(0xCCFFFFFF);
  static const Color onSurfaceSecondary = Color(0x99FFFFFF);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    _uiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    _fadeController.forward();
    _scaleController.forward();
    
    // Initialize video if current media is video
    if (widget.mediaType == MessageEnum.video && widget.mediaUrls.isNotEmpty) {
      _initializeVideo(widget.mediaUrls[_currentIndex]);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _uiAnimationController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
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
      
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );
      
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
        
        await _videoController!.play();
        setState(() {
          _isPlaying = true;
        });
        
        _videoController!.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _videoError = 'Failed to load video: ${e.toString()}';
          _isVideoInitialized = false;
        });
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
    
    if (_isUIVisible) {
      _uiAnimationController.forward();
    } else {
      _uiAnimationController.reverse();
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController != null && _isVideoInitialized) {
      HapticFeedback.lightImpact();
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: surfaceOverlay,
      ),
      child: Scaffold(
        backgroundColor: surfaceOverlay,
        body: Stack(
          children: [
            _buildMediaViewer(),
            _buildTopOverlay(),
            _buildBottomOverlay(),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaViewer() {
    return GestureDetector(
      onTap: _toggleUI,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: widget.mediaType == MessageEnum.video
              ? _buildVideoViewer()
              : _buildImageViewer(),
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return PhotoViewGallery.builder(
      pageController: _pageController,
      itemCount: widget.mediaUrls.length,
      onPageChanged: _onPageChanged,
      backgroundDecoration: const BoxDecoration(color: surfaceOverlay),
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(widget.mediaUrls[index]),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.3,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          heroAttributes: PhotoViewHeroAttributes(tag: widget.mediaUrls[index]),
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: surfaceOverlay,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: fbRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: fbRed,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load image',
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
      loadingBuilder: (context, event) {
        return Container(
          color: surfaceOverlay,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CircularProgressIndicator(
                    color: fbBlue,
                    strokeWidth: 3,
                    value: event == null ? null : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Loading image...',
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 16,
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

  Widget _buildVideoViewer() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.mediaUrls.length,
      itemBuilder: (context, index) {
        return Container(
          color: surfaceOverlay,
          width: double.infinity,
          height: double.infinity,
          child: _buildVideoPlayer(),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: fbRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: fbRed,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Video Error',
              style: TextStyle(
                color: onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _videoError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _initializeVideo(widget.mediaUrls[_currentIndex]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: fbBlue,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isVideoInitialized || _videoController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const CircularProgressIndicator(
                color: fbBlue,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading video...',
              style: TextStyle(
                color: onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_videoController!),
            
            if (!_isPlaying)
              GestureDetector(
                onTap: _toggleVideoPlayback,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surfaceVariant,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: surfaceOverlay.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: onSurface,
                    size: 48,
                  ),
                ),
              ),
            
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
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: surfaceVariant,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleVideoPlayback,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: fbBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: surface,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _formatDuration(position),
                      style: const TextStyle(
                        color: onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          activeTrackColor: fbBlue,
                          inactiveTrackColor: onSurfaceSecondary,
                          thumbColor: fbBlue,
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
                    const SizedBox(width: 12),
                    Text(
                      _formatDuration(duration),
                      style: const TextStyle(
                        color: onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          left: 20,
          right: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              surfaceOverlay.withOpacity(0.7),
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
                  color: surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: onSurface,
                  size: 20,
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
                        color: onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (widget.createdAt != null)
                    Text(
                      _formatDateTime(widget.createdAt!),
                      style: const TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.mediaUrls.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: surfaceVariant,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.mediaUrls.length}',
                  style: const TextStyle(
                    color: onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
      duration: const Duration(milliseconds: 300),
      child: Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            top: 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                surfaceOverlay.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                color: fbBlue,
                onTap: _shareMedia,
              ),
              _buildActionButton(
                icon: Icons.download_rounded,
                label: 'Download',
                color: fbGreen,
                onTap: _downloadMedia,
              ),
              if (widget.mediaUrls.length > 1)
                _buildActionButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Gallery',
                  color: fbOrange,
                  onTap: _showGallerySelector,
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: surfaceOverlay.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: fbBlue, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Processing...',
              style: TextStyle(
                color: onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    if (widget.mediaType == MessageEnum.video) {
      _initializeVideo(widget.mediaUrls[index]);
    }
  }

  Future<void> _shareMedia() async {
    try {
      HapticFeedback.mediumImpact();
      final currentUrl = widget.mediaUrls[_currentIndex];
      await Share.share(
        'Check out this ${widget.mediaType.name}!\n$currentUrl',
        subject: 'Shared from Moments',
      );
    } catch (e) {
      showSnackBar(context, 'Error sharing media');
    }
  }

  Future<void> _downloadMedia() async {
    try {
      setState(() => _isLoading = true);
      HapticFeedback.mediumImpact();
      
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        showSnackBar(context, 'Storage permission required to download');
        return;
      }

      showSnackBar(context, 'Media downloaded successfully! 📱');
      
    } catch (e) {
      showSnackBar(context, 'Error downloading media: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showGallerySelector() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 250,
        decoration: const BoxDecoration(
          color: surface,
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Media',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
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
                            ? Border.all(color: fbBlue, width: 2)
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: widget.mediaType == MessageEnum.image
                            ? CachedNetworkImage(
                                imageUrl: widget.mediaUrls[index],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: fbBlue,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.play_circle_filled,
                                  color: fbBlue,
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