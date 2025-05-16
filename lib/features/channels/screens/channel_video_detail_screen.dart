import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ChannelVideoDetailScreen extends ConsumerStatefulWidget {
  final String videoId;
  
  const ChannelVideoDetailScreen({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  ConsumerState<ChannelVideoDetailScreen> createState() => _ChannelVideoDetailScreenState();
}

class _ChannelVideoDetailScreenState extends ConsumerState<ChannelVideoDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  ChannelVideoModel? _video;
  bool _isLoading = true;
  String? _error;
  int _currentImageIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadVideoData();
  }

  Future<void> _loadVideoData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get video data using provider
      final video = await ref.read(channelVideosProvider.notifier).getVideoById(widget.videoId);
      
      if (video == null) {
        throw Exception('Video not found');
      }
      
      _video = video;
      
      // Initialize media (video or image)
      if (!video.isMultipleImages && video.videoUrl.isNotEmpty) {
        // Initialize video player
        _videoPlayerController = VideoPlayerController.network(video.videoUrl);
        await _videoPlayerController!.initialize();
        _videoPlayerController!.setLooping(true);
        
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
            _isLoading = false;
          });
          
          // Auto-play video
          _videoPlayerController!.play();
          setState(() {
            _isPlaying = true;
          });
          
          // Increment view count
          ref.read(channelVideosProvider.notifier).incrementViewCount(widget.videoId);
        }
      } else {
        // No video to initialize, just mark as loaded
        setState(() {
          _isLoading = false;
        });
        
        // Increment view count
        ref.read(channelVideosProvider.notifier).incrementViewCount(widget.videoId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_isVideoInitialized && _videoPlayerController != null) {
      _videoPlayerController!.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isVideoInitialized || _videoPlayerController == null) return;
    
    setState(() {
      if (_isPlaying) {
        _videoPlayerController!.pause();
      } else {
        _videoPlayerController!.play();
      }
      _isPlaying = !_isPlaying;
    });
  }

  void _navigateToComments() {
    Navigator.of(context).pushNamed(
      Constants.channelCommentsScreen,
      arguments: widget.videoId,
    );
  }

  void _navigateToChannelProfile() {
    if (_video == null) return;
    
    Navigator.of(context).pushNamed(
      Constants.channelProfileScreen,
      arguments: _video!.channelId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
              ),
            )
          : _error != null
              ? _buildErrorView(modernTheme)
              : _buildVideoDetailView(modernTheme),
    );
  }

  Widget _buildErrorView(ModernThemeExtension modernTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: modernTheme.primaryColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading content',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoDetailView(ModernThemeExtension modernTheme) {
    if (_video == null) {
      return const Center(child: Text('Content not found'));
    }

    return CustomScrollView(
      slivers: [
        // App bar with back button
        SliverAppBar(
          backgroundColor: Colors.black,
          expandedHeight: 0,
          pinned: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.share,
                color: Colors.white,
              ),
              onPressed: () {
                // Share functionality
              },
            ),
          ],
        ),
        
        // Media content
        SliverToBoxAdapter(
          child: _video!.isMultipleImages
              ? _buildImageCarousel()
              : _buildVideoPlayer(),
        ),
        
        // Video details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caption
                Text(
                  _video!.caption,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Channel info row
                GestureDetector(
                  onTap: _navigateToChannelProfile,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                        backgroundImage: _video!.channelImage.isNotEmpty
                            ? NetworkImage(_video!.channelImage)
                            : null,
                        child: _video!.channelImage.isEmpty
                            ? Text(
                                _video!.channelName.isNotEmpty
                                    ? _video!.channelName[0].toUpperCase()
                                    : "C",
                                style: TextStyle(
                                  color: modernTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              _video!.channelName,
                              style: TextStyle(
                                color: modernTheme.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: modernTheme.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatCount(_video!.views),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Stats (likes, comments, shares)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.favorite,
                      count: _video!.likes,
                      label: 'Likes',
                      color: _video!.isLiked ? Colors.red : modernTheme.textSecondaryColor!,
                      onTap: () {
                        ref.read(channelVideosProvider.notifier).likeVideo(widget.videoId);
                      },
                    ),
                    _buildStatItem(
                      icon: Icons.comment,
                      count: _video!.comments,
                      label: 'Comments',
                      color: modernTheme.textSecondaryColor!,
                      onTap: _navigateToComments,
                    ),
                    _buildStatItem(
                      icon: Icons.share,
                      count: _video!.shares,
                      label: 'Shares',
                      color: modernTheme.textSecondaryColor!,
                      onTap: () {
                        // Share functionality
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Tags
                if (_video!.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _video!.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: modernTheme.textSecondaryColor!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                
                const SizedBox(height: 24),
                
                // Comments section header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comments (${_video!.comments})',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    GestureDetector(
                      onTap: _navigateToComments,
                      child: Text(
                        'View All',
                        style: TextStyle(
                          color: modernTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Recent comments preview
                _buildRecentCommentsPreview(modernTheme),
                
                const SizedBox(height: 32),
                
                // Related videos header
                Text(
                  'More from this Channel',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Related videos horizontal list
                SizedBox(
                  height: 200,
                  child: FutureBuilder<List<ChannelVideoModel>>(
                    future: ref.read(channelVideosProvider.notifier)
                        .loadChannelVideos(_video!.channelId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            'No more videos from this channel',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                            ),
                          ),
                        );
                      }
                      
                      final videos = snapshot.data!
                          .where((v) => v.id != widget.videoId) // Filter out current video
                          .take(10) // Limit to 10 videos
                          .toList();
                      
                      if (videos.isEmpty) {
                        return Center(
                          child: Text(
                            'No more videos from this channel',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                            ),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacementNamed(
                                Constants.channelVideoDetailScreen,
                                arguments: video.id,
                              );
                            },
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(12),
                                image: video.isMultipleImages && video.imageUrls.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(video.imageUrls.first),
                                        fit: BoxFit.cover,
                                      )
                                    : video.thumbnailUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(video.thumbnailUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                              ),
                              child: Stack(
                                children: [
                                  if (!video.isMultipleImages && video.thumbnailUrl.isEmpty)
                                    Center(
                                      child: Icon(
                                        Icons.play_circle_fill,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                  // Gradient overlay at bottom
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        video.caption,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (_isVideoInitialized && _videoPlayerController != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          // Video player
          AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          ),
          
          // Play/pause button
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      );
    } else {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildImageCarousel() {
    if (_video!.imageUrls.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white.withOpacity(0.7),
              size: 64,
            ),
          ),
        ),
      );
    }
    
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Image carousel
        CarouselSlider(
          options: CarouselOptions(
            aspectRatio: 1,
            viewportFraction: 1.0,
            enableInfiniteScroll: _video!.imageUrls.length > 1,
            autoPlay: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items: _video!.imageUrls.map((imageUrl) {
            return Container(
              width: double.infinity,
              color: Colors.black,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white.withOpacity(0.7),
                      size: 64,
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
        
        // Image indicator dots
        if (_video!.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _video!.imageUrls.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentCommentsPreview(ModernThemeExtension modernTheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(Constants.channelComments)
          .where('videoId', isEqualTo: widget.videoId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
              ),
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return GestureDetector(
            onTap: _navigateToComments,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Be the first to comment',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }
        
        final comments = snapshot.data!.docs;
        
        return Column(
          children: comments.map((doc) {
            final comment = doc.data() as Map<String, dynamic>;
            final userName = comment['userName'] ?? '';
            final userImage = comment['userImage'] ?? '';
            final commentText = comment['comment'] ?? '';
            
            return GestureDetector(
              onTap: _navigateToComments,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                      backgroundImage: userImage.isNotEmpty
                          ? NetworkImage(userImage)
                          : null,
                      child: userImage.isEmpty
                          ? Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                              style: TextStyle(
                                color: modernTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Comment content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            commentText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            _formatCount(count),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
  }
}