// lib/features/status/screens/status_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/status/providers/status_providers.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/theme/status_theme.dart';
import 'package:textgb/features/status/services/status_time_service.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusListScreen extends ConsumerWidget {
  const StatusListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFeedAsync = ref.watch(statusFeedProvider);
    final modernTheme = context.modernTheme;

    return Scaffold(
      backgroundColor: modernTheme.surfaceColor ?? const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Status'),
        backgroundColor: modernTheme.surfaceColor ?? Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
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

    // Separate viewed and unviewed groups
    final unviewedGroups = allGroups.where((g) => g.hasUnviewedStatus).toList();
    final viewedGroups = allGroups.where((g) => !g.hasUnviewedStatus).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(statusFeedProvider.notifier).refresh(),
      color: StatusTheme.primaryBlue,
      child: CustomScrollView(
        slivers: [
          // My Status Section
          SliverToBoxAdapter(
            child: _buildMyStatusSection(context, myStatusGroup),
          ),

          // Recent Updates Header (if there are unviewed statuses)
          if (unviewedGroups.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSectionHeader('Recent updates', context),
            ),

          // Recent Updates List
          if (unviewedGroups.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildStatusListItem(
                  context,
                  unviewedGroups[index],
                  isViewed: false,
                ),
                childCount: unviewedGroups.length,
              ),
            ),

          // Viewed Updates Header (if there are viewed statuses)
          if (viewedGroups.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildSectionHeader('Viewed updates', context),
            ),

          // Viewed Updates List
          if (viewedGroups.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildStatusListItem(
                  context,
                  viewedGroups[index],
                  isViewed: true,
                ),
                childCount: viewedGroups.length,
              ),
            ),

          // Empty state if no statuses at all
          if (myStatusGroup == null && allGroups.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(context),
            ),
        ],
      ),
    );
  }

  Widget _buildMyStatusSection(BuildContext context, StatusGroup? myStatusGroup) {
    final hasStatus = myStatusGroup != null && myStatusGroup.activeStatuses.isNotEmpty;
    final modernTheme = context.modernTheme;

    return Container(
      color: modernTheme.surfaceColor ?? Colors.white,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onMyStatusTap(context, myStatusGroup),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Avatar with ring
                    _buildMyStatusAvatar(myStatusGroup, hasStatus),
                    const SizedBox(width: 12),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: modernTheme.textColor ?? const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasStatus
                                ? 'Tap to view your status'
                                : 'Tap to add status update',
                            style: TextStyle(
                              fontSize: 14,
                              color: modernTheme.textSecondaryColor ?? Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // View count (if has status)
                    if (hasStatus)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: StatusTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 14,
                              color: StatusTheme.primaryBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${myStatusGroup.activeStatuses.fold<int>(0, (sum, s) => sum + s.viewsCount)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: StatusTheme.primaryBlue,
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
          // Divider after My Status section
          Divider(
            height: 8,
            thickness: 8,
            color: modernTheme.backgroundColor ?? const Color(0xFFF5F5F5),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatusAvatar(StatusGroup? myStatusGroup, bool hasStatus) {
    // For placeholder, use a default avatar
    final avatarUrl = myStatusGroup?.userAvatar ?? '';
    final statusCount = myStatusGroup?.activeStatuses.length ?? 0;

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ring (if has status)
          if (hasStatus)
            CustomPaint(
              size: const Size(60, 60),
              painter: _MyStatusRingPainter(
                statusCount: statusCount,
              ),
            ),

          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: avatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : Icon(Icons.person, color: Colors.grey[600], size: 28),
            ),
          ),

          // Add icon (if no status)
          if (!hasStatus)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: StatusTheme.primaryBlue,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusListItem(
    BuildContext context,
    StatusGroup group,
    {required bool isViewed}
  ) {
    final statusCount = group.activeStatuses.length;
    final latestStatus = group.latestStatus;
    final modernTheme = context.modernTheme;

    if (latestStatus == null) return const SizedBox.shrink();

    return Container(
      color: modernTheme.surfaceColor ?? Colors.white,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onStatusTap(context, group),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Avatar with ring
                    _buildStatusAvatar(group, isViewed),
                    const SizedBox(width: 12),

                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.userName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isViewed
                                ? modernTheme.textSecondaryColor ?? Colors.grey[600]
                                : modernTheme.textColor ?? const Color(0xFF1F2937),
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
            ),
          ),
          // Divider between items (WhatsApp-style)
          Padding(
            padding: const EdgeInsets.only(left: 88),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: modernTheme.dividerColor ?? Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAvatar(StatusGroup group, bool isViewed) {
    final statusCount = group.activeStatuses.length;
    final hasUnviewed = group.hasUnviewedStatus;

    return SizedBox(
      width: 60,
      height: 60,
      child: CustomPaint(
        painter: _StatusListRingPainter(
          statusCount: statusCount,
          hasUnviewed: hasUnviewed && !isViewed,
        ),
        child: Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: group.userAvatar,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    final modernTheme = context.modernTheme;
    return Container(
      color: modernTheme.backgroundColor ?? const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: modernTheme.textSecondaryColor ?? Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: StatusTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 64,
              color: StatusTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No status updates yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share photos, videos and text\nwith your contacts',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push(RoutePaths.createStatus),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Create Status', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: StatusTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
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
            'Failed to load statuses',
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

  // Navigation handlers
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

// Custom painter for "My Status" ring
class _MyStatusRingPainter extends CustomPainter {
  final int statusCount;

  _MyStatusRingPainter({required this.statusCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;

    if (statusCount == 1) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..shader = StatusTheme.myStatusRingGradientShader.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      canvas.drawCircle(center, radius, paint);
    } else {
      _drawSegments(canvas, center, radius);
    }
  }

  void _drawSegments(Canvas canvas, Offset center, double radius) {
    const gapAngle = 0.08;
    final segmentAngle = (2 * 3.14159 - (statusCount * gapAngle)) / statusCount;

    for (int i = 0; i < statusCount; i++) {
      final startAngle = -3.14159 / 2 + (i * (segmentAngle + gapAngle));

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..shader = StatusTheme.myStatusRingGradientShader.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MyStatusRingPainter oldDelegate) =>
      oldDelegate.statusCount != statusCount;
}

// Custom painter for status list item ring
class _StatusListRingPainter extends CustomPainter {
  final int statusCount;
  final bool hasUnviewed;

  _StatusListRingPainter({
    required this.statusCount,
    required this.hasUnviewed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;

    final gradient = hasUnviewed
        ? StatusTheme.unviewedRingGradientShader
        : StatusTheme.viewedRingGradientShader;

    if (statusCount == 1) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      canvas.drawCircle(center, radius, paint);
    } else {
      _drawSegments(canvas, center, radius, gradient);
    }
  }

  void _drawSegments(Canvas canvas, Offset center, double radius, LinearGradient gradient) {
    const gapAngle = 0.08;
    final segmentAngle = (2 * 3.14159 - (statusCount * gapAngle)) / statusCount;

    for (int i = 0; i < statusCount; i++) {
      final startAngle = -3.14159 / 2 + (i * (segmentAngle + gapAngle));

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StatusListRingPainter oldDelegate) =>
      oldDelegate.statusCount != statusCount || oldDelegate.hasUnviewed != hasUnviewed;
}