// ===============================
// Channels Feed Screen
// TikTok-style vertical feed for channel videos
// Uses GoRouter for navigation
// ===============================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/channels/services/video_cache_service.dart';
import 'package:textgb/features/channels/widgets/video_item.dart';
import 'package:textgb/features/channels/models/video_model.dart';
import 'package:textgb/features/channels/providers/channel_provider.dart';
import 'package:textgb/features/comments/widgets/comments_bottom_sheet.dart';
import 'package:textgb/features/gifts/widgets/virtual_gifts_bottom_sheet.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class ChannelsFeedScreen extends ConsumerStatefulWidget {
  final String? startVideoId; // For direct video navigation

  const ChannelsFeedScreen({
    super.key,
    this.startVideoId,
  });

  @override
  ConsumerState<ChannelsFeedScreen> createState() => ChannelsFeedScreenState();
}

class ChannelsFeedScreenState extends ConsumerState<ChannelsFeedScreen>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin,
        WidgetsBindingObserver {
  // Core controllers
  final PageController _pageController = PageController();

  // State management
  bool _isFirstLoad = true;
  int _currentVideoIndex = 0;
  bool _isScreenActive = true;
  bool _isAppInForeground = true;
  bool _hasInitialized = false;
  bool _isNavigatingAway = false;
  bool _isManuallyPaused = false;
  bool _isCommentsSheetOpen = false;

  // Download state management
  final Map<String, bool> _downloadingVideos = {};
  final Map<String, double> _downloadProgress = {};

  // Video controllers
  VideoPlayerController? _currentVideoController;
  Timer? _cacheCleanupTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCacheCleanup();

    // Handle initial video position and start precaching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialVideoPosition();
      _precacheInitialVideos(); // Start precaching immediately
    });

    _hasInitialized = true;
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

    debugPrint('ChannelsFeedScreen: Screen became active');
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

    debugPrint('ChannelsFeedScreen: Screen became inactive');
    _isScreenActive = false;
    _stopPlayback();

    _restoreOriginalSystemUI();

    WakelockPlus.disable();
  }

  void _restoreOriginalSystemUI() {
    debugPrint('ChannelsFeedScreen: Restoring original system UI');

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
    debugPrint('ChannelsFeedScreen: Pausing for navigation');
    _isNavigatingAway = true;
    _stopPlayback();
  }

  void _resumeFromNavigation() {
    debugPrint('ChannelsFeedScreen: Resuming from navigation');
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

  // Precache initial videos as soon as they load
  void _precacheInitialVideos() {
    final feedState = ref.read(videoFeedProvider).value;
    if (feedState == null || feedState.videos.isEmpty) return;

    debugPrint('Precaching initial videos for instant playback...');

    // Get first 3 video URLs (skip image posts)
    final videoUrls = feedState.videos
        .where((v) => !v.isMultipleImages && v.videoUrl.isNotEmpty)
        .take(3)
        .map((v) => v.videoUrl)
        .toList();

    if (videoUrls.isNotEmpty) {
      VideoCacheService().precacheMultiple(
        videoUrls,
        cacheSegmentsPerVideo: 3, // Cache 6MB per video for instant start
        maxConcurrent: 2,
      );
    }
  }

  // Intelligent preloading with filtering for video-only content
  void _startIntelligentPreloading() {
    if (!_isScreenActive ||
        !_isAppInForeground ||
        _isNavigatingAway ||
        _isCommentsSheetOpen) {
      return;
    }

    final feedState = ref.read(videoFeedProvider).value;
    if (feedState == null || feedState.videos.isEmpty) return;

    debugPrint(
        'Starting intelligent preloading for index: $_currentVideoIndex');

    // Filter to get only actual videos (no image posts)
    final videoOnlyList = feedState.videos
        .where((v) => !v.isMultipleImages && v.videoUrl.isNotEmpty)
        .toList();

    if (videoOnlyList.isEmpty) return;

    // Find current video in the filtered list
    final currentVideo = feedState.videos[_currentVideoIndex];

    // If current item is an image post, find nearest video
    if (currentVideo.isMultipleImages) {
      debugPrint('Current item is image post, skipping preload');
      return;
    }

    final currentIndexInVideoList =
        videoOnlyList.indexWhere((v) => v.videoUrl == currentVideo.videoUrl);

    if (currentIndexInVideoList == -1) return;

    final videoUrls = videoOnlyList.map((v) => v.videoUrl).toList();

    VideoCacheService().intelligentPreload(
      videoUrls: videoUrls,
      currentIndex: currentIndexInVideoList,
      preloadNext: 5, // Preload next 5 videos
      preloadPrevious: 2, // Preload previous 2 videos
      cacheSegmentsPerVideo: 3, // 6MB per video
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

    debugPrint('ChannelsFeedScreen: Starting fresh playback');

    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
      debugPrint('ChannelsFeedScreen: Video controller playing');
    } else {
      debugPrint(
          'ChannelsFeedScreen: Video controller not ready, attempting initialization');
      final feedState = ref.read(videoFeedProvider).value;
      if (feedState != null &&
          feedState.videos.isNotEmpty &&
          _currentVideoIndex < feedState.videos.length) {
        setState(() {});
      }
    }

    _startIntelligentPreloading();
    WakelockPlus.enable();
  }

  void _stopPlayback() {
    debugPrint('ChannelsFeedScreen: Stopping playback');

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

  void _setupSystemUI() {
    debugPrint('ChannelsFeedScreen: Setting up black system UI');

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
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
    final feedState = ref.read(videoFeedProvider).value;
    if (feedState == null) return;

    final videoIndex =
        feedState.videos.indexWhere((video) => video.id == videoId);

    if (videoIndex != -1) {
      debugPrint('ChannelsFeedScreen: Jumping to video at index $videoIndex');

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(videoIndex);

          setState(() {
            _currentVideoIndex = videoIndex;
          });

          _startIntelligentPreloading();

          debugPrint(
              'ChannelsFeedScreen: Successfully jumped to video $videoId at index $videoIndex');
        }
      });
    } else {
      debugPrint('ChannelsFeedScreen: Video with ID $videoId not found in list');
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

  void onManualPlayPause(bool isPlaying) {
    debugPrint('ChannelsFeedScreen: Manual play/pause - isPlaying: $isPlaying');
    setState(() {
      _isManuallyPaused = !isPlaying;
    });
  }

  void _onPageChanged(int index) {
    final feedState = ref.read(videoFeedProvider).value;
    if (feedState == null ||
        index >= feedState.videos.length ||
        !_isScreenActive) return;

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

    // TODO: Track video view
    // await channelRepository.trackVideoView(feedState.videos[index].id);
  }

  Widget _buildSmallVideoWindow() {
    final systemTopPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: systemTopPadding + 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
          context.pop(); // GoRouter
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
    final feedState = ref.read(videoFeedProvider).value;
    if (feedState == null ||
        feedState.videos.isEmpty ||
        _currentVideoIndex >= feedState.videos.length) {
      return Container(color: Colors.black);
    }

    final currentVideo = feedState.videos[_currentVideoIndex];

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

  void _showVirtualGifts(VideoModel? video) async {
    if (video == null) {
      debugPrint('No video available for gifting');
      return;
    }

    final canInteract = await _requireAuthentication('send gifts');
    if (!canInteract) return;

    final currentUser = ref.read(currentUserProvider);

    // Get user's channel to check if they own this channel
    final myChannel = await ref.read(myChannelProvider.future);
    if (myChannel != null && video.channelId == myChannel.id) {
      _showCannotGiftOwnVideoMessage();
      return;
    }

    _pauseForNavigation();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VirtualGiftsBottomSheet(
        recipientName: video.channelName,
        recipientImage: video.channelAvatar,
        onGiftSelected: (gift) {
          _handleGiftSent(video, gift);
        },
        onClose: () {
          _resumeFromNavigation();
        },
      ),
    ).whenComplete(() {
      _resumeFromNavigation();
    });
  }

  Future<bool> _requireAuthentication(String actionName) async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);

    if (!isAuthenticated) {
      final result = await requireLogin(
        context,
        ref,
        customTitle: 'Sign In Required',
        customSubtitle: 'Please sign in to $actionName.',
        customActionText: 'Sign In',
        customIcon: _getIconForAction(actionName),
      );
      return result;
    }

    return true;
  }

  IconData _getIconForAction(String actionName) {
    switch (actionName.toLowerCase()) {
      case 'like videos':
      case 'like':
        return Icons.favorite;
      case 'comment':
      case 'comment on videos':
        return Icons.comment;
      case 'send gifts':
      case 'gift':
        return Icons.card_giftcard;
      case 'download videos':
      case 'download':
        return Icons.download;
      case 'share videos':
      case 'share':
        return Icons.share;
      default:
        return Icons.video_call;
    }
  }

  void _handleGiftSent(VideoModel video, VirtualGift gift) {
    debugPrint(
        'Gift sent: ${gift.name} (KES ${gift.price}) to ${video.channelName}');
    _showSnackBar('${gift.emoji} ${gift.name} sent to ${video.channelName}!');
  }

  void _showCannotGiftOwnVideoMessage() {
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
            const Icon(
              Icons.card_giftcard,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot Gift Your Own Video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You cannot send gifts to your own channel.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.pop(), // GoRouter
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    debugPrint('ChannelsFeedScreen: Disposing');

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

    final feedAsync = ref.watch(videoFeedProvider);

    return feedAsync.when(
      data: (feedState) {
        if (_isFirstLoad && feedState.videos.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading videos...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
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
          body: Stack(
            children: [
              // Full screen video - NO padding, NO ClipRRect
              Positioned.fill(
                child: _buildBody(feedState.videos),
              ),

              if (_isCommentsSheetOpen) _buildSmallVideoWindow(),

              if (!_isCommentsSheetOpen)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 0,
                  right: 0,
                  child: _buildSimplifiedHeader(),
                ),

              if (!_isCommentsSheetOpen) _buildRightSideMenu(),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load feed: $error',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(videoFeedProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
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
      physics: _isScreenActive && !_isCommentsSheetOpen
          ? null
          : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final video = videos[index];

        return VideoItem(
          video: video,
          isActive: index == _currentVideoIndex &&
              _isScreenActive &&
              _isAppInForeground &&
              !_isNavigatingAway,
          onVideoControllerReady: _onVideoControllerReady,
          onManualPlayPause: onManualPlayPause,
          isCommentsOpen: _isCommentsSheetOpen,
          isFeedScreen: true,
        );
      },
    );
  }

  Widget _buildSimplifiedHeader() {
    final systemTopPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: systemTopPadding,
      left: 0,
      right: 0,
      child: Row(
        children: [
          const SizedBox(width: 56),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Channels',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
              ],
            ),
          ),
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  Widget _buildRightSideMenu() {
    final feedState = ref.watch(videoFeedProvider).value;
    final currentVideo = feedState != null &&
            feedState.videos.isNotEmpty &&
            _currentVideoIndex < feedState.videos.length
        ? feedState.videos[_currentVideoIndex]
        : null;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 0.5,
      bottom: systemBottomPadding,
      child: Column(
        children: [
          // Like button
          _buildRightMenuItem(
            child: Icon(
              currentVideo?.isLiked == true
                  ? CupertinoIcons.heart_fill
                  : CupertinoIcons.heart,
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
              CupertinoIcons.text_bubble,
              color: Colors.white,
              size: 26,
            ),
            label: _formatCount(currentVideo?.comments ?? 0),
            onTap: () => _showCommentsForCurrentVideo(currentVideo),
          ),

          const SizedBox(height: 10),

          // Download button
          _buildRightMenuItem(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_downloadingVideos[currentVideo?.id] == true)
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      value: _downloadProgress[currentVideo?.id] ?? 0.0,
                      color: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      strokeWidth: 2,
                    ),
                  )
                else
                  const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 26,
                  ),
              ],
            ),
            label: _downloadingVideos[currentVideo?.id] == true
                ? '${((_downloadProgress[currentVideo?.id] ?? 0.0) * 100).toInt()}%'
                : 'Save',
            onTap: () => _downloadCurrentVideo(currentVideo),
          ),

          const SizedBox(height: 10),

          // Gift button
          _buildRightMenuItem(
            child: const Text(
              '🎁',
              style: TextStyle(
                fontSize: 28,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            onTap: () => _showVirtualGifts(currentVideo),
          ),

          const SizedBox(height: 10),

          // Channel avatar
          _buildRightMenuItem(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: currentVideo?.channelAvatar.isNotEmpty == true
                    ? Image.network(
                        currentVideo!.channelAvatar,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 44,
                            height: 44,
                            color: Colors.grey[800],
                            child: Center(
                              child: Text(
                                currentVideo.channelName.isNotEmpty
                                    ? currentVideo.channelName[0].toUpperCase()
                                    : 'C',
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
                        color: Colors.grey[800],
                        child: Center(
                          child: Text(
                            currentVideo?.channelName.isNotEmpty == true
                                ? currentVideo!.channelName[0].toUpperCase()
                                : 'C',
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
            onTap: () => _navigateToChannelProfile(),
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

  void _navigateToChannelProfile() async {
    final feedState = ref.read(videoFeedProvider).value;
    if (feedState != null && _currentVideoIndex < feedState.videos.length) {
      _pauseForNavigation();

      final channelId = feedState.videos[_currentVideoIndex].channelId;
      context.push(RoutePaths.channelProfile(channelId)); // GoRouter

      // Resume after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _resumeFromNavigation();
        }
      });
    }
  }

  void _likeCurrentVideo(VideoModel? video) async {
    if (video == null) return;

    final canInteract = await _requireAuthentication('like videos');
    if (!canInteract) return;

    await ref
        .read(videoFeedProvider.notifier)
        .toggleLike(video.id, video.isLiked);
  }

  void _showCommentsForCurrentVideo(VideoModel? video) async {
    if (video == null || _isCommentsSheetOpen) return;

    final canInteract = await _requireAuthentication('comment on videos');
    if (!canInteract) return;

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

  Future<void> _downloadCurrentVideo(VideoModel? video) async {
    if (video == null) return;

    final canInteract = await _requireAuthentication('download videos');
    if (!canInteract) return;

    if (_downloadingVideos[video.id] == true) {
      _showSnackBar('Video is already downloading...');
      return;
    }

    if (video.isMultipleImages) {
      _showSnackBar('Cannot download image posts');
      return;
    }

    if (video.videoUrl.isEmpty) {
      _showSnackBar('Invalid video URL');
      return;
    }

    try {
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showSnackBar('Storage permission required to download videos');
        return;
      }

      await _downloadVideo(video);
    } catch (e) {
      debugPrint('Error downloading video: $e');
      _showSnackBar('Failed to download video');
      setState(() {
        _downloadingVideos[video.id] = false;
        _downloadProgress.remove(video.id);
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await [
          Permission.videos,
          Permission.photos,
        ].request();

        return status.values.every((status) => status.isGranted);
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    return true;
  }

  Future<void> _downloadVideo(VideoModel video) async {
    setState(() {
      _downloadingVideos[video.id] = true;
      _downloadProgress[video.id] = 0.0;
    });

    try {
      final dio = Dio();

      Directory? directory;
      String fileName =
          'textgb_${video.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      final savePath = '${directory.path}/$fileName';

      await dio.download(
        video.videoUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            setState(() {
              _downloadProgress[video.id] = progress;
            });
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          },
        ),
      );

      setState(() {
        _downloadingVideos[video.id] = false;
        _downloadProgress.remove(video.id);
      });

      _showSnackBar('Video saved successfully!');
    } catch (e) {
      debugPrint('Download error: $e');
      setState(() {
        _downloadingVideos[video.id] = false;
        _downloadProgress.remove(video.id);
      });

      _showSnackBar('Download failed. Please try again.');
    }
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
  static void handleTabChanged(
      GlobalKey<ChannelsFeedScreenState> feedScreenKey, bool isActive) {
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
