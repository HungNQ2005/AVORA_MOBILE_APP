import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../models/payment_qr_model.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return PaymentRepository(dio);
});

/// Repository thuần gọi API thanh toán đến Backend Avora Web (`dumb client`).
/// Mọi xử lý tạo mã giao dịch, sinh VietQR URL, tính thời gian giữ chỗ và đối soát
/// SePay webhook đều thực hiện 100% trên server.
class PaymentRepository {
  final Dio _dio;

  PaymentRepository(this._dio);

  /// Tạo hoặc lấy lại mã QR VietQR cho đơn đặt phòng đang ở trạng thái PENDING (`POST /api/payment/create-qr`).
  Future<PaymentQrModel> createPaymentQr(String bookingId) async {
    try {
      final response = await _dio.post(
        '/payment/create-qr',
        data: {'booking_id': bookingId},
      );

      final body = response.data;
      if (body is Map && body['data'] is Map) {
        return PaymentQrModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }

      throw const ApiException(
        message: 'Phản hồi tạo mã QR thanh toán không hợp lệ từ máy chủ.',
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(
        message: e.message ?? 'Không thể tạo mã QR thanh toán.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Kiểm tra trạng thái thanh toán của đơn đặt phòng (`GET /api/payment/status/:bookingId`).
  Future<PaymentStatusModel> fetchPaymentStatus(String bookingId) async {
    try {
      final response = await _dio.get('/payment/status/$bookingId');

      final body = response.data;
      if (body is Map && body['data'] is Map) {
        return PaymentStatusModel.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
        );
      }

      throw const ApiException(
        message: 'Không thể kiểm tra trạng thái thanh toán.',
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(
        message: e.message ?? 'Không thể kiểm tra trạng thái thanh toán.',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

