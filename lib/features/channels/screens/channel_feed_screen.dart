// lib/features/channels/screens/channel_feed_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/services/video_cache_service.dart';
import 'package:textgb/features/channels/widgets/comments_bottom_sheet.dart';
import 'package:textgb/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ChannelFeedScreen extends ConsumerStatefulWidget {
  final String videoId;

  const ChannelFeedScreen({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  ConsumerState<ChannelFeedScreen> createState() => _ChannelFeedScreenState();
}

class _ChannelFeedScreenState extends ConsumerState<ChannelFeedScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // Core controllers
  final PageController _pageController = PageController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache service
  final VideoCacheService _cacheService = VideoCacheService();
  
  // State management
  int _currentVideoIndex = 0;
  bool _isAppInForeground = true;
  bool _isScreenActive = true;
  
  // Caption expansion state
  Map<int, bool> _expandedCaptions = {};
  
  // Like animation state
  bool _showLikeAnimation = false;
  late AnimationController _likeAnimationController;
  late AnimationController _heartScaleController;
  late Animation<double> _heartScaleAnimation;
  
  // Channel data
  ChannelModel? _channel;
  List<ChannelVideoModel> _channelVideos = [];
  bool _isChannelLoading = true;
  String? _channelError;
  bool _isFollowing = false;
  bool _isOwner = false;
  
  // Video controllers
  Map<int, VideoPlayerController> _videoControllers = {};
  Map<int, bool> _videoInitialized = {};
  Timer? _cacheCleanupTimer;
  
  // Progress tracking
  Timer? _progressTimer;
  double _currentProgress = 0.0;
  
  // Animation controllers
  late AnimationController _imageProgressController;
  late AnimationController _progressController;
  
  // Bottom nav bar constants
  static const double _bottomNavContentHeight = 60.0;
  static const double _progressBarHeight = 3.0;
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);

  // Store original system UI for restoration
  SystemUiOverlayStyle? _originalSystemUiStyle;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupSystemUI();
    _loadChannelData();
    _setupCacheCleanup();
    _initializeAnimationControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store original system UI after dependencies are available
    if (_originalSystemUiStyle == null) {
      _storeOriginalSystemUI();
    }
  }

  void _storeOriginalSystemUI() {
    // Store the current system UI style before making changes
    final brightness = Theme.of(context).brightness;
    _originalSystemUiStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }
  
  void _initializeAnimationControllers() {
    _imageProgressController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    
    // Like animation controllers
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

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent, // Changed to transparent
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  void _setupCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _cacheService.cleanupOldCache();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        if (_isScreenActive) {
          _playCurrentVideo();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        _pauseCurrentVideo();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _loadChannelData() async {
    if (!mounted) return;
    
    setState(() {
      _isChannelLoading = true;
      _channelError = null;
    });

    try {
      // Get the specific video first to find the channel
      final targetVideo = await ref.read(channelVideosProvider.notifier).getVideoById(widget.videoId);
      
      if (targetVideo == null) {
        throw Exception('Video not found');
      }
      
      // Get the channel
      final channel = await ref.read(channelsProvider.notifier).getChannelById(targetVideo.channelId);
      
      if (channel == null) {
        throw Exception('Channel not found');
      }
      
      // Load all channel videos
      final videos = await ref.read(channelVideosProvider.notifier).loadChannelVideos(targetVideo.channelId);
      
      // Find the index of the target video
      final targetIndex = videos.indexWhere((video) => video.id == widget.videoId);
      
      final followedChannels = ref.read(channelsProvider).followedChannels;
      final isFollowing = followedChannels.contains(targetVideo.channelId);
      final userChannel = ref.read(channelsProvider).userChannel;
      final isOwner = userChannel != null && userChannel.id == targetVideo.channelId;
      
      if (mounted) {
        setState(() {
          _channel = channel;
          _channelVideos = videos;
          _isFollowing = isFollowing;
          _isOwner = isOwner;
          _isChannelLoading = false;
          _currentVideoIndex = targetIndex >= 0 ? targetIndex : 0;
        });
        
        // Set the page controller to the target video after the widget is built
        if (targetIndex >= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.animateToPage(
                targetIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }
        
        // Initialize video controllers with performance optimization
        _initializeVideoControllersOptimized();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _channelError = e.toString();
          _isChannelLoading = false;
        });
      }
    }
  }

  void _initializeVideoControllersOptimized() {
    if (_channelVideos.isEmpty) return;
    
    // Only initialize current video and next 2 videos for performance
    final maxInitialize = (_channelVideos.length).clamp(0, 3);
    final startIndex = _currentVideoIndex;
    
    for (int i = 0; i < maxInitialize; i++) {
      final index = startIndex + i;
      if (index < _channelVideos.length) {
        final video = _channelVideos[index];
        if (!video.isMultipleImages && video.videoUrl.isNotEmpty) {
          _initializeVideoController(index, video.videoUrl);
        }
      }
    }
    
    // Wait for the next frame before starting playback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_channelVideos.isNotEmpty && mounted) {
        _playCurrentVideo(); // This will handle wakelock
        _startProgressTracking();
      }
    });
  }

  Future<void> _initializeVideoController(int index, String videoUrl) async {
    try {
      File? cachedFile;
      try {
        if (await _cacheService.isVideoCached(videoUrl)) {
          cachedFile = await _cacheService.getCachedVideo(videoUrl);
        } else {
          // Only preload if within first 3 videos for performance
          if (index < 3) {
            cachedFile = await _cacheService.preloadVideo(videoUrl);
          }
        }
      } catch (e) {
        debugPrint('Cache error for video $index, falling back to network: $e');
      }

      VideoPlayerController controller;
      if (cachedFile != null && await cachedFile.exists()) {
        controller = VideoPlayerController.file(cachedFile);
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }
      
      _videoControllers[index] = controller;
      
      await controller.initialize();
      controller.setLooping(true);
      
      if (mounted) {
        setState(() {
          _videoInitialized[index] = true;
        });
      }
      
      if (index == _currentVideoIndex && _isScreenActive && _isAppInForeground) {
        controller.play();
        WakelockPlus.enable();
      }
    } catch (e) {
      debugPrint('Error initializing video $index: $e');
    }
  }

  void _onPageChanged(int index) {
    if (index >= _channelVideos.length) return;

    // Pause current video and disable wakelock
    _pauseCurrentVideo();
    _stopProgressTracking();
    
    setState(() {
      _currentVideoIndex = index;
      _currentProgress = 0.0;
      _progressNotifier.value = 0.0;
    });

    // Play new video (this will enable wakelock if appropriate)
    _playCurrentVideo();
    _startProgressTracking();
    
    // Intelligent preloading: initialize next video controller if needed
    _preloadNextVideos(index);
    
    // Increment view count
    ref.read(channelVideosProvider.notifier).incrementViewCount(_channelVideos[index].id);
  }
  
  void _preloadNextVideos(int currentIndex) {
    // Preload next 2 videos if not already initialized
    for (int i = 1; i <= 2; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex < _channelVideos.length && 
          !_videoInitialized.containsKey(nextIndex) &&
          !_channelVideos[nextIndex].isMultipleImages &&
          _channelVideos[nextIndex].videoUrl.isNotEmpty) {
        _initializeVideoController(nextIndex, _channelVideos[nextIndex].videoUrl);
      }
    }
    
    // Clean up old controllers to save memory (keep only current and next 2)
    _cleanupOldControllers(currentIndex);
  }
  
  void _cleanupOldControllers(int currentIndex) {
    final controllersToRemove = <int>[];
    
    _videoControllers.forEach((index, controller) {
      // Keep current video and next 2 videos
      if (index < currentIndex - 1 || index > currentIndex + 2) {
        controllersToRemove.add(index);
      }
    });
    
    for (final index in controllersToRemove) {
      _videoControllers[index]?.dispose();
      _videoControllers.remove(index);
      _videoInitialized.remove(index);
    }
  }
  
  void _startProgressTracking() {
    _progressTimer?.cancel();
    
    if (_currentVideoIndex >= _channelVideos.length) return;
    final currentVideo = _channelVideos[_currentVideoIndex];
    
    if (currentVideo.isMultipleImages) {
      // For images, use animation controller and enable wakelock
      _imageProgressController.reset();
      _imageProgressController.forward();
      _imageProgressController.addListener(_updateImageProgress);
      
      // Enable wakelock for images too to prevent screen from sleeping
      if (_isScreenActive && _isAppInForeground) {
        WakelockPlus.enable();
      }
    } else {
      // For videos, track actual video progress
      _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (!mounted || !_isScreenActive || !_isAppInForeground) {
          timer.cancel();
          WakelockPlus.disable();
          return;
        }
        
        final controller = _videoControllers[_currentVideoIndex];
        if (controller != null && controller.value.isInitialized) {
          final position = controller.value.position;
          final duration = controller.value.duration;
          
          if (duration.inMilliseconds > 0) {
            final progress = position.inMilliseconds / duration.inMilliseconds;
            setState(() {
              _currentProgress = progress;
            });
            _progressNotifier.value = progress;
          }
        }
      });
    }
  }
  
  void _stopProgressTracking() {
    _progressTimer?.cancel();
    _imageProgressController.removeListener(_updateImageProgress);
    _imageProgressController.stop();
    // Don't disable wakelock here as it might be needed for the next content
  }
  
  void _updateImageProgress() {
    if (!mounted) return;
    final progress = _imageProgressController.value;
    setState(() {
      _currentProgress = progress;
    });
    _progressNotifier.value = progress;
  }

  void _playCurrentVideo() {
    if (!_isScreenActive || !_isAppInForeground || _currentVideoIndex >= _channelVideos.length) {
      WakelockPlus.disable();
      return;
    }
    
    final controller = _videoControllers[_currentVideoIndex];
    if (controller != null && _videoInitialized[_currentVideoIndex] == true) {
      controller.seekTo(Duration.zero);
      controller.play();
      WakelockPlus.enable();
    } else {
      // For images or when video is not ready, still enable wakelock
      WakelockPlus.enable();
    }
  }

  void _pauseCurrentVideo() {
    final controller = _videoControllers[_currentVideoIndex];
    if (controller != null && _videoInitialized[_currentVideoIndex] == true) {
      controller.pause();
    }
    // Always disable wakelock when pausing
    WakelockPlus.disable();
  }

  void _togglePlayPause() {
    if (_currentVideoIndex >= _channelVideos.length) return;
    
    final currentVideo = _channelVideos[_currentVideoIndex];
    if (currentVideo.isMultipleImages) return;
    
    final controller = _videoControllers[_currentVideoIndex];
    if (controller != null && _videoInitialized[_currentVideoIndex] == true) {
      if (controller.value.isPlaying) {
        controller.pause();
        WakelockPlus.disable();
      } else {
        controller.play();
        WakelockPlus.enable();
      }
    }
  }

  void _handleDoubleTap() {
    if (_currentVideoIndex >= _channelVideos.length) return;
    
    // Trigger like animation
    setState(() {
      _showLikeAnimation = true;
    });
    
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
    
    // Like the current video
    final currentVideo = _channelVideos[_currentVideoIndex];
    ref.read(channelVideosProvider.notifier).likeVideo(currentVideo.id);
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _toggleFollow() async {
    if (_channel == null) return;
    
    setState(() {
      _isFollowing = !_isFollowing;
    });
    
    await ref.read(channelsProvider.notifier).toggleFollowChannel(_channel!.id);
  }

  void _toggleCaptionExpansion(int index) {
    setState(() {
      _expandedCaptions[index] = !(_expandedCaptions[index] ?? false);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF424242),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.8,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  // Enhanced back navigation with proper system UI restoration
  void _handleBackNavigation() {
    // Pause playback and disable wakelock before leaving
    _pauseCurrentVideo();
    
    // Restore the original system UI style if available
    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    } else {
      // Fallback: restore based on current theme
      final brightness = Theme.of(context).brightness;
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
    }
    
    // Small delay to ensure system UI is properly restored
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // Like animation overlay
  Widget _buildLikeAnimationOverlay() {
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
                        Icons.favorite,
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
                  Icons.favorite,
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Stop all playback and disable wakelock before disposing
    _pauseCurrentVideo();
    
    // Restore original system UI style on dispose if available
    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    } else if (mounted) {
      // Fallback: restore based on current theme
      final brightness = Theme.of(context).brightness;
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
    }
    
    _cacheService.dispose();
    _cacheCleanupTimer?.cancel();
    _progressTimer?.cancel();
    _imageProgressController.dispose();
    _progressController.dispose();
    _likeAnimationController.dispose();
    _heartScaleController.dispose();
    _progressNotifier.dispose();
    
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoInitialized.clear();
    
    _pageController.dispose();
    
    // Final wakelock disable
    WakelockPlus.disable();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isChannelLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    if (_channelError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildErrorState(),
      );
    }
    
    final modernTheme = context.modernTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalBottomNavHeight = _bottomNavContentHeight + _progressBarHeight + bottomPadding;
    
    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Stack(
          children: [
            // Main video content - FULL SCREEN
            Positioned.fill(
              bottom: totalBottomNavHeight,
              child: _buildVideoFeed(),
            ),
            
            // Top bar overlay - Reliable back button and search
            Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              left: 4, // Adjusted for better tap area
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Enhanced back button with larger tap area
                  Material(
                    type: MaterialType.transparency,
                    child: IconButton(
                      onPressed: _handleBackNavigation,
                      icon: const Icon(
                        CupertinoIcons.chevron_left,
                        color: Colors.white,
                        size: 28,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      iconSize: 28,
                      padding: const EdgeInsets.all(12), // Larger tap area
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      splashRadius: 24,
                      tooltip: 'Back',
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 28,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    iconSize: 28,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    splashRadius: 24,
                  ),
                ],
              ),
            ),
            
            // Bottom content overlay
            _buildBottomContent(),
            
            // Bottom navigation bar with progress indicator
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavigationBar(modernTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoFeed() {
    if (_channelVideos.isEmpty) {
      return _buildEmptyState();
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _channelVideos.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        final video = _channelVideos[index];
        
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
                _buildVideoContent(video, index),
                // Like animation overlay
                if (_showLikeAnimation && index == _currentVideoIndex)
                  _buildLikeAnimationOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoContent(ChannelVideoModel video, int index) {
    if (video.isMultipleImages) {
      return _buildImageCarousel(video.imageUrls);
    } else if (video.videoUrl.isNotEmpty) {
      return _buildVideoPlayer(index);
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildVideoPlayer(int index) {
    final controller = _videoControllers[index];
    final isInitialized = _videoInitialized[index] ?? false;
    
    if (controller == null || !isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
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

  Widget _buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) return _buildPlaceholder();
    
    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        enableInfiniteScroll: imageUrls.length > 1,
        autoPlay: imageUrls.length > 1,
        autoPlayInterval: const Duration(seconds: 4),
      ),
      items: imageUrls.map((imageUrl) {
        return SizedBox.expand(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        );
      }).toList(),
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

  // Bottom content overlay - Profile + Follow + Caption (positioned from progress bar level)
  Widget _buildBottomContent() {
    if (_channelVideos.isEmpty || _currentVideoIndex >= _channelVideos.length || _channel == null) {
      return const SizedBox.shrink();
    }
    
    final currentVideo = _channelVideos[_currentVideoIndex];
    final isExpanded = _expandedCaptions[_currentVideoIndex] ?? false;
    
    return Positioned(
      bottom: _bottomNavContentHeight + _progressBarHeight + MediaQuery.of(context).padding.bottom + 16, // Start from progress bar level
      left: 16,
      right: 80, // Leave space for right side interactions
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Channel name with follow button (TikTok style)
          Row(
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _channel!.name,
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
                    ),
                    // Verified badge if applicable
                    if (_channel!.isVerified)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Follow button with red fill when not following
              if (!_isOwner)
                GestureDetector(
                  onTap: _toggleFollow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isFollowing ? Colors.transparent : const Color(0xFFFF3040), // Red fill when not following
                      border: Border.all(color: Colors.white, width: 1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Caption with hashtags (exactly like channels feed screen)
          _buildSmartCaption(currentVideo, isExpanded),
        ],
      ),
    );
  }

  // Smart caption exactly like in channel_video_item.dart
  Widget _buildSmartCaption(ChannelVideoModel video, bool isExpanded) {
    if (video.caption.isEmpty) return const SizedBox.shrink();

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

    // Combine caption with hashtags on new line
    String fullText = video.caption;
    if (video.tags.isNotEmpty) {
      final hashtags = video.tags.map((tag) => '#$tag').join(' ');
      fullText += '\n$hashtags';
    }

    return GestureDetector(
      onTap: () => _toggleCaptionExpansion(_currentVideoIndex),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: isExpanded 
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

  // Progress bar widget for the bottom nav divider
  Widget _buildProgressBar(ModernThemeExtension modernTheme) {
    return ValueListenableBuilder<double>(
      valueListenable: _progressNotifier,
      builder: (context, progress, child) {
        return Container(
          height: _progressBarHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: MediaQuery.of(context).size.width * progress.clamp(0.0, 1.0),
                height: _progressBarHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      modernTheme.primaryColor ?? Colors.blue,
                      (modernTheme.primaryColor ?? Colors.blue).withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Bottom navigation bar widget - Updated with custom DM button
  Widget _buildBottomNavigationBar(ModernThemeExtension modernTheme) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalHeight = _bottomNavContentHeight + _progressBarHeight + bottomPadding;
    
    // Get current video for likes and comments count
    final videos = _channelVideos;
    final currentVideo = videos.isNotEmpty && _currentVideoIndex < videos.length 
        ? videos[_currentVideoIndex] 
        : null;
    
    return Container(
      height: totalHeight,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Column(
        children: [
          // Progress bar as divider
          _buildProgressBar(modernTheme),
          
          // Navigation content
          Container(
            height: _bottomNavContentHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: CupertinoIcons.gift_alt_fill,
                  activeIcon: CupertinoIcons.gift_fill,
                  label: 'Gift',
                  isActive: false,
                  onTap: () {
                    // TODO: Navigate to Gift screen when implemented
                  },
                  iconColor: Colors.white,
                  labelColor: Colors.white,
                ),
                _buildNavItem(
                  icon: Icons.download_rounded,
                  activeIcon: Icons.download,
                  label: 'Save',
                  isActive: false,
                  onTap: () {
                    // TODO: Implement save video to gallery functionality
                  },
                  iconColor: Colors.white,
                  labelColor: Colors.white,
                ),
                // Custom DM button (no label)
                _buildDMButton(),
                _buildNavItemWithBadge(
                  icon: currentVideo?.isLiked == true ? Icons.favorite : Icons.favorite,
                  activeIcon: Icons.favorite,
                  label: 'Likes',
                  isActive: false,
                  onTap: () => _likeCurrentVideo(currentVideo),
                  iconColor: currentVideo?.isLiked == true ? const Color(0xFFFF3040) : Colors.white,
                  labelColor: Colors.white,
                  badgeCount: currentVideo?.likes ?? 0,
                ),
                _buildNavItemWithBadge(
                  icon: CupertinoIcons.text_bubble_fill,
                  activeIcon: CupertinoIcons.text_bubble_fill,
                  label: 'Comments',
                  isActive: false,
                  onTap: () => _showCommentsForCurrentVideo(currentVideo),
                  iconColor: Colors.white,
                  labelColor: Colors.white,
                  badgeCount: currentVideo?.comments ?? 0,
                ),
              ],
            ),
          ),
          
          // System navigation bar space
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  // Custom DM button similar to the post button in home screen
  Widget _buildDMButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to DM screen when implemented
      },
      child: Container(
        width: 45,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade500,
              Colors.cyan.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'DM',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: iconColor ?? (isActive ? Colors.white : Colors.white.withOpacity(0.6)),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: labelColor ?? (isActive ? Colors.white : Colors.white.withOpacity(0.6)),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
    required int badgeCount,
  }) {
    final modernTheme = context.modernTheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: iconColor ?? (isActive ? Colors.white : Colors.white.withOpacity(0.6)),
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor ?? Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _formatCount(badgeCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: labelColor ?? (isActive ? Colors.white : Colors.white.withOpacity(0.6)),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined, color: Colors.white, size: 80),
          const SizedBox(height: 24),
          const Text(
            'No Videos Yet',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _isOwner 
                ? 'Create your first video to share with your followers'
                : 'This channel hasn\'t posted any videos yet',
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (_isOwner) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Constants.createChannelPostScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0050),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Video'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Error Loading Content',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _channelError!,
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleBackNavigation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0050),
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  void _likeCurrentVideo(ChannelVideoModel? video) {
    if (video != null) {
      ref.read(channelVideosProvider.notifier).likeVideo(video.id);
    }
  }

  void _showCommentsForCurrentVideo(ChannelVideoModel? video) {
    if (video != null) {
      // Pause current video and disable wakelock when showing comments
      _pauseCurrentVideo();
      
      // Show comments bottom sheet and handle completion
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        useSafeArea: true,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: CommentsBottomSheet(videoId: video.id),
        ),
      ).whenComplete(() {
        // Resume video and re-enable wakelock when comments are closed
        if (_isScreenActive && _isAppInForeground) {
          _playCurrentVideo();
        }
      });
    }
  }

  void _navigateToCreatePost() async {
    // Pause current video and disable wakelock
    _pauseCurrentVideo();
    
    final result = await Navigator.pushNamed(context, Constants.createChannelPostScreen);
    if (result == true) {
      // Reload channel videos
      await _loadChannelData();
      
      // Reset progress and restart playback
      setState(() {
        _currentProgress = 0.0;
      });
      _progressNotifier.value = 0.0;
      _progressTimer?.cancel();
      _imageProgressController.reset();
      
      if (_channelVideos.isNotEmpty && _isScreenActive && _isAppInForeground) {
        _imageProgressController.forward();
        _playCurrentVideo(); // This will handle wakelock
      }
    } else {
      // Resume video if user cancelled (this will re-enable wakelock)
      if (_isScreenActive && _isAppInForeground) {
        _playCurrentVideo();
      }
    }
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}