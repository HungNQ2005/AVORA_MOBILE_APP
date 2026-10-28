import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:avora_mobile/features/booking/data/repositories/booking_repository.dart';
import 'package:avora_mobile/features/booking/data/models/booking_detail_model.dart';

import '../home/home_repository_test.mocks.dart';

void main() {
  late BookingRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = BookingRepository(mockDio);
  });

  group('BookingRepository.getBookingDetail()', () {
    final mockBookingDetailJson = {
      'status': 'success',
      'data': {
        'booking_id': 'bk-001',
        'hotel_id': 'hotel-001',
        'total_amount': 1200000,
        'discount_amount': 0,
        'guest_name': 'Trần Văn B',
        'guest_phone': '0912345678',
        'booking_status_cd': '2',
        'status_code_name': 'CFM',
        'm_hotel': {
          'name': 'Avora Da Nang Luxury',
          'address': 'Bạch Đằng, Đà Nẵng',
          'star_quality': 5,
        },
        't_booking_detail': [
          {
            'room_type_id': 'rt-001',
            'check_in_date': '2026-11-01',
            'check_out_date': '2026-11-03',
            'quantity': 1,
            'unit_price': 600000,
            'm_room_type': {
              'type_name': 'Phòng Deluxe',
              'bed_type': '1 giường đôi lớn',
              'room_size': '30m²',
              'max_adults': 2,
              'max_children': 0,
            },
          }
        ],
      },
    };

    test('returns BookingDetailModel on 200 success', () async {
      when(mockDio.get('/bookings/bk-001')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/bookings/bk-001'),
          statusCode: 200,
          data: mockBookingDetailJson,
        ),
      );

      final result = await repository.getBookingDetail('bk-001');

      expect(result, isA<BookingDetailModel>());
      expect(result.bookingId, 'bk-001');
      expect(result.hotelName, 'Avora Da Nang Luxury');
      expect(result.roomTypeName, 'Phòng Deluxe');
      expect(result.guestName, 'Trần Văn B');
      expect(result.totalAmount, 1200000);
      expect(result.checkInDate, '2026-11-01');
      expect(result.checkOutDate, '2026-11-03');
      expect(result.nights, 2);
    });

    test('throws friendly exception when 404 not found', () async {
      when(mockDio.get('/bookings/invalid-id')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/bookings/invalid-id'),
          response: Response(
            requestOptions: RequestOptions(path: '/bookings/invalid-id'),
            statusCode: 404,
            data: {
              'status': 'error',
              'message': 'Không tìm thấy thông tin đơn đặt phòng.',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => repository.getBookingDetail('invalid-id'),
        throwsA(
          predicate((e) =>
              e.toString().contains('Không tìm thấy thông tin đơn đặt phòng')),
        ),
      );
    });

    test('throws exception when response data is malformed', () async {
      when(mockDio.get('/bookings/malformed')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/bookings/malformed'),
          statusCode: 200,
          data: {'status': 'success', 'data': null},
        ),
      );

      expect(
        () => repository.getBookingDetail('malformed'),
        throwsA(
          predicate((e) =>
              e.toString().contains('Dữ liệu chi tiết đặt phòng không đúng định dạng')),
        ),
      );
    });
  });
}
