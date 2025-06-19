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
        channelsState.followedChannels.contains(channel.id) &&
        channel.id != channelsState.userChannel?.id // Exclude user's own channel
    ).toList();
  }

  List<ChannelModel> _getDiscoverChannels() {
    final channelsState = ref.watch(channelsProvider);
    return channelsState.channels.where((channel) => 
        !channelsState.followedChannels.contains(channel.id) &&
        channel.id != channelsState.userChannel?.id // Exclude user's own channel
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
        return _buildDiscoverChannelItem(
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
    final channelsState = ref.watch(channelsProvider);
    final userChannel = channelsState.userChannel;

    return RefreshIndicator(
      onRefresh: _loadExploreChannels,
      color: modernTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User's Own Channel Section
            if (userChannel != null) ...[
              _buildMyChannelSection(modernTheme, userChannel),
              const SizedBox(height: 8),
            ],
            
            // Following Channels Section
            if (followingChannels.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Following',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: modernTheme.textColor,
                  ),
                ),
              ),
              ...followingChannels.map((channel) => _buildFollowingChannelItem(
                channel: channel,
                onTap: () => _navigateToChannelDetail(context, channel),
              )),
            ] else if (userChannel != null) ...[
              // Show message about following channels when user has a channel but follows none
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.heart,
                        size: 48,
                        color: modernTheme.textSecondaryColor!.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No channels followed yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: modernTheme.textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover and follow channels to see them here',
                        style: TextStyle(
                          fontSize: 14,
                          color: modernTheme.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _tabController.animateTo(1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: modernTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Discover Channels'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Create channel prompt if user has no channel and follows none
            if (userChannel == null && followingChannels.isEmpty)
              _buildCreateChannelPrompt(modernTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildMyChannelSection(ModernThemeExtension modernTheme, ChannelModel userChannel) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            modernTheme.primaryColor!.withOpacity(0.1),
            modernTheme.primaryColor!.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: modernTheme.primaryColor!.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.tv_fill,
                  color: modernTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'My Channel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: modernTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          _buildMyChannelCard(modernTheme, userChannel),
        ],
      ),
    );
  }

  Widget _buildMyChannelCard(ModernThemeExtension modernTheme, ChannelModel userChannel) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
        onTap: _navigateToMyChannel,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Channel Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                    backgroundImage: userChannel.profileImage.isNotEmpty
                        ? CachedNetworkImageProvider(userChannel.profileImage)
                        : null,
                    child: userChannel.profileImage.isEmpty
                        ? Text(
                            userChannel.name.isNotEmpty
                                ? userChannel.name[0].toUpperCase()
                                : "C",
                            style: TextStyle(
                              color: modernTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                  if (userChannel.isVerified)
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
                          size: 18,
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
                    Text(
                      userChannel.name,
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      userChannel.description,
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Stats
                    Row(
                      children: [
                        _buildStatChip(
                          modernTheme,
                          CupertinoIcons.person_2,
                          '${_formatCount(userChannel.followers)} followers',
                        ),
                        const SizedBox(width: 12),
                        _buildStatChip(
                          modernTheme,
                          CupertinoIcons.square_grid_2x2,
                          '${userChannel.videosCount} posts',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Manage button
              Icon(
                CupertinoIcons.chevron_right,
                color: modernTheme.textSecondaryColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(ModernThemeExtension modernTheme, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: modernTheme.primaryColor!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: modernTheme.primaryColor,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: modernTheme.primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateChannelPrompt(ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: modernTheme.primaryColor!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.tv,
                size: 48,
                color: modernTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Start Your Channel Journey',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your own channel to share content and connect with your audience',
              style: TextStyle(
                fontSize: 14,
                color: modernTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateChannel,
              icon: const Icon(CupertinoIcons.add),
              label: const Text('Create My Channel'),
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
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: Text(
                'Or explore other channels',
                style: TextStyle(
                  color: modernTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
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
              'No channels to discover',
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
              'Discover Channels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: modernTheme.textColor,
              ),
            ),
          ),
          ...discoverChannels.map((channel) => _buildDiscoverChannelItem(
            channel: channel,
            onTap: () => _navigateToChannelDetail(context, channel),
          )),
        ],
      ),
    );
  }

  // Specialized item for channels in Following tab - no follow button, space for unread counter
  Widget _buildFollowingChannelItem({
    required ChannelModel channel,
    required VoidCallback onTap,
  }) {
    final modernTheme = context.modernTheme;
    // TODO: Get actual unread count from channel messages provider
    final unreadCount = 0; // Placeholder for unread messages count

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
              // Channel Avatar with unread indicator
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
                  // TODO: Show unread indicator when unreadCount > 0
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: modernTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: modernTheme.surfaceColor!,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                    
                    // Show last message preview or description
                    Text(
                      // TODO: Replace with actual last message preview
                      channel.description.isEmpty ? 'No recent activity' : channel.description,
                      style: TextStyle(
                        color: unreadCount > 0 
                            ? modernTheme.textColor // Bold for unread
                            : modernTheme.textSecondaryColor,
                        fontSize: 14,
                        fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Stats and timestamp
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.person_2,
                          color: modernTheme.textSecondaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${_formatCount(channel.followers)} followers',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        // TODO: Add timestamp of last message
                        Text(
                          '2h', // Placeholder timestamp
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
            ],
          ),
        ),
      ),
    );
  }

  // Specialized item for channels in Discover tab - includes follow button
  Widget _buildDiscoverChannelItem({
    required ChannelModel channel,
    required VoidCallback onTap,
  }) {
    final modernTheme = context.modernTheme;
    final channelsState = ref.watch(channelsProvider);
    final isFollowing = channelsState.followedChannels.contains(channel.id);

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
                        Flexible(
                          child: Text(
                            '${_formatCount(channel.followers)} followers',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          CupertinoIcons.square_grid_2x2,
                          color: modernTheme.textSecondaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${channel.videosCount} posts',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Follow Button
              GestureDetector(
                onTap: () {
                  ref.read(channelsProvider.notifier).toggleFollowChannel(channel.id);
                },
                child: Container(
                  constraints: const BoxConstraints(minWidth: 70, maxWidth: 90),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFollowing 
                        ? modernTheme.surfaceColor
                        : modernTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isFollowing 
                          ? modernTheme.textSecondaryColor!.withOpacity(0.3)
                          : modernTheme.primaryColor!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: isFollowing 
                            ? modernTheme.textSecondaryColor
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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

  Widget _buildChannelListItem({
    required ChannelModel channel,
    required VoidCallback onTap,
  }) {
    final modernTheme = context.modernTheme;
    final channelsState = ref.watch(channelsProvider);
    final isSubscribed = channelsState.followedChannels.contains(channel.id);

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
                        Flexible(
                          child: Text(
                            '${_formatCount(channel.followers)} subscribers',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          CupertinoIcons.square_grid_2x2,
                          color: modernTheme.textSecondaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${channel.videosCount} posts',
                            style: TextStyle(
                              color: modernTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Follow Button (only show in discover, not in following list)
              // TODO: Add unread counter here when implementing notifications
              GestureDetector(
                onTap: () {
                  ref.read(channelsProvider.notifier).toggleFollowChannel(channel.id);
                },
                child: Container(
                  constraints: const BoxConstraints(minWidth: 70, maxWidth: 90),
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
                  child: Center(
                    child: Text(
                      isSubscribed ? 'Following' : 'Follow',
                      style: TextStyle(
                        color: isSubscribed 
                            ? modernTheme.textSecondaryColor
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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