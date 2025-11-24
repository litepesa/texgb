// lib/features/channels/screens/channels_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/core/router/app_router.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/widgets/channel_card.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

/// Main channels discovery/home screen with tabs
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

  // Helper method to get safe theme with fallback
  ModernThemeExtension _getSafeTheme() {
    if (!mounted) {
      return _getFallbackTheme();
    }
    
    try {
      final extension = Theme.of(context).extension<ModernThemeExtension>();
      return extension ?? _getFallbackTheme();
    } catch (e) {
      debugPrint('Modern theme error: $e');
      return _getFallbackTheme();
    }
  }

  ModernThemeExtension _getFallbackTheme() {
    final isDark = mounted ? Theme.of(context).brightness == Brightness.dark : false;
    
    return ModernThemeExtension(
      primaryColor: const Color(0xFF07C160), // WeChat green
      surfaceColor: isDark ? Colors.grey[900] : Colors.grey[50],
      textColor: isDark ? Colors.white : Colors.black,
      textSecondaryColor: isDark ? Colors.grey[400] : Colors.grey[600],
      dividerColor: isDark ? Colors.grey[800] : Colors.grey[300],
      textTertiaryColor: isDark ? Colors.grey[500] : Colors.grey[400],
      surfaceVariantColor: isDark ? Colors.grey[800] : Colors.grey[100],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getSafeTheme();
    
    return Container(
      color: theme.surfaceColor,
      child: Column(
        children: [
          // Search bar (matching chat list screen style)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: theme.backgroundColor?.withOpacity(0.6),
              border: Border(
                bottom: BorderSide(
                  color: (theme.dividerColor ?? Colors.grey).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: theme.textColor),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: theme.textSecondaryColor),
                prefixIcon: Icon(
                  CupertinoIcons.search,
                  color: theme.textSecondaryColor,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          CupertinoIcons.clear_circled_solid,
                          color: theme.textSecondaryColor,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // Tabs (matching user list screen style)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (theme.dividerColor ?? Colors.grey[300]!).withOpacity(0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  bottom: BorderSide(
                    color: theme.primaryColor ?? const Color(0xFF07C160),
                    width: 3,
                  ),
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: theme.primaryColor ?? const Color(0xFF07C160),
              unselectedLabelColor: theme.textSecondaryColor,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _tabController.index == 0
                              ? (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.15)
                              : (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.explore,
                          size: 14,
                          color: _tabController.index == 0
                              ? theme.primaryColor ?? const Color(0xFF07C160)
                              : theme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'Discovery',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _tabController.index == 1
                              ? (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.15)
                              : (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.trending_up,
                          size: 14,
                          color: _tabController.index == 1
                              ? theme.primaryColor ?? const Color(0xFF07C160)
                              : theme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'Trending',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _tabController.index == 2
                              ? (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.15)
                              : (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          CupertinoIcons.bell_fill,
                          size: 14,
                          color: _tabController.index == 2
                              ? theme.primaryColor ?? const Color(0xFF07C160)
                              : theme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'Subscribed',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
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
                _buildDiscoveryTab(theme),
                _buildTrendingTab(theme),
                _buildSubscribedTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Discovery tab - all channels with filters
  Widget _buildDiscoveryTab(ModernThemeExtension theme) {
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
            theme: theme,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(channelsListProvider);
          },
          color: theme.primaryColor ?? const Color(0xFF07C160),
          backgroundColor: theme.surfaceColor,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80), // FAB clearance
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChannelCard(
                  channel: channel,
                  onTap: () => _navigateToChannelDetail(channel.id),
                  showSubscribeButton: true,
                ),
              );
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor ?? const Color(0xFF07C160),
          strokeWidth: 3,
        ),
      ),
      error: (error, stack) => _buildErrorState(
        error: error.toString(),
        onRetry: () {
          ref.invalidate(channelsListProvider);
        },
        theme: theme,
      ),
    );
  }

  // Trending tab - trending channels
  Widget _buildTrendingTab(ModernThemeExtension theme) {
    final trendingAsync = ref.watch(trendingChannelsProvider);

    return trendingAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return _buildEmptyState(
            icon: Icons.trending_up,
            title: 'No trending channels',
            subtitle: 'Check back later for trending content',
            theme: theme,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(trendingChannelsProvider);
          },
          color: theme.primaryColor ?? const Color(0xFF07C160),
          backgroundColor: theme.surfaceColor,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChannelCard(
                  channel: channel,
                  onTap: () => _navigateToChannelDetail(channel.id),
                  showSubscribeButton: true,
                ),
              );
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor ?? const Color(0xFF07C160),
          strokeWidth: 3,
        ),
      ),
      error: (error, stack) => _buildErrorState(
        error: error.toString(),
        onRetry: () {
          ref.invalidate(trendingChannelsProvider);
        },
        theme: theme,
      ),
    );
  }

  // Subscribed tab - user's subscribed channels
  Widget _buildSubscribedTab(ModernThemeExtension theme) {
    final subscribedAsync = ref.watch(subscribedChannelsProvider);

    return subscribedAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return _buildEmptyState(
            icon: CupertinoIcons.bell,
            title: 'No subscriptions yet',
            subtitle: 'Subscribe to channels to see them here',
            theme: theme,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(subscribedChannelsProvider);
          },
          color: theme.primaryColor ?? const Color(0xFF07C160),
          backgroundColor: theme.surfaceColor,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
            itemCount: channels.length,
            itemBuilder: (context, index) {
              final channel = channels[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChannelCard(
                  channel: channel,
                  onTap: () => _navigateToChannelDetail(channel.id),
                  showSubscribeButton: false, // Already subscribed
                ),
              );
            },
          ),
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor ?? const Color(0xFF07C160),
          strokeWidth: 3,
        ),
      ),
      error: (error, stack) => _buildErrorState(
        error: error.toString(),
        onRetry: () {
          ref.invalidate(subscribedChannelsProvider);
        },
        theme: theme,
      ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ModernThemeExtension theme,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (theme.primaryColor ?? const Color(0xFF07C160)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: theme.textTertiaryColor ?? Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
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
    required ModernThemeExtension theme,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor ?? const Color(0xFF07C160),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
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