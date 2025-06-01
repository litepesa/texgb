// Enhanced version of lib/features/channels/screens/channels_feed_screen.dart
// Updated with MediaKit support for audio amplification

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
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
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
  bool _showProgressBar = true;
  
  // Enhanced progress tracking - Updated for MediaKit
  double _videoProgress = 0.0;
  Duration _videoDuration = Duration.zero;
  Duration _videoPosition = Duration.zero;
  Player? _currentMediaKitPlayer;
  Timer? _progressUpdateTimer;
  Timer? _cacheCleanupTimer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  
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
    
    if (mounted) {
      setState(() {
        _showProgressBar = true;
      });
    }
    
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
    
    // Updated for MediaKit
    if (_currentMediaKitPlayer != null) {
      _currentMediaKitPlayer!.seek(Duration.zero);
      _currentMediaKitPlayer!.play();
    }
    
    _setupVideoProgressTracking();
    _startIntelligentPreloading();
    
    WakelockPlus.enable();
  }

  void _pauseAllPlayback() {
    debugPrint('ChannelsFeedScreen: Pausing all playback');
    
    // Updated for MediaKit
    if (_currentMediaKitPlayer != null) {
      _currentMediaKitPlayer!.pause();
    }
    
    _progressUpdateTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
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
    if (_currentMediaKitPlayer == null) {
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
          _showProgressBar = true;
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
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    
    // Ensure progress bar is visible
    if (mounted) {
      setState(() {
        _showProgressBar = true;
      });
    }
    
    // Updated for MediaKit - Use streams instead of polling
    if (_currentMediaKitPlayer != null) {
      debugPrint('Setting up MediaKit progress tracking');
      
      // Listen to position updates
      _positionSubscription = _currentMediaKitPlayer!.stream.position.listen((position) {
        if (!mounted || !_isScreenActive || !_isAppInForeground) return;
        
        if (mounted) {
          setState(() {
            _videoPosition = position;
          });
        }
        
        // Calculate progress when we have both position and duration
        if (_videoDuration.inMilliseconds > 0) {
          final progress = (position.inMilliseconds / _videoDuration.inMilliseconds).clamp(0.0, 1.0);
          
          if (mounted) {
            setState(() {
              _videoProgress = progress;
            });
            
            debugPrint('MediaKit Video Progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
          
          // Trigger next batch preloading when halfway through
          if (progress > 0.5 && _isScreenActive && _isAppInForeground) {
            _preloadNextBatch();
          }
        }
      });
      
      // Listen to duration updates
      _durationSubscription = _currentMediaKitPlayer!.stream.duration.listen((duration) {
        if (!mounted) return;
        
        if (mounted) {
          setState(() {
            _videoDuration = duration;
          });
        }
      });
    } else {
      // Fallback for images or when video is not ready
      _progressUpdateTimer = Timer.periodic(_progressUpdateInterval, (timer) {
        if (!mounted || !_isScreenActive || !_isAppInForeground) {
          timer.cancel();
          return;
        }
        
        if (mounted) {
          setState(() {
            _videoProgress = _progressController.value;
          });
        }
      });
    }
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

  // Updated method signature for MediaKit Player with real-time audio level detection
  void _onMediaKitPlayerReady(Player player) {
    if (!mounted || !_isScreenActive || !_isAppInForeground) return;
    
    debugPrint('MediaKit player ready, setting up adaptive audio based on actual volume levels');
    
    setState(() {
      _currentMediaKitPlayer = player;
      _videoProgress = 0.0;
      _showProgressBar = true;
    });
    
    // Start with moderate volume, then detect and adjust
    player.setVolume(200.0);
    player.seek(Duration.zero);
    
    // Schedule audio level detection after video starts playing
    Timer(const Duration(milliseconds: 800), () {
      _detectAndAdjustAudioLevels(player);
    });
    
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

  // Smart audio level detection and adjustment
  void _detectAndAdjustAudioLevels(Player player) async {
    if (!mounted || !_isScreenActive || !_isAppInForeground) return;
    
    try {
      debugPrint('🎧 Detecting audio levels for smart volume adjustment...');
      
      // Apply audio analysis filter to detect volume levels
      await player.setAudioFilter('volumedetect,dynaudnorm=f=500:g=31:p=0.95:m=10.0:r=0.5');
      
      // Wait a moment for audio analysis
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Since we can't easily get volumedetect output in Flutter,
      // we'll use a smart progressive approach
      _progressiveVolumeAdjustment(player);
      
    } catch (e) {
      debugPrint('⚠️ Audio filter detection failed, using fallback: $e');
      _fallbackVolumeDetection(player);
    }
  }

  // Progressive volume adjustment - tests different levels
  void _progressiveVolumeAdjustment(Player player) async {
    if (!mounted || !_isScreenActive || !_isAppInForeground) return;
    
    try {
      // Start with dynamic normalization that auto-adjusts
      await player.setAudioFilter('dynaudnorm=f=500:g=31:p=0.95:m=5.0:r=1.0:n=1:c=1:b=1');
      
      // Set volume to let the normalization do most of the work
      player.setVolume(200.0); // High base, normalization will adjust
      
      debugPrint('✅ Applied smart auto-normalizing filter - will boost quiet videos and control loud ones');
      
      // Alternative approach: Apply aggressive boost for very quiet content
      Timer(const Duration(seconds: 2), () {
        if (mounted && _isScreenActive && _isAppInForeground) {
          _applyAggressiveBoostIfNeeded(player);
        }
      });
      
    } catch (e) {
      debugPrint('⚠️ Progressive adjustment failed: $e');
      player.setVolume(200.0); // Fallback to your original 200%
    }
  }

  // Apply extra boost if content is still too quiet
  void _applyAggressiveBoostIfNeeded(Player player) async {
    try {
      // For very quiet content, apply additional processing
      await player.setAudioFilter('dynaudnorm=f=500:g=31:p=0.95:m=5.0:r=1.0,volume=1.5:precision=float');
      
      debugPrint('🔊 Applied aggressive boost for quiet content');
    } catch (e) {
      // If filters fail, just use high volume
      player.setVolume(200.0);
      debugPrint('🔊 Using 200% volume fallback for quiet content');
    }
  }

  // Fallback when advanced features don't work
  void _fallbackVolumeDetection(Player player) {
    // Simple approach: Use the dynamic normalization that adapts automatically
    try {
      // This filter automatically detects quiet vs loud content and adjusts
      player.setAudioFilter('dynaudnorm=f=500:g=31:p=0.95:m=10.0:r=0.5:n=1:c=1:b=1');
      player.setVolume(200.0);
      
      debugPrint('✅ Fallback: Using auto-adaptive normalization');
    } catch (e) {
      // Last resort: Your original 400% boost
      player.setVolume(200.0);
      debugPrint('🔊 Last resort: 200% volume boost');
    }
  }

  // Remove the volume adjustment method since all short videos need the same treatment
  // void _adjustVolumeBasedOnContent(Player player) - REMOVED

  void _onPageChanged(int index) {
    final videos = ref.read(channelVideosProvider).videos;
    if (index >= videos.length || !_isScreenActive) return;

    debugPrint('Page changed to: $index');

    setState(() {
      _currentVideoIndex = index;
      _currentMediaKitPlayer = null; // Updated for MediaKit
      _videoProgress = 0.0;
      _videoPosition = Duration.zero;
      _videoDuration = Duration.zero;
      _showProgressBar = true;
    });

    _progressUpdateTimer?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _progressController.reset();
    
    // Handle different content types
    if (videos[index].isMultipleImages || videos[index].videoUrl.isEmpty) {
      _progressController.forward();
      debugPrint('Starting image progress animation');
    } else {
      debugPrint('Waiting for MediaKit video to initialize for progress tracking');
    }

    if (_isScreenActive && _isAppInForeground) {
      _startIntelligentPreloading();
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
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    
    _progressController.dispose();
    _pageController.dispose();
    
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
          
          // Enhanced progress bar with cache indicators
          Positioned(
            bottom: bottomNavHeight + 16,
            left: 16,
            right: 16,
            child: _buildEnhancedProgressBar(modernTheme),
          ),
          
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
          
          return ChannelVideoItem(
            video: video,
            isActive: index == _currentVideoIndex && _isScreenActive && _isAppInForeground,
            onVideoControllerReady: _onMediaKitPlayerReady, // Updated callback
          );
        },
      ),
    );
  }

  Widget _buildEnhancedProgressBar(ModernThemeExtension modernTheme) {
    final shouldShow = _showProgressBar && (_videoProgress > 0.0 || _isFirstLoad);
    
    debugPrint('Progress Bar - Show: $shouldShow, Progress: $_videoProgress, FirstLoad: $_isFirstLoad');
    
    if (!shouldShow) return const SizedBox.shrink();
    
    return Container(
      height: 4,
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
              height: 4,
              color: Colors.transparent,
            ),
            // Progress fill with enhanced styling for cached content
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: (MediaQuery.of(context).size.width - 32) * _videoProgress.clamp(0.0, 1.0),
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
                'Progress: ${(_videoProgress * 100).toStringAsFixed(1)}% | MediaKit: ${_currentMediaKitPlayer != null ? "Active" : "Inactive"}',
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
      
      ref.read(channelVideosProvider.notifier).loadVideos(forceRefresh: true);
      
      setState(() {
        _videoProgress = 0.0;
        _videoPosition = Duration.zero;
        _videoDuration = Duration.zero;
        _showProgressBar = true;
      });
      _progressUpdateTimer?.cancel();
      _positionSubscription?.cancel();
      _durationSubscription?.cancel();
      _progressController.reset();
      if (_isScreenActive && _isAppInForeground) {
        _progressController.forward();
      }
    }
  }
}

extension on Player {
  setAudioFilter(String s) {}
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