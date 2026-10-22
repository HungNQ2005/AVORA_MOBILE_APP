import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/my_booking/data/models/booking_item_model.dart';
import 'package:avora_mobile/features/my_booking/data/repositories/my_booking_repository.dart';
import 'package:avora_mobile/features/my_booking/presentation/screens/my_booking_screen.dart';

class _FakeMyBookingRepository extends MyBookingRepository {
  _FakeMyBookingRepository() : super(Dio());

  BookingListResponse responseData = BookingListResponse(
    bookings: [
      const BookingItemModel(
        bookingId: 'bk-1',
        bookingCode: 'AV#20261021-001',
        category: 'upcoming',
        guestName: 'Nguyễn Văn A',
        guestPhone: '0912345678',
        statusCodeName: 'CFM',
        statusName: 'Đã xác nhận & Đã thanh toán',
        statusBadgeVariant: 'confirmed',
        totalAmount: 1850000,
        discountAmount: 150000,
        hotel: BookingHotelModel(
          hotelId: 'h-1',
          name: 'Avora Resort & Spa Đà Nẵng',
          address: '28 Võ Nguyên Giáp, Đà Nẵng',
          starQuality: 5,
        ),
        stay: BookingStayModel(
          checkInDate: '2026-11-10',
          checkOutDate: '2026-11-12',
          nights: 2,
          daysLeftText: '20 ngày nữa',
          isUpcoming: true,
          roomTypeName: 'Phòng Deluxe Hướng Biển',
          quantity: 1,
        ),
        cancellation: BookingCancellationModel(
          isFreeCancel: true,
          deadlineText: 'trước 48h',
          estimatedRefundAmount: 1850000,
          refundPercentage: 100,
        ),
        payment: BookingPaymentModel(
          isPaid: true,
          amountPaid: 1850000,
          paymentMethod: 'Chuyển khoản ngân hàng',
          hasVatInvoice: true,
        ),
      ),
      const BookingItemModel(
        bookingId: 'bk-2',
        bookingCode: 'AV#20260910-002',
        category: 'completed',
        guestName: 'Nguyễn Văn A',
        guestPhone: '0912345678',
        statusCodeName: 'CFM',
        statusName: 'Đã hoàn thành lưu trú',
        statusBadgeVariant: 'success',
        totalAmount: 2200000,
        hotel: BookingHotelModel(
          hotelId: 'h-2',
          name: 'Avora Grand Hotel Sài Gòn',
          address: '15 Lê Duẩn, Quận 1, TP. HCM',
          starQuality: 4,
        ),
        stay: BookingStayModel(
          checkInDate: '2026-09-10',
          checkOutDate: '2026-09-12',
          nights: 2,
          roomTypeName: 'Phòng Executive Suite',
          quantity: 1,
        ),
        cancellation: BookingCancellationModel(),
        payment: BookingPaymentModel(
          isPaid: true,
          amountPaid: 2200000,
          paymentMethod: 'Thẻ tín dụng',
        ),
      ),
    ],
    counts: const BookingCountsModel(
      all: 2,
      upcoming: 1,
      completed: 1,
      cancelled: 0,
    ),
    availableYears: const [2026],
  );

  @override
  Future<BookingListResponse> fetchMyBookings({
    String? status,
    String? search,
    String? timeRange,
    String? userId,
  }) async {
    var filtered = responseData.bookings;
    if (status != null && status != 'all') {
      filtered = filtered.where((b) => b.category == status).toList();
    }
    if (search != null && search.isNotEmpty) {
      filtered = filtered
          .where((b) =>
              b.bookingCode.contains(search) ||
              b.hotel.name.toLowerCase().contains(search.toLowerCase()))
          .toList();
    }

    return BookingListResponse(
      bookings: filtered,
      counts: responseData.counts,
      availableYears: responseData.availableYears,
    );
  }

  @override
  Future<BookingVoucherModel> fetchBookingVoucher(String bookingId) async {
    return const BookingVoucherModel(
      bookingId: 'bk-1',
      bookingCode: 'AV#20261021-001',
      voucherCode: 'AV#20261021-001',
      bookingDate: '21/10/2026',
      statusCodeName: 'CFM',
      isPaid: true,
      qrData: 'AVORABK:bk-1:AV#20261021-001',
      hotelName: 'Avora Resort & Spa Đà Nẵng',
      hotelAddress: '28 Võ Nguyên Giáp, Đà Nẵng',
      guestName: 'Nguyễn Văn A',
      guestPhone: '0912345678',
      checkInDate: '2026-11-10',
      checkOutDate: '2026-11-12',
      nights: 2,
      roomTypeName: 'Phòng Deluxe Hướng Biển',
      totalAmount: 1850000,
      paymentMethod: 'Chuyển khoản ngân hàng',
    );
  }
}

void main() {
  testWidgets('displays title, status tabs, and loaded bookings',
      (tester) async {
    final fakeRepo = _FakeMyBookingRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myBookingRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: MyBookingScreen(),
        ),
      ),
    );

    // Initial pump & settle for loading
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Quản lý Đặt Chỗ & Lịch Sử'), findsOneWidget);
    expect(find.text('Tất cả đơn'), findsOneWidget);
    expect(find.text('Sắp tới'), findsOneWidget);
    expect(find.text('Đã hoàn thành'), findsOneWidget);
    expect(find.text('Đã hủy'), findsOneWidget);

    // Check hotel names
    expect(find.text('Avora Resort & Spa Đà Nẵng'), findsOneWidget);
    expect(find.text('AV#20261021-001'), findsOneWidget);
    expect(find.text('Chuyến Đi Sắp Tới'), findsOneWidget);
  });

  testWidgets('switches to Sắp tới tab and filters list', (tester) async {
    final fakeRepo = _FakeMyBookingRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myBookingRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: MyBookingScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on Sắp tới tab
    await tester.tap(find.text('Sắp tới'));
    await tester.pumpAndSettle();

    expect(find.text('Avora Resort & Spa Đà Nẵng'), findsOneWidget);
  });
}
