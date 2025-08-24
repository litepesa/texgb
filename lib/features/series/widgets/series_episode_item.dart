// lib/features/series/widgets/series_episode_item.dart
// REPURPOSED from channel_video_item.dart - Episode display with access control

import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:textgb/features/series/models/series_episode_model.dart';
import 'package:textgb/features/series/services/video_cache_service.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/series/providers/series_episodes_provider.dart';
import 'package:textgb/features/series/providers/series_provider.dart';
import 'package:textgb/constants.dart';
import 'package:carousel_slider/carousel_slider.dart';

class SeriesEpisodeItem extends ConsumerStatefulWidget {
  final SeriesEpisodeModel episode;
  final bool isActive;
  final Function(VideoPlayerController)? onVideoControllerReady;
  final Function(bool isPlaying)? onManualPlayPause;
  final VideoPlayerController? preloadedController;
  final bool isLoading;
  final bool hasFailed;
  final bool isCommentsOpen;
  final bool showWatchButton; // NEW: Show "Watch Series" button in main feed
  final bool showLockOverlay; // NEW: Show lock overlay for inaccessible episodes
  
  const SeriesEpisodeItem({
    super.key,
    required this.episode,
    required this.isActive,
    this.onVideoControllerReady,
    this.onManualPlayPause,
    this.preloadedController,
    this.isLoading = false,
    this.hasFailed = false,
    this.isCommentsOpen = false,
    this.showWatchButton = false,
    this.showLockOverlay = false,
  });

  @override
  ConsumerState<SeriesEpisodeItem> createState() => _SeriesEpisodeItemState();
}

class _SeriesEpisodeItemState extends ConsumerState<SeriesEpisodeItem>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {

  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  int _currentImageIndex = 0;
  bool _isInitializing = false;
  bool _showFullDescription = false;
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
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
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
  void didUpdateWidget(SeriesEpisodeItem oldWidget) {
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

    if (widget.episode.id != oldWidget.episode.id) {
      _showFullDescription = false;
    }
  }

  bool _shouldReinitializeMedia(SeriesEpisodeItem oldWidget) {
    return widget.episode.videoUrl != oldWidget.episode.videoUrl ||
           widget.episode.isMultipleImages != oldWidget.episode.isMultipleImages ||
           widget.preloadedController != oldWidget.preloadedController;
  }

  void _cleanupCurrentController(SeriesEpisodeItem oldWidget) {
    if (_isInitialized && 
        _videoPlayerController != null && 
        oldWidget.preloadedController == null) {
      _videoPlayerController!.dispose();
    }
    
    _videoPlayerController = null;
    _isInitialized = false;
  }

  void _handleActiveStateChange() {
    if (widget.episode.isMultipleImages) return;
    
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
    
    if (!widget.isCommentsOpen && widget.isActive && _isInitialized && !_isPlaying) {
      _playVideo();
    }
  }

  Future<void> _initializeMedia() async {
    if (widget.episode.isMultipleImages) {
      setState(() {
        _isInitialized = true;
      });
      return;
    }
    
    if (widget.episode.videoUrl.isEmpty) {
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

      debugPrint('Initializing episode video with cache: ${widget.episode.videoUrl}');

      if (widget.preloadedController != null) {
        await _usePreloadedController();
      } else {
        File? cachedFile;
        try {
          if (await _cacheService.isVideoCached(widget.episode.videoUrl)) {
            cachedFile = await _cacheService.getCachedVideo(widget.episode.videoUrl);
            debugPrint('Using cached episode video: ${cachedFile.path}');
          } else {
            debugPrint('Episode video not cached, downloading: ${widget.episode.videoUrl}');
            cachedFile = await _cacheService.preloadVideo(widget.episode.videoUrl);
          }
        } catch (e) {
          debugPrint('Cache error, falling back to network: $e');
        }

        if (cachedFile != null && await cachedFile.exists()) {
          await _createControllerFromFile(cachedFile);
        } else {
          debugPrint('Fallback to network episode video');
          await _createControllerFromNetwork();
        }
      }
      
      if (_videoPlayerController != null && mounted) {
        await _setupVideoController();
      }
    } catch (e) {
      debugPrint('Episode video initialization failed: $e');
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
      Uri.parse(widget.episode.videoUrl),
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
    
    if (widget.isActive && !widget.isCommentsOpen) {
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
    if (widget.episode.isMultipleImages || _isCommentsSheetOpen) return;
    
    if (!_isInitialized) return;
    
    bool willBePlaying;
    if (_isPlaying) {
      _pauseVideo();
      willBePlaying = false;
    } else {
      _playVideo();
      willBePlaying = true;
    }
    
    if (widget.onManualPlayPause != null) {
      widget.onManualPlayPause!(willBePlaying);
    }
  }

  void _handleDoubleTap() {
    if (_isCommentsSheetOpen) return;
    
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
    
    // Like the episode
    ref.read(seriesEpisodesProvider.notifier).likeEpisode(widget.episode.id);
    
    if (mounted) {
      setState(() {});
    }
  }

  void _handleWatchSeriesButtonTap() {
    // Navigate to series episodes screen starting from episode 1
    Navigator.pushNamed(
      context,
      Constants.seriesEpisodesScreen,
      arguments: {
        'seriesId': widget.episode.seriesId,
        'startEpisodeId': null, // Start from episode 1
      },
    );
  }

  void _toggleDescriptionExpansion() {
    setState(() {
      _showFullDescription = !_showFullDescription;
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
                // Media content
                _buildMediaContent(),
                
                // Loading indicator
                if (widget.isLoading || _isInitializing)
                  _buildLoadingIndicator(),
                
                // Error state
                if (widget.hasFailed)
                  _buildErrorState(),
                
                // Play indicator for paused videos
                if (!widget.episode.isMultipleImages && _isInitialized && !_isPlaying && !_isCommentsSheetOpen)
                  _buildPlayIndicator(),
                
                // Lock overlay for inaccessible episodes
                if (widget.showLockOverlay && !_isCommentsSheetOpen)
                  _buildLockOverlay(),
                
                // Like animation overlay
                if (_showLikeAnimation && !_isCommentsSheetOpen)
                  _buildLikeAnimation(),
                
                // Bottom content overlay
                if (!_isCommentsSheetOpen)
                  _buildBottomContentOverlay(),
                
                // Image carousel indicators
                if (widget.episode.isMultipleImages && widget.episode.imageUrls.length > 1 && !_isCommentsSheetOpen)
                  _buildCarouselIndicators(),
              ],
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
    if (widget.episode.isMultipleImages) {
      return _buildImageCarousel();
    } else {
      return _buildVideoPlayer();
    }
  }

  Widget _buildImageCarousel() {
    if (widget.episode.imageUrls.isEmpty) {
      return _buildPlaceholder(Icons.broken_image);
    }
    
    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        enableInfiniteScroll: widget.episode.imageUrls.length > 1,
        autoPlay: widget.isActive && widget.episode.imageUrls.length > 1 && !_isCommentsSheetOpen,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
        onPageChanged: (index, reason) {
          setState(() {
            _currentImageIndex = index;
          });
        },
      ),
      items: widget.episode.imageUrls.map((imageUrl) {
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
        fit: BoxFit.cover,
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
              'Failed to load episode',
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

  Widget _buildPlayIndicator() {
    return const Center(
      child: Icon(
        CupertinoIcons.play,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  // NEW: Lock overlay for inaccessible episodes
  Widget _buildLockOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Episode Locked',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Episode ${widget.episode.episodeNumber} requires series purchase',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Show paywall - this would be handled by parent
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0050),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Unlock Series'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartDescription() {
    if (widget.episode.description.isEmpty) return const SizedBox.shrink();

    final descriptionStyle = TextStyle(
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

    final moreStyle = descriptionStyle.copyWith(
      color: Colors.white.withOpacity(0.7),
      fontWeight: FontWeight.w500,
    );

    String fullText = widget.episode.description;

    return GestureDetector(
      onTap: _toggleDescriptionExpansion,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: _showFullDescription 
          ? _buildExpandedText(fullText, descriptionStyle, moreStyle)
          : _buildTruncatedText(fullText, descriptionStyle, moreStyle),
      ),
    );
  }

  Widget _buildExpandedText(String fullText, TextStyle descriptionStyle, TextStyle moreStyle) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: fullText,
            style: descriptionStyle,
          ),
          TextSpan(
            text: ' less',
            style: moreStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildTruncatedText(String fullText, TextStyle descriptionStyle, TextStyle moreStyle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        
        final textPainter = TextPainter(
          text: TextSpan(text: fullText, style: descriptionStyle),
          textDirection: TextDirection.ltr,
          maxLines: 2,
        );
        textPainter.layout(maxWidth: maxWidth);
        
        if (!textPainter.didExceedMaxLines) {
          return Text(fullText, style: descriptionStyle);
        }
        
        final firstLineHeight = textPainter.preferredLineHeight;
        final oneAndHalfLineHeight = firstLineHeight * 1.5;
        
        final cutPosition = textPainter.getPositionForOffset(
          Offset(maxWidth * 0.7, oneAndHalfLineHeight)
        );
        
        var cutIndex = cutPosition.offset;
        
        while (cutIndex > 0 && fullText[cutIndex] != ' ') {
          cutIndex--;
        }
        
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
                style: descriptionStyle,
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

  Widget _buildBottomContentOverlay() {
    if (_isCommentsSheetOpen) return const SizedBox.shrink();
    
    return Positioned(
      bottom: 8,
      left: 16,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Episode info
          _buildEpisodeInfo(),
          
          const SizedBox(height: 6),
          
          // Episode description
          if (widget.episode.description.isNotEmpty) ...[
            _buildSmartDescription(),
            const SizedBox(height: 8),
          ],
          
          // Watch Series button (only in main feed)
          if (widget.showWatchButton) ...[
            _buildWatchSeriesButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildEpisodeInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Series title
        Text(
          widget.episode.seriesTitle,
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
        ),
        
        const SizedBox(height: 2),
        
        // Episode info
        Row(
          children: [
            Text(
              widget.episode.shortEpisodeTitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            if (widget.episode.title.isNotEmpty) ...[
              const Text(
                ' • ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              Flexible(
                child: Text(
                  widget.episode.title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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
            ],
          ],
        ),
      ],
    );
  }

  // NEW: Watch Series button for main feed
  Widget _buildWatchSeriesButton() {
    return GestureDetector(
      onTap: _handleWatchSeriesButtonTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF0050).withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 6),
            const Text(
              'Watch Series',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselIndicators() {
    if (_isCommentsSheetOpen) return const SizedBox.shrink();
    
    return Positioned(
      top: 120,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.episode.imageUrls.length, (index) {
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