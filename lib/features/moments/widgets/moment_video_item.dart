// lib/features/moments/widgets/moment_video_item.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:video_player/video_player.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/providers/moments_provider.dart';
import 'package:textgb/features/gifts/widgets/virtual_gifts_bottom_sheet.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MomentVideoItem extends ConsumerStatefulWidget {
  final MomentModel moment;
  final int momentIndex;
  final bool isActive;
  final bool isCommentsOpen;
  final Function(VideoPlayerController)? onVideoControllerReady;
  final Function(bool isPlaying)? onManualPlayPause;
  final VoidCallback? onDoubleTap;
  final Function(VirtualGift)? onGiftSent; // NEW: Callback for when gift is sent

  const MomentVideoItem({
    super.key,
    required this.moment,
    required this.momentIndex,
    required this.isActive,
    this.isCommentsOpen = false,
    this.onVideoControllerReady,
    this.onManualPlayPause,
    this.onDoubleTap,
    this.onGiftSent, // NEW: Add gift callback
  });

  @override
  ConsumerState<MomentVideoItem> createState() => _MomentVideoItemState();
}

class _MomentVideoItemState extends ConsumerState<MomentVideoItem>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {

  // Video state
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isInitializing = false;
  bool _isManuallyPaused = false;
  
  // Caption state
  bool _captionExpanded = false;
  
  // Animation controllers for like effect
  late AnimationController _likeAnimationController;
  late AnimationController _heartScaleController;
  late AnimationController _burstAnimationController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _burstAnimation;
  bool _showLikeAnimation = false;

  @override
  bool get wantKeepAlive => widget.isActive;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMedia();
  }

  void _initializeAnimations() {
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _heartScaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _heartScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _heartScaleController,
      curve: Curves.elasticOut,
    ));
    
    _burstAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _burstAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _burstAnimationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(MomentVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      _handleActiveStateChange();
    }
    
    if (widget.isCommentsOpen != oldWidget.isCommentsOpen) {
      _handleCommentsStateChange();
    }
    
    if (widget.moment.id != oldWidget.moment.id) {
      _cleanupCurrentController();
      _captionExpanded = false;
      _initializeMedia();
    }
  }

  void _cleanupCurrentController() {
    if (_videoController != null) {
      _videoController!.dispose();
      _videoController = null;
      _isVideoInitialized = false;
    }
  }

  void _handleActiveStateChange() {
    if (widget.moment.hasVideo) {
      if (widget.isActive && _isVideoInitialized && !_isManuallyPaused) {
        _playVideo();
      } else if (!widget.isActive) {
        _pauseVideo();
      }
    }
  }

  void _handleCommentsStateChange() {
    // Video continues playing in small window mode
    // Only manage play state based on isActive
    if (!widget.isCommentsOpen && widget.isActive && _isVideoInitialized && !_isManuallyPaused) {
      _playVideo();
    }
  }

  Future<void> _initializeMedia() async {
    if (widget.moment.hasVideo && widget.moment.videoUrl!.isNotEmpty) {
      await _initializeVideoController();
    }
  }

  Future<void> _initializeVideoController() async {
    if (_isInitializing) return;
    
    try {
      setState(() {
        _isInitializing = true;
      });

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.moment.videoUrl!),
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: false,
        ),
      );
      
      await _videoController!.initialize().timeout(
        const Duration(seconds: 10),
      );
      
      _videoController!.setLooping(true);
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        if (widget.onVideoControllerReady != null) {
          widget.onVideoControllerReady!(_videoController!);
        }
        
        if (widget.isActive && !widget.isCommentsOpen) {
          _videoController!.seekTo(Duration.zero);
          _playVideo();
        }
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _playVideo() {
    if (_videoController != null && _isVideoInitialized) {
      _videoController!.play();
    }
  }

  void _pauseVideo() {
    if (_videoController != null && _isVideoInitialized) {
      _videoController!.pause();
    }
  }

  void _togglePlayPause() {
    if (widget.isCommentsOpen || !widget.moment.hasVideo) return;
    
    if (!_isVideoInitialized) return;
    
    bool willBePlaying;
    if (_videoController!.value.isPlaying) {
      _pauseVideo();
      _isManuallyPaused = true;
      willBePlaying = false;
    } else {
      _playVideo();
      _isManuallyPaused = false;
      willBePlaying = true;
    }
    
    if (widget.onManualPlayPause != null) {
      widget.onManualPlayPause!(willBePlaying);
    }
  }

  void _handleDoubleTap() {
    if (widget.isCommentsOpen) return;
    
    // Trigger like animation
    setState(() {
      _showLikeAnimation = true;
    });
    
    // Start all animations
    _heartScaleController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _heartScaleController.reverse();
      });
    });
    
    _burstAnimationController.forward().then((_) {
      _burstAnimationController.reset();
    });
    
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reset();
      if (mounted) {
        setState(() {
          _showLikeAnimation = false;
        });
      }
    });
    
    // Like the moment
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null && !widget.moment.likedBy.contains(currentUser.uid)) {
      ref.read(momentsProvider.notifier).toggleLikeMoment(widget.moment.id, false);
    }
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Notify parent
    if (widget.onDoubleTap != null) {
      widget.onDoubleTap!();
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _heartScaleController.dispose();
    _burstAnimationController.dispose();
    
    if (_videoController != null) {
      _videoController!.dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: _handleDoubleTap,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main content
            _buildMainContent(),
            
            // Loading indicator
            if (_isInitializing)
              _buildLoadingIndicator(),
            
            // Play indicator for paused videos
            if (widget.moment.hasVideo && 
                _isVideoInitialized && 
                !_videoController!.value.isPlaying && 
                !widget.isCommentsOpen)
              _buildPlayIndicator(),
            
            // Like animation overlay
            if (_showLikeAnimation && !widget.isCommentsOpen)
              _buildLikeAnimationOverlay(),
            
            // Bottom info overlay
            if (!widget.isCommentsOpen)
              _buildBottomInfoOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (widget.moment.hasVideo) {
      return _buildVideoPlayer();
    } else if (widget.moment.hasImages) {
      return _buildImageCarousel();
    } else {
      return _buildTextContent();
    }
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        color: Colors.black,
        child: _isInitializing 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : null,
      );
    }
    
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    if (widget.moment.imageUrls.isEmpty) return _buildPlaceholder();
    
    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        enableInfiniteScroll: widget.moment.imageUrls.length > 1,
        autoPlay: widget.isActive && widget.moment.imageUrls.length > 1 && !widget.isCommentsOpen,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
      ),
      items: widget.moment.imageUrls.map((imageUrl) {
        return SizedBox.expand(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingIndicator();
            },
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextContent() {
    return Container(
      color: context.modernTheme.primaryColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            widget.moment.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildPlayIndicator() {
    return const Center(
      child: Icon(
        CupertinoIcons.play,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildBottomInfoOverlay() {
    return Positioned(
      left: 16,
      right: 80, // Leave space for right side menu  
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Author info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.moment.authorImage.isNotEmpty
                    ? NetworkImage(widget.moment.authorImage)
                    : null,
                backgroundColor: Colors.grey[300],
                child: widget.moment.authorImage.isEmpty
                    ? Text(
                        widget.moment.authorName.isNotEmpty 
                            ? widget.moment.authorName[0].toUpperCase()
                            : "U",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.moment.authorName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Expandable caption
          if (widget.moment.content.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildExpandableCaption(),
          ],

          const SizedBox(height: 8),
          
          // Timestamp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.white.withOpacity(0.7),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _getTimeAgo(widget.moment.createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableCaption() {
    // Check if caption needs truncation (more than 2 lines estimated)
    final isLongCaption = widget.moment.content.length > 100 || widget.moment.content.split('\n').length > 2;
    
    // Create truncated version
    String displayText = widget.moment.content;
    if (isLongCaption && !_captionExpanded) {
      // Split by lines first
      final lines = widget.moment.content.split('\n');
      if (lines.length > 2) {
        displayText = lines.take(2).join('\n');
        // If the second line is too long, truncate it
        final secondLineWords = displayText.split(' ');
        if (secondLineWords.length > 15) {
          displayText = secondLineWords.take(15).join(' ');
        }
      } else {
        // Single long line - truncate by words
        final words = widget.moment.content.split(' ');
        if (words.length > 15) {
          displayText = words.take(15).join(' ');
        }
      }
    }
    
    return GestureDetector(
      onTap: () {
        if (isLongCaption) {
          setState(() {
            _captionExpanded = !_captionExpanded;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.3,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                ),
              ],
            ),
            children: [
              TextSpan(text: displayText),
              if (isLongCaption) ...[
                if (!_captionExpanded) ...[
                  const TextSpan(text: '... '),
                  TextSpan(
                    text: 'more',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ] else ...[
                  if (displayText != widget.moment.content)
                    TextSpan(
                      text: widget.moment.content.substring(displayText.length),
                    ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: 'less',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLikeAnimationOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Burst effect background
            Center(
              child: AnimatedBuilder(
                animation: _burstAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _burstAnimation.value * 3,
                    child: Opacity(
                      opacity: (1 - _burstAnimation.value).clamp(0.0, 0.5),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.red.withOpacity(0.6),
                              Colors.pink.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Center heart that scales
            Center(
              child: AnimatedBuilder(
                animation: _heartScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _heartScaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 100,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Floating hearts
            ..._buildFloatingHearts(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingHearts() {
    const heartCount = 8;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return List.generate(heartCount, (index) {
      final offsetX = (index * 0.25 - 1) * screenWidth * 0.5;
      final startY = screenHeight * 0.6;
      final endY = screenHeight * 0.1;
      
      return AnimatedBuilder(
        animation: _likeAnimationController,
        builder: (context, child) {
          final progress = _likeAnimationController.value;
          final opacity = (1.0 - progress).clamp(0.0, 1.0);
          final y = startY + (endY - startY) * progress;
          
          return Positioned(
            left: screenWidth / 2 + offsetX,
            top: y,
            child: Transform.rotate(
              angle: (index - 4) * 0.3 + progress * 2,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: index % 2 == 0 ? Colors.red : Colors.pink,
                    size: 25 + (index % 3) * 10.0,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}