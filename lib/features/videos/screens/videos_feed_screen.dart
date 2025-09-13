// lib/features/videos/screens/videos_feed_screen.dart (Updated with WhatsApp button)

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
import 'package:textgb/features/gifts/widgets/virtual_gifts_bottom_sheet.dart';
import 'package:textgb/features/authentication/widgets/login_required_widget.dart';
import 'package:textgb/constants.dart';
//import 'package:textgb/features/videos/widgets/video_reaction_widget.dart';
import 'package:textgb/features/users/models/user_model.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

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
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver, RouteAware {
  
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
  
  // Download state management
  final Map<String, bool> _downloadingVideos = {}; // Track which videos are downloading
  final Map<String, double> _downloadProgress = {}; // Track download progress for each video
  
  VideoPlayerController? _currentVideoController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllers();
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
    if (_isScreenActive && _isAppInForeground && !_isManuallyPaused && !_isCommentsSheetOpen) {
      // Add a small delay to ensure the screen is fully visible before starting playback
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_isNavigatingAway && _isScreenActive && _isAppInForeground && !_isManuallyPaused && !_isCommentsSheetOpen) {
          _startFreshPlayback();
        }
      });
    }
  }

  void _startFreshPlayback() {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isManuallyPaused || _isCommentsSheetOpen) return;
    
    debugPrint('VideosFeedScreen: Starting fresh playback');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
      debugPrint('VideosFeedScreen: Video controller playing');
    } else {
      // If video controller isn't ready, trigger a re-initialization
      debugPrint('VideosFeedScreen: Video controller not ready, attempting initialization');
      final videos = ref.read(videosProvider);
      if (videos.isNotEmpty && _currentVideoIndex < videos.length) {
        // This will trigger the video item to reinitialize if needed
        setState(() {});
      }
    }
    
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
          _jumpToVideo(widget.startVideoId!);
        }
      }
    }
  }

  // Add this method to jump to a specific video
  void _jumpToVideo(String videoId) {
    final videos = ref.read(videosProvider);
    final videoIndex = videos.indexWhere((video) => video.id == videoId);
    
    if (videoIndex != -1) {
      debugPrint('VideosFeedScreen: Jumping to video at index $videoIndex');
      
      // Use a delay to ensure the PageView is ready and videos are loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(videoIndex);
          
          // Update the current video index
          setState(() {
            _currentVideoIndex = videoIndex;
          });
          
          debugPrint('VideosFeedScreen: Successfully jumped to video $videoId at index $videoIndex');
        }
      });
    } else {
      debugPrint('VideosFeedScreen: Video with ID $videoId not found in list');
    }
  }

  void _onVideoControllerReady(VideoPlayerController controller) {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isCommentsSheetOpen) return;
    
    debugPrint('Video controller ready, setting up fresh playback');
    
    setState(() {
      _currentVideoController = controller;
    });

    // Always start fresh from the beginning for NEW videos
    controller.seekTo(Duration.zero);
    
    WakelockPlus.enable();
  }

  // Separate method for starting fresh video (seeks to beginning)
  void _startFreshVideo() {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isManuallyPaused || _isCommentsSheetOpen) return;
    
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
      _currentVideoController = null;
      _isManuallyPaused = false; // Reset manual pause state for new video
    });

    if (_isScreenActive && _isAppInForeground && !_isNavigatingAway && !_isManuallyPaused && !_isCommentsSheetOpen) {
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
      final currentVideo = videos.isNotEmpty && _currentVideoIndex < videos.length 
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

  // Show virtual gifts bottom sheet
  void _showVirtualGifts(VideoModel? video) async {
    if (video == null) {
      debugPrint('No video available for gifting');
      return;
    }

    // Check if user is authenticated before allowing gifts
    final canInteract = await _requireAuthentication('send gifts');
    if (!canInteract) return;

    final currentUser = ref.read(currentUserProvider);
    
    // Check if user is trying to gift their own video
    if (video.userId == currentUser!.uid) {
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
    // TODO: Implement actual gift sending logic
    debugPrint('Gift sent: ${gift.name} (KES ${gift.price}) to ${video.userName}');
    
    // Show success message
    _showSnackBar('${gift.emoji} ${gift.name} sent to ${video.userName}!');
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

  // WhatsApp navigation method (dummy implementation for now)
  void _openWhatsApp(VideoModel? video) async {
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
    
    // TODO: Implement actual WhatsApp navigation logic
    // For now, just show a message that this will be implemented
    _showWhatsAppComingSoonMessage(video);
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

  // Helper method to show WhatsApp coming soon message
  void _showWhatsAppComingSoonMessage(VideoModel video) {
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
              'WhatsApp Integration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'WhatsApp messaging with ${video.userName} will be available soon!',
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

  @override
  void dispose() {
    debugPrint('VideosFeedScreen: Disposing');
    
    WidgetsBinding.instance.removeObserver(this);
    
    _pageController.dispose();
    
    _stopPlayback();
    
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
      physics: _isScreenActive && !_isCommentsSheetOpen ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final video = videos[index];
        
        return VideoItem(
          video: video,
          isActive: index == _currentVideoIndex && _isScreenActive && _isAppInForeground && !_isNavigatingAway,
          onVideoControllerReady: _onVideoControllerReady,
          onManualPlayPause: onManualPlayPause,
          isCommentsOpen: _isCommentsSheetOpen, // Pass comments state to video item
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
              Text(
                'For You',
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
              ),
            ],
          ),
        ),
        
        // Search button
        IconButton(
          onPressed: () {},
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

  // TikTok-style right side menu - now with WhatsApp button
  Widget _buildRightSideMenu() {
    final videos = ref.watch(videosProvider);
    final currentVideo = videos.isNotEmpty && _currentVideoIndex < videos.length 
        ? videos[_currentVideoIndex] 
        : null;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 4, // Much closer to edge
      bottom: systemBottomPadding, // Closer to system nav for better screen utilization
      child: Column(
        children: [
          // Like button
          _buildRightMenuItem(
            child: Icon(
              currentVideo?.isLiked == true ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
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
          
          // Download button (replaced star/bookmark)
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
          
          // Share button - UPDATED with share_plus functionality
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.arrowshape_turn_up_right,
              color: Colors.white,
              size: 26,
            ),
            label: 'Share',
            onTap: () async {
              // Check if user is authenticated before allowing share
              final canInteract = await _requireAuthentication('share videos');
              if (canInteract) {
                await _shareCurrentVideo(currentVideo);
              }
            },
          ),
          
          const SizedBox(height: 10),
          
          // WhatsApp button - NEW
          _buildRightMenuItem(
            child: Lottie.asset(
              'assets/lottie/chat_bubble.json',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
            onTap: () {},
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
          
          // Profile avatar with red border - FIXED: Only show when user data is ready
          _buildRightMenuItem(
            child: Consumer(
              builder: (context, ref, child) {
                final videoUser = _getUserDataIfAvailable();
                
                // Only display profile avatar when we actually have the user data
                if (videoUser == null) {
                  // Show loading indicator while waiting for user data
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.grey.withOpacity(0.3),
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
                }
                
                // User data is available, safe to display
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), // Rounded square instead of circle
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6), // Slightly smaller radius for the image
                    child: videoUser.profileImage.isNotEmpty
                        ? Image.network(
                            videoUser.profileImage,
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
                                  borderRadius: BorderRadius.circular(6),
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
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    videoUser.name.isNotEmpty ? videoUser.name[0].toUpperCase() : 'U',
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
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                videoUser.name.isNotEmpty ? videoUser.name[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                  ),
                );
              },
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

  // Share current video using share_plus package
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
          sharePositionOrigin: box != null 
              ? box.localToGlobal(Offset.zero) & box.size 
              : null,
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

  // Download current video functionality
  Future<void> _downloadCurrentVideo(VideoModel? video) async {
    if (video == null) return;
    
    // Check if user is authenticated before allowing download
    final canInteract = await _requireAuthentication('download videos');
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
      String fileName = 'textgb_${video.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
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
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
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