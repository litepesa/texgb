// lib/features/channels/screens/channels_feed_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/widgets/channel_video_item.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/services/video_cache_service.dart';
import 'package:textgb/features/channels/widgets/comments_bottom_sheet.dart';
import 'package:textgb/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ChannelsFeedScreen extends ConsumerStatefulWidget {
  final Function(double)? onVideoProgressChanged;
  final String? startVideoId; // For direct video navigation
  final String? channelId; // For channel-specific filtering (optional)

  const ChannelsFeedScreen({
    Key? key,
    this.onVideoProgressChanged,
    this.startVideoId,
    this.channelId,
  }) : super(key: key);

  @override
  ConsumerState<ChannelsFeedScreen> createState() => ChannelsFeedScreenState();
}

class ChannelsFeedScreenState extends ConsumerState<ChannelsFeedScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver, RouteAware {
  
  // Core controllers
  final PageController _pageController = PageController();
  late AnimationController _progressController;
  late AnimationController _musicDiscController; // Add music disc animation controller
  
  // Cache service
  final VideoCacheService _cacheService = VideoCacheService();
  
  // State management
  bool _isFirstLoad = true;
  int _currentVideoIndex = 0;
  bool _isScreenActive = true;
  bool _isAppInForeground = true;
  bool _hasInitialized = false;
  String _selectedFeedType = 'For You'; // Track selected feed type
  bool _isNavigatingAway = false; // Track navigation state
  bool _isManuallyPaused = false; // Track if user manually paused the video
  
  // Enhanced progress tracking
  double _videoProgress = 0.0;
  Duration _videoDuration = Duration.zero;
  Duration _videoPosition = Duration.zero;
  VideoPlayerController? _currentVideoController;
  Timer? _progressUpdateTimer;
  Timer? _cacheCleanupTimer;
  
  // Simple notifier for progress tracking
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  
  static const Duration _progressUpdateInterval = Duration(milliseconds: 200);
  static const Duration _cacheCleanupInterval = Duration(minutes: 10);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _loadVideos();
    _setupCacheCleanup();
    _hasInitialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        if (_isScreenActive && !_isNavigatingAway) {
          _startFreshPlayback();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        _stopPlayback();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void onScreenBecameActive() {
    if (!_hasInitialized) return;
    
    debugPrint('ChannelsFeedScreen: Screen became active');
    _isScreenActive = true;
    _isNavigatingAway = false; // Reset navigation state
    
    if (_isAppInForeground && !_isManuallyPaused) {
      _startFreshPlayback();
      _startIntelligentPreloading();
      WakelockPlus.enable();
    }
  }

  void onScreenBecameInactive() {
    if (!_hasInitialized) return;
    
    debugPrint('ChannelsFeedScreen: Screen became inactive');
    _isScreenActive = false;
    _stopPlayback();
    WakelockPlus.disable();
  }

  // New method to handle navigation away from feed
  void _pauseForNavigation() {
    debugPrint('ChannelsFeedScreen: Pausing for navigation');
    _isNavigatingAway = true;
    _stopPlayback();
  }

  // New method to handle returning from navigation
  void _resumeFromNavigation() {
    debugPrint('ChannelsFeedScreen: Resuming from navigation');
    _isNavigatingAway = false;
    if (_isScreenActive && _isAppInForeground && !_isManuallyPaused) {
      // Add a small delay to ensure the screen is fully visible before starting playback
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_isNavigatingAway && _isScreenActive && _isAppInForeground && !_isManuallyPaused) {
          _startFreshPlayback();
        }
      });
    }
  }

  void _startFreshPlayback() {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isManuallyPaused) return;
    
    debugPrint('ChannelsFeedScreen: Starting fresh playback');
    
    // Only seek to beginning for truly fresh starts (new videos or screen activation)
    // Don't seek when resuming from manual pause
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
      debugPrint('ChannelsFeedScreen: Video controller playing');
    } else {
      // If video controller isn't ready, trigger a re-initialization
      debugPrint('ChannelsFeedScreen: Video controller not ready, attempting initialization');
      final videos = ref.read(channelVideosProvider).videos;
      if (videos.isNotEmpty && _currentVideoIndex < videos.length) {
        // This will trigger the video item to reinitialize if needed
        setState(() {});
      }
    }
    
    _setupVideoProgressTracking();
    _startIntelligentPreloading();
    
    // Start music disc animation only if controller is initialized
    if (_musicDiscController.isAnimating != true) {
      _musicDiscController.repeat();
    }
    
    WakelockPlus.enable();
  }

  void _stopPlayback() {
    debugPrint('ChannelsFeedScreen: Stopping playback');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.pause();
      // Seek to beginning for fresh start next time
      _currentVideoController!.seekTo(Duration.zero);
    }
    
    // Stop music disc animation safely
    if (_musicDiscController.isAnimating) {
      _musicDiscController.stop();
    }
    
    _progressUpdateTimer?.cancel();
    
    // Reset progress for fresh start
    _updateProgress(0.0);
  }

  void _initializeControllers() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    
    // Initialize music disc rotation controller
    _musicDiscController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // Slow, hypnotic rotation
    );
    
    _progressController.addListener(_onProgressControllerUpdate);
  }

  void _onProgressControllerUpdate() {
    if (!mounted) return;
    
    // Update progress for images or fallback
    if (_currentVideoController == null || !_currentVideoController!.value.isInitialized) {
      final progress = _progressController.value;
      setState(() {
        _videoProgress = progress;
      });
      _progressNotifier.value = progress;
      _updateProgress(progress);
    }
  }

  void _updateProgress(double progress) {
    // Call the callback to update the home screen progress indicator
    if (widget.onVideoProgressChanged != null && _isScreenActive && !_isNavigatingAway) {
      widget.onVideoProgressChanged!(progress);
    }
  }

  void _setupSystemUI() {
    // Always black background with light status bar for TikTok-style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  void _setupCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(_cacheCleanupInterval, (timer) {
      _cacheService.cleanupOldCache();
    });
  }

  Future<void> _loadVideos() async {
    if (_isFirstLoad) {
      debugPrint('ChannelsFeedScreen: Loading initial videos');
      await ref.read(channelVideosProvider.notifier).loadVideos();
      
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
        
        // If a specific video ID was provided, jump to it
        if (widget.startVideoId != null) {
          _jumpToVideo(widget.startVideoId!);
        }
        
        _progressController.forward();
        
        if (_isScreenActive && _isAppInForeground && !_isNavigatingAway) {
          Timer(const Duration(milliseconds: 500), () {
            if (mounted && _isScreenActive && _isAppInForeground && !_isNavigatingAway) {
              _startIntelligentPreloading();
            }
          });
        }
      }
    }
  }

  // Add this method to jump to a specific video
  void _jumpToVideo(String videoId) {
    final videos = ref.read(channelVideosProvider).videos;
    final videoIndex = videos.indexWhere((video) => video.id == videoId);
    
    if (videoIndex != -1) {
      debugPrint('ChannelsFeedScreen: Jumping to video at index $videoIndex');
      
      // Use a delay to ensure the PageView is ready and videos are loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(videoIndex);
          
          // Update the current video index
          setState(() {
            _currentVideoIndex = videoIndex;
          });
          
          debugPrint('ChannelsFeedScreen: Successfully jumped to video $videoId at index $videoIndex');
        }
      });
    } else {
      debugPrint('ChannelsFeedScreen: Video with ID $videoId not found in list');
    }
  }

  void _setupVideoProgressTracking() {
    if (!_isScreenActive || !_isAppInForeground || _isNavigatingAway) return;
    
    _progressUpdateTimer?.cancel();
    
    _progressUpdateTimer = Timer.periodic(_progressUpdateInterval, (timer) {
      if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway) {
        timer.cancel();
        return;
      }
      
      if (_currentVideoController?.value.isInitialized == true) {
        final controller = _currentVideoController!;
        final position = controller.value.position;
        final duration = controller.value.duration;
        
        if (duration.inMilliseconds > 0) {
          final progress = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
          
          if (mounted) {
            setState(() {
              _videoPosition = position;
              _videoDuration = duration;
              _videoProgress = progress;
            });
            
            _progressNotifier.value = progress;
            _updateProgress(progress);
          }
          
          // Trigger next batch preloading when halfway through
          if (progress > 0.5 && _isScreenActive && _isAppInForeground && !_isNavigatingAway) {
            _preloadNextBatch();
          }
        }
      } else {
        // For images or when video is not ready, use animation controller
        if (mounted) {
          final progress = _progressController.value;
          setState(() {
            _videoProgress = progress;
          });
          _progressNotifier.value = progress;
          _updateProgress(progress);
        }
      }
    });
  }

  void _startIntelligentPreloading() {
    if (!_isScreenActive || !_isAppInForeground || _isNavigatingAway) return;
    
    final videos = ref.read(channelVideosProvider).videos;
    if (videos.isEmpty) return;
    
    debugPrint('Starting intelligent preloading for index: $_currentVideoIndex');
    _cacheService.preloadVideosIntelligently(videos, _currentVideoIndex);
  }

  void _preloadNextBatch() {
    final videos = ref.read(channelVideosProvider).videos;
    if (videos.isEmpty) return;
    
    _cacheService.preloadNextBatch(videos, _currentVideoIndex);
  }

  void _onVideoControllerReady(VideoPlayerController controller) {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway) return;
    
    debugPrint('Video controller ready, setting up fresh playback');
    
    setState(() {
      _currentVideoController = controller;
      _videoProgress = 0.0;
    });

    // Always start fresh from the beginning for NEW videos
    controller.seekTo(Duration.zero);
    _setupVideoProgressTracking();
    
    if (_progressController.isAnimating) {
      _progressController.stop();
      _progressController.reset();
    }
    
    WakelockPlus.enable();
    
    if (_isScreenActive && _isAppInForeground && !_isNavigatingAway && !_isManuallyPaused) {
      _startIntelligentPreloading();
    }
  }

  // Separate method for starting fresh video (seeks to beginning)
  void _startFreshVideo() {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isManuallyPaused) return;
    
    debugPrint('ChannelsFeedScreen: Starting fresh video from beginning');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.seekTo(Duration.zero);
      _currentVideoController!.play();
    }
    
    _startFreshPlayback();
  }

  // Method to handle manual play/pause from video item
  void onManualPlayPause(bool isPlaying) {
    debugPrint('ChannelsFeedScreen: Manual play/pause - isPlaying: $isPlaying');
    setState(() {
      _isManuallyPaused = !isPlaying;
    });
  }

  void _onPageChanged(int index) {
    final videos = ref.read(channelVideosProvider).videos;
    if (index >= videos.length || !_isScreenActive) return;

    debugPrint('Page changed to: $index');

    setState(() {
      _currentVideoIndex = index;
      _currentVideoController = null;
      _videoProgress = 0.0;
      _videoPosition = Duration.zero;
      _videoDuration = Duration.zero;
      _isManuallyPaused = false; // Reset manual pause state for new video
    });

    _progressNotifier.value = 0.0;
    _updateProgress(0.0);

    _progressUpdateTimer?.cancel();
    _progressController.reset();
    
    // Handle different content types
    if (videos[index].isMultipleImages || videos[index].videoUrl.isEmpty) {
      _progressController.forward();
      debugPrint('Starting image progress animation');
    } else {
      debugPrint('Waiting for video to initialize for progress tracking');
    }

    if (_isScreenActive && _isAppInForeground && !_isNavigatingAway && !_isManuallyPaused) {
      _startIntelligentPreloading();
      // Restart music disc animation for new video - check if controller is ready
      if (!_musicDiscController.isAnimating) {
        _musicDiscController.repeat();
      }
      WakelockPlus.enable();
    }
    
    ref.read(channelVideosProvider.notifier).incrementViewCount(videos[index].id);
  }

  @override
  void dispose() {
    debugPrint('ChannelsFeedScreen: Disposing');
    
    WidgetsBinding.instance.removeObserver(this);
    
    _progressUpdateTimer?.cancel();
    _cacheCleanupTimer?.cancel();
    
    _progressController.dispose();
    _musicDiscController.dispose(); // Dispose music disc controller
    _pageController.dispose();
    _progressNotifier.dispose();
    
    _stopPlayback();
    _cacheService.dispose();
    
    WakelockPlus.disable();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Setup system UI for current theme
    _setupSystemUI();
    
    final channelVideosState = ref.watch(channelVideosProvider);
    final channelsState = ref.watch(channelsProvider);
    
    if (_isFirstLoad && channelVideosState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.shrink(),
      );
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content - full screen
          Positioned.fill(
            child: _buildBody(channelVideosState, channelsState),
          ),
          
          // Clean top floating icons - only menu and search
          _buildTopFloatingIcons(),
          
          // TikTok-style right side menu
          _buildRightSideMenu(),
          
          // Cache performance indicator (debug mode only)
          if (kDebugMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              child: _buildCacheDebugInfo(),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ChannelVideosState videosState, ChannelsState channelsState) {
    
    if (!videosState.isLoading && channelsState.userChannel == null) {
      return _buildCreateChannelPrompt();
    }

    if (!videosState.isLoading && videosState.videos.isEmpty) {
      return _buildEmptyState(channelsState);
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: videosState.videos.length,
      onPageChanged: _onPageChanged,
      physics: _isScreenActive ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final video = videosState.videos[index];
        
        return ChannelVideoItem(
          video: video,
          isActive: index == _currentVideoIndex && _isScreenActive && _isAppInForeground && !_isNavigatingAway,
          onVideoControllerReady: _onVideoControllerReady,
          onManualPlayPause: onManualPlayPause,
        );
      },
    );
  }

  // Clean top floating icons - only three dot menu and search
  Widget _buildTopFloatingIcons() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Three dot menu on the left (vertical)
          GestureDetector(
            onTap: _showFeedOptionsMenu,
            child: const Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 26,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          
          // Search icon on the right
          GestureDetector(
            onTap: () {
              // TODO: Navigate to search screen
            },
            child: const Icon(
              CupertinoIcons.search,
              color: Colors.white,
              size: 26,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show feed options menu with the previous options
  void _showFeedOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            const Text(
              'Feed Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            
            // Feed type options
            _buildFeedOption('Today', 'Today'),
            const SizedBox(height: 12),
            _buildFeedOption('Following', 'Following'),
            const SizedBox(height: 12),
            _buildFeedOption('For You', 'For You'),
            
            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            const SizedBox(height: 12),
            
            // Additional options
            _buildMenuOption(Icons.settings, 'Settings', () {
              Navigator.pop(context);
              // TODO: Navigate to settings
            }),
            const SizedBox(height: 12),
            _buildMenuOption(Icons.help_outline, 'Help & Support', () {
              Navigator.pop(context);
              // TODO: Navigate to help
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedOption(String title, String value) {
    final isSelected = _selectedFeedType == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFeedType = value;
        });
        Navigator.pop(context);
        // TODO: Filter feed based on selected type
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue, width: 1) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.blue : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? Colors.blue : Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TikTok-style right side menu (Douyin icons)
  Widget _buildRightSideMenu() {
    final videos = ref.watch(channelVideosProvider).videos;
    final currentVideo = videos.isNotEmpty && _currentVideoIndex < videos.length 
        ? videos[_currentVideoIndex] 
        : null;

    return Positioned(
      right: 4, // Much closer to edge
      bottom: 120, // Above bottom nav
      child: Column(
        children: [
          // Profile avatar with red ring
          _buildRightMenuItem(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: CircleAvatar(
                backgroundImage: currentVideo?.channelImage.isNotEmpty == true
                    ? NetworkImage(currentVideo!.channelImage)
                    : null,
                backgroundColor: Colors.grey,
                child: currentVideo?.channelImage.isEmpty == true
                    ? Text(
                        currentVideo?.channelName.isNotEmpty == true
                            ? currentVideo!.channelName[0].toUpperCase()
                            : "U",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
            ),
            onTap: () => _navigateToChannelProfile(),
          ),
          
          const SizedBox(height: 10),
          
          // Like button
          _buildRightMenuItem(
            child: Icon(
              currentVideo?.isLiked == true ? Icons.favorite : Icons.favorite_border,
              color: currentVideo?.isLiked == true ? Colors.red : Colors.white,
              size: 26,
            ),
            label: _formatCount(currentVideo?.likes ?? 0),
            onTap: () => _likeCurrentVideo(currentVideo),
          ),
          
          const SizedBox(height: 10),
          
          // Comment button
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.chat_bubble,
              color: Colors.white,
              size: 26,
            ),
            label: _formatCount(currentVideo?.comments ?? 0),
            onTap: () => _showCommentsForCurrentVideo(currentVideo),
          ),
          
          const SizedBox(height: 10),
          
          // Share button
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.paperplane,
              color: Colors.white,
              size: 26,
            ),
            label: 'Share',
            onTap: () => _showShareOptions(),
          ),
          
          const SizedBox(height: 10),
          
          // More button (three dots horizontal)
          _buildRightMenuItem(
            child: const Icon(
              Icons.more_horiz,
              color: Colors.white,
              size: 26,
            ),
            onTap: () => _showVideoOptionsMenu(),
          ),
          
          const SizedBox(height: 16),
          
          // Music disc (rotating)
          _buildMusicDisc(),
        ],
      ),
    );
  }

  Widget _buildRightMenuItem({
    required Widget child,
    String? label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4), // Reduced padding
            child: child,
          ),
          if (label != null) ...[
            const SizedBox(height: 2), // Reduced spacing
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11, // Slightly smaller text
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMusicDisc() {
    return AnimatedBuilder(
      animation: _musicDiscController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _musicDiscController.value * 2 * 3.14159, // Full rotation
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              // Add animated ring border like TikTok
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer rotating ring (dotted pattern like TikTok)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 1,
                    ),
                  ),
                ),
                // Inner disc with music note
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade400,
                        Colors.grey.shade700,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCacheDebugInfo() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _cacheService.getCacheStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final stats = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cache: ${stats['fileCount']} files (${stats['totalSizeMB']}MB)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
              Text(
                'Queue: ${stats['queueLength']} | Loading: ${stats['preloadingCount']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
              Text(
                'Progress: ${(_videoProgress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateChannelPrompt() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library,
            color: Colors.white,
            size: 80,
          ),
          SizedBox(height: 24),
          Text(
            'Create your Channel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 32),
          // Add create channel button here
        ],
      ),
    );
  }

  Widget _buildEmptyState(ChannelsState channelsState) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            color: Colors.white,
            size: 80,
          ),
          SizedBox(height: 24),
          Text(
            'No Videos Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Add create post button here
        ],
      ),
    );
  }

  void _navigateToChannelProfile() async {
    final videos = ref.read(channelVideosProvider).videos;
    if (_currentVideoIndex < videos.length) {
      // Pause video before navigation
      _pauseForNavigation();
      
      final result = await Navigator.of(context).pushNamed(
        Constants.channelProfileScreen,
        arguments: videos[_currentVideoIndex].channelId,
      );
      
      // Resume video after returning from navigation
      _resumeFromNavigation();
    }
  }

  void _likeCurrentVideo(ChannelVideoModel? video) {
    if (video != null) {
      ref.read(channelVideosProvider.notifier).likeVideo(video.id);
    }
  }

  void _showCommentsForCurrentVideo(ChannelVideoModel? video) {
    if (video != null) {
      showCommentsBottomSheet(context, video.id);
    }
  }

  void _showVideoOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Video Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(Icons.report_outlined, 'Report', () {
              Navigator.pop(context);
            }),
            const SizedBox(height: 16),
            _buildMenuOption(Icons.block, 'Not Interested', () {
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
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
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share Video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.copy, 'Copy Link'),
                _buildShareOption(Icons.message, 'Message'),
                _buildShareOption(Icons.more_horiz, 'More'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}

// Extension for tab management 
extension ChannelsFeedScreenExtension on ChannelsFeedScreenState {
  static void handleTabChanged(GlobalKey<ChannelsFeedScreenState> feedScreenKey, bool isActive) {
    final state = feedScreenKey.currentState;
    if (state != null) {
      if (isActive) {
        state.onScreenBecameActive();
      } else {
        state.onScreenBecameInactive();
      }
    }
  }
}

class ChannelsFeedController {
  final GlobalKey<ChannelsFeedScreenState> _key;
  
  ChannelsFeedController(this._key);
  
  void setActive(bool isActive) {
    ChannelsFeedScreenExtension.handleTabChanged(_key, isActive);
  }
  
  void pause() => setActive(false);
  void resume() => setActive(true);
}