// lib/features/channels/screens/channels_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/core/router/app_router.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

/// Channels list screen matching users list screen design
class ChannelsListScreen extends ConsumerStatefulWidget {
  const ChannelsListScreen({super.key});

  @override
  ConsumerState<ChannelsListScreen> createState() => _ChannelsListScreenState();
}

class _ChannelsListScreenState extends ConsumerState<ChannelsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> categories = ['All', 'Following', 'Verified'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<ChannelModel> get filteredChannels {
    final channelsAsync = ref.watch(
      channelsListProvider(
        page: 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      ),
    );

    return channelsAsync.when(
      data: (channels) {
        List<ChannelModel> filteredList;

        switch (_selectedCategory) {
          case 'Following':
            final subscribedAsync = ref.watch(subscribedChannelsProvider);
            filteredList = subscribedAsync.when(
              data: (subscribed) => channels
                  .where((channel) =>
                      subscribed.any((sub) => sub.id == channel.id))
                  .toList(),
              loading: () => [],
              error: (_, __) => [],
            );
            break;
          case 'Verified':
            filteredList = channels.where((channel) => channel.isVerified).toList();
            break;
          default: // 'All'
            filteredList = channels;
            break;
        }

        // Sort: Verified first, then by subscriber count
        filteredList.sort((a, b) {
          if (a.isVerified && !b.isVerified) return -1;
          if (!a.isVerified && b.isVerified) return 1;
          return b.subscriberCount.compareTo(a.subscriberCount);
        });

        return filteredList;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  Future<void> _refreshChannels() async {
    debugPrint('Channels screen: Pull-to-refresh triggered');
    ref.invalidate(channelsListProvider);
    ref.invalidate(subscribedChannelsProvider);
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Following':
        return Icons.favorite;
      case 'Verified':
        return Icons.verified;
      default:
        return Icons.tv;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;

    return Scaffold(
      backgroundColor: theme.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
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
                  hintText: 'Search channels',
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

            // Channels List with integrated filter tabs
            Expanded(
              child: Container(
                color: theme.surfaceColor,
                child: _buildChannelsListWithTabs(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelsListWithTabs() {
    final theme = context.modernTheme;
    final channels = filteredChannels;

    final channelsAsync = ref.watch(
      channelsListProvider(
        page: 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      ),
    );

    if (channelsAsync.isLoading) {
      return _buildLoadingView(theme, 'Loading channels...');
    }

    if (channels.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshChannels,
        color: theme.primaryColor,
        backgroundColor: theme.surfaceColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildCategoryTabs(theme),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: _buildEmptyState(theme),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshChannels,
      color: theme.primaryColor,
      backgroundColor: theme.surfaceColor,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildCategoryTabs(theme),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final channel = channels[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: index == channels.length - 1 ? 16 : 8,
                  ),
                  child: _buildChannelItem(channel),
                );
              },
              childCount: channels.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(ModernThemeExtension theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor!.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor!.withOpacity(0.08),
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
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border(
                          bottom: BorderSide(
                            color: theme.primaryColor!,
                            width: 3,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor!.withOpacity(0.15)
                            : theme.primaryColor!.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: isSelected
                            ? theme.primaryColor
                            : theme.textSecondaryColor,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isSelected
                              ? theme.primaryColor
                              : theme.textSecondaryColor,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                          letterSpacing: 0.1,
                        ),
                        child: Text(
                          category,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingView(ModernThemeExtension theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ModernThemeExtension theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEmptyStateIcon(),
            color: theme.textTertiaryColor,
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            _getEmptyStateTitle(),
            style: TextStyle(
              color: theme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubtitle(),
            style: TextStyle(
              color: theme.textSecondaryColor,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedCategory) {
      case 'Following':
        return Icons.favorite_outline;
      case 'Verified':
        return Icons.verified_outlined;
      default:
        return Icons.tv_outlined;
    }
  }

  String _getEmptyStateTitle() {
    switch (_selectedCategory) {
      case 'Following':
        return 'No Subscribed Channels';
      case 'Verified':
        return 'No Verified Channels';
      default:
        return 'No Channels Available';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedCategory) {
      case 'Following':
        return 'Subscribe to channels to see them here';
      case 'Verified':
        return 'Verified channels will appear here';
      default:
        return _searchQuery.isEmpty
            ? 'Channels will appear here when they are created'
            : 'No channels found matching your search';
    }
  }

  Widget _buildChannelItem(ChannelModel channel) {
    final subscribedAsync = ref.watch(subscribedChannelsProvider);
    final isSubscribed = subscribedAsync.when(
      data: (subscribed) => subscribed.any((sub) => sub.id == channel.id),
      loading: () => false,
      error: (_, __) => false,
    );
    final theme = context.modernTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: channel.isVerified
              ? Colors.blue.withOpacity(0.3)
              : theme.dividerColor!.withOpacity(0.15),
          width: channel.isVerified ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: channel.isVerified
                ? Colors.blue.withOpacity(0.12)
                : theme.primaryColor!.withOpacity(0.08),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/channel/${channel.id}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: channel.isVerified
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  )
                : null,
            child: Row(
              children: [
                // Channel Avatar
                Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: channel.isVerified
                            ? LinearGradient(
                                colors: [
                                  Colors.blue.shade300,
                                  Colors.indigo.shade400
                                ],
                              )
                            : null,
                        border: !channel.isVerified
                            ? Border.all(
                                color: theme.dividerColor!.withOpacity(0.2),
                                width: 1,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: (channel.isVerified
                                    ? Colors.blue
                                    : theme.primaryColor!)
                                .withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: channel.avatarUrl != null &&
                                  channel.avatarUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: channel.avatarUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    decoration: BoxDecoration(
                                      color:
                                          theme.primaryColor!.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.tv,
                                      color: theme.primaryColor,
                                      size: 22,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    decoration: BoxDecoration(
                                      color:
                                          theme.primaryColor!.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        channel.name.isNotEmpty
                                            ? channel.name[0].toUpperCase()
                                            : 'C',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor!.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      channel.name.isNotEmpty
                                          ? channel.name[0].toUpperCase()
                                          : 'C',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // Verified indicator on avatar
                    if (channel.isVerified)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: theme.surfaceColor!, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // Channel Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Channel name with verified badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              channel.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: theme.textColor,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (channel.isVerified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Description
                      if (channel.description.isNotEmpty)
                        Text(
                          channel.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 4),

                      // Stats with Subscribe Button
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatChip(
                              icon: Icons.article_outlined,
                              text: '${channel.postCount} posts',
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _buildStatChip(
                              icon: Icons.people_outline_rounded,
                              text: _formatCount(channel.subscriberCount),
                              theme: theme,
                            ),
                            if (channel.type == ChannelType.premium &&
                                channel.subscriptionPriceCoins != null) ...[
                              const SizedBox(width: 8),
                              _buildStatChip(
                                icon: Icons.monetization_on_outlined,
                                text: '${channel.subscriptionPriceCoins} coins',
                                theme: theme,
                              ),
                            ],
                            const SizedBox(width: 8),
                            // Subscribe Button styled as stat chip
                            Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              child: InkWell(
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  final actionsNotifier =
                                      ref.read(channelActionsProvider.notifier);
                                  if (isSubscribed) {
                                    await actionsNotifier.unsubscribe(channel.id);
                                  } else {
                                    await actionsNotifier.subscribe(channel.id);
                                  }
                                  ref.invalidate(subscribedChannelsProvider);
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSubscribed
                                        ? theme.primaryColor!.withOpacity(0.15)
                                        : theme.primaryColor!.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSubscribed
                                          ? theme.primaryColor!.withOpacity(0.3)
                                          : theme.primaryColor!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSubscribed
                                            ? Icons.check_rounded
                                            : Icons.add_rounded,
                                        size: 10,
                                        color: isSubscribed
                                            ? theme.primaryColor
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        isSubscribed ? 'Subscribed' : 'Subscribe',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSubscribed
                                              ? theme.primaryColor
                                              : Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String text,
    required theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.surfaceVariantColor!.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.dividerColor!.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 10,
            color: theme.textSecondaryColor,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: theme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return '$count followers';
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}K followers';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}M followers';
    }
  }
}
