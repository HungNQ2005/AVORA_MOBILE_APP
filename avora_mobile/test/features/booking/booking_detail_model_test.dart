import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/booking/data/models/booking_detail_model.dart';

void main() {
  group('BookingDetailModel', () {
    test('parses correctly from raw database structure (t_booking with joins)', () {
      final json = {
        'booking_id': 'b101-uuid',
        'user_id': 'u202-uuid',
        'hotel_id': 'h303-uuid',
        'total_amount': 1500000,
        'discount_amount': 200000,
        'guest_name': 'Nguyễn Văn A',
        'guest_phone': '0912345678',
        'special_request': 'Tầng cao, phòng yên tĩnh',
        'booking_status_cd': '2',
        'status_code_name': 'CFM',
        'created_at': '2026-10-21T10:00:00.000Z',
        'updated_at': '2026-10-21T10:00:00.000Z',
        'm_hotel': {
          'hotel_id': 'h303-uuid',
          'name': 'Avora Grand Hotel Danang',
          'address': '120 Bạch Đằng, Hải Châu, Đà Nẵng',
          'star_rating': 4.8,
          'star_quality': 5,
          'm_hotel_image': [
            {
              'image_url': 'https://avora.vn/img1.jpg',
              'is_thumbnail': true,
              'sort_order': 1,
            }
          ],
        },
        't_booking_detail': [
          {
            'booking_detail_id': 'bd1',
            'room_type_id': 'rt1',
            'check_in_date': '2026-11-10',
            'check_out_date': '2026-11-12',
            'quantity': 1,
            'unit_price': 850000,
            'm_room_type': {
              'room_type_id': 'rt1',
              'type_name': 'Deluxe Ocean View',
              'bed_type': '1 giường đôi lớn',
              'room_size': '32m²',
              'max_adults': 2,
              'max_children': 1,
              'default_price': 850000,
            },
          }
        ],
        'm_coupon': {
          'coupon_id': 'c1',
          'code': 'SUMMER2026',
          'discount_type': 'FIXED',
          'discount_value': 200000,
        },
        't_payment_transaction': [
          {
            'transaction_id': 'tx101',
            'amount_paid': 1500000,
            'payment_method_cd': 'BTR',
            'paid_at': '2026-10-21T10:05:00.000Z',
          }
        ],
        'm_cancellation_policy': {
          'cancellation_policy_id': 'cp1',
          'free_cancel_before_hours': 48,
          'penalty_rate': 100,
          'description': 'Miễn phí hủy phòng trước 48h.',
        },
      };

      final model = BookingDetailModel.fromJson(json);

      expect(model.bookingId, 'b101-uuid');
      expect(model.hotelName, 'Avora Grand Hotel Danang');
      expect(model.hotelAddress, '120 Bạch Đằng, Hải Châu, Đà Nẵng');
      expect(model.hotelStarQuality, 5);
      expect(model.hotelThumbnailUrl, 'https://avora.vn/img1.jpg');
      expect(model.guestName, 'Nguyễn Văn A');
      expect(model.guestPhone, '0912345678');
      expect(model.specialRequest, 'Tầng cao, phòng yên tĩnh');
      expect(model.roomTypeName, 'Deluxe Ocean View');
      expect(model.bedType, '1 giường đôi lớn');
      expect(model.roomSize, '32m²');
      expect(model.maxAdults, 2);
      expect(model.maxChildren, 1);
      expect(model.checkInDate, '2026-11-10');
      expect(model.checkOutDate, '2026-11-12');
      expect(model.nights, 2);
      expect(model.totalAmount, 1500000);
      expect(model.discountAmount, 200000);
      expect(model.couponCode, 'SUMMER2026');
      expect(model.isPaid, true);
      expect(model.paymentMethod, 'Chuyển khoản ngân hàng');
      expect(model.statusName, 'Đã xác nhận & Đã thanh toán');
      expect(model.statusBadgeVariant, 'confirmed');
      expect(model.freeCancelHours, 48);
      expect(model.cancellationPolicyDescription, 'Miễn phí hủy phòng trước 48h.');
      expect(model.formattedCheckIn, contains('Từ 14:00'));
      expect(model.formattedCheckOut, contains('Trước 12:00'));
    });

    test('resolves cancelled status properly (code 3 / CAN)', () {
      final json = {
        'booking_id': 'b102',
        'hotel_id': 'h1',
        'total_amount': 500000,
        'guest_name': 'Khách hàng B',
        'guest_phone': '0988776655',
        'booking_status_cd': '3',
        'status_code_name': 'CAN',
        't_booking_detail': [
          {
            'check_in_date': '2026-12-01',
            'check_out_date': '2026-12-03',
          }
        ],
      };

      final model = BookingDetailModel.fromJson(json);

      expect(model.statusName, 'Đã hủy phòng');
      expect(model.statusBadgeVariant, 'cancelled');
    });

    test('resolves pending status properly (code 1 / PND)', () {
      final json = {
        'booking_id': 'b103',
        'hotel_id': 'h1',
        'total_amount': 500000,
        'guest_name': 'Khách hàng C',
        'guest_phone': '0988776655',
        'booking_status_cd': '1',
        'status_code_name': 'PND',
        't_booking_detail': [
          {
            'check_in_date': '2026-12-01',
            'check_out_date': '2026-12-03',
          }
        ],
      };

      final model = BookingDetailModel.fromJson(json);

      expect(model.statusName, 'Chờ thanh toán');
      expect(model.statusBadgeVariant, 'pending');
      expect(model.isPaid, false);
    });

    test('resolves completed status when checkout is in the past', () {
      final json = {
        'booking_id': 'b104',
        'hotel_id': 'h1',
        'total_amount': 1000000,
        'guest_name': 'Khách hàng D',
        'guest_phone': '0988776655',
        'booking_status_cd': '2',
        'status_code_name': 'CFM',
        't_booking_detail': [
          {
            'check_in_date': '2024-01-10',
            'check_out_date': '2024-01-12',
          }
        ],
      };

      final model = BookingDetailModel.fromJson(json);

      expect(model.statusName, 'Đã hoàn thành lưu trú');
      expect(model.statusBadgeVariant, 'completed');
    });

    test('parses correctly from enriched booking format', () {
      final json = {
        'booking_id': 'b105',
        'booking_code': 'AV-1026-B105',
        'guest_name': 'Lê Văn E',
        'guest_phone': '0901234567',
        'status_name': 'Đã xác nhận đặt chỗ',
        'status_badge_variant': 'confirmed',
        'total_amount': 2000000,
        'discount_amount': 100000,
        'hotel': {
          'hotel_id': 'h99',
          'name': 'Avora Boutique Hotel',
          'address': 'Quận 1, TP. HCM',
          'thumbnail_url': 'https://avora.vn/thumb.jpg',
        },
        'stay': {
          'room_type_name': 'Executive Suite',
          'check_in_date': '2026-11-20',
          'check_out_date': '2026-11-23',
          'nights': 3,
          'quantity': 2,
          'unit_price': 1000000,
          'bed_type': 'King Bed',
          'room_size': '45m²',
          'max_adults': 4,
          'max_children': 2,
        },
        'coupon': {
          'code': 'VIP100',
          'discount_text': 'Giảm 100.000 ₫',
        },
        'payment': {
          'is_paid': true,
          'payment_method': 'VNPAY QR',
        },
      };

      final model = BookingDetailModel.fromJson(json);

      expect(model.bookingCode, 'AV-1026-B105');
      expect(model.hotelName, 'Avora Boutique Hotel');
      expect(model.roomTypeName, 'Executive Suite');
      expect(model.nights, 3);
      expect(model.quantity, 2);
      expect(model.couponCode, 'VIP100');
      expect(model.isPaid, true);
      expect(model.paymentMethod, 'VNPAY QR');
      expect(model.statusName, 'Đã xác nhận đặt chỗ');
    });
  });
}
