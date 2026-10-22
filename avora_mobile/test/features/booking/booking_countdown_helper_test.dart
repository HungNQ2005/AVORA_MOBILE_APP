import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/my_booking/data/models/booking_countdown_helper.dart';

void main() {
  group('BookingCountdownHelper.getCountdown', () {
    final createdAt = DateTime.utc(2026, 10, 22, 7);

    test('returns the remaining time until the 10-minute deadline', () {
      final countdown = BookingCountdownHelper.getCountdown(
        createdAtStr: createdAt.toIso8601String(),
        currentTime: createdAt.add(const Duration(minutes: 2, seconds: 15)),
      );

      expect(countdown?.label, '07:45');
      expect(countdown?.expired, isFalse);
    });

    test('rounds up partial seconds and marks the deadline as expired', () {
      final almostExpired = BookingCountdownHelper.getCountdown(
        createdAtStr: createdAt.toIso8601String(),
        currentTime: createdAt.add(const Duration(minutes: 9, seconds: 59)),
      );
      final expired = BookingCountdownHelper.getCountdown(
        createdAtStr: createdAt.toIso8601String(),
        currentTime: createdAt.add(const Duration(minutes: 10)),
      );

      expect(almostExpired?.label, '00:01');
      expect(almostExpired?.expired, isFalse);
      expect(expired?.label, '00:00');
      expect(expired?.expired, isTrue);
    });

    test('returns null for an invalid creation time', () {
      expect(
        BookingCountdownHelper.getCountdown(
          createdAtStr: 'not-a-date',
          currentTime: createdAt,
        ),
        isNull,
      );
    });
  });
}
