// lib/features/channels/screens/recommended_posts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class RecommendedPostsScreen extends ConsumerStatefulWidget {
  const RecommendedPostsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RecommendedPostsScreen> createState() => _RecommendedPostsScreenState();
}

class _RecommendedPostsScreenState extends ConsumerState<RecommendedPostsScreen> {
  final PageController _pageController = PageController(
    viewportFraction: 0.85, // Shows part of adjacent pages
  );
  
  // Cache for recommended channels to avoid reloading
  List<ChannelModel> _recommendedChannels = [];
  bool _isLoadingRecommendations = false;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load recommended channels when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendedChannels();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Load all channels as recommendations
  /// This method gets all available channels and sorts them by activity and followers
  Future<void> _loadRecommendedChannels({bool forceRefresh = false}) async {
    if (_isLoadingRecommendations && !forceRefresh) return;

    setState(() {
      _isLoadingRecommendations = true;
      _error = null;
      if (forceRefresh) _recommendedChannels.clear();
    });

    try {
      // Load all channels
      await ref.read(channelsProvider.notifier).loadChannels(forceRefresh: forceRefresh);
      final channelsState = ref.read(channelsProvider);
      
      if (channelsState.error != null) {
        throw Exception(channelsState.error);
      }

      // Get all active channels
      final allChannels = channelsState.channels
          .where((channel) => channel.isActive)
          .toList();

      // Sort channels by multiple criteria:
      // 1. Featured channels first
      // 2. Then by recent activity (lastPostAt)
      // 3. Then by follower count
      // 4. Finally by verification status
      allChannels.sort((a, b) {
        // Featured channels first
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        
        // Then by recent activity
        if (a.lastPostAt != null && b.lastPostAt != null) {
          final activityComparison = b.lastPostAt!.compareTo(a.lastPostAt!);
          if (activityComparison != 0) return activityComparison;
        } else if (a.lastPostAt != null && b.lastPostAt == null) {
          return -1;
        } else if (a.lastPostAt == null && b.lastPostAt != null) {
          return 1;
        }
        
        // Then by follower count
        final followerComparison = b.followers.compareTo(a.followers);
        if (followerComparison != 0) return followerComparison;
        
        // Finally by verification status
        if (a.isVerified && !b.isVerified) return -1;
        if (!a.isVerified && b.isVerified) return 1;
        
        // Default to creation date
        return b.createdAt.compareTo(a.createdAt);
      });

      setState(() {
        _recommendedChannels = allChannels;
        _isLoadingRecommendations = false;
      });

    } catch (e) {
      debugPrint('Error loading channel recommendations: $e');
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
    if (_isLoadingRecommendations && _recommendedChannels.isEmpty) {
      return _buildLoadingState();
    }

    if (_error != null && _recommendedChannels.isEmpty) {
      return _buildErrorState(_error!);
    }

    if (_recommendedChannels.isEmpty && !_isLoadingRecommendations) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadRecommendedChannels(forceRefresh: true),
      backgroundColor: context.modernTheme.surfaceColor,
      color: context.modernTheme.textColor,
      child: Column(
        children: [
          // Page indicator dots
          if (_recommendedChannels.isNotEmpty) _buildPageIndicator(),
          
          // Main carousel
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: _recommendedChannels.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
                  child: _buildChannelCard(_recommendedChannels[index], index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _recommendedChannels.length > 10 ? 10 : _recommendedChannels.length, // Limit dots to 10
          (index) {
            // For more than 10 items, show relative position
            int displayIndex = _recommendedChannels.length > 10 
                ? (_currentIndex < 5 ? index : (_currentIndex > _recommendedChannels.length - 6 ? index + _recommendedChannels.length - 10 : index + _currentIndex - 4))
                : index;
            
            bool isActive = displayIndex == _currentIndex;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3.0),
              height: 6.0,
              width: isActive ? 20.0 : 6.0,
              decoration: BoxDecoration(
                color: isActive 
                    ? context.modernTheme.textColor 
                    : context.modernTheme.textSecondaryColor?.withOpacity(0.4),
                borderRadius: BorderRadius.circular(3.0),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChannelCard(ChannelModel channel, int index) {
    // Calculate scale based on current page position
    double scale = 1.0;
    if (_pageController.hasClients && _pageController.page != null) {
      scale = 1.0 - ((_pageController.page! - index).abs() * 0.1).clamp(0.0, 0.3);
    }

    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: () => _navigateToChannelProfile(channel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main thumbnail
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: _buildChannelImage(channel),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Channel info outside thumbnail
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: channel.profileImage.isNotEmpty
                        ? CachedNetworkImageProvider(channel.profileImage)
                        : null,
                    backgroundColor: context.modernTheme.surfaceVariantColor,
                    child: channel.profileImage.isEmpty
                        ? Text(
                            channel.name.isNotEmpty 
                                ? channel.name[0].toUpperCase()
                                : "C",
                            style: TextStyle(
                              color: context.modernTheme.textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          channel.name,
                          style: TextStyle(
                            color: context.modernTheme.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatCount(channel.videosCount)} episodes',
                          style: TextStyle(
                            color: context.modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelImage(ChannelModel channel) {
    // Use cover image if available, otherwise use profile image
    final imageUrl = channel.coverImage.isNotEmpty ? channel.coverImage : channel.profileImage;
    
    if (imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => _buildImagePlaceholder(channel),
        errorWidget: (context, url, error) => _buildImagePlaceholder(channel),
      );
    } else {
      return _buildImagePlaceholder(channel);
    }
  }

  Widget _buildImagePlaceholder(ChannelModel channel) {
    return Container(
      color: context.modernTheme.primaryColor?.withOpacity(0.3) ?? Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              channel.name.isNotEmpty ? channel.name[0].toUpperCase() : "C",
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              Icons.video_library,
              color: Colors.white.withOpacity(0.7),
              size: 32,
            ),
          ],
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
            'Discovering channels...',
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
            'Could not load channels',
            style: TextStyle(color: context.modernTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadRecommendedChannels(forceRefresh: true),
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
            'No channels available',
            style: TextStyle(
              color: context.modernTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new channels',
            style: TextStyle(color: context.modernTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  void _navigateToChannelProfile(ChannelModel channel) async {
    try {
      // Load videos from this channel to get the latest one
      final channelVideos = await ref
          .read(channelVideosProvider.notifier)
          .loadChannelVideos(channel.id);
      
      if (channelVideos.isNotEmpty) {
        // Get the latest video (first video in the list)
        final latestVideo = channelVideos.first; // Assuming videos are sorted newest first
        
        Navigator.pushNamed(
          context,
          Constants.channelFeedScreen,
          arguments: latestVideo.id, // Pass the latest video ID
        );
      } else {
        // No videos available, show a message or navigate to profile instead
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No episodes available in this channel'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Error loading videos, show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading channel content'),
          backgroundColor: Colors.red,
        ),
      );
    }
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