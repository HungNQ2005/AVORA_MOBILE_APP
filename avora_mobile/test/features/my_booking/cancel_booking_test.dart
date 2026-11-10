import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/auth/data/auth_model.dart';
import 'package:avora_mobile/features/my_booking/data/models/bank_model.dart';
import 'package:avora_mobile/features/my_booking/data/models/booking_item_model.dart';
import 'package:avora_mobile/features/my_booking/data/repositories/my_booking_repository.dart';
import 'package:avora_mobile/features/my_booking/presentation/providers/my_booking_provider.dart';
import 'package:avora_mobile/features/my_booking/presentation/widgets/cancel_booking_modal.dart';
import 'package:avora_mobile/features/my_booking/presentation/widgets/canceled_booking_card.dart';
import 'package:avora_mobile/features/my_booking/presentation/screens/my_booking_screen.dart';

// ─── Dummy / Fake Data ──────────────────────────────────────────────────────────

const kSampleBanks = [
  BankModel(
    bankCd: '101',
    codeName: 'VCB',
    bin: '970436',
    code: 'VCB',
    name: 'Ngân hàng TMCP Ngoại thương Việt Nam',
    shortName: 'Vietcombank',
    logoUrl: 'https://img.vietqr.io/image/vcb.png',
  ),
  BankModel(
    bankCd: '102',
    codeName: 'MBB',
    bin: '970422',
    code: 'MB',
    name: 'Ngân hàng TMCP Quân Đội',
    shortName: 'MB Bank',
    logoUrl: 'https://img.vietqr.io/image/mbb.png',
  ),
];

BookingItemModel createUnpaidBooking({
  String bookingId = 'bk-unpaid',
  num totalAmount = 1500000,
}) {
  return BookingItemModel(
    bookingId: bookingId,
    bookingCode: 'AV#20261109-001',
    category: 'upcoming',
    guestName: 'Nguyễn Văn A',
    guestPhone: '0901234567',
    statusCodeName: 'PND',
    statusName: 'Chờ thanh toán',
    statusBadgeVariant: 'amber',
    totalAmount: totalAmount,
    hotel: const BookingHotelModel(
      hotelId: 'h-1',
      name: 'Avora Riverside Hotel',
      address: '12 Bạch Đằng, Đà Nẵng',
    ),
    stay: const BookingStayModel(
      checkInDate: '2026-11-20',
      checkOutDate: '2026-11-22',
      nights: 2,
      roomTypeName: 'Phòng Deluxe',
    ),
    cancellation: const BookingCancellationModel(
      isFreeCancel: true,
      deadlineText: 'trước 48h',
      estimatedRefundAmount: 0,
      refundPercentage: 100,
    ),
    payment: const BookingPaymentModel(
      isPaid: false,
      amountPaid: 0,
    ),
  );
}

BookingItemModel createPaidBookingWithRefund({
  String bookingId = 'bk-paid',
  num totalAmount = 2000000,
  num refundPercentage = 100,
  num estimatedRefund = 2000000,
}) {
  return BookingItemModel(
    bookingId: bookingId,
    bookingCode: 'AV#20261109-002',
    category: 'upcoming',
    guestName: 'Trần Thị B',
    guestPhone: '0912345678',
    statusCodeName: 'CFM',
    statusName: 'Đã xác nhận & Đã thanh toán',
    statusBadgeVariant: 'confirmed',
    totalAmount: totalAmount,
    hotel: const BookingHotelModel(
      hotelId: 'h-2',
      name: 'Avora Grand Hotel Sài Gòn',
      address: '15 Lê Duẩn, Quận 1, TP. HCM',
    ),
    stay: const BookingStayModel(
      checkInDate: '2026-11-25',
      checkOutDate: '2026-11-27',
      nights: 2,
      roomTypeName: 'Phòng Suite Hướng Phố',
    ),
    cancellation: BookingCancellationModel(
      isFreeCancel: refundPercentage == 100,
      deadlineText: 'trước 24h',
      estimatedRefundAmount: estimatedRefund,
      refundPercentage: refundPercentage,
      policyNote: refundPercentage == 100
          ? 'Hủy trong thời hạn miễn phí (Hoàn 100%)'
          : 'Áp dụng phí hủy 30% theo chính sách khách sạn',
    ),
    payment: BookingPaymentModel(
      isPaid: true,
      amountPaid: totalAmount,
      totalPaidAmount: totalAmount,
      paymentMethod: 'Chuyển khoản ngân hàng',
    ),
  );
}

void main() {
  group('sanitizeAccountHolder Tests', () {
    test('removes Vietnamese accents and converts to uppercase', () {
      expect(sanitizeAccountHolder('Nguyễn Văn An'), 'NGUYEN VAN AN');
      expect(sanitizeAccountHolder('đỗ thị mỹ duyên'), 'DO THI MY DUYEN');
      expect(sanitizeAccountHolder('LÊ VĂN HƯNG'), 'LE VAN HUNG');
      expect(sanitizeAccountHolder('Trần Quốc Tuấn'), 'TRAN QUOC TUAN');
    });

    test('handles empty or whitespace string', () {
      expect(sanitizeAccountHolder(''), '');
      expect(sanitizeAccountHolder('   '), '   ');
    });
  });

  group('BankModel Tests', () {
    test('parses from JSON correctly', () {
      final json = {
        'bank_cd': '101',
        'code_name': 'VCB',
        'bin_code': '970436',
        'name': 'Ngân hàng TMCP Ngoại thương Việt Nam',
        'short_name': 'Vietcombank',
        'logo_url': 'https://vietqr.net/vcb.png',
      };

      final bank = BankModel.fromJson(json);
      expect(bank.bankCd, '101');
      expect(bank.codeName, 'VCB');
      expect(bank.effectiveBin, '970436');
      expect(bank.shortName, 'Vietcombank');
      expect(bank.fullNameWithShort, 'Ngân hàng TMCP Ngoại thương Việt Nam (Vietcombank)');
    });

    test('matches search query by shortName, fullName, BIN, or code', () {
      final bank = kSampleBanks[0]; // Vietcombank, BIN 970436, VCB
      expect(bank.matches('vietcom'), isTrue);
      expect(bank.matches('VCB'), isTrue);
      expect(bank.matches('970436'), isTrue);
      expect(bank.matches('Ngoại thương'), isTrue);
      expect(bank.matches('Techcombank'), isFalse);
    });
  });

  group('CancelBookingModal - Case 1: Đơn chưa thanh toán / Hoàn 0đ', () {
    testWidgets('renders warning box, reason dropdown, and red cancel button',
        (tester) async {
      final unpaidBooking = createUnpaidBooking();
      var confirmed = false;
      String? capturedReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CancelBookingModal(
              booking: unpaidBooking,
              onConfirmCancel: ({
                required String reason,
                String? bankCd,
                String? bankName,
                String? bankBin,
                String? accountNumber,
                String? accountHolder,
              }) async {
                confirmed = true;
                capturedReason = reason;
                return true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header
      expect(find.text('Xác nhận hủy đặt phòng'), findsOneWidget);
      expect(find.textContaining('Mã đơn: #AV#20261109-001'), findsOneWidget);

      // Warning Box
      expect(find.text('Bạn có chắc chắn muốn hủy đặt phòng?'), findsOneWidget);
      expect(
        find.textContaining('Đơn đặt phòng này hiện chưa thanh toán'),
        findsOneWidget,
      );

      // Does NOT show bank form in Case 1
      expect(find.text('Thông tin tài khoản nhận tiền hoàn'), findsNothing);
      expect(find.text('Ngân hàng nhận tiền *'), findsNothing);

      // Action button
      expect(find.text('Xác nhận hủy phòng'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Xác nhận hủy phòng'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(capturedReason, 'Khách thay đổi kế hoạch chuyến đi');
    });

    testWidgets('choosing "Khác" validates custom reason cannot be empty',
        (tester) async {
      final unpaidBooking = createUnpaidBooking();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CancelBookingModal(
              booking: unpaidBooking,
              onConfirmCancel: ({
                required String reason,
                String? bankCd,
                String? bankName,
                String? bankBin,
                String? accountNumber,
                String? accountHolder,
              }) async =>
                  true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open dropdown and pick 'Khác'
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Khác').last);
      await tester.pumpAndSettle();

      // Custom reason textfield is now visible
      expect(
        find.widgetWithText(TextField, 'Vui lòng nhập lý do hủy phòng của bạn...'),
        findsOneWidget,
      );

      // Submit without entering text -> Error
      await tester.tap(find.text('Xác nhận hủy phòng'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập lý do hủy phòng cụ thể.'), findsOneWidget);

      // Enter valid custom reason
      await tester.enterText(
        find.widgetWithText(TextField, 'Vui lòng nhập lý do hủy phòng của bạn...'),
        'Chuyến bay bị hủy do thời tiết xấu',
      );
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập lý do hủy phòng cụ thể.'), findsNothing);
    });
  });

  group('CancelBookingModal - Case 2: Đơn đã thanh toán & Hoàn tiền > 0đ', () {
    testWidgets('renders refund banner, bank form, and preselects user info',
        (tester) async {
      final paidBooking = createPaidBookingWithRefund(
        totalAmount: 2000000,
        refundPercentage: 100,
        estimatedRefund: 2000000,
      );

      const user = UserModel(
        userId: 'u-1',
        email: 'customer@avora.vn',
        fullName: 'Nguyễn Văn An',
        refundBankCd: '101',
        refundAccountNumber: '0987654321',
        refundAccountHolder: 'NGUYEN VAN AN',
      );

      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CancelBookingModal(
                booking: paidBooking,
                user: user,
                initialBanks: kSampleBanks,
                onConfirmCancel: ({
                  required String reason,
                  String? bankCd,
                  String? bankName,
                  String? bankBin,
                  String? accountNumber,
                  String? accountHolder,
                }) async {
                  submittedData = {
                    'reason': reason,
                    'bankCd': bankCd,
                    'bankName': bankName,
                    'bankBin': bankBin,
                    'accountNumber': accountNumber,
                    'accountHolder': accountHolder,
                  };
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header
      expect(find.text('Yêu cầu hủy phòng & Hoàn tiền'), findsOneWidget);

      // Refund Banner
      expect(find.text('THÔNG TIN HOÀN TIỀN'), findsOneWidget);
      expect(find.text('Hoàn 100% giá trị đơn'), findsOneWidget);
      expect(find.text('2.000.000 ₫'), findsOneWidget);

      // Bank form section title
      expect(find.text('Thông tin tài khoản nhận tiền hoàn'), findsOneWidget);

      // Prefilled bank
      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('0987654321'), findsOneWidget);
      expect(find.text('NGUYEN VAN AN'), findsOneWidget);

      // Submit action button
      expect(find.text('Xác nhận gửi yêu cầu hoàn tiền'), findsOneWidget);

      await tester.tap(find.text('Xác nhận gửi yêu cầu hoàn tiền'));
      await tester.pumpAndSettle();

      expect(submittedData, isNotNull);
      expect(submittedData!['bankCd'], '101');
      expect(submittedData!['bankBin'], '970436');
      expect(submittedData!['accountNumber'], '0987654321');
      expect(submittedData!['accountHolder'], 'NGUYEN VAN AN');
      expect(submittedData!['reason'], 'Khách thay đổi kế hoạch chuyến đi');
    });

    testWidgets('validates required bank, account number, and holder name',
        (tester) async {
      final paidBooking = createPaidBookingWithRefund();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CancelBookingModal(
                booking: paidBooking,
                initialBanks: kSampleBanks,
                onConfirmCancel: ({
                  required String reason,
                  String? bankCd,
                  String? bankName,
                  String? bankBin,
                  String? accountNumber,
                  String? accountHolder,
                }) async =>
                    true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Submit with empty fields
      await tester.tap(find.text('Xác nhận gửi yêu cầu hoàn tiền'));
      await tester.pumpAndSettle();

      // Verify all validation messages
      expect(
        find.text('Vui lòng chọn ngân hàng nhận tiền hoàn từ danh sách hệ thống.'),
        findsOneWidget,
      );
      expect(
        find.text('Vui lòng nhập số tài khoản ngân hàng hợp lệ (từ 6 đến 25 chữ số).'),
        findsOneWidget,
      );
      expect(
        find.text('Vui lòng nhập tên chủ tài khoản (viết hoa không dấu).'),
        findsOneWidget,
      );
    });
  });

  group('CanceledBookingCard Tests', () {
    testWidgets('renders cancellation date, status, reason alert, and refund info',
        (tester) async {
      final cancelledBooking = BookingItemModel(
        bookingId: 'bk-can-1',
        bookingCode: 'AV#20261015-CAN',
        category: 'cancelled',
        guestName: 'Phạm Văn C',
        guestPhone: '0987112233',
        statusCodeName: 'CAN',
        statusName: 'Đã hủy phòng',
        statusBadgeVariant: 'cancelled',
        totalAmount: 1200000,
        createdAt: '2026-10-15T08:00:00Z',
        cancellationReason: 'Khách đổi lịch trình công tác đột xuất',
        hotel: const BookingHotelModel(
          hotelId: 'h-1',
          name: 'Avora Boutique Hotel Hội An',
          address: '45 Trần Phú, Hội An',
        ),
        stay: const BookingStayModel(
          checkInDate: '2026-10-20',
          checkOutDate: '2026-10-22',
          nights: 2,
          roomTypeName: 'Phòng Superior',
        ),
        cancellation: const BookingCancellationModel(),
        payment: const BookingPaymentModel(isPaid: true, amountPaid: 1200000),
        refund: const BookingRefundModel(
          refundId: 'ref-1',
          refundAmount: 1200000,
          refundStatusLabel: 'Hoàn tiền thành công',
          gatewayRefundRef: 'REF-970422-BK1',
          reason: 'Hủy trong thời hạn miễn phí',
        ),
      );

      var rebooked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanceledBookingCard(
              booking: cancelledBooking,
              onRebook: () => rebooked = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Avora Boutique Hotel Hội An'), findsOneWidget);
      expect(find.textContaining('Đã hủy ngày 2026-10-15'), findsOneWidget);
      expect(find.textContaining('Đã hủy phòng • Hoàn tiền thành công'), findsOneWidget);
      expect(find.textContaining('Lý do hủy: Khách đổi lịch trình công tác đột xuất'), findsOneWidget);
      expect(find.textContaining('Số tiền hoàn lại: 1.200.000 ₫'), findsOneWidget);
      expect(find.textContaining('Mã tham chiếu: REF-970422-BK1'), findsOneWidget);

      // Rebook button
      await tester.tap(find.text('Tìm lại chỗ nghỉ'));
      await tester.pumpAndSettle();

      expect(rebooked, isTrue);
    });
  });

  group('CancelBooking - Bank Picker Search & Select', () {
    testWidgets('opens bank picker, filters by query, and selects bank',
        (tester) async {
      final paidBooking = createPaidBookingWithRefund();
      BankModel? capturedBank;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CancelBookingModal(
                booking: paidBooking,
                initialBanks: kSampleBanks,
                onConfirmCancel: ({
                  required String reason,
                  String? bankCd,
                  String? bankName,
                  String? bankBin,
                  String? accountNumber,
                  String? accountHolder,
                }) async {
                  capturedBank = kSampleBanks.firstWhere((b) => b.bankCd == bankCd);
                  return true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially "Chọn ngân hàng nhận tiền..."
      expect(find.text('Chọn ngân hàng nhận tiền...'), findsOneWidget);

      // Tap to open picker
      await tester.tap(find.text('Chọn ngân hàng nhận tiền...'));
      await tester.pumpAndSettle();

      // Bottom sheet is open
      expect(find.text('Chọn ngân hàng nhận tiền'), findsOneWidget);
      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('MB Bank'), findsOneWidget);

      // Search for "Quân Đội"
      await tester.enterText(
        find.byKey(const Key('bank_search_input')),
        'Quân Đội',
      );
      await tester.pumpAndSettle();

      // Vietcombank is filtered out, MB Bank remains
      expect(find.text('MB Bank'), findsOneWidget);
      expect(find.text('Vietcombank'), findsNothing);

      // Tap MB Bank
      await tester.tap(find.text('MB Bank'));
      await tester.pumpAndSettle();

      // Sheet closes, trigger displays MB Bank
      expect(find.text('MB Bank'), findsOneWidget);
      expect(find.text('Mã BIN: 970422'), findsOneWidget);

      // Enter account info
      await tester.enterText(
        find.widgetWithText(TextField, 'Ví dụ: 0987654321'),
        '1234567890',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'VD: NGUYEN VAN A'),
        'nguyen van an',
      );
      await tester.pumpAndSettle();

      // Text in account holder field should be uppercase
      expect(find.text('NGUYEN VAN AN'), findsOneWidget);

      // Submit
      await tester.tap(find.text('Xác nhận gửi yêu cầu hoàn tiền'));
      await tester.pumpAndSettle();

      expect(capturedBank, isNotNull);
      expect(capturedBank!.bankCd, '102');
      expect(capturedBank!.shortName, 'MB Bank');
    });
  });

  group('MyBookingRepository - Network & Payload Tests', () {
    test('fetchRefundBanks fetches from /bookings/banks successfully', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/bookings/banks') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'success',
                    'data': [
                      {
                        'bank_cd': '101',
                        'code_name': 'VCB',
                        'bin': '970436',
                        'short_name': 'Vietcombank',
                        'name': 'Ngân hàng TMCP Ngoại thương Việt Nam',
                      }
                    ],
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final repo = MyBookingRepository(dio);
      final banks = await repo.fetchRefundBanks();
      expect(banks.length, 1);
      expect(banks[0].shortName, 'Vietcombank');
      expect(banks[0].effectiveBin, '970436');
    });

    test('fetchRefundBanks falls back to /wallet/banks when /bookings/banks fails', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/bookings/banks') {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(requestOptions: options, statusCode: 500),
                ),
              );
            }
            if (options.path == '/wallet/banks') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'success',
                    'data': [
                      {
                        'code_cd': '102',
                        'code_name': 'MBB',
                        'bin_code': '970422',
                        'short_name': 'MB Bank',
                        'name': 'Ngân hàng TMCP Quân Đội',
                      }
                    ],
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final repo = MyBookingRepository(dio);
      final banks = await repo.fetchRefundBanks();
      expect(banks.length, 1);
      expect(banks[0].shortName, 'MB Bank');
      expect(banks[0].effectiveBin, '970422');
    });

    test('cancelBooking sends complete Case 2 payload to /bookings/:id/cancel', () async {
      final dio = Dio();
      RequestOptions? sentOptions;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sentOptions = options;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'status': 'success',
                  'message': 'Đã gửi yêu cầu hủy đặt phòng và hoàn tiền thành công.',
                },
              ),
            );
          },
        ),
      );

      final repo = MyBookingRepository(dio);
      final msg = await repo.cancelBooking(
        'bk-123',
        reason: 'Khách thay đổi kế hoạch chuyến đi',
        bankCd: '101',
        bankName: 'Ngân hàng TMCP Ngoại thương Việt Nam (Vietcombank)',
        bankBin: '970436',
        accountNumber: '0987654321',
        accountHolder: 'NGUYEN VAN AN',
      );

      expect(msg, 'Đã gửi yêu cầu hủy đặt phòng và hoàn tiền thành công.');
      expect(sentOptions, isNotNull);
      expect(sentOptions!.path, '/bookings/bk-123/cancel');
      final payload = sentOptions!.data as Map;
      expect(payload['reason'], 'Khách thay đổi kế hoạch chuyến đi');
      expect(payload['bank_cd'], '101');
      expect(payload['bank_bin'], '970436');
      expect(payload['account_number'], '0987654321');
      expect(payload['account_holder'], 'NGUYEN VAN AN');
    });
  });

  group('MyBookingNotifier - cancelBooking State & Lifecycle', () {
    test('updates state on successful cancelBooking and reloads bookings', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/bookings/my') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'success',
                    'data': {
                      'bookings': [],
                      'counts': {'all': 0, 'upcoming': 0, 'completed': 0, 'cancelled': 0},
                      'available_years': [2026],
                    },
                  },
                ),
              );
            }
            if (options.path.contains('/cancel')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'success',
                    'message': 'Đã hủy đặt phòng thành công.',
                  },
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final repo = MyBookingRepository(dio);
      final notifier = MyBookingNotifier(repo);

      // Initial load settle
      await Future.delayed(const Duration(milliseconds: 50));

      final success = await notifier.cancelBooking(
        'bk-test',
        reason: 'Lý do sức khỏe đột xuất',
      );

      expect(success, isTrue);
      expect(notifier.state.isActionLoading, isFalse);
      expect(notifier.state.actionSuccessMessage, 'Đã hủy đặt phòng thành công.');
      expect(notifier.state.errorMessage, isNull);
    });

    test('handles cancelBooking API failure and captures error message', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/bookings/my') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'success',
                    'data': {
                      'bookings': [],
                      'counts': {'all': 0, 'upcoming': 0, 'completed': 0, 'cancelled': 0},
                      'available_years': [2026],
                    },
                  },
                ),
              );
            }
            if (options.path.contains('/cancel')) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 400,
                    data: {
                      'status': 'error',
                      'message': 'Chỉ có thể hủy đơn trước ngày nhận phòng ít nhất 24h.',
                    },
                  ),
                ),
              );
            }
            return handler.next(options);
          },
        ),
      );

      final repo = MyBookingRepository(dio);
      final notifier = MyBookingNotifier(repo);
      await Future.delayed(const Duration(milliseconds: 50));

      final success = await notifier.cancelBooking(
        'bk-test',
        reason: 'Khách thay đổi kế hoạch',
      );

      expect(success, isFalse);
      expect(notifier.state.isActionLoading, isFalse);
      expect(
        notifier.state.errorMessage,
        'Chỉ có thể hủy đơn trước ngày nhận phòng ít nhất 24h.',
      );
    });
  });

  group('MyBookingScreen - End-to-End Cancel Flow', () {
    testWidgets('tapping Hủy phòng opens modal and confirming triggers cancellation',
        (tester) async {
      final unpaid = createUnpaidBooking(bookingId: 'bk-upcoming-1');
      final repo = _FakeCancelFlowRepository(unpaid);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myBookingRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: MyBookingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Card is displayed
      expect(find.text('Avora Riverside Hotel'), findsOneWidget);
      expect(find.text('Hủy phòng'), findsOneWidget);

      // Tap "Hủy phòng"
      await tester.tap(find.text('Hủy phòng'));
      await tester.pumpAndSettle();

      // Modal is open
      expect(find.text('Xác nhận hủy đặt phòng'), findsOneWidget);
      expect(find.text('Bạn có chắc chắn muốn hủy đặt phòng?'), findsOneWidget);

      // Confirm cancel
      await tester.tap(find.text('Xác nhận hủy phòng'));
      await tester.pumpAndSettle();

      expect(repo.cancelCalled, isTrue);
      expect(repo.cancelPayload?['reason'], 'Khách thay đổi kế hoạch chuyến đi');
      // Modal dismissed
      expect(find.text('Bạn có chắc chắn muốn hủy đặt phòng?'), findsNothing);
    });
  });
}

class _FakeCancelFlowRepository extends MyBookingRepository {
  final BookingItemModel booking;
  bool cancelCalled = false;
  Map<String, dynamic>? cancelPayload;

  _FakeCancelFlowRepository(this.booking) : super(Dio());

  @override
  Future<BookingListResponse> fetchMyBookings({
    String? status,
    String? search,
    String? timeRange,
    String? userId,
  }) async {
    return BookingListResponse(
      bookings: [booking],
      counts: const BookingCountsModel(all: 1, upcoming: 1),
    );
  }

  @override
  Future<String> cancelBooking(
    String bookingId, {
    required String reason,
    String? bankCd,
    String? bankName,
    String? bankBin,
    String? accountNumber,
    String? accountHolder,
  }) async {
    cancelCalled = true;
    cancelPayload = {
      'reason': reason,
      'bankCd': bankCd,
      'bankName': bankName,
      'bankBin': bankBin,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
    };
    return 'Đã hủy đơn đặt phòng thành công!';
  }
}
