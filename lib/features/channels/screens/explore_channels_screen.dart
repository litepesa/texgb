// lib/features/channels/screens/explore_channels_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExploreChannelsScreen extends ConsumerStatefulWidget {
  final bool isInTabView;
  
  const ExploreChannelsScreen({
    Key? key, 
    this.isInTabView = false,
  }) : super(key: key);

  @override
  ConsumerState<ExploreChannelsScreen> createState() => _ExploreChannelsScreenState();
}

class _ExploreChannelsScreenState extends ConsumerState<ExploreChannelsScreen> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  List<ChannelModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExploreChannels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  bool get wantKeepAlive => true;

  Future<void> _loadExploreChannels() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ref.read(channelsProvider.notifier).loadChannels(forceRefresh: true);
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Error loading channels: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _searchChannels(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final channelsState = ref.read(channelsProvider);
      final results = channelsState.channels.where((channel) {
        final queryLower = query.toLowerCase();
        return channel.name.toLowerCase().contains(queryLower) ||
               channel.description.toLowerCase().contains(queryLower) ||
               channel.tags.any((tag) => tag.toLowerCase().contains(queryLower));
      }).toList();
      
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      showSnackBar(context, 'Error searching channels: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToChannelDetail(BuildContext context, ChannelModel channel) {
    Navigator.pushNamed(
      context,
      Constants.channelProfileScreen,
      arguments: channel.id,
    ).then((_) {
      // Refresh the list when returning from detail screen
      _loadExploreChannels();
    });
  }

  void _navigateToCreateChannel() {
    Navigator.pushNamed(context, Constants.createChannelScreen).then((result) {
      if (result == true) {
        _loadExploreChannels();
      }
    });
  }

  void _navigateToMyChannel() {
    Navigator.pushNamed(context, Constants.myChannelScreen);
  }

  List<ChannelModel> _getFollowingChannels() {
    final channelsState = ref.watch(channelsProvider);
    return channelsState.channels.where((channel) => 
        channelsState.followedChannels.contains(channel.id)
    ).toList();
  }

  List<ChannelModel> _getDiscoverChannels() {
    final channelsState = ref.watch(channelsProvider);
    return channelsState.channels.where((channel) => 
        !channelsState.followedChannels.contains(channel.id)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final modernTheme = context.modernTheme;
    final accentColor = modernTheme.primaryColor!;
    final channelsState = ref.watch(channelsProvider);
    
    return Scaffold(
      appBar: widget.isInTabView 
          ? null 
          : AppBar(
              title: Text(
                'Channels',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: modernTheme.textColor,
                ),
              ),
              backgroundColor: modernTheme.backgroundColor,
              elevation: 0,
              actions: [
                if (channelsState.userChannel != null)
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.tv,
                      color: accentColor,
                    ),
                    onPressed: _navigateToMyChannel,
                    tooltip: 'My Channel',
                  )
                else
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.add_circled,
                      color: accentColor,
                    ),
                    onPressed: _navigateToCreateChannel,
                    tooltip: 'Create Channel',
                  ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            _buildSearchBar(modernTheme),
            
            // Tab bar (only show if not searching)
            if (!_isSearching) _buildTabBar(modernTheme),
            
            // Content area
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: accentColor))
                  : _buildContent(modernTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            if (value.isEmpty) {
              _isSearching = false;
              _searchResults = [];
            }
          });
          
          if (value.isNotEmpty) {
            _searchChannels(value);
          }
        },
        decoration: InputDecoration(
          hintText: 'Search channels...',
          hintStyle: TextStyle(
            color: modernTheme.textSecondaryColor,
          ),
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: modernTheme.textSecondaryColor,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    CupertinoIcons.clear,
                    color: modernTheme.textSecondaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchResults = [];
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: modernTheme.surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(
          color: modernTheme.textColor,
        ),
      ),
    );
  }

  Widget _buildTabBar(ModernThemeExtension modernTheme) {
    return Container(
      color: modernTheme.backgroundColor,
      child: TabBar(
        controller: _tabController,
        labelColor: modernTheme.primaryColor,
        unselectedLabelColor: modernTheme.textSecondaryColor,
        indicatorColor: modernTheme.primaryColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.heart_fill, size: 18),
                const SizedBox(width: 8),
                const Text('Following'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.compass, size: 18),
                const SizedBox(width: 8),
                const Text('Discover'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ModernThemeExtension modernTheme) {
    if (_isSearching) {
      return _buildSearchResults(modernTheme);
    } else {
      return _buildTabContent(modernTheme);
    }
  }

  Widget _buildSearchResults(ModernThemeExtension modernTheme) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.search,
              size: 60,
              color: modernTheme.textSecondaryColor!.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No channels found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 16,
                color: modernTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final channel = _searchResults[index];
        return _buildChannelListItem(
          channel: channel,
          onTap: () => _navigateToChannelDetail(context, channel),
        );
      },
    );
  }

  Widget _buildTabContent(ModernThemeExtension modernTheme) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildFollowingTab(modernTheme),
        _buildDiscoverTab(modernTheme),
      ],
    );
  }

  Widget _buildFollowingTab(ModernThemeExtension modernTheme) {
    final followingChannels = _getFollowingChannels();

    if (followingChannels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.heart,
              size: 60,
              color: modernTheme.textSecondaryColor!.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No channels followed yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow channels to see them here',
              style: TextStyle(
                fontSize: 16,
                color: modernTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(1),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Discover Channels'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExploreChannels,
      color: modernTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: followingChannels.length,
        itemBuilder: (context, index) {
          final channel = followingChannels[index];
          return _buildChannelListItem(
            channel: channel,
            onTap: () => _navigateToChannelDetail(context, channel),
          );
        },
      ),
    );
  }

  Widget _buildDiscoverTab(ModernThemeExtension modernTheme) {
    final discoverChannels = _getDiscoverChannels();

    if (discoverChannels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.compass,
              size: 60,
              color: modernTheme.textSecondaryColor!.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No channels available yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to create a channel!',
              style: TextStyle(
                fontSize: 16,
                color: modernTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToCreateChannel,
              icon: const Icon(CupertinoIcons.add),
              label: const Text('Create Channel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: modernTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExploreChannels,
      color: modernTheme.primaryColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              'Popular Channels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
            ),
          ),
          ...discoverChannels.map((channel) => _buildChannelListItem(
            channel: channel,
            onTap: () => _navigateToChannelDetail(context, channel),
          )),
        ],
      ),
    );
  }

  Widget _buildChannelListItem({
    required ChannelModel channel,
    required VoidCallback onTap,
  }) {
    final modernTheme = context.modernTheme;
    final channelsState = ref.watch(channelsProvider);
    final isSubscribed = channelsState.followedChannels.contains(channel.id);
    final isOwnChannel = channelsState.userChannel?.id == channel.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Channel Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                    backgroundImage: channel.profileImage.isNotEmpty
                        ? CachedNetworkImageProvider(channel.profileImage)
                        : null,
                    child: channel.profileImage.isEmpty
                        ? Text(
                            channel.name.isNotEmpty
                                ? channel.name[0].toUpperCase()
                                : "C",
                            style: TextStyle(
                              color: modernTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  if (channel.isVerified)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: modernTheme.surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Channel Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel Name
                    Text(
                      channel.name,
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Description
                    Text(
                      channel.description,
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Stats
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.person_2,
                          color: modernTheme.textSecondaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatCount(channel.followers)} subscribers',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          CupertinoIcons.square_grid_2x2,
                          color: modernTheme.textSecondaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${channel.videosCount} posts',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Subscribe/Subscribed Button
              if (isOwnChannel)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: modernTheme.primaryColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: modernTheme.primaryColor!.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'My Channel',
                    style: TextStyle(
                      color: modernTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () {
                    ref.read(channelsProvider.notifier).toggleFollowChannel(channel.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSubscribed 
                          ? modernTheme.surfaceColor
                          : modernTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSubscribed 
                            ? modernTheme.textSecondaryColor!.withOpacity(0.3)
                            : modernTheme.primaryColor!,
                      ),
                    ),
                    child: Text(
                      isSubscribed ? 'Subscribed' : 'Subscribe',
                      style: TextStyle(
                        color: isSubscribed 
                            ? modernTheme.textSecondaryColor
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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