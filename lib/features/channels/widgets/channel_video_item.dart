// lib/features/channels/widgets/channel_video_item.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/services/video_cache_service.dart';
import 'package:textgb/features/channels/widgets/channel_required_widget.dart'; // Add this import
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/widgets/comments_bottom_sheet.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart'; // Add this import
import 'package:textgb/constants.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ChannelVideoItem extends ConsumerStatefulWidget {
  final ChannelVideoModel video;
  final bool isActive;
  final Function(VideoPlayerController)? onVideoControllerReady;
  final Function(bool isPlaying)? onManualPlayPause; // New callback for manual play/pause
  final VideoPlayerController? preloadedController;
  final bool isLoading;
  final bool hasFailed;
  final bool isCommentsOpen; // New parameter to track comments state
  final bool showVerificationBadge; // NEW: Control whether to show verification or timestamp
  final bool showFollowButton; // NEW: Control whether to show follow button
  
  const ChannelVideoItem({
    super.key,
    required this.video,
    required this.isActive,
    this.onVideoControllerReady,
    this.onManualPlayPause,
    this.preloadedController,
    this.isLoading = false,
    this.hasFailed = false,
    this.isCommentsOpen = false, // Default to false
    this.showVerificationBadge = true, // Default to verification for main feed
    this.showFollowButton = true, // Default to show follow button
  });

  @override
  ConsumerState<ChannelVideoItem> createState() => _ChannelVideoItemState();
}

class _ChannelVideoItemState extends ConsumerState<ChannelVideoItem>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {

  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  int _currentImageIndex = 0;
  bool _isInitializing = false;
  bool _showFullCaption = false;
  bool _isCommentsSheetOpen = false;
  
  // Animation controllers for like effect
  late AnimationController _likeAnimationController;
  late AnimationController _heartScaleController;
  late Animation<double> _heartScaleAnimation;
  bool _showLikeAnimation = false;
  
  final VideoCacheService _cacheService = VideoCacheService();

  @override
  bool get wantKeepAlive => widget.isActive;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMedia();
  }

  void _initializeAnimations() {
    // Animation for the floating hearts
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Animation for the heart scale effect
    _heartScaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _heartScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _heartScaleController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(ChannelVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isActive != oldWidget.isActive) {
      _handleActiveStateChange();
    }
    
    if (widget.isCommentsOpen != oldWidget.isCommentsOpen) {
      _handleCommentsStateChange();
    }
    
    if (_shouldReinitializeMedia(oldWidget)) {
      _cleanupCurrentController(oldWidget);
      _initializeMedia();
    }

    // Reset caption state if video changes
    if (widget.video.id != oldWidget.video.id) {
      _showFullCaption = false;
    }
  }

  bool _shouldReinitializeMedia(ChannelVideoItem oldWidget) {
    return widget.video.videoUrl != oldWidget.video.videoUrl ||
           widget.video.isMultipleImages != oldWidget.video.isMultipleImages ||
           widget.preloadedController != oldWidget.preloadedController;
  }

  void _cleanupCurrentController(ChannelVideoItem oldWidget) {
    if (_isInitialized && 
        _videoPlayerController != null && 
        oldWidget.preloadedController == null) {
      _videoPlayerController!.dispose();
    }
    
    _videoPlayerController = null;
    _isInitialized = false;
  }

  void _handleActiveStateChange() {
    if (widget.video.isMultipleImages) return;
    
    if (widget.isActive && _isInitialized && !_isPlaying) {
      _playVideo();
    } else if (!widget.isActive && _isInitialized && _isPlaying) {
      _pauseVideo();
    }
  }

  void _handleCommentsStateChange() {
    setState(() {
      _isCommentsSheetOpen = widget.isCommentsOpen;
    });
    
    // Don't pause video when comments open - video should continue playing
    // The small window will show the same video stream
    
    // Only manage play state based on isActive, not comments state
    if (!widget.isCommentsOpen && widget.isActive && _isInitialized && !_isPlaying) {
      _playVideo();
    }
  }

  // Helper method to check if user has channel before allowing follow action
  Future<bool> _checkUserHasChannel() async {
    final currentUser = ref.read(authenticationProvider).valueOrNull?.userModel;
    final channelsState = ref.read(channelsProvider);
    
    // If user is not authenticated OR doesn't have a channel, show the channel required widget
    if (currentUser == null || channelsState.userChannel == null) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: ChannelRequiredWidget(
              title: 'Channel Required',
              subtitle: currentUser == null 
                  ? 'You need to log in and create a channel to follow other channels.'
                  : 'You need to create a channel to follow other channels.',
              actionText: currentUser == null ? 'Get Started' : 'Create Channel',
              icon: Icons.people,
            ),
          ),
        ),
      );

      return result ?? false;
    }

    return true; // User is authenticated and has channel
  }

  Future<void> _initializeMedia() async {
    if (widget.video.isMultipleImages) {
      setState(() {
        _isInitialized = true;
      });
      return;
    }
    
    if (widget.video.videoUrl.isEmpty) {
      return;
    }
    
    await _initializeVideoWithCache();
  }

  Future<void> _initializeVideoWithCache() async {
    if (_isInitializing) return;
    
    try {
      setState(() {
        _isInitializing = true;
      });

      debugPrint('Initializing video with cache: ${widget.video.videoUrl}');

      // Use preloaded controller if available
      if (widget.preloadedController != null) {
        await _usePreloadedController();
      } else {
        // Try to get cached video first
        File? cachedFile;
        try {
          if (await _cacheService.isVideoCached(widget.video.videoUrl)) {
            cachedFile = await _cacheService.getCachedVideo(widget.video.videoUrl);
            debugPrint('Using cached video: ${cachedFile.path}');
          } else {
            debugPrint('Video not cached, downloading: ${widget.video.videoUrl}');
            cachedFile = await _cacheService.preloadVideo(widget.video.videoUrl);
          }
        } catch (e) {
          debugPrint('Cache error, falling back to network: $e');
        }

        // Initialize video player with cached file or network URL
        if (cachedFile != null && await cachedFile.exists()) {
          await _createControllerFromFile(cachedFile);
        } else {
          debugPrint('Fallback to network video');
          await _createControllerFromNetwork();
        }
      }
      
      if (_videoPlayerController != null && mounted) {
        await _setupVideoController();
      }
    } catch (e) {
      debugPrint('Video initialization failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _usePreloadedController() async {
    _videoPlayerController = widget.preloadedController;
    
    if (!_videoPlayerController!.value.isInitialized) {
      await _videoPlayerController!.initialize();
    }
  }

  Future<void> _createControllerFromFile(File videoFile) async {
    _videoPlayerController = VideoPlayerController.file(
      videoFile,
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: false,
      ),
    );
    
    await _videoPlayerController!.initialize().timeout(
      const Duration(seconds: 10),
    );
  }

  Future<void> _createControllerFromNetwork() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: false,
      ),
    );
    
    await _videoPlayerController!.initialize().timeout(
      const Duration(seconds: 10),
    );
  }

  Future<void> _setupVideoController() async {
    _videoPlayerController!.setLooping(true);
    
    setState(() {
      _isInitialized = true;
    });
    
    // Only start playing if active and comments are not open
    if (widget.isActive && !widget.isCommentsOpen) {
      // Only seek to beginning for truly new videos, not when resuming
      _videoPlayerController!.seekTo(Duration.zero);
      _playVideo();
    }
    
    if (widget.onVideoControllerReady != null) {
      widget.onVideoControllerReady!(_videoPlayerController!);
    }
  }

  void _playVideo() {
    if (_isInitialized && _videoPlayerController != null) {
      _videoPlayerController!.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _pauseVideo() {
    if (_isInitialized && _videoPlayerController != null) {
      _videoPlayerController!.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _togglePlayPause() {
    if (widget.video.isMultipleImages || _isCommentsSheetOpen) return;
    
    if (!_isInitialized) return;
    
    bool willBePlaying;
    if (_isPlaying) {
      _pauseVideo();
      willBePlaying = false;
    } else {
      // Resume from current position, don't seek to beginning
      _playVideo();
      willBePlaying = true;
    }
    
    // Notify parent about manual play/pause
    if (widget.onManualPlayPause != null) {
      widget.onManualPlayPause!(willBePlaying);
    }
  }

  void _handleDoubleTap() {
    if (_isCommentsSheetOpen) return;
    
    // Trigger like animation
    _showLikeAnimation = true;
    _heartScaleController.forward().then((_) {
      _heartScaleController.reverse();
    });
    
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reset();
      if (mounted) {
        setState(() {
          _showLikeAnimation = false;
        });
      }
    });
    
    // Like the video
    ref.read(channelVideosProvider.notifier).likeVideo(widget.video.id);
    
    // Haptic feedback
    if (mounted) {
      setState(() {});
    }
  }

  void _handleFollowToggle() async {
    // Check if user has channel before allowing follow
    final canInteract = await _checkUserHasChannel();
    if (!canInteract) return;
    
    // Toggle follow for the channel
    ref.read(channelsProvider.notifier).toggleFollowChannel(widget.video.channelId);
    
    // Optional: Add haptic feedback
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleCaptionExpansion() {
    setState(() {
      _showFullCaption = !_showFullCaption;
    });
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _heartScaleController.dispose();
    
    if (_isInitialized && 
        _videoPlayerController != null && 
        widget.preloadedController == null) {
      _videoPlayerController!.dispose();
    }
    _videoPlayerController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main content area
          GestureDetector(
            onTap: _togglePlayPause,
            onDoubleTap: _handleDoubleTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Media content with proper full-screen coverage
                _buildMediaContent(),
                
                // Loading indicator
                if (widget.isLoading || _isInitializing)
                  _buildLoadingIndicator(),
                
                // Error state
                if (widget.hasFailed)
                  _buildErrorState(),
                
                // Play indicator for paused videos (TikTok style)
                if (!widget.video.isMultipleImages && _isInitialized && !_isPlaying && !_isCommentsSheetOpen)
                  _buildTikTokPlayIndicator(),
                
                // Like animation overlay
                if (_showLikeAnimation && !_isCommentsSheetOpen)
                  _buildLikeAnimation(),
                
                // Bottom content overlay (TikTok style) - moved to very bottom - UPDATED WITHOUT PRICE
                if (!_isCommentsSheetOpen)
                  _buildBottomContentOverlay(),
                
                // Image carousel indicators
                if (widget.video.isMultipleImages && widget.video.imageUrls.length > 1 && !_isCommentsSheetOpen)
                  _buildCarouselIndicators(),
              ],
            ),
          ),
          
          // Follow Button - Moved to top left corner (conditionally shown) - REMOVED COMPLETELY
          // if (!_isCommentsSheetOpen && widget.showFollowButton)
          //   _buildTopLeftFollowButton(),
        ],
      ),
    );
  }

  Widget _buildLikeAnimation() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _likeAnimationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Center heart that scales
              Center(
                child: AnimatedBuilder(
                  animation: _heartScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _heartScaleAnimation.value,
                      child: const Icon(
                        CupertinoIcons.heart,
                        color: Colors.red,
                        size: 80,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Floating hearts
              ..._buildFloatingHearts(),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildFloatingHearts() {
    const heartCount = 6;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return List.generate(heartCount, (index) {
      final offsetX = (index * 0.15 - 0.4) * screenWidth;
      final startY = screenHeight * 0.6;
      final endY = screenHeight * 0.2;
      
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
              angle: (index - 2) * 0.3,
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  CupertinoIcons.heart,
                  color: Colors.red,
                  size: 20 + (index % 3) * 10.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
  
  Widget _buildMediaContent() {
    if (widget.video.isMultipleImages) {
      return _buildImageCarousel();
    } else {
      return _buildVideoPlayer();
    }
  }

  Widget _buildImageCarousel() {
    if (widget.video.imageUrls.isEmpty) {
      return _buildPlaceholder(Icons.broken_image);
    }
    
    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        enableInfiniteScroll: widget.video.imageUrls.length > 1,
        autoPlay: widget.isActive && widget.video.imageUrls.length > 1 && !_isCommentsSheetOpen,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
        onPageChanged: (index, reason) {
          setState(() {
            _currentImageIndex = index;
          });
        },
      ),
      items: widget.video.imageUrls.map((imageUrl) {
        return _buildFullScreenImage(imageUrl);
      }).toList(),
    );
  }

  Widget _buildFullScreenImage(String imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover, // Changed to cover for full screen like channel feed
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(Icons.broken_image);
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: widget.isLoading || _isInitializing 
            ? _buildLoadingIndicator()
            : null,
      );
    }
    
    return _buildFullScreenVideo();
  }

  // Full screen video like channel feed screen - using cover fit
  Widget _buildFullScreenVideo() {
    final controller = _videoPlayerController!;
    
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover, // Changed to cover for full screen like channel feed
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to load video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _isInitialized = false;
                });
                _initializeMedia();
              },
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.3),
          size: 64,
        ),
      ),
    );
  }

  Widget _buildTikTokPlayIndicator() {
    return const Center(
      child: Icon(
        CupertinoIcons.play,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  // Smart caption widget that shows truncated or full text
  Widget _buildSmartCaption() {
    if (widget.video.caption.isEmpty) return const SizedBox.shrink();

    final captionStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.3,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.7),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );

    final moreStyle = captionStyle.copyWith(
      color: Colors.white.withOpacity(0.7),
      fontWeight: FontWeight.w500,
    );

    // Just use caption text
    String fullText = widget.video.caption;

    return GestureDetector(
      onTap: _toggleCaptionExpansion,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: _showFullCaption 
          ? _buildExpandedText(fullText, captionStyle, moreStyle)
          : _buildTruncatedText(fullText, captionStyle, moreStyle),
      ),
    );
  }

  Widget _buildExpandedText(String fullText, TextStyle captionStyle, TextStyle moreStyle) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: fullText,
            style: captionStyle,
          ),
          TextSpan(
            text: ' less',
            style: moreStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildTruncatedText(String fullText, TextStyle captionStyle, TextStyle moreStyle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        
        final textPainter = TextPainter(
          text: TextSpan(text: fullText, style: captionStyle),
          textDirection: TextDirection.ltr,
          maxLines: 2,
        );
        textPainter.layout(maxWidth: maxWidth);
        
        // If text doesn't exceed 2 lines, show it fully
        if (!textPainter.didExceedMaxLines) {
          return Text(fullText, style: captionStyle);
        }
        
        // Find where the text should be cut for 1.5 lines
        final firstLineHeight = textPainter.preferredLineHeight;
        final oneAndHalfLineHeight = firstLineHeight * 1.5;
        
        final cutPosition = textPainter.getPositionForOffset(
          Offset(maxWidth * 0.7, oneAndHalfLineHeight)
        );
        
        var cutIndex = cutPosition.offset;
        
        // Find the last space before cut position to avoid cutting words
        while (cutIndex > 0 && fullText[cutIndex] != ' ') {
          cutIndex--;
        }
        
        // Ensure we have some text to show
        if (cutIndex < 10) {
          cutIndex = fullText.indexOf(' ', 10);
          if (cutIndex == -1) cutIndex = fullText.length ~/ 3;
        }
        
        final truncatedText = fullText.substring(0, cutIndex);
        
        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: truncatedText,
                style: captionStyle,
              ),
              TextSpan(
                text: '... more',
                style: moreStyle,
              ),
            ],
          ),
        );
      },
    );
  }

  // TikTok-style bottom content overlay - REMOVED PRICE AND BUY BUTTON
  Widget _buildBottomContentOverlay() {
    // Hide all overlay content when comments are open
    if (_isCommentsSheetOpen) return const SizedBox.shrink();
    
    final channelsState = ref.watch(channelsProvider);
    final isFollowing = channelsState.followedChannels.contains(widget.video.channelId);
    final userChannel = channelsState.userChannel;
    final isOwner = userChannel != null && userChannel.id == widget.video.channelId;
    
    return Positioned(
      bottom: 8,
      left: 16,
      right: 80, // Leave space for right side menu
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Channel name (no verification status)
          _buildChannelNameWithVerification(),
          
          const SizedBox(height: 6),
          
          // Smart caption (product/service description) - always show if not empty
          if (widget.video.caption.isNotEmpty) ...[
            _buildSmartCaption(),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  // Channel name only (no verification status)
  Widget _buildChannelNameWithVerification() {
    return Text(
      widget.video.channelName,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
        shadows: [
          Shadow(
            color: Colors.black,
            blurRadius: 2,
          ),
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCarouselIndicators() {
    // Hide indicators when comments are open
    if (_isCommentsSheetOpen) return const SizedBox.shrink();
    
    return Positioned(
      top: 120, // Below top floating icons
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.video.imageUrls.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentImageIndex == index ? 8 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: _currentImageIndex == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Follow Button positioned at top left corner (conditionally shown)
  Widget _buildTopLeftFollowButton() {
    final channelsState = ref.watch(channelsProvider);
    final isFollowing = channelsState.followedChannels.contains(widget.video.channelId);
    final userChannel = channelsState.userChannel;
    final isOwner = userChannel != null && userChannel.id == widget.video.channelId;
    
    // Don't show follow button if user owns this channel
    if (isOwner) return const SizedBox.shrink();
    
    return Positioned(
      top: 16,
      left: 16,
      child: AnimatedScale(
        scale: isFollowing ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: isFollowing ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: GestureDetector(
            onTap: _handleFollowToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'Follow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}