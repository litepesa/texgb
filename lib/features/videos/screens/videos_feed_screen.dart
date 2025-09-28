// lib/features/videos/screens/videos_feed_screen.dart (Updated with search integration)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/videos/widgets/video_item.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/comments/widgets/comments_bottom_sheet.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/features/videos/widgets/search_overlay.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isNavigatingAway = false; // Track navigation state
  bool _isManuallyPaused = false; // Track if user manually paused the video
  bool _isCommentsSheetOpen = false; // Track comments sheet state

  // Video controllers
  VideoPlayerController? _currentVideoController;
  Timer? _cacheCleanupTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
    _setupCacheCleanup();
    // Use post-frame callback to avoid provider modification during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVideos();
    });
    _hasInitialized = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    _isNavigatingAway = false; // Reset navigation state

    // Setup system UI when actually becoming active and visible
    if (mounted) {
      _setupSystemUI();
    }

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

    // Don't restore system UI here - let HomeScreen handle it
    // The home screen will manage system UI for other tabs

    WakelockPlus.disable();
  }

  // New method to handle navigation away from feed
  void _pauseForNavigation() {
    debugPrint('VideosFeedScreen: Pausing for navigation');
    _isNavigatingAway = true;
    _stopPlayback();
  }

  // New method to handle returning from navigation
  void _resumeFromNavigation() {
    debugPrint('VideosFeedScreen: Resuming from navigation');
    _isNavigatingAway = false;
    if (_isScreenActive &&
        _isAppInForeground &&
        !_isManuallyPaused &&
        !_isCommentsSheetOpen) {
      // Add a small delay to ensure the screen is fully visible before starting playback
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

  void _startIntelligentPreloading() {
    if (!_isScreenActive ||
        !_isAppInForeground ||
        _isNavigatingAway ||
        _isCommentsSheetOpen) {
      return;
    }

    final videos = ref.read(videosProvider);
    if (videos.isEmpty) return;

    debugPrint(
        'Starting intelligent preloading for index: $_currentVideoIndex');
    // Preloading logic can be added here if needed
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
      // If video controller isn't ready, trigger a re-initialization
      debugPrint(
          'VideosFeedScreen: Video controller not ready, attempting initialization');
      final videos = ref.read(videosProvider);
      if (videos.isNotEmpty && _currentVideoIndex < videos.length) {
        // This will trigger the video item to reinitialize if needed
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
      // Only seek to beginning if not in comments mode
      if (!_isCommentsSheetOpen) {
        _currentVideoController!.seekTo(Duration.zero);
      }
    }
  }

  // Add method to control video window mode
  void _setVideoWindowMode(bool isSmallWindow) {
    setState(() {
      _isCommentsSheetOpen = isSmallWindow;
    });

    // Don't pause the video controller here - let it continue playing in small window
    // The video item will handle the display logic based on isCommentsOpen state
  }

  void _initializeControllers() {
    // Controllers initialization if needed in the future
  }

  // Only apply system UI when screen is actually active and visible
  void _setupSystemUI() {
    // Only apply black system UI if this screen is currently active and visible
    if (!mounted || !_isScreenActive) return;

    debugPrint('VideosFeedScreen: Setting up system UI (black theme)');

    // Set immersive black theme only when this screen is active
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  // Load videos from the new authentication provider
  Future<void> _loadVideos() async {
    if (_isFirstLoad) {
      debugPrint('VideosFeedScreen: Loading initial videos');

      // Load videos from the authentication provider
      final authNotifier = ref.read(authenticationProvider.notifier);
      await authNotifier.loadVideos();

      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });

        // If a specific video ID was provided, jump to it
        if (widget.startVideoId != null) {
          // Ensure we have videos loaded before jumping
          final videos = ref.read(videosProvider);
          if (videos.isNotEmpty) {
            debugPrint('VideosFeedScreen: Videos loaded, jumping to ${widget.startVideoId}');
            _jumpToVideo(widget.startVideoId!);
          } else {
            debugPrint('VideosFeedScreen: No videos loaded, cannot jump to specific video');
          }
        } else {
          // Start intelligent preloading for the first video
          _startIntelligentPreloading();
        }
      }
    }
  }

  // IMPROVED: Add this method to jump to a specific video with better reliability
  void _jumpToVideo(String videoId) {
    final videos = ref.read(videosProvider);
    final videoIndex = videos.indexWhere((video) => video.id == videoId);

    if (videoIndex != -1) {
      debugPrint('VideosFeedScreen: Jumping to video at index $videoIndex');

      // Set the current index immediately to prevent wrong video from playing
      _currentVideoIndex = videoIndex;

      // Method 1: Try immediate jump if PageController is ready
      if (_pageController.hasClients && mounted) {
        try {
          _pageController.jumpToPage(videoIndex);
          debugPrint('VideosFeedScreen: Immediate jump successful to index $videoIndex');
          
          // Update state to reflect the change
          if (mounted) {
            setState(() {
              _currentVideoIndex = videoIndex;
              _isManuallyPaused = false; // Reset pause state for new video
            });
          }
          
          // Start intelligent preloading for the target video
          _startIntelligentPreloading();
          return;
        } catch (e) {
          debugPrint('VideosFeedScreen: Immediate jump failed: $e');
        }
      }

      // Method 2: Use post-frame callback for reliable navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        // Double-check PageController is ready
        if (_pageController.hasClients) {
          try {
            _pageController.jumpToPage(videoIndex);
            debugPrint('VideosFeedScreen: Post-frame jump successful to index $videoIndex');
            
            // Update state after successful jump
            if (mounted) {
              setState(() {
                _currentVideoIndex = videoIndex;
                _isManuallyPaused = false;
              });
            }
            
            _startIntelligentPreloading();
          } catch (e) {
            debugPrint('VideosFeedScreen: Post-frame jump failed: $e');
            _fallbackJump(videoIndex);
          }
        } else {
          debugPrint('VideosFeedScreen: PageController not ready, using fallback');
          _fallbackJump(videoIndex);
        }
      });
    } else {
      debugPrint('VideosFeedScreen: Video with ID $videoId not found in list');
    }
  }

  // Add this fallback method for delayed navigation
  void _fallbackJump(int targetIndex) {
    // Use a timer as fallback for when PageController isn't immediately ready
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_pageController.hasClients) {
        timer.cancel();
        
        try {
          _pageController.jumpToPage(targetIndex);
          debugPrint('VideosFeedScreen: Fallback jump successful to index $targetIndex');
          
          if (mounted) {
            setState(() {
              _currentVideoIndex = targetIndex;
              _isManuallyPaused = false;
            });
          }
          
          _startIntelligentPreloading();
        } catch (e) {
          debugPrint('VideosFeedScreen: Fallback jump failed: $e');
        }
      } else if (timer.tick > 50) { // Stop trying after 5 seconds
        timer.cancel();
        debugPrint('VideosFeedScreen: Giving up on jump after timeout');
      }
    });
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

    // Always start fresh from the beginning for NEW videos
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

  // Separate method for starting fresh video (seeks to beginning)
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

  // Method to handle manual play/pause from video item
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
      _isManuallyPaused = false; // Reset manual pause state for new video
    });

    if (_isScreenActive &&
        _isAppInForeground &&
        !_isNavigatingAway &&
        !_isManuallyPaused &&
        !_isCommentsSheetOpen) {
      _startIntelligentPreloading();
      WakelockPlus.enable();
    }

    // Increment view count using the new authentication provider
    final authNotifier = ref.read(authenticationProvider.notifier);
    authNotifier.incrementViewCount(videos[index].id);
  }

  // SIMPLIFIED: Only get user data when it's actually available
  UserModel? _getUserDataIfAvailable() {
    final users = ref.read(usersProvider);
    final isUsersLoading = ref.read(isAuthLoadingProvider);

    // Don't try to find user if still loading or empty
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
      // User not found in current list
      return null;
    }
  }

  // Updated WhatsApp function to use actual user WhatsApp number from database
  Future<void> _openWhatsAppWithVideo(VideoModel? video) async {
    if (video == null) return;

    // Check if user is authenticated before allowing WhatsApp messaging
    final canInteract = await _requireAuthentication('message on whatsapp');
    if (!canInteract) return;

    final currentUser = ref.read(currentUserProvider);

    // Check if user is trying to message their own video
    if (video.userId == currentUser!.uid) {
      _showCannotMessageOwnVideoMessage();
      return;
    }

    try {
      // Pause video before opening WhatsApp
      _pauseForNavigation();

      // Get the video creator's user data from the database
      final authNotifier = ref.read(authenticationProvider.notifier);
      final videoCreator = await authNotifier.getUserById(video.userId);

      if (videoCreator == null) {
        _showUserNotFoundMessage();
        return;
      }

      // Check if the video creator has a WhatsApp number
      if (!videoCreator.hasWhatsApp) {
        _showWhatsAppNotAvailableMessage(videoCreator.name);
        return;
      }

      // Prepare message content with video context
      String message = 'Hi ${videoCreator.name}! I saw your video';
      
      if (video.caption.isNotEmpty) {
        // Add video caption for context (truncate if too long)
        String caption = video.caption;
        if (caption.length > 50) {
          caption = '${caption.substring(0, 50)}...';
        }
        message += ' about "$caption"';
      }
      
      message += ' and wanted to chat!';

      // Encode the message for URL
      final encodedMessage = Uri.encodeComponent(message);
      
      // Create WhatsApp URL with the user's actual WhatsApp number
      final whatsappUrl = 'https://wa.me/${videoCreator.whatsappNumber}?text=$encodedMessage';
      final uri = Uri.parse(whatsappUrl);

      debugPrint('Opening WhatsApp with URL: $whatsappUrl');
      debugPrint('Video creator: ${videoCreator.name}, WhatsApp: ${videoCreator.whatsappNumber}');

      // Try to launch WhatsApp
      if (await canLaunchUrl(uri)) {
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (success) {
          _showSnackBar('Opening WhatsApp to message ${videoCreator.name}...');
        } else {
          throw Exception('Failed to launch WhatsApp');
        }
      } else {
        // WhatsApp is not installed or URL is invalid
        _showWhatsAppNotInstalledMessage();
      }
    } catch (e) {
      debugPrint('Error opening WhatsApp: $e');
      _showSnackBar('Failed to open WhatsApp');
    } finally {
      // Resume video after attempting to open WhatsApp
      // Add delay to ensure user returns to the app
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _resumeFromNavigation();
        }
      });
    }
  }

  // Helper method to show when user is not found
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
              'Could not find the video creator\'s profile. Please try again later.',
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

  // Helper method to show when WhatsApp number is not available
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

  // Helper method to show WhatsApp not installed message
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

  // Add this method to build the small video window
  Widget _buildSmallVideoWindow() {
    final systemTopPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: systemTopPadding + 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
          // Close comments and return to full screen
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
                // Video content only - no overlays
                Positioned.fill(
                  child: _buildVideoContentOnly(),
                ),

                // Close button overlay
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

    // Return only the media content without any overlays
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

  // Helper method to require authentication before actions
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

    return true; // User is authenticated
  }

  // Helper method to get appropriate icon for different actions
  IconData _getIconForAction(String actionName) {
    switch (actionName.toLowerCase()) {
      case 'like videos':
      case 'like':
        return Icons.favorite;
      case 'comment':
      case 'comment on videos':
        return Icons.comment;
      case 'message on whatsapp':
      case 'whatsapp':
        return Icons.message;
      default:
        return Icons.video_call;
    }
  }

  // Helper method to show cannot message own video
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

  // Helper method to show snackbar
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

  // NEW: Method to open search overlay
  void _openSearchOverlay() {
    // Pause video before opening search
    _pauseForNavigation();

    SearchOverlayController.show(
      context,
      onVideoTap: (videoId) {
        // When a video is selected from search, jump to it
        _jumpToVideo(videoId);
        _resumeFromNavigation();
      },
      showFilters: true,
    );
  }

  @override
  void dispose() {
    debugPrint('VideosFeedScreen: Disposing');

    WidgetsBinding.instance.removeObserver(this);

    // STOP ALL PLAYBACK AND DISABLE WAKELOCK
    _stopPlayback();
    
    // CLEANUP CACHE TIMER
    _cacheCleanupTimer?.cancel();

    _pageController.dispose();

    // Final wakelock disable
    WakelockPlus.disable();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Only setup system UI if this screen is actually active
    if (_isScreenActive && mounted) {
      _setupSystemUI();
    }

    // Watch videos from the new authentication provider
    final videos = ref.watch(videosProvider);
    final isLoading = ref.watch(isAuthLoadingProvider);
    final systemTopPadding = MediaQuery.of(context).padding.top;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    // Show loading screen during initial video loading
    if (_isFirstLoad && isLoading) {
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
                'Loading videos...',
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
      body: Container(
        color: Colors.black, // Ensure black background
        child: Stack(
          children: [
            // Main content area
            _buildBody(videos),

            // Small video window when comments are open
            if (_isCommentsSheetOpen) _buildSmallVideoWindow(),

            // Top navigation - simplified header matching moments feed style
            if (!_isCommentsSheetOpen) // Hide top bar when comments are open
              Positioned(
                top: systemTopPadding,
                left: 0,
                right: 0,
                child: _buildSimplifiedHeader(),
              ),

            // TikTok-style right side menu
            if (!_isCommentsSheetOpen) // Hide right menu when comments are open
              _buildRightSideMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<VideoModel> videos) {
    final isLoading = ref.watch(isAuthLoadingProvider);

    if (!isLoading && videos.isEmpty) {
      return _buildEmptyState();
    }

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
          isCommentsOpen:
              _isCommentsSheetOpen, // Pass comments state to video item
        );
      },
    );
  }

  // New simplified header matching moments feed screen style (without back button)
  Widget _buildSimplifiedHeader() {
    return Row(
      children: [
        // Empty space for alignment
        const SizedBox(width: 56), // Same width as an IconButton

        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              /*Text(
                'Marketplace',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.7),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),*/
            ],
          ),
        ),

        // Search button - UPDATED: Now opens search overlay
        IconButton(
          onPressed: _openSearchOverlay,
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
    );
  }

  // TikTok-style right side menu
  Widget _buildRightSideMenu() {
    final videos = ref.watch(videosProvider);
    final currentVideo = videos.isNotEmpty && _currentVideoIndex < videos.length
        ? videos[_currentVideoIndex]
        : null;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 4, // Much closer to edge
      bottom:
          systemBottomPadding, // Closer to system nav for better screen utilization
      child: Column(
        children: [
          // WhatsApp button - UPDATED: Now directly opens WhatsApp instead of VideoReactionWidget
          GestureDetector(
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

          const SizedBox(height: 10),

          // Like button
          _buildRightMenuItem(
            child: Icon(
              currentVideo?.isLiked == true
                  ? CupertinoIcons.heart
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

          // Profile avatar with red border
          _buildRightMenuItem(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22), // Rounded square instead of circle
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22), // Slightly smaller radius for the image
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
                                : 'H',
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
            padding: const EdgeInsets.all(4), // Reduced padding
            child: child,
          ),
          if (label != null) ...[
            const SizedBox(height: 2), // Reduced spacing
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11, // Slightly smaller text
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

  // Empty state - updated to simply show no videos message
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            color: Colors.white,
            size: 80,
          ),
          SizedBox(height: 24),
          Text(
            'No Videos Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Check back later for new videos',
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

  void _navigateToUserProfile() async {
    final videos = ref.read(videosProvider);
    if (_currentVideoIndex < videos.length) {
      // Pause video before navigation
      _pauseForNavigation();

      final result = await Navigator.of(context).pushNamed(
        Constants.userProfileScreen,
        arguments: videos[_currentVideoIndex].userId,
      );

      // Resume video after returning from navigation
      _resumeFromNavigation();
    }
  }

  void _likeCurrentVideo(VideoModel? video) async {
    if (video == null) return;

    // Check if user is authenticated before allowing like
    final canInteract = await _requireAuthentication('like videos');
    if (!canInteract) return;

    // Use the authentication provider to like the video
    final authNotifier = ref.read(authenticationProvider.notifier);
    authNotifier.likeVideo(video.id);
  }

  void _showCommentsForCurrentVideo(VideoModel? video) async {
    if (video == null || _isCommentsSheetOpen) return;

    // Check if user is authenticated before allowing comments
    final canInteract = await _requireAuthentication('comment on videos');
    if (!canInteract) return;

    // Set video to small window mode
    _setVideoWindowMode(true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        video: video,
        onClose: () {
          // Reset video to full screen mode
          _setVideoWindowMode(false);
        },
      ),
    ).whenComplete(() {
      // Ensure video returns to full screen mode
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