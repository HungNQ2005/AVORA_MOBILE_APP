import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/coupon_model.dart';

/// Provider cung cấp BookingRepository
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return BookingRepository(dio);
});

/// Repository xử lý tính toán giá phòng và kiểm tra/áp dụng mã giảm giá (Coupon/Voucher)
class BookingRepository {
  final Dio _dio;

  BookingRepository(this._dio);

  /// Gọi API `POST /api/bookings/calculate` để tính toán chi tiết giá tiền & áp dụng Coupon.
  Future<BookingPricingModel> calculatePricing({
    required String hotelId,
    required String roomTypeId,
    required int quantity,
    required String checkInDate,
    required String checkOutDate,
    String? couponCode,
  }) async {
    try {
      final payload = {
        'hotel_id': hotelId,
        'room_type_id': roomTypeId,
        'quantity': quantity,
        'check_in_date': checkInDate,
        'check_out_date': checkOutDate,
        if (couponCode != null && couponCode.trim().isNotEmpty)
          'coupon_code': couponCode.trim().toUpperCase(),
      };

      final response = await _dio.post(
        '/bookings/calculate',
        data: payload,
      );

      final data = response.data;
      if (data != null && data['data'] is Map<String, dynamic>) {
        return BookingPricingModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }

      throw Exception('Dữ liệu tính toán giá phòng không đúng định dạng.');
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw Exception(serverMsg ?? e.message ?? 'Không thể tính toán chi phí đặt phòng.');
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }
}
