// lib/features/channels/screens/channels_feed_screen.dart
// Ultra-clean TikTok-like feed with no search bar and minimal UI

import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/widgets/channel_video_item.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
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
  
  // Aggressive preloading system for seamless scrolling
  final Map<int, VideoPlayerController> _preloadedControllers = {};
  final Map<int, bool> _preloadingInProgress = {};
  final Set<int> _readyControllers = {};
  final Queue<int> _videoPreloadQueue = Queue<int>();
  bool _isProcessingQueue = false;
  
  // Enhanced configuration for TikTok-like experience
  static const int _maxPreloadedVideos = 5;
  static const int _maxConcurrentPreloads = 4;
  static const Duration _progressUpdateInterval = Duration(milliseconds: 100);
  static const Duration _preloadDelay = Duration(milliseconds: 200);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _setupSystemUI();
    _loadVideos();
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

  // Screen lifecycle management
  void onScreenBecameActive() {
    if (!_hasInitialized) return;
    
    debugPrint('ChannelsFeedScreen: Screen became active');
    _isScreenActive = true;
    
    if (_isAppInForeground) {
      _resumePlayback();
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
    
    debugPrint('ChannelsFeedScreen: Resuming playback - fresh start');
    
    // Always start fresh when resuming - like TikTok
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.seekTo(Duration.zero);
      _currentVideoController!.play();
    }
    
    _setupVideoProgressTracking();
    _startPreloadingSystem();
    
    // Keep screen awake during video playback
    WakelockPlus.enable();
  }

  void _pauseAllPlayback() {
    debugPrint('ChannelsFeedScreen: Pausing all playback');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.pause();
    }
    
    for (final controller in _preloadedControllers.values) {
      if (controller.value.isInitialized) {
        controller.pause();
      }
    }
    
    _progressUpdateTimer?.cancel();
    _isProcessingQueue = false;
    _videoPreloadQueue.clear();
  }

  void _initializeControllers() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    
    _progressController.addListener(_onProgressControllerUpdate);
  }

  void _onProgressControllerUpdate() {
    if (_currentVideoController == null || !_currentVideoController!.value.isInitialized) {
      if (mounted) {
        setState(() {
          _videoProgress = _progressController.value;
        });
      }
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

  Future<void> _loadVideos() async {
    if (_isFirstLoad) {
      debugPrint('ChannelsFeedScreen: Loading initial videos');
      await ref.read(channelVideosProvider.notifier).loadVideos();
      
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
        
        _progressController.forward();
        
        // Start aggressive preloading immediately
        if (_isScreenActive && _isAppInForeground) {
          Timer(_preloadDelay, () {
            if (mounted && _isScreenActive && _isAppInForeground) {
              _startPreloadingSystem();
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
          }
          
          // Preload next videos aggressively
          if (progress > 0.6 && _isScreenActive && _isAppInForeground) {
            _preloadNextVideos();
          }
        }
      }
    });
  }

  // Aggressive preloading system for seamless experience
  void _startPreloadingSystem() {
    if (!_isScreenActive || !_isAppInForeground) return;
    _preloadNextVideos();
  }

  void _preloadNextVideos() {
    if (!_isScreenActive || !_isAppInForeground) return;
    
    final videos = ref.read(channelVideosProvider).videos;
    if (videos.isEmpty) return;
    
    // Preload both forward and backward for smooth scrolling
    for (int i = 1; i <= _maxPreloadedVideos; i++) {
      final nextIndex = _currentVideoIndex + i;
      final prevIndex = _currentVideoIndex - i;
      
      // Preload next videos
      if (nextIndex < videos.length && 
          !_preloadedControllers.containsKey(nextIndex) && 
          !_preloadingInProgress.containsKey(nextIndex) &&
          !videos[nextIndex].isMultipleImages &&
          videos[nextIndex].videoUrl.isNotEmpty) {
        _videoPreloadQueue.add(nextIndex);
      }
      
      // Preload previous videos for backward scrolling
      if (prevIndex >= 0 && 
          !_preloadedControllers.containsKey(prevIndex) && 
          !_preloadingInProgress.containsKey(prevIndex) &&
          !videos[prevIndex].isMultipleImages &&
          videos[prevIndex].videoUrl.isNotEmpty) {
        _videoPreloadQueue.add(prevIndex);
      }
    }
    
    _processPreloadQueue();
  }

  void _processPreloadQueue() async {
    if (_isProcessingQueue || 
        _videoPreloadQueue.isEmpty || 
        !_isScreenActive || 
        !_isAppInForeground) return;
    
    _isProcessingQueue = true;
    final videos = ref.read(channelVideosProvider).videos;
    
    final List<Future<void>> preloadTasks = [];
    int processed = 0;
    
    while (_videoPreloadQueue.isNotEmpty && 
           processed < _maxConcurrentPreloads &&
           _isScreenActive &&
           _isAppInForeground) {
      
      final index = _videoPreloadQueue.removeFirst();
      
      if (index >= videos.length || 
          _preloadedControllers.containsKey(index) || 
          _preloadingInProgress.containsKey(index)) {
        continue;
      }
      
      _preloadingInProgress[index] = true;
      processed++;
      
      preloadTasks.add(_preloadVideo(index, videos[index]));
    }
    
    await Future.wait(preloadTasks);
    _isProcessingQueue = false;
  }

  Future<void> _preloadVideo(int index, ChannelVideoModel video) async {
    if (!_isScreenActive || !_isAppInForeground) {
      _preloadingInProgress.remove(index);
      return;
    }
    
    try {
      final controller = VideoPlayerController.network(
        video.videoUrl,
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: false,
        ),
      );

      await controller.initialize().timeout(
        const Duration(seconds: 8),
      );
      
      controller.setLooping(true);
      controller.setVolume(0); // Preloaded videos muted
      
      if (mounted && 
          _isScreenActive &&
          _isAppInForeground) {
        _preloadedControllers[index] = controller;
        _readyControllers.add(index);
        debugPrint('Successfully preloaded video: $index');
      } else {
        controller.dispose();
      }
    } catch (e) {
      debugPrint('Failed to preload video $index: $e');
      // Silently fail - no error UI clutter
    } finally {
      _preloadingInProgress.remove(index);
    }
  }

  void _cleanupOldPreloadedVideos() {
    final keysToRemove = _preloadedControllers.keys.where(
      (index) => (index - _currentVideoIndex).abs() > _maxPreloadedVideos
    ).toList();
    
    for (final index in keysToRemove) {
      final controller = _preloadedControllers.remove(index);
      controller?.dispose();
      _readyControllers.remove(index);
      debugPrint('Cleaned up preloaded video: $index');
    }
  }

  VideoPlayerController? _getPreloadedController(int index) {
    final controller = _preloadedControllers.remove(index);
    if (controller != null) {
      debugPrint('Using preloaded controller for video: $index');
      controller.setVolume(1.0);
      _readyControllers.remove(index);
    }
    return controller;
  }

  void _onVideoControllerReady(VideoPlayerController controller) {
    if (!mounted || !_isScreenActive || !_isAppInForeground) return;
    
    setState(() {
      _currentVideoController = controller;
    });
    
    // Always start fresh - TikTok style
    controller.seekTo(Duration.zero);
    _setupVideoProgressTracking();
    
    if (_progressController.isAnimating) {
      _progressController.stop();
    }
    
    // Keep screen awake during video playback
    WakelockPlus.enable();
    
    if (_isScreenActive && _isAppInForeground) {
      _preloadNextVideos();
    }
  }

  void _onPageChanged(int index) {
    final videos = ref.read(channelVideosProvider).videos;
    if (index >= videos.length || !_isScreenActive) return;

    setState(() {
      _currentVideoIndex = index;
      _currentVideoController = null;
      // Reset progress for new video
      _videoProgress = 0.0;
      _videoPosition = Duration.zero;
      _videoDuration = Duration.zero;
    });

    _progressUpdateTimer?.cancel();
    
    _progressController.reset();
    if (videos[index].isMultipleImages || videos[index].videoUrl.isEmpty) {
      _progressController.forward();
    }

    _cleanupOldPreloadedVideos();
    if (_isScreenActive && _isAppInForeground) {
      _preloadNextVideos();
      // Maintain wakelock during video transitions
      WakelockPlus.enable();
    }
    
    ref.read(channelVideosProvider.notifier).incrementViewCount(videos[index].id);
  }

  @override
  void dispose() {
    debugPrint('ChannelsFeedScreen: Disposing');
    
    WidgetsBinding.instance.removeObserver(this);
    
    _progressUpdateTimer?.cancel();
    
    _progressController.dispose();
    _pageController.dispose();
    
    _pauseAllPlayback();
    for (final controller in _preloadedControllers.values) {
      controller.dispose();
    }
    _preloadedControllers.clear();
    
    _videoPreloadQueue.clear();
    _preloadingInProgress.clear();
    _readyControllers.clear();;
    
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
    
    // Minimal loading screen - no loading indicators during normal use
    if (_isFirstLoad && channelVideosState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.shrink(), // Minimal loading
      );
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBody(channelVideosState, channelsState, modernTheme, bottomNavHeight),
          
          // Clean progress bar only
          Positioned(
            bottom: bottomNavHeight + 8,
            left: 0,
            right: 0,
            child: _buildMinimalProgressBar(modernTheme),
          ),
          
          if (!_isScreenActive)
            _buildInactiveOverlay(modernTheme),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(channelsState, modernTheme),
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
          final preloadedController = _getPreloadedController(index);
          
          return ChannelVideoItem(
            video: video,
            isActive: index == _currentVideoIndex && _isScreenActive && _isAppInForeground,
            onVideoControllerReady: _onVideoControllerReady,
            preloadedController: preloadedController,
          );
        },
      ),
    );
  }

  Widget _buildMinimalProgressBar(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1.5),
          color: Colors.white.withOpacity(0.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(1.5),
          child: LinearProgressIndicator(
            value: _videoProgress,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
            minHeight: 3,
          ),
        ),
      ),
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

  Widget? _buildFloatingActionButton(ChannelsState channelsState, ModernThemeExtension modernTheme) {
    return FloatingActionButton(
      backgroundColor: modernTheme.primaryColor,
      onPressed: () {
        if (channelsState.userChannel == null) {
          _navigateToCreateChannel();
        } else {
          _navigateToCreatePost();
        }
      },
      child: const Icon(Icons.add),
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
      for (final controller in _preloadedControllers.values) {
        controller.dispose();
      }
      _preloadedControllers.clear();
      _preloadingInProgress.clear();
      _videoPreloadQueue.clear();
      _readyControllers.clear();
      
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