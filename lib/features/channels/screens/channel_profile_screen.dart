import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      Constants.channelVideoDetailScreen,
      arguments: video.id,
    ).then((_) => _loadChannelData());
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
              : _buildProfileView(modernTheme),
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
              'Error loading channel',
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

  Widget _buildProfileView(ModernThemeExtension modernTheme) {
    if (_channel == null) {
      return const Center(child: Text('Channel not found'));
    }

    return CustomScrollView(
      slivers: [
        // App bar with channel cover image
        SliverAppBar(
          backgroundColor: Colors.transparent,
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _channel!.coverImage.isNotEmpty
                ? Image.network(
                    _channel!.coverImage,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Colors.grey[800],
                    child: Center(
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
                    ),
                  ),
          ),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (_isOwner)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: _editChannel,
              ),
          ],
        ),
        
        // Channel info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile image, name and follow button
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
                    
                    // Follow/Unfollow button or create post button
                    if (_isOwner)
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
                      )
                    else
                      ElevatedButton(
                        onPressed: _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing
                              ? Colors.grey[700]
                              : modernTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(_isFollowing ? 'Following' : 'Follow'),
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
                    _buildStatColumn(_channel!.followers.toString(), 'Followers'),
                    _buildStatColumn(_channel!.videosCount.toString(), 'Videos'),
                    _buildStatColumn(_channel!.likesCount.toString(), 'Likes'),
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
                Text(
                  'Content',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Content count
                Text(
                  '${_channelVideos.length} videos and posts',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Channel content grid
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
                        if (_isOwner)
                          Text(
                            'Create your first post to share with your followers',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            'This channel hasn\'t posted any content yet',
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
            : SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 3/4, // Slightly taller than wide
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final video = _channelVideos[index];
                      
                      return GestureDetector(
                        onTap: () => _openVideoDetails(video),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[800],
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
                              if (!video.isMultipleImages)
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
                                      Icons.videocam,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        video.caption,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.favorite,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${video.likes}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.visibility,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${video.views}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
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
                    childCount: _channelVideos.length,
                  ),
                ),
              ),
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }
  
  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}