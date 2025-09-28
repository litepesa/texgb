// lib/features/videos/screens/my_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/videos/models/video_model.dart';
import 'package:textgb/features/authentication/providers/authentication_provider.dart';
import 'package:textgb/features/authentication/providers/auth_convenience_providers.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/videos/widgets/boost_tab_widget.dart';
import 'package:textgb/features/videos/widgets/edit_tab_widget.dart';
import 'package:textgb/features/videos/widgets/analytics_tab_widget.dart';
import 'package:intl/intl.dart';

class MyPostScreen extends ConsumerStatefulWidget {
  final String videoId;
  
  const MyPostScreen({
    super.key,
    required this.videoId,
  });

  @override
  ConsumerState<MyPostScreen> createState() => _MyPostScreenState();
}

class _MyPostScreenState extends ConsumerState<MyPostScreen>
    with TickerProviderStateMixin {
  VideoModel? _video;
  bool _isLoading = true;
  String? _error;
  String? _videoThumbnail;
  late AnimationController _rocketAnimationController;
  late Animation<double> _rocketAnimation;
  late TabController _tabController;
  VideoPlayerController? _videoPlayerController;
  bool _isPlaying = false;
  
  // Cache manager for video thumbnails
  static final _thumbnailCacheManager = CacheManager(
    Config(
      'postVideoThumbnails',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Initialize rocket animation
    _rocketAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _rocketAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rocketAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _loadVideoData();
  }

  @override
  void dispose() {
    _rocketAnimationController.dispose();
    _tabController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideoData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load the specific video from the authentication provider
      final videos = ref.read(videosProvider);
      final video = videos.firstWhere(
        (v) => v.id == widget.videoId,
        orElse: () => throw Exception('Video not found'),
      );
      
      if (mounted) {
        setState(() {
          _video = video;
          _isLoading = false;
        });
        
        // Generate thumbnail if it's a video
        if (!video.isMultipleImages && video.videoUrl.isNotEmpty) {
          _generateVideoThumbnail();
        }
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

  Future<void> _generateVideoThumbnail() async {
    if (_video == null || _video!.videoUrl.isEmpty) return;
    
    try {
      // Check if thumbnail is already cached
      final cacheKey = 'post_thumb_${_video!.id}';
      final fileInfo = await _thumbnailCacheManager.getFileFromCache(cacheKey);
      
      if (fileInfo != null && fileInfo.file.existsSync()) {
        // Use cached thumbnail
        if (mounted) {
          setState(() {
            _videoThumbnail = fileInfo.file.path;
          });
        }
      } else {
        // Generate new thumbnail
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: _video!.videoUrl,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 400,
          quality: 85,
        );
        
        if (thumbnailPath != null && mounted) {
          // Cache the thumbnail
          final thumbnailFile = File(thumbnailPath);
          if (thumbnailFile.existsSync()) {
            await _thumbnailCacheManager.putFile(
              cacheKey,
              thumbnailFile.readAsBytesSync(),
            );
          }
          
          setState(() {
            _videoThumbnail = thumbnailPath;
          });
        }
      }
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_video == null || _video!.isMultipleImages || _video!.videoUrl.isEmpty) return;
    
    try {
      _videoPlayerController = VideoPlayerController.network(_video!.videoUrl);
      await _videoPlayerController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing video player: $e');
    }
  }

  void _toggleVideoPlayback() {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) {
      _initializeVideoPlayer().then((_) {
        if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
          _videoPlayerController!.play();
          setState(() {
            _isPlaying = true;
          });
        }
      });
    } else {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        _videoPlayerController!.play();
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  void _boostPost() {
    _rocketAnimationController.forward().then((_) {
      _rocketAnimationController.reset();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🚀 Post boost feature coming soon!'),
        backgroundColor: context.modernTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editPost() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit feature coming soon!'),
        backgroundColor: context.modernTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addBannerText() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Banner text editor coming soon!'),
        backgroundColor: context.modernTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deletePost() async {
    if (_video == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.red.shade600,
            ),
            const SizedBox(width: 8),
            const Text('Delete Post'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: context.modernTheme.textSecondaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                await ref.read(authenticationProvider.notifier).deleteVideo(
                  _video!.id,
                  (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red.shade600,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                );
                
                // Go back to previous screen after successful deletion
                Navigator.of(context).pop();
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(Constants.videoDeleted),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting post: ${e.toString()}'),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // UPDATED: Handle RFC3339 string timestamps instead of Firestore Timestamps
  String _formatTimeAgo(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return DateFormat('MMM d, y').format(dateTime);
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      // Fallback for invalid timestamp
      return 'Unknown';
    }
  }

  String _formatViewCount(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: _isLoading || _error != null || _video == null
          ? null
          : AppBar(
              backgroundColor: modernTheme.backgroundColor,
              foregroundColor: modernTheme.textColor,
              elevation: 0,
              title: const Text('My Post'),
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: modernTheme.textColor,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editPost();
                        break;
                      case 'delete':
                        _deletePost();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit Post'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Post', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
      body: _isLoading
          ? _buildLoadingView(modernTheme)
          : _error != null
              ? _buildErrorView(modernTheme)
              : _video != null
                  ? _buildPostView(modernTheme)
                  : _buildErrorView(modernTheme),
    );
  }

  Widget _buildLoadingView(ModernThemeExtension modernTheme) {
    return SafeArea(
      child: Column(
        children: [
          // App Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: modernTheme.textColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  'My Post',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: modernTheme.primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading post details...',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 16,
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

  Widget _buildErrorView(ModernThemeExtension modernTheme) {
    return SafeArea(
      child: Column(
        children: [
          // App Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: modernTheme.textColor,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  'My Post',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
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
                      'Post Not Found',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error ?? 'The post you\'re looking for doesn\'t exist.',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: modernTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Go Back'),
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

  Widget _buildPostView(ModernThemeExtension modernTheme) {
    return Column(
      children: [
        // Tab Bar at the top
        Container(
          color: modernTheme.backgroundColor,
          child: TabBar(
            controller: _tabController,
            labelColor: modernTheme.primaryColor,
            unselectedLabelColor: modernTheme.textSecondaryColor,
            indicatorColor: modernTheme.primaryColor,
            isScrollable: true,
            tabs: const [
              Tab(
                icon: Icon(Icons.rocket_launch),
                text: 'Boost',
              ),
              Tab(
                icon: Icon(Icons.image),
                text: 'Preview',
              ),
              Tab(
                icon: Icon(Icons.analytics),
                text: 'Analytics',
              ),
              Tab(
                icon: Icon(Icons.edit),
                text: 'Edit',
              ),
            ],
          ),
        ),
        
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Boost Tab
              BoostTabWidget(
                rocketAnimationController: _rocketAnimationController,
                rocketAnimation: _rocketAnimation,
                onBoostPost: _boostPost,
              ),
              // Preview Tab
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPostPreviewCard(_video!, modernTheme),
                    _buildActionButtons(modernTheme),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Analytics Tab
              AnalyticsTabWidget(video: _video!),
              // Edit Tab
              EditTabWidget(
                video: _video,
                onAddBannerText: _addBannerText,
                onEditPost: _editPost,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostPreviewCard(VideoModel video, ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: Constants.videoAspectRatio, // TikTok-style aspect ratio
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media Content - Full coverage
              if (video.isMultipleImages && video.imageUrls.isNotEmpty)
                PageView.builder(
                  itemCount: video.imageUrls.length,
                  itemBuilder: (context, index) => CachedNetworkImage(
                    imageUrl: video.imageUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: modernTheme.surfaceColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            modernTheme.primaryColor!,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: modernTheme.primaryColor!.withOpacity(0.1),
                      child: Icon(
                        Icons.image_not_supported,
                        color: modernTheme.primaryColor,
                        size: 48,
                      ),
                    ),
                  ),
                )
              else if (!video.isMultipleImages && _videoPlayerController != null && _videoPlayerController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController!),
                )
              else if (!video.isMultipleImages && _videoThumbnail != null)
                Image.file(
                  File(_videoThumbnail!),
                  fit: BoxFit.cover,
                )
              else if (!video.isMultipleImages && video.thumbnailUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: modernTheme.surfaceColor,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          modernTheme.primaryColor!,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: modernTheme.primaryColor!.withOpacity(0.1),
                    child: Icon(
                      Icons.video_library,
                      color: modernTheme.primaryColor,
                      size: 48,
                    ),
                  ),
                )
              else
                Container(
                  color: modernTheme.primaryColor!.withOpacity(0.1),
                  child: Icon(
                    video.isMultipleImages ? Icons.photo_library : Icons.play_circle_fill,
                    color: modernTheme.primaryColor,
                    size: 64,
                  ),
                ),
              
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Play/Pause button for videos
              if (!video.isMultipleImages)
                Center(
                  child: GestureDetector(
                    onTap: _toggleVideoPlayback,
                    child: AnimatedOpacity(
                      opacity: _isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Post Info Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundImage: video.userImage.isNotEmpty
                                  ? CachedNetworkImageProvider(video.userImage)
                                  : null,
                              child: video.userImage.isEmpty
                                  ? Text(
                                      video.userName.isNotEmpty
                                          ? video.userName[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatTimeAgo(video.createdAt), // UPDATED: Pass string directly
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Caption
                      Text(
                        video.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Tags
                      if (video.tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: video.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      
                      const SizedBox(height: 12),
                      
                      // Stats
                      Row(
                        children: [
                          _buildStatChip(
                            Icons.favorite,
                            _formatViewCount(video.likes),
                            modernTheme,
                            isOverlay: true,
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.comment,
                            _formatViewCount(video.comments),
                            modernTheme,
                            isOverlay: true,
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.visibility,
                            _formatViewCount(video.views),
                            modernTheme,
                            isOverlay: true,
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.share,
                            _formatViewCount(video.shares),
                            modernTheme,
                            isOverlay: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Page indicator for multiple images
              if (video.isMultipleImages && video.imageUrls.length > 1)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${video.imageUrls.length} photos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, ModernThemeExtension modernTheme, {bool isOverlay = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOverlay 
            ? Colors.white.withOpacity(0.2)
            : modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: isOverlay 
            ? Border.all(color: Colors.white.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isOverlay ? Colors.white : modernTheme.textSecondaryColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: isOverlay ? Colors.white : modernTheme.textSecondaryColor,
              fontSize: 14,
              fontWeight: isOverlay ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _boostPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: AnimatedBuilder(
                animation: _rocketAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_rocketAnimation.value * 10),
                    child: Transform.rotate(
                      angle: _rocketAnimation.value * 0.5,
                      child: const Icon(Icons.rocket_launch, size: 20),
                    ),
                  );
                },
              ),
              label: const Text('Boost Post'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _editPost,
              style: OutlinedButton.styleFrom(
                foregroundColor: modernTheme.primaryColor,
                side: BorderSide(color: modernTheme.primaryColor!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit, size: 20),
              label: const Text('Edit'),
            ),
          ),
        ],
      ),
    );
  }
}