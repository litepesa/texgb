// lib/features/channels/widgets/enhanced_media_preview.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class EnhancedMediaPreview extends StatefulWidget {
  final List<File> images;
  final File? video;
  final Function(int)? onImageRemove;
  final VoidCallback? onVideoRemove;
  final Function(Duration, Duration)? onVideoTrim;

  const EnhancedMediaPreview({
    Key? key,
    this.images = const [],
    this.video,
    this.onImageRemove,
    this.onVideoRemove,
    this.onVideoTrim,
  }) : super(key: key);

  @override
  State<EnhancedMediaPreview> createState() => _EnhancedMediaPreviewState();
}

class _EnhancedMediaPreviewState extends State<EnhancedMediaPreview>
    with TickerProviderStateMixin {
  // Controllers
  PageController? _pageController;
  VideoPlayerController? _videoController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // State
  int _currentIndex = 0;
  bool _showControls = true;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  Duration _videoDuration = Duration.zero;
  Duration _videoPosition = Duration.zero;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePageController();
    _initializeVideo();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeController.forward();
    _scaleController.forward();
  }

  void _initializePageController() {
    if (widget.images.isNotEmpty || widget.video != null) {
      _pageController = PageController();
    }
  }

  Future<void> _initializeVideo() async {
    if (widget.video != null) {
      _videoController = VideoPlayerController.file(widget.video!);
      await _videoController!.initialize();
      
      _videoController!.addListener(_videoListener);
      
      setState(() {
        _isVideoInitialized = true;
        _videoDuration = _videoController!.value.duration;
      });
    }
  }

  void _videoListener() {
    if (_videoController == null) return;
    
    setState(() {
      _videoPosition = _videoController!.value.position;
      _isPlaying = _videoController!.value.isPlaying;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pageController?.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    if (widget.images.isEmpty && widget.video == null) {
      return _buildEmptyState(modernTheme);
    }
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Media content
                  widget.video != null
                      ? _buildVideoPreview(modernTheme)
                      : _buildImageCarousel(modernTheme),
                  
                  // Controls overlay
                  if (_showControls)
                    _buildControlsOverlay(modernTheme),
                  
                  // Tap to toggle controls
                  GestureDetector(
                    onTap: _toggleControls,
                    behavior: HitTestBehavior.translucent,
                    child: Container(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ModernThemeExtension modernTheme) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: modernTheme.borderColor ?? Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: modernTheme.textSecondaryColor!.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Select media to preview',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(ModernThemeExtension modernTheme) {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildImageCarousel(ModernThemeExtension modernTheme) {
    if (widget.images.isEmpty) return Container();
    
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
        HapticFeedback.lightImpact();
      },
      itemCount: widget.images.length,
      itemBuilder: (context, index) {
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.file(
            widget.images[index],
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: modernTheme.surfaceColor,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: modernTheme.textSecondaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildControlsOverlay(ModernThemeExtension modernTheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Top controls
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Media type indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.video != null ? Icons.videocam : Icons.photo,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.video != null 
                            ? 'Video'
                            : '${widget.images.length} Photo${widget.images.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                
                // Remove button
                GestureDetector(
                  onTap: _handleRemove,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Center controls (video only)
          if (widget.video != null)
            Center(
              child: GestureDetector(
                onTap: _toggleVideoPlayback,
                child: AnimatedOpacity(
                  opacity: _isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          
          // Bottom controls
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: widget.video != null
                ? _buildVideoControls(modernTheme)
                : _buildImageControls(modernTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls(ModernThemeExtension modernTheme) {
    return Column(
      children: [
        // Video progress
        if (_videoDuration.inMilliseconds > 0) ...[
          Row(
            children: [
              Text(
                _formatDuration(_videoPosition),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _videoPosition.inMilliseconds.toDouble(),
                  max: _videoDuration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    _videoController!.seekTo(Duration(milliseconds: value.toInt()));
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.3),
                ),
              ),
              Text(
                _formatDuration(_videoDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          // Trim button (if video is longer than 5 minutes)
          if (_videoDuration > const Duration(minutes: 5))
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                onPressed: _showTrimDialog,
                icon: const Icon(Icons.content_cut, size: 16),
                label: const Text('Trim Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildImageControls(ModernThemeExtension modernTheme) {
    if (widget.images.length <= 1) return Container();
    
    return Column(
      children: [
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.images.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentIndex
                    ? Colors.white
                    : Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Navigation hints
        Text(
          'Swipe to browse • Pinch to zoom',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _handleRemove() {
    if (widget.video != null) {
      widget.onVideoRemove?.call();
    } else if (widget.images.isNotEmpty) {
      widget.onImageRemove?.call(_currentIndex);
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController == null) return;
    
    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  void _showTrimDialog() {
    // This would integrate with the video trimmer widget
    widget.onVideoTrim?.call(Duration.zero, const Duration(minutes: 5));
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}