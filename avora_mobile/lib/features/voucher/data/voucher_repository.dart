import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/core/network/api_client.dart';
import 'package:avora_mobile/features/booking/data/models/coupon_model.dart';

/// Provider cung cấp VoucherRepository instance
final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return VoucherRepository(dio);
});

/// Repository xử lý truy xuất danh sách Voucher / Coupon từ backend AVORA (Read-Only)
class VoucherRepository {
  final Dio _dio;

  VoucherRepository(this._dio);

  /// Lấy danh sách Voucher từ API `GET /api/coupons`
  Future<List<CouponModel>> getCustomerVouchers({
    String? search,
    String? discountType,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (discountType != null && discountType != 'ALL') {
        queryParams['discount_type'] = discountType;
      }

      final response = await _dio.get(
        '/coupons',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data != null && data['data'] != null) {
        final dynamic raw = data['data'];
        List rawList = [];
        if (raw is Map && raw['coupons'] is List) {
          rawList = raw['coupons'] as List;
        } else if (raw is List) {
          rawList = raw;
        }

        return rawList
            .whereType<Map>()
            .map((item) => CouponModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw Exception(
        serverMsg ?? e.message ?? 'Không thể tải danh sách mã khuyến mãi.',
      );
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  /// Lấy chi tiết một Voucher theo ID từ `GET /api/coupons/:id`
  Future<CouponModel> getVoucherById(String couponId) async {
    try {
      final response = await _dio.get('/coupons/$couponId');
      final data = response.data;
      if (data != null && data['data'] is Map<String, dynamic>) {
        return CouponModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
      throw Exception('Dữ liệu chi tiết mã khuyến mãi không đúng định dạng.');
    } on DioException catch (e) {
      final resData = e.response?.data;
      final serverMsg = resData is Map ? resData['message']?.toString() : null;
      throw Exception(
        serverMsg ?? e.message ?? 'Không thể tải chi tiết mã khuyến mãi.',
      );
    } catch (e) {
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }
}
