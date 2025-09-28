import 'package:flutter_test/flutter_test.dart';
import 'package:incloud_app/core/utils/date_utils.dart' as app_date_utils;

void main() {
  group('DateUtils Tests', () {
    test('formatOrderDateTime should format morning time with AM', () {
      // Test case: 7:09 AM on September 29, 2025
      final testDateTime = DateTime(2025, 9, 29, 7, 9, 0);
      final result = app_date_utils.DateUtils.formatOrderDateTime(testDateTime);

      // Should include AM indicator and proper formatting
      expect(result, contains('7:09 AM'));
      expect(result, contains('29/9/2025'));
    });

    test('formatOrderDateTime should format afternoon time with PM', () {
      // Test case: 7:09 PM on September 29, 2025
      final testDateTime = DateTime(2025, 9, 29, 19, 9, 0);
      final result = app_date_utils.DateUtils.formatOrderDateTime(testDateTime);

      // Should include PM indicator and proper formatting
      expect(result, contains('7:09 PM'));
      expect(result, contains('29/9/2025'));
    });

    test('formatOrderDateTime should format noon correctly', () {
      // Test case: 12:00 PM (noon) on September 29, 2025
      final testDateTime = DateTime(2025, 9, 29, 12, 0, 0);
      final result = app_date_utils.DateUtils.formatOrderDateTime(testDateTime);

      // Should show 12:00 PM for noon
      expect(result, contains('12:00 PM'));
      expect(result, contains('29/9/2025'));
    });

    test('formatOrderDateTime should format midnight correctly', () {
      // Test case: 12:00 AM (midnight) on September 29, 2025
      final testDateTime = DateTime(2025, 9, 29, 0, 0, 0);
      final result = app_date_utils.DateUtils.formatOrderDateTime(testDateTime);

      // Should show 12:00 AM for midnight
      expect(result, contains('12:00 AM'));
      expect(result, contains('29/9/2025'));
    });

    test('formatDetailedDateTime should format with full month name', () {
      // Test case: 7:09 AM on September 29, 2025
      final testDateTime = DateTime(2025, 9, 29, 7, 9, 0);
      final result = app_date_utils.DateUtils.formatDetailedDateTime(testDateTime);

      // Should include full month name and "at"
      expect(result, contains('September 29, 2025'));
      expect(result, contains('at 7:09 AM'));
    });

    test('formatCompactDateTime should format with abbreviated month', () {
      // Test case: 7:09 AM on September 29, 2025
      final testDateTime = DateTime(2025, 9, 29, 7, 9, 0);
      final result = app_date_utils.DateUtils.formatCompactDateTime(testDateTime);

      // Should include abbreviated month
      expect(result, contains('Sep 29'));
      expect(result, contains('7:09 AM'));
    });

    test('formatTime should format time only', () {
      // Test case: 7:09 AM
      final testDateTime = DateTime(2025, 9, 29, 7, 9, 0);
      final result = app_date_utils.DateUtils.formatTime(testDateTime);

      // Should only include time
      expect(result, equals('7:09 AM'));
    });

    test('isToday should return true for today\'s date', () {
      final today = app_date_utils.DateUtils.nowInUtc();
      final result = app_date_utils.DateUtils.isToday(today);

      expect(result, isTrue);
    });

    test('isYesterday should return true for yesterday\'s date', () {
      final yesterday = app_date_utils.DateUtils.nowInUtc().subtract(const Duration(days: 1));
      final result = app_date_utils.DateUtils.isYesterday(yesterday);

      expect(result, isTrue);
    });
  });
}