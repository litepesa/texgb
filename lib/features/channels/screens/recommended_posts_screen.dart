// lib/features/channels/screens/recommended_posts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/constants.dart';

class RecommendedPostsScreen extends ConsumerStatefulWidget {
  const RecommendedPostsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RecommendedPostsScreen> createState() => _RecommendedPostsScreenState();
}

class _RecommendedPostsScreenState extends ConsumerState<RecommendedPostsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelVideosProvider.notifier).loadVideos();
      ref.read(channelsProvider.notifier).loadChannels();
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showFloatingButton) {
      setState(() => _showFloatingButton = true);
    } else if (_scrollController.offset <= 200 && _showFloatingButton) {
      setState(() => _showFloatingButton = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelVideosState = ref.watch(channelVideosProvider);
    final channelsState = ref.watch(channelsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: _buildBody(channelVideosState, channelsState),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: const Text(
        'Recommended',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.search, color: Colors.white),
          onPressed: () {
            // TODO: Navigate to search screen
          },
        ),
        IconButton(
          icon: const Icon(CupertinoIcons.bell, color: Colors.white),
          onPressed: () {
            // TODO: Navigate to notifications screen
          },
        ),
      ],
    );
  }

  Widget _buildBody(ChannelVideosState videosState, ChannelsState channelsState) {
    if (videosState.isLoading && videosState.videos.isEmpty) {
      return _buildLoadingState();
    }

    if (videosState.error != null) {
      return _buildErrorState(videosState.error!);
    }

    if (videosState.videos.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(channelVideosProvider.notifier).loadVideos(forceRefresh: true);
        await ref.read(channelsProvider.notifier).loadChannels(forceRefresh: true);
      },
      backgroundColor: Colors.grey[900],
      color: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Trending section
          SliverToBoxAdapter(
            child: _buildSectionHeader('Trending Now', Icons.trending_up),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Show top 6 trending videos
                  if (index >= videosState.videos.length || index >= 6) return null;
                  return _buildVideoThumbnail(videosState.videos[index], isTrending: true);
                },
                childCount: videosState.videos.length > 6 ? 6 : videosState.videos.length,
              ),
            ),
          ),

          // Recent posts section
          SliverToBoxAdapter(
            child: _buildSectionHeader('Latest Posts', Icons.access_time),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Show remaining videos starting from index 6
                  final videoIndex = index + 6;
                  if (videoIndex >= videosState.videos.length) return null;
                  return _buildHorizontalVideoCard(videosState.videos[videoIndex]);
                },
                childCount: videosState.videos.length > 6 ? videosState.videos.length - 6 : 0,
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnail(ChannelVideoModel video, {bool isTrending = false}) {
    return GestureDetector(
      onTap: () => _navigateToVideoFeed(video),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[900],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[800],
                ),
                child: Stack(
                  children: [
                    // Video thumbnail or first image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: _buildThumbnailImage(video),
                    ),
                    
                    // Play indicator for videos
                    if (!video.isMultipleImages)
                      const Center(
                        child: Icon(
                          CupertinoIcons.play_circle,
                          color: Colors.white,
                          size: 32,
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.collections,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${video.imageUrls.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Trending badge
                    if (isTrending)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'TRENDING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    
                    // Video stats overlay
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.heart,
                              color: Colors.white,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatCount(video.likes),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Video info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Caption
                    Text(
                      video.caption.isNotEmpty ? video.caption : 'No caption',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    
                    // Channel info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundImage: video.channelImage.isNotEmpty
                              ? NetworkImage(video.channelImage)
                              : null,
                          backgroundColor: Colors.grey,
                          child: video.channelImage.isEmpty
                              ? Text(
                                  video.channelName.isNotEmpty 
                                      ? video.channelName[0].toUpperCase()
                                      : "U",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            video.channelName,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildHorizontalVideoCard(ChannelVideoModel video) {
    return GestureDetector(
      onTap: () => _navigateToVideoFeed(video),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 120,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[800],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildThumbnailImage(video),
                  ),
                  
                  // Play indicator
                  if (!video.isMultipleImages)
                    const Center(
                      child: Icon(
                        CupertinoIcons.play_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  
                  // Multiple images indicator
                  if (video.isMultipleImages && video.imageUrls.length > 1)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${video.imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Video info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Caption
                  Text(
                    video.caption.isNotEmpty ? video.caption : 'No caption',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Channel info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: video.channelImage.isNotEmpty
                            ? NetworkImage(video.channelImage)
                            : null,
                        backgroundColor: Colors.grey,
                        child: video.channelImage.isEmpty
                            ? Text(
                                video.channelName.isNotEmpty 
                                    ? video.channelName[0].toUpperCase()
                                    : "U",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          video.channelName,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Stats
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.heart,
                        color: Colors.grey,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(video.likes),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        CupertinoIcons.chat_bubble,
                        color: Colors.grey,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(video.comments),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        CupertinoIcons.eye,
                        color: Colors.grey,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(video.views),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(ChannelVideoModel video) {
    String imageUrl = '';
    
    if (video.isMultipleImages && video.imageUrls.isNotEmpty) {
      imageUrl = video.imageUrls.first;
    } else if (video.thumbnailUrl.isNotEmpty) {
      imageUrl = video.thumbnailUrl;
    }
    
    if (imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[800],
        child: const Icon(
          Icons.video_library,
          color: Colors.grey,
          size: 32,
        ),
      );
    }
    
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[800],
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[800],
          child: const Icon(
            Icons.broken_image,
            color: Colors.grey,
            size: 32,
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading recommendations...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(channelVideosProvider.notifier).loadVideos(forceRefresh: true);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: Colors.grey,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No videos available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for new content',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (!_showFloatingButton) return null;
    
    return FloatingActionButton(
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      },
      backgroundColor: Colors.white,
      child: const Icon(
        Icons.keyboard_arrow_up,
        color: Colors.black,
      ),
    );
  }

  void _navigateToVideoFeed(ChannelVideoModel video) {
    // Navigate to the channels feed screen with the specific video
    Navigator.pushNamed(
      context,
      Constants.channelsFeedScreen,
      arguments: {
        'startVideoId': video.id,
        'channelId': video.channelId,
      },
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