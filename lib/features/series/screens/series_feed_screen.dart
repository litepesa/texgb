// lib/features/series/screens/series_feed_screen.dart
// REPURPOSED from channels_feed_screen.dart - Main feed showing featured episodes

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/series/providers/series_episodes_provider.dart';
import 'package:textgb/features/series/providers/series_provider.dart';
import 'package:textgb/features/series/widgets/series_episode_item.dart';
import 'package:textgb/features/series/models/series_episode_model.dart';
import 'package:textgb/features/series/services/video_cache_service.dart';
import 'package:textgb/features/series/widgets/episode_comments_bottom_sheet.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SeriesFeedScreen extends ConsumerStatefulWidget {
  final String? startEpisodeId; // For direct episode navigation
  final String? seriesId; // For series-specific filtering (optional)

  const SeriesFeedScreen({
    super.key,
    this.startEpisodeId,
    this.seriesId,
  });

  @override
  ConsumerState<SeriesFeedScreen> createState() => SeriesFeedScreenState();
}

class SeriesFeedScreenState extends ConsumerState<SeriesFeedScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver, RouteAware {
  
  // Core controllers
  final PageController _pageController = PageController();
  
  // Cache service
  final VideoCacheService _cacheService = VideoCacheService();
  
  // State management
  bool _isFirstLoad = true;
  int _currentEpisodeIndex = 0;
  bool _isScreenActive = true;
  bool _isAppInForeground = true;
  bool _hasInitialized = false;
  bool _isNavigatingAway = false;
  bool _isManuallyPaused = false;
  bool _isCommentsSheetOpen = false;
  
  VideoPlayerController? _currentVideoController;
  Timer? _cacheCleanupTimer;
  
  // Store original system UI for restoration
  SystemUiOverlayStyle? _originalSystemUiStyle;
  
  static const Duration _cacheCleanupInterval = Duration(minutes: 10);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    // Use post-frame callback to avoid provider modification during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeaturedEpisodes();
    });
    _setupCacheCleanup();
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
    
    debugPrint('SeriesFeedScreen: Screen became active');
    _isScreenActive = true;
    _isNavigatingAway = false;
    
    _setupSystemUI();
    
    if (_isAppInForeground && !_isManuallyPaused && !_isCommentsSheetOpen) {
      _startFreshPlayback();
      _startIntelligentPreloading();
      WakelockPlus.enable();
    }
  }

  void onScreenBecameInactive() {
    if (!_hasInitialized) return;
    
    debugPrint('SeriesFeedScreen: Screen became inactive');
    _isScreenActive = false;
    _stopPlayback();
    
    _restoreOriginalSystemUI();
    WakelockPlus.disable();
  }

  void _restoreOriginalSystemUI() {
    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    } else {
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
  }

  void _pauseForNavigation() {
    debugPrint('SeriesFeedScreen: Pausing for navigation');
    _isNavigatingAway = true;
    _stopPlayback();
  }

  void _resumeFromNavigation() {
    debugPrint('SeriesFeedScreen: Resuming from navigation');
    _isNavigatingAway = false;
    if (_isScreenActive && _isAppInForeground && !_isManuallyPaused && !_isCommentsSheetOpen) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_isNavigatingAway && _isScreenActive && _isAppInForeground && !_isManuallyPaused && !_isCommentsSheetOpen) {
          _startFreshPlayback();
        }
      });
    }
  }

  void _startFreshPlayback() {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isManuallyPaused || _isCommentsSheetOpen) return;
    
    debugPrint('SeriesFeedScreen: Starting fresh playback');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
      debugPrint('SeriesFeedScreen: Video controller playing');
    } else {
      debugPrint('SeriesFeedScreen: Video controller not ready, attempting initialization');
      final episodes = ref.read(seriesEpisodesProvider).featuredEpisodes;
      if (episodes.isNotEmpty && _currentEpisodeIndex < episodes.length) {
        setState(() {});
      }
    }
    
    _startIntelligentPreloading();
    WakelockPlus.enable();
  }

  void _stopPlayback() {
    debugPrint('SeriesFeedScreen: Stopping playback');
    
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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  void _setupCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(_cacheCleanupInterval, (timer) {
      _cacheService.cleanupOldCache();
    });
  }

  // Load featured episodes from all published series
  Future<void> _loadFeaturedEpisodes() async {
    if (_isFirstLoad) {
      debugPrint('SeriesFeedScreen: Loading featured episodes');
      
      await ref.read(seriesEpisodesProvider.notifier).loadFeaturedEpisodes();
      
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
        
        // If a specific episode ID was provided, jump to it
        if (widget.startEpisodeId != null) {
          _jumpToEpisode(widget.startEpisodeId!);
        }
        
        if (_isScreenActive && _isAppInForeground && !_isNavigatingAway && !_isCommentsSheetOpen) {
          Timer(const Duration(milliseconds: 500), () {
            if (mounted && _isScreenActive && _isAppInForeground && !_isNavigatingAway && !_isCommentsSheetOpen) {
              _startIntelligentPreloading();
            }
          });
        }
      }
    }
  }

  void _jumpToEpisode(String episodeId) {
    final episodes = ref.read(seriesEpisodesProvider).featuredEpisodes;
    final episodeIndex = episodes.indexWhere((episode) => episode.id == episodeId);
    
    if (episodeIndex != -1) {
      debugPrint('SeriesFeedScreen: Jumping to episode at index $episodeIndex');
      
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(episodeIndex);
          setState(() {
            _currentEpisodeIndex = episodeIndex;
          });
          debugPrint('SeriesFeedScreen: Successfully jumped to episode $episodeId at index $episodeIndex');
        }
      });
    } else {
      debugPrint('SeriesFeedScreen: Episode with ID $episodeId not found in featured episodes');
    }
  }

  void _startIntelligentPreloading() {
    if (!_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isCommentsSheetOpen) return;
    
    final episodes = ref.read(seriesEpisodesProvider).featuredEpisodes;
    if (episodes.isEmpty) return;
    
    debugPrint('Starting intelligent preloading for episode index: $_currentEpisodeIndex');
    _cacheService.preloadVideosIntelligently(episodes, _currentEpisodeIndex);
  }

  void _onVideoControllerReady(VideoPlayerController controller) {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isCommentsSheetOpen) return;
    
    debugPrint('Video controller ready, setting up fresh playback');
    
    setState(() {
      _currentVideoController = controller;
    });

    controller.seekTo(Duration.zero);
    WakelockPlus.enable();
    
    if (_isScreenActive && _isAppInForeground && !_isNavigatingAway && !_isManuallyPaused && !_isCommentsSheetOpen) {
      _startIntelligentPreloading();
    }
  }

  void onManualPlayPause(bool isPlaying) {
    debugPrint('SeriesFeedScreen: Manual play/pause - isPlaying: $isPlaying');
    setState(() {
      _isManuallyPaused = !isPlaying;
    });
  }

  void _onPageChanged(int index) {
    final episodes = ref.read(seriesEpisodesProvider).featuredEpisodes;
    if (index >= episodes.length || !_isScreenActive) return;

    debugPrint('Page changed to: $index');

    setState(() {
      _currentEpisodeIndex = index;
      _currentVideoController = null;
      _isManuallyPaused = false;
    });

    if (_isScreenActive && _isAppInForeground && !_isNavigatingAway && !_isManuallyPaused && !_isCommentsSheetOpen) {
      _startIntelligentPreloading();
      WakelockPlus.enable();
    }
    
    ref.read(seriesEpisodesProvider.notifier).incrementEpisodeViews(episodes[index].id);
  }

  // Build small video window for comments mode
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
    final episodes = ref.read(seriesEpisodesProvider).featuredEpisodes;
    
    if (episodes.isEmpty || _currentEpisodeIndex >= episodes.length) {
      return Container(color: Colors.black);
    }
    
    final currentEpisode = episodes[_currentEpisodeIndex];
    
    if (currentEpisode.isMultipleImages) {
      return _buildImageCarouselOnly(currentEpisode.imageUrls);
    } else {
      return _buildVideoPlayerOnly();
    }
  }

  Widget _buildVideoPlayerOnly() {
    if (_currentVideoController?.value.isInitialized != true) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, value: 20),
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

  @override
  void dispose() {
    debugPrint('SeriesFeedScreen: Disposing');
    
    WidgetsBinding.instance.removeObserver(this);
    _cacheCleanupTimer?.cancel();
    _pageController.dispose();
    _stopPlayback();
    _cacheService.dispose();
    _restoreOriginalSystemUI();
    WakelockPlus.disable();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    _setupSystemUI();
    
    final episodesState = ref.watch(seriesEpisodesProvider);
    final systemTopPadding = MediaQuery.of(context).padding.top;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Show loading screen during initial featured episodes loading
    if (_isFirstLoad && episodesState.isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'Loading featured episodes...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.black,
      body: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Stack(
          children: [
            // Main content
            Positioned(
              top: systemTopPadding,
              left: 0,
              right: 0,
              bottom: systemBottomPadding,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: _buildBody(episodesState),
              ),
            ),
            
            // Small video window when comments are open
            if (_isCommentsSheetOpen) _buildSmallVideoWindow(),
          
            // Top navigation
            if (!_isCommentsSheetOpen)
              Positioned(
                top: systemTopPadding + 16,
                left: 0,
                right: 0,
                child: _buildSimplifiedHeader(),
              ),
          
            // Right side menu
            if (!_isCommentsSheetOpen) _buildRightSideMenu(),
          
            // Cache debug info (debug mode only)
            if (kDebugMode && !_isCommentsSheetOpen)
              Positioned(
                top: systemTopPadding + 120,
                left: 16,
                child: _buildCacheDebugInfo(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(SeriesEpisodesState episodesState) {
    if (!episodesState.isLoading && episodesState.featuredEpisodes.isEmpty) {
      return _buildEmptyState();
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: episodesState.featuredEpisodes.length,
      onPageChanged: _onPageChanged,
      physics: _isScreenActive && !_isCommentsSheetOpen ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final episode = episodesState.featuredEpisodes[index];
        
        return SeriesEpisodeItem(
          episode: episode,
          isActive: index == _currentEpisodeIndex && _isScreenActive && _isAppInForeground && !_isNavigatingAway,
          onVideoControllerReady: _onVideoControllerReady,
          onManualPlayPause: onManualPlayPause,
          isCommentsOpen: _isCommentsSheetOpen,
          showWatchButton: true, // KEY: Show "Watch Series" button in featured feed
        );
      },
    );
  }

  Widget _buildSimplifiedHeader() {
    return Row(
      children: [
        const Spacer(),
        IconButton(
          onPressed: () {
            // TODO: Add search functionality for series
          },
          icon: const Icon(
            CupertinoIcons.search,
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
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          splashRadius: 24,
          tooltip: 'Search Series',
        ),
      ],
    );
  }

  Widget _buildRightSideMenu() {
    final episodes = ref.watch(seriesEpisodesProvider).featuredEpisodes;
    final currentEpisode = episodes.isNotEmpty && _currentEpisodeIndex < episodes.length 
        ? episodes[_currentEpisodeIndex] 
        : null;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 4,
      bottom: systemBottomPadding + 8,
      child: Column(
        children: [
          // Like button
          _buildRightMenuItem(
            child: Icon(
              currentEpisode?.isLiked == true ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: currentEpisode?.isLiked == true ? Colors.red : Colors.white,
              size: 26,
            ),
            label: _formatCount(currentEpisode?.likes ?? 0),
            onTap: () => _likeCurrentEpisode(currentEpisode),
          ),
          
          const SizedBox(height: 10),
          
          // Comment button
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.text_bubble,
              color: Colors.white,
              size: 26,
            ),
            label: _formatCount(currentEpisode?.comments ?? 0),
            onTap: () => _showCommentsForCurrentEpisode(currentEpisode),
          ),
          
          const SizedBox(height: 10),
          
          // Series avatar (rounded square with red border)
          _buildRightMenuItem(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: currentEpisode?.seriesImage.isNotEmpty == true
                    ? Image.network(
                        currentEpisode!.seriesImage,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 44,
                            height: 44,
                            color: Colors.grey,
                            child: Center(
                              child: Text(
                                currentEpisode.seriesTitle.isNotEmpty
                                    ? currentEpisode.seriesTitle[0].toUpperCase()
                                    : "S",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 44,
                        height: 44,
                        color: Colors.grey,
                        child: Center(
                          child: Text(
                            currentEpisode?.seriesTitle.isNotEmpty == true
                                ? currentEpisode!.seriesTitle[0].toUpperCase()
                                : "S",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            onTap: () => _navigateToSeriesDetails(),
          ),
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
            padding: const EdgeInsets.all(4),
            child: child,
          ),
          if (label != null) ...[
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            color: Colors.white,
            size: 80,
          ),
          SizedBox(height: 24),
          Text(
            'No Featured Episodes Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Featured episodes from published series will appear here',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToSeriesDetails() async {
    final episodes = ref.read(seriesEpisodesProvider).featuredEpisodes;
    if (_currentEpisodeIndex < episodes.length) {
      _pauseForNavigation();
      
      final result = await Navigator.of(context).pushNamed(
        Constants.seriesDetailsScreen,
        arguments: episodes[_currentEpisodeIndex].seriesId,
      );
      
      _resumeFromNavigation();
    }
  }

  void _likeCurrentEpisode(SeriesEpisodeModel? episode) async {
    if (episode != null) {
      ref.read(seriesEpisodesProvider.notifier).likeEpisode(episode.id);
    }
  }

  void _showCommentsForCurrentEpisode(SeriesEpisodeModel? episode) async {
    if (episode == null || _isCommentsSheetOpen) return;
    
    _setVideoWindowMode(true);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => EpisodeCommentsBottomSheet(
        episode: episode,
        onClose: () {
          _setVideoWindowMode(false);
        },
      ),
    ).whenComplete(() {
      _setVideoWindowMode(false);
    });
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
extension SeriesFeedScreenExtension on SeriesFeedScreenState {
  static void handleTabChanged(GlobalKey<SeriesFeedScreenState> feedScreenKey, bool isActive) {
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

class SeriesFeedController {
  final GlobalKey<SeriesFeedScreenState> _key;
  
  SeriesFeedController(this._key);
  
  void setActive(bool isActive) {
    SeriesFeedScreenExtension.handleTabChanged(_key, isActive);
  }
  
  void pause() => setActive(false);
  void resume() => setActive(true);
}