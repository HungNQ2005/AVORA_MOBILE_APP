import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/booking/data/models/coupon_model.dart';
import 'package:avora_mobile/features/voucher/data/voucher_repository.dart';
import 'package:avora_mobile/features/voucher/presentation/screens/voucher_wallet_screen.dart';

class _FakeVoucherRepository extends VoucherRepository {
  List<CouponModel> mockVouchers = [];
  bool shouldThrow = false;
  String errorMessage = 'Lỗi máy chủ không xác định';

  _FakeVoucherRepository() : super(Dio());

  @override
  Future<List<CouponModel>> getCustomerVouchers({
    String? search,
    String? discountType,
  }) async {
    if (shouldThrow) {
      throw Exception(errorMessage);
    }
    return mockVouchers;
  }
}

void main() {
  void useMobileViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  final sampleVouchers = [
    const CouponModel(
      couponId: 'v-1',
      code: 'SUMMER2026',
      discountType: 'PERCENT',
      discountValue: 15,
      maxDiscountAmount: 200000,
      minOrderAmount: 500000,
      validFrom: '2026-06-01T00:00:00Z',
      validTo: '2026-08-31T23:59:59Z',
      status: 'ACTIVE',
      statusLabel: 'Đang hoạt động',
    ),
    const CouponModel(
      couponId: 'v-2',
      code: 'AVORA100K',
      discountType: 'FIXED',
      discountValue: 100000,
      minOrderAmount: 1000000,
      validFrom: '2026-01-01T00:00:00Z',
      validTo: '2026-12-31T23:59:59Z',
      status: 'ACTIVE',
      statusLabel: 'Đang hoạt động',
    ),
    const CouponModel(
      couponId: 'v-3',
      code: 'AUTUMN2026',
      discountType: 'PERCENT',
      discountValue: 20,
      minOrderAmount: 300000,
      validFrom: '2026-09-01T00:00:00Z',
      validTo: '2026-11-30T23:59:59Z',
      status: 'UPCOMING',
      statusLabel: 'Sắp diễn ra',
    ),
    const CouponModel(
      couponId: 'v-4',
      code: 'EXPIRED50',
      discountType: 'FIXED',
      discountValue: 50000,
      minOrderAmount: 200000,
      validTo: '2025-12-31T23:59:59Z',
      status: 'EXPIRED',
      statusLabel: 'Hết hạn',
    ),
  ];

  testWidgets('displays loaded active vouchers and only active/upcoming tabs', (
    tester,
  ) async {
    useMobileViewport(tester);
    final repository = _FakeVoucherRepository()..mockVouchers = sampleVouchers;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [voucherRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: VoucherWalletScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify app bar title
    expect(find.text('Mã Khuyến Mãi'), findsOneWidget);
    expect(find.text('Ví ưu đãi và voucher đặt phòng AVORA'), findsOneWidget);

    // Verify active vouchers are displayed by default
    expect(find.text('SUMMER2026'), findsOneWidget);
    expect(find.text('-15%'), findsOneWidget);
    expect(find.text('AVORA100K'), findsOneWidget);
    expect(find.text('-100.000 ₫'), findsOneWidget);

    // Verify 'Tất cả' and 'Hết hạn' are removed
    expect(find.text('Tất cả'), findsNothing);
    expect(find.text('Hết hạn'), findsNothing);
    expect(find.text('EXPIRED50'), findsNothing);

    // Verify only 'Đang hoạt động' and 'Sắp diễn ra' tabs exist
    expect(find.text('Đang hoạt động'), findsWidgets);
    expect(find.text('Sắp diễn ra'), findsWidgets);
  });

  testWidgets('filter tabs toggle between active and upcoming', (
    tester,
  ) async {
    useMobileViewport(tester);
    final repository = _FakeVoucherRepository()..mockVouchers = sampleVouchers;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [voucherRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: VoucherWalletScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap 'Sắp diễn ra' tab
    final upcomingTab = find.widgetWithText(InkWell, 'Sắp diễn ra');
    await tester.tap(upcomingTab);
    await tester.pumpAndSettle();

    // Only AUTUMN2026 should be visible
    expect(find.text('AUTUMN2026'), findsOneWidget);
    expect(find.text('SUMMER2026'), findsNothing);
    expect(find.text('AVORA100K'), findsNothing);
    expect(find.text('EXPIRED50'), findsNothing);

    // Tap back to 'Đang hoạt động' tab
    final activeTab = find.widgetWithText(InkWell, 'Đang hoạt động');
    await tester.tap(activeTab);
    await tester.pumpAndSettle();

    expect(find.text('SUMMER2026'), findsOneWidget);
    expect(find.text('AVORA100K'), findsOneWidget);
    expect(find.text('AUTUMN2026'), findsNothing);
  });

  testWidgets('search filters vouchers by code or description', (
    tester,
  ) async {
    useMobileViewport(tester);
    final repository = _FakeVoucherRepository()..mockVouchers = sampleVouchers;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [voucherRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: VoucherWalletScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Enter search text '100K'
    await tester.enterText(find.byType(TextField), '100K');
    await tester.pumpAndSettle();

    expect(find.text('AVORA100K'), findsOneWidget);
    expect(find.text('SUMMER2026'), findsNothing);
    expect(find.text('EXPIRED50'), findsNothing);
  });

  testWidgets('displays empty state when list is empty', (tester) async {
    useMobileViewport(tester);
    final repository = _FakeVoucherRepository()..mockVouchers = [];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [voucherRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: VoucherWalletScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy mã khuyến mãi'), findsOneWidget);
  });

  testWidgets('displays error state and retry button on load failure', (
    tester,
  ) async {
    useMobileViewport(tester);
    final repository = _FakeVoucherRepository()
      ..shouldThrow = true
      ..errorMessage = 'Không thể kết nối đến máy chủ AVORA';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [voucherRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: VoucherWalletScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không thể kết nối đến máy chủ AVORA'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    // Recovery test: turn off error and tap retry
    repository.shouldThrow = false;
    repository.mockVouchers = sampleVouchers;

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('SUMMER2026'), findsOneWidget);
  });

  testWidgets('tapping copy icon displays snackbar feedback', (tester) async {
    useMobileViewport(tester);
    final repository = _FakeVoucherRepository()..mockVouchers = sampleVouchers;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [voucherRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: VoucherWalletScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap copy icon of the first voucher
    final copyIcons = find.byIcon(Icons.copy_rounded);
    expect(copyIcons, findsWidgets);

    await tester.tap(copyIcons.first);
    await tester.pump(); // Start snackbar animation

    expect(find.text('Đã sao chép mã SUMMER2026'), findsOneWidget);
  });
}
