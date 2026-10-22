import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/my_booking/data/models/booking_item_model.dart';
import 'package:avora_mobile/features/my_booking/data/repositories/my_booking_repository.dart';
import 'package:avora_mobile/features/my_booking/presentation/screens/my_booking_screen.dart';

class _FakeMyBookingRepository extends MyBookingRepository {
  _FakeMyBookingRepository() : super(Dio());

  final _bookings = const [
    BookingItemModel(
      bookingId: 'upcoming-1',
      bookingCode: 'AV-1026-UP01',
      category: 'upcoming',
      guestName: 'Nguyễn Văn A',
      guestPhone: '0912345678',
      statusCodeName: 'CFM',
      statusName: 'Đã xác nhận đặt chỗ',
      statusBadgeVariant: 'confirmed',
      totalAmount: 1600000,
      hotel: BookingHotelModel(
        hotelId: 'h1',
        name: 'Khách sạn Biển Xanh',
        address: 'Đà Nẵng',
      ),
      stay: BookingStayModel(
        checkInDate: '2026-11-20',
        checkOutDate: '2026-11-22',
        nights: 2,
        roomTypeName: 'Phòng Deluxe',
      ),
      cancellation: BookingCancellationModel(),
      payment: BookingPaymentModel(),
    ),
    BookingItemModel(
      bookingId: 'completed-1',
      bookingCode: 'AV-1026-HI01',
      category: 'completed',
      guestName: 'Nguyễn Văn A',
      guestPhone: '0912345678',
      statusCodeName: 'CFM',
      statusName: 'Đã hoàn thành lưu trú',
      statusBadgeVariant: 'success',
      totalAmount: 1200000,
      hotel: BookingHotelModel(
        hotelId: 'h2',
        name: 'Khách sạn Phố Cổ Hội An',
        address: 'Hội An',
      ),
      stay: BookingStayModel(
        checkInDate: '2026-09-10',
        checkOutDate: '2026-09-12',
        nights: 2,
        roomTypeName: 'Phòng Superior',
      ),
      cancellation: BookingCancellationModel(),
      payment: BookingPaymentModel(),
    ),
  ];

  @override
  Future<BookingListResponse> fetchMyBookings({
    String? status,
    String? search,
    String? timeRange,
    String? userId,
  }) async {
    final filtered = _bookings.where((booking) {
      final matchesStatus =
          status == null || status == 'all' || booking.category == status;
      final query = search?.toLowerCase() ?? '';
      final matchesSearch =
          query.isEmpty ||
          booking.bookingCode.toLowerCase().contains(query) ||
          booking.hotel.name.toLowerCase().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();

    return BookingListResponse(
      bookings: filtered,
      counts: const BookingCountsModel(all: 2, upcoming: 1, completed: 1),
      availableYears: const [2026],
    );
  }
}

void main() {
  testWidgets(
    'shows upcoming bookings and groups completed bookings as history',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myBookingRepositoryProvider.overrideWithValue(
              _FakeMyBookingRepository(),
            ),
          ],
          child: const MaterialApp(home: MyBookingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quản lý Đặt Chỗ & Lịch Sử'), findsOneWidget);
      expect(find.text('Chuyến Đi Sắp Tới'), findsOneWidget);
      expect(find.text('Khách sạn Biển Xanh'), findsOneWidget);
      expect(find.text('Xem chi tiết'), findsOneWidget);

      await tester.tap(find.text('Lịch sử'));
      await tester.pumpAndSettle();

      expect(find.text('Lịch sử đặt chỗ'), findsOneWidget);
      expect(find.text('Khách sạn Phố Cổ Hội An'), findsOneWidget);
      expect(find.text('Khách sạn Biển Xanh'), findsNothing);
    },
  );
}
