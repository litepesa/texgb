// ===============================
// Status Ring Widget
// Circular avatar with gradient border (segmented for multiple statuses)
// ===============================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/services/status_time_service.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

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
    final statusCount = statusGroup.activeStatuses.length;
    final modernTheme = context.modernTheme;

    if (latestStatus == null) {
      return const SizedBox.shrink();
    }

    final ringSize = isMyStatus ? 72.0 : 64.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ringSize + 16,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with gradient ring
            SizedBox(
              width: ringSize + (3.0 * 2) + 4,
              height: ringSize + (3.0 * 2) + 4,
              child: CustomPaint(
                painter: _SegmentedRingPainter(
                  statusCount: statusCount,
                  hasUnviewed: hasUnviewed,
                  isMyStatus: isMyStatus,
                  ringWidth: 3.0,
                  primaryColor: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Avatar
                      Container(
                        width: ringSize,
                        height: ringSize,
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
                            imageUrl: statusGroup.userAvatar,
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
                              color: modernTheme.primaryColor ?? Theme.of(context).primaryColor,
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
                ),
              ),
            ),

            const SizedBox(height: 4),

            // User name (truncated)
            SizedBox(
              width: ringSize + 8,
              child: Text(
                isMyStatus ? 'My Status' : statusGroup.userName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),

            // Time stamp
            Text(
              StatusTimeService.formatRingTime(latestStatus.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for segmented status ring
class _SegmentedRingPainter extends CustomPainter {
  final int statusCount;
  final bool hasUnviewed;
  final bool isMyStatus;
  final double ringWidth;
  final Color primaryColor;

  _SegmentedRingPainter({
    required this.statusCount,
    required this.hasUnviewed,
    required this.isMyStatus,
    required this.ringWidth,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (ringWidth / 2);

    // Get ring colors
    final gradient = _getRingGradient();

    // If only one status, draw a complete circle
    if (statusCount == 1) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      canvas.drawCircle(center, radius, paint);
    } else {
      // Multiple statuses - draw segmented ring like WhatsApp
      _drawSegmentedRing(canvas, center, radius, gradient);
    }
  }

  void _drawSegmentedRing(Canvas canvas, Offset center, double radius, LinearGradient gradient) {
    const gapAngle = 0.08; // Small gap between segments (in radians)
    final segmentAngle = (2 * math.pi - (statusCount * gapAngle)) / statusCount;

    for (int i = 0; i < statusCount; i++) {
      final startAngle = -math.pi / 2 + (i * (segmentAngle + gapAngle));
      final sweepAngle = segmentAngle;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      final path = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
        );

      canvas.drawPath(path, paint);
    }
  }

  LinearGradient _getRingGradient() {
    if (!hasUnviewed) {
      // Viewed - gray
      return const LinearGradient(
        colors: [Colors.grey, Colors.grey],
      );
    } else if (isMyStatus) {
      // My status - primary color
      return LinearGradient(
        colors: [primaryColor, primaryColor],
      );
    } else {
      // Unviewed - primary color
      return LinearGradient(
        colors: [primaryColor, primaryColor],
      );
    }
  }

  @override
  bool shouldRepaint(_SegmentedRingPainter oldDelegate) {
    return oldDelegate.statusCount != statusCount ||
        oldDelegate.hasUnviewed != hasUnviewed ||
        oldDelegate.isMyStatus != isMyStatus ||
        oldDelegate.ringWidth != ringWidth ||
        oldDelegate.primaryColor != primaryColor;
  }
}