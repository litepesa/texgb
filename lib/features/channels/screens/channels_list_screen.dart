// lib/features/channels/screens/channels_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/providers/channel_videos_provider.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class ChannelsListScreen extends ConsumerStatefulWidget {
  const ChannelsListScreen({super.key});

  @override
  ConsumerState<ChannelsListScreen> createState() => _ChannelsListScreenState();
}

class _ChannelsListScreenState extends ConsumerState<ChannelsListScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';
  
  final List<String> categories = [
    'All',
    'Following',
    'Shopping',
  ];

  @override
  void initState() {
    super.initState();
    // Load channels when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(channelsProvider.notifier).loadChannels();
    });
  }

  List<ChannelModel> get filteredChannels {
    final channelsState = ref.watch(channelsProvider);
    final followedChannels = channelsState.followedChannels;
    final userChannel = channelsState.userChannel;
    List<ChannelModel> channels;
    
    switch (_selectedCategory) {
      case 'Following':
        channels = channelsState.channels
            .where((channel) => followedChannels.contains(channel.id))
            .toList();
        break;
      case 'Shopping':
        // For now, return empty list since this feature is not active yet
        channels = [];
        break;
      default: // 'All'
        channels = channelsState.channels;
        break;
    }

    // Always filter out user's own channel
    if (userChannel != null) {
      channels.removeWhere((channel) => channel.id == userChannel.id);
    }
    
    return channels;
  }

  Future<void> _navigateToChannelFeed(ChannelModel channel) async {
    try {
      // Load channel videos to get the latest video
      final videos = await ref.read(channelVideosProvider.notifier).loadChannelVideos(channel.id);
      
      if (videos.isNotEmpty) {
        // Navigate to channel feed with the first/latest video
        Navigator.pushNamed(
          context,
          Constants.channelFeedScreen,
          arguments: videos.first.id,
        );
      } else {
        // No videos available, show a message or navigate to channel profile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This channel has no videos yet'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate to channel profile instead
        Navigator.pushNamed(
          context,
          Constants.channelProfileScreen,
          arguments: channel.id,
        );
      }
    } catch (e) {
      // Error loading videos, navigate to channel profile
      Navigator.pushNamed(
        context,
        Constants.channelProfileScreen,
        arguments: channel.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelsState = ref.watch(channelsProvider);
    final theme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: Column(
        children: [
          // Category filter tabs (WhatsApp-style)
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
            ),
            child: SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;
                  final isActive = category != 'Shopping'; // Only All and Following are active
                  return _buildCategoryTab(category, isSelected, isActive);
                },
              ),
            ),
          ),

          // Featured channels indicator
          if (filteredChannels.any((channel) => channel.isFeatured) && _selectedCategory == 'All')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.blue[600],
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${filteredChannels.where((channel) => channel.isFeatured).length} Featured channels',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Channels list
          Expanded(
            child: _buildChannelsList(channelsState),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsList(ChannelsState channelsState) {
    final theme = context.modernTheme;
    
    if (channelsState.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor,
        ),
      );
    }

    if (channelsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.textTertiaryColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading channels',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              channelsState.error!,
              style: TextStyle(
                color: theme.textTertiaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(channelsProvider.notifier).loadChannels(forceRefresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final channels = filteredChannels;

    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedCategory == 'Following' 
                ? Icons.favorite_outline 
                : _selectedCategory == 'Shopping'
                  ? Icons.shopping_bag_outlined
                  : Icons.video_library_outlined,
              color: theme.textTertiaryColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'Following' 
                ? 'No followed channels'
                : _selectedCategory == 'Shopping'
                  ? 'Shopping channels coming soon'
                  : 'No channels available',
              style: TextStyle(
                color: theme.textSecondaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory == 'Following'
                ? 'Follow channels to see them here'
                : _selectedCategory == 'Shopping'
                  ? 'Verified shopping channels will appear here'
                  : 'Check back later for new channels',
              style: TextStyle(
                color: theme.textTertiaryColor,
                fontSize: 14,
              ),
            ),
            if (_selectedCategory == 'All') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, Constants.createChannelScreen);
                },
                child: const Text('Create Channel'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(channelsProvider.notifier).loadChannels(forceRefresh: true);
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return _buildChannelListItem(channel);
        },
      ),
    );
  }

  Widget _buildCategoryTab(String category, bool isSelected, bool isActive) {
    final theme = context.modernTheme;
    final modernTheme = context.modernTheme;
    
    return GestureDetector(
      onTap: isActive ? () {
        setState(() {
          _selectedCategory = category;
        });
      } : null,
      child: Container(
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF25D366) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category,
              style: TextStyle(
                color: isActive 
                  ? (isSelected ? modernTheme.primaryColor : theme.textSecondaryColor)
                  : theme.textTertiaryColor,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            // Add verified badge for Shopping tab
            if (category == 'Shopping') ...[
              const SizedBox(width: 4),
              Icon(
                Icons.verified,
                color: isActive 
                  ? (isSelected ? modernTheme.primaryColor : theme.textSecondaryColor)
                  : theme.textTertiaryColor,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChannelListItem(ChannelModel channel) {
    final followedChannels = ref.watch(channelsProvider).followedChannels;
    final isFollowing = followedChannels.contains(channel.id);
    final theme = context.modernTheme;

    return InkWell(
      onTap: () async {
        // Navigate to channel feed for all channels
        await _navigateToChannelFeed(channel);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Channel avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: channel.isFeatured ? Colors.blue : Colors.transparent,
                      width: channel.isFeatured ? 2 : 0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: channel.profileImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: channel.profileImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: theme.surfaceVariantColor,
                              child: Icon(
                                Icons.video_library,
                                color: theme.textTertiaryColor,
                                size: 24,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: theme.surfaceVariantColor,
                              child: Center(
                                child: Text(
                                  channel.name.isNotEmpty ? channel.name[0].toUpperCase() : 'C',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textSecondaryColor,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: theme.surfaceVariantColor,
                            child: Center(
                              child: Text(
                                channel.name.isNotEmpty ? channel.name[0].toUpperCase() : 'C',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textSecondaryColor,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                
                // Featured indicator
                if (channel.isFeatured)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.surfaceColor!, width: 2),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Channel info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Channel name and verification
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          channel.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (channel.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Followers count
                  Text(
                    '${_formatCount(channel.followers)} followers',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Follow button
            GestureDetector(
              onTap: () {
                ref.read(channelsProvider.notifier).toggleFollowChannel(channel.id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isFollowing ? theme.surfaceVariantColor : theme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  border: isFollowing ? Border.all(color: theme.borderColor!) : null,
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: isFollowing ? theme.textSecondaryColor : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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