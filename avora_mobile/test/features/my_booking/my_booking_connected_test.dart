import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/booking/data/models/booking_detail_model.dart';
import 'package:avora_mobile/features/booking/presentation/providers/booking_detail_provider.dart';
import 'package:avora_mobile/features/my_booking/presentation/screens/my_booking_screen.dart';

void main() {
  final testUpcomingBooking = BookingDetailModel(
    bookingId: 'bk-upcoming-1',
    bookingCode: 'AV-1026-UP01',
    userId: 'u1',
    hotelId: 'h1',
    hotelName: 'Khách sạn Biển Xanh',
    hotelAddress: 'Đà Nẵng',
    guestName: 'Nguyễn Văn A',
    guestPhone: '0912345678',
    roomTypeName: 'Phòng Deluxe Giường Đôi',
    checkInDate: '2026-11-20',
    checkOutDate: '2026-11-22',
    nights: 2,
    totalAmount: 1600000,
    bookingStatusCd: '2',
    statusCodeName: 'CFM',
    statusName: 'Đã xác nhận đặt chỗ',
    statusBadgeVariant: 'confirmed',
  );

  final testHistoryBooking = BookingDetailModel(
    bookingId: 'bk-history-1',
    bookingCode: 'AV-1026-HI01',
    userId: 'u1',
    hotelId: 'h2',
    hotelName: 'Khách sạn Phố Cổ Hội An',
    hotelAddress: 'Hội An',
    guestName: 'Nguyễn Văn A',
    guestPhone: '0912345678',
    roomTypeName: 'Phòng Superior',
    checkInDate: '2026-09-10',
    checkOutDate: '2026-09-12',
    nights: 2,
    totalAmount: 1200000,
    bookingStatusCd: '2',
    statusCodeName: 'CFM',
    statusName: 'Đã hoàn thành lưu trú',
    statusBadgeVariant: 'completed',
  );

  testWidgets('renders list of real bookings and switches tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myAllBookingsProvider.overrideWith(
            (_) async => [testUpcomingBooking, testHistoryBooking],
          ),
        ],
        child: const MaterialApp(home: MyBookingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tab "Sắp tới" hiển thị đơn sắp tới
    expect(find.text('#AV-1026-UP01'), findsOneWidget);
    expect(find.text('Khách sạn Biển Xanh'), findsOneWidget);
    expect(find.text('Đã xác nhận đặt chỗ'), findsOneWidget);
    expect(find.text('1.600.000 ₫'), findsOneWidget);
    expect(find.text('Xem chi tiết'), findsOneWidget);

    // Chuyển sang Tab "Lịch sử"
    await tester.tap(find.text('Lịch sử'));
    await tester.pumpAndSettle();

    // Tab "Lịch sử" hiển thị đơn đã hoàn thành
    expect(find.text('#AV-1026-HI01'), findsOneWidget);
    expect(find.text('Khách sạn Phố Cổ Hội An'), findsOneWidget);
    expect(find.text('Đã hoàn thành lưu trú'), findsOneWidget);
    expect(find.text('1.200.000 ₫'), findsOneWidget);
  });
}
