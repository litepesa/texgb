import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

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
      // TODO: Implement actual video loading logic
      // For now, we'll simulate loading
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Generate thumbnail if it's a video
      if (_video != null && !_video!.isMultipleImages && _video!.videoUrl.isNotEmpty) {
        _generateVideoThumbnail();
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: _video!.videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 300,
        quality: 85,
      );
      
      if (thumbnailPath != null && mounted) {
        setState(() {
          _videoThumbnail = thumbnailPath;
        });
      }
    } catch (e) {
      print('Error generating thumbnail: $e');
    }
  }

  void _boostPost() {
    _rocketAnimationController.forward().then((_) {
      _rocketAnimationController.reset();
    });
    
    // TODO: Implement boost logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🚀 Post boost feature coming soon!'),
        backgroundColor: context.modernTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editPost() {
    // TODO: Navigate to edit post screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit post feature coming soon!'),
        backgroundColor: context.modernTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addBannerText() {
    // TODO: Implement banner text editor
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Banner text editor coming soon!'),
        backgroundColor: context.modernTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deletePost() {
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
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to channel screen
              // TODO: Implement delete logic
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

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      body: _isLoading
          ? _buildLoadingView(modernTheme)
          : _error != null
              ? _buildErrorView(modernTheme)
              : _buildPostView(modernTheme),
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
                      _error!,
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
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
    // TODO: Replace with actual video data from provider
    final dummyVideo = ChannelVideoModel(
      id: widget.videoId,
      channelId: 'channel_123',
      channelName: 'My Channel',
      channelImage: 'https://picsum.photos/100/100',
      userId: 'user_123',
      videoUrl: 'https://example.com/video.mp4',
      thumbnailUrl: 'https://picsum.photos/400/600',
      caption: 'Amazing sunset view from my balcony! 🌅',
      likes: 142,
      comments: 23,
      views: 1250,
      shares: 8,
      isLiked: false,
      tags: ['sunset', 'nature', 'photography'],
      createdAt: Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      isActive: true,
      isFeatured: false,
      isMultipleImages: false,
      imageUrls: [],
    );

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
          _buildPostPreviewCard(dummyVideo, modernTheme),
          
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
                _buildAnalyticsTab(dummyVideo, modernTheme),
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
                      Image.network(
                        video.imageUrls.first,
                        fit: BoxFit.cover,
                      )
                    else if (!video.isMultipleImages && _videoThumbnail != null)
                      Image.file(
                        File(_videoThumbnail!),
                        fit: BoxFit.cover,
                      )
                    else if (!video.isMultipleImages && video.thumbnailUrl.isNotEmpty)
                      Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
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
                Text(
                  video.caption,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
                    _buildStatChip(Icons.favorite, '${video.likes}', modernTheme),
                    const SizedBox(width: 12),
                    _buildStatChip(Icons.comment, '${video.comments}', modernTheme),
                    const SizedBox(width: 12),
                    _buildStatChip(Icons.visibility, '${video.views}', modernTheme),
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
                '${video.views}',
                Icons.visibility,
                '↗ 12% vs last post',
                Colors.green,
                modernTheme,
              ),
              _buildAnalyticsCard(
                'Likes',
                '${video.likes}',
                Icons.favorite,
                '↗ 8% vs last post',
                Colors.red,
                modernTheme,
              ),
              _buildAnalyticsCard(
                'Comments',
                '${video.comments}',
                Icons.comment,
                '↗ 15% vs last post',
                Colors.blue,
                modernTheme,
              ),
              _buildAnalyticsCard(
                'Engagement',
                '${((video.likes + video.comments) / video.views * 100).toStringAsFixed(1)}%',
                Icons.trending_up,
                'Above average',
                Colors.orange,
                modernTheme,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          Text(
            'Recent Activity',
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildActivityItem(
            'New like from @user123',
            '2 minutes ago',
            Icons.favorite,
            Colors.red,
            modernTheme,
          ),
          _buildActivityItem(
            'Comment from @johndoe',
            '5 minutes ago',
            Icons.comment,
            Colors.blue,
            modernTheme,
          ),
          _buildActivityItem(
            'Shared by @sarah_m',
            '1 hour ago',
            Icons.share,
            Colors.green,
            modernTheme,
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
              color: Colors.green,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color iconColor,
    ModernThemeExtension modernTheme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  time,
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
            _editPost,
            modernTheme,
          ),
          _buildEditOption(
            'Advanced Settings',
            'Comments, downloads, and more',
            Icons.settings,
            _editPost,
            modernTheme,
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