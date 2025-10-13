// lib/features/videos/screens/single_video_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:textgb/features/comments/widgets/comments_bottom_sheet.dart';
import 'package:textgb/features/gifts/widgets/virtual_gifts_bottom_sheet.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:textgb/features/videos/widgets/video_item.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SingleVideoScreen extends ConsumerStatefulWidget {
  final String videoId;

  const SingleVideoScreen({
    super.key,
    required this.videoId,
    String? userId,
  });

  @override
  ConsumerState<SingleVideoScreen> createState() => _SingleVideoScreenState();
}

class _SingleVideoScreenState extends ConsumerState<SingleVideoScreen>
    with
        WidgetsBindingObserver,
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin {
  // Core controllers
  final PageController _pageController = PageController();

  // State management
  int _currentVideoIndex = 0;
  bool _isAppInForeground = true;
  final bool _isScreenActive = true;
  bool _isNavigatingAway = false;
  bool _isManuallyPaused = false;
  bool _isCommentsSheetOpen = false; // Track comments sheet state

  // Download state management
  final Map<String, bool> _downloadingVideos =
      {}; // Track which videos are downloading
  final Map<String, double> _downloadProgress =
      {}; // Track download progress for each video

  // Video data
  UserModel? _videoAuthor;
  List<VideoModel> _videos = [];
  bool _isLoading = true;
  String? _error;
  bool _isFollowing = false;
  bool _isOwner = false;

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
    _loadVideoData();
    _setupCacheCleanup();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store original system UI after dependencies are available
    if (_originalSystemUiStyle == null) {
      _storeOriginalSystemUI();
    }
  }

  void _storeOriginalSystemUI() {
    // Store the current system UI style before making changes
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

  void _setupSystemUI() {
    // Set transparent status bar and navigation bar for full immersive experience
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  void _setupCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      // Cache cleanup logic can be added here if needed
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

  // Helper method to check if user has authentication before allowing interactions
  Future<bool> _checkUserAuthentication(String actionName) async {
    final isAuthenticated = ref.read(isAuthenticatedProvider);

    // If user is not authenticated, show the login required widget
    if (!isAuthenticated) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: LoginRequiredWidget(
              title: 'Sign In Required',
              subtitle: 'You need to sign in to $actionName.',
              actionText: 'Sign In',
              icon: _getIconForAction(actionName),
            ),
          ),
        ),
      );

      return result ?? false;
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

  Future<void> _loadVideoData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the specific video first to find the user
      final allVideos = ref.read(videosProvider);
      final targetVideo = allVideos.firstWhere(
        (video) => video.id == widget.videoId,
        orElse: () => throw Exception('Video not found'),
      );

      // Get the user/author - UPDATED to use uid instead of id
      final allUsers = ref.read(usersProvider);
      final author = allUsers.firstWhere(
        (user) =>
            user.uid == targetVideo.userId, // Changed from user.id to user.uid
        orElse: () => throw Exception('User not found'),
      );

      // Load all user videos
      final userVideos = allVideos
          .where((video) => video.userId == targetVideo.userId)
          .toList();

      // Sort by newest first - UPDATED to handle string timestamps
      userVideos.sort((a, b) {
        try {
          final aTime = DateTime.parse(a.createdAt);
          final bTime = DateTime.parse(b.createdAt);
          return bTime.compareTo(aTime); // Sort by newest first
        } catch (e) {
          // Fallback to string comparison if parsing fails
          return b.createdAt.compareTo(a.createdAt);
        }
      });

      // Find the index of the target video
      final targetIndex =
          userVideos.indexWhere((video) => video.id == widget.videoId);

      final followedUsers = ref.read(followedUsersProvider);
      final isFollowing = followedUsers.contains(targetVideo.userId);
      final currentUser = ref.read(currentUserProvider);
      final isOwner = currentUser != null &&
          currentUser.uid == targetVideo.userId; // Changed from id to uid

      if (mounted) {
        setState(() {
          _videoAuthor = author;
          _videos = userVideos;
          _isFollowing = isFollowing;
          _isOwner = isOwner;
          _isLoading = false;
          _currentVideoIndex = targetIndex >= 0 ? targetIndex : 0;
        });

        // Set the page controller to the target video after the widget is built
        if (targetIndex >= 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.animateToPage(
                targetIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }

        // Initialize intelligent preloading
        _startIntelligentPreloading();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _startIntelligentPreloading() {
    if (!_isScreenActive ||
        !_isAppInForeground ||
        _isNavigatingAway ||
        _isCommentsSheetOpen) {
      return;
    }

    if (_videos.isEmpty) return;

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

    debugPrint('SingleVideoScreen: Starting fresh playback');

    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
      debugPrint('SingleVideoScreen: Video controller playing');
    } else {
      // If video controller isn't ready, trigger a re-initialization
      debugPrint(
          'SingleVideoScreen: Video controller not ready, attempting initialization');
      if (_videos.isNotEmpty && _currentVideoIndex < _videos.length) {
        // This will trigger the video item to reinitialize if needed
        setState(() {});
      }
    }

    _startIntelligentPreloading();

    WakelockPlus.enable();
  }

  void _stopPlayback() {
    debugPrint('SingleVideoScreen: Stopping playback');

    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.pause();
      // Only seek to beginning if not in comments mode
      if (!_isCommentsSheetOpen) {
        _currentVideoController!.seekTo(Duration.zero);
      }
    }
  }

  void _pauseForNavigation() {
    debugPrint('SingleVideoScreen: Pausing for navigation');
    _isNavigatingAway = true;
    _stopPlayback();
  }

  void _resumeFromNavigation() {
    debugPrint('SingleVideoScreen: Resuming from navigation');
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

  // Add method to control video window mode
  void _setVideoWindowMode(bool isSmallWindow) {
    setState(() {
      _isCommentsSheetOpen = isSmallWindow;
    });

    // Don't pause the video controller here - let it continue playing in small window
    // The video item will handle the display logic based on isCommentsOpen state
  }

  // UPDATED METHOD: Handle WhatsApp messaging with video context - now mirrors BUY button functionality
  Future<void> _openWhatsAppWithVideo(VideoModel? video) async {
    if (video == null) return;

    // Check if user is authenticated before allowing WhatsApp messaging
    final canInteract = await _checkUserAuthentication('message on whatsapp');
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

      // Generate shareable link for this video (your landing page)
      final videoLink = 'https://share.weibao.africa/v/${video.id}';
      
      // Prepare message content with landing page link
      // When clicked in WhatsApp, this will show rich preview and open your app
      String message = '$videoLink\n\nHi ${videoCreator.name}! I saw your video';
      
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
      debugPrint('Video link: $videoLink');

      // Try to launch WhatsApp directly without checking canLaunchUrl
      // This works better across different WhatsApp versions (regular and business)
      try {
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (success) {
          _showSnackBar('Opening WhatsApp to contact ${videoCreator.name}...');
        } else {
          // If launch returns false, WhatsApp might not be installed
          _showWhatsAppNotInstalledMessage();
        }
      } catch (e) {
        // If launching fails, WhatsApp is likely not installed
        debugPrint('Failed to launch WhatsApp: $e');
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
    if (_videos.isEmpty || _currentVideoIndex >= _videos.length) {
      return Container(color: Colors.black);
    }

    final currentVideo = _videos[_currentVideoIndex];

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

  void onManualPlayPause(bool isPlaying) {
    debugPrint('SingleVideoScreen: Manual play/pause - isPlaying: $isPlaying');
    setState(() {
      _isManuallyPaused = !isPlaying;
    });
  }

  void _onPageChanged(int index) {
    if (index >= _videos.length || !_isScreenActive) return;

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

    ref
        .read(authenticationProvider.notifier)
        .incrementViewCount(_videos[index].id);
  }

  // Enhanced back navigation with proper system UI restoration
  void _handleBackNavigation() {
    // Close comments sheet if open
    if (_isCommentsSheetOpen) {
      Navigator.of(context).pop();
      return;
    }

    // Pause playback and disable wakelock before leaving
    _stopPlayback();

    // Restore the original system UI style if available
    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    } else {
      // Fallback: restore based on current theme
      final brightness = Theme.of(context).brightness;
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ));
    }

    // Small delay to ensure system UI is properly restored
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // Add navigation to user profile
  void _navigateToUserProfile() async {
    if (_videoAuthor == null) return;

    // Pause current video and disable wakelock before navigation
    _pauseForNavigation();

    // Navigate to user profile screen - pass just the userId string
    await Navigator.pushNamed(
      context,
      Constants.userProfileScreen,
      arguments: _videoAuthor!.uid, // Changed from id to uid
    );

    // Resume video when returning (if still active)
    _resumeFromNavigation();
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

  // Custom back button positioned at top right corner (mirroring follow button style and position)
  Widget _buildTopRightBackButton() {
    final systemTopPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: systemTopPadding +
          16, // Match follow button positioning exactly relative to video area
      right: 16, // Match follow button positioning but on opposite side
      child: GestureDetector(
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
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Stop all playback and disable wakelock before disposing
    _stopPlayback();

    // Restore original system UI style on dispose if available
    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    } else if (mounted) {
      // Fallback: restore based on current theme
      final brightness = Theme.of(context).brightness;
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: true,
      ));
    }

    _cacheCleanupTimer?.cancel();

    _pageController.dispose();

    // Final wakelock disable
    WakelockPlus.disable();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildErrorState(),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _handleBackNavigation();
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Stack(
          children: [
            // Main video content - full screen without any padding
            Positioned.fill(
              child: _buildVideoFeed(),
            ),

            // Small video window when comments are open
            if (_isCommentsSheetOpen) _buildSmallVideoWindow(),

            // Custom back button - positioned to match follow button alignment
            if (!_isCommentsSheetOpen) _buildTopRightBackButton(),

            // TikTok-style right side menu - matching original design (hide when comments open)
            if (!_isCommentsSheetOpen) _buildRightSideMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoFeed() {
    if (_videos.isEmpty) {
      return _buildEmptyState();
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _videos.length,
      onPageChanged: _onPageChanged,
      physics: _isScreenActive && !_isCommentsSheetOpen
          ? null
          : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final video = _videos[index];

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
          showVerificationBadge: true,
        );
      },
    );
  }

  // TikTok-style right side menu (UPDATED with WhatsApp integration)
  Widget _buildRightSideMenu() {
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final currentVideo =
        _videos.isNotEmpty && _currentVideoIndex < _videos.length
            ? _videos[_currentVideoIndex]
            : null;

    return Positioned(
      right: 0.5, // Much closer to edge
      bottom: systemBottomPadding, // Position above system nav bar
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
                // Show progress indicator if downloading
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

          // Gift button - with exciting emoji
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

          // Profile avatar with red border - SIMPLIFIED: Use video metadata directly
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined,
              color: Colors.white, size: 80),
          const SizedBox(height: 24),
          const Text(
            'No Videos Yet',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _isOwner
                ? 'Create your first video to share with your followers'
                : 'This user hasn\'t posted any videos yet',
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (_isOwner) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, Constants.createPostScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0050),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create Video'),
            ),
          ],
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
            'Error Loading Content',
            style: TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
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

  void _likeCurrentVideo(VideoModel? video) async {
    if (video == null) return;

    // Check if user is authenticated before allowing like
    final canInteract = await _checkUserAuthentication('like videos');
    if (!canInteract) return;

    ref.read(authenticationProvider.notifier).likeVideo(video.id);
  }

  void _showCommentsForCurrentVideo(VideoModel? video) async {
    if (video == null || _isCommentsSheetOpen) return;

    // Check if user is authenticated before allowing comments
    final canInteract = await _checkUserAuthentication('comment on videos');
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

  // NEW: Share current video using share_plus package
  Future<void> _shareCurrentVideo(VideoModel? video) async {
    if (video == null) return;

    try {
      // Create share content
      String shareText = '';

      // Add video caption if available
      if (video.caption.isNotEmpty) {
        shareText += video.caption;
      }

      // Add creator credit
      if (shareText.isNotEmpty) {
        shareText += '\n\n';
      }
      shareText += 'Check out this video by ${video.userName}!';

      // Add hashtags if available
      if (video.tags.isNotEmpty) {
        shareText += '\n\n${video.tags.map((tag) => '#$tag').join(' ')}';
      }

      // Add app promotion
      shareText += '\n\nShared via TextGB';

      // Get the render box for share position (required for iPad)
      final RenderBox? box = context.findRenderObject() as RenderBox?;

      // Share using share_plus
      final result = await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Check out this video!',
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        ),
      );

      // Show feedback based on share result
      if (result.status == ShareResultStatus.success) {
        _showSnackBar('Video shared successfully!');
      } else if (result.status == ShareResultStatus.dismissed) {
        // User cancelled sharing - no need to show message
      } else {
        _showSnackBar('Failed to share video');
      }
    } catch (e) {
      debugPrint('Error sharing video: $e');
      _showSnackBar('Failed to share video');
    }
  }

  // NEW: Show virtual gifts bottom sheet
  void _showVirtualGifts(VideoModel? video) async {
    if (video == null) {
      debugPrint('No video available for gifting');
      return;
    }

    // Check if user is authenticated before allowing gifts
    final canInteract = await _checkUserAuthentication('send gifts');
    if (!canInteract) return;

    final currentUser = ref.read(currentUserProvider);

    // At this point we know user is authenticated
    // Check if user is trying to gift their own video - UPDATED to use uid
    if (video.userId == currentUser!.uid) {
      // Changed from id to uid
      _showCannotGiftOwnVideoMessage();
      return;
    }

    // Pause video before showing gifts
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
          // Resume video when gifts sheet is closed
          _resumeFromNavigation();
        },
      ),
    ).whenComplete(() {
      // Ensure video resumes if sheet is dismissed
      _resumeFromNavigation();
    });
  }

  void _handleGiftSent(VideoModel video, VirtualGift gift) {
    // TODO: Implement actual gift sending logic
    // This would typically involve:
    // 1. Deducting the gift price from user's wallet
    // 2. Adding the gift to the user owner's earnings
    // 3. Recording the gift transaction
    // 4. Optionally sending a notification to the user owner

    debugPrint(
        'Gift sent: ${gift.name} (KES ${gift.price}) to ${video.userName}');

    // Show success message
    _showSnackBar('${gift.emoji} ${gift.name} sent to ${video.userName}!');

    // TODO: You might want to also send this as a chat message like video reactions
    // or create a separate gifts system
  }

  // Helper method to show cannot gift own video message
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

  // NEW: Download current video functionality
  Future<void> _downloadCurrentVideo(VideoModel? video) async {
    if (video == null) return;

    // Check if user is authenticated before allowing download
    final canInteract = await _checkUserAuthentication('download videos');
    if (!canInteract) return;

    // Check if already downloading
    if (_downloadingVideos[video.id] == true) {
      _showSnackBar('Video is already downloading...');
      return;
    }

    // For image posts, we can't download videos
    if (video.isMultipleImages) {
      _showSnackBar('Cannot download image posts');
      return;
    }

    // Check if video URL is valid
    if (video.videoUrl.isEmpty) {
      _showSnackBar('Invalid video URL');
      return;
    }

    try {
      // Request storage permission
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showSnackBar('Storage permission required to download videos');
        return;
      }

      // Start download
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

  // Request storage permission based on Android version
  Future<bool> _requestStoragePermission() async {
    // For Android 13+ (API 33+), we need different permissions
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ - request media permissions
        final status = await [
          Permission.videos,
          Permission.photos,
        ].request();

        return status.values.every((status) => status.isGranted);
      } else {
        // Android 12 and below - request storage permission
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      // For iOS, request photos permission
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    return true; // For other platforms
  }

  // Download video with progress tracking
  Future<void> _downloadVideo(VideoModel video) async {
    setState(() {
      _downloadingVideos[video.id] = true;
      _downloadProgress[video.id] = 0.0;
    });

    try {
      final dio = Dio();

      // Get download directory
      Directory? directory;
      String fileName =
          'textgb_${video.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      if (Platform.isAndroid) {
        // Try to save to Downloads folder
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to app documents directory
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // For iOS, save to app documents directory
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms
        directory = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      final savePath = '${directory.path}/$fileName';

      // Download with progress tracking
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

      // Download completed successfully
      setState(() {
        _downloadingVideos[video.id] = false;
        _downloadProgress.remove(video.id);
      });

      _showSnackBar('Video saved successfully!');

      // Optionally, add to device gallery (Android only)
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

  // Add video to Android gallery (optional)
  Future<void> _addToGallery(String filePath) async {
    try {
      // This would require additional packages like gallery_saver
      // For now, we'll just save to Downloads which should be visible in gallery
      debugPrint('Video saved to: $filePath');
    } catch (e) {
      debugPrint('Error adding to gallery: $e');
    }
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}