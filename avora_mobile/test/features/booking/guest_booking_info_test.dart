import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/features/booking/data/models/guest_booking_info.dart';
import 'package:avora_mobile/features/booking/data/models/booking_guest_info_args.dart';
import 'package:avora_mobile/features/booking/presentation/screens/booking_guest_info_screen.dart';

void main() {
  group('GuestBookingInfo Validation Unit Tests', () {
    test('isValidGuestName validates correctly matching backend', () {
      // Valid Vietnamese names
      expect(GuestBookingInfo.isValidGuestName('Nguyễn Văn An'), isTrue);
      expect(GuestBookingInfo.isValidGuestName('Trần Thị Mai Phương'), isTrue);
      expect(GuestBookingInfo.isValidGuestName('Lê Bình'), isTrue);
      expect(GuestBookingInfo.isValidGuestName('John Doe'), isTrue);

      // Invalid names
      expect(GuestBookingInfo.isValidGuestName(''), isFalse);
      expect(GuestBookingInfo.isValidGuestName('A'), isFalse); // < 2 chars
      expect(GuestBookingInfo.isValidGuestName('12345'), isFalse); // only numbers
      expect(GuestBookingInfo.isValidGuestName('Nguyễn Văn 123'), isFalse); // contains numbers
      expect(GuestBookingInfo.isValidGuestName('John @Doe'), isFalse); // special characters
    });

    test('isValidGuestPhone validates VN and international numbers', () {
      // Valid VN phone
      expect(GuestBookingInfo.isValidGuestPhone('0905123456', '+84'), isTrue);
      expect(GuestBookingInfo.isValidGuestPhone('0905 123 456', '+84'), isTrue);
      expect(GuestBookingInfo.isValidGuestPhone('84905123456', '+84'), isTrue);

      // Invalid VN phone
      expect(GuestBookingInfo.isValidGuestPhone('', '+84'), isFalse);
      expect(GuestBookingInfo.isValidGuestPhone('123', '+84'), isFalse);
      expect(GuestBookingInfo.isValidGuestPhone('0905abc456', '+84'), isFalse);

      // Valid International phone
      expect(GuestBookingInfo.isValidGuestPhone('4155552671', '+1'), isTrue);
      expect(GuestBookingInfo.isValidGuestPhone('9012345678', '+81'), isTrue);
    });

    test('combinedSpecialRequest formats correctly', () {
      const info = GuestBookingInfo(
        lastName: 'Nguyễn',
        firstName: 'Văn An',
        selectedRequests: ['Phòng không hút thuốc', '1 giường lớn đôi King-size'],
        customNote: 'Gia đình có trẻ nhỏ',
      );

      expect(info.fullName, 'Nguyễn Văn An');
      expect(
        info.combinedSpecialRequest,
        'Phòng không hút thuốc; 1 giường lớn đôi King-size; Gia đình có trẻ nhỏ',
      );
    });
  });

  group('BookingGuestInfoScreen Widget Tests', () {
    testWidgets('renders all required cards and input fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingGuestInfoScreen(
              args: BookingGuestInfoArgs(
                hotelName: 'Avora Resort',
                roomName: 'Deluxe Ocean View',
                stayDates: '20/11/2026 - 22/11/2026',
                nights: 2,
                adults: 2,
                children: 0,
                rooms: 1,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and summary
      expect(find.text('Thông tin khách lưu trú'), findsOneWidget);
      expect(find.text('Avora Resort'), findsOneWidget);
      expect(find.text('Deluxe Ocean View'), findsAtLeastNWidgets(1));

      // Check contact info card and labels
      expect(find.text('Thông tin người nhận phòng'), findsOneWidget);
      expect(find.text('Ví dụ: Nguyễn'), findsOneWidget);
      expect(find.text('Ví dụ: Văn An'), findsOneWidget);
      expect(find.text('0905 123 456'), findsOneWidget);

      // Check special requests card
      expect(find.text('Yêu cầu đặc biệt cho chỗ nghỉ'), findsOneWidget);
      expect(find.text('Phòng không hút thuốc'), findsOneWidget);
      expect(find.text('1 giường lớn đôi King-size'), findsOneWidget);
      expect(find.text('Nhận phòng sớm (~12:00)'), findsOneWidget);

      // Check action button
      expect(find.text('Tiếp tục'), findsOneWidget);

      // Check coupon card and input
      expect(find.text('Mã giảm giá / Voucher'), findsOneWidget);
      expect(find.text('Nhập mã (VD: SAIGON10)'), findsOneWidget);
      expect(find.text('Áp dụng'), findsOneWidget);
    });

    testWidgets('entering and applying coupon works in UI', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BookingGuestInfoScreen(
              args: BookingGuestInfoArgs(
                hotelName: 'Avora Resort',
                roomName: 'Deluxe Ocean View',
                stayDates: '20/11/2026 - 22/11/2026',
                nights: 2,
                adults: 2,
                children: 0,
                rooms: 1,
                totalPrice: 2000000,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down to make coupon card fully visible above bottom bar
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Enter coupon SAIGON10
      final couponField = find.widgetWithText(TextFormField, 'Nhập mã (VD: SAIGON10)');
      expect(couponField, findsOneWidget);
      await tester.enterText(couponField, 'SAIGON10');
      await tester.pump();

      // Tap apply button
      await tester.tap(find.text('Áp dụng'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should show Bỏ mã button
      expect(find.text('Bỏ mã'), findsOneWidget);
    });
  });
}
