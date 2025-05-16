import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/widgets/channel_video_item.dart';
import 'package:textgb/constants.dart';

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
  double _currentProgress = 0.0;
  final Duration _videoDuration = const Duration(seconds: 30); // Approximate average video duration

  @override
  void initState() {
    super.initState();
    _loadVideos();
    
    // Set up the progress controller for the progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: _videoDuration,
    )..addListener(() {
      setState(() {
        _currentProgress = _progressController.value;
      });
    });
    
    // Set up transparent status bar for immersive experience
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
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
        // Start progress animation when videos are loaded
        _progressController.forward();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    // Reset system UI when leaving this screen
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read state from providers
    final channelVideosState = ref.watch(channelVideosProvider);
    final channelsState = ref.watch(channelsProvider);
    final modernTheme = context.modernTheme;
    
    // Calculate bottom padding to account for navigation bar and system navigation
    final bottomNavHeight = 100.0; // Increased height to account for system navigation
    
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
                // Video progress indicator
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                    value: _currentProgress,
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
              setState(() {
                _currentVideoIndex = index;
              });
              
              // Reset progress bar for new video
              _resetProgress();
              
              // Increment view count when a video is watched
              ref.read(channelVideosProvider.notifier).incrementViewCount(
                videosState.videos[index].id,
              );
            },
            itemBuilder: (context, index) {
              final video = videosState.videos[index];
              
              return ChannelVideoItem(
                video: video,
                isActive: index == _currentVideoIndex,
              );
            },
          ),
    );
  }

  void _resetProgress() {
    // Reset and restart progress animation
    _progressController.reset();
    _progressController.forward();
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
      // Refresh data after post creation
      ref.read(channelVideosProvider.notifier).loadVideos(forceRefresh: true);
      _resetProgress();
    }
  }
}