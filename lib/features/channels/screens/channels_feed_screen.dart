// lib/features/channels/screens/channels_feed_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/widgets/channel_video_item.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/services/video_cache_service.dart';
import 'package:textgb/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ChannelsFeedScreen extends ConsumerStatefulWidget {
  const ChannelsFeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChannelsFeedScreen> createState() => _ChannelsFeedScreenState();
}

class _ChannelsFeedScreenState extends ConsumerState<ChannelsFeedScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  
  // Core controllers
  final PageController _pageController = PageController();
  late AnimationController _progressController;
  
  // Cache service
  final VideoCacheService _cacheService = VideoCacheService();
  
  // State management
  bool _isFirstLoad = true;
  int _currentVideoIndex = 0;
  bool _isScreenActive = true;
  bool _isAppInForeground = true;
  bool _hasInitialized = false;
  
  // Enhanced progress tracking
  double _videoProgress = 0.0;
  Duration _videoDuration = Duration.zero;
  Duration _videoPosition = Duration.zero;
  VideoPlayerController? _currentVideoController;
  Timer? _progressUpdateTimer;
  Timer? _cacheCleanupTimer;
  
  // Simple notifier for home screen progress bar
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
    _setupSystemUI();
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
        if (_isScreenActive) {
          _resumePlayback();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isAppInForeground = false;
        _pauseAllPlayback();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void onScreenBecameActive() {
    if (!_hasInitialized) return;
    
    debugPrint('ChannelsFeedScreen: Screen became active');
    _isScreenActive = true;
    
    if (_isAppInForeground) {
      _resumePlayback();
      _startIntelligentPreloading();
      WakelockPlus.enable();
    }
  }

  void onScreenBecameInactive() {
    if (!_hasInitialized) return;
    
    debugPrint('ChannelsFeedScreen: Screen became inactive');
    _isScreenActive = false;
    _pauseAllPlayback();
    WakelockPlus.disable();
  }

  void _resumePlayback() {
    if (!mounted || !_isScreenActive || !_isAppInForeground) return;
    
    debugPrint('ChannelsFeedScreen: Resuming playback');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.seekTo(Duration.zero);
      _currentVideoController!.play();
    }
    
    _setupVideoProgressTracking();
    _startIntelligentPreloading();
    
    WakelockPlus.enable();
  }

  void _pauseAllPlayback() {
    debugPrint('ChannelsFeedScreen: Pausing all playback');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.pause();
    }
    
    _progressUpdateTimer?.cancel();
  }

  void _initializeControllers() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    
    _progressController.addListener(_onProgressControllerUpdate);
  }

  void _onProgressControllerUpdate() {
    if (!mounted) return;
    
    // Update progress for images or fallback
    if (_currentVideoController == null || !_currentVideoController!.value.isInitialized) {
      setState(() {
        _videoProgress = _progressController.value;
      });
      // Simple update for home screen - no other changes
      _progressNotifier.value = _progressController.value;
    }
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
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
        
        _progressController.forward();
        
        if (_isScreenActive && _isAppInForeground) {
          Timer(const Duration(milliseconds: 500), () {
            if (mounted && _isScreenActive && _isAppInForeground) {
              _startIntelligentPreloading();
            }
          });
        }
      }
    }
  }

  void _setupVideoProgressTracking() {
    if (!_isScreenActive || !_isAppInForeground) return;
    
    _progressUpdateTimer?.cancel();
    
    _progressUpdateTimer = Timer.periodic(_progressUpdateInterval, (timer) {
      if (!mounted || !_isScreenActive || !_isAppInForeground) {
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
            
            // Simple update for home screen - no other changes
            _progressNotifier.value = progress;
            
            debugPrint('Video Progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
          
          // Trigger next batch preloading when halfway through
          if (progress > 0.5 && _isScreenActive && _isAppInForeground) {
            _preloadNextBatch();
          }
        }
      } else {
        // For images or when video is not ready, use animation controller
        if (mounted) {
          setState(() {
            _videoProgress = _progressController.value;
          });
          // Simple update for home screen - no other changes
          _progressNotifier.value = _progressController.value;
        }
      }
    });
  }

  void _startIntelligentPreloading() {
    if (!_isScreenActive || !_isAppInForeground) return;
    
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
    if (!mounted || !_isScreenActive || !_isAppInForeground) return;
    
    debugPrint('Video controller ready, setting up progress tracking');
    
    setState(() {
      _currentVideoController = controller;
      _videoProgress = 0.0;
    });
    
    controller.seekTo(Duration.zero);
    _setupVideoProgressTracking();
    
    if (_progressController.isAnimating) {
      _progressController.stop();
      _progressController.reset();
    }
    
    WakelockPlus.enable();
    
    if (_isScreenActive && _isAppInForeground) {
      _startIntelligentPreloading();
    }
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
    });

    // Simple update for home screen - no other changes
    _progressNotifier.value = 0.0;

    _progressUpdateTimer?.cancel();
    _progressController.reset();
    
    // Handle different content types
    if (videos[index].isMultipleImages || videos[index].videoUrl.isEmpty) {
      _progressController.forward();
      debugPrint('Starting image progress animation');
    } else {
      debugPrint('Waiting for video to initialize for progress tracking');
    }

    if (_isScreenActive && _isAppInForeground) {
      _startIntelligentPreloading();
      WakelockPlus.enable();
    }
    
    ref.read(channelVideosProvider.notifier).incrementViewCount(videos[index].id);
  }

  // Public method to build progress bar (for home screen access)
  Widget buildEnhancedProgressBar(ModernThemeExtension modernTheme) {
    return ValueListenableBuilder<double>(
      valueListenable: _progressNotifier,
      builder: (context, progress, child) {
        // Always show progress bar when there's any progress or during initial load
        if (progress == 0.0 && !_isFirstLoad) return const SizedBox.shrink();
        
        return Container(
          height: 2, // Reduced from 3px to 2px
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white.withOpacity(0.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                // Background track
                Container(
                  width: double.infinity,
                  height: 2, // Reduced from 3px to 2px
                  color: Colors.transparent,
                ),
                // Progress fill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: (MediaQuery.of(context).size.width - 32) * progress.clamp(0.0, 1.0),
                  height: 1, // Reduced from 2px to 1px
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        modernTheme.primaryColor ?? Colors.blue,
                        (modernTheme.primaryColor ?? Colors.blue).withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: (modernTheme.primaryColor ?? Colors.blue).withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    debugPrint('ChannelsFeedScreen: Disposing');
    
    WidgetsBinding.instance.removeObserver(this);
    
    _progressUpdateTimer?.cancel();
    _cacheCleanupTimer?.cancel();
    
    _progressController.dispose();
    _pageController.dispose();
    
    // Clean up the simple notifier
    _progressNotifier.dispose();
    
    _pauseAllPlayback();
    _cacheService.dispose();
    
    WakelockPlus.disable();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final channelVideosState = ref.watch(channelVideosProvider);
    final channelsState = ref.watch(channelsProvider);
    final modernTheme = context.modernTheme;
    
    final bottomNavHeight = 100.0;
    
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
          _buildBody(channelVideosState, channelsState, modernTheme, bottomNavHeight),
          
          // Cache performance indicator (debug mode only)
          if (kDebugMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              child: _buildCacheDebugInfo(modernTheme),
            ),
          
          if (!_isScreenActive)
            _buildInactiveOverlay(modernTheme),
        ],
      ),
      // FAB removed - no longer shows floating action button
    );
  }

  Widget _buildBody(ChannelVideosState videosState, ChannelsState channelsState, 
                    ModernThemeExtension modernTheme, double bottomPadding) {
    
    if (!videosState.isLoading && channelsState.userChannel == null) {
      return _buildCreateChannelPrompt(modernTheme);
    }

    if (!videosState.isLoading && videosState.videos.isEmpty) {
      return _buildEmptyState(channelsState, modernTheme);
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: videosState.videos.length,
        onPageChanged: _onPageChanged,
        physics: _isScreenActive ? null : const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final video = videosState.videos[index];
          
          return ChannelVideoItem(
            video: video,
            isActive: index == _currentVideoIndex && _isScreenActive && _isAppInForeground,
            onVideoControllerReady: _onVideoControllerReady,
          );
        },
      ),
    );
  }

  Widget _buildCacheDebugInfo(ModernThemeExtension modernTheme) {
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

  Widget _buildInactiveOverlay(ModernThemeExtension modernTheme) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pause_circle_filled,
              color: modernTheme.primaryColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Video Paused',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateChannelPrompt(ModernThemeExtension modernTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library,
            color: modernTheme.primaryColor,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'Create your Channel',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToCreateChannel,
            icon: const Icon(Icons.add),
            label: const Text('Create Channel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: modernTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ChannelsState channelsState, ModernThemeExtension modernTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            color: modernTheme.primaryColor,
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'No Videos Yet',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          if (channelsState.userChannel != null)
            ElevatedButton.icon(
              onPressed: _navigateToCreatePost,
              icon: const Icon(Icons.add),
              label: const Text('Create Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToCreateChannel() async {
    final result = await Navigator.pushNamed(context, Constants.createChannelScreen);
    if (result == true) {
      ref.read(channelsProvider.notifier).loadUserChannel();
    }
  }

  void _navigateToCreatePost() async {
    final result = await Navigator.pushNamed(context, Constants.createChannelPostScreen);
    if (result == true) {
      _pauseAllPlayback();
      
      ref.read(channelVideosProvider.notifier).loadVideos(forceRefresh: true);
      
      setState(() {
        _videoProgress = 0.0;
        _videoPosition = Duration.zero;
        _videoDuration = Duration.zero;
      });
      _progressUpdateTimer?.cancel();
      _progressController.reset();
      if (_isScreenActive && _isAppInForeground) {
        _progressController.forward();
      }
    }
  }
}

// Extension for tab management
extension ChannelsFeedScreenExtension on _ChannelsFeedScreenState {
  static void handleTabChanged(GlobalKey<_ChannelsFeedScreenState> feedScreenKey, bool isActive) {
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
  final GlobalKey<_ChannelsFeedScreenState> _key;
  
  ChannelsFeedController(this._key);
  
  void setActive(bool isActive) {
    ChannelsFeedScreenExtension.handleTabChanged(_key, isActive);
  }
  
  void pause() => setActive(false);
  void resume() => setActive(true);
}