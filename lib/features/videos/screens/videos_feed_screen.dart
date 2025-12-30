// lib/features/videos/screens/videos_feed_screen.dart - WeChat Channels Style Layout

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/videos/services/video_cache_service.dart';
import 'package:textgb/features/videos/widgets/video_item.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/comments/widgets/comments_bottom_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:textgb/features/videos/widgets/search_overlay.dart';
import 'package:textgb/features/videos/providers/video_progress_provider.dart';

class VideosFeedScreen extends ConsumerStatefulWidget {
  final String? startVideoId;
  final String? userId;

  const VideosFeedScreen({
    super.key,
    this.startVideoId,
    this.userId,
  });

  @override
  ConsumerState<VideosFeedScreen> createState() => VideosFeedScreenState();
}

class VideosFeedScreenState extends ConsumerState<VideosFeedScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver,
        RouteAware {
  final PageController _pageController = PageController();

  // Feed filter tab state
  int _selectedTabIndex = 2; // Default to "Hot" tab
  final List<String> _feedTabs = ['Following', 'Friends', 'Hot'];

  // State management
  bool _isFirstLoad = true;
  int _currentVideoIndex = 0;
  bool _isScreenActive = false;
  bool _isAppInForeground = true;
  bool _hasInitialized = false;
  bool _isNavigatingAway = false;
  bool _isManuallyPaused = false;
  bool _isCommentsSheetOpen = false;

  VideoPlayerController? _currentVideoController;
  Timer? _cacheCleanupTimer;
  SystemUiOverlayStyle? _originalSystemUiStyle;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _setupCacheCleanup();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialVideoPosition();
      _precacheInitialVideos();
      // Auto-play videos when screen loads
      onScreenBecameActive();
    });

    _hasInitialized = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_originalSystemUiStyle == null) {
      _storeOriginalSystemUI();
    }
  }

  void _storeOriginalSystemUI() {
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        if (_isScreenActive && !_isNavigatingAway && !_isCommentsSheetOpen) {
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
    debugPrint('VideosFeedScreen: Screen became active');
    _isScreenActive = true;
    _isNavigatingAway = false;
    _setupSystemUI();

    if (_isAppInForeground && !_isManuallyPaused && !_isCommentsSheetOpen) {
      _startFreshPlayback();
      WakelockPlus.enable();
    }
  }

  void onScreenBecameInactive() {
    if (!_hasInitialized) return;
    debugPrint('VideosFeedScreen: Screen became inactive');
    _isScreenActive = false;
    _stopPlayback();
    _restoreOriginalSystemUI();
    WakelockPlus.disable();
  }

  void _restoreOriginalSystemUI() {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  void _pauseForNavigation() {
    _isNavigatingAway = true;
    _stopPlayback();
  }

  void _resumeFromNavigation() {
    _isNavigatingAway = false;
    if (_isScreenActive && _isAppInForeground && !_isManuallyPaused && !_isCommentsSheetOpen) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_isNavigatingAway && _isScreenActive && _isAppInForeground && !_isManuallyPaused && !_isCommentsSheetOpen) {
          _startFreshPlayback();
        }
      });
    }
  }

  void _setupCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 10), (timer) {});
  }

  void _precacheInitialVideos() {
    final videos = ref.read(videosProvider);
    if (videos.isEmpty) return;

    final videoUrls = videos
        .where((v) => !v.isMultipleImages && v.videoUrl.isNotEmpty)
        .take(3)
        .map((v) => v.videoUrl)
        .toList();
    
    if (videoUrls.isNotEmpty) {
      VideoCacheService().precacheMultiple(
        videoUrls,
        cacheSegmentsPerVideo: 3,
        maxConcurrent: 2,
      );
    }
  }

  void _startIntelligentPreloading() {
    if (!_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isCommentsSheetOpen) {
      return;
    }

    final videos = ref.read(videosProvider);
    if (videos.isEmpty) return;

    final videoOnlyList = videos
        .where((v) => !v.isMultipleImages && v.videoUrl.isNotEmpty)
        .toList();
    
    if (videoOnlyList.isEmpty) return;
    
    final currentVideo = videos[_currentVideoIndex];
    if (currentVideo.isMultipleImages) return;
    
    final currentIndexInVideoList = videoOnlyList
        .indexWhere((v) => v.videoUrl == currentVideo.videoUrl);
    
    if (currentIndexInVideoList == -1) return;
    
    final videoUrls = videoOnlyList.map((v) => v.videoUrl).toList();
    
    VideoCacheService().intelligentPreload(
      videoUrls: videoUrls,
      currentIndex: currentIndexInVideoList,
      preloadNext: 5,
      preloadPrevious: 2,
      cacheSegmentsPerVideo: 3,
    );
  }

  void _startFreshPlayback() {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isManuallyPaused || _isCommentsSheetOpen) {
      return;
    }

    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
    } else {
      final videos = ref.read(videosProvider);
      if (videos.isNotEmpty && _currentVideoIndex < videos.length) {
        setState(() {});
      }
    }

    _startIntelligentPreloading();
    WakelockPlus.enable();
  }

  void _stopPlayback() {
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.pause();
      if (!_isCommentsSheetOpen) {
        _currentVideoController!.seekTo(Duration.zero);
      }
    }
  }

  void _setVideoWindowMode(bool isSmallWindow) {
    setState(() {
      _isCommentsSheetOpen = isSmallWindow;
    });
  }

  void _initializeControllers() {}

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.black,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  void _handleInitialVideoPosition() {
    if (!mounted) return;
    
    setState(() {
      _isFirstLoad = false;
    });

    if (widget.startVideoId != null) {
      _jumpToVideo(widget.startVideoId!);
    } else {
      _startIntelligentPreloading();
    }
  }

  void _jumpToVideo(String videoId) {
    final videos = ref.read(videosProvider);
    final videoIndex = videos.indexWhere((video) => video.id == videoId);

    if (videoIndex != -1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(videoIndex);
          setState(() {
            _currentVideoIndex = videoIndex;
          });
          _startIntelligentPreloading();
        }
      });
    }
  }

  void _onVideoControllerReady(VideoPlayerController controller) {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isCommentsSheetOpen) {
      return;
    }

    setState(() {
      _currentVideoController = controller;
    });

    controller.addListener(() {
      if (mounted && controller.value.isInitialized) {
        final position = controller.value.position.inMilliseconds;
        final duration = controller.value.duration.inMilliseconds;
        if (duration > 0) {
          final progress = position / duration;
          ref.read(videoProgressProvider.notifier).state = progress.clamp(0.0, 1.0);
        }
        ref.read(isVideoPlayingProvider.notifier).state = controller.value.isPlaying;
      }
    });

    controller.seekTo(Duration.zero);
    WakelockPlus.enable();

    if (_isScreenActive && _isAppInForeground && !_isNavigatingAway && !_isManuallyPaused && !_isCommentsSheetOpen) {
      _startIntelligentPreloading();
    }
  }

  void onManualPlayPause(bool isPlaying) {
    setState(() {
      _isManuallyPaused = !isPlaying;
    });
  }

  void _onPageChanged(int index) {
    final videos = ref.read(videosProvider);
    if (index >= videos.length || !_isScreenActive) return;

    setState(() {
      _currentVideoIndex = index;
      _isManuallyPaused = false;
    });

    if (_isScreenActive && _isAppInForeground && !_isNavigatingAway && !_isManuallyPaused && !_isCommentsSheetOpen) {
      _startIntelligentPreloading();
      WakelockPlus.enable();
    }

    ref.read(authenticationProvider.notifier).incrementViewCount(videos[index].id);
  }

  Widget _buildSmallVideoWindow() {
    final systemTopPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: systemTopPadding + 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          _setVideoWindowMode(false);
        },
        child: Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Positioned.fill(child: _buildVideoContentOnly()),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContentOnly() {
    final videos = ref.read(videosProvider);

    if (videos.isEmpty || _currentVideoIndex >= videos.length) {
      return Container(color: Colors.black);
    }

    final currentVideo = videos[_currentVideoIndex];

    if (currentVideo.isMultipleImages) {
      return _buildImageCarouselOnly(currentVideo.imageUrls);
    } else {
      return _buildVideoPlayerOnly();
    }
  }

  Widget _buildVideoPlayerOnly() {
    if (_currentVideoController?.value.isInitialized != true) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _currentVideoController!.value.size.width,
          height: _currentVideoController!.value.size.height,
          child: VideoPlayer(_currentVideoController!),
        ),
      ),
    );
  }

  Widget _buildImageCarouselOnly(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 32)),
      );
    }

    return PageView.builder(
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return Image.network(
          imageUrls[index],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.black,
              child: const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 32)),
            );
          },
        );
      },
    );
  }

  void _showCommentsForCurrentVideo(VideoModel video) {
    _setVideoWindowMode(true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        video: video,
        onClose: () {
          _setVideoWindowMode(false);
        },
      ),
    ).whenComplete(() {
      _setVideoWindowMode(false);
    });
  }

  void _showSearchOverlay() {
    _pauseForNavigation();
    
    SearchOverlayController.show(
      context,
      onVideoTap: (videoId) {
        _jumpToVideo(videoId);
        _resumeFromNavigation();
      },
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    // TODO: Add filtering logic based on selected tab
  }

  void _handleBackNavigation() {
    _stopPlayback();
    _restoreOriginalSystemUI();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  // RouteAware callbacks for handling navigation
  @override
  void didPush() {
    // Called when this route has been pushed
    onScreenBecameActive();
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and this route shows up
    onScreenBecameActive();
  }

  @override
  void didPop() {
    // Called when this route has been popped off
    onScreenBecameInactive();
  }

  @override
  void didPushNext() {
    // Called when a new route has been pushed, and this route is no longer visible
    onScreenBecameInactive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPlayback();
    _cacheCleanupTimer?.cancel();
    _pageController.dispose();
    _restoreOriginalSystemUI();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final videos = ref.watch(videosProvider);
    final isAppInitializing = ref.watch(isAppInitializingProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    if (isAppInitializing || (_isFirstLoad && videos.isEmpty)) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading videos...',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Black status bar area
          Container(
            height: topPadding,
            color: Colors.black,
          ),
          // Video content area with header overlay inside
          Expanded(
            child: Stack(
              children: [
                _buildBody(videos),
                // Header overlay inside video area
                if (!_isCommentsSheetOpen) _buildHeaderOverlay(),
                // Small video window when comments are open
                if (_isCommentsSheetOpen) _buildSmallVideoWindow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: _handleBackNavigation,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  CupertinoIcons.back,
                  color: Colors.white,
                  size: 24,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Feed filter tabs
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_feedTabs.length, (index) {
                  final isSelected = _selectedTabIndex == index;
                  return GestureDetector(
                    onTap: () => _onTabSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _feedTabs[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 4),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 2,
                            width: isSelected ? 16 : 0,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            // Search button
            GestureDetector(
              onTap: _showSearchOverlay,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  CupertinoIcons.search,
                  color: Colors.white,
                  size: 24,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<VideoModel> videos) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: videos.length,
      onPageChanged: _onPageChanged,
      physics: _isScreenActive && !_isCommentsSheetOpen ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final video = videos[index];

        return VideoItem(
          video: video,
          isActive: index == _currentVideoIndex && _isScreenActive && _isAppInForeground && !_isNavigatingAway,
          onVideoControllerReady: _onVideoControllerReady,
          onManualPlayPause: onManualPlayPause,
          isCommentsOpen: _isCommentsSheetOpen,
          isFeedScreen: true,
          onCommentsPressed: () => _showCommentsForCurrentVideo(video),
        );
      },
    );
  }
}

extension VideosFeedScreenExtension on VideosFeedScreenState {
  static void handleTabChanged(GlobalKey<VideosFeedScreenState> feedScreenKey, bool isActive) {
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

class VideosFeedController {
  final GlobalKey<VideosFeedScreenState> _key;

  VideosFeedController(this._key);

  void setActive(bool isActive) {
    VideosFeedScreenExtension.handleTabChanged(_key, isActive);
  }

  void pause() => setActive(false);
  void resume() => setActive(true);
}