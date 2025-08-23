import 'dart:math';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/services/video_cache_service.dart';
import 'package:textgb/features/channels/widgets/comments_bottom_sheet.dart';
import 'package:textgb/features/channels/widgets/channel_video_item.dart';
import 'package:textgb/features/channels/widgets/channel_required_widget.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/chat/providers/chat_provider.dart';
import 'package:textgb/features/chat/screens/chat_screen.dart';
import 'package:textgb/features/chat/models/video_reaction_model.dart';
import 'package:textgb/features/chat/widgets/video_reaction_input.dart';
import 'package:textgb/features/chat/repositories/chat_repository.dart';
import 'package:textgb/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ChannelFeedScreen extends ConsumerStatefulWidget {
  final String videoId;

  const ChannelFeedScreen({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  ConsumerState<ChannelFeedScreen> createState() => _ChannelFeedScreenState();
}

class _ChannelFeedScreenState extends ConsumerState<ChannelFeedScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // Core controllers
  final PageController _pageController = PageController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache service
  final VideoCacheService _cacheService = VideoCacheService();
  
  // State management
  int _currentVideoIndex = 0;
  bool _isAppInForeground = true;
  bool _isScreenActive = true;
  bool _isNavigatingAway = false;
  bool _isManuallyPaused = false;
  bool _isCommentsSheetOpen = false; // Track comments sheet state
  
  // Channel data
  ChannelModel? _channel;
  List<ChannelVideoModel> _channelVideos = [];
  bool _isChannelLoading = true;
  String? _channelError;
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
    _loadChannelData();
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
      statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
  }

  void _setupSystemUI() {
    // Set both status bar and navigation bar to black for immersive experience
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

  Future<void> _loadChannelData() async {
    if (!mounted) return;
    
    setState(() {
      _isChannelLoading = true;
      _channelError = null;
    });

    try {
      // Get the specific video first to find the channel
      final targetVideo = await ref.read(channelVideosProvider.notifier).getVideoById(widget.videoId);
      
      if (targetVideo == null) {
        throw Exception('Video not found');
      }
      
      // Get the channel
      final channel = await ref.read(channelsProvider.notifier).getChannelById(targetVideo.channelId);
      
      if (channel == null) {
        throw Exception('Channel not found');
      }
      
      // Load all channel videos
      final videos = await ref.read(channelVideosProvider.notifier).loadChannelVideos(targetVideo.channelId);
      
      // Find the index of the target video
      final targetIndex = videos.indexWhere((video) => video.id == widget.videoId);
      
      final followedChannels = ref.read(channelsProvider).followedChannels;
      final isFollowing = followedChannels.contains(targetVideo.channelId);
      final userChannel = ref.read(channelsProvider).userChannel;
      final isOwner = userChannel != null && userChannel.id == targetVideo.channelId;
      
      if (mounted) {
        setState(() {
          _channel = channel;
          _channelVideos = videos;
          _isFollowing = isFollowing;
          _isOwner = isOwner;
          _isChannelLoading = false;
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
          _channelError = e.toString();
          _isChannelLoading = false;
        });
      }
    }
  }

  void _startIntelligentPreloading() {
    if (!_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isCommentsSheetOpen) return;
    
    if (_channelVideos.isEmpty) return;
    
    debugPrint('Starting intelligent preloading for index: $_currentVideoIndex');
    _cacheService.preloadVideosIntelligently(_channelVideos, _currentVideoIndex);
  }

  void _startFreshPlayback() {
    if (!mounted || !_isScreenActive || !_isAppInForeground || _isNavigatingAway || _isManuallyPaused || _isCommentsSheetOpen) return;
    
    debugPrint('ChannelFeedScreen: Starting fresh playback');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.play();
      debugPrint('ChannelFeedScreen: Video controller playing');
    } else {
      // If video controller isn't ready, trigger a re-initialization
      debugPrint('ChannelFeedScreen: Video controller not ready, attempting initialization');
      if (_channelVideos.isNotEmpty && _currentVideoIndex < _channelVideos.length) {
        // This will trigger the video item to reinitialize if needed
        setState(() {});
      }
    }
    
    _startIntelligentPreloading();
    
    WakelockPlus.enable();
  }

  void _stopPlayback() {
    debugPrint('ChannelFeedScreen: Stopping playback');
    
    if (_currentVideoController?.value.isInitialized == true) {
      _currentVideoController!.pause();
      // Only seek to beginning if not in comments mode
      if (!_isCommentsSheetOpen) {
        _currentVideoController!.seekTo(Duration.zero);
      }
    }
  }

  void _pauseForNavigation() {
    debugPrint('ChannelFeedScreen: Pausing for navigation');
    _isNavigatingAway = true;
    _stopPlayback();
  }

  void _resumeFromNavigation() {
    debugPrint('ChannelFeedScreen: Resuming from navigation');
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

  // Add method to control video window mode
  void _setVideoWindowMode(bool isSmallWindow) {
    setState(() {
      _isCommentsSheetOpen = isSmallWindow;
    });
    
    // Don't pause the video controller here - let it continue playing in small window
    // The video item will handle the display logic based on isCommentsOpen state
  }

  // Add this new method to build the small video window
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
    if (_channelVideos.isEmpty || _currentVideoIndex >= _channelVideos.length) {
      return Container(color: Colors.black);
    }
    
    final currentVideo = _channelVideos[_currentVideoIndex];
    
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

  void onManualPlayPause(bool isPlaying) {
    debugPrint('ChannelFeedScreen: Manual play/pause - isPlaying: $isPlaying');
    setState(() {
      _isManuallyPaused = !isPlaying;
    });
  }

  void _onPageChanged(int index) {
    if (index >= _channelVideos.length || !_isScreenActive) return;

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
    
    ref.read(channelVideosProvider.notifier).incrementViewCount(_channelVideos[index].id);
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
        statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
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

  // Add navigation to channel profile
  void _navigateToChannelProfile() async {
    if (_channel == null) return;
    
    // Pause current video and disable wakelock before navigation
    _pauseForNavigation();
    
    // Navigate to channel profile screen
    await Navigator.pushNamed(
      context,
      Constants.channelProfileScreen,
      arguments: _channel!.id,
    );
    
    // Resume video when returning (if still active)
    _resumeFromNavigation();
  }

  // NEW: Navigate to channel owner chat with video reaction system
  Future<void> _navigateToChannelOwnerChat(ChannelVideoModel? video) async {
    if (video == null) {
      debugPrint('No video available for reaction');
      return;
    }

    final currentUser = ref.read(authenticationProvider).valueOrNull?.userModel;
    if (currentUser == null) {
      debugPrint('User not authenticated');
      return;
    }

    // Check if user is trying to react to their own video
    if (video.userId == currentUser.uid) {
      _showCannotReactToOwnVideoMessage();
      return;
    }

    // Pause video before showing reaction input
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

      // Show reaction input bottom sheet
      final reaction = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VideoReactionInput(
          video: video,
          onSendReaction: (reaction) => Navigator.pop(context, reaction),
          onCancel: () => Navigator.pop(context),
        ),
      );

      // If reaction was provided, create chat and send reaction
      if (reaction != null && reaction.trim().isNotEmpty && mounted) {
        final chatListNotifier = ref.read(chatListProvider.notifier);
        final chatId = await chatListNotifier.createOrGetChat(currentUser.uid, channelOwner.uid);
        
        if (chatId != null) {
          // Send video reaction message
          await _sendVideoReactionMessage(
            chatId: chatId,
            video: video,
            reaction: reaction,
            senderId: currentUser.uid,
          );

          // Navigate to chat to show the sent reaction
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatId: chatId,
                contact: channelOwner,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating video reaction: $e');
      _showSnackBar('Failed to send reaction');
    } finally {
      // Resume video after interaction
      _resumeFromNavigation();
    }
  }

  // Helper method to send video reaction message
  Future<void> _sendVideoReactionMessage({
    required String chatId,
    required ChannelVideoModel video,
    required String reaction,
    required String senderId,
  }) async {
    try {
      final chatRepository = ref.read(chatRepositoryProvider);
      
      // Create video reaction data
      final videoReaction = VideoReactionModel(
        videoId: video.id,
        videoUrl: video.videoUrl,
        thumbnailUrl: video.isMultipleImages && video.imageUrls.isNotEmpty 
            ? video.imageUrls.first 
            : video.thumbnailUrl,
        channelName: video.channelName,
        channelImage: video.channelImage,
        reaction: reaction,
        timestamp: DateTime.now(),
      );

      // Send as a video reaction message
      await chatRepository.sendVideoReactionMessage(
        chatId: chatId,
        senderId: senderId,
        videoReaction: videoReaction,
      );
      
    } catch (e) {
      debugPrint('Error sending video reaction message: $e');
      rethrow;
    }
  }

  // Helper method to show cannot react to own video message
  void _showCannotReactToOwnVideoMessage() {
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
              Icons.info_outline,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Cannot React to Your Own Video',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You cannot send reactions to your own channel videos.',
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
    
    // Final wakelock disable
    WakelockPlus.disable();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isChannelLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    if (_channelError != null) {
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
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)), // Add rounded corners
          child: Stack(
            children: [
              // Main video content - positioned to avoid covering status bar and system nav
              Positioned(
                top: systemTopPadding, // Start below status bar
                left: 0,
                right: 0,
                bottom: systemBottomPadding, // Reserve space above system nav
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(12)), // Match parent corners
                  child: _buildVideoFeed(),
                ),
              ),
              
              // Small video window when comments are open
              if (_isCommentsSheetOpen) _buildSmallVideoWindow(),
              
              // Top navigation - updated header with channel name (hide when comments open)
              if (!_isCommentsSheetOpen)
                Positioned(
                  top: systemTopPadding + 16, // Same positioning as single video screen
                  left: 0,
                  right: 16, // Add right padding to align with video content
                  child: _buildChannelHeader(),
                ),
              
              // TikTok-style right side menu - matching channels feed (hide when comments open)
              if (!_isCommentsSheetOpen) _buildRightSideMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoFeed() {
    if (_channelVideos.isEmpty) {
      return _buildEmptyState();
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _channelVideos.length,
      onPageChanged: _onPageChanged,
      physics: _isScreenActive && !_isCommentsSheetOpen ? null : const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final video = _channelVideos[index];
        
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

  // Simplified header with only back button
  Widget _buildChannelHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Back button - using same style as single video screen
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

  // TikTok-style right side menu (matching channels feed exactly)
  Widget _buildRightSideMenu() {
    final currentVideo = _channelVideos.isNotEmpty && _currentVideoIndex < _channelVideos.length 
        ? _channelVideos[_currentVideoIndex] 
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
              currentVideo?.isLiked == true ? CupertinoIcons.heart : CupertinoIcons.heart,
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
          
          
          // DM button - UPDATED with video reaction navigation
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined, color: Colors.white, size: 80),
          const SizedBox(height: 24),
          const Text(
            'No Videos Yet',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _isOwner 
                ? 'Create your first video to share with your followers'
                : 'This channel hasn\'t posted any videos yet',
            style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (_isOwner) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Check if user has channel before allowing creation
                final hasChannel = await requireUserChannel(
                  context,
                  ref,
                  customTitle: 'Channel Required',
                  customSubtitle: 'You need to create a channel before you can upload content.',
                  customActionText: 'Create Channel',
                  customIcon: Icons.video_call,
                );
                
                if (hasChannel && mounted) {
                  Navigator.pushNamed(context, Constants.createChannelPostScreen);
                }
              },
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
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _channelError!,
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
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}