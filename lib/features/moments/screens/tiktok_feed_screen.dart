import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';
import 'package:textgb/common/videoviewerscreen.dart';
import 'package:textgb/features/moments/screens/create_moment_screen.dart';
import 'package:textgb/models/moment_model.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/moments_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:video_player/video_player.dart';

class TikTokFeedScreen extends StatefulWidget {
  const TikTokFeedScreen({Key? key}) : super(key: key);

  @override
  State<TikTokFeedScreen> createState() => _TikTokFeedScreenState();
}

class _TikTokFeedScreenState extends State<TikTokFeedScreen> {
  final PageController _pageController = PageController();
  List<MomentModel> _allMoments = [];
  int _currentPage = 0;
  Map<int, VideoPlayerController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _loadMoments();
    
    // Add page listener to manage video playback
    _pageController.addListener(_pageListener);
  }

  @override
  void dispose() {
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _pageController.removeListener(_pageListener);
    _pageController.dispose();
    super.dispose();
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

  Future<void> _loadMoments() async {
    try {
      final authProvider = context.read<AuthenticationProvider>();
      final momentsProvider = context.read<MomentsProvider>();
      
      final currentUser = authProvider.userModel!;
      final contactIds = currentUser.contactsUIDs;
      
      await momentsProvider.fetchMoments(
        currentUserId: currentUser.uid,
        contactIds: contactIds,
      );
      
      // Combine and sort all moments
      setState(() {
        _allMoments = [
          ...momentsProvider.userMoments,
          ...momentsProvider.contactsMoments,
        ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
      
      // Initialize video controller for first visible item if it's a video
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeVideoController(0);
      });
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error loading feed: $e');
      }
    }
  }
  
  Future<void> _initializeVideoController(int index) async {
    // Skip if out of bounds
    if (index < 0 || index >= _allMoments.length) return;
    
    final moment = _allMoments[index];
    
    // Only initialize if it's a video
    if (moment.isVideo && moment.mediaUrls.isNotEmpty) {
      // Skip if controller already exists
      if (_videoControllers.containsKey(index)) return;
      
      try {
        final controller = VideoPlayerController.network(moment.mediaUrls[0]);
        
        // Store controller with index
        _videoControllers[index] = controller;
        
        // Initialize and play if this is the current page
        await controller.initialize();
        if (mounted) {
          setState(() {});
          if (index == _currentPage) {
            controller.setLooping(true);
            controller.play();
          }
        }
      } catch (e) {
        print('Error initializing video: $e');
      }
    }
  }
  
  void _manageVideoPlayback() {
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
    
    // Pre-load next video for smoother experience
    _initializeVideoController(_currentPage + 1);
  }
  
  void _toggleLike(int index) {
    if (index < 0 || index >= _allMoments.length) return;
    
    final moment = _allMoments[index];
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
    // Implementation will be added later
    showSnackBar(context, 'Comments coming soon');
  }
  
  void _shareContent(int index) {
    // Implementation will be added later
    showSnackBar(context, 'Share feature coming soon');
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Following',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 20),
            const Text(
              'For You',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
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
          if (momentsProvider.isLoading && _allMoments.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }
          
          if (_allMoments.isEmpty) {
            return _buildEmptyState(accentColor);
          }
          
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _allMoments.length,
            itemBuilder: (context, index) {
              final moment = _allMoments[index];
              
              // Mark moment as viewed if it's not the current user's
              if (moment.uid != currentUser.uid && !moment.viewedBy.contains(currentUser.uid)) {
                momentsProvider.markMomentAsViewed(
                  momentId: moment.momentId,
                  userId: currentUser.uid,
                );
              }
              
              return _buildMomentItem(index, moment, currentUser.uid);
            },
          );
        },
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
        child: Center(
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
  
  Widget _buildEmptyState(Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No videos yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Be the first to share a video or follow others to see their content',
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
                  builder: (context) => const CreateMomentScreen(),
                ),
              ).then((_) => _loadMoments());
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Now'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}