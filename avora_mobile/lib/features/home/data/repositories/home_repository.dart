import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/core/network/api_client.dart';
import '../models/hotel_model.dart';

/// Provider cung cấp [HomeRepository].
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(dio: ref.watch(apiClientProvider));
});

/// Repository xử lý Data layer cho Home feature.
/// Tương tác với Backend Node.js qua `/hotels`.
class HomeRepository {
  final Dio _dio;

  HomeRepository({required Dio dio}) : _dio = dio;

  /// Lấy danh sách khách sạn từ Backend (`GET /api/hotels`).
  Future<List<HotelModel>> fetchHotels({
    String? destination,
    String? checkIn,
    String? checkOut,
    int? adults,
    int? children,
    int? rooms,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (destination != null && destination.isNotEmpty) {
        queryParams['destination'] = destination;
      }
      if (checkIn != null) queryParams['checkIn'] = checkIn;
      if (checkOut != null) queryParams['checkOut'] = checkOut;
      if (adults != null) queryParams['adults'] = adults;
      if (children != null) queryParams['children'] = children;
      if (rooms != null) queryParams['rooms'] = rooms;

      final response = await _dio.get(
        '/hotels',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final Map<String, dynamic> rawJson = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      final dynamic data = rawJson['data'];
      final List<dynamic> hotelsList;

      if (data is Map && data['hotels'] is List) {
        hotelsList = data['hotels'] as List;
      } else if (data is List) {
        hotelsList = data;
      } else {
        hotelsList = [];
      }

      return hotelsList
          .map((item) => HotelModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((h) => h.hotelStatus.toUpperCase() == 'ACTIVE')
          .toList();
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Lỗi khi tải danh sách khách sạn.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Lỗi xử lý dữ liệu khách sạn: $e');
    }
  }

  /// Danh sách điểm đến thịnh hành (đồng bộ với Web version).
  List<TrendingDestination> getTrendingDestinations() {
    return const [
      TrendingDestination(
        name: 'Đà Nẵng',
        subtitle: '1.842 chỗ nghỉ sẵn có',
        imageUrl:
            'https://images.unsplash.com/photo-1559592413-7cec4d0cae2b?auto=format&fit=crop&w=1000&q=80',
        tag: '📍 Điểm đến số 1',
        startingPrice: 'Từ 480.000đ/đêm',
      ),
      TrendingDestination(
        name: 'Phú Quốc',
        subtitle: '965 chỗ nghỉ sẵn có',
        imageUrl:
            'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=1000&q=80',
        tag: '🏝 Đảo thiên đường',
        startingPrice: 'Từ 750.000đ/đêm',
      ),
      TrendingDestination(
        name: 'Đà Lạt',
        subtitle: '1.340 chỗ nghỉ ngắm mây',
        imageUrl:
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      ),
      TrendingDestination(
        name: 'Nha Trang',
        subtitle: '1.120 chỗ nghỉ ven biển',
        imageUrl:
            'https://images.unsplash.com/photo-1506929562872-bb421503ef21?auto=format&fit=crop&w=800&q=80',
      ),
      TrendingDestination(
        name: 'Vịnh Hạ Long',
        subtitle: '540 khách sạn & du thuyền',
        imageUrl:
            'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=800&q=80',
      ),
    ];
  }
}
