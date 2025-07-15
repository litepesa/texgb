import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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

class ChannelProfileScreen extends ConsumerStatefulWidget {
  final String channelId;
  
  const ChannelProfileScreen({
    Key? key,
    required this.channelId,
  }) : super(key: key);

  @override
  ConsumerState<ChannelProfileScreen> createState() => _ChannelProfileScreenState();
}

class _ChannelProfileScreenState extends ConsumerState<ChannelProfileScreen> {
  bool _isLoading = true;
  ChannelModel? _channel;
  List<ChannelVideoModel> _channelVideos = [];
  String? _error;
  bool _isFollowing = false;
  bool _isOwner = false;
  final ScrollController _scrollController = ScrollController();
  final Map<String, String> _videoThumbnails = {};
  
  // Cache manager for video thumbnails
  static final _thumbnailCacheManager = CacheManager(
    Config(
      'channelVideoThumbnails',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
    ),
  );

  // Custom white theme
  static const _whiteTheme = _WhiteTheme();

  @override
  void initState() {
    super.initState();
    _loadChannelData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChannelData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get channel data
      final channel = await ref.read(channelsProvider.notifier).getChannelById(widget.channelId);
      
      if (channel == null) {
        throw Exception('Channel not found');
      }
      
      // Get channel videos
      final videos = await ref.read(channelVideosProvider.notifier).loadChannelVideos(widget.channelId);
      
      // Check if user is following this channel
      final followedChannels = ref.read(channelsProvider).followedChannels;
      final isFollowing = followedChannels.contains(widget.channelId);
      
      // Check if user is the owner of this channel
      final userChannel = ref.read(channelsProvider).userChannel;
      final isOwner = userChannel != null && userChannel.id == widget.channelId;
      
      if (mounted) {
        setState(() {
          _channel = channel;
          _channelVideos = videos;
          _isFollowing = isFollowing;
          _isOwner = isOwner;
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
              maxHeight: 400, // Higher quality for better display
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

  void _toggleFollow() async {
    if (_channel == null) return;
    
    // Update local state first (optimistic update)
    setState(() {
      _isFollowing = !_isFollowing;
    });
    
    // Update in provider
    await ref.read(channelsProvider.notifier).toggleFollowChannel(_channel!.id);
    
    // Refresh data
    _loadChannelData();
  }

  void _editChannel() {
    // Navigate to EditChannelScreen
    Navigator.pushNamed(
      context, 
      Constants.editChannelScreen,
      arguments: _channel,
    ).then((_) => _loadChannelData());
  }

  void _createPost() {
    // Navigate to CreateChannelPostScreen
    Navigator.pushNamed(context, Constants.createChannelPostScreen)
        .then((result) {
      if (result == true) {
        _loadChannelData();
      }
    });
  }

  void _openVideoDetails(ChannelVideoModel video) {
    // Navigate to ChannelVideoDetailScreen
    Navigator.pushNamed(
      context, 
      Constants.channelFeedScreen,
      arguments: video.id,
    ).then((_) => _loadChannelData());
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
    return Scaffold(
      backgroundColor: _whiteTheme.backgroundColor,
      body: _isLoading
          ? _buildLoadingView()
          : _error != null
              ? _buildErrorView()
              : _buildProfileView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: CircularProgressIndicator(
        color: _whiteTheme.primaryColor,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildErrorView() {
    return SafeArea(
      child: Column(
        children: [
          // App Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: _whiteTheme.backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: _whiteTheme.dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: _whiteTheme.textColor,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  'Profile',
                  style: TextStyle(
                    color: _whiteTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
                      color: _whiteTheme.primaryColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Channel not found',
                      style: TextStyle(
                        color: _whiteTheme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This channel may have been deleted or doesn\'t exist',
                      style: TextStyle(
                        color: _whiteTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Go Back',
                        style: TextStyle(
                          color: _whiteTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildProfileView() {
    if (_channel == null) {
      return Center(
        child: Text(
          'Channel not found',
          style: TextStyle(
            color: _whiteTheme.textColor,
            fontSize: 16,
          ),
        ),
      );
    }

    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            backgroundColor: _whiteTheme.backgroundColor,
            elevation: 0,
            pinned: true,
            floating: false,
            snap: false,
            expandedHeight: 380,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: _whiteTheme.textColor,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (_isOwner)
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: _whiteTheme.textColor,
                  ),
                  onPressed: _editChannel,
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 60,
                      bottom: 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Profile Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _whiteTheme.dividerColor,
                              width: 2,
                            ),
                          ),
                          child: _channel!.profileImage.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: _channel!.profileImage,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    placeholder: (context, url) => Container(
                                      color: _whiteTheme.surfaceColor,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _whiteTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: _whiteTheme.surfaceColor,
                                      child: Center(
                                        child: Text(
                                          _channel!.name.isNotEmpty
                                              ? _channel!.name[0].toUpperCase()
                                              : "C",
                                          style: TextStyle(
                                            color: _whiteTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 36,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _whiteTheme.surfaceColor,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _channel!.name.isNotEmpty
                                          ? _channel!.name[0].toUpperCase()
                                          : "C",
                                      style: TextStyle(
                                        color: _whiteTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 36,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Channel Name and Verification
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                _channel!.name,
                                style: TextStyle(
                                  color: _whiteTheme.textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (_channel!.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                color: _whiteTheme.primaryColor,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Owner Name
                        Text(
                          '@${_channel!.ownerName}',
                          style: TextStyle(
                            color: _whiteTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatColumn(
                              _formatViewCount(_channel!.followers),
                              'Followers',
                            ),
                            _buildStatColumn(
                              _formatViewCount(_channel!.videosCount),
                              'Videos',
                            ),
                            _buildStatColumn(
                              _formatViewCount(_channel!.likesCount),
                              'Likes',
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Action Button
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: _isOwner
                              ? OutlinedButton.icon(
                                  onPressed: _createPost,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Create Post'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _whiteTheme.primaryColor,
                                    side: BorderSide(color: _whiteTheme.primaryColor),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFollowing
                                        ? _whiteTheme.surfaceColor
                                        : _whiteTheme.primaryColor,
                                    foregroundColor: _isFollowing
                                        ? _whiteTheme.textColor
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: _isFollowing 
                                          ? BorderSide(color: _whiteTheme.dividerColor)
                                          : BorderSide.none,
                                    ),
                                  ),
                                  child: Text(
                                    _isFollowing ? 'Following' : 'Follow',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ];
      },
      body: Column(
        children: [
          // Description Section (if available)
          if (_channel!.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _whiteTheme.backgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: _whiteTheme.dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Text(
                _channel!.description,
                style: TextStyle(
                  color: _whiteTheme.textColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          
          // Content Section
          Expanded(
            child: _channelVideos.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(1),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                      childAspectRatio: 9 / 16, // TikTok-like aspect ratio
                    ),
                    itemCount: _channelVideos.length,
                    itemBuilder: (context, index) {
                      final video = _channelVideos[index];
                      
                      return GestureDetector(
                        onTap: () => _openVideoDetails(video),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _whiteTheme.surfaceColor,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Video Thumbnail
                              if (video.thumbnailUrl.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: video.thumbnailUrl,
                                  fit: BoxFit.cover,
                                  memCacheHeight: 600, // Optimize memory usage
                                  placeholder: (context, url) => Container(
                                    color: _whiteTheme.surfaceColor,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _whiteTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    return _buildThumbnailPlaceholder();
                                  },
                                )
                              else if (video.isMultipleImages && video.imageUrls.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: video.imageUrls.first,
                                  fit: BoxFit.cover,
                                  memCacheHeight: 600, // Optimize memory usage
                                  placeholder: (context, url) => Container(
                                    color: _whiteTheme.surfaceColor,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _whiteTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    return _buildThumbnailPlaceholder();
                                  },
                                )
                              else if (!video.isMultipleImages && _videoThumbnails.containsKey(video.id))
                                Image.file(
                                  File(_videoThumbnails[video.id]!),
                                  fit: BoxFit.cover,
                                )
                              else
                                _buildThumbnailPlaceholder(),
                              
                              // Multiple Images Indicator
                              if (video.isMultipleImages && video.imageUrls.length > 1)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.collections,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              
                              // View Count
                              Positioned(
                                bottom: 4,
                                left: 4,
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
                                        Icons.visibility,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _formatViewCount(video.views),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: _whiteTheme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: _whiteTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_outlined,
            color: _whiteTheme.textSecondaryColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No videos yet',
            style: TextStyle(
              color: _whiteTheme.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isOwner
                ? 'Start creating content to share with your followers'
                : 'This channel hasn\'t shared any videos yet',
            style: TextStyle(
              color: _whiteTheme.textSecondaryColor,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      color: _whiteTheme.surfaceColor,
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          color: _whiteTheme.primaryColor,
          size: 32,
        ),
      ),
    );
  }
}

// Custom white theme class
class _WhiteTheme {
  const _WhiteTheme();
  
  Color get backgroundColor => Color(0xFF8E8E93);
  Color get surfaceColor => const Color(0xFFF8F9FA);
  Color get primaryColor => const Color(0xFF007AFF);
  Color get textColor => const Color(0xFF1C1C1E);
  Color get textSecondaryColor => Colors.white70;
  Color get dividerColor => const Color(0xFFE5E5EA);
}