// lib/features/channels/widgets/channel_video_item.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/services/video_cache_service.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/widgets/comments_bottom_sheet.dart';
import 'package:textgb/constants.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:audio_session/audio_session.dart';

class ChannelVideoItem extends ConsumerStatefulWidget {
  final ChannelVideoModel video;
  final bool isActive;
  final Function(Player)? onVideoControllerReady;
  final Player? preloadedController;
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

  Player? _player;
  VideoController? _videoController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  int _currentImageIndex = 0;
  bool _isInitializing = false;
  
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
        _player != null && 
        oldWidget.preloadedController == null) {
      _player!.dispose();
    }
    
    _player = null;
    _videoController = null;
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
    
    await _initializeVideoWithMediaKit();
  }

  Future<void> _initializeVideoWithMediaKit() async {
    if (_isInitializing) return;
    
    try {
      setState(() {
        _isInitializing = true;
      });

      debugPrint('Initializing MediaKit video with amplification: ${widget.video.videoUrl}');

      // Configure mobile audio session for maximum amplification
      await _configureMobileAudioSession();

      // Use preloaded controller if available
      if (widget.preloadedController != null) {
        await _usePreloadedController();
      } else {
        // Try to get cached video first
        File? cachedFile;
        try {
          if (await _cacheService.isVideoCached(widget.video.videoUrl)) {
            cachedFile = await _cacheService.getCachedVideo(widget.video.videoUrl);
            debugPrint('Using cached video for MediaKit: ${cachedFile.path}');
          } else {
            debugPrint('Video not cached, using network URL with MediaKit: ${widget.video.videoUrl}');
            // Start caching in background
            _cacheService.preloadVideo(widget.video.videoUrl);
          }
        } catch (e) {
          debugPrint('Cache error, falling back to network: $e');
        }

        // Initialize MediaKit player
        await _createMediaKitPlayer(cachedFile);
      }
      
      if (_player != null && mounted) {
        await _setupMediaKitController();
      }
    } catch (e) {
      debugPrint('MediaKit video initialization failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _configureMobileAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        // iOS Configuration for maximum audio performance
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.moviePlayback,
        
        // Android Configuration for enhanced audio
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.movie,
          flags: AndroidAudioFlags.audibilityEnforced,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ));
      
      debugPrint('Mobile audio session configured for amplification');
    } catch (e) {
      debugPrint('Audio session configuration failed: $e');
    }
  }

  Future<void> _usePreloadedController() async {
    _player = widget.preloadedController;
    _videoController = VideoController(_player!);
    
    // Apply aggressive audio amplification to preloaded controller
    await _player!.setVolume(200.0); // 200% amplification
    debugPrint('Applied 200% audio amplification to preloaded MediaKit player');
  }

  Future<void> _createMediaKitPlayer(File? videoFile) async {
    _player = Player();
    _videoController = VideoController(_player!);
    
    // Configure MediaKit player for optimal mobile performance
    await _player!.setPlaylistMode(PlaylistMode.single);
    //await _player!.setAudioDevice(AudioDevice.auto());
    
    // AGGRESSIVE AUDIO AMPLIFICATION - TikTok Style
    await _player!.setVolume(200.0); // 200% volume boost!
    debugPrint('MediaKit player configured with 200% audio amplification');
    
    // Load video from cached file or network
    if (videoFile != null && await videoFile.exists()) {
      await _player!.open(Media(videoFile.path));
      debugPrint('MediaKit loaded cached video: ${videoFile.path}');
    } else {
      await _player!.open(Media(widget.video.videoUrl));
      debugPrint('MediaKit loaded network video: ${widget.video.videoUrl}');
    }
  }

  Future<void> _setupMediaKitController() async {
    // Set looping for continuous playback
    await _player!.setPlaylistMode(PlaylistMode.loop);
    
    setState(() {
      _isInitialized = true;
    });
    
    if (widget.isActive) {
      await _player!.seek(Duration.zero);
      _playVideo();
    }
    
    // Notify parent that MediaKit controller is ready
    if (widget.onVideoControllerReady != null) {
      widget.onVideoControllerReady!(_player!);
    }
    
    debugPrint('MediaKit video setup complete with audio amplification');
  }

  void _playVideo() {
    if (_isInitialized && _player != null) {
      _player!.play();
      setState(() {
        _isPlaying = true;
      });
      debugPrint('MediaKit video playing with amplified audio');
    }
  }

  void _pauseVideo() {
    if (_isInitialized && _player != null) {
      _player!.pause();
      setState(() {
        _isPlaying = false;
      });
      debugPrint('MediaKit video paused');
    }
  }

  void _togglePlayPause() {
    if (widget.video.isMultipleImages) return;
    
    if (!_isInitialized) return;
    
    if (_isPlaying) {
      _pauseVideo();
    } else {
      if (_player != null) {
        _player!.seek(Duration.zero);
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
        _player != null && 
        widget.preloadedController == null) {
      _player!.dispose();
    }
    _player = null;
    _videoController = null;
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
            
            // Gradient overlay for better text readability
            _buildGradientOverlay(),
            
            // Content overlay
            _buildContentOverlay(modernTheme),
            
            // Compact action buttons
            _buildCompactActionButtons(modernTheme),
            
            // Image carousel indicators
            if (widget.video.isMultipleImages && widget.video.imageUrls.length > 1)
              _buildCarouselIndicators(),
          ],
        ),
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
      return _buildMediaKitVideoPlayer(modernTheme);
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

  Widget _buildMediaKitVideoPlayer(ModernThemeExtension modernTheme) {
    if (!_isInitialized || _videoController == null) {
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
      child: Video(
        controller: _videoController!,
        fit: BoxFit.cover,
        controls: NoVideoControls, // Hide controls for TikTok-style experience
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
          _buildProfileAction(modernTheme),
          const SizedBox(height: 16),
          
          _buildCompactActionButton(
            widget.video.isLiked ? Icons.favorite : Icons.favorite_border,
            widget.video.likes,
            widget.video.isLiked ? const Color(0xFFFF3040) : Colors.white,
            () {
              ref.read(channelVideosProvider.notifier).likeVideo(widget.video.id);
            },
            isActive: widget.video.isLiked,
          ),
          
          const SizedBox(height: 12),
          
          _buildCompactActionButton(
            Icons.chat_bubble_outline,
            widget.video.comments,
            Colors.white,
            () {
              showCommentsBottomSheet(context, widget.video.id);
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildCompactActionButton(
            Icons.bookmark_border,
            0,
            Colors.white,
            () {
              _toggleBookmark();
            },
            showCount: false,
          ),
          
          const SizedBox(height: 12),
          
          _buildCompactActionButton(
            Icons.share_outlined,
            0,
            Colors.white,
            () {
              _showShareOptions();
            },
            showCount: false,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAction(ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: () => _navigateToChannelProfile(),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 22,
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
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: -2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3040),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 12,
              ),
            ),
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

  void _toggleBookmark() {
    debugPrint('Bookmarking video: ${widget.video.id}');
  }

  void _navigateToChannelProfile() {
    Navigator.of(context).pushNamed(
      Constants.channelProfileScreen,
      arguments: widget.video.channelId,
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.copy, 'Copy Link', () {
                  Navigator.pop(context);
                }),
                _buildShareOption(Icons.message, 'Message', () {
                  Navigator.pop(context);
                }),
                _buildShareOption(Icons.more_horiz, 'More', () {
                  Navigator.pop(context);
                }),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
        ],
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