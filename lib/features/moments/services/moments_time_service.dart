// ===============================
// Moments Time Service
// Format timestamps for moments display
// ===============================

import 'package:timeago/timeago.dart' as timeago;

class MomentsTimeService {
  /// Format moment timestamp in WeChat style
  /// - Just now (< 1 min)
  /// - X minutes ago
  /// - X hours ago
  /// - Today HH:mm
  /// - Yesterday HH:mm
  /// - MM-DD (this year)
  /// - YYYY-MM-DD (older)
  static String formatMomentTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // Just now (< 1 minute)
    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    // Within an hour
    if (difference.inHours < 1) {
      return timeago.format(timestamp, locale: 'en_short');
    }

    // Within 24 hours
    if (difference.inHours < 24 && now.day == timestamp.day) {
      return 'Today ${_formatTime(timestamp)}';
    }

    // Yesterday
    if (difference.inHours < 48 && now.day - timestamp.day == 1) {
      return 'Yesterday ${_formatTime(timestamp)}';
    }

    // Within this year
    if (now.year == timestamp.year) {
      return _formatMonthDay(timestamp);
    }

    // Older
    return _formatFullDate(timestamp);
  }

  /// Format detailed timestamp (for comment detail view)
  static String formatDetailedTime(DateTime timestamp) {
    final now = DateTime.now();

    if (now.year == timestamp.year) {
      return '${_formatMonthDay(timestamp)} ${_formatTime(timestamp)}';
    } else {
      return '${_formatFullDate(timestamp)} ${_formatTime(timestamp)}';
    }
  }

  /// Simple relative time (for notifications)
  static String formatRelativeTime(DateTime timestamp) {
    return timeago.format(timestamp, locale: 'en');
  }

  /// Format time only (HH:mm)
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Format month and day (MM-DD)
  static String _formatMonthDay(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$month-$day';
  }

  /// Format full date (YYYY-MM-DD)
  static String _formatFullDate(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Check if timestamp is today
  static bool isToday(DateTime timestamp) {
    final now = DateTime.now();
    return now.year == timestamp.year &&
        now.month == timestamp.month &&
        now.day == timestamp.day;
  }

  /// Check if timestamp is yesterday
  static bool isYesterday(DateTime timestamp) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return yesterday.year == timestamp.year &&
        yesterday.month == timestamp.month &&
        yesterday.day == timestamp.day;
  }

  /// Check if timestamp is within last N days
  static bool isWithinDays(DateTime timestamp, int days) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inDays <= days;
  }
}
