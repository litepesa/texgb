// lib/features/videos/screens/videos_feed_screen.dart - COMPLETE UPDATED VERSION WITH FULL SCREEN VIDEO

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/videos/services/video_cache_service.dart';
import 'package:textgb/features/videos/widgets/video_item.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/comments/widgets/comments_bottom_sheet.dart';
import 'package:textgb/features/gifts/widgets/virtual_gifts_bottom_sheet.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
// Import search overlay
import 'package:textgb/features/videos/widgets/search_overlay.dart';

class VideosFeedScreen extends ConsumerStatefulWidget {
  final String? startVideoId; // For direct video navigation
  final String? userId; // For user-specific filtering (optional)

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
    
    // Handle initial video position and start precaching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialVideoPosition();
      _precacheInitialVideos(); // Start precaching immediately
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
    debugPrint('VideosFeedScreen: Restoring original system UI');
    
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
    debugPrint('VideosFeedScreen: Pausing for navigation');
    _isNavigatingAway = true;
    _stopPlayback();
  }

  void _resumeFromNavigation() {
    debugPrint('VideosFeedScreen: Resuming from navigation');
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

  // NEW: Precache initial videos as soon as they load
  void _precacheInitialVideos() {
    final videos = ref.read(videosProvider);
    if (videos.isEmpty) return;

    debugPrint('Precaching initial videos for instant playback...');
    
    // Get first 3 video URLs (skip image posts)
    final videoUrls = videos
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

  // UPDATED: Intelligent preloading with filtering for video-only content
  void _startIntelligentPreloading() {
    if (!_isScreenActive ||
        !_isAppInForeground ||
        _isNavigatingAway ||
        _isCommentsSheetOpen) {
      return;
    }

    final videos = ref.read(videosProvider);
    if (videos.isEmpty) return;

    debugPrint('Starting intelligent preloading for index: $_currentVideoIndex');
    
    // Filter to get only actual videos (no image posts)
    final videoOnlyList = videos
        .where((v) => !v.isMultipleImages && v.videoUrl.isNotEmpty)
        .toList();
    
    if (videoOnlyList.isEmpty) return;
    
    // Find current video in the filtered list
    final currentVideo = videos[_currentVideoIndex];
    
    // If current item is an image post, find nearest video
    if (currentVideo.isMultipleImages) {
      debugPrint('Current item is image post, skipping preload');
      return;
    }
    
    final currentIndexInVideoList = videoOnlyList
        .indexWhere((v) => v.videoUrl == currentVideo.videoUrl);
    
    if (currentIndexInVideoList == -1) return;
    
    final videoUrls = videoOnlyList.map((v) => v.videoUrl).toList();
    
    VideoCacheService().intelligentPreload(
      videoUrls: videoUrls,
      currentIndex: currentIndexInVideoList,
      preloadNext: 5,           // Preload next 5 videos
      preloadPrevious: 2,       // Preload previous 2 videos
      cacheSegmentsPerVideo: 3, // 6MB per video (increased from 2)
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

    debugPrint('VideosFeedScreen: Starting fresh playback');

    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
      debugPrint('VideosFeedScreen: Video controller playing');
    } else {
      debugPrint('VideosFeedScreen: Video controller not ready, attempting initialization');
      final videos = ref.read(videosProvider);
      if (videos.isNotEmpty && _currentVideoIndex < videos.length) {
        setState(() {});
      }
    }

    _startIntelligentPreloading();
    WakelockPlus.enable();
  }

  void _stopPlayback() {
    debugPrint('VideosFeedScreen: Stopping playback');

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
    debugPrint('VideosFeedScreen: Setting up black system UI');
    
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
    final videos = ref.read(videosProvider);
    final videoIndex = videos.indexWhere((video) => video.id == videoId);

    if (videoIndex != -1) {
      debugPrint('VideosFeedScreen: Jumping to video at index $videoIndex');

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(videoIndex);

          setState(() {
            _currentVideoIndex = videoIndex;
          });

          _startIntelligentPreloading();

          debugPrint('VideosFeedScreen: Successfully jumped to video $videoId at index $videoIndex');
        }
      });
    } else {
      debugPrint('VideosFeedScreen: Video with ID $videoId not found in list');
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

  void _startFreshVideo() {
    if (!mounted ||
        !_isScreenActive ||
        !_isAppInForeground ||
        _isNavigatingAway ||
        _isManuallyPaused ||
        _isCommentsSheetOpen) {
      return;
    }

    debugPrint('VideosFeedScreen: Starting fresh video from beginning');

    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.seekTo(Duration.zero);
      _currentVideoController!.play();
    }

    _startFreshPlayback();
  }

  void onManualPlayPause(bool isPlaying) {
    debugPrint('VideosFeedScreen: Manual play/pause - isPlaying: $isPlaying');
    setState(() {
      _isManuallyPaused = !isPlaying;
    });
  }

  void _onPageChanged(int index) {
    final videos = ref.read(videosProvider);
    if (index >= videos.length || !_isScreenActive) return;

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

    final authNotifier = ref.read(authenticationProvider.notifier);
    authNotifier.incrementViewCount(videos[index].id);
  }

  UserModel? _getUserDataIfAvailable() {
    final users = ref.read(usersProvider);
    final isUsersLoading = ref.read(isAuthLoadingProvider);

    if (isUsersLoading || users.isEmpty) {
      return null;
    }

    try {
      final videos = ref.read(videosProvider);
      final currentVideo =
          videos.isNotEmpty && _currentVideoIndex < videos.length
              ? videos[_currentVideoIndex]
              : null;

      if (currentVideo == null) return null;

      return users.firstWhere(
        (user) => user.uid == currentVideo.userId,
      );
    } catch (e) {
      return null;
    }
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

  Future<void> _openWhatsAppWithVideo(VideoModel? video) async {
    if (video == null) return;

    final currentUser = ref.read(currentUserProvider);

    if (video.userId == currentUser!.uid) {
      _showCannotMessageOwnVideoMessage();
      return;
    }

    try {
      _pauseForNavigation();

      final authNotifier = ref.read(authenticationProvider.notifier);
      final videoCreator = await authNotifier.getUserById(video.userId);

      if (videoCreator == null) {
        _showUserNotFoundMessage();
        return;
      }

      if (!videoCreator.hasWhatsApp) {
        _showWhatsAppNotAvailableMessage(videoCreator.name);
        return;
      }

      final videoLink = 'https://share.weibao.africa/v/${video.id}';
      
      String message = '$videoLink\n\nHi ${videoCreator.name}! I saw your video';
      
      if (video.caption.isNotEmpty) {
        String caption = video.caption;
        if (caption.length > 50) {
          caption = '${caption.substring(0, 50)}...';
        }
        message += ' about "$caption"';
      }
      
      message += ' and wanted to chat!';

      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/${videoCreator.whatsappNumber}?text=$encodedMessage';
      final uri = Uri.parse(whatsappUrl);

      debugPrint('Opening WhatsApp with URL: $whatsappUrl');

      try {
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (success) {
          _showSnackBar('Opening WhatsApp to contact ${videoCreator.name}...');
        } else {
          _showWhatsAppNotInstalledMessage();
        }
      } catch (e) {
        debugPrint('Failed to launch WhatsApp: $e');
        _showWhatsAppNotInstalledMessage();
      }
    } catch (e) {
      debugPrint('Error opening WhatsApp: $e');
      _showSnackBar('Failed to open WhatsApp');
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _resumeFromNavigation();
        }
      });
    }
  }

  void _showUserNotFoundMessage() {
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off,
                color: Colors.orange,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'User Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Could not find the video owner\'s profile. Please try again later.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
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

  void _showWhatsAppNotAvailableMessage(String userName) {
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_off,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'WhatsApp Link Not Added',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$userName hasn\'t added their WhatsApp number to their profile yet.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWhatsAppNotInstalledMessage() {
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.message,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'WhatsApp Not Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please install WhatsApp to send messages or check your internet connection.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
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

    if (video.userId == currentUser!.uid) {
      _showCannotGiftOwnVideoMessage();
      return;
    }

    _pauseForNavigation();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VirtualGiftsBottomSheet(
        recipientName: video.userName,
        recipientImage: video.userImage,
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
      case 'message on whatsapp':
      case 'whatsapp':
        return Icons.message;
      default:
        return Icons.video_call;
    }
  }

  void _handleGiftSent(VideoModel video, VirtualGift gift) {
    debugPrint('Gift sent: ${gift.name} (KES ${gift.price}) to ${video.userName}');
    _showSnackBar('${gift.emoji} ${gift.name} sent to ${video.userName}!');
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
              'You cannot send gifts to your own videos.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
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

  void _showCannotMessageOwnVideoMessage() {
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.message,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot Message Yourself',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You cannot send a WhatsApp message to your own video.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  // Show search overlay method
  void _showSearchOverlay() {
    // Pause video before showing search
    _pauseForNavigation();
    
    SearchOverlayController.show(
      context,
      onVideoTap: (videoId) {
        // Jump to the selected video in the feed
        _jumpToVideo(videoId);
        // Resume playback after search
        _resumeFromNavigation();
      },
    );
  }

  @override
  void dispose() {
    debugPrint('VideosFeedScreen: Disposing');

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

    // Show loading only while app is initializing
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
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading videos...',
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
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen video - NO padding, NO ClipRRect
          Positioned.fill(
            child: _buildBody(videos),
          ),

          if (_isCommentsSheetOpen) _buildSmallVideoWindow(),

          if (!_isCommentsSheetOpen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 0,
              right: 0,
              child: _buildSimplifiedHeader(),
            ),

          if (!_isCommentsSheetOpen)
            _buildRightSideMenu(),
        ],
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
  // Get system top padding for proper alignment
  final systemTopPadding = MediaQuery.of(context).padding.top;
  
  return Positioned(
    top: systemTopPadding,  // System padding + 16 offset
    left: 0,
    right: 0,
    child: Row(
      children: [
        const SizedBox(width: 56),

        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
            ],
          ),
        ),

        // Search button
        IconButton(
          onPressed: _showSearchOverlay,
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
          tooltip: 'Search',
        ),
      ],
    ),
  );
}

  Widget _buildRightSideMenu() {
    final videos = ref.watch(videosProvider);
    final currentVideo = videos.isNotEmpty && _currentVideoIndex < videos.length
        ? videos[_currentVideoIndex]
        : null;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 0.5,
      bottom: systemBottomPadding,
      child: Column(
        children: [
          // WhatsApp button
          /*GestureDetector(
            onTap: () => _openWhatsAppWithVideo(currentVideo),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  child: Lottie.asset(
                    'assets/lottie/chat_bubble.json',
                    width: 58,
                    height: 58,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),*/

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

          // Share button
          /*_buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.arrowshape_turn_up_right,
              color: Colors.white,
              size: 26,
            ),
            label: '0',
            onTap: () => _showShareOptions(),
          ),
          
          const SizedBox(height: 10),

          // DM button - custom white rounded square with 'DM' text
          _buildRightMenuItem(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'DM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            label: 'Inbox',
            onTap: () {
              // TODO: Add DM functionality
            },
          ),*/

          // Gift button
          /*_buildRightMenuItem(
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

          const SizedBox(height: 10),*/

          // Profile avatar
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
                child: currentVideo?.userImage.isNotEmpty == true
                    ? Image.network(
                        currentVideo!.userImage,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Center(
                              child: Text(
                                currentVideo.userName.isNotEmpty == true
                                    ? currentVideo.userName[0].toUpperCase()
                                    : 'U',
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
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(
                          child: Text(
                            currentVideo?.userName.isNotEmpty == true
                                ? currentVideo!.userName[0].toUpperCase()
                                : 'U',
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
            onTap: () => _navigateToUserProfile(),
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

  void _navigateToUserProfile() async {
    final videos = ref.read(videosProvider);
    if (_currentVideoIndex < videos.length) {
      _pauseForNavigation();

      final result = await Navigator.of(context).pushNamed(
        Constants.userProfileScreen,
        arguments: videos[_currentVideoIndex].userId,
      );

      _resumeFromNavigation();
    }
  }

  void _likeCurrentVideo(VideoModel? video) async {
    if (video == null) return;

    final canInteract = await _requireAuthentication('like videos');
    if (!canInteract) return;

    final authNotifier = ref.read(authenticationProvider.notifier);
    authNotifier.likeVideo(video.id);
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

  Future<void> _shareCurrentVideo(VideoModel? video) async {
    if (video == null) return;

    try {
      String shareText = '';

      if (video.caption.isNotEmpty) {
        shareText += video.caption;
      }

      if (shareText.isNotEmpty) {
        shareText += '\n\n';
      }
      shareText += 'Check out this video by ${video.userName}!';

      if (video.tags.isNotEmpty) {
        shareText += '\n\n${video.tags.map((tag) => '#$tag').join(' ')}';
      }

      shareText += '\n\nShared via TextGB';

      final RenderBox? box = context.findRenderObject() as RenderBox?;

      final result = await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Check out this video!',
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        ),
      );

      if (result.status == ShareResultStatus.success) {
        _showSnackBar('Video shared successfully!');
      } else if (result.status == ShareResultStatus.dismissed) {
        // User cancelled sharing
      } else {
        _showSnackBar('Failed to share video');
      }
    } catch (e) {
      debugPrint('Error sharing video: $e');
      _showSnackBar('Failed to share video');
    }
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

      if (Platform.isAndroid) {
        await _addToGallery(savePath);
      }
    } catch (e) {
      debugPrint('Download error: $e');
      setState(() {
        _downloadingVideos[video.id] = false;
        _downloadProgress.remove(video.id);
      });

      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
            _showSnackBar('Download timeout. Please try again.');
            break;
          case DioExceptionType.connectionError:
            _showSnackBar('Network error. Check your connection.');
            break;
          default:
            _showSnackBar('Download failed. Please try again.');
        }
      } else {
        _showSnackBar('Download failed. Please try again.');
      }
    }
  }

  Future<void> _addToGallery(String filePath) async {
    try {
      debugPrint('Video saved to: $filePath');
    } catch (e) {
      debugPrint('Error adding to gallery: $e');
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
extension VideosFeedScreenExtension on VideosFeedScreenState {
  static void handleTabChanged(
      GlobalKey<VideosFeedScreenState> feedScreenKey, bool isActive) {
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