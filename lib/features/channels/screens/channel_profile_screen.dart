// lib/features/channels/screens/channel_profile_screen.dart
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
import 'package:textgb/constants.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ChannelProfileScreen extends ConsumerStatefulWidget {
  final String channelId;

  const ChannelProfileScreen({
    Key? key,
    required this.channelId,
  }) : super(key: key);

  @override
  ConsumerState<ChannelProfileScreen> createState() => _ChannelProfileScreenState();
}

class _ChannelProfileScreenState extends ConsumerState<ChannelProfileScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // Core controllers
  final PageController _pageController = PageController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache service
  final VideoCacheService _cacheService = VideoCacheService();
  
  // State management
  int _currentVideoIndex = 0;
  
  // Caption expansion state
  Map<int, bool> _expandedCaptions = {};
  
  // Channel data
  ChannelModel? _channel;
  List<ChannelVideoModel> _channelVideos = [];
  bool _isChannelLoading = true;
  String? _channelError;
  bool _isFollowing = false;
  bool _isOwner = false;
  
  // Video controllers
  Map<int, VideoPlayerController> _videoControllers = {};
  Map<int, bool> _videoInitialized = {};
  Timer? _cacheCleanupTimer;
  
  // Progress tracking
  Timer? _progressTimer;
  double _currentProgress = 0.0;
  
  // Animation controller for image carousels
  late AnimationController _imageProgressController;
  late AnimationController _progressController;
  
  // Bottom nav bar constants
  static const double _bottomNavContentHeight = 60.0;
  static const double _progressBarHeight = 3.0;
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupSystemUI();
    _loadChannelData();
    _setupCacheCleanup();
    _initializeAnimationControllers();
  }
  
  void _initializeAnimationControllers() {
    _imageProgressController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
  }

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
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
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _pauseCurrentVideo();
        break;
      case AppLifecycleState.resumed:
        _playCurrentVideo();
        break;
      default:
        break;
    }
  }

  Future<void> _loadChannelData() async {
    setState(() {
      _isChannelLoading = true;
      _channelError = null;
    });

    try {
      final channel = await ref.read(channelsProvider.notifier).getChannelById(widget.channelId);
      
      if (channel == null) {
        throw Exception('Channel not found');
      }
      
      final videos = await ref.read(channelVideosProvider.notifier).loadChannelVideos(widget.channelId);
      final followedChannels = ref.read(channelsProvider).followedChannels;
      final isFollowing = followedChannels.contains(widget.channelId);
      final userChannel = ref.read(channelsProvider).userChannel;
      final isOwner = userChannel != null && userChannel.id == widget.channelId;
      
      if (mounted) {
        setState(() {
          _channel = channel;
          _channelVideos = videos;
          _isFollowing = isFollowing;
          _isOwner = isOwner;
          _isChannelLoading = false;
        });
        
        _initializeVideoControllers();
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

  void _initializeVideoControllers() {
    for (int i = 0; i < _channelVideos.length; i++) {
      final video = _channelVideos[i];
      if (!video.isMultipleImages && video.videoUrl.isNotEmpty) {
        _initializeVideoController(i, video.videoUrl);
      }
    }
    
    if (_channelVideos.isNotEmpty) {
      _playCurrentVideo();
      _startProgressTracking();
    }
  }

  Future<void> _initializeVideoController(int index, String videoUrl) async {
    try {
      File? cachedFile;
      try {
        if (await _cacheService.isVideoCached(videoUrl)) {
          cachedFile = await _cacheService.getCachedVideo(videoUrl);
        } else {
          cachedFile = await _cacheService.preloadVideo(videoUrl);
        }
      } catch (e) {
        debugPrint('Cache error, falling back to network: $e');
      }

      VideoPlayerController controller;
      if (cachedFile != null && await cachedFile.exists()) {
        controller = VideoPlayerController.file(cachedFile);
      } else {
        controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }
      
      _videoControllers[index] = controller;
      
      await controller.initialize();
      controller.setLooping(true);
      
      if (mounted) {
        setState(() {
          _videoInitialized[index] = true;
        });
      }
      
      if (index == _currentVideoIndex) {
        controller.play();
      }
    } catch (e) {
      debugPrint('Error initializing video $index: $e');
    }
  }

  void _onPageChanged(int index) {
    if (index >= _channelVideos.length) return;

    _pauseCurrentVideo();
    _stopProgressTracking();
    
    setState(() {
      _currentVideoIndex = index;
      _currentProgress = 0.0;
      _progressNotifier.value = 0.0;
    });

    _playCurrentVideo();
    _startProgressTracking();
    _cacheService.preloadVideosIntelligently(_channelVideos, index);
    ref.read(channelVideosProvider.notifier).incrementViewCount(_channelVideos[index].id);
  }
  
  void _startProgressTracking() {
    _progressTimer?.cancel();
    
    final currentVideo = _channelVideos[_currentVideoIndex];
    
    if (currentVideo.isMultipleImages) {
      // For images, use animation controller
      _imageProgressController.reset();
      _imageProgressController.forward();
      _imageProgressController.addListener(_updateImageProgress);
    } else {
      // For videos, track actual video progress
      _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        final controller = _videoControllers[_currentVideoIndex];
        if (controller != null && controller.value.isInitialized) {
          final position = controller.value.position;
          final duration = controller.value.duration;
          
          if (duration.inMilliseconds > 0) {
            final progress = position.inMilliseconds / duration.inMilliseconds;
            setState(() {
              _currentProgress = progress;
            });
            _progressNotifier.value = progress;
          }
        }
      });
    }
  }
  
  void _stopProgressTracking() {
    _progressTimer?.cancel();
    _imageProgressController.removeListener(_updateImageProgress);
    _imageProgressController.stop();
  }
  
  void _updateImageProgress() {
    final progress = _imageProgressController.value;
    setState(() {
      _currentProgress = progress;
    });
    _progressNotifier.value = progress;
  }

  void _playCurrentVideo() {
    final controller = _videoControllers[_currentVideoIndex];
    if (controller != null && _videoInitialized[_currentVideoIndex] == true) {
      controller.seekTo(Duration.zero);
      controller.play();
      WakelockPlus.enable();
    }
  }

  void _pauseCurrentVideo() {
    final controller = _videoControllers[_currentVideoIndex];
    if (controller != null && _videoInitialized[_currentVideoIndex] == true) {
      controller.pause();
      WakelockPlus.disable();
    }
  }

  void _togglePlayPause() {
    final controller = _videoControllers[_currentVideoIndex];
    if (controller != null && _videoInitialized[_currentVideoIndex] == true) {
      if (controller.value.isPlaying) {
        controller.pause();
        WakelockPlus.disable();
      } else {
        controller.play();
        WakelockPlus.enable();
      }
    }
  }

  void _toggleFollow() async {
    if (_channel == null) return;
    
    setState(() {
      _isFollowing = !_isFollowing;
    });
    
    await ref.read(channelsProvider.notifier).toggleFollowChannel(_channel!.id);
  }

  void _toggleCaptionExpansion(int index) {
    setState(() {
      _expandedCaptions[index] = !(_expandedCaptions[index] ?? false);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF424242),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.8,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    _cacheService.dispose();
    _cacheCleanupTimer?.cancel();
    _progressTimer?.cancel();
    _imageProgressController.dispose();
    _progressController.dispose();
    _progressNotifier.dispose();
    
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoInitialized.clear();
    
    _pageController.dispose();
    
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
    
    final modernTheme = context.modernTheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalBottomNavHeight = _bottomNavContentHeight + _progressBarHeight + bottomPadding;
    
    return WillPopScope(
      onWillPop: () async {
        // Reset system UI when user navigates back
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ));
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Stack(
          children: [
            // Main video content - FULL SCREEN (fills entire screen)
            Positioned.fill(
              bottom: totalBottomNavHeight,
              child: _buildVideoFeed(),
            ),
            
            // Top bar overlay - Back arrow and Search
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
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
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.search,
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
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom content overlay
            _buildBottomContent(),
            
            // Bottom navigation bar with progress indicator
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNavigationBar(modernTheme),
            ),
          ],
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
      itemBuilder: (context, index) {
        final video = _channelVideos[index];
        
        return GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: _buildVideoContent(video, index),
          ),
        );
      },
    );
  }

  Widget _buildVideoContent(ChannelVideoModel video, int index) {
    if (video.isMultipleImages) {
      return _buildImageCarousel(video.imageUrls);
    } else if (video.videoUrl.isNotEmpty) {
      return _buildVideoPlayer(index);
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildVideoPlayer(int index) {
    final controller = _videoControllers[index];
    final isInitialized = _videoInitialized[index] ?? false;
    
    if (controller == null || !isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) return _buildPlaceholder();
    
    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        enableInfiniteScroll: imageUrls.length > 1,
        autoPlay: imageUrls.length > 1,
        autoPlayInterval: const Duration(seconds: 4),
      ),
      items: imageUrls.map((imageUrl) {
        return SizedBox.expand(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }

  // Bottom content overlay - Profile + Follow + Caption
  Widget _buildBottomContent() {
    if (_channelVideos.isEmpty || _currentVideoIndex >= _channelVideos.length || _channel == null) {
      return const SizedBox.shrink();
    }
    
    final currentVideo = _channelVideos[_currentVideoIndex];
    final isExpanded = _expandedCaptions[_currentVideoIndex] ?? false;
    
    return Positioned(
      bottom: 130, // Adjusted for bottom nav bar
      left: 16,
      right: 16, // Adjusted since we removed the right menu
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile + Username + Follow button row
          Row(
            children: [
              // Profile circle - smaller like in your image
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _channel!.profileImage.isNotEmpty
                      ? Image.network(_channel!.profileImage, fit: BoxFit.cover)
                      : Container(
                          color: const Color(0xFF616161),
                          child: Center(
                            child: Text(
                              _channel!.name.isNotEmpty ? _channel!.name[0].toUpperCase() : 'C',
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
              
              const SizedBox(width: 10),
              
              // Username
              Expanded(
                child: Text(
                  _channel!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Follow button - EXACTLY like your reference images (gray background)
              if (!_isOwner)
                GestureDetector(
                  onTap: _toggleFollow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF616161).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Caption
          GestureDetector(
            onTap: () => _toggleCaptionExpansion(_currentVideoIndex),
            child: Text(
              currentVideo.caption.isNotEmpty ? currentVideo.caption : 'Sirin Amin Zehra Sirin Vefalim Dance',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              maxLines: isExpanded ? null : 1,
              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 2),
          
          // Hashtags with More
          GestureDetector(
            onTap: () => _toggleCaptionExpansion(_currentVideoIndex),
            child: isExpanded
                ? Text(
                    currentVideo.tags.isNotEmpty 
                        ? currentVideo.tags.map((tag) => '#$tag').join(' ')
                        : '#shortvideo #dance #popular #trending',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Flexible(
                        child: Text(
                          currentVideo.tags.isNotEmpty 
                              ? currentVideo.tags.map((tag) => '#$tag').join(' ')
                              : '#shortvideo #dance #popul...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'More',
                        style: TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                  ),
          ),
        ],
      ),
    );
  }

  // Progress bar widget for the bottom nav divider
  Widget _buildProgressBar(ModernThemeExtension modernTheme) {
    return ValueListenableBuilder<double>(
      valueListenable: _progressNotifier,
      builder: (context, progress, child) {
        return Container(
          height: _progressBarHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: MediaQuery.of(context).size.width * progress.clamp(0.0, 1.0),
                height: _progressBarHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      modernTheme.primaryColor ?? Colors.blue,
                      (modernTheme.primaryColor ?? Colors.blue).withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Bottom navigation bar widget - Now with 5 tabs matching channels_feed_screen
  Widget _buildBottomNavigationBar(ModernThemeExtension modernTheme) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final totalHeight = _bottomNavContentHeight + _progressBarHeight + bottomPadding;
    
    // Get current video for likes and comments count
    final videos = _channelVideos;
    final currentVideo = videos.isNotEmpty && _currentVideoIndex < videos.length 
        ? videos[_currentVideoIndex] 
        : null;
    
    return Container(
      height: totalHeight,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Column(
        children: [
          // Progress bar as divider
          _buildProgressBar(modernTheme),
          
          // Navigation content
          Container(
            height: _bottomNavContentHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isActive: true,
                  onTap: () {},
                  iconColor: Colors.white,
                  labelColor: Colors.white,
                ),
                _buildNavItem(
                  icon: Icons.search,
                  activeIcon: Icons.search,
                  label: 'Search',
                  isActive: false,
                  onTap: () {},
                  iconColor: Colors.white,
                  labelColor: Colors.white,
                ),
                _buildNavItem(
                  icon: Icons.add_circle,
                  activeIcon: Icons.add_circle,
                  label: 'Post',
                  isActive: false,
                  onTap: _navigateToCreatePost,
                  iconColor: Colors.white,
                  labelColor: Colors.white,
                ),
                _buildNavItemWithBadge(
                  icon: currentVideo?.isLiked == true ? Icons.favorite : Icons.favorite,
                  activeIcon: Icons.favorite,
                  label: 'Likes',
                  isActive: false,
                  onTap: () => _likeCurrentVideo(currentVideo),
                  iconColor: currentVideo?.isLiked == true ? const Color(0xFFFF3040) : Colors.white,
                  labelColor: Colors.white,
                  badgeCount: currentVideo?.likes ?? 0,
                ),
                _buildNavItemWithBadge(
                  icon: CupertinoIcons.text_bubble_fill,
                  activeIcon: CupertinoIcons.text_bubble_fill,
                  label: 'Comments',
                  isActive: false,
                  onTap: () {}, // No action needed for comments in profile screen
                  iconColor: Colors.white,
                  labelColor: Colors.white,
                  badgeCount: currentVideo?.comments ?? 0,
                ),
              ],
            ),
          ),
          
          // System navigation bar space
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: iconColor ?? (isActive ? Colors.white : Colors.white.withOpacity(0.6)),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: labelColor ?? (isActive ? Colors.white : Colors.white.withOpacity(0.6)),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
    required int badgeCount,
  }) {
    final modernTheme = context.modernTheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: iconColor ?? (isActive ? Colors.white : Colors.white.withOpacity(0.6)),
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor ?? Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _formatCount(badgeCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: labelColor ?? (isActive ? Colors.white : Colors.white.withOpacity(0.6)),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
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
              onPressed: () => Navigator.pushNamed(context, Constants.createChannelPostScreen),
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
            'Error Loading Channel',
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
            onPressed: () => Navigator.of(context).pop(),
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

  void _navigateToCreatePost() async {
    final result = await Navigator.pushNamed(context, Constants.createChannelPostScreen);
    if (result == true) {
      _pauseCurrentVideo();
      
      await ref.read(channelVideosProvider.notifier).loadChannelVideos(widget.channelId);
      
      setState(() {
        _currentProgress = 0.0;
      });
      _progressNotifier.value = 0.0;
      _progressTimer?.cancel();
      _imageProgressController.reset();
      if (_channelVideos.isNotEmpty) {
        _imageProgressController.forward();
      }
    }
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}