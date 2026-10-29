import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/hotels/data/models/hotel_detail_model.dart';
import 'package:avora_mobile/features/my_booking/data/models/booking_countdown_helper.dart';

void main() {
  group('ReviewModel.fromJson', () {
    test('reads the hotel review API response fields', () {
      final review = ReviewModel.fromJson({
        'review_id': 'review-1',
        'reviewer_name': 'Nguyen Van A',
        'rating_score': 8,
        'comment': 'A comfortable stay',
        'created_at': '2026-10-22T09:00:00Z',
      });

      expect(review.reviewId, 'review-1');
      expect(review.guestName, 'Nguyen Van A');
      expect(review.score, 8);
      expect(review.comment, 'A comfortable stay');
    });
  });

  group('BookingCountdownHelper.getCountdown', () {
    test('formats remaining payment time as minutes and seconds', () {
      final countdown = BookingCountdownHelper.getCountdown(
        createdAtStr: '2026-10-22T10:00:00Z',
        currentTime: DateTime.parse('2026-10-22T10:03:21Z'),
      );

      expect(countdown?.label, '06:39');
      expect(countdown?.expired, isFalse);
    });

    test('returns expired at and after the ten-minute deadline', () {
      final countdown = BookingCountdownHelper.getCountdown(
        createdAtStr: '2026-10-22T10:00:00Z',
        currentTime: DateTime.parse('2026-10-22T10:10:00Z'),
      );

      expect(countdown?.label, '00:00');
      expect(countdown?.expired, isTrue);
    });

    test('ignores missing or invalid timestamps', () {
      expect(
        BookingCountdownHelper.getCountdown(
          createdAtStr: '',
          currentTime: DateTime.utc(2026, 10, 22),
        ),
        isNull,
      );
      expect(
        BookingCountdownHelper.getCountdown(
          createdAtStr: 'not-a-date',
          currentTime: DateTime.utc(2026, 10, 22),
        ),
        isNull,
      );
    });
  });
}