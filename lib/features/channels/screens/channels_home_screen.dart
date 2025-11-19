// lib/features/channels/screens/channels_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/core/router/app_router.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/widgets/channel_card.dart';
import 'package:textgb/features/channels/theme/channels_theme.dart';

/// Main channels discovery/home screen with tabs - Facebook-quality UI
class ChannelsHomeScreen extends ConsumerStatefulWidget {
  const ChannelsHomeScreen({super.key});

  @override
  ConsumerState<ChannelsHomeScreen> createState() => _ChannelsHomeScreenState();
}

class _ChannelsHomeScreenState extends ConsumerState<ChannelsHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update tab icons
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChannelsTheme.screenBackground,
      body: Column(
        children: [
          // Search bar with Facebook-quality design
          Container(
            padding: const EdgeInsets.fromLTRB(
              ChannelsTheme.spacingL,
              ChannelsTheme.spacingM,
              ChannelsTheme.spacingL,
              ChannelsTheme.spacingM,
            ),
            decoration: BoxDecoration(
              color: ChannelsTheme.white,
              border: Border(
                bottom: BorderSide(
                  color: ChannelsTheme.divider,
                  width: 1,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: ChannelsTheme.bodyLarge,
              decoration: ChannelsTheme.inputDecoration(
                hintText: 'Search channels',
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: ChannelsTheme.textTertiary,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          CupertinoIcons.clear_circled_solid,
                          color: ChannelsTheme.textTertiary,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Tabs with Facebook-quality design
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: ChannelsTheme.spacingL,
              vertical: ChannelsTheme.spacingM,
            ),
            decoration: BoxDecoration(
              color: ChannelsTheme.white,
              borderRadius: BorderRadius.circular(ChannelsTheme.cardRadius),
              boxShadow: ChannelsTheme.cardShadow,
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: ChannelsTheme.facebookBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ChannelsTheme.buttonRadius),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: ChannelsTheme.facebookBlue,
              unselectedLabelColor: ChannelsTheme.textSecondary,
              labelStyle: ChannelsTheme.buttonText.copyWith(
                fontSize: 13,
              ),
              unselectedLabelStyle: ChannelsTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.explore_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: ChannelsTheme.spacingXs),
                      const Text('Discovery'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 18,
                      ),
                      const SizedBox(width: ChannelsTheme.spacingXs),
                      const Text('Trending'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.bell_fill,
                        size: 18,
                      ),
                      const SizedBox(width: ChannelsTheme.spacingXs),
                      const Text('Subscribed'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoveryTab(),
                _buildTrendingTab(),
                _buildSubscribedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Discovery tab - all channels with filters
  Widget _buildDiscoveryTab() {
    final channelsAsync = ref.watch(
      channelsListProvider(
        page: 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      ),
    );

    return channelsAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return _buildEmptyState(
            icon: Icons.explore_outlined,
            title: _searchQuery.isEmpty
                ? 'No channels yet'
                : 'No channels found',
            subtitle: _searchQuery.isEmpty
                ? 'Be the first to create a channel'
                : 'Try a different search term',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(channelsListProvider);
          },
          color: ChannelsTheme.facebookBlue,
          backgroundColor: ChannelsTheme.white,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: ChannelsTheme.spacingS,
              bottom: 80,
            ),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return ChannelCard(
                channel: channel,
                onTap: () => _navigateToChannelDetail(channel.id),
                showSubscribeButton: true,
              );
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: ChannelsTheme.facebookBlue,
          strokeWidth: 3,
        ),
      ),
      error: (error, stack) => _buildErrorState(
        error: error.toString(),
        onRetry: () {
          ref.invalidate(channelsListProvider);
        },
      ),
    );
  }

  // Trending tab - trending channels
  Widget _buildTrendingTab() {
    final trendingAsync = ref.watch(trendingChannelsProvider);

    return trendingAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return _buildEmptyState(
            icon: Icons.trending_up,
            title: 'No trending channels',
            subtitle: 'Check back later for trending content',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(trendingChannelsProvider);
          },
          color: ChannelsTheme.facebookBlue,
          backgroundColor: ChannelsTheme.white,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: ChannelsTheme.spacingS,
              bottom: 80,
            ),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return ChannelCard(
                channel: channel,
                onTap: () => _navigateToChannelDetail(channel.id),
                showSubscribeButton: true,
              );
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: ChannelsTheme.facebookBlue,
          strokeWidth: 3,
        ),
      ),
      error: (error, stack) => _buildErrorState(
        error: error.toString(),
        onRetry: () {
          ref.invalidate(trendingChannelsProvider);
        },
      ),
    );
  }

  // Subscribed tab - user's subscribed channels
  Widget _buildSubscribedTab() {
    final subscribedAsync = ref.watch(subscribedChannelsProvider);

    return subscribedAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return _buildEmptyState(
            icon: CupertinoIcons.bell,
            title: 'No subscriptions yet',
            subtitle: 'Subscribe to channels to see them here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(subscribedChannelsProvider);
          },
          color: ChannelsTheme.facebookBlue,
          backgroundColor: ChannelsTheme.white,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: ChannelsTheme.spacingS,
              bottom: 80,
            ),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return ChannelCard(
                channel: channel,
                onTap: () => _navigateToChannelDetail(channel.id),
                showSubscribeButton: false, // Already subscribed
              );
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: ChannelsTheme.facebookBlue,
          strokeWidth: 3,
        ),
      ),
      error: (error, stack) => _buildErrorState(
        error: error.toString(),
        onRetry: () {
          ref.invalidate(subscribedChannelsProvider);
        },
      ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ChannelsTheme.spacingXxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(ChannelsTheme.spacingXl),
              decoration: BoxDecoration(
                color: ChannelsTheme.hoverColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: ChannelsTheme.textTertiary,
              ),
            ),
            const SizedBox(height: ChannelsTheme.spacingXl),
            Text(
              title,
              style: ChannelsTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ChannelsTheme.spacingS),
            Text(
              subtitle,
              style: ChannelsTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Error state widget
  Widget _buildErrorState({
    required String error,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ChannelsTheme.spacingXxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(ChannelsTheme.spacingXl),
              decoration: BoxDecoration(
                color: ChannelsTheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: ChannelsTheme.error,
              ),
            ),
            const SizedBox(height: ChannelsTheme.spacingXl),
            Text(
              'Something went wrong',
              style: ChannelsTheme.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ChannelsTheme.spacingS),
            Text(
              error,
              style: ChannelsTheme.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: ChannelsTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ChannelsTheme.primaryButtonStyle.copyWith(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(
                    horizontal: ChannelsTheme.spacingXl,
                    vertical: ChannelsTheme.spacingM,
                  ),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToChannelDetail(String channelId) {
    context.goToChannelDetail(channelId);
  }
}
