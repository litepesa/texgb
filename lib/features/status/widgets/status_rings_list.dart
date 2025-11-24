// ===============================
// Status Rings List Widget
// Horizontal scrollable list of status rings
// ===============================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/widgets/status_ring.dart';
import 'package:textgb/features/status/providers/status_providers.dart';
import 'package:textgb/core/router/route_paths.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class StatusRingsList extends ConsumerWidget {
  final bool showMyStatus;

  const StatusRingsList({
    super.key,
    this.showMyStatus = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFeedAsync = ref.watch(statusFeedProvider);

    return statusFeedAsync.when(
      data: (state) => _buildRingsList(context, state),
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildRingsList(BuildContext context, StatusFeedState state) {
    final myStatusGroup = state.myStatusGroup;
    final activeGroups = state.activeGroups;
    final modernTheme = context.modernTheme;

    // If no statuses at all, show empty state
    if (myStatusGroup == null && activeGroups.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      height: 120,
      color: modernTheme.surfaceColor ?? Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        itemCount: (showMyStatus && myStatusGroup != null ? 1 : 0) + activeGroups.length,
        itemBuilder: (context, index) {
          // My status comes first
          if (showMyStatus && myStatusGroup != null && index == 0) {
            return StatusRing(
              statusGroup: myStatusGroup,
              isMyStatus: true,
              onTap: () => _onMyStatusTap(context, myStatusGroup),
            );
          }

          // Other contacts' statuses
          final groupIndex = (showMyStatus && myStatusGroup != null) ? index - 1 : index;
          final group = activeGroups[groupIndex];

          return StatusRing(
            statusGroup: group,
            onTap: () => _onStatusTap(context, group),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final modernTheme = context.modernTheme;
    return Container(
      height: 120,
      color: modernTheme.surfaceColor ?? Colors.white,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final modernTheme = context.modernTheme;
    return Container(
      height: 120,
      color: modernTheme.surfaceColor ?? Colors.white,
      child: Center(
        child: Text(
          'Failed to load statuses',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final modernTheme = context.modernTheme;
    return Container(
      height: 120,
      color: modernTheme.surfaceColor ?? Colors.white,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 32,
              color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              'No statuses yet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _navigateToCreateStatus(context),
              child: Text(
                'Create your first status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // NAVIGATION
  // ===============================

  void _onMyStatusTap(BuildContext context, StatusGroup myStatusGroup) {
    if (myStatusGroup.activeStatuses.isEmpty) {
      // No status exists, navigate to create
      _navigateToCreateStatus(context);
    } else {
      // View my statuses
      _navigateToStatusViewer(context, myStatusGroup, 0);
    }
  }

  void _onStatusTap(BuildContext context, StatusGroup group) {
    _navigateToStatusViewer(context, group, 0);
  }

  void _navigateToCreateStatus(BuildContext context) {
    context.push(RoutePaths.createStatus);
  }

  void _navigateToStatusViewer(
    BuildContext context,
    StatusGroup group,
    int initialIndex,
  ) {
    // Pass group data via extra parameter
    context.push(
      RoutePaths.statusViewer,
      extra: {
        'group': group,
        'initialIndex': initialIndex,
      },
    );
  }
}
