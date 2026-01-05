// ===============================
// Status Time Service
// Time formatting and expiry management for statuses
// ===============================

import 'package:textgb/features/status/models/status_model.dart';
import 'package:textgb/features/status/models/status_constants.dart';

class StatusTimeService {
  StatusTimeService._();

  // ===============================
  // EXPIRY CALCULATIONS
  // ===============================

  /// Calculate expiry date from creation date
  static DateTime calculateExpiryDate(DateTime createdAt) {
    return createdAt.add(StatusConstants.expiryDuration);
  }

  /// Check if status is expired
  static bool isExpired(StatusModel status) {
    return DateTime.now().isAfter(status.expiresAt);
  }

  /// Get time remaining until expiry
  static Duration timeUntilExpiry(StatusModel status) {
    final now = DateTime.now();
    if (now.isAfter(status.expiresAt)) {
      return Duration.zero;
    }
    return status.expiresAt.difference(now);
  }

  /// Get time since status was created
  static Duration timeSinceCreation(StatusModel status) {
    return DateTime.now().difference(status.createdAt);
  }

  // ===============================
  // FORMATTING
  // ===============================

  /// Format status time for display (e.g., "5 minutes ago", "2 hours ago")
  static String formatStatusTime(DateTime statusTime) {
    final now = DateTime.now();
    final difference = now.difference(statusTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return 'Yesterday';
    }
  }

  /// Format time remaining until expiry (e.g., "5h left", "30m left")
  static String formatTimeRemaining(StatusModel status) {
    final remaining = timeUntilExpiry(status);

    if (remaining == Duration.zero) {
      return 'Expired';
    }

    if (remaining.inHours > 0) {
      return '${remaining.inHours}h left';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m left';
    } else {
      return '${remaining.inSeconds}s left';
    }
  }

  /// Format exact expiry time (e.g., "Expires at 3:45 PM")
  static String formatExpiryTime(DateTime expiryTime) {
    final hour = expiryTime.hour;
    final minute = expiryTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return 'Expires at $displayHour:$minute $period';
  }

  /// Format timestamp for status ring subtitle
  static String formatRingTime(DateTime statusTime) {
    final difference = DateTime.now().difference(statusTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  /// Format timestamp for status list (WhatsApp-style: "Today, 10:30 AM" or "Yesterday")
  static String formatListTime(DateTime statusTime) {
    final now = DateTime.now();
    final difference = now.difference(statusTime);

    final hour = statusTime.hour;
    final minute = statusTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeStr = '$displayHour:$minute $period';

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24 && statusTime.day == now.day) {
      return 'Today, $timeStr';
    } else if (difference.inDays == 1 ||
        (difference.inHours < 48 && statusTime.day == now.day - 1)) {
      return 'Yesterday, $timeStr';
    } else if (difference.inDays < 7) {
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final weekday = weekdays[statusTime.weekday - 1];
      return '$weekday, $timeStr';
    } else {
      final day = statusTime.day.toString().padLeft(2, '0');
      final month = statusTime.month.toString().padLeft(2, '0');
      final year = statusTime.year;
      return '$day/$month/$year, $timeStr';
    }
  }

  // ===============================
  // FILTERING
  // ===============================

  /// Filter out expired statuses from a list
  static List<StatusModel> filterExpired(List<StatusModel> statuses) {
    return statuses.where((s) => !isExpired(s)).toList();
  }

  /// Filter active statuses (not deleted, not expired)
  static List<StatusModel> filterActive(List<StatusModel> statuses) {
    return statuses.where((s) => s.isActive).toList();
  }

  /// Sort statuses by creation time (newest first)
  static List<StatusModel> sortByNewest(List<StatusModel> statuses) {
    final sorted = List<StatusModel>.from(statuses);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Sort statuses by creation time (oldest first)
  static List<StatusModel> sortByOldest(List<StatusModel> statuses) {
    final sorted = List<StatusModel>.from(statuses);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  // ===============================
  // STATUS GROUP OPERATIONS
  // ===============================

  /// Filter status groups that have active statuses
  static List<StatusGroup> filterActiveGroups(List<StatusGroup> groups) {
    return groups.where((g) => g.activeStatuses.isNotEmpty).toList();
  }

  /// Sort status groups by latest status time (most recent first)
  static List<StatusGroup> sortGroupsByLatest(List<StatusGroup> groups) {
    final sorted = List<StatusGroup>.from(groups);
    sorted.sort((a, b) {
      final aTime = a.latestStatusTime;
      final bTime = b.latestStatusTime;

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  /// Separate groups into viewed and unviewed
  static Map<String, List<StatusGroup>> separateByViewStatus(
      List<StatusGroup> groups) {
    final unviewed = <StatusGroup>[];
    final viewed = <StatusGroup>[];

    for (final group in groups) {
      if (group.hasUnviewedStatus) {
        unviewed.add(group);
      } else {
        viewed.add(group);
      }
    }

    return {
      'unviewed': unviewed,
      'viewed': viewed,
    };
  }

  // ===============================
  // SCHEDULING
  // ===============================

  /// Get next cleanup time (when to remove expired statuses)
  static DateTime getNextCleanupTime() {
    final now = DateTime.now();
    // Clean up every hour at the start of the hour
    return DateTime(now.year, now.month, now.day, now.hour + 1, 0, 0);
  }

  /// Calculate when to schedule next expiry check
  static Duration getNextExpiryCheckDelay(List<StatusModel> statuses) {
    if (statuses.isEmpty) {
      return const Duration(hours: 1); // Default check interval
    }

    // Find the status that will expire soonest
    final activeStatuses = filterActive(statuses);
    if (activeStatuses.isEmpty) {
      return const Duration(hours: 1);
    }

    final soonestExpiry = activeStatuses.reduce((a, b) {
      return a.expiresAt.isBefore(b.expiresAt) ? a : b;
    }).expiresAt;

    final timeUntilExpiry = soonestExpiry.difference(DateTime.now());

    // Add a small buffer to ensure status is actually expired
    return timeUntilExpiry + const Duration(seconds: 5);
  }

  // ===============================
  // VALIDATION
  // ===============================

  /// Check if enough time has passed to create another status
  /// (Prevents spam - optional rate limiting)
  static bool canCreateStatus(List<StatusModel> myStatuses) {
    if (myStatuses.isEmpty) return true;

    // Check if user has reached max statuses
    final activeStatuses = filterActive(myStatuses);
    if (activeStatuses.length >= StatusConstants.maxStatusesPerUser) {
      return false;
    }

    // Optional: Add rate limiting (e.g., max 1 status per minute)
    final latestStatus = sortByNewest(activeStatuses).first;
    final timeSinceLastStatus =
        DateTime.now().difference(latestStatus.createdAt);

    // Allow if more than 30 seconds have passed
    return timeSinceLastStatus.inSeconds >= 30;
  }

  // ===============================
  // DISPLAY HELPERS
  // ===============================

  /// Get a human-readable summary of status timing
  static String getStatusTimingSummary(StatusModel status) {
    final created = formatStatusTime(status.createdAt);
    final remaining = formatTimeRemaining(status);

    return '$created • $remaining';
  }

  /// Check if status is about to expire (less than 1 hour remaining)
  static bool isExpiringsoon(StatusModel status) {
    final remaining = timeUntilExpiry(status);
    return remaining.inHours < 1 && remaining.inMinutes > 0;
  }

  /// Check if status is very new (less than 5 minutes old)
  static bool isVeryNew(StatusModel status) {
    final age = timeSinceCreation(status);
    return age.inMinutes < 5;
  }
}
