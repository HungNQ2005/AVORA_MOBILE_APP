import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/booking_item_model.dart';

/// Provider cung cấp MyBookingRepository
final myBookingRepositoryProvider = Provider<MyBookingRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return MyBookingRepository(dio);
});

/// Repository xử lý giao tiếp API cho Quản lý đặt phòng và lịch sử lưu trú
class MyBookingRepository {
  final Dio _dio;

  MyBookingRepository(this._dio);

  /// Lấy danh sách booking và lịch sử đặt phòng từ backend `GET /api/bookings/my`
  Future<BookingListResponse> fetchMyBookings({
    String? status,
    String? search,
    String? timeRange,
    String? userId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status != 'all' && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (timeRange != null && timeRange != 'all' && timeRange.isNotEmpty) {
        queryParams['timeRange'] = timeRange;
      }
      if (userId != null && userId.trim().isNotEmpty) {
        queryParams['user_id'] = userId.trim();
      }

      final response = await _dio.get(
        '/bookings/my',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data != null && data['data'] is Map<String, dynamic>) {
        return BookingListResponse.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }

      throw Exception('Dữ liệu danh sách đơn đặt phòng không đúng định dạng.');
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw Exception(
        serverMsg ?? e.message ?? 'Không thể tải danh sách đơn đặt phòng.',
      );
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  /// Lấy thông tin Voucher / E-ticket từ `GET /api/bookings/:id/voucher`
  Future<BookingVoucherModel> fetchBookingVoucher(String bookingId) async {
    try {
      final response = await _dio.get('/bookings/$bookingId/voucher');
      final data = response.data;
      if (data != null && data['data'] is Map<String, dynamic>) {
        return BookingVoucherModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }

      throw Exception('Dữ liệu voucher không đúng định dạng.');
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw Exception(
        serverMsg ?? e.message ?? 'Không thể tải voucher đơn đặt phòng.',
      );
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  /// Cập nhật thông tin khách lưu trú từ `PATCH /api/bookings/:id`
  Future<void> updateGuestInfo(
    String bookingId, {
    required String guestName,
    required String guestPhone,
    String? specialRequest,
  }) async {
    try {
      final payload = {
        'guest_name': guestName.trim(),
        'guest_phone': guestPhone.trim(),
        'special_request': specialRequest?.trim(),
      };

      await _dio.patch(
        '/bookings/$bookingId',
        data: payload,
      );
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw Exception(
        serverMsg ?? e.message ?? 'Không thể cập nhật thông tin khách.',
      );
    } catch (e) {
      throw Exception('Lỗi cập nhật: $e');
    }
  }

  /// Đổi ngày lưu trú từ `PATCH /api/bookings/:id/dates`
  Future<void> changeBookingDates(
    String bookingId, {
    required String checkInDate,
    required String checkOutDate,
  }) async {
    try {
      final payload = {
        'check_in_date': checkInDate.trim(),
        'check_out_date': checkOutDate.trim(),
      };

      await _dio.patch(
        '/bookings/$bookingId/dates',
        data: payload,
      );
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw Exception(
        serverMsg ?? e.message ?? 'Không thể thay đổi ngày lưu trú.',
      );
    } catch (e) {
      throw Exception('Lỗi đổi ngày: $e');
    }
  }

  /// Hủy đơn đặt phòng từ `POST /api/bookings/:id/cancel`
  Future<String> cancelBooking(
    String bookingId, {
    required String reason,
  }) async {
    try {
      final payload = {
        'reason': reason.trim(),
      };

      final response = await _dio.post(
        '/bookings/$bookingId/cancel',
        data: payload,
      );

      final resData = response.data;
      final msg = resData is Map ? resData['message']?.toString() : null;
      return msg ?? 'Đã hủy đơn đặt phòng thành công.';
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw Exception(
        serverMsg ?? e.message ?? 'Không thể hủy đơn đặt phòng.',
      );
    } catch (e) {
      throw Exception('Lỗi hủy phòng: $e');
    }
  }
}
