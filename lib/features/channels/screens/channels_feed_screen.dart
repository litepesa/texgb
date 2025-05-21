// lib/features/channels/screens/channels_feed_screen.dart
// Enhanced with video preloading for smoother transitions

import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/widgets/channel_video_item.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; // Add Wakelock package

class ChannelsFeedScreen extends ConsumerStatefulWidget {
  const ChannelsFeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChannelsFeedScreen> createState() => _ChannelsFeedScreenState();
}

class _ChannelsFeedScreenState extends ConsumerState<ChannelsFeedScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _progressController;
  bool _isFirstLoad = true;
  int _currentVideoIndex = 0;
  
  // Track progress and video directly
  double _videoProgress = 0.0;
  VideoPlayerController? _currentVideoController;
  Timer? _progressUpdateTimer;
  
  // Video preloading for smoother transitions
  final Map<int, VideoPlayerController> _preloadedControllers = {};
  final int _maxPreloadedVideos = 4; // Maximum number of videos to preload
  final Set<int> _preloadingInProgress = {};
  
  // Queue for videos to preload
  final Queue<int> _videoPreloadQueue = Queue<int>();
  bool _isProcessingQueue = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    
    // Set up the progress controller - now used as a fallback only
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addListener(() {
      setState(() {
        // Only use the animation controller's value if we don't have a video controller
        if (_currentVideoController == null || !_currentVideoController!.value.isInitialized) {
          _videoProgress = _progressController.value;
        }
      });
    });
    
    // Set up transparent status bar for immersive experience
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    
    // Keep the screen on while in the feed
    WakelockPlus.enable();
  }

  Future<void> _loadVideos() async {
    // Only load on first load
    if (_isFirstLoad) {
      debugPrint('ChannelsFeedScreen: Initial video load');
      await ref.read(channelVideosProvider.notifier).debugChannelVideosData();
      await ref.read(channelVideosProvider.notifier).loadVideos();
      
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
        });
        // Start progress animation when videos are loaded (fallback)
        _progressController.forward();
        
        // Start preloading videos after initial load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _preloadNextVideos();
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    _currentVideoController?.dispose();
    _progressUpdateTimer?.cancel();
    
    // Clean up all preloaded controllers
    for (final controller in _preloadedControllers.values) {
      controller.dispose();
    }
    _preloadedControllers.clear();
    
    // Allow the screen to turn off again when leaving the feed
    WakelockPlus.disable();
    
    // Reset system UI when leaving this screen
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    super.dispose();
  }
  
  // Set up video progress tracking with direct timer updates
  void _setupVideoProgressTracking() {
    // Cancel any existing timer
    _progressUpdateTimer?.cancel();
    
    // Start a new timer that updates every 100ms
    _progressUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_currentVideoController != null && 
          _currentVideoController!.value.isInitialized &&
          _currentVideoController!.value.isPlaying) {
        
        final position = _currentVideoController!.value.position;
        final duration = _currentVideoController!.value.duration;
        
        // Avoid division by zero
        if (duration.inMilliseconds > 0) {
          final progress = position.inMilliseconds / duration.inMilliseconds;
          
          // Only update if value is valid
          if (progress >= 0 && progress <= 1) {
            setState(() {
              _videoProgress = progress;
            });
          }
          
          // If nearing the end of video, ensure next videos are preloaded
          if (progress > 0.8 && _videoPreloadQueue.isEmpty) {
            _preloadNextVideos();
          }
        }
      }
    });
  }
  
  // Handle video controller ready callback from ChannelVideoItem
  void _onVideoControllerReady(VideoPlayerController controller) {
    setState(() {
      _currentVideoController = controller;
    });
    
    // Setup the progress tracking when we get a new controller
    _setupVideoProgressTracking();
    
    // Stop the fallback animation controller if it's running
    if (_progressController.isAnimating) {
      _progressController.stop();
    }
    
    // Preload the next videos
    _preloadNextVideos();
  }
  
  // Preload videos around the current index for smoother transitions
  void _preloadNextVideos() {
    final videos = ref.read(channelVideosProvider).videos;
    if (videos.isEmpty) return;
    
    // Queue up videos to preload (next several videos)
    for (int i = 1; i <= _maxPreloadedVideos; i++) {
      final index = _currentVideoIndex + i;
      if (index < videos.length && 
          !_preloadedControllers.containsKey(index) && 
          !_preloadingInProgress.contains(index) &&
          !videos[index].isMultipleImages) {
        _videoPreloadQueue.add(index);
      }
    }
    
    // Process the queue if not already processing
    if (!_isProcessingQueue) {
      _processPreloadQueue();
    }
  }
  
  void _processPreloadQueue() async {
    if (_videoPreloadQueue.isEmpty) {
      _isProcessingQueue = false;
      return;
    }
    
    _isProcessingQueue = true;
    
    final videos = ref.read(channelVideosProvider).videos;
    
    // Process up to _maxPreloadedVideos at a time
    while (_videoPreloadQueue.isNotEmpty && 
           _preloadedControllers.length < _maxPreloadedVideos) {
      
      final index = _videoPreloadQueue.removeFirst();
      if (index >= videos.length || 
          _preloadedControllers.containsKey(index) || 
          _preloadingInProgress.contains(index) ||
          videos[index].isMultipleImages) {
        continue;
      }
      
      // Mark this index as being preloaded
      _preloadingInProgress.add(index);
      
      try {
        // Create and initialize the controller
        final video = videos[index];
        final controller = VideoPlayerController.network(video.videoUrl);
        await controller.initialize();
        
        // Only add to preloaded controllers if still relevant
        // (user might have scrolled far away during loading)
        if (mounted && 
            (index > _currentVideoIndex) && 
            (index <= _currentVideoIndex + _maxPreloadedVideos)) {
          _preloadedControllers[index] = controller;
          debugPrint('Preloaded video: $index');
        } else {
          // No longer needed, dispose immediately
          controller.dispose();
          debugPrint('Preloaded video $index no longer needed, disposed');
        }
      } catch (e) {
        debugPrint('Error preloading video $index: $e');
      } finally {
        // Remove from in-progress set regardless of success/failure
        _preloadingInProgress.remove(index);
      }
    }
    
    // Clear any preloaded videos that are no longer needed
    _cleanupOldPreloadedVideos();
    
    _isProcessingQueue = false;
  }
  
  // Clean up videos that are no longer needed
  void _cleanupOldPreloadedVideos() {
    // Identify videos to remove (ones that are outside our preload window)
    final keysToRemove = _preloadedControllers.keys.where(
      (index) => index <= _currentVideoIndex || index > _currentVideoIndex + _maxPreloadedVideos
    ).toList();
    
    // Remove and dispose controllers for these videos
    for (final index in keysToRemove) {
      final controller = _preloadedControllers.remove(index);
      controller?.dispose();
      debugPrint('Cleaned up preloaded video: $index');
    }
  }
  
  // Get a preloaded controller if available
  VideoPlayerController? _getPreloadedController(int index) {
    final controller = _preloadedControllers.remove(index);
    if (controller != null) {
      debugPrint('Using preloaded controller for video: $index');
    }
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    // Read state from providers
    final channelVideosState = ref.watch(channelVideosProvider);
    final channelsState = ref.watch(channelsProvider);
    final modernTheme = context.modernTheme;
    
    // Calculate bottom padding to account for navigation bar and system navigation
    final bottomNavHeight = 100.0; // Increased height to account for system navigation
    
    if (_isFirstLoad) {
      return const _LoadingScreen();
    }
    
    return Scaffold(
      extendBodyBehindAppBar: true, // Extend content behind app bar
      extendBody: true, // Extend content behind bottom nav
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          _buildBody(channelVideosState, channelsState, modernTheme, bottomNavHeight),
          
          // Top transparent gradient for status bar protection
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Search bar at top with transparent background
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    Icons.search,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search channels and videos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Progress bar divider above bottom nav
          Positioned(
            bottom: bottomNavHeight + 8, // Position above bottom nav with gap
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Video progress indicator - now synced with actual video position
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                    value: _videoProgress,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(modernTheme.primaryColor!),
                  ),
                ),
                // Divider line
                Container(
                  height: 1,
                  color: Colors.grey[900],
                ),
              ],
            ),
          ),
          
          // Show error message if any
          if (channelVideosState.error != null)
            _buildErrorOverlay(channelVideosState.error!, modernTheme),
            
          // Optional: Video preload status indicator (for development/testing)
          // if (kDebugMode)
          //   Positioned(
          //     top: MediaQuery.of(context).padding.top + 60,
          //     right: 16,
          //     child: Container(
          //       padding: const EdgeInsets.all(8),
          //       decoration: BoxDecoration(
          //         color: Colors.black.withOpacity(0.7),
          //         borderRadius: BorderRadius.circular(8),
          //       ),
          //       child: Text(
          //         'Preloaded: ${_preloadedControllers.length}',
          //         style: const TextStyle(color: Colors.white, fontSize: 12),
          //       ),
          //     ),
          //   ),
        ],
      ),
      floatingActionButton: channelsState.userChannel == null
          ? FloatingActionButton(
              backgroundColor: modernTheme.primaryColor,
              onPressed: () => _navigateToCreateChannel(),
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              backgroundColor: modernTheme.primaryColor,
              onPressed: () => _navigateToCreatePost(),
              child: const Icon(Icons.add),
            ),
    );
  }

  // Show error message overlay
  Widget _buildErrorOverlay(String error, ModernThemeExtension modernTheme) {
    return Positioned(
      bottom: 160,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Error: ${error.split(']').last.trim()}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // Build main body content based on state
  Widget _buildBody(ChannelVideosState videosState, ChannelsState channelsState, ModernThemeExtension modernTheme, double bottomPadding) {
    // Show channel creation message if user doesn't have a channel
    if (!videosState.isLoading && channelsState.userChannel == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library,
              color: modernTheme.primaryColor,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Create your Channel',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Create your own channel to start sharing videos and photos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateChannel(),
              icon: const Icon(Icons.add),
              label: const Text('Create Channel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show loading indicator when loading and no videos yet
    if (videosState.isLoading && _isFirstLoad) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading Channels',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Finding the best content for you',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Show empty state when no videos
    if (!videosState.isLoading && videosState.videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              color: modernTheme.primaryColor,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'No Videos Yet',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                channelsState.userChannel != null
                    ? 'Be the first to share a video or photo in your channel!'
                    : 'Follow channels or create your own to see videos here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (channelsState.userChannel != null)
              ElevatedButton.icon(
                onPressed: () => _navigateToCreatePost(),
                icon: const Icon(Icons.add),
                label: const Text('Create Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: modernTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Video feed with padding at bottom to prevent overlap with nav bar
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: videosState.videos.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  color: modernTheme.primaryColor,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No videos available',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          )
        : PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: videosState.videos.length,
            onPageChanged: (index) {
              // Store the old index for cleanup
              final oldIndex = _currentVideoIndex;
              
              setState(() {
                _currentVideoIndex = index;
                // Reset current video controller reference when page changes
                _currentVideoController = null;
                // Reset video progress
                _videoProgress = 0.0;
              });
              
              // Cancel progress tracking timer
              _progressUpdateTimer?.cancel();
              
              // Reset fallback progress animation for new video
              if (_progressController.isAnimating) {
                _progressController.stop();
              }
              _progressController.reset();
              _progressController.forward();
              
              // Clean up videos that are far from current position
              _cleanupOldPreloadedVideos();
              
              // Preload next videos
              _preloadNextVideos();
              
              // Increment view count when a video is watched
              ref.read(channelVideosProvider.notifier).incrementViewCount(
                videosState.videos[index].id,
              );
            },
            itemBuilder: (context, index) {
              final video = videosState.videos[index];
              
              // Get preloaded controller if available
              final preloadedController = _getPreloadedController(index);
              
              return ChannelVideoItem(
                video: video,
                isActive: index == _currentVideoIndex,
                onVideoControllerReady: _onVideoControllerReady,
                preloadedController: preloadedController,
              );
            },
          ),
    );
  }

  void _navigateToCreateChannel() async {
    // Navigate to CreateChannelScreen
    final result = await Navigator.pushNamed(context, Constants.createChannelScreen);
    
    if (result == true) {
      // Refresh data after channel creation
      ref.read(channelsProvider.notifier).loadUserChannel();
    }
  }

  void _navigateToCreatePost() async {
    // Navigate to CreateChannelPostScreen
    final result = await Navigator.pushNamed(context, Constants.createChannelPostScreen);
    
    if (result == true) {
      // Clean up all preloaded videos since the feed will change
      for (final controller in _preloadedControllers.values) {
        controller.dispose();
      }
      _preloadedControllers.clear();
      _preloadingInProgress.clear();
      _videoPreloadQueue.clear();
      
      // Refresh data after post creation
      ref.read(channelVideosProvider.notifier).loadVideos(forceRefresh: true);
      
      // Reset video progress tracking
      setState(() {
        _videoProgress = 0.0;
      });
      _progressUpdateTimer?.cancel();
      
      if (_progressController.isAnimating) {
        _progressController.stop();
      }
      _progressController.reset();
      _progressController.forward();
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    const wechatGreen = Color(0xFF07C160);
    const darkBackground = Color(0xFF0F0F0F);
    
    return const Scaffold(
      backgroundColor: darkBackground,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(wechatGreen),
        ),
      ),
    );
  }
}