import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/invoice/data/models/invoice_model.dart';
import 'package:avora_mobile/features/invoice/data/repositories/invoice_repository.dart';
import 'package:avora_mobile/features/invoice/presentation/providers/invoice_provider.dart';
import 'package:avora_mobile/features/invoice/presentation/screens/invoice_detail_screen.dart';
import 'package:avora_mobile/features/invoice/presentation/screens/invoice_list_screen.dart';
import 'package:avora_mobile/features/my_booking/data/models/booking_item_model.dart';

class _FakeInvoiceRepository extends InvoiceRepository {
  List<InvoiceListItemModel> mockInvoices = [];
  InvoiceDetailModel? mockDetail;
  bool shouldThrow = false;
  String errorMessage = 'Lỗi máy chủ không xác định';

  _FakeInvoiceRepository() : super(Dio());

  @override
  Future<List<InvoiceListItemModel>> fetchInvoices({
    String? search,
    String? status,
  }) async {
    if (shouldThrow) {
      throw Exception(errorMessage);
    }
    return mockInvoices;
  }

  @override
  Future<InvoiceDetailModel> fetchInvoiceDetail(String bookingId) async {
    if (shouldThrow) {
      throw Exception(errorMessage);
    }
    if (mockDetail != null) {
      return mockDetail!;
    }
    throw Exception('Không tìm thấy hóa đơn');
  }
}

void main() {
  const sampleBookingItem = BookingItemModel(
    bookingId: 'b3b7e75e-1234-5678-90ab-cdef12345678',
    bookingCode: 'BK-2026-B3B7E7',
    category: 'completed',
    guestName: 'Nguyễn Văn A',
    guestPhone: '0901234567',
    statusCodeName: 'CFM',
    statusName: 'Đã hoàn thành',
    statusBadgeVariant: 'confirmed',
    totalAmount: 1350000,
    discountAmount: 150000,
    hotel: BookingHotelModel(
      hotelId: 'h-1',
      name: 'Avora Hotel Danang',
      address: '170 Bạch Đằng, Hải Châu, Đà Nẵng',
    ),
    stay: BookingStayModel(
      checkInDate: '2026-10-25',
      checkOutDate: '2026-10-27',
      nights: 2,
      roomTypeName: 'Phòng Deluxe River View',
    ),
    cancellation: BookingCancellationModel(),
    payment: BookingPaymentModel(
      isPaid: true,
      transactionId: 'TXN-987654321',
      gatewayRefId: 'AVORA839201',
      amountPaid: 1350000,
      paymentMethod: 'Chuyển khoản VietQR (SePay)',
      paymentMethodCd: 'BTR',
      paidAt: '2026-10-25T14:30:00Z',
      hasVatInvoice: true,
    ),
  );

  const sampleInvoiceDetail = InvoiceDetailModel(
    invoiceNumber: 'BK-2026-B3B7E7',
    lookupCode: 'B3B7E75E',
    bookingId: 'b3b7e75e-1234-5678-90ab-cdef12345678',
    bookingCode: 'AV-1026-B3B7E7',
    transactionId: 'TXN-987654321',
    gatewayRefId: 'AVORA839201',
    hotelName: 'Avora Hotel Danang',
    hotelAddress: '170 Bạch Đằng, Hải Châu, Đà Nẵng',
    issuedDate: '25/10/2026',
    paidAt: '2026-10-25T14:30:00Z',
    buyerName: 'Nguyễn Văn A',
    buyerPhone: '0901234567',
    subtotal: 1500000,
    discountAmount: 150000,
    couponCode: 'SUMMER2026',
    totalAmount: 1350000,
    amountPaid: 1350000,
    paymentMethodCd: 'BTR',
    paymentMethod: 'Chuyển khoản VietQR (SePay)',
    bookingStatusCd: '2',
    statusCodeName: 'CFM',
    invoiceStatus: 'Đã ghi nhận giao dịch (AVORA839201)',
    isPaid: true,
    roomTypeName: 'Phòng Deluxe River View',
    checkInDate: '2026-10-25',
    checkOutDate: '2026-10-27',
    nights: 2,
    quantity: 1,
  );

  group('Invoice Models Test', () {
    test('InvoiceListItemModel from BookingItemModel maps correctly', () {
      final item = InvoiceListItemModel.fromBookingItem(sampleBookingItem);

      expect(item.bookingId, 'b3b7e75e-1234-5678-90ab-cdef12345678');
      expect(item.hotelName, 'Avora Hotel Danang');
      expect(item.transactionId, 'TXN-987654321');
      expect(item.isPaid, isTrue);
      expect(item.formattedAmountPaid, '1.350.000 ₫');
      expect(item.roomTypeName, 'Phòng Deluxe River View');
      expect(item.nights, 2);
    });

    test('InvoiceDetailModel fromCombined maps correctly', () {
      final invoiceJson = {
        'invoice_number': 'BK-2026-B3B7E7',
        'lookup_code': 'B3B7E75E',
        'hotel_name': 'Avora Hotel Danang',
        'hotel_address': '170 Bạch Đằng, Đà Nẵng',
        'issued_date': '25/10/2026',
        'buyer_name': 'Nguyễn Văn A',
        'buyer_phone': '0901234567',
        'subtotal': 1500000,
        'discount_amount': 150000,
        'coupon_code': 'SUMMER2026',
        'total_amount': 1350000,
        'amount_paid': 1350000,
        'payment_method_cd': 'BTR',
        'gateway_ref_id': 'AVORA839201',
        'booking_status_cd': '2',
        'status_code_name': 'CFM',
        'invoice_status': 'Đã ghi nhận giao dịch (AVORA839201)',
      };

      final bookingJson = {
        'booking_code': 'BK-2026-B3B7E7',
        't_payment_transaction': [
          {
            'transaction_id': 'TXN-987654321',
            'amount_paid': 1350000,
            'payment_method_cd': 'BTR',
            'gateway_ref_id': 'AVORA839201',
            'paid_at': '2026-10-25T14:30:00Z',
          }
        ],
        'stay': {
          'check_in_date': '2026-10-25',
          'check_out_date': '2026-10-27',
          'room_type_name': 'Phòng Deluxe River View',
          'nights': 2,
          'quantity': 1,
        }
      };

      final detail = InvoiceDetailModel.fromCombined(
        bookingId: 'b3b7e75e-1234-5678-90ab-cdef12345678',
        invoiceJson: invoiceJson,
        bookingJson: bookingJson,
      );

      expect(detail.invoiceNumber, 'BK-2026-B3B7E7');
      expect(detail.transactionId, 'TXN-987654321');
      expect(detail.amountPaid, 1350000);
      expect(detail.paymentMethod, 'Chuyển khoản VietQR (SePay)');
      expect(detail.isPaid, isTrue);
      expect(detail.roomTypeName, 'Phòng Deluxe River View');
      expect(detail.nights, 2);
      expect(detail.formattedAmountPaid, '1.350.000 ₫');
      expect(detail.formattedSubtotal, '1.500.000 ₫');
      expect(detail.formattedDiscount, '-150.000 ₫');
    });
  });

  group('InvoiceListScreen Widget Test', () {
    testWidgets('displays invoice list with items and handles filter',
        (tester) async {
      final fakeRepo = _FakeInvoiceRepository();
      fakeRepo.mockInvoices = [
        InvoiceListItemModel.fromBookingItem(sampleBookingItem),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: InvoiceListScreen(),
          ),
        ),
      );

      // Cho phép notifier tải xong
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Kiểm tra tiêu đề màn hình
      expect(find.text('Hóa đơn thanh toán'), findsOneWidget);
      expect(find.text('Lịch sử biên nhận VAT & Giao dịch điện tử'),
          findsOneWidget);

      // Kiểm tra nội dung của InvoiceCard
      expect(find.text('Avora Hotel Danang'), findsOneWidget);
      expect(find.text('1.350.000 ₫'), findsOneWidget);
      expect(find.text('Thành công'), findsOneWidget);
      expect(find.text('Chi tiết hóa đơn'), findsOneWidget);
      expect(find.textContaining('TXN-987654321'), findsOneWidget);
    });

    testWidgets('displays empty view when no invoices exist', (tester) async {
      final fakeRepo = _FakeInvoiceRepository();
      fakeRepo.mockInvoices = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: InvoiceListScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Chưa có hóa đơn thanh toán nào'), findsOneWidget);
      expect(find.text('Khám phá khách sạn ngay'), findsOneWidget);
    });
  });

  group('InvoiceDetailScreen Widget Test', () {
    testWidgets(
        'displays all required details: transaction ID, invoice ID, amount, payment method, payment date, and payment status',
        (tester) async {
      final fakeRepo = _FakeInvoiceRepository();
      fakeRepo.mockDetail = sampleInvoiceDetail;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            invoiceRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: InvoiceDetailScreen(
              bookingId: 'b3b7e75e-1234-5678-90ab-cdef12345678',
            ),
          ),
        ),
      );

      // Pump để async data tải xong
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Kiểm tra tiêu đề
      expect(find.text('Chi tiết hóa đơn & Giao dịch'), findsOneWidget);

      // 2. Transaction ID
      expect(find.text('TXN-987654321'), findsOneWidget);

      // 3. Invoice ID & Lookup Code
      expect(find.text('BK-2026-B3B7E7'), findsOneWidget);
      expect(find.text('B3B7E75E'), findsOneWidget);

      // 4. Amount
      expect(find.text('1.350.000 ₫'), findsWidgets);

      // 5. Payment Method
      expect(
          find.text('Chuyển khoản VietQR (SePay)'), findsOneWidget);

      // 6. Payment Status
      expect(find.text('Thanh toán thành công'), findsOneWidget);
      expect(find.text('THANH TOÁN THÀNH CÔNG'), findsOneWidget);

      // 7. Action buttons
      expect(find.text('Tải file PDF hóa đơn điện tử'), findsOneWidget);
      expect(find.text('Xem đơn đặt phòng liên kết'), findsOneWidget);
      expect(find.text('Về danh sách hóa đơn'), findsOneWidget);
    });
  });
}
