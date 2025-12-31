// lib/features/status/screens/status_list_screen.dart
// WhatsApp-style Status List Screen
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/status/providers/status_providers.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/services/status_time_service.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusListScreen extends ConsumerStatefulWidget {
  const StatusListScreen({super.key});

  @override
  ConsumerState<StatusListScreen> createState() => _StatusListScreenState();
}

class _StatusListScreenState extends ConsumerState<StatusListScreen> {
  @override
  Widget build(BuildContext context) {
    final statusFeedAsync = ref.watch(statusFeedProvider);
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor ?? Colors.white,
      body: statusFeedAsync.when(
        data: (state) => _buildStatusList(context, ref, state, modernTheme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error.toString()),
      ),
    );
  }

  Widget _buildStatusList(
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
      },
      color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
      child: CustomScrollView(
        slivers: [
          // Top padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 12),
          ),

          // My Status
          SliverToBoxAdapter(
            child: _buildMyStatusItem(context, myStatusGroup, modernTheme),
          ),

          // Divider
          if (allGroups.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Recent updates',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                  ),
                ),
              ),
            ),

          // Contact Statuses
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final group = allGroups[index];
                return _buildStatusItem(context, group, modernTheme);
              },
              childCount: allGroups.length,
            ),
          ),

          // Empty state if no contacts have status
          if (allGroups.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(modernTheme),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // MY STATUS ITEM (WhatsApp style)
  // ==========================================
  Widget _buildMyStatusItem(
    BuildContext context,
    StatusGroup? myStatusGroup,
    dynamic modernTheme,
  ) {
    final hasStatus = myStatusGroup != null && myStatusGroup.activeStatuses.isNotEmpty;
    final latestStatus = hasStatus ? myStatusGroup.latestStatus : null;

    return InkWell(
      onTap: () => _onMyStatusTap(context, myStatusGroup),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: modernTheme.surfaceColor ?? Colors.white,
        child: Row(
          children: [
            // Avatar with ring and add button
            Stack(
              children: [
                // Avatar with status ring
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: hasStatus
                        ? null
                        : Border.all(
                            color: modernTheme.dividerColor ?? Colors.grey[300]!,
                            width: 2,
                          ),
                  ),
                  child: hasStatus
                      ? CustomPaint(
                          painter: _StatusRingPainter(
                            statuses: myStatusGroup!.activeStatuses,
                            primaryColor: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
                          ),
                          child: _buildAvatar(myStatusGroup.userAvatar, 52),
                        )
                      : _buildAvatar(null, 52),
                ),

                // Add button overlay
                if (!hasStatus)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: modernTheme.surfaceColor ?? Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Info section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: modernTheme.textColor ?? Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasStatus
                        ? StatusTimeService.formatListTime(latestStatus!.createdAt)
                        : 'Tap to add status update',
                    style: TextStyle(
                      fontSize: 14,
                      color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Settings icon (if has status)
            if (hasStatus)
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                  size: 20,
                ),
                onPressed: () => context.push(RoutePaths.myStatusDetail),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STATUS ITEM (WhatsApp style)
  // ==========================================
  Widget _buildStatusItem(
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: modernTheme.surfaceColor ?? Colors.white,
        child: Row(
          children: [
            // Avatar with status ring
            Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(2),
              child: CustomPaint(
                painter: _StatusRingPainter(
                  statuses: group.activeStatuses,
                  primaryColor: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
                ),
                child: _buildAvatar(group.userAvatar, 52),
              ),
            ),

            const SizedBox(width: 12),

            // Info section
            Expanded(
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
                  const SizedBox(height: 2),
                  Text(
                    StatusTimeService.formatListTime(latestStatus.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // AVATAR BUILDER
  // ==========================================
  Widget _buildAvatar(String? avatarUrl, double size) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      // Placeholder avatar when no profile picture
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
        child: Icon(
          Icons.person,
          color: Colors.grey[600],
          size: size * 0.5,
        ),
      );
    }

    // Display user's profile picture
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: Icon(
            Icons.person,
            color: Colors.grey[600],
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================
  Widget _buildEmptyState(dynamic modernTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: modernTheme.textTertiaryColor ?? Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No updates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: modernTheme.textColor ?? Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status updates from your contacts\nwill appear here',
              style: TextStyle(
                fontSize: 14,
                color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            'Failed to load status updates',
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

// ==========================================
// WhatsApp-style Status Ring Painter
// ==========================================
class _StatusRingPainter extends CustomPainter {
  final List<StatusModel> statuses;
  final Color primaryColor;

  _StatusRingPainter({
    required this.statuses,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final ringWidth = 2.5;
    final gap = 0.05; // Gap between segments (in radians)
    final totalStatuses = statuses.length;

    if (totalStatuses == 0) return;

    // Calculate angles for each segment
    final segmentAngle = (2 * 3.14159 - (gap * totalStatuses)) / totalStatuses;

    for (int i = 0; i < totalStatuses; i++) {
      final startAngle = -3.14159 / 2 + (i * (segmentAngle + gap));
      final sweepAngle = segmentAngle;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;

      // Check if this specific status is viewed
      final isViewed = statuses[i].isViewedByMe;
      paint.color = isViewed ? Colors.grey[400]! : primaryColor;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - ringWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StatusRingPainter oldDelegate) {
    // Check if status list or colors changed
    if (oldDelegate.statuses.length != statuses.length) return true;
    if (oldDelegate.primaryColor != primaryColor) return true;

    // Check if any status viewed state changed
    for (int i = 0; i < statuses.length; i++) {
      if (oldDelegate.statuses[i].isViewedByMe != statuses[i].isViewedByMe) {
        return true;
      }
    }

    return false;
  }
}

// Helper function to convert hex color string to Color
Color _hexToColor(String hex) {
  final hexCode = hex.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}
