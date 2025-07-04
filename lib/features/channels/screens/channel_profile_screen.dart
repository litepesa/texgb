// lib/features/channels/screens/channel_profile_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  // Core controllers
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache service
  final VideoCacheService _cacheService = VideoCacheService();
  
  // State management
  int _currentVideoIndex = 0;
  bool _isCommenting = false;
  
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupSystemUI();
    _loadChannelData();
    _setupKeyboardListener();
    _setupCacheCleanup();
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

  void _setupKeyboardListener() {
    _commentFocusNode.addListener(() {
      setState(() {
        _isCommenting = _commentFocusNode.hasFocus;
      });
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
    
    setState(() {
      _currentVideoIndex = index;
    });

    _playCurrentVideo();
    _cacheService.preloadVideosIntelligently(_channelVideos, index);
    ref.read(channelVideosProvider.notifier).incrementViewCount(_channelVideos[index].id);
  }

  void _playCurrentVideo() {
    final controller = _videoControllers[_currentVideoIndex];
    if (controller != null && _videoInitialized[_currentVideoIndex] == true) {
      controller.seekTo(Duration.zero);
      controller.play();
    }
  }

  void _pauseCurrentVideo() {
    final controller = _videoControllers[_currentVideoIndex];
    if (controller != null && _videoInitialized[_currentVideoIndex] == true) {
      controller.pause();
    }
  }

  void _togglePlayPause() {
    final controller = _videoControllers[_currentVideoIndex];
    if (controller != null && _videoInitialized[_currentVideoIndex] == true) {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
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

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    if (_auth.currentUser == null) {
      _showSnackBar('You must be logged in to comment');
      return;
    }

    if (_channelVideos.isEmpty || _currentVideoIndex >= _channelVideos.length) return;

    final currentVideo = _channelVideos[_currentVideoIndex];

    setState(() {
      _isCommenting = true;
    });

    try {
      final uid = _auth.currentUser!.uid;
      final userDoc = await _firestore.collection(Constants.users).doc(uid).get();
      final userData = userDoc.data();
      
      if (userData == null) {
        throw Exception('User data not found');
      }
      
      final userName = userData[Constants.name] ?? '';
      final userImage = userData[Constants.image] ?? '';
      
      final commentData = {
        'videoId': currentVideo.id,
        'userId': uid,
        'userName': userName,
        'userImage': userImage,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'replyCount': 0,
      };
      
      await _firestore.collection(Constants.channelComments).add(commentData);
      await _firestore.collection(Constants.channelVideos).doc(currentVideo.id).update({
        'comments': FieldValue.increment(1),
      });
      
      _commentController.clear();
      _commentFocusNode.unfocus();
      
      _showSnackBar('Comment added successfully');
      
    } catch (e) {
      _showSnackBar('Error adding comment: ${e.toString()}');
    } finally {
      setState(() {
        _isCommenting = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.grey[800],
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
    
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoInitialized.clear();
    
    _commentController.dispose();
    _commentFocusNode.dispose();
    _pageController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main video content - FULL SCREEN (fills entire screen)
          Positioned.fill(
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
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          
          // Right side menu overlay
          _buildRightSideMenu(),
          
          // Bottom content overlay
          _buildBottomContent(),
          
          // Comment input overlay (directly over video)
          _buildCommentInput(),
        ],
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
    
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
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
            fit: BoxFit.cover, // Fill entire screen edge to edge
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

  // Top bar - EXACTLY like your screenshots
  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back arrow
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 28,
            ),
          ),
          
          // Search icon
          GestureDetector(
            onTap: () {
              // Implement search functionality
            },
            child: const Icon(
              Icons.search,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // Right side menu - EXACTLY 5 icons like your screenshots
  Widget _buildRightSideMenu() {
    final currentVideo = _channelVideos.isNotEmpty && _currentVideoIndex < _channelVideos.length 
        ? _channelVideos[_currentVideoIndex] 
        : null;

    return Positioned(
      right: 12,
      bottom: 200,
      child: Column(
        children: [
          // Heart icon with count - EXACTLY like your screenshots
          _buildSideMenuItem(
            icon: currentVideo?.isLiked == true ? Icons.favorite : Icons.favorite_border,
            iconColor: currentVideo?.isLiked == true ? Colors.red : Colors.white,
            count: currentVideo?.likes ?? 1026,
            onTap: () => _likeCurrentVideo(currentVideo),
          ),
          
          const SizedBox(height: 20),
          
          // Chat bubble icon with count - EXACTLY like your screenshots
          _buildSideMenuItem(
            icon: Icons.chat_bubble_outline,
            iconColor: Colors.white,
            count: currentVideo?.comments ?? 29,
            onTap: () => _commentFocusNode.requestFocus(),
          ),
          
          const SizedBox(height: 20),
          
          // Star icon with count - EXACTLY like your screenshots
          _buildSideMenuItem(
            icon: Icons.star_border,
            iconColor: Colors.white,
            count: 138,
            onTap: () {
              // Star functionality
            },
          ),
          
          const SizedBox(height: 20),
          
          // Flower/More icon with count - EXACTLY like your screenshots
          _buildSideMenuItem(
            icon: Icons.local_florist_outlined,
            iconColor: Colors.white,
            count: 58,
            onTap: () {
              // More options
            },
          ),
          
          const SizedBox(height: 20),
          
          // Share arrow icon with count - EXACTLY like your screenshots
          _buildSideMenuItem(
            icon: Icons.reply,
            iconColor: Colors.white,
            count: 9,
            onTap: () {
              // Share functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenuItem({
    required IconData icon,
    required Color iconColor,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            _formatCount(count),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
      bottom: 70, // Above comment input
      left: 16,
      right: 70, // Leave more space for right menu
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
                          color: Colors.grey[700],
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
                      color: Colors.grey[700]!.withOpacity(0.8), // Gray background like in your image
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
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'More',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Comment input overlay - EXACTLY like your reference images (dark background)
  Widget _buildCommentInput() {
    return Positioned(
      bottom: MediaQuery.of(context).viewPadding.bottom + 12,
      left: 16,
      right: 16,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7), // Dark background like in your image
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            
            // Profile icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[600],
              ),
              child: _auth.currentUser?.photoURL != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _auth.currentUser!.photoURL!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 14,
                    ),
            ),
            
            const SizedBox(width: 12),
            
            // Comment text field
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _commentFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Comment',
                  hintStyle: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _addComment(),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // @ symbol
            const Icon(
              Icons.alternate_email,
              color: Colors.white54,
              size: 18,
            ),
            
            const SizedBox(width: 8),
            
            // Emoji button
            const Icon(
              Icons.emoji_emotions_outlined,
              color: Colors.white54,
              size: 18,
            ),
            
            const SizedBox(width: 8),
            
            // Gallery/Photo icon
            const Icon(
              Icons.photo_outlined,
              color: Colors.white54,
              size: 18,
            ),
            
            const SizedBox(width: 12),
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
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (_isOwner) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, Constants.createChannelPostScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
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
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}