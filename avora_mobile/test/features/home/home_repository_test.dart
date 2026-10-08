import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:avora_mobile/features/home/data/repositories/home_repository.dart';
import 'package:avora_mobile/core/network/api_client.dart';

@GenerateMocks([Dio])
import 'home_repository_test.mocks.dart';

void main() {
  late HomeRepository repository;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    repository = HomeRepository(dio: mockDio);
  });

  group('HomeRepository.fetchHotels()', () {
    final mockHotelJson = {
      'status': 'success',
      'message': 'Lấy danh sách khách sạn thành công',
      'data': {
        'hotels': [
          {
            'hotel_id': 'hotel-001',
            'name': 'Avora Luxury Da Nang Hotel',
            'address': '170 Bạch Đằng, Hải Châu',
            'city_name': 'Đà Nẵng',
            'star_quality': 5,
            'star_rating': 9.4,
            'score_label': 'Tuyệt hảo',
            'reviews_count': 1580,
            'price': 1650000,
            'original_price': 2200000,
            'thumbnail': 'https://images.unsplash.com/photo-1566073771259-6a8506099945',
            'images': ['https://images.unsplash.com/photo-1566073771259-6a8506099945'],
            'tag': 'Ưu đãi mùa hè',
            'is_genius': true,
            'hotel_status': 'ACTIVE',
          },
          {
            'hotel_id': 'hotel-002',
            'name': 'Inactive Hotel',
            'hotel_status': 'INACTIVE',
            'price': 800000,
          }
        ]
      }
    };

    test('✅ Lấy danh sách thành công và tự động lọc chỉ giữ khách sạn ACTIVE', () async {
      when(
        mockDio.get(
          '/hotels',
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: mockHotelJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/hotels'),
        ),
      );

      final hotels = await repository.fetchHotels(destination: 'Đà Nẵng');

      expect(hotels.length, equals(1));
      expect(hotels.first.hotelId, equals('hotel-001'));
      expect(hotels.first.name, equals('Avora Luxury Da Nang Hotel'));
      expect(hotels.first.isGenius, isTrue);
      expect(hotels.first.price, equals(1650000));
    });

    test('❌ Server trả về lỗi DioException → ném ra ApiException', () async {
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
            message: 'Kết nối quá thời gian. Vui lòng kiểm tra kết nối mạng và thử lại.',
          ),
        ),
      );

      expect(
        () => repository.fetchHotels(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('HomeRepository.getTrendingDestinations()', () {
    test('✅ Trả về danh sách điểm đến thịnh hành đồng bộ với Web', () {
      final destinations = repository.getTrendingDestinations();

      expect(destinations.isNotEmpty, isTrue);
      expect(destinations.any((d) => d.name == 'Đà Nẵng'), isTrue);
      expect(destinations.any((d) => d.name == 'Phú Quốc'), isTrue);
    });
  });
}
