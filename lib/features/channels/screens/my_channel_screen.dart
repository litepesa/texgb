import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _MyChannelScreenState extends ConsumerState<MyChannelScreen> {
  bool _isLoading = true;
  ChannelModel? _channel;
  List<ChannelVideoModel> _channelVideos = [];
  String? _error;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadChannelData();
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
        throw Exception('You don\'t have a channel yet');
      }
      
      // Get channel videos
      final videos = await ref.read(channelVideosProvider.notifier).loadChannelVideos(userChannel.id);
      
      if (mounted) {
        setState(() {
          _channel = userChannel;
          _channelVideos = videos;
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

  void _editChannel() {
    if (_channel == null) return;
    
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
            SnackBar(content: Text(error)),
          );
        },
      );
      
      // Refresh videos after deletion
      _loadChannelData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting video: ${e.toString()}')),
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
        title: const Text('Delete Content'),
        content: Text('Are you sure you want to delete "${video.caption}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteVideo(video.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openVideoDetails(ChannelVideoModel video) {
    // Navigate to ChannelVideoDetailScreen
    Navigator.pushNamed(
      context, 
      Constants.channelVideoDetailScreen,
      arguments: video.id,
    ).then((_) => _loadChannelData());
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'My Channel',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: modernTheme.textColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: modernTheme.textColor,
            ),
            onPressed: _channel != null ? _editChannel : null,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: modernTheme.primaryColor,
              ),
            )
          : _error != null
              ? _buildErrorView(modernTheme)
              : _buildChannelView(modernTheme),
      floatingActionButton: _channel != null
          ? FloatingActionButton(
              backgroundColor: modernTheme.primaryColor,
              onPressed: _createPost,
              child: const Icon(Icons.add),
            )
          : null,
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
              'Channel Not Found',
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
              onPressed: () => Navigator.pushNamed(context, Constants.createChannelScreen),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Create a Channel'),
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

    return RefreshIndicator(
      onRefresh: _loadChannelData,
      child: CustomScrollView(
        slivers: [
          // Channel cover image
          SliverToBoxAdapter(
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                image: _channel!.coverImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_channel!.coverImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _channel!.coverImage.isEmpty
                  ? Center(
                      child: Text(
                        _channel!.name.isNotEmpty
                            ? _channel!.name[0].toUpperCase()
                            : "C",
                        style: TextStyle(
                          color: modernTheme.primaryColor,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          
          // Channel info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image, name and create post button
                  Row(
                    children: [
                      // Profile image
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                        backgroundImage: _channel!.profileImage.isNotEmpty
                            ? NetworkImage(_channel!.profileImage)
                            : null,
                        child: _channel!.profileImage.isEmpty
                            ? Text(
                                _channel!.name.isNotEmpty
                                    ? _channel!.name[0].toUpperCase()
                                    : "C",
                                style: TextStyle(
                                  color: modernTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                              )
                            : null,
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Channel name and owner
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _channel!.name,
                                  style: TextStyle(
                                    color: modernTheme.textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                                if (_channel!.isVerified)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              'Owner: ${_channel!.ownerName}',
                              style: TextStyle(
                                color: modernTheme.textSecondaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Create post button
                      ElevatedButton.icon(
                        onPressed: _createPost,
                        icon: const Icon(Icons.add),
                        label: const Text('Post'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: modernTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Channel description
                  Text(
                    _channel!.description,
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontSize: 16,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Channel stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(_channel!.followers.toString(), 'Followers', modernTheme),
                      _buildStatColumn(_channel!.videosCount.toString(), 'Videos', modernTheme),
                      _buildStatColumn(_channel!.likesCount.toString(), 'Likes', modernTheme),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tags
                  if (_channel!.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _channel!.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: modernTheme.primaryColor!.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              color: modernTheme.primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Content header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Content',
                        style: TextStyle(
                          color: modernTheme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '${_channelVideos.length} posts',
                        style: TextStyle(
                          color: modernTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Channel content list
          _channelVideos.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.videocam_off,
                            color: modernTheme.textSecondaryColor,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No content yet',
                            style: TextStyle(
                              color: modernTheme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first post to share with your followers',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final video = _channelVideos[index];
                      return _buildVideoItem(video, modernTheme);
                    },
                    childCount: _channelVideos.length,
                  ),
                ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatColumn(String count, String label, ModernThemeExtension modernTheme) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
  
  Widget _buildVideoItem(ChannelVideoModel video, ModernThemeExtension modernTheme) {
    return Dismissible(
      key: Key(video.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        _confirmDeleteVideo(video);
        return false; // Don't dismiss automatically
      },
      child: InkWell(
        onTap: () => _openVideoDetails(video),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: modernTheme.dividerColor!,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade800,
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
                          color: modernTheme.primaryColor,
                          size: 32,
                        ),
                      ),
                    if (video.isMultipleImages && video.imageUrls.length > 1)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Content details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.caption,
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Stats row
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: modernTheme.textSecondaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${video.likes}',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Icon(
                          Icons.comment,
                          color: modernTheme.textSecondaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${video.comments}',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Icon(
                          Icons.visibility,
                          color: modernTheme.textSecondaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${video.views}',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Tags
                    if (video.tags.isNotEmpty)
                      SizedBox(
                        height: 24,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: video.tags.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: modernTheme.primaryColor!.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '#${video.tags[index]}',
                                style: TextStyle(
                                  color: modernTheme.primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              
              // Delete button
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: modernTheme.textSecondaryColor,
                ),
                onPressed: () => _confirmDeleteVideo(video),
              ),
            ],
          ),
        ),
      ),
    );
  }
}