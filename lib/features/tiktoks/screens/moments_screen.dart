import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/common/videoviewerscreen.dart';
import 'package:textgb/features/tiktoks/screens/create_moment_screen.dart';
import 'package:textgb/features/tiktoks/screens/tiktok_comments_screen.dart';
import 'package:textgb/models/moment_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/moments_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({Key? key}) : super(key: key);

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> 
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver, RouteAware {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<int, VideoPlayerController> _videoControllers = {};
  bool _isForYouSelected = true; // Track which feed is selected
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
    
    // Ensure we have videos to show on initial load
    _initialLoadMoments();
    
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

  Future<void> _initialLoadMoments() async {
    // This method ensures we have content for all users, even new ones
    final authProvider = context.read<AuthenticationProvider>();
    final momentsProvider = context.read<MomentsProvider>();
    
    final currentUser = authProvider.userModel!;
    final contactIds = currentUser.contactsUIDs;
    
    // Set feed mode based on selection
    momentsProvider.setFeedMode(
      _isForYouSelected ? FeedMode.forYou : FeedMode.following
    );
    
    // Always fetch the discovery feed first - this works even for new users with no contacts
    if (!momentsProvider.initialDiscoveryLoaded) {
      await momentsProvider.fetchVideoFeed(
        currentUserId: currentUser.uid,
        contactIds: contactIds,
      );
    }
    
    // Then fetch user's and contacts' moments in the background
    momentsProvider.fetchMoments(
      currentUserId: currentUser.uid,
      contactIds: contactIds,
    );
    
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

  Future<void> _loadMoments() async {
    final momentsProvider = context.read<MomentsProvider>();
    if (momentsProvider.isLoading) return;
    
    setState(() {
      // Use spinner only on first load
      if (momentsProvider.currentFeed.isEmpty) {
        momentsProvider.setLoading(true);
      }
    });
    
    try {
      final authProvider = context.read<AuthenticationProvider>();
      final currentUser = authProvider.userModel!;
      final contactIds = currentUser.contactsUIDs;
      
      // Set feed mode based on selection
      momentsProvider.setFeedMode(
        _isForYouSelected ? FeedMode.forYou : FeedMode.following
      );
      
      // For For You feed, prioritize fetching video content
      if (_isForYouSelected) {
        // This will ensure we have content even for new users
        await momentsProvider.fetchVideoFeed(
          currentUserId: currentUser.uid,
          contactIds: contactIds,
        );
      }
      
      // Also fetch regular moments in background
      momentsProvider.fetchMoments(
        currentUserId: currentUser.uid,
        contactIds: contactIds,
      );
      
      // Reset page controller to start when switching feeds
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
        showSnackBar(context, 'Error loading feed: $e');
      }
    } finally {
      if (mounted) {
        momentsProvider.setLoading(false);
      }
    }
  }

  Future<void> _initializeVideoController(int index) async {
    final momentsProvider = context.read<MomentsProvider>();
    final moments = momentsProvider.currentFeed;
    
    // Skip if out of bounds
    if (index < 0 || index >= moments.length) return;
    
    final moment = moments[index];
    
    // Only initialize if it's a video and has media URLs
    if (moment.isVideo && moment.mediaUrls.isNotEmpty) {
      // Skip if controller already exists
      if (_videoControllers.containsKey(index)) return;
      
      try {
        final controller = VideoPlayerController.network(
          moment.mediaUrls[0],
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
    final momentsProvider = context.read<MomentsProvider>();
    final moments = momentsProvider.currentFeed;
    if (index < 0 || index >= moments.length) return;
    
    final moment = moments[index];
    final currentUserId = context.read<AuthenticationProvider>().userModel!.uid;
    
    context.read<MomentsProvider>().toggleLike(
      momentId: moment.momentId,
      userId: currentUserId,
      onSuccess: () {},
      onError: (error) {
        showSnackBar(context, 'Error: $error');
      },
    );
  }
  
  void _showComments(int index) {
    final momentsProvider = context.read<MomentsProvider>();
    final moments = momentsProvider.currentFeed;
    if (index < 0 || index >= moments.length) return;
    
    final moment = moments[index];
    
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
                      '${moment.comments.length} comments',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  const Divider(),
                  
                  // Comments list with input field
                  Expanded(
                    child: TikTokCommentsScreen(
                      moment: moment,
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _isForYouSelected = false;
                });
                
                // If switching from For You to Following, clean up controllers
                for (final controller in _videoControllers.values) {
                  controller.pause();
                }
                _videoControllers.clear();
                
                _loadMoments();
              },
              child: Text(
                'Following',
                style: TextStyle(
                  color: _isForYouSelected ? Colors.white60 : Colors.white,
                  fontSize: _isForYouSelected ? 16 : 17,
                  fontWeight: _isForYouSelected ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isForYouSelected = true;
                });
                
                // If switching from Following to For You, clean up controllers
                for (final controller in _videoControllers.values) {
                  controller.pause();
                }
                _videoControllers.clear();
                
                _loadMoments();
              },
              child: Text(
                'For You',
                style: TextStyle(
                  color: _isForYouSelected ? Colors.white : Colors.white60,
                  fontSize: _isForYouSelected ? 17 : 16,
                  fontWeight: _isForYouSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const CreateMomentScreen(),
                ),
              ).then((_) => _loadMoments());
            },
          ),
        ],
      ),
      body: Consumer<MomentsProvider>(
        builder: (context, momentsProvider, child) {
          // Get the current feed based on selected tab
          final moments = momentsProvider.currentFeed;
          
          if (momentsProvider.isLoading && moments.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }
          
          if (moments.isEmpty) {
            return _buildEmptyState(accentColor, _isForYouSelected);
          }
          
          return Stack(
            children: [
              // Main content
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: moments.length,
                itemBuilder: (context, index) {
                  final moment = moments[index];
                  
                  // Mark moment as viewed if it's not the current user's
                  if (moment.uid != currentUser.uid && !moment.viewedBy.contains(currentUser.uid)) {
                    momentsProvider.markMomentAsViewed(
                      momentId: moment.momentId,
                      userId: currentUser.uid,
                    );
                  }
                  
                  return _buildMomentItem(index, moment, currentUser.uid);
                },
                onPageChanged: (index) {
                  // Load more content when we're close to the end
                  if (index >= moments.length - 5 && !_isLoadingMore && !momentsProvider.isLoading) {
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
                            'Loading more videos...',
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
      final momentsProvider = context.read<MomentsProvider>();
      final authProvider = context.read<AuthenticationProvider>();
      final currentUser = authProvider.userModel!;
      
      // Load more videos for the For You feed
      if (_isForYouSelected) {
        await momentsProvider.fetchVideoFeed(
          currentUserId: currentUser.uid,
          contactIds: currentUser.contactsUIDs,
        );
      }
      
      // For the Following feed, we just make sure all contacts' content is loaded
      // This is typically handled by the initial load already
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
  
  Widget _buildEmptyState(Color accentColor, bool isForYouTab) {
    // For the "For You" tab, instead of showing empty state, we should retry loading
    // This should only appear briefly since we've improved the feed loading
    if (isForYouTab) {
      // This is unexpected, as For You should always have content - retry loading
      Future.delayed(Duration.zero, () {
        if (mounted) {
          context.read<MomentsProvider>().fetchVideoFeed(
            currentUserId: context.read<AuthenticationProvider>().userModel!.uid,
            contactIds: context.read<AuthenticationProvider>().userModel!.contactsUIDs,
          );
        }
      });
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(color: accentColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Finding videos for you...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    // This is for the Following tab which might really be empty for new users
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 70,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No videos from your contacts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Add contacts or check out the "For You" tab to see trending videos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to add contacts screen
                  Navigator.pushNamed(context, '/contactsScreen');
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Add Contacts'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => const CreateMomentScreen(),
                    ),
                  ).then((_) => _loadMoments());
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Now'),
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
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              setState(() {
                _isForYouSelected = true;
              });
              _loadMoments();
            },
            child: const Text('Switch to For You'),
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMomentItem(int index, MomentModel moment, String currentUserId) {
    final bool isLiked = moment.likedBy.contains(currentUserId);
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Content (Video or Image)
        GestureDetector(
          onDoubleTap: () => _toggleLike(index),
          child: moment.isVideo
              ? _buildVideoPlayer(index, moment)
              : _buildImageViewer(moment),
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
                '@${moment.userName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              
              // Description
              if (moment.text.isNotEmpty)
                Text(
                  moment.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              
              // Location
              if (moment.location.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      moment.location,
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
                    '/userMomentsScreen',
                    arguments: moment.uid,
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
                      imageUrl: moment.userImage,
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
                    '${moment.likedBy.length}',
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
                    '${moment.comments.length}',
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
  
  Widget _buildVideoPlayer(int index, MomentModel moment) {
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
  
  Widget _buildImageViewer(MomentModel moment) {
    if (moment.mediaUrls.isEmpty) {
      return Container(color: Colors.black);
    }
    
    return Container(
      color: Colors.black,
      child: CachedNetworkImage(
        imageUrl: moment.mediaUrls[0],
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
}