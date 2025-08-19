import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class MyChannelScreen extends ConsumerStatefulWidget {
  const MyChannelScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MyChannelScreen> createState() => _MyChannelScreenState();
}

class _MyChannelScreenState extends ConsumerState<MyChannelScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  ChannelModel? _channel;
  List<ChannelVideoModel> _channelVideos = [];
  String? _error;
  bool _isDeleting = false;
  late TabController _tabController;
  Map<String, String> _videoThumbnails = {};
  
  // Cache manager for video thumbnails
  static final _thumbnailCacheManager = CacheManager(
    Config(
      'channelVideoThumbnails',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChannelData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChannelData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get user's channel data
      final userChannel = ref.read(channelsProvider).userChannel;
      
      if (userChannel == null) {
        throw Exception('Channel not found');
      }
      
      // Get channel videos
      final videos = await ref.read(channelVideosProvider.notifier).loadChannelVideos(userChannel.id);
      
      if (mounted) {
        setState(() {
          _channel = userChannel;
          _channelVideos = videos;
          _isLoading = false;
        });
        
        // Generate thumbnails for video content
        _generateVideoThumbnails();
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

  Future<void> _generateVideoThumbnails() async {
    for (final video in _channelVideos) {
      if (!video.isMultipleImages && video.videoUrl.isNotEmpty) {
        try {
          // Check if thumbnail is already cached
          final cacheKey = 'thumb_${video.id}';
          final fileInfo = await _thumbnailCacheManager.getFileFromCache(cacheKey);
          
          if (fileInfo != null && fileInfo.file.existsSync()) {
            // Use cached thumbnail
            if (mounted) {
              setState(() {
                _videoThumbnails[video.id] = fileInfo.file.path;
              });
            }
          } else {
            // Generate new thumbnail
            final thumbnailPath = await VideoThumbnail.thumbnailFile(
              video: video.videoUrl,
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
                _videoThumbnails[video.id] = thumbnailPath;
              });
            }
          }
        } catch (e) {
          print('Error generating thumbnail for video ${video.id}: $e');
        }
      }
    }
  }

  void _editChannel() {
    if (_channel == null) return;
    
    Navigator.pushNamed(
      context, 
      Constants.editChannelScreen,
      arguments: _channel,
    ).then((_) => _loadChannelData());
  }



  Future<void> _deleteVideo(String videoId) async {
    if (_isDeleting) return;
    
    setState(() {
      _isDeleting = true;
    });
    
    try {
      await ref.read(channelVideosProvider.notifier).deleteVideo(
        videoId,
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
      
      _loadChannelData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting video: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _confirmDeleteVideo(ChannelVideoModel video) {
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
            const Text('Delete Content'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${video.caption}"? This action cannot be undone.',
          style: const TextStyle(fontSize: 16),
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
              _deleteVideo(video.id);
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

  void _openVideoDetails(ChannelVideoModel video) {
    Navigator.pushNamed(
      context, 
      Constants.myPostScreen,
      arguments: video.id,
    ).then((_) => _loadChannelData());
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: _isLoading
          ? _buildLoadingView(modernTheme)
          : _error != null
              ? _buildErrorView(modernTheme)
              : _buildChannelView(modernTheme),
    );
  }

  Widget _buildLoadingView(ModernThemeExtension modernTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: modernTheme.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your channel...',
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ModernThemeExtension modernTheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadChannelData,
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
                elevation: 4,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelView(ModernThemeExtension modernTheme) {
    if (_channel == null) {
      return const Center(child: Text('Channel not found'));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Channel Header
              _buildChannelHeader(modernTheme),
              
              // Channel Info Card
              _buildChannelInfoCard(modernTheme),
              
              // Tab Bar
              Container(
                color: modernTheme.surfaceColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: modernTheme.primaryColor,
                  unselectedLabelColor: modernTheme.textSecondaryColor,
                  indicatorColor: modernTheme.primaryColor,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.grid_view),
                      text: 'Posts',
                    ),
                    Tab(
                      icon: Icon(Icons.analytics),
                      text: 'Analytics',
                    ),
                  ],
                ),
              ),
              
              // Tab Content
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPostsTab(modernTheme),
                    _buildAnalyticsTab(modernTheme),
                  ],
                ),
              ),
              
              // Bottom padding
              const SizedBox(height: 80),
            ],
          ),
        ),
        extendBodyBehindAppBar: true,
      ),
    );
  }

  Widget _buildChannelHeader(ModernThemeExtension modernTheme) {
    final systemTopPadding = MediaQuery.of(context).padding.top;
    
    return Container(
      height: 320 + systemTopPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            modernTheme.primaryColor!,
            modernTheme.primaryColor!.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Cover Image
          if (_channel!.coverImage.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: _channel!.coverImage,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        modernTheme.primaryColor!,
                        modernTheme.primaryColor!.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        modernTheme.primaryColor!,
                        modernTheme.primaryColor!.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.white30,
                    size: 48,
                  ),
                ),
              ),
            ),
          
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Edit Channel Button
          Positioned(
            top: systemTopPadding + 16,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _editChannel,
                  borderRadius: BorderRadius.circular(25),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          color: modernTheme.primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit Channel',
                          style: TextStyle(
                            color: modernTheme.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Channel Content
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _channel!.profileImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _channel!.profileImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: modernTheme.primaryColor!.withOpacity(0.1),
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
                              color: modernTheme.primaryColor,
                              child: Center(
                                child: Text(
                                  _channel!.name.isNotEmpty
                                      ? _channel!.name[0].toUpperCase()
                                      : "C",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 36,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: modernTheme.primaryColor,
                            child: Center(
                              child: Text(
                                _channel!.name.isNotEmpty
                                    ? _channel!.name[0].toUpperCase()
                                    : "C",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Channel Info
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _channel!.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_channel!.isVerified) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_channel!.followers} followers',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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

  Widget _buildChannelInfoCard(ModernThemeExtension modernTheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (_channel!.description.isNotEmpty) ...[
            Text(
              _channel!.description,
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 16,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ],
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                _channel!.followers.toString(),
                'Followers',
                Icons.people,
                modernTheme,
              ),
              _buildStatItem(
                _channel!.videosCount.toString(),
                'Posts',
                Icons.video_library,
                modernTheme,
              ),
              _buildStatItem(
                _channel!.likesCount.toString(),
                'Likes',
                Icons.favorite,
                modernTheme,
              ),
            ],
          ),
          
          // Tags
          if (_channel!.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _channel!.tags.length,
                itemBuilder: (context, index) {
                  final tag = _channel!.tags[index];
                  return Container(
                    margin: EdgeInsets.only(right: index < _channel!.tags.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: modernTheme.primaryColor!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: modernTheme.primaryColor!.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        color: modernTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String count,
    String label,
    IconData icon,
    ModernThemeExtension modernTheme,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: modernTheme.primaryColor,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: modernTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab(ModernThemeExtension modernTheme) {
    if (_channelVideos.isEmpty) {
      return _buildEmptyState(modernTheme);
    }

    return GridView.builder(
      padding: const EdgeInsets.only(
        left: 4,
        right: 4,
        top: 4,
        bottom: 20,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 9 / 16,
      ),
      itemCount: _channelVideos.length,
      itemBuilder: (context, index) {
        final video = _channelVideos[index];
        return _buildVideoCard(video, modernTheme);
      },
    );
  }

  Widget _buildVideoCard(ChannelVideoModel video, ModernThemeExtension modernTheme) {
    return GestureDetector(
      onTap: () => _openVideoDetails(video),
      onLongPress: () => _confirmDeleteVideo(video),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail covering the entire tile
          if (video.isMultipleImages && video.imageUrls.isNotEmpty)
            CachedNetworkImage(
              imageUrl: video.imageUrls.first,
              fit: BoxFit.cover,
              memCacheHeight: 600,
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
                  Icons.photo_library,
                  color: modernTheme.primaryColor,
                  size: 48,
                ),
              ),
            )
          else if (!video.isMultipleImages && _videoThumbnails.containsKey(video.id))
            Image.file(
              File(_videoThumbnails[video.id]!),
              fit: BoxFit.cover,
            )
          else if (!video.isMultipleImages && video.thumbnailUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: video.thumbnailUrl,
              fit: BoxFit.cover,
              memCacheHeight: 600,
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
                  Icons.play_circle_fill,
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
                size: 48,
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
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // View count at bottom left
          Positioned(
            bottom: 8,
            left: 8,
            child: Row(
              children: [
                const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatViewCount(video.views),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
          
          // Multiple images indicator
          if (video.isMultipleImages && video.imageUrls.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${video.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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

  String _formatViewCount(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  Widget _buildEmptyState(ModernThemeExtension modernTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_library_outlined,
                color: modernTheme.primaryColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No content yet',
              style: TextStyle(
                color: modernTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your posts will appear here when you start sharing content',
              style: TextStyle(
                color: modernTheme.textSecondaryColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(ModernThemeExtension modernTheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overview Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: modernTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Channel Overview',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Total Views',
                        _channelVideos.fold<int>(0, (sum, video) => sum + video.views).toString(),
                        Icons.visibility,
                        modernTheme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Total Likes',
                        _channelVideos.fold<int>(0, (sum, video) => sum + video.likes).toString(),
                        Icons.favorite,
                        modernTheme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Comments',
                        _channelVideos.fold<int>(0, (sum, video) => sum + video.comments).toString(),
                        Icons.comment,
                        modernTheme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnalyticsCard(
                        'Engagement',
                        '${_calculateEngagementRate().toStringAsFixed(1)}%',
                        Icons.trending_up,
                        modernTheme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Performance Tips
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: modernTheme.primaryColor!.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: modernTheme.primaryColor!.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: modernTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Performance Tips',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTipItem(
                  'Post consistently to keep your audience engaged',
                  Icons.schedule,
                  modernTheme,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Use trending hashtags to increase visibility',
                  Icons.tag,
                  modernTheme,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Respond to comments to boost engagement',
                  Icons.chat_bubble_outline,
                  modernTheme,
                ),
              ],
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
    ModernThemeExtension modernTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modernTheme.primaryColor!.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: modernTheme.primaryColor,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: modernTheme.textSecondaryColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon, ModernThemeExtension modernTheme) {
    return Row(
      children: [
        Icon(
          icon,
          color: modernTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: modernTheme.textColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  double _calculateEngagementRate() {
    if (_channelVideos.isEmpty) return 0.0;
    
    final totalEngagement = _channelVideos.fold<int>(
      0,
      (sum, video) => sum + video.likes + video.comments,
    );
    final totalViews = _channelVideos.fold<int>(
      0,
      (sum, video) => sum + video.views,
    );
    
    if (totalViews == 0) return 0.0;
    return (totalEngagement / totalViews) * 100;
  }}