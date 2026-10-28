import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/coupon_model.dart';
import '../models/booking_result_model.dart';
import '../models/booking_detail_model.dart';

/// Provider cung cấp BookingRepository
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return BookingRepository(dio);
});

/// Repository xử lý tính toán giá phòng, áp dụng mã giảm giá và tạo đơn đặt phòng
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

  /// Gọi API `POST /api/bookings` để tạo đơn đặt phòng mới vào cơ sở dữ liệu.
  Future<BookingResultModel> createBooking({
    required String hotelId,
    required String roomTypeId,
    required int quantity,
    required String checkInDate,
    required String checkOutDate,
    required String guestName,
    required String guestPhone,
    String? specialRequest,
    String? couponCode,
    String? hotelName,
    String? roomName,
  }) async {
    try {
      final payload = {
        'hotel_id': hotelId,
        'room_type_id': roomTypeId,
        'quantity': quantity,
        'rooms': [
          {
            'room_type_id': roomTypeId,
            'quantity': quantity,
          }
        ],
        'check_in_date': checkInDate,
        'check_out_date': checkOutDate,
        'guest_name': guestName.trim(),
        'guest_phone': guestPhone.trim(),
        if (specialRequest != null && specialRequest.trim().isNotEmpty)
          'special_request': specialRequest.trim(),
        if (couponCode != null && couponCode.trim().isNotEmpty)
          'coupon_code': couponCode.trim().toUpperCase(),
      };

      final response = await _dio.post(
        '/bookings',
        data: payload,
      );

      final data = response.data;
      if (data != null && data['data'] is Map<String, dynamic>) {
        final result = BookingResultModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
        // Bổ sung tên khách sạn và tên phòng từ context gọi nếu server không trả kèm
        return BookingResultModel(
          bookingId: result.bookingId,
          bookingCode: result.bookingCode,
          bookingStatusCd: result.bookingStatusCd,
          statusCodeName: result.statusCodeName,
          hotelId: result.hotelId,
          guestName: result.guestName,
          guestPhone: result.guestPhone,
          totalAmount: result.totalAmount,
          discountAmount: result.discountAmount,
          couponApplied: result.couponApplied,
          createdAt: result.createdAt,
          hotelName: hotelName ?? result.hotelName,
          roomName: roomName ?? result.roomName,
        );
      }

      throw Exception('Dữ liệu phản hồi đơn đặt phòng không đúng định dạng.');
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverCode = resData is Map ? resData['code']?.toString() : null;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;

      if (serverCode == 'SOLD_OUT' || (serverMsg != null && serverMsg.contains('hết phòng'))) {
        throw Exception('Rất tiếc, phòng đã hết trong thời gian bạn chọn. Vui lòng chọn ngày khác hoặc giảm số phòng.');
      }
      throw Exception(serverMsg ?? e.message ?? 'Không thể tạo đơn đặt phòng.');
    } catch (e) {
      throw Exception('Lỗi đặt phòng: $e');
    }
  }

  /// Gọi API `GET /api/bookings/:id` để lấy toàn bộ thông tin chi tiết của một đơn đặt phòng.
  Future<BookingDetailModel> getBookingDetail(String bookingId) async {
    try {
      final response = await _dio.get('/bookings/$bookingId');
      final data = response.data;
      if (data != null && data['data'] is Map<String, dynamic>) {
        return BookingDetailModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }

      throw Exception('Dữ liệu chi tiết đặt phòng không đúng định dạng.');
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      if (e.response?.statusCode == 404) {
        throw Exception(serverMsg ?? 'Không tìm thấy thông tin đơn đặt phòng.');
      }
      throw Exception(serverMsg ?? e.message ?? 'Không thể tải chi tiết đặt phòng.');
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  /// Gọi API `GET /api/bookings/my` để lấy danh sách các đơn đặt phòng của người dùng hiện tại.
  Future<List<BookingDetailModel>> getMyBookings({String status = 'all'}) async {
    try {
      final response = await _dio.get(
        '/bookings/my',
        queryParameters: {
          if (status != 'all') 'status': status,
        },
      );

      final data = response.data;
      if (data != null && data['data'] is Map<String, dynamic>) {
        final bookingsList = data['data']['bookings'];
        if (bookingsList is List) {
          return bookingsList
              .whereType<Map>()
              .map((item) => BookingDetailModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList();
        }
      }

      return [];
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw Exception(serverMsg ?? e.message ?? 'Không thể tải danh sách đơn đặt phòng.');
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }
}
