import 'package:intl/intl.dart';

/// Centralized date and time formatting utilities for the InCloud app
class DateUtils {
  // Private constructor to prevent instantiation
  DateUtils._();

  /// Returns current time in UTC for database storage
  /// This ensures consistent UTC timestamps in Supabase
  static DateTime nowInUtc() {
    return DateTime.now().toUtc();
  }

  /// Returns current time in UTC as ISO8601 string for database storage
  /// Use this instead of DateTime.now().toIso8601String()
  static String nowInUtcString() {
    return DateTime.now().toUtc().toIso8601String();
  }

  /// Formats a DateTime to display date and time with AM/PM indicator
  /// Example: "29/9/2025 7:09 AM"
  static String formatOrderDateTime(DateTime dateTime) {
    try {
      // Convert UTC to local timezone (Philippines)
      final localDateTime = dateTime.toLocal();

      // Format: day/month/year hour:minute AM/PM
      final dateFormat = DateFormat('d/M/yyyy h:mm a');
      return dateFormat.format(localDateTime);
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  /// Formats a DateTime to display just the date
  /// Example: "September 29, 2025"
  static String formatDate(DateTime dateTime) {
    try {
      final localDateTime = dateTime.toLocal();
      final dateFormat = DateFormat('MMMM d, yyyy');
      return dateFormat.format(localDateTime);
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  /// Formats a DateTime to display just the time with AM/PM
  /// Example: "7:09 AM"
  static String formatTime(DateTime dateTime) {
    try {
      final localDateTime = dateTime.toLocal();
      final timeFormat = DateFormat('h:mm a');
      return timeFormat.format(localDateTime);
    } catch (e) {
      print('Error formatting time: $e');
      return 'Invalid Time';
    }
  }

  /// Formats a DateTime for detailed view (used in order details)
  /// Example: "September 29, 2025 at 7:09 AM"
  static String formatDetailedDateTime(DateTime dateTime) {
    try {
      final localDateTime = dateTime.toLocal();
      final dateFormat = DateFormat('MMMM d, yyyy');
      final timeFormat = DateFormat('h:mm a');
      return '${dateFormat.format(localDateTime)} at ${timeFormat.format(localDateTime)}';
    } catch (e) {
      print('Error formatting detailed date time: $e');
      return 'Invalid Date Time';
    }
  }

  /// Formats a DateTime for compact display
  /// Example: "Sep 29, 7:09 AM"
  static String formatCompactDateTime(DateTime dateTime) {
    try {
      final localDateTime = dateTime.toLocal();
      final dateFormat = DateFormat('MMM d, h:mm a');
      return dateFormat.format(localDateTime);
    } catch (e) {
      print('Error formatting compact date time: $e');
      return 'Invalid Date Time';
    }
  }

  /// Formats relative time (e.g., "2 hours ago", "Yesterday")
  /// Falls back to absolute time if more than 7 days ago
  static String formatRelativeTime(DateTime dateTime) {
    try {
      final now = DateTime.now();
      final localDateTime = dateTime.toLocal();
      final difference = now.difference(localDateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else {
        // Fall back to absolute date for older items
        return formatOrderDateTime(localDateTime);
      }
    } catch (e) {
      print('Error formatting relative time: $e');
      return formatOrderDateTime(dateTime);
    }
  }

  /// Checks if a date is today
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    final localDateTime = dateTime.toLocal();
    return now.year == localDateTime.year &&
           now.month == localDateTime.month &&
           now.day == localDateTime.day;
  }

  /// Checks if a date is yesterday
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final localDateTime = dateTime.toLocal();
    return yesterday.year == localDateTime.year &&
           yesterday.month == localDateTime.month &&
           yesterday.day == localDateTime.day;
  }
}