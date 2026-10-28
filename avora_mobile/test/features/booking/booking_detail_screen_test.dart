import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/booking/data/models/booking_detail_model.dart';
import 'package:avora_mobile/features/booking/presentation/providers/booking_detail_provider.dart';
import 'package:avora_mobile/features/booking/presentation/screens/booking_detail_screen.dart';

void main() {
  const testBookingId = 'bk-test-123';

  final testBooking = BookingDetailModel(
    bookingId: testBookingId,
    bookingCode: 'AV-1026-TEST',
    userId: 'u1',
    hotelId: 'h1',
    hotelName: 'Avora Grand Resort & Spa',
    hotelAddress: '123 Đường Biển, Đà Nẵng',
    hotelStarQuality: 5,
    guestName: 'Nguyễn Văn A',
    guestPhone: '0901234567',
    specialRequest: 'Phòng tầng cao view biển',
    roomTypeName: 'Phòng Deluxe Ocean View',
    bedType: '1 giường đôi lớn',
    roomSize: '36m²',
    maxAdults: 2,
    maxChildren: 1,
    quantity: 1,
    unitPrice: 1200000,
    checkInDate: '2026-11-15',
    checkOutDate: '2026-11-17',
    nights: 2,
    totalAmount: 2400000,
    discountAmount: 200000,
    couponCode: 'AVORA200',
    bookingStatusCd: '2',
    statusCodeName: 'CFM',
    statusName: 'Đã xác nhận & Đã thanh toán',
    statusBadgeVariant: 'confirmed',
    isPaid: true,
    paymentMethod: 'Chuyển khoản ngân hàng',
    cancellationPolicyDescription: 'Miễn phí hủy trước 48h.',
  );

  Widget createWidget({
    required Override overrideProvider,
  }) {
    return ProviderScope(
      overrides: [overrideProvider],
      child: const MaterialApp(
        home: BookingDetailScreen(bookingId: testBookingId),
      ),
    );
  }

  group('BookingDetailScreen', () {
    testWidgets('displays loading view when async state is loading', (tester) async {
      final completer = Completer<BookingDetailModel>();

      await tester.pumpWidget(
        createWidget(
          overrideProvider: bookingDetailProvider(testBookingId).overrideWith(
            (_) => completer.future,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đang tải thông tin đơn đặt phòng...'), findsOneWidget);
    });

    testWidgets('displays error view with retry button when error occurs', (tester) async {
      await tester.pumpWidget(
        createWidget(
          overrideProvider: bookingDetailProvider(testBookingId).overrideWith(
            (_) => Future.error(Exception('Không thể kết nối đến máy chủ.')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không thể tải chi tiết đặt phòng'), findsOneWidget);
      expect(find.textContaining('Không thể kết nối đến máy chủ.'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets('displays all booking details, status, and check-in/out schedule on success', (tester) async {
      await tester.pumpWidget(
        createWidget(
          overrideProvider: bookingDetailProvider(testBookingId).overrideWith(
            (_) async => testBooking,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tiêu đề AppBar
      expect(find.text('Chi tiết đơn đặt phòng'), findsOneWidget);

      // Mã đặt phòng và trạng thái
      expect(find.text('#AV-1026-TEST'), findsOneWidget);
      expect(find.text('Đã xác nhận & Đã thanh toán'), findsOneWidget);

      // Lịch trình lưu trú: Nhận & Trả phòng
      expect(find.text('Lịch trình lưu trú'), findsOneWidget);
      expect(find.text('NHẬN PHÒNG'), findsOneWidget);
      expect(find.text('Từ 14:00'), findsOneWidget);
      expect(find.text('TRẢ PHÒNG'), findsOneWidget);
      expect(find.text('Trước 12:00'), findsOneWidget);
      expect(find.text('2 đêm'), findsOneWidget);

      // Thông tin khách sạn & phòng
      expect(find.text('Avora Grand Resort & Spa'), findsOneWidget);
      expect(find.text('123 Đường Biển, Đà Nẵng'), findsOneWidget);
      expect(find.text('Phòng Deluxe Ocean View'), findsOneWidget);
      expect(find.text('1 giường đôi lớn'), findsOneWidget);
      expect(find.text('36m²'), findsOneWidget);
      expect(find.text('1 phòng'), findsOneWidget);

      // Thông tin khách
      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.text('0901234567'), findsOneWidget);
      expect(find.text('Phòng tầng cao view biển'), findsOneWidget);

      // Chi tiết thanh toán
      expect(find.text('Chi tiết giá & Thanh toán'), findsOneWidget);
      expect(find.text('AVORA200'), findsOneWidget);
      expect(find.text('Tổng thanh toán:'), findsOneWidget);
      expect(find.text('2.400.000 ₫'), findsNWidgets(2));
      expect(find.text('Đã thanh toán qua Chuyển khoản ngân hàng'), findsOneWidget);

      // Chính sách & Nút điều hướng
      expect(find.text('Chính sách & Hướng dẫn'), findsOneWidget);
      expect(find.text('Về danh sách đặt chỗ'), findsOneWidget);
      expect(find.text('Về trang chủ'), findsOneWidget);
    });
  });
}
