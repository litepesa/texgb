import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/features/channels/channel_model.dart';
import 'package:textgb/features/channels/channel_provider.dart';
import 'package:textgb/features/channels/screens/channel_detail_screen.dart';
import 'package:textgb/features/channels/widgets/channel_list_item.dart';
import 'package:textgb/features/channels/widgets/channel_search_bar.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';

class ExploreChannelsScreen extends StatefulWidget {
  final bool isInTabView;
  
  const ExploreChannelsScreen({
    Key? key, 
    this.isInTabView = false,
  }) : super(key: key);

  @override
  State<ExploreChannelsScreen> createState() => _ExploreChannelsScreenState();
}

class _ExploreChannelsScreenState extends State<ExploreChannelsScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  List<ChannelModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadExploreChannels();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        await context.read<ChannelProvider>().fetchExploreChannels();
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
      final results = await context.read<ChannelProvider>().searchChannels(query);
      
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
    context.read<ChannelProvider>().setSelectedChannel(channel);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelDetailScreen(channelId: channel.id),
      ),
    ).then((_) {
      // Refresh the list when returning from detail screen
      _loadExploreChannels();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final modernTheme = context.modernTheme;
    final accentColor = modernTheme.primaryColor!;
    
    return Scaffold(
      appBar: widget.isInTabView 
          ? null 
          : AppBar(
              title: Text(
                'Explore Channels',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: modernTheme.textColor,
                ),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            ChannelSearchBar(
              controller: _searchController,
              placeholder: 'Search channels',
              showResults: _isSearching,
              searchQuery: _searchQuery,
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
              onClear: () {
                setState(() {
                  _isSearching = false;
                  _searchResults = [];
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
            
            // Content area
            Expanded(
              child: _isLoading
                ? Center(child: CircularProgressIndicator(color: accentColor))
                : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return _buildSearchResults();
    } else {
      return _buildExploreChannels();
    }
  }

  Widget _buildSearchResults() {
    final modernTheme = context.modernTheme;
    
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
        return ChannelListItem(
          channel: channel,
          onTap: () => _navigateToChannelDetail(context, channel),
        );
      },
    );
  }

  Widget _buildExploreChannels() {
    final channelProvider = context.watch<ChannelProvider>();
    final exploreChannels = channelProvider.exploreChannels;
    final modernTheme = context.modernTheme;
    
    if (exploreChannels.isEmpty) {
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
          ...exploreChannels.map((channel) => ChannelListItem(
            channel: channel,
            onTap: () => _navigateToChannelDetail(context, channel),
          )),
        ],
      ),
    );
  }
}