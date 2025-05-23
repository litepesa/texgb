import 'dart:async';
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
  
  // Simplified preloading system
  final Map<int, VideoPlayerController> _preloadedControllers = {};
  final Set<int> _preloadingInProgress = {};
  
  // Conservative configuration for real device performance
  static const int _maxPreloadedVideos = 3;
  static const Duration _progressUpdateInterval = Duration(milliseconds: 200);
  static const Duration _preloadDelay = Duration(milliseconds: 500);

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
    
    debugPrint('ChannelsFeedScreen: Resuming playback');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.seekTo(Duration.zero);
      _currentVideoController!.play();
    }
    
    _setupVideoProgressTracking();
    _startPreloadingNearbyVideos();
    
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
        
        if (_isScreenActive && _isAppInForeground) {
          Timer(_preloadDelay, () {
            if (mounted && _isScreenActive && _isAppInForeground) {
              _startPreloadingNearbyVideos();
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
          
          // Preload when halfway through
          if (progress > 0.5 && _isScreenActive && _isAppInForeground) {
            _startPreloadingNearbyVideos();
          }
        }
      }
    });
  }

  void _startPreloadingNearbyVideos() {
    if (!_isScreenActive || !_isAppInForeground) return;
    
    final videos = ref.read(channelVideosProvider).videos;
    if (videos.isEmpty) return;
    
    // Preload next few videos only
    for (int i = 1; i <= _maxPreloadedVideos; i++) {
      final nextIndex = _currentVideoIndex + i;
      
      if (nextIndex < videos.length && 
          !_preloadedControllers.containsKey(nextIndex) && 
          !_preloadingInProgress.contains(nextIndex) &&
          !videos[nextIndex].isMultipleImages &&
          videos[nextIndex].videoUrl.isNotEmpty) {
        _preloadVideo(nextIndex, videos[nextIndex]);
      }
    }
  }

  Future<void> _preloadVideo(int index, ChannelVideoModel video) async {
    if (!_isScreenActive || !_isAppInForeground || _preloadingInProgress.contains(index)) {
      return;
    }
    
    _preloadingInProgress.add(index);
    
    try {
      final controller = VideoPlayerController.network(
        video.videoUrl,
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: false,
        ),
      );

      await controller.initialize().timeout(
        const Duration(seconds: 10),
      );
      
      controller.setLooping(true);
      controller.setVolume(0); // Preloaded videos muted
      
      if (mounted && _isScreenActive && _isAppInForeground) {
        _preloadedControllers[index] = controller;
        debugPrint('Successfully preloaded video: $index');
      } else {
        controller.dispose();
      }
    } catch (e) {
      debugPrint('Failed to preload video $index: $e');
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
      debugPrint('Cleaned up preloaded video: $index');
    }
  }

  VideoPlayerController? _getPreloadedController(int index) {
    final controller = _preloadedControllers.remove(index);
    if (controller != null) {
      debugPrint('Using preloaded controller for video: $index');
      controller.setVolume(1.0);
    }
    return controller;
  }

  void _onVideoControllerReady(VideoPlayerController controller) {
    if (!mounted || !_isScreenActive || !_isAppInForeground) return;
    
    setState(() {
      _currentVideoController = controller;
    });
    
    controller.seekTo(Duration.zero);
    _setupVideoProgressTracking();
    
    if (_progressController.isAnimating) {
      _progressController.stop();
    }
    
    WakelockPlus.enable();
    
    if (_isScreenActive && _isAppInForeground) {
      _startPreloadingNearbyVideos();
    }
  }

  void _onPageChanged(int index) {
    final videos = ref.read(channelVideosProvider).videos;
    if (index >= videos.length || !_isScreenActive) return;

    setState(() {
      _currentVideoIndex = index;
      _currentVideoController = null;
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
      _startPreloadingNearbyVideos();
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
    
    _preloadingInProgress.clear();
    
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
          
          // Enhanced progress bar
          Positioned(
            bottom: bottomNavHeight + 12,
            left: 16,
            right: 16,
            child: _buildEnhancedProgressBar(modernTheme),
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

  Widget _buildEnhancedProgressBar(ModernThemeExtension modernTheme) {
    return Container(
      height: 4,
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
            Container(
              width: double.infinity,
              height: 4,
              color: Colors.transparent,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: MediaQuery.of(context).size.width * _videoProgress,
              height: 4,
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