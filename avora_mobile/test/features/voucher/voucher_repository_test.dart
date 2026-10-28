import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/voucher/data/voucher_repository.dart';

class _FakeDioAdapter implements HttpClientAdapter {
  final Map<String, dynamic> Function(RequestOptions options) handler;

  _FakeDioAdapter(this.handler);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final result = handler(options);
    final statusCode = result['statusCode'] as int? ?? 200;
    final body = result['body'];
    return ResponseBody.fromString(
      body is String ? body : ResponseBody.fromString('', 200).toString(),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  group('VoucherRepository Tests', () {
    test('getCustomerVouchers parses backend response correctly', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/coupons') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'success',
                    'message': 'Lấy danh sách coupon thành công',
                    'data': {
                      'total_coupons': 2,
                      'active_coupons': 1,
                      'expired_coupons': 1,
                      'coupons': [
                        {
                          'coupon_id': 'c-1',
                          'code': 'SUMMER2026',
                          'discount_type': 'PERCENT',
                          'discount_value': 15,
                          'max_discount_amount': 200000,
                          'min_order_amount': 500000,
                          'valid_from': '2026-06-01T00:00:00Z',
                          'valid_to': '2026-08-31T23:59:59Z',
                          'status': 'ACTIVE',
                          'status_label': 'Đang hoạt động',
                        },
                        {
                          'coupon_id': 'c-2',
                          'code': 'TET2026',
                          'discount_type': 'FIXED',
                          'discount_value': 100000,
                          'min_order_amount': 0,
                          'status': 'EXPIRED',
                          'status_label': 'Hết hạn',
                        },
                      ],
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final repository = VoucherRepository(dio);
      final vouchers = await repository.getCustomerVouchers();

      expect(vouchers.length, 2);
      expect(vouchers[0].code, 'SUMMER2026');
      expect(vouchers[0].discountType, 'PERCENT');
      expect(vouchers[0].discountValue, 15);
      expect(vouchers[0].formattedBadge, '-15%');
      expect(vouchers[0].minOrderAmount, 500000);
      expect(vouchers[0].status, 'ACTIVE');
      expect(vouchers[0].statusLabel, 'Đang hoạt động');

      expect(vouchers[1].code, 'TET2026');
      expect(vouchers[1].discountType, 'FIXED');
      expect(vouchers[1].discountValue, 100000);
      expect(vouchers[1].formattedBadge, '-100.000 ₫');
      expect(vouchers[1].status, 'EXPIRED');
    });

    test('getCustomerVouchers supports direct list in data field', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'data': [
                    {
                      'coupon_id': 'c-3',
                      'code': 'WELCOME50',
                      'discount_type': 'FIXED',
                      'discount_value': 50000,
                      'status': 'ACTIVE',
                    }
                  ],
                },
              ),
            );
          },
        ),
      );

      final repository = VoucherRepository(dio);
      final vouchers = await repository.getCustomerVouchers();

      expect(vouchers.length, 1);
      expect(vouchers[0].code, 'WELCOME50');
      expect(vouchers[0].discountValue, 50000);
    });

    test('getVoucherById returns coupon detail', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/coupons/c-1') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'success',
                    'data': {
                      'coupon_id': 'c-1',
                      'code': 'SUMMER2026',
                      'discount_type': 'PERCENT',
                      'discount_value': 15,
                    },
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final repository = VoucherRepository(dio);
      final voucher = await repository.getVoucherById('c-1');

      expect(voucher.couponId, 'c-1');
      expect(voucher.code, 'SUMMER2026');
      expect(voucher.discountValue, 15);
    });
  });
}
