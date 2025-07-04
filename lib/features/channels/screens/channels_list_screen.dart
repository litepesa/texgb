// lib/features/channels/screens/channels_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    'Featured',
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
    
    switch (_selectedCategory) {
      case 'Following':
        return channelsState.channels
            .where((channel) => followedChannels.contains(channel.id))
            .toList();
      case 'Featured':
        return channelsState.channels
            .where((channel) => channel.isFeatured)
            .toList();
      default: // 'All'
        return channelsState.channels;
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelsState = ref.watch(channelsProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Category filter tabs (WhatsApp-style)
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 0.5,
                ),
              ),
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
                  return _buildCategoryTab(category, isSelected);
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
    if (channelsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (channelsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading channels',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              channelsState.error!,
              style: TextStyle(
                color: Colors.grey[500],
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
                : Icons.video_library_outlined,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'Following' 
                ? 'No followed channels'
                : 'No channels available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory == 'Following'
                ? 'Follow channels to see them here'
                : 'Check back later for new channels',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            if (_selectedCategory != 'Following') ...[
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

  Widget _buildCategoryTab(String category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
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
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00A884) : Colors.grey[600],
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChannelListItem(ChannelModel channel) {
    final followedChannels = ref.watch(channelsProvider).followedChannels;
    final isFollowing = followedChannels.contains(channel.id);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          Constants.channelProfileScreen,
          arguments: channel.id,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[100]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Channel avatar
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: channel.isFeatured ? Colors.blue : Colors.transparent,
                      width: channel.isFeatured ? 2 : 0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: channel.profileImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: channel.profileImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.video_library,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Text(
                                  channel.name.isNotEmpty ? channel.name[0].toUpperCase() : 'C',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Text(
                                channel.name.isNotEmpty ? channel.name[0].toUpperCase() : 'C',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
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
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 8,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
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
                  
                  const SizedBox(height: 2),
                  
                  // Description
                  if (channel.description.isNotEmpty)
                    Text(
                      channel.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: 4),
                  
                  // Stats row
                  Row(
                    children: [
                      Text(
                        '${_formatCount(channel.followers)} followers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (channel.videosCount > 0) ...[
                        Text(
                          ' • ${channel.videosCount} videos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isFollowing ? Colors.grey[200] : const Color(0xFF00A884),
                  borderRadius: BorderRadius.circular(16),
                  border: isFollowing ? Border.all(color: Colors.grey[300]!) : null,
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: isFollowing ? Colors.grey[700] : Colors.white,
                    fontSize: 12,
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