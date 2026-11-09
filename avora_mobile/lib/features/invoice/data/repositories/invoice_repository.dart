import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/core/network/api_client.dart';
import 'package:avora_mobile/features/my_booking/data/models/booking_item_model.dart';
import '../models/invoice_model.dart';

/// Provider cung cấp InvoiceRepository
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return InvoiceRepository(dio);
});

/// Repository xử lý giao tiếp API hóa đơn VAT & thông tin giao dịch thanh toán
class InvoiceRepository {
  final Dio _dio;

  InvoiceRepository(this._dio);

  /// Lấy danh sách hóa đơn thanh toán từ `GET /api/bookings/my?requireVatOnly=true`
  Future<List<InvoiceListItemModel>> fetchInvoices({
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'requireVatOnly': 'true',
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (status != null && status != 'all' && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        '/bookings/my',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data != null && data['data'] is Map<String, dynamic>) {
        final rawBookings = data['data']['bookings'] as List? ?? [];
        return rawBookings
            .map((b) => BookingItemModel.fromJson(
                  Map<String, dynamic>.from(b as Map),
                ))
            .map((b) => InvoiceListItemModel.fromBookingItem(b))
            .toList();
      }

      throw Exception('Dữ liệu danh sách hóa đơn không đúng định dạng.');
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw Exception(
        serverMsg ?? e.message ?? 'Không thể tải danh sách hóa đơn thanh toán.',
      );
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  /// Lấy chi tiết hóa đơn VAT & thông tin giao dịch thanh toán từ:
  /// `GET /api/bookings/:id/invoice` kết hợp dữ liệu bổ trợ từ `GET /api/bookings/:id`
  Future<InvoiceDetailModel> fetchInvoiceDetail(String bookingId) async {
    try {
      // 1. Gọi API biên nhận / hóa đơn VAT điện tử
      final invoiceResponse = await _dio.get('/bookings/$bookingId/invoice');
      final invoiceData = invoiceResponse.data;
      if (invoiceData == null || invoiceData['data'] is! Map) {
        throw Exception('Dữ liệu hóa đơn từ hệ thống không đúng định dạng.');
      }
      final invoiceMap = Map<String, dynamic>.from(invoiceData['data'] as Map);

      // 2. Gọi API chi tiết đơn đặt phòng để lấy thêm thông tin giao dịch (transaction_id, phòng, ngày)
      Map<String, dynamic>? bookingMap;
      try {
        final bookingResponse = await _dio.get('/bookings/$bookingId');
        if (bookingResponse.data != null &&
            bookingResponse.data['data'] is Map) {
          bookingMap =
              Map<String, dynamic>.from(bookingResponse.data['data'] as Map);
        }
      } catch (_) {
        // Dự phòng nếu API booking bị lỗi hoặc mạng chậm, vẫn hiển thị hóa đơn từ invoiceMap
      }

      return InvoiceDetailModel.fromCombined(
        bookingId: bookingId,
        invoiceJson: invoiceMap,
        bookingJson: bookingMap,
      );
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw Exception(
        serverMsg ?? e.message ?? 'Không thể tải chi tiết hóa đơn điện tử.',
      );
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }
}

