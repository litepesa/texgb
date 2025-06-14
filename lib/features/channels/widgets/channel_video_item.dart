// lib/features/channels/widgets/channel_video_item.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/services/video_cache_service.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/widgets/comments_bottom_sheet.dart';
import 'package:textgb/constants.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ChannelVideoItem extends ConsumerStatefulWidget {
  final ChannelVideoModel video;
  final bool isActive;
  final Function(VideoPlayerController)? onVideoControllerReady;
  final VideoPlayerController? preloadedController;
  final bool isLoading;
  final bool hasFailed;
  
  const ChannelVideoItem({
    Key? key,
    required this.video,
    required this.isActive,
    this.onVideoControllerReady,
    this.preloadedController,
    this.isLoading = false,
    this.hasFailed = false,
  }) : super(key: key);

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
  // Removed local _isFollowing state - will use provider state instead
  
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
    
    if (_shouldReinitializeMedia(oldWidget)) {
      _cleanupCurrentController(oldWidget);
      _initializeMedia();
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
    
    if (widget.isActive) {
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
    if (widget.video.isMultipleImages) return;
    
    if (!_isInitialized) return;
    
    if (_isPlaying) {
      _pauseVideo();
    } else {
      if (_videoPlayerController != null) {
        _videoPlayerController!.seekTo(Duration.zero);
      }
      _playVideo();
    }
  }

  void _handleDoubleTap() {
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
    final modernTheme = context.modernTheme;
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: GestureDetector(
        onTap: _togglePlayPause,
        onDoubleTap: _handleDoubleTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media content with proper full-screen coverage
            _buildMediaContent(modernTheme),
            
            // Loading indicator
            if (widget.isLoading || _isInitializing)
              _buildLoadingIndicator(modernTheme),
            
            // Error state
            if (widget.hasFailed)
              _buildErrorState(modernTheme),
            
            // Play indicator for paused videos
            if (!widget.video.isMultipleImages && _isInitialized && !_isPlaying)
              _buildTikTokPlayIndicator(),
            
            // Like animation overlay
            if (_showLikeAnimation)
              _buildLikeAnimation(),
            
            // Top right floating buttons (follow and search)
            _buildTopRightFloatingButtons(modernTheme),
            
            // Gradient overlay for better text readability
            _buildGradientOverlay(),
            
            // Content overlay
            _buildContentOverlay(modernTheme),
            
            // Compact action buttons (only like, comment, download)
            _buildCompactActionButtons(modernTheme),
            
            // Image carousel indicators
            if (widget.video.isMultipleImages && widget.video.imageUrls.length > 1)
              _buildCarouselIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRightFloatingButtons(ModernThemeExtension modernTheme) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      right: 16,
      child: Row(
        children: [
          // Follow button - just text
          GestureDetector(
            onTap: () => _toggleFollow(),
            child: Consumer(
              builder: (context, ref, child) {
                // Get the current follow status from your channels provider
                final channelsState = ref.watch(channelsProvider);
                final isFollowing = _isUserFollowingChannel(channelsState, widget.video.channelId);
                
                return Text(
                  isFollowing ? 'Unfollow' : 'Follow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Search button - just icon
          GestureDetector(
            onTap: () => _navigateToSearch(),
            child: const Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
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
                      child: Icon(
                        Icons.favorite,
                        color: const Color(0xFFFF3040),
                        size: 80,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
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
                  Icons.favorite,
                  color: const Color(0xFFFF3040),
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
  
  Widget _buildMediaContent(ModernThemeExtension modernTheme) {
    if (widget.video.isMultipleImages) {
      return _buildImageCarousel(modernTheme);
    } else {
      return _buildVideoPlayer(modernTheme);
    }
  }

  Widget _buildImageCarousel(ModernThemeExtension modernTheme) {
    if (widget.video.imageUrls.isEmpty) {
      return _buildPlaceholder(modernTheme, Icons.broken_image);
    }
    
    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        enableInfiniteScroll: widget.video.imageUrls.length > 1,
        autoPlay: widget.isActive && widget.video.imageUrls.length > 1,
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
        return _buildFullScreenImage(imageUrl, modernTheme);
      }).toList(),
    );
  }

  Widget _buildFullScreenImage(String imageUrl, ModernThemeExtension modernTheme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingIndicator(modernTheme);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(modernTheme, Icons.broken_image);
        },
      ),
    );
  }

  Widget _buildVideoPlayer(ModernThemeExtension modernTheme) {
    if (!_isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: widget.isLoading || _isInitializing 
            ? _buildLoadingIndicator(modernTheme)
            : null,
      );
    }
    
    return SizedBox.expand(
      child: _buildFullScreenVideo(),
    );
  }

  Widget _buildFullScreenVideo() {
    final controller = _videoPlayerController!;
    
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ModernThemeExtension modernTheme) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ModernThemeExtension modernTheme) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white.withOpacity(0.7),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load video',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
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
              child: Text(
                'Retry',
                style: TextStyle(
                  color: modernTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ModernThemeExtension modernTheme, IconData icon) {
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
    return Center(
      child: Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 100,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 250, // Increased for better readability
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContentOverlay(ModernThemeExtension modernTheme) {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel info
          GestureDetector(
            onTap: () => _navigateToChannelProfile(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                  backgroundImage: widget.video.channelImage.isNotEmpty
                      ? NetworkImage(widget.video.channelImage)
                      : null,
                  child: widget.video.channelImage.isEmpty
                      ? Text(
                          widget.video.channelName.isNotEmpty
                              ? widget.video.channelName[0].toUpperCase()
                              : "C",
                          style: TextStyle(
                            color: modernTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.video.channelName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Caption with better shadows for readability
          Text(
            widget.video.caption,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.3,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                ),
              ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Tags
          if (widget.video.tags.isNotEmpty)
            SizedBox(
              height: 20,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.video.tags.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${widget.video.tags[index]}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButtons(ModernThemeExtension modernTheme) {
    return Positioned(
      bottom: 80,
      right: 12,
      child: Column(
        children: [
          // Like button
          _buildCompactActionButton(
            widget.video.isLiked ? Icons.favorite : Icons.favorite_border,
            widget.video.likes,
            widget.video.isLiked ? const Color(0xFFFF3040) : Colors.white,
            () {
              ref.read(channelVideosProvider.notifier).likeVideo(widget.video.id);
            },
            isActive: widget.video.isLiked,
          ),
          
          const SizedBox(height: 16),
          
          // Comment button
          _buildCompactActionButton(
            Icons.chat_bubble_outline,
            widget.video.comments,
            Colors.white,
            () {
              showCommentsBottomSheet(context, widget.video.id);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Download button
          _buildCompactActionButton(
            Icons.download_outlined,
            0,
            Colors.white,
            () {
              _downloadVideo();
            },
            showCount: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButton(
    IconData icon,
    int count,
    Color color,
    VoidCallback onTap, {
    bool isActive = false,
    bool showCount = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // Clean icon without background styling
            Icon(
              icon,
              color: color,
              size: 28,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 6,
                ),
              ],
            ),
            if (showCount && count > 0) ...[
              const SizedBox(height: 4),
              Text(
                _formatCount(count),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselIndicators() {
    return Positioned(
      top: 100,
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

  // Helper method to check if user is following a channel
  bool _isUserFollowingChannel(ChannelsState channelsState, String channelId) {
    // Check if the channelId is in the followedChannels list
    return channelsState.followedChannels.contains(channelId);
  }

  void _toggleFollow() {
    // Use your existing toggleFollowChannel method
    ref.read(channelsProvider.notifier).toggleFollowChannel(widget.video.channelId);
  }

  void _navigateToSearch() {
    debugPrint('Navigating to search');
    // TODO: Navigate to search screen
    Navigator.of(context).pushNamed('/search');
  }

  void _downloadVideo() {
    debugPrint('Downloading video: ${widget.video.id}');
    // TODO: Implement video download functionality
  }

  void _navigateToChannelProfile() {
    Navigator.of(context).pushNamed(
      Constants.channelProfileScreen,
      arguments: widget.video.channelId,
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