// lib/features/status/screens/status_list_screen.dart
// WhatsApp-style Updates Tab (Status + Channels combined)
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/status/providers/status_providers.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/theme/status_theme.dart';
import 'package:textgb/features/status/services/status_time_service.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/core/router/app_router.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusListScreen extends ConsumerStatefulWidget {
  const StatusListScreen({super.key});

  @override
  ConsumerState<StatusListScreen> createState() => _StatusListScreenState();
}

class _StatusListScreenState extends ConsumerState<StatusListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _channelsTabController;
  int _selectedChannelTab = 0; // 0: All, 1: Unread, 2: My channels

  @override
  void initState() {
    super.initState();
    _channelsTabController = TabController(length: 3, vsync: this);
    _channelsTabController.addListener(() {
      setState(() {
        _selectedChannelTab = _channelsTabController.index;
      });
    });
  }

  @override
  void dispose() {
    _channelsTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusFeedAsync = ref.watch(statusFeedProvider);
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor ?? const Color(0xFFF5F5F5),
      body: statusFeedAsync.when(
        data: (state) => _buildUpdatesTab(context, ref, state, modernTheme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildUpdatesTab(
    BuildContext context,
    WidgetRef ref,
    StatusFeedState state,
    dynamic modernTheme,
  ) {
    final myStatusGroup = state.myStatusGroup;
    final allGroups = state.activeGroups;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(statusFeedProvider.notifier).refresh();
        ref.invalidate(subscribedChannelsProvider);
      },
      color: StatusTheme.primaryBlue,
      child: CustomScrollView(
        slivers: [
          // ==========================================
          // STATUS SECTION (with thumbnail cards)
          // ==========================================
          SliverToBoxAdapter(
            child: Container(
              color: modernTheme.surfaceColor ?? Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: modernTheme.textColor ?? Colors.black,
                      ),
                    ),
                  ),
                  
                  // My Status Card
                  _buildMyStatusCard(context, myStatusGroup, modernTheme),
                  
                  // Other Status Cards
                  if (allGroups.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...allGroups.take(5).map((group) => 
                      _buildStatusCard(context, group, modernTheme)
                    ),
                  ],
                  
                  // View All Status button (if more than 5)
                  if (allGroups.length > 5)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextButton(
                        onPressed: () {
                          // TODO: Navigate to full status list
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: StatusTheme.primaryBlue,
                        ),
                        child: const Text('View all'),
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Divider
          SliverToBoxAdapter(
            child: Container(
              height: 8,
              color: modernTheme.backgroundColor ?? const Color(0xFFF5F5F5),
            ),
          ),

          // ==========================================
          // CHANNELS SECTION
          // ==========================================
          SliverToBoxAdapter(
            child: Container(
              color: modernTheme.surfaceColor ?? Colors.white,
              child: Column(
                children: [
                  // Channels header with Explore button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                    child: Row(
                      children: [
                        Text(
                          'Channels',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: modernTheme.textColor ?? Colors.black,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            // Navigate to channels explore screen
                            context.push(RoutePaths.channelsHome);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: StatusTheme.primaryBlue,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Explore'),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: StatusTheme.primaryBlue,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 40,
                    decoration: BoxDecoration(
                      color: modernTheme.surfaceVariantColor ?? Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      controller: _channelsTabController,
                      indicator: BoxDecoration(
                        color: StatusTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: StatusTheme.primaryBlue,
                      unselectedLabelColor: modernTheme.textSecondaryColor ?? Colors.grey,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'All'),
                        Tab(text: 'Unread'),
                        Tab(text: 'My channels'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Channels list based on selected tab
          _buildChannelsList(modernTheme),
        ],
      ),
    );
  }

  // ==========================================
  // MY STATUS CARD (WhatsApp style with thumbnail)
  // ==========================================
  Widget _buildMyStatusCard(
    BuildContext context,
    StatusGroup? myStatusGroup,
    dynamic modernTheme,
  ) {
    final hasStatus = myStatusGroup != null && myStatusGroup.activeStatuses.isNotEmpty;
    final latestStatus = hasStatus ? myStatusGroup.latestStatus : null;

    return InkWell(
      onTap: () => _onMyStatusTap(context, myStatusGroup),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: modernTheme.dividerColor ?? Colors.grey[300]!,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail or placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: hasStatus ? null : Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: hasStatus && latestStatus != null
                  ? _buildStatusThumbnail(latestStatus)
                  : Center(
                      child: Icon(
                        Icons.add_circle_outline,
                        size: 32,
                        color: StatusTheme.primaryBlue,
                      ),
                    ),
            ),

            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'My status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: modernTheme.textColor ?? Colors.black,
                          ),
                        ),
                        if (hasStatus) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: StatusTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  size: 12,
                                  color: StatusTheme.primaryBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${myStatusGroup!.activeStatuses.fold<int>(0, (sum, s) => sum + s.viewsCount)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: StatusTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasStatus
                          ? StatusTimeService.formatListTime(latestStatus!.createdAt)
                          : 'Tap to add status update',
                      style: TextStyle(
                        fontSize: 13,
                        color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STATUS CARD (WhatsApp style with thumbnail)
  // ==========================================
  Widget _buildStatusCard(
    BuildContext context,
    StatusGroup group,
    dynamic modernTheme,
  ) {
    final latestStatus = group.latestStatus;
    if (latestStatus == null) return const SizedBox.shrink();

    final hasUnviewed = group.hasUnviewedStatus;

    return InkWell(
      onTap: () => _onStatusTap(context, group),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasUnviewed
                ? StatusTheme.primaryBlue
                : (modernTheme.dividerColor ?? Colors.grey[300]!),
            width: hasUnviewed ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: _buildStatusThumbnail(latestStatus),
            ),

            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: hasUnviewed
                            ? (modernTheme.textColor ?? Colors.black)
                            : (modernTheme.textSecondaryColor ?? Colors.grey[600]),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      StatusTimeService.formatListTime(latestStatus.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status count badge
            if (group.activeStatuses.length > 1)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: StatusTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${group.activeStatuses.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: StatusTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STATUS THUMBNAIL BUILDER
  // ==========================================
  Widget _buildStatusThumbnail(StatusModel status) {
    if (status.mediaType.isImage && status.mediaUrl != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
        child: CachedNetworkImage(
          imageUrl: status.mediaUrl!,
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          ),
        ),
      );
    } else if (status.mediaType.isVideo && status.mediaUrl != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Container(
              color: Colors.black,
              width: 80,
              height: 80,
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Text status
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: status.textBackground != null
              ? StatusTheme.getTextBackgroundGradient(status.textBackground!.colors)
              : const LinearGradient(
                  colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
                ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              status.content ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  // ==========================================
  // CHANNELS LIST
  // ==========================================
  Widget _buildChannelsList(dynamic modernTheme) {
    switch (_selectedChannelTab) {
      case 0: // All
        return _buildAllChannels(modernTheme);
      case 1: // Unread
        return _buildUnreadChannels(modernTheme);
      case 2: // My channels
        return _buildMyChannels(modernTheme);
      default:
        return _buildAllChannels(modernTheme);
    }
  }

  Widget _buildAllChannels(dynamic modernTheme) {
    final subscribedAsync = ref.watch(subscribedChannelsProvider);

    return subscribedAsync.when(
      data: (channels) {
        if (channels.isEmpty) {
          return SliverToBoxAdapter(
            child: _buildEmptyChannelsState(
              'No channels yet',
              'Tap Explore to find channels',
              modernTheme,
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final channel = channels[index];
              return _buildChannelListItem(channel, modernTheme);
            },
            childCount: channels.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading channels',
            style: TextStyle(color: modernTheme.textSecondaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadChannels(dynamic modernTheme) {
    // TODO: Implement filtering by unread
    return _buildAllChannels(modernTheme);
  }

  Widget _buildMyChannels(dynamic modernTheme) {
    // TODO: Implement filtering by user's own channels
    return _buildAllChannels(modernTheme);
  }

  Widget _buildChannelListItem(ChannelModel channel, dynamic modernTheme) {
    return InkWell(
      onTap: () => context.goToChannelDetail(channel.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor ?? Colors.white,
          border: Border(
            bottom: BorderSide(
              color: modernTheme.dividerColor ?? Colors.grey[300]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Channel avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                image: channel.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(channel.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: channel.avatarUrl == null
                  ? Icon(
                      CupertinoIcons.tv_circle_fill,
                      size: 28,
                      color: Colors.grey[600],
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Channel info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          channel.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: modernTheme.textColor ?? Colors.black,
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
                  Text(
                    channel.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Time and unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Now', // TODO: Get actual time from latest post
                  style: TextStyle(
                    fontSize: 12,
                    color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                // Unread badge (example)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: StatusTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChannelsState(
    String title,
    String subtitle,
    dynamic modernTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.tv_circle,
            size: 64,
            color: modernTheme.textTertiaryColor ?? Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: modernTheme.textColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: modernTheme.textSecondaryColor ?? Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load updates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // NAVIGATION
  // ==========================================
  void _onMyStatusTap(BuildContext context, StatusGroup? myStatusGroup) {
    if (myStatusGroup == null || myStatusGroup.activeStatuses.isEmpty) {
      // No status, navigate to create
      context.push(RoutePaths.createStatus);
    } else {
      // View my status
      context.push(
        RoutePaths.statusViewer,
        extra: {
          'group': myStatusGroup,
          'initialIndex': 0,
        },
      );
    }
  }

  void _onStatusTap(BuildContext context, StatusGroup group) {
    context.push(
      RoutePaths.statusViewer,
      extra: {
        'group': group,
        'initialIndex': 0,
      },
    );
  }
}