// lib/shared/utilities/datetime_helper.dart
import 'package:intl/intl.dart';

/// Centralized timestamp handling for the entire chat system
/// This ensures consistent time handling across local storage, server sync, and UI display
/// 
/// KEY PRINCIPLES:
/// 1. ALWAYS store timestamps as UTC milliseconds (int) in database
/// 2. ALWAYS convert to local time for display
/// 3. NEVER mix UTC and local times
/// 4. Use this helper for ALL timestamp operations
class DateTimeHelper {
  // Private constructor to prevent instantiation
  DateTimeHelper._();
  
  // ========================================
  // DATABASE STORAGE (UTC milliseconds)
  // ========================================
  
  /// Convert DateTime to database timestamp (UTC milliseconds since epoch)
  /// This is the ONLY format we store in the database
  static int toDbTimestamp(DateTime dateTime) {
    // Always convert to UTC first, then get milliseconds
    return dateTime.toUtc().millisecondsSinceEpoch;
  }
  
  /// Convert database timestamp to DateTime (local time)
  /// This is used when reading from database for display
  static DateTime fromDbTimestamp(int timestamp) {
    // Create UTC DateTime from milliseconds, then convert to local
    return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true).toLocal();
  }
  
  /// Get current timestamp for database storage
  static int nowDbTimestamp() {
    return DateTime.now().toUtc().millisecondsSinceEpoch;
  }
  
  // ========================================
  // ISO 8601 / RFC 3339 (for server communication)
  // ========================================
  
  /// Convert DateTime to ISO 8601 string (for server API)
  /// Always in UTC format with 'Z' suffix
  static String toIso8601(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }
  
  /// Parse ISO 8601 string to DateTime (local time)
  /// Handles both 'Z' suffix and timezone offsets
  static DateTime fromIso8601(String iso8601String) {
    try {
      // Parse the ISO string (handles UTC 'Z' and timezone offsets)
      final utcDateTime = DateTime.parse(iso8601String);
      
      // If already UTC, just convert to local
      if (utcDateTime.isUtc) {
        return utcDateTime.toLocal();
      }
      
      // If not UTC, ensure it's converted properly
      return utcDateTime.toLocal();
    } catch (e) {
      // Fallback: try parsing with explicit UTC flag
      try {
        final cleanString = iso8601String.replaceAll('Z', '');
        final dateTime = DateTime.parse(cleanString);
        return DateTime.fromMillisecondsSinceEpoch(
          dateTime.millisecondsSinceEpoch,
          isUtc: true,
        ).toLocal();
      } catch (e2) {
        // Last resort: return current time
        // Log this error - it should never happen in production
        print('❌ Failed to parse timestamp: $iso8601String - Error: $e2');
        return DateTime.now();
      }
    }
  }
  
  /// Parse ISO 8601 string to database timestamp
  /// Direct conversion for efficiency
  static int iso8601ToDbTimestamp(String iso8601String) {
    return toDbTimestamp(fromIso8601(iso8601String));
  }
  
  // ========================================
  // DISPLAY FORMATTING
  // ========================================
  
  /// Format timestamp for chat list (relative time)
  /// Examples: "Just now", "5m ago", "2h ago", "Yesterday", "Jan 15"
  static String formatChatListTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);
    
    // Just now (less than 1 minute)
    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    
    // Minutes ago (1-59 minutes)
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    
    // Hours ago (1-23 hours)
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    
    // Yesterday
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final localDay = DateTime(local.year, local.month, local.day);
    if (localDay == yesterday) {
      return 'Yesterday';
    }
    
    // This week (show day name)
    if (difference.inDays < 7) {
      return DateFormat('EEEE').format(local); // Monday, Tuesday, etc.
    }
    
    // This year (show month and day)
    if (local.year == now.year) {
      return DateFormat('MMM d').format(local); // Jan 15
    }
    
    // Other years (show full date)
    return DateFormat('MMM d, yyyy').format(local); // Jan 15, 2024
  }
  
  /// Format timestamp for message bubble
  /// Examples: "10:30 AM", "Yesterday 10:30 AM", "Jan 15, 10:30 AM"
  static String formatMessageTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);
    
    // Today (just show time)
    if (difference.inHours < 24 && local.day == now.day) {
      return DateFormat('h:mm a').format(local); // 10:30 AM
    }
    
    // Yesterday
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final localDay = DateTime(local.year, local.month, local.day);
    if (localDay == yesterday) {
      return 'Yesterday ${DateFormat('h:mm a').format(local)}';
    }
    
    // This year
    if (local.year == now.year) {
      return DateFormat('MMM d, h:mm a').format(local); // Jan 15, 10:30 AM
    }
    
    // Other years
    return DateFormat('MMM d, yyyy h:mm a').format(local); // Jan 15, 2024 10:30 AM
  }
  
  /// Format timestamp for message details/search
  /// Always shows full date and time
  static String formatFullDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(local);
    // Example: Jan 15, 2024 at 10:30 AM
  }
  
  /// Format timestamp for day separator in chat
  /// Examples: "Today", "Yesterday", "January 15, 2024"
  static String formatDaySeparator(DateTime dateTime) {
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final localDay = DateTime(local.year, local.month, local.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (localDay == today) {
      return 'Today';
    }
    
    if (localDay == yesterday) {
      return 'Yesterday';
    }
    
    // This year (no year shown)
    if (local.year == now.year) {
      return DateFormat('MMMM d').format(local); // January 15
    }
    
    // Other years
    return DateFormat('MMMM d, yyyy').format(local); // January 15, 2024
  }
  
  /// Format "last seen" time
  /// Examples: "Online", "Last seen just now", "Last seen 5m ago", "Last seen today at 10:30 AM"
  static String formatLastSeen(DateTime dateTime, {bool isOnline = false}) {
    if (isOnline) {
      return 'Online';
    }
    
    final local = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);
    
    // Just now (less than 1 minute)
    if (difference.inSeconds < 60) {
      return 'Last seen just now';
    }
    
    // Minutes ago (1-59 minutes)
    if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    }
    
    // Hours ago (1-5 hours)
    if (difference.inHours < 6) {
      return 'Last seen ${difference.inHours}h ago';
    }
    
    // Today
    if (difference.inHours < 24 && local.day == now.day) {
      return 'Last seen today at ${DateFormat('h:mm a').format(local)}';
    }
    
    // Yesterday
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final localDay = DateTime(local.year, local.month, local.day);
    if (localDay == yesterday) {
      return 'Last seen yesterday at ${DateFormat('h:mm a').format(local)}';
    }
    
    // This week
    if (difference.inDays < 7) {
      return 'Last seen ${DateFormat('EEEE').format(local)} at ${DateFormat('h:mm a').format(local)}';
    }
    
    // Older
    return 'Last seen ${DateFormat('MMM d').format(local)}';
  }
  
  // ========================================
  // COMPARISON UTILITIES
  // ========================================
  
  /// Check if two timestamps are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    final local1 = date1.toLocal();
    final local2 = date2.toLocal();
    
    return local1.year == local2.year &&
           local1.month == local2.month &&
           local1.day == local2.day;
  }
  
  /// Check if timestamp is today
  static bool isToday(DateTime dateTime) {
    return isSameDay(dateTime, DateTime.now());
  }
  
  /// Check if timestamp is yesterday
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(dateTime, yesterday);
  }
  
  /// Check if timestamp is within last N minutes
  static bool isWithinMinutes(DateTime dateTime, int minutes) {
    final difference = DateTime.now().difference(dateTime);
    return difference.inMinutes <= minutes;
  }
  
  /// Check if user is considered "online" (last seen within 5 minutes)
  static bool isUserOnline(DateTime lastSeen) {
    return isWithinMinutes(lastSeen, 5);
  }
  
  // ========================================
  // SORTING UTILITIES
  // ========================================
  
  /// Compare two timestamps for sorting (newest first)
  static int compareNewestFirst(DateTime a, DateTime b) {
    return b.compareTo(a);
  }
  
  /// Compare two timestamps for sorting (oldest first)
  static int compareOldestFirst(DateTime a, DateTime b) {
    return a.compareTo(b);
  }
  
  // ========================================
  // VALIDATION
  // ========================================
  
  /// Validate if a timestamp is reasonable (not in future, not too old)
  /// Returns true if valid, false otherwise
  static bool isValidTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    
    // Not in the future (with 1 minute tolerance for clock skew)
    if (dateTime.isAfter(now.add(const Duration(minutes: 1)))) {
      return false;
    }
    
    // Not older than 10 years (reasonable for chat history)
    final tenYearsAgo = now.subtract(const Duration(days: 365 * 10));
    if (dateTime.isBefore(tenYearsAgo)) {
      return false;
    }
    
    return true;
  }
  
  /// Validate database timestamp (int)
  static bool isValidDbTimestamp(int timestamp) {
    // Check if timestamp is in reasonable range
    // Not negative, not in far future
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (timestamp < 0) return false;
    if (timestamp > now + 60000) return false; // Not more than 1 minute in future
    
    // Not older than 10 years
    final tenYearsAgo = now - (365 * 10 * 24 * 60 * 60 * 1000);
    if (timestamp < tenYearsAgo) return false;
    
    return true;
  }
  
  // ========================================
  // DEBUG/TESTING
  // ========================================
  
  /// Get human-readable timestamp info for debugging
  static String debugInfo(dynamic timestamp) {
    if (timestamp is int) {
      if (!isValidDbTimestamp(timestamp)) {
        return 'Invalid timestamp: $timestamp';
      }
      final dateTime = fromDbTimestamp(timestamp);
      return 'DB: $timestamp -> Local: ${formatFullDateTime(dateTime)}';
    } else if (timestamp is String) {
      try {
        final dateTime = fromIso8601(timestamp);
        return 'ISO: $timestamp -> Local: ${formatFullDateTime(dateTime)}';
      } catch (e) {
        return 'Invalid ISO string: $timestamp';
      }
    } else if (timestamp is DateTime) {
      return 'DateTime: ${formatFullDateTime(timestamp)} (${toDbTimestamp(timestamp)})';
    } else {
      return 'Unknown type: $timestamp';
    }
  }
  
  // ========================================
  // MIGRATION HELPERS
  // ========================================
  
  /// Convert old string timestamp to new int timestamp
  /// Used for database migration
  static int? migrateStringToInt(String? stringTimestamp) {
    if (stringTimestamp == null || stringTimestamp.isEmpty) {
      return null;
    }
    
    try {
      // Try parsing as ISO 8601
      final dateTime = DateTime.parse(stringTimestamp);
      return toDbTimestamp(dateTime);
    } catch (e) {
      print('⚠️ Failed to migrate timestamp: $stringTimestamp');
      return null;
    }
  }
  
  /// Batch convert timestamps for migration
  static Map<String, int?> batchMigrateTimestamps(Map<String, String?> timestamps) {
    final result = <String, int?>{};
    
    timestamps.forEach((key, value) {
      result[key] = migrateStringToInt(value);
    });
    
    return result;
  }
}

// ========================================
// EXTENSION METHODS (Optional)
// ========================================

extension DateTimeExtensions on DateTime {
  /// Convert to database timestamp
  int toDbTimestamp() => DateTimeHelper.toDbTimestamp(this);
  
  /// Convert to ISO 8601 string
  String toIso8601String() => DateTimeHelper.toIso8601(this);
  
  /// Format for chat list display
  String formatChatListTime() => DateTimeHelper.formatChatListTime(this);
  
  /// Format for message display
  String formatMessageTime() => DateTimeHelper.formatMessageTime(this);
  
  /// Check if is today
  bool get isToday => DateTimeHelper.isToday(this);
  
  /// Check if is yesterday
  bool get isYesterday => DateTimeHelper.isYesterday(this);
}

extension IntTimestampExtensions on int {
  /// Convert database timestamp to DateTime
  DateTime fromDbTimestamp() => DateTimeHelper.fromDbTimestamp(this);
  
  /// Validate as database timestamp
  bool get isValidDbTimestamp => DateTimeHelper.isValidDbTimestamp(this);
}