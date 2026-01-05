// lib/features/marketplace/screens/marketplace_feed_screen.dart - WeChat Channels Style Layout

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/marketplace/providers/marketplace_provider.dart';
import 'package:textgb/features/marketplace/providers/marketplace_convenience_providers.dart';
import 'package:textgb/features/marketplace/services/marketplace_cache_service.dart';
import 'package:textgb/features/marketplace/widgets/marketplace_video_item.dart';
import 'package:textgb/features/marketplace/models/marketplace_video_model.dart';
import 'package:textgb/features/marketplace/widgets/marketplace_comments_bottom_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
// Import search overlay
import 'package:textgb/features/marketplace/widgets/marketplace_search_overlay.dart';
// Import marketplaceVideo progress provider
import 'package:textgb/features/marketplace/providers/marketplace_progress_provider.dart';

class MarketplaceFeedScreen extends ConsumerStatefulWidget {
  final String? startItemId; // For direct marketplaceVideo navigation
  final String? userId; // For user-specific filtering (optional)

  const MarketplaceFeedScreen({
    super.key,
    this.startItemId,
    this.userId,
  });

  @override
  ConsumerState<MarketplaceFeedScreen> createState() =>
      MarketplaceFeedScreenState();
}

class MarketplaceFeedScreenState extends ConsumerState<MarketplaceFeedScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver,
        RouteAware {
  // Core controllers
  final PageController _pageController = PageController();

  // Feed filter tab state
  int _selectedTabIndex = 2; // Default to "Hot" tab
  final List<String> _feedTabs = ['Flashsale', 'Live', 'Hot'];

  // State management
  bool _isFirstLoad = true;
  int _currentVideoIndex = 0;
  bool _isScreenActive = false;
  bool _isAppInForeground = true;
  bool _hasInitialized = false;
  bool _isNavigatingAway = false;
  bool _isManuallyPaused = false;
  bool _isCommentsSheetOpen = false;

  // Video controllers
  VideoPlayerController? _currentVideoController;
  Timer? _cacheCleanupTimer;

  // Store original system UI for restoration
  SystemUiOverlayStyle? _originalSystemUiStyle;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _setupCacheCleanup();

    // Handle initial marketplaceVideo position and start precaching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialVideoPosition();
      _precacheInitialVideos(); // Start precaching immediately
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
      statusBarIconBrightness:
          brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          brightness == Brightness.dark ? Brightness.light : Brightness.dark,
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

    debugPrint('MarketplaceFeedScreen: Screen became active');
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

    debugPrint('MarketplaceFeedScreen: Screen became inactive');
    _isScreenActive = false;
    _stopPlayback();

    _restoreOriginalSystemUI();

    WakelockPlus.disable();
  }

  void _restoreOriginalSystemUI() {
    debugPrint('MarketplaceFeedScreen: Restoring original system UI');

    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  void _pauseForNavigation() {
    debugPrint('MarketplaceFeedScreen: Pausing for navigation');
    _isNavigatingAway = true;
    _stopPlayback();
  }

  void _resumeFromNavigation() {
    debugPrint('MarketplaceFeedScreen: Resuming from navigation');
    _isNavigatingAway = false;
    if (_isScreenActive &&
        _isAppInForeground &&
        !_isManuallyPaused &&
        !_isCommentsSheetOpen) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted &&
            !_isNavigatingAway &&
            _isScreenActive &&
            _isAppInForeground &&
            !_isManuallyPaused &&
            !_isCommentsSheetOpen) {
          _startFreshPlayback();
        }
      });
    }
  }

  void _setupCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      // Cache cleanup logic can be added here if needed
    });
  }

  // NEW: Precache initial marketplaceVideos as soon as they load
  void _precacheInitialVideos() {
    final marketplaceVideos = ref.read(marketplaceVideosProvider);
    if (marketplaceVideos.isEmpty) return;

    debugPrint('Precaching initial marketplaceVideos for instant playback...');

    // Get first 3 marketplaceVideo URLs (skip image posts)
    final videoUrls = marketplaceVideos
        .where((v) => !v.isMultipleImages && v.videoUrl.isNotEmpty)
        .take(3)
        .map((v) => v.videoUrl)
        .toList();

    if (videoUrls.isNotEmpty) {
      MarketplaceCacheService().precacheMultiple(
        videoUrls,
        cacheSegmentsPerVideo:
            3, // Cache 6MB per marketplaceVideo for instant start
        maxConcurrent: 2,
      );
    }
  }

  // UPDATED: Intelligent preloading with filtering for marketplaceVideo-only content
  void _startIntelligentPreloading() {
    if (!_isScreenActive ||
        !_isAppInForeground ||
        _isNavigatingAway ||
        _isCommentsSheetOpen) {
      return;
    }

    final marketplaceVideos = ref.read(marketplaceVideosProvider);
    if (marketplaceVideos.isEmpty) return;

    debugPrint(
        'Starting intelligent preloading for index: $_currentVideoIndex');

    // Filter to get only actual marketplaceVideos (no image posts)
    final videoOnlyList = marketplaceVideos
        .where((v) => !v.isMultipleImages && v.videoUrl.isNotEmpty)
        .toList();

    if (videoOnlyList.isEmpty) return;

    // Find current marketplaceVideo in the filtered list
    final currentVideo = marketplaceVideos[_currentVideoIndex];

    // If current item is an image post, find nearest marketplaceVideo
    if (currentVideo.isMultipleImages) {
      debugPrint('Current item is image post, skipping preload');
      return;
    }

    final currentIndexInVideoList =
        videoOnlyList.indexWhere((v) => v.videoUrl == currentVideo.videoUrl);

    if (currentIndexInVideoList == -1) return;

    final videoUrls = videoOnlyList.map((v) => v.videoUrl).toList();

    MarketplaceCacheService().intelligentPreload(
      videoUrls: videoUrls,
      currentIndex: currentIndexInVideoList,
      preloadNext: 5, // Preload next 5 marketplaceVideos
      preloadPrevious: 2, // Preload previous 2 marketplaceVideos
      cacheSegmentsPerVideo: 3, // 6MB per marketplaceVideo (increased from 2)
    );
  }

  void _startFreshPlayback() {
    if (!mounted ||
        !_isScreenActive ||
        !_isAppInForeground ||
        _isNavigatingAway ||
        _isManuallyPaused ||
        _isCommentsSheetOpen) {
      return;
    }

    debugPrint('MarketplaceFeedScreen: Starting fresh playback');

    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
      debugPrint('MarketplaceFeedScreen: Video controller playing');
    } else {
      debugPrint(
          'MarketplaceFeedScreen: Video controller not ready, attempting initialization');
      final marketplaceVideos = ref.read(marketplaceVideosProvider);
      if (marketplaceVideos.isNotEmpty &&
          _currentVideoIndex < marketplaceVideos.length) {
        setState(() {});
      }
    }

    _startIntelligentPreloading();
    WakelockPlus.enable();
  }

  void _stopPlayback() {
    debugPrint('MarketplaceFeedScreen: Stopping playback');

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

  void _initializeControllers() {
    // Controllers initialization if needed in the future
  }

  void _setupSystemUI() {
    debugPrint('MarketplaceFeedScreen: Setting up black system UI');

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

    if (widget.startItemId != null) {
      _jumpToVideo(widget.startItemId!);
    } else {
      _startIntelligentPreloading();
    }
  }

  void _jumpToVideo(String videoId) {
    final marketplaceVideos = ref.read(marketplaceVideosProvider);
    final videoIndex = marketplaceVideos
        .indexWhere((marketplaceVideo) => marketplaceVideo.id == videoId);

    if (videoIndex != -1) {
      debugPrint(
          'MarketplaceFeedScreen: Jumping to marketplaceVideo at index $videoIndex');

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(videoIndex);

          setState(() {
            _currentVideoIndex = videoIndex;
          });

          _startIntelligentPreloading();

          debugPrint(
              'MarketplaceFeedScreen: Successfully jumped to marketplaceVideo $videoId at index $videoIndex');
        }
      });
    } else {
      debugPrint(
          'MarketplaceFeedScreen: Video with ID $videoId not found in list');
    }
  }

  void _onVideoControllerReady(VideoPlayerController controller) {
    if (!mounted ||
        !_isScreenActive ||
        !_isAppInForeground ||
        _isNavigatingAway ||
        _isCommentsSheetOpen) {
      return;
    }

    debugPrint('Video controller ready, setting up fresh playback');

    setState(() {
      _currentVideoController = controller;
    });

    // Add listener to track marketplaceVideo progress
    controller.addListener(() {
      if (mounted && controller.value.isInitialized) {
        final position = controller.value.position.inMilliseconds;
        final duration = controller.value.duration.inMilliseconds;
        if (duration > 0) {
          final progress = position / duration;
          ref.read(marketplaceProgressProvider.notifier).state =
              progress.clamp(0.0, 1.0);
        }
        ref.read(isMarketplacePlayingProvider.notifier).state =
            controller.value.isPlaying;
      }
    });

    controller.seekTo(Duration.zero);

    WakelockPlus.enable();

    if (_isScreenActive &&
        _isAppInForeground &&
        !_isNavigatingAway &&
        !_isManuallyPaused &&
        !_isCommentsSheetOpen) {
      _startIntelligentPreloading();
    }
  }

  void _startFreshVideo() {
    if (!mounted ||
        !_isScreenActive ||
        !_isAppInForeground ||
        _isNavigatingAway ||
        _isManuallyPaused ||
        _isCommentsSheetOpen) {
      return;
    }

    debugPrint(
        'MarketplaceFeedScreen: Starting fresh marketplaceVideo from beginning');

    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.seekTo(Duration.zero);
      _currentVideoController!.play();
    }

    _startFreshPlayback();
  }

  void onManualPlayPause(bool isPlaying) {
    debugPrint(
        'MarketplaceFeedScreen: Manual play/pause - isPlaying: $isPlaying');
    setState(() {
      _isManuallyPaused = !isPlaying;
    });
  }

  void _onPageChanged(int index) {
    final marketplaceVideos = ref.read(marketplaceVideosProvider);
    if (index >= marketplaceVideos.length || !_isScreenActive) return;

    debugPrint('Page changed to: $index');

    setState(() {
      _currentVideoIndex = index;
      _isManuallyPaused = false;
    });

    if (_isScreenActive &&
        _isAppInForeground &&
        !_isNavigatingAway &&
        !_isManuallyPaused &&
        !_isCommentsSheetOpen) {
      _startIntelligentPreloading();
      WakelockPlus.enable();
    }

    final marketplaceNotifier = ref.read(marketplaceProvider.notifier);
    marketplaceNotifier
        .incrementMarketplaceVideoViewCount(marketplaceVideos[index].id);
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
                Positioned.fill(
                  child: _buildVideoContentOnly(),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
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
    final marketplaceVideos = ref.read(marketplaceVideosProvider);

    if (marketplaceVideos.isEmpty ||
        _currentVideoIndex >= marketplaceVideos.length) {
      return Container(color: Colors.black);
    }

    final currentVideo = marketplaceVideos[_currentVideoIndex];

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
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
        ),
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
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 32),
        ),
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
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 32),
              ),
            );
          },
        );
      },
    );
  }

  // Show comments with small marketplaceVideo window
  void _showCommentsForCurrentVideo(MarketplaceVideoModel marketplaceVideo) {
    _setVideoWindowMode(true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => MarketplaceCommentsBottomSheet(
        marketplaceVideo: marketplaceVideo,
        onClose: () {
          _setVideoWindowMode(false);
        },
      ),
    ).whenComplete(() {
      _setVideoWindowMode(false);
    });
  }

  // Show search overlay method
  void _showSearchOverlay() {
    // Pause marketplaceVideo before showing search
    _pauseForNavigation();

    MarketplaceSearchOverlayController.show(
      context,
      onVideoTap: (videoId) {
        // Jump to the selected marketplaceVideo in the feed
        _jumpToVideo(videoId);
        // Resume playback after search
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

  @override
  void dispose() {
    debugPrint('MarketplaceFeedScreen: Disposing');

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

    final marketplaceVideos = ref.watch(marketplaceVideosProvider);
    final isAppInitializing = ref.watch(isAppInitializingProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    // Show loading only while app is initializing
    if (isAppInitializing || (_isFirstLoad && marketplaceVideos.isEmpty)) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: Color(0xFF00BFA5), // Teal for marketplace
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading marketplace items...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
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
                _buildBody(marketplaceVideos),
                // Header overlay inside video area
                if (!_isCommentsSheetOpen) _buildHeaderOverlay(),
                // Small marketplaceVideo window when comments are open
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
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.6),
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
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
                              color: isSelected
                                  ? const Color(0xFF00BFA5)
                                  : Colors.transparent, // Teal indicator
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

  Widget _buildBody(List<MarketplaceVideoModel> marketplaceVideos) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: marketplaceVideos.length,
      onPageChanged: _onPageChanged,
      physics: _isScreenActive && !_isCommentsSheetOpen
          ? null
          : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final marketplaceVideo = marketplaceVideos[index];

        return MarketplaceItem(
          marketplaceVideo: marketplaceVideo,
          isActive: index == _currentVideoIndex &&
              _isScreenActive &&
              _isAppInForeground &&
              !_isNavigatingAway,
          onVideoControllerReady: _onVideoControllerReady,
          onManualPlayPause: onManualPlayPause,
          isCommentsOpen: _isCommentsSheetOpen,
          isFeedScreen: true,
          // Pass callback to show comments with small marketplaceVideo window
          onCommentsPressed: () =>
              _showCommentsForCurrentVideo(marketplaceVideo),
        );
      },
    );
  }
}

extension MarketplaceFeedScreenExtension on MarketplaceFeedScreenState {
  static void handleTabChanged(
      GlobalKey<MarketplaceFeedScreenState> feedScreenKey, bool isActive) {
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

class MarketplaceFeedController {
  final GlobalKey<MarketplaceFeedScreenState> _key;

  MarketplaceFeedController(this._key);

  void setActive(bool isActive) {
    MarketplaceFeedScreenExtension.handleTabChanged(_key, isActive);
  }

  void pause() => setActive(false);
  void resume() => setActive(true);
}
