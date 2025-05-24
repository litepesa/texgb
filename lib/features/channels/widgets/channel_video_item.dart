// lib/features/channels/widgets/channel_video_item.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
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
    with AutomaticKeepAliveClientMixin {

  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  int _currentImageIndex = 0;
  bool _isInitializing = false;

  
  final VideoCacheService _cacheService = VideoCacheService();

  @override
  bool get wantKeepAlive => widget.isActive;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
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
    if (widget.video.isMultipleImages || !_isInitialized) return;
    
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _videoPlayerController!.seekTo(Duration.zero);
      _playVideo();
    }
  }

  @override
  void dispose() {
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
          
          // Gradient overlay for better text readability
          _buildGradientOverlay(),
          
          // Content overlay
          _buildContentOverlay(modernTheme),
          
          // Compact action buttons
          _buildCompactActionButtons(modernTheme),
          
          // Play indicator for paused videos
          if (!widget.video.isMultipleImages && _isInitialized && !_isPlaying)
            _buildMinimalPlayIndicator(),
          
          // Image carousel indicators
          if (widget.video.isMultipleImages && widget.video.imageUrls.length > 1)
            _buildCarouselIndicators(),
        ],
      ),
    );
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
    
    return GestureDetector(
      onTap: _togglePlayPause,
      child: SizedBox.expand(
        child: _buildFullScreenVideo(),
      ),
    );
  }

  Widget _buildFullScreenVideo() {
    final controller = _videoPlayerController!;
    
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
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

  Widget _buildMinimalPlayIndicator() {
    return Center(
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 36,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
            ),
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