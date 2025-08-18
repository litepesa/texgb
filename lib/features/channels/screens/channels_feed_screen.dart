// lib/features/channels/screens/channels_feed_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/widgets/channel_video_item.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/services/video_cache_service.dart';
import 'package:textgb/features/channels/widgets/comments_bottom_sheet.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/features/chat/models/message_model.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ChannelsFeedScreen extends ConsumerStatefulWidget {
  final String? startVideoId; // For direct video navigation
  final String? channelId; // For channel-specific filtering (optional)

  const ChannelsFeedScreen({
    Key? key,
    this.startVideoId,
    this.channelId,
  }) : super(key: key);

  @override
  ConsumerState<ChannelsFeedScreen> createState() => ChannelsFeedScreenState();
}

class ChannelsFeedScreenState extends ConsumerState<ChannelsFeedScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver, RouteAware {
  
  // Core controllers
  final PageController _pageController = PageController();
  
  // Cache service
  final VideoCacheService _cacheService = VideoCacheService();
  
  // State management
  bool _isFirstLoad = true;
  int _currentVideoIndex = 0;
  bool _isScreenActive = true;
  bool _isAppInForeground = true;
  bool _hasInitialized = false;
  bool _isNavigatingAway = false; // Track navigation state
  bool _isManuallyPaused = false; // Track if user manually paused the video
  bool _isCommentsSheetOpen = false; // Track comments sheet state
  bool _isChannelEnsuring = false; // NEW: Track channel auto-creation
  
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
    // FIXED: Use post-frame callback to avoid provider modification during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureChannelAndLoadVideos();
    });
    _setupCacheCleanup();
    _hasInitialized = true;
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
    
    debugPrint('ChannelsFeedScreen: Screen became active');
    _isScreenActive = true;
    _isNavigatingAway = false; // Reset navigation state
    
    // Setup system UI when becoming active
    _setupSystemUI();
    
    if (_isAppInForeground && !_isManuallyPaused && !_isCommentsSheetOpen) {
      _startFreshPlayback();
      _startIntelligentPreloading();
      WakelockPlus.enable();
    }
  }

  void onScreenBecameInactive() {
    if (!_hasInitialized) return;
    
    debugPrint('ChannelsFeedScreen: Screen became inactive');
    _isScreenActive = false;
    _stopPlayback();
    
    // Restore original system UI when becoming inactive
    _restoreOriginalSystemUI();
    
    WakelockPlus.disable();
  }

  void _restoreOriginalSystemUI() {
    if (_originalSystemUiStyle != null) {
      SystemChrome.setSystemUIOverlayStyle(_originalSystemUiStyle!);
    } else {
      // Fallback: restore based on current theme
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

  // New method to handle navigation away from feed
  void _pauseForNavigation() {
    debugPrint('ChannelsFeedScreen: Pausing for navigation');
    _isNavigatingAway = true;
    _stopPlayback();
  }

  // New method to handle returning from navigation
  void _resumeFromNavigation() {
    debugPrint('ChannelsFeedScreen: Resuming from navigation');
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
    
    debugPrint('ChannelsFeedScreen: Starting fresh playback');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
      debugPrint('ChannelsFeedScreen: Video controller playing');
    } else {
      // If video controller isn't ready, trigger a re-initialization
      debugPrint('ChannelsFeedScreen: Video controller not ready, attempting initialization');
      final videos = ref.read(channelVideosProvider).videos;
      if (videos.isNotEmpty && _currentVideoIndex < videos.length) {
        // This will trigger the video item to reinitialize if needed
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

  void _setupSystemUI() {
    // Set both status bar and navigation bar to black for immersive TikTok-style experience
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black, // Changed from transparent to black
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black, // Keep black for immersive experience
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

  // NEW: Ensure user has channel before loading videos
  Future<void> _ensureChannelAndLoadVideos() async {
    if (_isFirstLoad) {
      debugPrint('ChannelsFeedScreen: Ensuring channel and loading initial videos');
      
      setState(() {
        _isChannelEnsuring = true;
      });
      
      // Ensure user has a channel first
      final channel = await ref.read(channelsProvider.notifier).ensureUserHasChannel();
      
      if (channel != null) {
        debugPrint('ChannelsFeedScreen: Channel ensured, loading videos');
        // Load videos after ensuring channel
        await ref.read(channelVideosProvider.notifier).loadVideos();
      } else {
        debugPrint('ChannelsFeedScreen: Failed to ensure channel');
      }
      
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
          _isChannelEnsuring = false;
        });
        
        // If a specific video ID was provided, jump to it
        if (widget.startVideoId != null) {
          _jumpToVideo(widget.startVideoId!);
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

  // Add this method to jump to a specific video
  void _jumpToVideo(String videoId) {
    final videos = ref.read(channelVideosProvider).videos;
    final videoIndex = videos.indexWhere((video) => video.id == videoId);
    
    if (videoIndex != -1) {
      debugPrint('ChannelsFeedScreen: Jumping to video at index $videoIndex');
      
      // Use a delay to ensure the PageView is ready and videos are loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(videoIndex);
          
          // Update the current video index
          setState(() {
            _currentVideoIndex = videoIndex;
          });
          
          debugPrint('ChannelsFeedScreen: Successfully jumped to video $videoId at index $videoIndex');
        }
      });
    } else {
      debugPrint('ChannelsFeedScreen: Video with ID $videoId not found in list');
    }
  }

  void _startIntelligentPreloading() {
    if (!_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isCommentsSheetOpen) return;
    
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

  void _onVideoControllerReady(VideoPlayerController controller) {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isCommentsSheetOpen) return;
    
    debugPrint('Video controller ready, setting up fresh playback');
    
    setState(() {
      _currentVideoController = controller;
    });

    // Always start fresh from the beginning for NEW videos
    controller.seekTo(Duration.zero);
    
    WakelockPlus.enable();
    
    if (_isScreenActive && _isAppInForeground && !_isNavigatingAway && !_isManuallyPaused && !_isCommentsSheetOpen) {
      _startIntelligentPreloading();
    }
  }

  // Separate method for starting fresh video (seeks to beginning)
  void _startFreshVideo() {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isManuallyPaused || _isCommentsSheetOpen) return;
    
    debugPrint('ChannelsFeedScreen: Starting fresh video from beginning');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.seekTo(Duration.zero);
      _currentVideoController!.play();
    }
    
    _startFreshPlayback();
  }

  // Method to handle manual play/pause from video item
  void onManualPlayPause(bool isPlaying) {
    debugPrint('ChannelsFeedScreen: Manual play/pause - isPlaying: $isPlaying');
    setState(() {
      _isManuallyPaused = !isPlaying;
    });
  }

  void _onPageChanged(int index) {
    final videos = ref.read(channelVideosProvider).videos;
    if (index >= videos.length || !_isScreenActive) return;

    debugPrint('Page changed to: $index');

    setState(() {
      _currentVideoIndex = index;
      _currentVideoController = null;
      _isManuallyPaused = false; // Reset manual pause state for new video
    });

    if (_isScreenActive && _isAppInForeground && !_isNavigatingAway && !_isManuallyPaused && !_isCommentsSheetOpen) {
      _startIntelligentPreloading();
      WakelockPlus.enable();
    }
    
    ref.read(channelVideosProvider.notifier).incrementViewCount(videos[index].id);
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
    final videos = ref.read(channelVideosProvider).videos;
    
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

  // UPDATED: Navigate to channel owner chat with video context (swipe-to-reply style)
  Future<void> _navigateToChannelOwnerChat(ChannelVideoModel? video) async {
    if (video == null) {
      debugPrint('No video available for DM');
      return;
    }

    final currentUser = ref.read(authenticationProvider).valueOrNull?.userModel;
    if (currentUser == null) {
      debugPrint('User not authenticated');
      return;
    }

    // Check if user is trying to DM themselves
    if (video.userId == currentUser.uid) {
      _showCannotDMSelfMessage();
      return;
    }

    // Pause video before navigation
    _pauseForNavigation();

    try {
      // Get channel details to get channel owner info
      final channel = await ref.read(channelsProvider.notifier).getChannelById(video.channelId);
      
      if (channel == null) {
        debugPrint('Channel not found');
        _resumeFromNavigation();
        return;
      }

      // Get channel owner's user data
      final authNotifier = ref.read(authenticationProvider.notifier);
      final channelOwner = await authNotifier.getUserDataById(channel.ownerId);
      
      if (channelOwner == null) {
        debugPrint('Channel owner not found');
        _resumeFromNavigation();
        return;
      }

      // Create or get existing chat (without sending video yet)
      final chatListNotifier = ref.read(chatListProvider.notifier);
      final chatId = await chatListNotifier.createChat(channelOwner.uid); // No video context here
      
      if (chatId != null && mounted) {
        // Create a video message model for context (not sent yet)
        final videoContext = MessageModel(
          messageId: '', // Empty ID since it's not sent yet
          chatId: chatId,
          senderId: currentUser.uid,
          content: '', // No content yet - user will add their own message
          type: MessageEnum.video,
          status: MessageStatus.sending,
          timestamp: DateTime.now(),
          mediaUrl: video.videoUrl,
          mediaMetadata: {
            'isSharedVideo': true,
            'videoId': video.id,
            'thumbnailUrl': video.isMultipleImages && video.imageUrls.isNotEmpty 
                ? video.imageUrls.first 
                : video.thumbnailUrl,
          },
        );

        // Navigate to chat screen with video context
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chatId,
              contact: channelOwner,
              videoContext: videoContext, // Pass video as context (like reply)
            ),
          ),
        );

        // Check if any message was sent (video or text)
        if (result == null || result == false) {
          final hasMessages = await chatListNotifier.chatHasMessages(chatId);
          
          if (!hasMessages) {
            // Delete the empty chat if no messages were sent
            await chatListNotifier.deleteChat(
              chatId, 
              currentUser.uid, 
              deleteForEveryone: true
            );
          }
        }
      } else if (mounted) {
        debugPrint('Failed to create chat with channel owner');
      }
    } catch (e) {
      debugPrint('Error navigating to channel owner chat: $e');
    } finally {
      // Resume video after returning from navigation
      _resumeFromNavigation();
    }
  }

  // Add helper method to show cannot DM self message
  void _showCannotDMSelfMessage() {
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
              CupertinoIcons.smiley,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot DM Yourself',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You cannot send a direct message to your own channel.',
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

  @override
  void dispose() {
    debugPrint('ChannelsFeedScreen: Disposing');
    
    WidgetsBinding.instance.removeObserver(this);
    
    _cacheCleanupTimer?.cancel();
    
    _pageController.dispose();
    
    _stopPlayback();
    _cacheService.dispose();
    
    // Restore original system UI on dispose
    _restoreOriginalSystemUI();
    
    WakelockPlus.disable();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Setup system UI for current theme
    _setupSystemUI();
    
    final channelVideosState = ref.watch(channelVideosProvider);
    final channelsState = ref.watch(channelsProvider);
    final systemTopPadding = MediaQuery.of(context).padding.top;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Show loading screen during channel ensuring or initial video loading
    if ((_isFirstLoad && channelVideosState.isLoading) || _isChannelEnsuring || channelsState.isEnsuring) {
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
              Text(
                _isChannelEnsuring || channelsState.isEnsuring 
                    ? 'Setting up your channel...'
                    : 'Loading videos...',
                style: const TextStyle(
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
            // Main content - positioned to avoid covering status bar and system nav
            Positioned(
              top: systemTopPadding,
              left: 0,
              right: 0,
              bottom: systemBottomPadding,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: _buildBody(channelVideosState, channelsState),
              ),
            ),
            
            // Small video window when comments are open
            if (_isCommentsSheetOpen) _buildSmallVideoWindow(),
          
            // Top navigation - simplified header matching moments feed style
            if (!_isCommentsSheetOpen) // Hide top bar when comments are open
              Positioned(
                top: systemTopPadding + 16,
                left: 0,
                right: 0,
                child: _buildSimplifiedHeader(),
              ),
          
            // TikTok-style right side menu
            if (!_isCommentsSheetOpen) // Hide right menu when comments are open
              _buildRightSideMenu(),
          
            // Cache performance indicator (debug mode only)
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

  Widget _buildBody(ChannelVideosState videosState, ChannelsState channelsState) {
    // REMOVED: Create channel prompt - channels are now auto-created
    
    if (!videosState.isLoading && videosState.videos.isEmpty) {
      return _buildEmptyState(channelsState);
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: videosState.videos.length,
      onPageChanged: _onPageChanged,
      physics: _isScreenActive && !_isCommentsSheetOpen ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final video = videosState.videos[index];
        
        return ChannelVideoItem(
          video: video,
          isActive: index == _currentVideoIndex && _isScreenActive && _isAppInForeground && !_isNavigatingAway,
          onVideoControllerReady: _onVideoControllerReady,
          onManualPlayPause: onManualPlayPause,
          isCommentsOpen: _isCommentsSheetOpen, // Pass comments state to video item
        );
      },
    );
  }

  // New simplified header matching moments feed screen style
  Widget _buildSimplifiedHeader() {
    return Row(
      children: [
        // Back button
        Material(
          type: MaterialType.transparency,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              CupertinoIcons.chevron_left,
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
            tooltip: 'Back',
          ),
        ),
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
          onPressed: () {
            // TODO: Add search functionality
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
          tooltip: 'Search',
        ),
      ],
    );
  }

  // TikTok-style right side menu (Douyin icons) - optimized positioning
  Widget _buildRightSideMenu() {
    final videos = ref.watch(channelVideosProvider).videos;
    final currentVideo = videos.isNotEmpty && _currentVideoIndex < videos.length 
        ? videos[_currentVideoIndex] 
        : null;
    final systemBottomPadding = MediaQuery.of(context).padding.bottom;

    return Positioned(
      right: 4, // Much closer to edge
      bottom: systemBottomPadding + 8, // Closer to system nav for better screen utilization
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
          
          // Star button (save/bookmark)
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.star,
              color: Colors.white,
              size: 26,
            ),
            label: '0',
            onTap: () {
              // TODO: Add save/bookmark functionality
            },
          ),
          
          const SizedBox(height: 10),
          
          // Share button
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.arrowshape_turn_up_right,
              color: Colors.white,
              size: 26,
            ),
            label: '0',
            onTap: () => _showShareOptions(),
          ),
          
          const SizedBox(height: 10),
          
          // Gift button
          _buildRightMenuItem(
            child: const Icon(
              CupertinoIcons.gift,
              color: Colors.white,
              size: 26,
            ),
            label: 'Gift',
            onTap: () {
              // TODO: Implement gift functionality
            },
          ),
          
          const SizedBox(height: 10),
          
          // DM button - UPDATED with navigation to chat
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
            onTap: () => _navigateToChannelOwnerChat(currentVideo),
          ),
          
          const SizedBox(height: 10),
          
          // Profile avatar with red border - moved to bottom and changed to rounded square
          _buildRightMenuItem(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8), // Rounded square instead of circle
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6), // Slightly smaller radius for the image
                child: currentVideo?.channelImage.isNotEmpty == true
                    ? Image.network(
                        currentVideo!.channelImage,
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
                                currentVideo?.channelName.isNotEmpty == true
                                    ? currentVideo!.channelName[0].toUpperCase()
                                    : "U",
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
                            currentVideo?.channelName.isNotEmpty == true
                                ? currentVideo!.channelName[0].toUpperCase()
                                : "U",
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

  // UPDATED: Empty state - no more create channel prompt
  Widget _buildEmptyState(ChannelsState channelsState) {
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
            'Start creating content to see videos here',
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

  void _navigateToChannelProfile() async {
    final videos = ref.read(channelVideosProvider).videos;
    if (_currentVideoIndex < videos.length) {
      // Pause video before navigation
      _pauseForNavigation();
      
      final result = await Navigator.of(context).pushNamed(
        Constants.channelProfileScreen,
        arguments: videos[_currentVideoIndex].channelId,
      );
      
      // Resume video after returning from navigation
      _resumeFromNavigation();
    }
  }

  void _likeCurrentVideo(ChannelVideoModel? video) {
    if (video != null) {
      ref.read(channelVideosProvider.notifier).likeVideo(video.id);
    }
  }

  void _showCommentsForCurrentVideo(ChannelVideoModel? video) {
    if (video != null && !_isCommentsSheetOpen) {
      // Set video to small window mode
      _setVideoWindowMode(true);
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.transparent,
        builder: (context) => ChannelCommentsBottomSheet(
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
  }

  void _showShareOptions() {
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
            const Text(
              'Share Video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.copy, 'Copy Link'),
                _buildShareOption(Icons.message, 'Message'),
                _buildShareOption(Icons.more_horiz, 'More'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
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
  static void handleTabChanged(GlobalKey<ChannelsFeedScreenState> feedScreenKey, bool isActive) {
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