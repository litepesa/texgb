// lib/features/channels/screens/channels_feed_screen.dart
// Final production-ready TikTok-like channels feed with complete tab awareness

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
  late AnimationController _uiController;
  
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
  bool _isVideoBuffering = false;
  
  // Robust preloading system
  final Map<int, VideoPlayerController> _preloadedControllers = {};
  final Map<int, bool> _preloadingInProgress = {};
  final Set<int> _failedPreloads = {};
  final Queue<int> _videoPreloadQueue = Queue<int>();
  bool _isProcessingQueue = false;
  
  // Enhanced configuration
  static const int _maxPreloadedVideos = 3;
  static const int _maxConcurrentPreloads = 2;
  static const Duration _progressUpdateInterval = Duration(milliseconds: 100);
  static const Duration _preloadDelay = Duration(milliseconds: 500);
  
  // UI state
  bool _showUI = true;
  Timer? _uiHideTimer;

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
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  // Screen lifecycle management - call these from parent tab controller
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
    
    // Resume current video
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
    }
    
    // Resume progress tracking
    _setupVideoProgressTracking();
    
    // Resume preloading
    _startPreloadingSystem();
  }

  void _pauseAllPlayback() {
    debugPrint('ChannelsFeedScreen: Pausing all playback');
    
    // Pause current video
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.pause();
    }
    
    // Pause all preloaded videos
    for (final controller in _preloadedControllers.values) {
      if (controller.value.isInitialized) {
        controller.pause();
      }
    }
    
    // Stop progress tracking
    _progressUpdateTimer?.cancel();
    
    // Stop preloading
    _isProcessingQueue = false;
    _videoPreloadQueue.clear();
  }

  void _initializeControllers() {
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    
    _uiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
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
        
        // Start preloading system with delay only if screen is active
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

  // Enhanced progress tracking system
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
        final isBuffering = controller.value.isBuffering;
        
        if (duration.inMilliseconds > 0) {
          final progress = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
          
          if (mounted) {
            setState(() {
              _videoPosition = position;
              _videoDuration = duration;
              _videoProgress = progress;
              _isVideoBuffering = isBuffering;
            });
          }
          
          // Trigger additional preloading near end
          if (progress > 0.8 && _isScreenActive && _isAppInForeground) {
            _preloadNextVideos();
          }
        }
      }
    });
  }

  // Robust preloading system
  void _startPreloadingSystem() {
    if (!_isScreenActive || !_isAppInForeground) return;
    _preloadNextVideos();
  }

  void _preloadNextVideos() {
    if (!_isScreenActive || !_isAppInForeground) return;
    
    final videos = ref.read(channelVideosProvider).videos;
    if (videos.isEmpty) return;
    
    // Calculate preload range
    for (int i = 1; i <= _maxPreloadedVideos; i++) {
      final index = _currentVideoIndex + i;
      if (index < videos.length && 
          !_preloadedControllers.containsKey(index) && 
          !_preloadingInProgress.containsKey(index) &&
          !_failedPreloads.contains(index) &&
          !videos[index].isMultipleImages &&
          videos[index].videoUrl.isNotEmpty) {
        _videoPreloadQueue.add(index);
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
    
    // Process multiple videos concurrently
    final List<Future<void>> preloadTasks = [];
    int processed = 0;
    
    while (_videoPreloadQueue.isNotEmpty && 
           processed < _maxConcurrentPreloads &&
           _preloadedControllers.length < _maxPreloadedVideos &&
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
    
    // Wait for all preload tasks to complete
    await Future.wait(preloadTasks);
    
    _isProcessingQueue = false;
  }

  Future<void> _preloadVideo(int index, ChannelVideoModel video) async {
    if (!_isScreenActive || !_isAppInForeground) {
      _preloadingInProgress.remove(index);
      return;
    }
    
    try {
      debugPrint('Preloading video: $index (${video.caption.length > 20 ? video.caption.substring(0, 20) : video.caption}...)');
      
      final controller = VideoPlayerController.network(
        video.videoUrl,
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: false,
        ),
      );

      // Add timeout for initialization
      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Video initialization timeout', const Duration(seconds: 10));
        },
      );
      
      controller.setLooping(true);
      controller.setVolume(0); // Preloaded videos should be muted
      
      // Only keep if still relevant and screen is still active
      if (mounted && 
          _isScreenActive &&
          _isAppInForeground &&
          index > _currentVideoIndex && 
          index <= _currentVideoIndex + _maxPreloadedVideos) {
        _preloadedControllers[index] = controller;
        debugPrint('Successfully preloaded video: $index');
      } else {
        controller.dispose();
        debugPrint('Disposed irrelevant preloaded video: $index');
      }
    } catch (e) {
      debugPrint('Failed to preload video $index: $e');
      _failedPreloads.add(index);
    } finally {
      _preloadingInProgress.remove(index);
    }
  }

  void _cleanupOldPreloadedVideos() {
    final keysToRemove = _preloadedControllers.keys.where(
      (index) => index <= _currentVideoIndex || index > _currentVideoIndex + _maxPreloadedVideos
    ).toList();
    
    for (final index in keysToRemove) {
      final controller = _preloadedControllers.remove(index);
      controller?.dispose();
      debugPrint('Cleaned up preloaded video: $index');
    }
    
    // Clear old failed preloads
    _failedPreloads.removeWhere((index) => index <= _currentVideoIndex - 2);
  }

  VideoPlayerController? _getPreloadedController(int index) {
    final controller = _preloadedControllers.remove(index);
    if (controller != null) {
      debugPrint('Using preloaded controller for video: $index');
      // Restore volume for active video
      controller.setVolume(1.0);
    }
    return controller;
  }

  void _onVideoControllerReady(VideoPlayerController controller) {
    if (!mounted || !_isScreenActive || !_isAppInForeground) return;
    
    setState(() {
      _currentVideoController = controller;
    });
    
    _setupVideoProgressTracking();
    
    if (_progressController.isAnimating) {
      _progressController.stop();
    }
    
    // Continue preloading only if screen is active
    if (_isScreenActive && _isAppInForeground) {
      _preloadNextVideos();
    }
  }

  void _onPageChanged(int index) {
    final videos = ref.read(channelVideosProvider).videos;
    if (index >= videos.length || !_isScreenActive) return;

    final oldIndex = _currentVideoIndex;
    
    setState(() {
      _currentVideoIndex = index;
      _currentVideoController = null;
      _videoProgress = 0.0;
      _videoPosition = Duration.zero;
      _videoDuration = Duration.zero;
      _isVideoBuffering = false;
    });

    _progressUpdateTimer?.cancel();
    
    // Reset progress animation for new content
    _progressController.reset();
    if (videos[index].isMultipleImages || videos[index].videoUrl.isEmpty) {
      _progressController.forward();
    }

    // Clean up and preload only if screen is active
    _cleanupOldPreloadedVideos();
    if (_isScreenActive && _isAppInForeground) {
      _preloadNextVideos();
    }
    
    // Increment view count
    ref.read(channelVideosProvider.notifier).incrementViewCount(videos[index].id);
    
    debugPrint('Page changed from $oldIndex to $index (screen active: $_isScreenActive)');
  }

  // UI management
  void _toggleUI() {
    if (!_isScreenActive) return;
    
    setState(() {
      _showUI = !_showUI;
    });
    
    if (_showUI) {
      _uiController.forward();
      _startUIHideTimer();
    } else {
      _uiController.reverse();
      _uiHideTimer?.cancel();
    }
  }

  void _startUIHideTimer() {
    _uiHideTimer?.cancel();
    _uiHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showUI && _isScreenActive) {
        setState(() {
          _showUI = false;
        });
        _uiController.reverse();
      }
    });
  }

  @override
  void dispose() {
    debugPrint('ChannelsFeedScreen: Disposing');
    
    WidgetsBinding.instance.removeObserver(this);
    
    // Stop all timers
    _progressUpdateTimer?.cancel();
    _uiHideTimer?.cancel();
    
    // Dispose controllers
    _progressController.dispose();
    _uiController.dispose();
    _pageController.dispose();
    
    // Clean up all preloaded controllers
    _pauseAllPlayback();
    for (final controller in _preloadedControllers.values) {
      controller.dispose();
    }
    _preloadedControllers.clear();
    
    // Clear queues
    _videoPreloadQueue.clear();
    _preloadingInProgress.clear();
    _failedPreloads.clear();
    
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
    
    if (_isFirstLoad) {
      return _buildLoadingScreen(modernTheme);
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          _buildBody(channelVideosState, channelsState, modernTheme, bottomNavHeight),
          
          // UI overlay
          AnimatedBuilder(
            animation: _uiController,
            builder: (context, child) {
              return Opacity(
                opacity: _uiController.value,
                child: _buildUIOverlay(modernTheme),
              );
            },
          ),
          
          // Progress bar (always visible)
          Positioned(
            bottom: bottomNavHeight + 8,
            left: 0,
            right: 0,
            child: _buildEnhancedProgressBar(modernTheme),
          ),
          
          // Show error message if any
          if (channelVideosState.error != null)
            _buildErrorOverlay(channelVideosState.error!, modernTheme),
            
          // Loading indicator for buffering
          if (_isVideoBuffering && _isScreenActive)
            _buildBufferingIndicator(modernTheme),
            
          // Screen inactive overlay
          if (!_isScreenActive)
            _buildInactiveOverlay(modernTheme),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(channelsState, modernTheme),
    );
  }

  Widget _buildLoadingScreen(ModernThemeExtension modernTheme) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF07C160)),
        ),
      ),
    );
  }

  Widget _buildBody(ChannelVideosState videosState, ChannelsState channelsState, 
                    ModernThemeExtension modernTheme, double bottomPadding) {
    
    if (!videosState.isLoading && channelsState.userChannel == null) {
      return _buildCreateChannelPrompt(modernTheme);
    }

    if (videosState.isLoading && _isFirstLoad) {
      return _buildInitialLoadingState(modernTheme);
    }

    if (!videosState.isLoading && videosState.videos.isEmpty) {
      return _buildEmptyState(channelsState, modernTheme);
    }

    return GestureDetector(
      onTap: _toggleUI,
      child: Padding(
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
      ),
    );
  }

  Widget _buildUIOverlay(ModernThemeExtension modernTheme) {
    return Column(
      children: [
        // Top gradient and search bar
        Container(
          height: MediaQuery.of(context).padding.top + 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
            ),
            child: _buildSearchBar(),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search channels and videos',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          // Status indicators
          Row(
            children: [
              if (!_isAppInForeground)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'BG',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (!_isScreenActive)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PAUSED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (_preloadedControllers.isNotEmpty && _isScreenActive)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_preloadedControllers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProgressBar(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Main progress bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withOpacity(0.3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _videoProgress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
                minHeight: 3,
              ),
            ),
          ),
          
          // Time display for videos
          if (_videoDuration.inSeconds > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_videoPosition),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      if (_isVideoBuffering)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      if (!_isScreenActive) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.pause_circle_outline,
                          color: Colors.orange,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    _formatDuration(_videoDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
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
            const SizedBox(height: 8),
            const Text(
              'Switch back to this tab to resume',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Create your own channel to start sharing videos and photos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialLoadingState(ModernThemeExtension modernTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: modernTheme.primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Channels',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding the best content for you',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              channelsState.userChannel != null
                  ? 'Be the first to share a video or photo in your channel!'
                  : 'Follow channels or create your own to see videos here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorOverlay(String error, ModernThemeExtension modernTheme) {
    return Positioned(
      bottom: 160,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Error: ${error.split(']').last.trim()}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBufferingIndicator(ModernThemeExtension modernTheme) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.45,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: modernTheme.primaryColor,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Buffering...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(ChannelsState channelsState, ModernThemeExtension modernTheme) {
    if (!_showUI || !_isScreenActive) return null;
    
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
      // Clean up preloaded videos since feed will change
      _pauseAllPlayback();
      for (final controller in _preloadedControllers.values) {
        controller.dispose();
      }
      _preloadedControllers.clear();
      _preloadingInProgress.clear();
      _videoPreloadQueue.clear();
      _failedPreloads.clear();
      
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// Extension to be used by parent tab controller
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

// Public interface for tab management
class ChannelsFeedController {
  final GlobalKey<_ChannelsFeedScreenState> _key;
  
  ChannelsFeedController(this._key);
  
  void setActive(bool isActive) {
    ChannelsFeedScreenExtension.handleTabChanged(_key, isActive);
  }
  
  void pause() => setActive(false);
  void resume() => setActive(true);
}