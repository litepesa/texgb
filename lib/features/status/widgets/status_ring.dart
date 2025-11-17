// ===============================
// Status Ring Widget
// Single circular avatar with gradient border
// ===============================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/theme/status_theme.dart';
import 'package:textgb/features/status/services/status_time_service.dart';

class StatusRing extends StatelessWidget {
  final StatusGroup statusGroup;
  final VoidCallback onTap;
  final bool isMyStatus;

  const StatusRing({
    super.key,
    required this.statusGroup,
    required this.onTap,
    this.isMyStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnviewed = statusGroup.hasUnviewedStatus;
    final latestStatus = statusGroup.latestStatus;

    if (latestStatus == null) {
      return const SizedBox.shrink();
    }

    final ringSize = isMyStatus
        ? StatusTheme.myStatusAvatarSize
        : StatusTheme.ringAvatarSize;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ringSize + 16,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with gradient ring
            Stack(
              alignment: Alignment.center,
              children: [
                // Gradient ring
                Container(
                  width: ringSize + (StatusTheme.ringBorderWidth * 2),
                  height: ringSize + (StatusTheme.ringBorderWidth * 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: StatusTheme.getRingGradient(
                      isViewed: !hasUnviewed,
                      isMyStatus: isMyStatus,
                    ),
                  ),
                ),

                // Avatar
                Container(
                  width: ringSize,
                  height: ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(statusGroup.userAvatar),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Add icon for my status (if no status exists)
                if (isMyStatus && statusGroup.activeStatuses.isEmpty)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
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
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            // User name (truncated)
            SizedBox(
              width: ringSize + 8,
              child: Text(
                isMyStatus ? 'My Status' : statusGroup.userName,
                style: StatusTheme.ringLabelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            // Time stamp
            if (latestStatus != null)
              Text(
                StatusTimeService.formatRingTime(latestStatus.createdAt),
                style: StatusTheme.ringTimeStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}
