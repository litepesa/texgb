import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/channel_provider.dart';
import 'package:textgb/features/channels/widgets/channel_list_item.dart';
import 'package:textgb/features/channels/screens/channel_detail_screen.dart';
import 'package:textgb/features/channels/widgets/channel_search_bar.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';


class MyChannelsScreen extends StatefulWidget {
  const MyChannelsScreen({Key? key}) : super(key: key);

  @override
  State<MyChannelsScreen> createState() => _MyChannelsScreenState();
}

class _MyChannelsScreenState extends State<MyChannelsScreen> with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Keep the state when switching between tabs
  @override
  bool get wantKeepAlive => true;

  Future<void> _loadChannels() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userId = context.read<AuthenticationProvider>().userModel!.uid;
        await context.read<ChannelProvider>().fetchSubscribedChannels(userId: userId);
      } catch (e) {
        if (mounted) {
          // Handle error
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final modernTheme = context.modernTheme;
    final accentColor = modernTheme.primaryColor!;
    
    return SafeArea(
      child: Column(
        children: [
          // Search bar component
          ChannelSearchBar(
            controller: _searchController,
            placeholder: 'Search subscribed channels',
            showResults: _isSearching,
            searchQuery: _searchQuery,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _isSearching = value.isNotEmpty;
              });
            },
            onClear: () {
              setState(() {
                _searchQuery = '';
                _isSearching = false;
                _searchController.clear();
              });
            },
          ),

          // Channels list
          Expanded(
            child: Consumer<ChannelProvider>(
              builder: (context, channelProvider, _) {
                if (channelProvider.isLoading || _isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final subscribedChannels = channelProvider.subscribedChannels;
                
                // Filter channels based on search query
                final filteredChannels = _searchQuery.isEmpty 
                    ? subscribedChannels 
                    : subscribedChannels.where((channel) => 
                        channel.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        channel.description.toLowerCase().contains(_searchQuery.toLowerCase())
                      ).toList();
                
                if (filteredChannels.isEmpty) {
                  return _buildEmptyState(context);
                }

                return RefreshIndicator(
                  onRefresh: _loadChannels,
                  color: accentColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filteredChannels.length,
                    itemBuilder: (context, index) {
                      final channel = filteredChannels[index];
                      return ChannelListItem(
                        channel: channel,
                        onTap: () {
                          // Navigate to channel detail screen
                          channelProvider.setSelectedChannel(channel);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChannelDetailScreen(channelId: channel.id),
                            ),
                          ).then((_) {
                            // Refresh the list when returning from detail screen
                            _loadChannels();
                          });
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.rss_feed : Icons.search_off,
            size: 64,
            color: modernTheme.textSecondaryColor!.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? 'No subscribed channels' 
                : 'No matches found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: modernTheme.textSecondaryColor ?? Colors.grey,
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Try a different search term',
                style: TextStyle(
                  fontSize: 14,
                  color: modernTheme.textSecondaryColor ?? Colors.grey,
                ),
              ),
            ),
          if (_searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'Go to Explore to find channels',
                style: TextStyle(
                  fontSize: 14,
                  color: modernTheme.textSecondaryColor ?? Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}