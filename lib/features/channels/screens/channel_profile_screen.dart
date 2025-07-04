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
    with WidgetsBindingObserver {
  
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

  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  void _restoreSystemUI() {
    // Restore to default system UI when leaving
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark 
          ? Brightness.light 
          : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Theme.of(context).brightness == Brightness.dark 
          ? Brightness.light 
          : Brightness.dark,
    ));
  }

  void _setupKeyboardListener() {
    _commentFocusNode.addListener(() {
      setState(() {
        _isCommenting = _commentFocusNode.hasFocus;
      });
    });
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
        
        // Initialize video controllers
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
    
    // Play first video if available
    if (_channelVideos.isNotEmpty) {
      _playCurrentVideo();
    }
  }

  Future<void> _initializeVideoController(int index, String videoUrl) async {
    try {
      // Try to get cached video first
      File? cachedFile;
      try {
        if (await _cacheService.isVideoCached(videoUrl)) {
          cachedFile = await _cacheService.getCachedVideo(videoUrl);
          debugPrint('Using cached video: ${cachedFile.path}');
        } else {
          debugPrint('Video not cached, downloading: $videoUrl');
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
      
      // Auto-play if this is the current video
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
    
    // Preload next videos using cache service
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
    
    // Dispose cache service
    _cacheService.dispose();
    _cacheCleanupTimer?.cancel();
    
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    _videoInitialized.clear();
    
    _commentController.dispose();
    _commentFocusNode.dispose();
    _pageController.dispose();
    
    // Restore system UI before disposing
    _restoreSystemUI();
    
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
    
    return WillPopScope(
      onWillPop: () async {
        _restoreSystemUI();
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Main video content
            Positioned.fill(
              child: _buildVideoFeed(),
            ),
            
            // Back button
            _buildBackButton(),
            
            // Channel info
            _buildChannelInfo(),
            
            // Right side menu
            _buildRightSideMenu(),
            
            // Video caption
            _buildVideoCaption(),
          ],
        ),
        
        // Comment bottom nav
        bottomNavigationBar: _buildCommentBottomNav(),
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
        return Container(
          width: double.infinity,
          height: double.infinity,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.broken_image,
        color: Colors.white,
        size: 64,
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: GestureDetector(
        onTap: () {
          _restoreSystemUI();
          Navigator.of(context).pop();
        },
        child: const Icon(
          Icons.arrow_back,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildChannelInfo() {
    if (_channel == null) return const SizedBox.shrink();
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 20,
      right: 20,
      child: Row(
        children: [
          // Channel avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
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
          
          const SizedBox(width: 12),
          
          // Channel name and verification
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _channel!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_channel!.isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 16,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Follow button (only if not owner)
          if (!_isOwner)
            GestureDetector(
              onTap: _toggleFollow,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isFollowing 
                      ? Colors.grey[600]!.withOpacity(0.8)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  _isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRightSideMenu() {
    final currentVideo = _channelVideos.isNotEmpty && _currentVideoIndex < _channelVideos.length 
        ? _channelVideos[_currentVideoIndex] 
        : null;

    return Positioned(
      right: 12,
      bottom: 200, // Above comment input area
      child: Column(
        children: [
          // Like button
          Column(
            children: [
              GestureDetector(
                onTap: () => _likeCurrentVideo(currentVideo),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    currentVideo?.isLiked == true ? Icons.favorite : Icons.favorite_border,
                    color: currentVideo?.isLiked == true ? Colors.red : Colors.white,
                    size: 32,
                    shadows: const [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                _formatCount(currentVideo?.likes ?? 0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Comment button
          Column(
            children: [
              GestureDetector(
                onTap: () => _commentFocusNode.requestFocus(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.mode_comment_outlined,
                    color: Colors.white,
                    size: 30,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                _formatCount(currentVideo?.comments ?? 0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
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
          Container(padding: const EdgeInsets.all(8), child: child),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoCaption() {
    final currentVideo = _channelVideos.isNotEmpty && _currentVideoIndex < _channelVideos.length 
        ? _channelVideos[_currentVideoIndex] 
        : null;

    if (currentVideo == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 120, // Above comment input
      left: 16,
      right: 70, // Leave space for right menu
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Caption
          if (currentVideo.caption.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                currentVideo.caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          // Hashtags
          if (currentVideo.tags.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                currentVideo.tags.take(3).map((tag) => '#$tag').join(' '),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentBottomNav() {
    return Container(
      height: 70 + MediaQuery.of(context).viewPadding.bottom,
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          child: Row(
            children: [
              // User avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[600],
                ),
                child: _auth.currentUser?.photoURL != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _auth.currentUser!.photoURL!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
              
              const SizedBox(width: 12),
              
              // Comment input field
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
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
              ),
              
              const SizedBox(width: 12),
              
              // Send button
              GestureDetector(
                onTap: _isCommenting ? null : _addComment,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: _isCommenting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 14,
                        ),
                ),
              ),
            ],
          ),
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
            onPressed: () {
              _restoreSystemUI();
              Navigator.of(context).pop();
            },
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