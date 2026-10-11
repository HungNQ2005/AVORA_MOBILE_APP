import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:avora_mobile/core/network/api_client.dart';
import 'package:avora_mobile/features/hotels/data/models/hotel_filter_params.dart';
import 'package:avora_mobile/features/hotels/data/repositories/hotel_repository.dart';

import '../home/home_repository_test.mocks.dart';

void main() {
  late HotelRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = HotelRepository(dio: mockDio);
  });

  group('HotelRepository.searchHotels()', () {
    final mockSearchSuccessJson = {
      'status': 'success',
      'code': 200,
      'message': 'Lấy danh sách khách sạn thành công',
      'data': {
        'hotels': [
          {
            'hotel_id': 'hotel-001',
            'name': 'Avora Luxury Da Nang Hotel',
            'description': 'Khách sạn ven sông Hàn sang trọng',
            'address': '170 Bạch Đằng, Hải Châu',
            'city_name': 'Đà Nẵng',
            'star_quality': 5,
            'star_rating': 9.4,
            'score_label': 'Tuyệt hảo',
            'reviews_count': 1580,
            'price': 1650000,
            'original_price': 2200000,
            'thumbnail':
                'https://images.unsplash.com/photo-1566073771259-6a8506099945',
            'images': [
              'https://images.unsplash.com/photo-1566073771259-6a8506099945'
            ],
            'tag': 'Ưu đãi mùa hè - Giảm 20%',
            'is_genius': true,
            'hotel_status': 'ACTIVE',
            'available_rooms': 3,
            'facilities': [
              {
                'id': 'fac-001',
                'name': 'Bãi biển riêng',
                'icon': 'beach_access',
                'type': 'OUTDOOR'
              },
              {
                'id': 'fac-002',
                'name': 'Hồ bơi vô cực',
                'icon': 'pool',
                'type': 'HOTEL'
              }
            ],
            'room_highlight': {
              'room_type_id': 'room-001',
              'name': 'Phòng Deluxe Hướng Biển',
              'bed_type': '1 giường đôi cực lớn',
              'room_size': '38 m²',
              'standard_beds': 1,
              'standard_capacity': 2,
              'has_extra_bed': true,
              'extra_bed_capacity': 1,
              'max_capacity': 3
            },
            'cancellation_policy': {
              'free_before_hours': 48,
              'description': 'Miễn phí hủy phòng trước 48h (hoàn tiền 100%)'
            }
          },
          {
            'hotel_id': 'hotel-002',
            'name': 'Inactive Hotel',
            'hotel_status': 'INACTIVE',
            'price': 900000,
          }
        ],
        'total': 1,
        'filterStats': {
          'priceRanges': {
            'all': 1,
            'under1m2': 0,
            'from1m2To2m5': 1,
            'from2m5To5m': 0,
            'above5m': 0
          },
          'stars': {'5': 1, '4': 0, '3': 0},
          'ratings': {'9': 1, '8': 1, '7': 1},
          'popularFacilities': {
            'beach': 1,
            'pool': 1,
            'breakfast': 1,
            'freeCancel': 1
          },
          'capacities': {
            'all': 1,
            'standard_double': 1,
            'standard_two_beds': 0,
            'with_extra_bed': 1
          }
        }
      }
    };

    test('✅ Tìm kiếm thành công → Trả về danh sách khách sạn và thống kê bộ lọc',
        () async {
      when(
        mockDio.get(
          '/hotels',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: mockSearchSuccessJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/hotels'),
        ),
      );

      final result = await repository.searchHotels(
        const HotelSearchParams(
          destination: 'Đà Nẵng',
          sortBy: 'popularity',
        ),
      );

      expect(result.hotels.length, equals(1));
      expect(result.hotels.first.hotelId, equals('hotel-001'));
      expect(result.hotels.first.name, equals('Avora Luxury Da Nang Hotel'));
      expect(result.hotels.first.starQuality, equals(5));
      expect(result.hotels.first.starRating, equals(9.4));
      expect(result.hotels.first.facilities.length, equals(2));
      expect(result.hotels.first.roomHighlight?.name,
          equals('Phòng Deluxe Hướng Biển'));
      expect(result.hotels.first.cancellationPolicy?.freeBeforeHours, equals(48));
      expect(result.filterStats.totalCount, equals(1));
      expect(result.filterStats.star5Count, equals(1));
      expect(result.exceededCapacity, isFalse);
    });

    test('⚠️ Xử lý phản hồi vượt quá sức chứa từ Backend (> 5 người/phòng)',
        () async {
      final mockExceededJson = {
        'status': 'success',
        'code': 200,
        'message': 'Lấy danh sách khách sạn thành công',
        'data': {
          'hotels': [],
          'total': 0,
          'exceededCapacity': true,
          'guestsPerRoom': 6,
          'totalGuests': 6,
          'rooms': 1,
          'minRoomsRequired': 2,
          'message': 'Không có loại phòng nào như vậy. Sức chứa tối đa là 5 người/phòng.',
          'filterStats': {'priceRanges': {'all': 0}}
        }
      };

      when(
        mockDio.get(
          '/hotels',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: mockExceededJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/hotels'),
        ),
      );

      final result = await repository.searchHotels(
        const HotelSearchParams(
          adults: 6,
          rooms: 1,
        ),
      );

      expect(result.exceededCapacity, isTrue);
      expect(result.hotels, isEmpty);
      expect(result.guestsPerRoom, equals(6));
      expect(result.minRoomsRequired, equals(2));
      expect(result.message, contains('Sức chứa tối đa là 5 người/phòng'));
    });

    test('❌ Server trả về lỗi mạng DioException → ném ra ApiException',
        () async {
      when(
        mockDio.get(
          '/hotels',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/hotels'),
          type: DioExceptionType.connectionTimeout,
          error: const ApiException(
            message:
                'Kết nối quá thời gian. Vui lòng kiểm tra kết nối mạng và thử lại.',
          ),
        ),
      );

      expect(
        () => repository.searchHotels(const HotelSearchParams()),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
