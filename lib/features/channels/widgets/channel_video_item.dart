// lib/features/channels/widgets/channel_video_item.dart
// Enhanced with better error handling, performance, and UI

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
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
  
  const ChannelVideoItem({
    Key? key,
    required this.video,
    required this.isActive,
    this.onVideoControllerReady,
    this.preloadedController,
  }) : super(key: key);

  @override
  ConsumerState<ChannelVideoItem> createState() => _ChannelVideoItemState();
}

class _ChannelVideoItemState extends ConsumerState<ChannelVideoItem>
    with AutomaticKeepAliveClientMixin {

  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentImageIndex = 0;
  int _retryCount = 0;
  bool _isRetrying = false;
  
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

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
    
    // Handle active state changes
    if (widget.isActive != oldWidget.isActive) {
      _handleActiveStateChange();
    }
    
    // Handle media changes
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
    _hasError = false;
    _retryCount = 0;
  }

  void _handleActiveStateChange() {
    if (widget.video.isMultipleImages) return;
    
    if (widget.isActive && _isInitialized && !_isPlaying && !_hasError) {
      _playVideo();
    } else if (!widget.isActive && _isInitialized && _isPlaying) {
      _pauseVideo();
    }
  }

  Future<void> _initializeMedia() async {
    if (widget.video.isMultipleImages) {
      setState(() {
        _isInitialized = true;
        _hasError = false;
      });
      return;
    }
    
    if (widget.video.videoUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No video URL provided';
      });
      return;
    }
    
    await _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _isRetrying = _retryCount > 0;
      });

      if (widget.preloadedController != null) {
        await _usePreloadedController();
      } else {
        await _createNewController();
      }
      
      if (_videoPlayerController != null && mounted) {
        await _setupVideoController();
      }
    } catch (e) {
      await _handleVideoError('Failed to initialize video: $e');
    }
  }

  Future<void> _usePreloadedController() async {
    debugPrint('Using preloaded controller for ${widget.video.id}');
    _videoPlayerController = widget.preloadedController;
    
    if (!_videoPlayerController!.value.isInitialized) {
      await _videoPlayerController!.initialize();
    }
  }

  Future<void> _createNewController() async {
    debugPrint('Creating new controller for ${widget.video.id}');
    _videoPlayerController = VideoPlayerController.network(
      widget.video.videoUrl,
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: false,
      ),
    );
    
    // Add timeout for initialization
    await _videoPlayerController!.initialize().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Video initialization timeout');
      },
    );
  }

  Future<void> _setupVideoController() async {
    _videoPlayerController!.setLooping(true);
    
    setState(() {
      _isInitialized = true;
      _hasError = false;
      _retryCount = 0;
      _isRetrying = false;
    });
    
    // Auto-play if active
    if (widget.isActive) {
      _playVideo();
    }
    
    // Notify parent
    if (widget.onVideoControllerReady != null) {
      widget.onVideoControllerReady!(_videoPlayerController!);
    }
  }

  Future<void> _handleVideoError(String error) async {
    debugPrint('Video error for ${widget.video.id}: $error');
    
    if (_retryCount < _maxRetries) {
      _retryCount++;
      debugPrint('Retrying video initialization (attempt $_retryCount/$_maxRetries)');
      
      setState(() {
        _isRetrying = true;
      });
      
      // Wait before retrying
      await Future.delayed(_retryDelay);
      
      if (mounted) {
        await _initializeVideo();
      }
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video after $_maxRetries attempts';
        _isRetrying = false;
      });
    }
  }

  void _playVideo() {
    if (_isInitialized && _videoPlayerController != null && !_hasError) {
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
    if (widget.video.isMultipleImages || !_isInitialized || _hasError) return;
    
    if (_isPlaying) {
      _pauseVideo();
    } else {
      _playVideo();
    }
  }

  void _retryVideoLoad() {
    _retryCount = 0;
    _initializeVideo();
  }

  @override
  void dispose() {
    // Only dispose if we created the controller (not preloaded)
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
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Media content
        _buildMediaContent(modernTheme),
        
        // Gradient overlay
        _buildGradientOverlay(),
        
        // Content overlay
        _buildContentOverlay(modernTheme),
        
        // Action buttons
        _buildActionButtons(modernTheme),
        
        // Play/pause indicator
        if (!widget.video.isMultipleImages && _isInitialized && !_isPlaying && !_hasError)
          _buildPlayPauseIndicator(),
        
        // Image carousel indicators
        if (widget.video.isMultipleImages && widget.video.imageUrls.length > 1)
          _buildCarouselIndicators(),
      ],
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
      return _buildImageError('No images available');
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
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  color: modernTheme.primaryColor,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / 
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildImageError('Failed to load image');
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVideoPlayer(ModernThemeExtension modernTheme) {
    if (_hasError) {
      return _buildVideoError(modernTheme);
    }
    
    if (_isRetrying) {
      return _buildRetryingIndicator(modernTheme);
    }
    
    if (!_isInitialized) {
      return _buildVideoLoading(modernTheme);
    }
    
    return GestureDetector(
      onTap: _togglePlayPause,
      child: VideoPlayer(_videoPlayerController!),
    );
  }

  Widget _buildVideoError(ModernThemeExtension modernTheme) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Video Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retryVideoLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryingIndicator(ModernThemeExtension modernTheme) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: modernTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Retrying... ($_retryCount/$_maxRetries)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLoading(ModernThemeExtension modernTheme) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: modernTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading video...',
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

  Widget _buildImageError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Colors.white.withOpacity(0.7),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
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
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.4),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentOverlay(ModernThemeExtension modernTheme) {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel info
          GestureDetector(
            onTap: () => _navigateToChannelProfile(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
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
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Caption
          Text(
            widget.video.caption,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 12),
          
          // Tags
          if (widget.video.tags.isNotEmpty)
            SizedBox(
              height: 24,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.video.tags.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '#${widget.video.tags[index]}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildActionButtons(ModernThemeExtension modernTheme) {
    return Positioned(
      bottom: 20,
      right: 16,
      child: Column(
        children: [
          // Like button
          _buildActionButton(
            Icons.favorite,
            _formatCount(widget.video.likes),
            widget.video.isLiked ? Colors.red : Colors.white,
            () {
              ref.read(channelVideosProvider.notifier).likeVideo(widget.video.id);
            },
            isActive: widget.video.isLiked,
          ),
          
          const SizedBox(height: 20),
          
          // Comment button
          _buildActionButton(
            Icons.comment,
            _formatCount(widget.video.comments),
            Colors.white,
            () {
              showCommentsBottomSheet(context, widget.video.id);
            },
          ),
          
          const SizedBox(height: 20),
          
          // Share button
          _buildActionButton(
            Icons.share,
            "Share",
            Colors.white,
            () {
              _showShareOptions();
            },
          ),
          
          const SizedBox(height: 20),
          
          // Views indicator
          _buildViewsIndicator(modernTheme),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive 
                    ? color.withOpacity(0.2)
                    : Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewsIndicator(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility,
            color: Colors.white.withOpacity(0.8),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            _formatCount(widget.video.views),
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseIndicator() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 40,
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
            width: _currentImageIndex == index ? 12 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentImageIndex == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
            ),
          );
        }),
      ),
    );
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
                  // Copy link functionality
                }),
                _buildShareOption(Icons.message, 'Message', () {
                  Navigator.pop(context);
                  // Share via message
                }),
                _buildShareOption(Icons.more_horiz, 'More', () {
                  Navigator.pop(context);
                  // More share options
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