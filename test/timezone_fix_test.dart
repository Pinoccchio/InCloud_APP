import 'package:flutter_test/flutter_test.dart';
import 'package:incloud_app/core/utils/date_utils.dart' as app_date_utils;

void main() {
  group('Timezone Fix Tests', () {
    test('nowInUtcString should return proper UTC timestamp', () {
      // Get current UTC timestamp
      final utcString = app_date_utils.DateUtils.nowInUtcString();

      // Should end with 'Z' indicating UTC
      expect(utcString, endsWith('Z'));

      // Should be parseable as UTC DateTime
      final parsedUtc = DateTime.parse(utcString);
      expect(parsedUtc.isUtc, isTrue);
    });

    test('Philippine time should be converted correctly to UTC', () {
      // Simulate Philippine time: 7:09 AM (UTC+8)
      final philippineTime = DateTime(2025, 9, 29, 7, 9, 0); // Local time

      // When converted to UTC for storage
      final utcTime = philippineTime.toUtc();

      // Should be 23:09 on September 28 (previous day) in UTC
      expect(utcTime.day, equals(28)); // Previous day in UTC
      expect(utcTime.hour, equals(23)); // 7 AM - 8 hours = 23:00 previous day
      expect(utcTime.minute, equals(9));
    });

    test('UTC timestamp should display correctly in Philippine time', () {
      // UTC timestamp: 2025-09-28 23:09:00 UTC (stored in database)
      final utcTime = DateTime.utc(2025, 9, 28, 23, 9, 0);

      // When displayed in Philippine time (UTC+8)
      final localTime = utcTime.toLocal();

      // Should show as 7:09 AM on September 29
      final formatted = app_date_utils.DateUtils.formatOrderDateTime(utcTime);

      // Should contain "7:09 AM" and "29/9/2025"
      expect(formatted, contains('7:09 AM'));
      expect(formatted, contains('29/9/2025'));
    });

    test('nowInUtc should return current time in UTC', () {
      final utcNow = app_date_utils.DateUtils.nowInUtc();

      // Should be UTC
      expect(utcNow.isUtc, isTrue);

      // Should be close to DateTime.now().toUtc()
      final systemUtc = DateTime.now().toUtc();
      final difference = utcNow.difference(systemUtc).inSeconds.abs();

      // Should be within 1 second
      expect(difference, lessThan(1));
    });

    test('Timezone conversion demonstrates the fix', () {
      print('=== TIMEZONE CONVERSION DEMONSTRATION ===');

      // 1. Current local time (Philippines)
      final localNow = DateTime.now();
      print('1. Current Philippine time: ${localNow.toString()}');

      // 2. Proper UTC conversion for database storage
      final utcForDb = app_date_utils.DateUtils.nowInUtcString();
      print('2. UTC for database storage: $utcForDb');

      // 3. Parse back from database and display
      final parsedFromDb = DateTime.parse(utcForDb);
      final displayTime = app_date_utils.DateUtils.formatOrderDateTime(parsedFromDb);
      print('3. Displayed to user: $displayTime');

      // Verify the cycle works correctly
      expect(parsedFromDb.isUtc, isTrue);
      expect(displayTime, isNotEmpty);
    });
  });
}