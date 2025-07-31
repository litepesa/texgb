// lib/features/channels/screens/recommended_posts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/models/channel_video_model.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class RecommendedPostsScreen extends ConsumerStatefulWidget {
  const RecommendedPostsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RecommendedPostsScreen> createState() => _RecommendedPostsScreenState();
}

class _RecommendedPostsScreenState extends ConsumerState<RecommendedPostsScreen> {
  final ScrollController _scrollController = ScrollController();
  
  // Cache for recommended videos to avoid reloading
  List<ChannelVideoModel> _recommendedVideos = [];
  bool _isLoadingRecommendations = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load recommended videos when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendedVideos();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load recommended videos efficiently
  /// This method selects videos from channels with recent activity
  Future<void> _loadRecommendedVideos({bool forceRefresh = false}) async {
    if (_isLoadingRecommendations && !forceRefresh) return;

    setState(() {
      _isLoadingRecommendations = true;
      _error = null;
      if (forceRefresh) _recommendedVideos.clear();
    });

    try {
      // Step 1: Get channels ordered by recent activity (lastPostAt)
      await ref.read(channelsProvider.notifier).loadChannels(forceRefresh: forceRefresh);
      final channelsState = ref.read(channelsProvider);
      
      if (channelsState.error != null) {
        throw Exception(channelsState.error);
      }

      // Step 2: Filter and sort channels by activity
      final activeChannels = channelsState.channels
          .where((channel) => channel.lastPostAt != null && channel.videosCount > 0)
          .toList();

      // Sort by most recent activity first
      activeChannels.sort((a, b) {
        if (a.lastPostAt == null && b.lastPostAt == null) return 0;
        if (a.lastPostAt == null) return 1;
        if (b.lastPostAt == null) return -1;
        return b.lastPostAt!.compareTo(a.lastPostAt!);
      });

      // Step 3: Load videos from top active channels (limit to first 10-15 channels)
      final List<ChannelVideoModel> recommendedVideos = [];
      final int maxChannelsToCheck = 15; // Limit for performance
      final int maxVideosPerChannel = 3; // Get recent videos per channel
      
      for (int i = 0; i < activeChannels.length && i < maxChannelsToCheck; i++) {
        final channel = activeChannels[i];
        
        try {
          // Load recent videos from this channel
          final channelVideos = await ref
              .read(channelVideosProvider.notifier)
              .loadChannelVideos(channel.id);

          // Take only the most recent videos from this channel
          final recentVideos = channelVideos.take(maxVideosPerChannel).toList();
          recommendedVideos.addAll(recentVideos);
          
        } catch (e) {
          debugPrint('Error loading videos for channel ${channel.id}: $e');
          // Continue with other channels
        }
      }

      // Step 4: Sort all collected videos by creation time (most recent first)
      recommendedVideos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Step 5: Limit total recommendations for performance
      final maxTotalVideos = 50; // Reasonable limit for UI performance
      final finalRecommendations = recommendedVideos.take(maxTotalVideos).toList();

      setState(() {
        _recommendedVideos = finalRecommendations;
        _isLoadingRecommendations = false;
      });

    } catch (e) {
      debugPrint('Error loading recommendations: $e');
      setState(() {
        _error = e.toString();
        _isLoadingRecommendations = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.modernTheme.surfaceColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingRecommendations && _recommendedVideos.isEmpty) {
      return _buildLoadingState();
    }

    if (_error != null && _recommendedVideos.isEmpty) {
      return _buildErrorState(_error!);
    }

    if (_recommendedVideos.isEmpty && !_isLoadingRecommendations) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadRecommendedVideos(forceRefresh: true),
      backgroundColor: context.modernTheme.surfaceColor,
      color: context.modernTheme.textColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: GridView.builder(
          controller: _scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.55,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _recommendedVideos.length,
          itemBuilder: (context, index) {
            return _buildVideoThumbnail(_recommendedVideos[index]);
          },
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail(ChannelVideoModel video) {
    return GestureDetector(
      onTap: () => _navigateToVideoFeed(video),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: context.modernTheme.surfaceVariantColor,
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildThumbnailContent(video),
                    ),
                  ),
                  
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            video.caption.isNotEmpty ? video.caption : 'No caption',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          
                          Text(
                            '${_formatCount(video.views)} views',
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
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: video.channelImage.isNotEmpty
                    ? NetworkImage(video.channelImage)
                    : null,
                backgroundColor: context.modernTheme.surfaceVariantColor,
                child: video.channelImage.isEmpty
                    ? Text(
                        video.channelName.isNotEmpty 
                            ? video.channelName[0].toUpperCase()
                            : "U",
                        style: TextStyle(
                          color: context.modernTheme.textColor,
                          fontSize: 10,
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
                        color: context.modernTheme.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _getTimeAgo(video.createdAt.toDate()),
                      style: TextStyle(
                        color: context.modernTheme.textSecondaryColor,
                        fontSize: 10,
                      ),
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

  Widget _buildThumbnailContent(ChannelVideoModel video) {
    if (video.isMultipleImages && video.imageUrls.isNotEmpty) {
      return Image.network(
        video.imageUrls.first,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingThumbnail();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorThumbnail();
        },
      );
    } else if (video.videoUrl.isNotEmpty) {
      return FutureBuilder<Uint8List?>(
        future: _generateVideoThumbnail(video.videoUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingThumbnail();
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          }
          
          if (video.thumbnailUrl.isNotEmpty) {
            return Image.network(
              video.thumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorThumbnail();
              },
            );
          }
          
          return _buildErrorThumbnail();
        },
      );
    } else {
      return _buildErrorThumbnail();
    }
  }

  Future<Uint8List?> _generateVideoThumbnail(String videoUrl) async {
    try {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        quality: 75,
        timeMs: 1000,
      );
      return thumbnail;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  Widget _buildLoadingThumbnail() {
    return Container(
      color: context.modernTheme.surfaceVariantColor,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: context.modernTheme.textColor,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorThumbnail() {
    return Container(
      color: context.modernTheme.surfaceVariantColor,
      child: Center(
        child: Icon(
          Icons.video_library,
          color: context.modernTheme.textSecondaryColor,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: context.modernTheme.textColor),
          const SizedBox(height: 16),
          Text(
            'Loading recommendations...',
            style: TextStyle(color: context.modernTheme.textColor),
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
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: context.modernTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadRecommendedVideos(forceRefresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            color: context.modernTheme.textSecondaryColor,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No recommendations available',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow some channels to see recommendations',
            style: TextStyle(color: context.modernTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  void _navigateToVideoFeed(ChannelVideoModel video) {
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}