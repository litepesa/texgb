// lib/features/series/screens/series_episodes_screen.dart
// REPURPOSED from channel_feed_screen.dart - Sequential episode viewing with access control

import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/series/providers/series_episodes_provider.dart';
import 'package:textgb/features/series/providers/series_provider.dart';
import 'package:textgb/features/series/models/series_episode_model.dart';
import 'package:textgb/features/series/models/series_model.dart';
import 'package:textgb/features/series/services/video_cache_service.dart';
import 'package:textgb/features/series/widgets/episode_comments_bottom_sheet.dart';
import 'package:textgb/features/series/widgets/series_episode_item.dart';
import 'package:textgb/features/series/widgets/episode_selector_bottom_sheet.dart';
import 'package:textgb/features/series/widgets/paywall_bottom_sheet.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SeriesEpisodesScreen extends ConsumerStatefulWidget {
  final String seriesId;
  final String? startEpisodeId; // Optional: start from specific episode

  const SeriesEpisodesScreen({
    Key? key,
    required this.seriesId,
    this.startEpisodeId,
  }) : super(key: key);

  @override
  ConsumerState<SeriesEpisodesScreen> createState() => _SeriesEpisodesScreenState();
}

class _SeriesEpisodesScreenState extends ConsumerState<SeriesEpisodesScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // Core controllers
  final PageController _pageController = PageController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache service
  final VideoCacheService _cacheService = VideoCacheService();
  
  // State management
  int _currentEpisodeIndex = 0;
  bool _isAppInForeground = true;
  bool _isScreenActive = true;
  bool _isNavigatingAway = false;
  bool _isManuallyPaused = false;
  bool _isCommentsSheetOpen = false;
  
  // Series and episode data
  SeriesModel? _series;
  List<SeriesEpisodeModel> _episodes = [];
  bool _isSeriesLoading = true;
  String? _seriesError;
  bool _hasPurchased = false;
  
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
    _setupSystemUI();
    _loadSeriesData();
    _setupCacheCleanup();
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

  Future<void> _loadSeriesData() async {
    if (!mounted) return;
    
    setState(() {
      _isSeriesLoading = true;
      _seriesError = null;
    });

    try {
      // Set current series in episodes provider to track state
      ref.read(seriesEpisodesProvider.notifier).setCurrentSeries(widget.seriesId);
      
      // Get the series
      final series = await ref.read(seriesProvider.notifier).getSeriesById(widget.seriesId);
      
      if (series == null) {
        throw Exception('Series not found');
      }
      
      // Check if series is published
      if (!series.isPublished) {
        throw Exception('Series is not available yet');
      }
      
      // Load all series episodes
      final episodes = await ref.read(seriesEpisodesProvider.notifier).loadSeriesEpisodes(widget.seriesId);
      
      // Check if user has purchased the series
      final hasPurchased = ref.read(seriesProvider.notifier).isSeriesPurchased(widget.seriesId);
      
      // Find the index of the target episode if provided
      int targetIndex = 0;
      if (widget.startEpisodeId != null) {
        final foundIndex = episodes.indexWhere((episode) => episode.id == widget.startEpisodeId);
        if (foundIndex >= 0) {
          targetIndex = foundIndex;
        }
      }
      
      if (mounted) {
        setState(() {
          _series = series;
          _episodes = episodes;
          _hasPurchased = hasPurchased;
          _isSeriesLoading = false;
          _currentEpisodeIndex = targetIndex;
        });
        
        // Set the page controller to the target episode after the widget is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients && episodes.isNotEmpty) {
            _pageController.animateToPage(
              targetIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
        
        // Initialize intelligent preloading
        _startIntelligentPreloading();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _seriesError = e.toString();
          _isSeriesLoading = false;
        });
      }
    }
  }

  void _startIntelligentPreloading() {
    if (!_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isCommentsSheetOpen) return;
    
    if (_episodes.isEmpty) return;
    
    debugPrint('Starting intelligent preloading for episode index: $_currentEpisodeIndex');
    _cacheService.preloadVideosIntelligently(_episodes, _currentEpisodeIndex);
  }

  void _startFreshPlayback() {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isManuallyPaused || _isCommentsSheetOpen) return;
    
    debugPrint('SeriesEpisodesScreen: Starting fresh playback');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
      debugPrint('SeriesEpisodesScreen: Video controller playing');
    } else {
      debugPrint('SeriesEpisodesScreen: Video controller not ready, attempting initialization');
      if (_episodes.isNotEmpty && _currentEpisodeIndex < _episodes.length) {
        setState(() {});
      }
    }
    
    _startIntelligentPreloading();
    WakelockPlus.enable();
  }

  void _stopPlayback() {
    debugPrint('SeriesEpisodesScreen: Stopping playback');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.pause();
      if (!_isCommentsSheetOpen) {
        _currentVideoController!.seekTo(Duration.zero);
      }
    }
  }

  void _pauseForNavigation() {
    debugPrint('SeriesEpisodesScreen: Pausing for navigation');
    _isNavigatingAway = true;
    _stopPlayback();
  }

  void _resumeFromNavigation() {
    debugPrint('SeriesEpisodesScreen: Resuming from navigation');
    _isNavigatingAway = false;
    if (_isScreenActive && _isAppInForeground && !_isManuallyPaused && !_isCommentsSheetOpen) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_isNavigatingAway && _isScreenActive && _isAppInForeground && !_isManuallyPaused && !_isCommentsSheetOpen) {
          _startFreshPlayback();
        }
      });
    }
  }

  void _setVideoWindowMode(bool isSmallWindow) {
    setState(() {
      _isCommentsSheetOpen = isSmallWindow;
    });
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
    if (_episodes.isEmpty || _currentEpisodeIndex >= _episodes.length) {
      return Container(color: Colors.black);
    }
    
    final currentEpisode = _episodes[_currentEpisodeIndex];
    
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
          child: CircularProgressIndicator(color: Colors.white),
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
    debugPrint('SeriesEpisodesScreen: Manual play/pause - isPlaying: $isPlaying');
    setState(() {
      _isManuallyPaused = !isPlaying;
    });
  }

  void _onPageChanged(int index) {
    if (index >= _episodes.length || !_isScreenActive) return;

    debugPrint('Episode page changed to: $index');

    // Check access before allowing navigation
    if (_series != null && !_canAccessEpisode(_episodes[index].episodeNumber)) {
      // User tried to access locked episode, show paywall
      _showPaywallDialog(_episodes[index]);
      
      // Revert to previous accessible episode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.animateToPage(
            _currentEpisodeIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
      return;
    }

    setState(() {
      _currentEpisodeIndex = index;
      _currentVideoController = null;
      _isManuallyPaused = false;
    });

    if (_isScreenActive && _isAppInForeground && !_isNavigatingAway && !_isManuallyPaused && !_isCommentsSheetOpen) {
      _startIntelligentPreloading();
      WakelockPlus.enable();
    }
    
    ref.read(seriesEpisodesProvider.notifier).incrementEpisodeViews(_episodes[index].id);
  }

  // Check if user can access a specific episode
  bool _canAccessEpisode(int episodeNumber) {
    if (_series == null) return false;
    return ref.read(seriesProvider.notifier).canAccessEpisode(_series!, episodeNumber);
  }

  // Show paywall dialog for locked episodes
  void _showPaywallDialog(SeriesEpisodeModel episode) {
    if (_series == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaywallBottomSheet(
        series: _series!,
        lockedEpisode: episode,
        onPurchaseSuccess: () {
          // Refresh series data after purchase
          _loadSeriesData();
        },
      ),
    );
  }

  // Enhanced back navigation with proper system UI restoration
  void _handleBackNavigation() {
    if (_isCommentsSheetOpen) {
      Navigator.of(context).pop();
      return;
    }
    
    _stopPlayback();
    
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
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // Navigate to series details/profile
  void _navigateToSeriesProfile() async {
    if (_series == null) return;
    
    _pauseForNavigation();
    
    await Navigator.pushNamed(
      context,
      Constants.seriesDetailsScreen,
      arguments: _series!.id,
    );
    
    _resumeFromNavigation();
  }

  // Show episode selector bottom sheet
  void _showEpisodeSelector() {
    if (_series == null || _episodes.isEmpty) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EpisodeSelectorBottomSheet(
        series: _series!,
        episodes: _episodes,
        currentEpisodeIndex: _currentEpisodeIndex,
        hasPurchased: _hasPurchased,
        onEpisodeSelected: (index) {
          if (_canAccessEpisode(_episodes[index].episodeNumber)) {
            // Navigate to selected episode
            setState(() {
              _currentEpisodeIndex = index;
            });
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pageController.hasClients) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            });
          } else {
            // Show paywall for locked episode
            _showPaywallDialog(_episodes[index]);
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    _stopPlayback();
    
    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    } else if (mounted) {
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
    _pageController.dispose();
    WakelockPlus.disable();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isSeriesLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    if (_seriesError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildErrorState(),
      );
    }
    
    final systemTopPadding = MediaQuery.of(context).padding.top;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    
    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Stack(
            children: [
              // Main episode content
              Positioned(
                top: systemTopPadding,
                left: 0,
                right: 0,
                bottom: systemBottomPadding,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  child: _buildEpisodesFeed(),
                ),
              ),
              
              // Small video window when comments are open
              if (_isCommentsSheetOpen) _buildSmallVideoWindow(),
              
              // Top navigation
              if (!_isCommentsSheetOpen)
                Positioned(
                  top: systemTopPadding + 16,
                  left: 0,
                  right: 16,
                  child: _buildSeriesHeader(),
                ),
              
              // Right side menu with episode selector
              if (!_isCommentsSheetOpen) _buildRightSideMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodesFeed() {
    if (_episodes.isEmpty) {
      return _buildEmptyState();
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _episodes.length,
      onPageChanged: _onPageChanged,
      physics: _isScreenActive && !_isCommentsSheetOpen ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final episode = _episodes[index];
        final canAccess = _canAccessEpisode(episode.episodeNumber);
        
        return SeriesEpisodeItem(
          episode: episode,
          isActive: index == _currentEpisodeIndex && _isScreenActive && _isAppInForeground && !_isNavigatingAway,
          onVideoControllerReady: _onVideoControllerReady,
          onManualPlayPause: onManualPlayPause,
          isCommentsOpen: _isCommentsSheetOpen,
          showWatchButton: false, // No watch button in episode view
          showLockOverlay: !canAccess, // Show lock overlay for inaccessible episodes
        );
      },
    );
  }

  Widget _buildSeriesHeader() {
    return Row(
      children: [
        // Series info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_series != null) ...[
                Text(
                  _series!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                if (_episodes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Episode ${_episodes[_currentEpisodeIndex].episodeNumber} of ${_episodes.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        
        // Back button
        GestureDetector(
          onTap: _handleBackNavigation,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.arrow_left,
                color: Colors.white,
                size: 14,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Text(
                'Back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightSideMenu() {
    final currentEpisode = _episodes.isNotEmpty && _currentEpisodeIndex < _episodes.length 
        ? _episodes[_currentEpisodeIndex] 
        : null;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 4,
      bottom: systemBottomPadding + 8,
      child: Column(
        children: [
          // Episode selector button (NEW)
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.list_bullet,
              color: Colors.white,
              size: 26,
            ),
            label: 'Episodes',
            onTap: _showEpisodeSelector,
          ),
          
          const SizedBox(height: 10),
          
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
          
          // Series profile avatar
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
                child: _series?.thumbnailImage.isNotEmpty == true
                    ? Image.network(
                        _series!.thumbnailImage,
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
                                _series?.title.isNotEmpty == true
                                    ? _series!.title[0].toUpperCase()
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
                            _series?.title.isNotEmpty == true
                                ? _series!.title[0].toUpperCase()
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
            onTap: () => _navigateToSeriesProfile(),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.play_circle_outline, color: Colors.white, size: 80),
          const SizedBox(height: 24),
          const Text(
            'No Episodes Yet',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _series?.creatorId == _auth.currentUser?.uid
                ? 'Start creating episodes for your series'
                : 'This series doesn\'t have any episodes yet',
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 16),
            textAlign: TextAlign.center,
          ),
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
            'Error Loading Series',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _seriesError!,
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

  void _likeCurrentEpisode(SeriesEpisodeModel? episode) {
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
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}