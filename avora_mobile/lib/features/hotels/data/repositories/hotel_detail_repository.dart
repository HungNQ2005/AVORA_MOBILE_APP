import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/core/network/api_client.dart';
import '../models/hotel_detail_model.dart';

/// Provider cung cấp [HotelDetailRepository].
final hotelDetailRepositoryProvider = Provider<HotelDetailRepository>((ref) {
  return HotelDetailRepository(dio: ref.watch(apiClientProvider));
});

/// Repository lấy chi tiết khách sạn từ Backend (`GET /api/hotels/:id`).
class HotelDetailRepository {
  final Dio _dio;

  HotelDetailRepository({required Dio dio}) : _dio = dio;

  /// Lấy thông tin chi tiết của một khách sạn theo ID.
  Future<HotelDetailModel> fetchHotelDetail(
    String id, {
    String? checkIn,
    String? checkOut,
    int? adults,
    int? children,
    int? rooms,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (checkIn != null) queryParams['checkIn'] = checkIn;
      if (checkOut != null) queryParams['checkOut'] = checkOut;
      if (adults != null) queryParams['adults'] = adults;
      if (children != null) queryParams['children'] = children;
      if (rooms != null) queryParams['rooms'] = rooms;

      final response = await _dio.get(
        '/hotels/$id',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final Map<String, dynamic> rawJson = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      final dynamic data = rawJson['data'];
      if (data is Map<String, dynamic>) {
        return HotelDetailModel.fromJson(data);
      } else if (data is Map) {
        return HotelDetailModel.fromJson(Map<String, dynamic>.from(data));
      }

      throw ApiException(message: 'Dữ liệu khách sạn không hợp lệ.');
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(
        message: e.response?.data is Map && e.response?.data['message'] != null
            ? e.response?.data['message'].toString()
            : (e.message ?? 'Lỗi khi tải thông tin chi tiết khách sạn.'),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Lỗi xử lý dữ liệu chi tiết khách sạn: $e');
    }
  }
}
