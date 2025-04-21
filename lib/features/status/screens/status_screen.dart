import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/common/videoviewerscreen.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/screens/create_status_screen.dart';
import 'package:textgb/features/status/screens/status_comments_screen.dart';
import 'package:textgb/models/status_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/status_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({Key? key}) : super(key: key);

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> 
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver, RouteAware {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<int, VideoPlayerController> _videoControllers = {};
  bool _isLoadingMore = false;
  bool _isVisible = true; // Track if screen is visible
  
  // Number of videos to preload ahead and behind
  final int _preloadWindow = 2;
  
  // RouteObserver instance
  static RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  bool get wantKeepAlive => true; // Keep the state when switching tabs

  @override
  void initState() {
    super.initState();
    
    // Register for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Ensure we have status posts to show on initial load
    _initialLoadStatus();
    
    // Add page listener to manage video playback
    _pageController.addListener(_pageListener);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route != null && route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Unsubscribe from route observer
    routeObserver.unsubscribe(this);
    
    // Dispose all video controllers
    _pauseAllVideos();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    
    _pageController.removeListener(_pageListener);
    _pageController.dispose();
    super.dispose();
  }
  
  // Called when the system puts the app in the background or returns the app to the foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is in background or inactive, pause all videos
        _pauseAllVideos();
        break;
      case AppLifecycleState.resumed:
        // App is in foreground, resume current video if screen is visible
        if (_isVisible) {
          _resumeCurrentVideo();
        }
        break;
      default:
        break;
    }
  }
  
  // Called when this route is pushed/popped
  @override
  void didPushNext() {
    // Another route has been pushed, pause videos
    _setVisibility(false);
    super.didPushNext();
  }
  
  @override
  void didPopNext() {
    // Returned to this route, resume videos
    _setVisibility(true);
    super.didPopNext();
  }
  
  // Method to handle tab visibility changes
  void handleVisibilityChanged(bool isVisible) {
    if (_isVisible != isVisible) {
      _setVisibility(isVisible);
    }
  }
  
  // Set screen visibility and manage video playback accordingly
  void _setVisibility(bool isVisible) {
    _isVisible = isVisible;
    if (isVisible) {
      _resumeCurrentVideo();
    } else {
      _pauseAllVideos();
    }
  }
  
  // Pause all videos
  void _pauseAllVideos() {
    for (final controller in _videoControllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
  }
  
  // Resume current video if any
  void _resumeCurrentVideo() {
    if (_videoControllers.containsKey(_currentPage)) {
      _videoControllers[_currentPage]!.play();
    }
  }

  void _pageListener() {
    // When the page settles, get the current page to manage video playing
    if (_pageController.page != null && 
        _pageController.page!.round() != _currentPage) {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
      
      // Stop previous video and play current video
      _manageVideoPlayback();
    }
  }

  Future<void> _initialLoadStatus() async {
    final authProvider = context.read<AuthenticationProvider>();
    final statusProvider = context.read<StatusProvider>();
    
    final currentUser = authProvider.userModel!;
    final contactIds = currentUser.contactsUIDs;
    
    // Load user status feed including public posts
    if (!statusProvider.initialFeedLoaded) {
      await statusProvider.fetchStatusFeed(
        currentUserId: currentUser.uid,
        contactIds: contactIds,
      );
    }
    
    // Initialize video controller for first visible item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentPage = 0;
      _initializeVideoController(0);
      
      // Preload a few more videos for smoother scrolling
      for (int i = 1; i <= _preloadWindow; i++) {
        _initializeVideoController(i);
      }
    });
  }

  Future<void> _loadStatus() async {
    final statusProvider = context.read<StatusProvider>();
    if (statusProvider.isLoading) return;
    
    setState(() {
      // Use spinner only on first load
      if (statusProvider.statusFeed.isEmpty) {
        statusProvider.setLoading(true);
      }
    });
    
    try {
      final authProvider = context.read<AuthenticationProvider>();
      final currentUser = authProvider.userModel!;
      final contactIds = currentUser.contactsUIDs;
      
      // Fetch status feed
      await statusProvider.fetchStatusFeed(
        currentUserId: currentUser.uid,
        contactIds: contactIds,
      );
      
      // Reset page controller to start
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      
      // Initialize video controller for first visible item
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _currentPage = 0;
        
        // Initialize first video plus preload window
        for (int i = 0; i <= _preloadWindow; i++) {
          _initializeVideoController(i);
        }
      });
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error loading status feed: $e');
      }
    } finally {
      if (mounted) {
        statusProvider.setLoading(false);
      }
    }
  }

  Future<void> _initializeVideoController(int index) async {
    final statusProvider = context.read<StatusProvider>();
    final statuses = statusProvider.statusFeed;
    
    // Skip if out of bounds
    if (index < 0 || index >= statuses.length) return;
    
    final status = statuses[index];
    
    // Only initialize if it's a video and has media URL
    if (status.statusType == StatusType.video && status.statusUrl.isNotEmpty) {
      // Skip if controller already exists
      if (_videoControllers.containsKey(index)) return;
      
      try {
        final controller = VideoPlayerController.network(
          status.statusUrl,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false, // Better audio handling
          ),
        );
        
        // Store controller with index
        _videoControllers[index] = controller;
        
        // Initialize and prepare video
        await controller.initialize();
        
        // Set to loop
        controller.setLooping(true);
        
        // Set volume
        controller.setVolume(1.0);
        
        // Optimize playback by setting video quality
        if (controller.value.size.width > 0) {
          // For smaller device screens, lower quality can be used
          final screenWidth = MediaQuery.of(context).size.width;
          if (controller.value.size.width > screenWidth * 1.5) {
            // Video is significantly higher resolution than needed
            // We could set a lower quality here if the API supported it
          }
        }
        
        // Only update UI and play if this is the current page and screen is visible
        if (mounted) {
          setState(() {});
          if (index == _currentPage && _isVisible) {
            controller.play();
          }
        }
      } catch (e) {
        print('Error initializing video: $e');
      }
    }
  }
  
  void _manageVideoPlayback() {
    // Only handle playback if screen is visible
    if (!_isVisible) return;
    
    // Pause all videos first
    for (final controller in _videoControllers.values) {
      controller.pause();
    }
    
    // Play current video if available
    if (_videoControllers.containsKey(_currentPage)) {
      _videoControllers[_currentPage]!.play();
    } else {
      // Initialize the controller if it doesn't exist
      _initializeVideoController(_currentPage);
    }
    
    // Cleanup old controllers to free memory
    _cleanupOldControllers();
    
    // Pre-load videos ahead for smoother scrolling
    for (int i = 1; i <= _preloadWindow; i++) {
      _initializeVideoController(_currentPage + i);
    }
    
    // Also preload previous videos for smoother scrolling up
    for (int i = 1; i <= _preloadWindow / 2; i++) {
      _initializeVideoController(_currentPage - i);
    }
  }
  
  void _cleanupOldControllers() {
    // Get all indexes that are outside our preload window
    final List<int> indexesToRemove = [];
    
    for (final index in _videoControllers.keys) {
      if ((index - _currentPage).abs() > _preloadWindow * 2) {
        indexesToRemove.add(index);
      }
    }
    
    // Remove and dispose controllers for these indexes
    for (final index in indexesToRemove) {
      final controller = _videoControllers[index];
      if (controller != null) {
        controller.pause();
        controller.dispose();
        _videoControllers.remove(index);
      }
    }
  }
  
  void _toggleLike(int index) {
    final statusProvider = context.read<StatusProvider>();
    final statuses = statusProvider.statusFeed;
    if (index < 0 || index >= statuses.length) return;
    
    final status = statuses[index];
    final currentUserId = context.read<AuthenticationProvider>().userModel!.uid;
    
    context.read<StatusProvider>().toggleLike(
      statusId: status.statusId,
      userId: currentUserId,
      statusOwnerUid: status.uid,
      onSuccess: () {},
      onError: (error) {
        showSnackBar(context, 'Error: $error');
      },
    );
  }
  
  void _showComments(int index) {
    final statusProvider = context.read<StatusProvider>();
    final statuses = statusProvider.statusFeed;
    if (index < 0 || index >= statuses.length) return;
    
    final status = statuses[index];
    
    // Pause current video if playing
    if (_videoControllers.containsKey(_currentPage)) {
      _videoControllers[_currentPage]!.pause();
    }
    
    // Show bottom sheet with comments
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Makes the bottom sheet take up to 90% of screen height
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8, // Start at 80% of screen height
          minChildSize: 0.5, // Can be dragged down to 50%
          maxChildSize: 0.9, // Can be dragged up to 90%
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      '${status.comments.length} comments',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Comments list with input field
                  Expanded(
                    child: StatusCommentsScreen(
                      status: status,
                      isBottomSheet: true,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Resume video playback when returning from comments, but only if screen is visible
      if (_videoControllers.containsKey(_currentPage) && mounted && _isVisible) {
        _videoControllers[_currentPage]!.play();
      }
    });
  }
  
  void _shareContent(int index) {
    // Implementation will be added later
    showSnackBar(context, 'Share feature coming soon');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF09BB07);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.search, color: Colors.white, size: 28),
          onPressed: () {
            // Search functionality will be added later
            showSnackBar(context, 'Search coming soon');
          },
        ),
        title: const Text(
          'Status',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const CreateStatusScreen(),
                ),
              ).then((_) => _loadStatus());
            },
          ),
        ],
      ),
      body: Consumer<StatusProvider>(
        builder: (context, statusProvider, child) {
          // Get the current feed
          final statuses = statusProvider.statusFeed;
          
          if (statusProvider.isLoading && statuses.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }
          
          if (statuses.isEmpty) {
            return _buildEmptyState(accentColor);
          }
          
          return Stack(
            children: [
              // Main content
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: statuses.length,
                itemBuilder: (context, index) {
                  final status = statuses[index];
                  
                  // Mark status as viewed if it's not the current user's
                  if (status.uid != currentUser.uid && !status.viewedBy.contains(currentUser.uid)) {
                    statusProvider.markStatusAsViewed(
                      statusId: status.statusId,
                      userId: currentUser.uid,
                      statusOwnerUid: status.uid,
                    );
                  }
                  
                  return _buildStatusItem(index, status, currentUser.uid);
                },
                onPageChanged: (index) {
                  // Load more content when we're close to the end
                  if (index >= statuses.length - 5 && !_isLoadingMore && !statusProvider.isLoading) {
                    _loadMoreContent();
                  }
                },
              ),
              
              // Loading more indicator at bottom 
              if (_isLoadingMore)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Loading more...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Load more content when reaching the end of the feed
  Future<void> _loadMoreContent() async {
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final statusProvider = context.read<StatusProvider>();
      final authProvider = context.read<AuthenticationProvider>();
      final currentUser = authProvider.userModel!;
      
      // Load more status posts
      await statusProvider.fetchMoreStatusPosts(
        currentUserId: currentUser.uid,
        contactIds: currentUser.contactsUIDs,
      );
    } catch (e) {
      print('Error loading more content: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }
  
  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 70,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Status Updates Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Be the first to share a photo or video status',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const CreateStatusScreen(),
                ),
              ).then((_) => _loadStatus());
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Status'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(int index, StatusModel status, String currentUserId) {
    final bool isLiked = status.likedBy.contains(currentUserId);
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Content (Video or Image)
        GestureDetector(
          onDoubleTap: () => _toggleLike(index),
          child: status.statusType == StatusType.video
              ? _buildVideoPlayer(index, status)
              : status.statusType == StatusType.image
                  ? _buildImageViewer(status)
                  : _buildMultipleImageViewer(status),
        ),
        
        // Gradient overlay for better text visibility
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
        
        // User info and description
        Positioned(
          left: 16,
          bottom: 100,
          right: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username
              Text(
                '@${status.userName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              // Description
              if (status.caption.isNotEmpty)
                Text(
                  status.caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              
              // Location (if implemented)
              if (status.location != null && status.location!.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.location!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        // Right side interaction buttons
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              // Profile avatar
              GestureDetector(
                onTap: () {
                  // Navigate to user profile
                  Navigator.pushNamed(
                    context,
                    '/userStatusScreen',
                    arguments: status.uid,
                  );
                },
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: userImageWidget(
                      imageUrl: status.userImage,
                      radius: 25,
                      onTap: () {},
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Like button
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                      size: 35,
                    ),
                    onPressed: () => _toggleLike(index),
                  ),
                  Text(
                    '${status.likedBy.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Comments button
              Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.comment,
                      color: Colors.white,
                      size: 35,
                    ),
                    onPressed: () => _showComments(index),
                  ),
                  Text(
                    '${status.comments.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Share button
              Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 35,
                    ),
                    onPressed: () => _shareContent(index),
                  ),
                  const Text(
                    'Share',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildVideoPlayer(int index, StatusModel status) {
    final controller = _videoControllers[index];
    
    if (controller != null && controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      );
    } else {
      // Show a loading indicator or placeholder
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }
  }
  
  Widget _buildImageViewer(StatusModel status) {
    if (status.statusUrl.isEmpty) {
      return Container(color: Colors.black);
    }
    
    return Container(
      color: Colors.black,
      child: CachedNetworkImage(
        imageUrl: status.statusUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error, color: Colors.white),
        ),
      ),
    );
  }
  
  Widget _buildMultipleImageViewer(StatusModel status) {
    if (status.mediaUrls == null || status.mediaUrls!.isEmpty) {
      return Container(color: Colors.black);
    }
    
    // Build a single image preview with indicator of multiple images
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main (first) image
          CachedNetworkImage(
            imageUrl: status.mediaUrls!.first,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(Icons.error, color: Colors.white),
            ),
          ),
          
          // Indicator for multiple images
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${status.mediaUrls!.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}