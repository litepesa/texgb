import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:intl/intl.dart';

class MyPostScreen extends ConsumerStatefulWidget {
  final String videoId;
  
  const MyPostScreen({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  ConsumerState<MyPostScreen> createState() => _MyPostScreenState();
}

class _MyPostScreenState extends ConsumerState<MyPostScreen>
    with TickerProviderStateMixin {
  ChannelVideoModel? _video;
  bool _isLoading = true;
  String? _error;
  String? _videoThumbnail;
  late AnimationController _rocketAnimationController;
  late Animation<double> _rocketAnimation;
  late TabController _tabController;
  
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
    _tabController = TabController(length: 3, vsync: this);
    
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
    super.dispose();
  }

  Future<void> _loadVideoData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load the specific video from the provider
      final video = await ref.read(channelVideosProvider.notifier).getVideoById(widget.videoId);
      
      if (video == null) {
        throw Exception('Video not found');
      }
      
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
                await ref.read(channelVideosProvider.notifier).deleteVideo(
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
                
                // Go back to channel screen after successful deletion
                Navigator.of(context).pop();
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

  String _formatTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());
    
    if (difference.inDays > 0) {
      return DateFormat('MMM d, y').format(timestamp.toDate());
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
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
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        // Custom App Bar
        SliverAppBar(
          backgroundColor: modernTheme.backgroundColor,
          foregroundColor: modernTheme.textColor,
          elevation: 0,
          pinned: true,
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
      ],
      body: Column(
        children: [
          // Post Preview Card
          _buildPostPreviewCard(_video!, modernTheme),
          
          // Action Buttons Row
          _buildActionButtons(modernTheme),
          
          // Tab Bar
          Container(
            color: modernTheme.backgroundColor,
            child: TabBar(
              controller: _tabController,
              labelColor: modernTheme.primaryColor,
              unselectedLabelColor: modernTheme.textSecondaryColor,
              indicatorColor: modernTheme.primaryColor,
              tabs: const [
                Tab(
                  icon: Icon(Icons.analytics),
                  text: 'Analytics',
                ),
                Tab(
                  icon: Icon(Icons.edit),
                  text: 'Edit',
                ),
                Tab(
                  icon: Icon(Icons.rocket_launch),
                  text: 'Boost',
                ),
              ],
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsTab(_video!, modernTheme),
                _buildEditTab(modernTheme),
                _buildBoostTab(modernTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostPreviewCard(ChannelVideoModel video, ModernThemeExtension modernTheme) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.grey.shade200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Media Content
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
                    
                    // Play button for videos
                    if (!video.isMultipleImages)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    
                    // Page indicator for multiple images
                    if (video.isMultipleImages && video.imageUrls.length > 1)
                      Positioned(
                        bottom: 8,
                        right: 8,
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
          ),
          
          // Post Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: video.channelImage.isNotEmpty
                          ? CachedNetworkImageProvider(video.channelImage)
                          : null,
                      child: video.channelImage.isEmpty
                          ? Text(
                              video.channelName.isNotEmpty
                                  ? video.channelName[0].toUpperCase()
                                  : 'C',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.channelName,
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _formatTimeAgo(video.createdAt),
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
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
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Tags
                if (video.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: video.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: modernTheme.primaryColor!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: modernTheme.primaryColor,
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
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      Icons.comment,
                      _formatViewCount(video.comments),
                      modernTheme,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      Icons.visibility,
                      _formatViewCount(video.views),
                      modernTheme,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      Icons.share,
                      _formatViewCount(video.shares),
                      modernTheme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: modernTheme.textSecondaryColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 14,
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

  Widget _buildAnalyticsTab(ChannelVideoModel video, ModernThemeExtension modernTheme) {
    final engagementRate = video.views > 0
        ? ((video.likes + video.comments + video.shares) / video.views * 100)
        : 0.0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance Overview
          Text(
            'Performance Overview',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Analytics Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildAnalyticsCard(
                'Total Views',
                _formatViewCount(video.views),
                Icons.visibility,
                video.isFeatured ? '⭐ Featured' : '↗ Growing',
                Colors.green,
                modernTheme,
              ),
              _buildAnalyticsCard(
                'Likes',
                _formatViewCount(video.likes),
                Icons.favorite,
                '${(video.likes / (video.views > 0 ? video.views : 1) * 100).toStringAsFixed(1)}% rate',
                Colors.red,
                modernTheme,
              ),
              _buildAnalyticsCard(
                'Comments',
                _formatViewCount(video.comments),
                Icons.comment,
                '${(video.comments / (video.views > 0 ? video.views : 1) * 100).toStringAsFixed(1)}% rate',
                Colors.blue,
                modernTheme,
              ),
              _buildAnalyticsCard(
                'Engagement',
                '${engagementRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                engagementRate > 10 ? 'Excellent' : 'Good',
                Colors.orange,
                modernTheme,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Post Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: video.isActive
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  video.isActive ? Icons.check_circle : Icons.pause_circle,
                  color: video.isActive ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post Status',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        video.isActive ? 'Active' : 'Paused',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (video.isFeatured)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Featured',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Performance Graph Placeholder
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    color: modernTheme.primaryColor,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Performance graph coming soon',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 14,
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

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    String trend,
    Color iconColor,
    ModernThemeExtension modernTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: TextStyle(
              color: trend.contains('↗') || trend.contains('Excellent') || trend.contains('Featured')
                  ? Colors.green
                  : modernTheme.textSecondaryColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTab(ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Options',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Edit Options
          _buildEditOption(
            'Add Banner Text',
            'Overlay text on your video or image',
            Icons.text_fields,
            _addBannerText,
            modernTheme,
          ),
          _buildEditOption(
            'Edit Caption',
            'Update your post description',
            Icons.edit_note,
            _editPost,
            modernTheme,
          ),
          _buildEditOption(
            'Manage Tags',
            'Add or remove hashtags',
            Icons.tag,
            _editPost,
            modernTheme,
          ),
          _buildEditOption(
            'Privacy Settings',
            'Control who can see this post',
            Icons.privacy_tip,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Privacy settings coming soon!'),
                  backgroundColor: modernTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            modernTheme,
          ),
          _buildEditOption(
            'Advanced Settings',
            'Comments, downloads, and more',
            Icons.settings,
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Advanced settings coming soon!'),
                  backgroundColor: modernTheme.primaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            modernTheme,
          ),
          
          const SizedBox(height: 24),
          
          // Post Activity Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modernTheme.primaryColor!.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.toggle_on,
                      color: modernTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Post Activity',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _video?.isActive ?? true,
                      onChanged: (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value ? 'Post activated' : 'Post paused',
                            ),
                            backgroundColor: modernTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      activeColor: modernTheme.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _video?.isActive ?? true
                      ? 'Your post is visible to viewers'
                      : 'Your post is hidden from viewers',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditOption(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    ModernThemeExtension modernTheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: modernTheme.surfaceColor,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: modernTheme.primaryColor!.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: modernTheme.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: modernTheme.textSecondaryColor,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBoostTab(ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Boost Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  modernTheme.primaryColor!,
                  modernTheme.primaryColor!.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _rocketAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -_rocketAnimation.value * 20),
                      child: Transform.rotate(
                        angle: _rocketAnimation.value * 0.8,
                        child: Icon(
                          Icons.rocket_launch,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Boost Your Post',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Increase visibility and reach more audience',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Boost Options',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Boost Options
          _buildBoostOption(
            'Quick Boost',
            '24 hours',
            '\$5.99',
            'Get 2x more views for 24 hours',
            Icons.flash_on,
            Colors.orange,
            modernTheme,
          ),
          _buildBoostOption(
            'Power Boost',
            '7 days',
            '\$19.99',
            'Get 5x more views for a week',
            Icons.rocket_launch,
            Colors.red,
            modernTheme,
          ),
          _buildBoostOption(
            'Mega Boost',
            '30 days',
            '\$49.99',
            'Get 10x more views for a month',
            Icons.star,
            Colors.purple,
            modernTheme,
          ),
          
          const SizedBox(height: 24),
          
          // Current Boost Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modernTheme.primaryColor!.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: modernTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Current Status',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'No active boost',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Boost your post to reach up to 10x more viewers and get more engagement.',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostOption(
    String title,
    String duration,
    String price,
    String description,
    IconData icon,
    Color color,
    ModernThemeExtension modernTheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Text(
              price,
              style: TextStyle(
                color: modernTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Duration: $duration',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: _boostPost,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          child: const Text('Select'),
        ),
      ),
    );
  }
}