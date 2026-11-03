import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/my_booking/data/models/booking_item_model.dart';
import 'package:avora_mobile/features/my_booking/data/repositories/my_booking_repository.dart';
import 'package:avora_mobile/features/my_booking/presentation/widgets/booking_card.dart';
import 'package:avora_mobile/features/my_booking/presentation/widgets/edit_guest_modal.dart';
import 'package:avora_mobile/features/my_booking/presentation/widgets/date_change_modal.dart';

BookingItemModel _createTestBooking({bool canEdit = false}) {
  return BookingItemModel(
    bookingId: 'bk-test-1',
    bookingCode: 'AV-TEST-001',
    category: 'upcoming',
    guestName: 'Nguyễn Văn A',
    guestPhone: '0912345678',
    specialRequest: 'Tầng cao',
    statusCodeName: canEdit ? 'PND' : 'CFM',
    statusName: canEdit ? 'Chờ thanh toán' : 'Đã xác nhận',
    statusBadgeVariant: canEdit ? 'amber' : 'confirmed',
    totalAmount: 1500000,
    canEdit: canEdit,
    hotel: const BookingHotelModel(
      hotelId: 'h-1',
      name: 'Avora Da Nang Hotel',
      address: '123 Bach Dang, Da Nang',
    ),
    stay: const BookingStayModel(
      checkInDate: '2026-11-10',
      checkOutDate: '2026-11-12',
      nights: 2,
    ),
    cancellation: const BookingCancellationModel(),
    payment: const BookingPaymentModel(),
  );
}

void main() {
  group('BookingCard - canEdit visibility tests', () {
    testWidgets('hides Edit and DateChange buttons when canEdit is false', (tester) async {
      final booking = _createTestBooking(canEdit: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: booking,
              onOpenVoucher: () {},
              onOpenEditGuest: () {},
              onOpenDateChange: () {},
              onOpenCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('Thông tin nhận phòng'), findsNothing);
      expect(find.text('Đổi ngày'), findsNothing);
      expect(find.text('Hủy phòng'), findsOneWidget);
    });

    testWidgets('shows Edit and DateChange buttons when canEdit is true', (tester) async {
      final booking = _createTestBooking(canEdit: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookingCard(
              booking: booking,
              onOpenVoucher: () {},
              onOpenEditGuest: () {},
              onOpenDateChange: () {},
              onOpenCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('Thông tin nhận phòng'), findsOneWidget);
      expect(find.text('Đổi ngày'), findsOneWidget);
      expect(find.text('Hủy phòng'), findsOneWidget);
    });
  });

  group('EditGuestModal validation tests', () {
    testWidgets('rejects invalid names with special characters or numbers', (tester) async {
      final booking = _createTestBooking(canEdit: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditGuestModal(
              booking: booking,
              onSave: ({required guestName, required guestPhone, specialRequest}) async {
                return true;
              },
            ),
          ),
        ),
      );

      final nameField = find.byType(TextFormField).at(0);
      // Nhập tên chứa ký tự @ không hợp lệ
      await tester.enterText(nameField, 'Nguyen Van A @#');
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();

      expect(
        find.text('Họ và tên chỉ dùng chữ cái, khoảng trắng, dấu nháy đơn, gạch nối hoặc dấu chấm.'),
        findsOneWidget,
      );
    });

    testWidgets('accepts valid Vietnamese name and phone and submits', (tester) async {
      final booking = _createTestBooking(canEdit: true);
      String? savedName;
      String? savedPhone;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditGuestModal(
              booking: booking,
              onSave: ({required guestName, required guestPhone, specialRequest}) async {
                savedName = guestName;
                savedPhone = guestPhone;
                return true;
              },
            ),
          ),
        ),
      );

      final nameField = find.byType(TextFormField).at(0);
      final phoneField = find.byType(TextFormField).at(1);

      await tester.enterText(nameField, 'Trần Thị Mỹ Duyên');
      await tester.enterText(phoneField, '+84 987 654 321');
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();

      expect(savedName, 'Trần Thị Mỹ Duyên');
      expect(savedPhone, '0987654321');
    });

    testWidgets('accepts international phone numbers starting with +', (tester) async {
      final booking = _createTestBooking(canEdit: true);
      String? savedPhone;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditGuestModal(
              booking: booking,
              onSave: ({required guestName, required guestPhone, specialRequest}) async {
                savedPhone = guestPhone;
                return true;
              },
            ),
          ),
        ),
      );

      final phoneField = find.byType(TextFormField).at(1);
      await tester.enterText(phoneField, '+82 10 1234 5678');
      await tester.tap(find.text('Lưu thông tin'));
      await tester.pumpAndSettle();

      expect(savedPhone, '+821012345678');
    });
  });

  group('DateChangeModal coupon removal notice tests', () {
    testWidgets('displays coupon removal warning and allows confirmation', (tester) async {
      final booking = _createTestBooking(canEdit: true);
      bool didConfirmRemoval = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateChangeModal(
              booking: booking,
              onConfirmDateChange: ({
                required checkInDate,
                required checkOutDate,
                bool confirmCouponRemoval = false,
              }) async {
                if (!confirmCouponRemoval) {
                  throw const CouponRemovalRequiredException(
                    message: 'Voucher không còn đủ điều kiện áp dụng.',
                    couponCode: 'SUMMER2026',
                    currentTotal: 1500000,
                    proposedTotal: 1800000,
                    currentDiscount: 300000,
                    reason: 'Đơn hàng mới không đạt giá trị tối thiểu 2.000.000 đ',
                  );
                }
                didConfirmRemoval = true;
                return true;
              },
            ),
          ),
        ),
      );

      // Bấm Xác nhận đổi ngày lần đầu
      await tester.tap(find.text('Xác nhận đổi ngày'));
      await tester.pumpAndSettle();

      // Phải xuất hiện box cảnh báo mất voucher giống Web
      expect(find.text('Voucher sẽ bị mất nếu bạn đổi ngày'), findsOneWidget);
      expect(find.text('Bỏ voucher & đổi ngày'), findsOneWidget);
      expect(find.text('Không đổi ngày'), findsOneWidget);

      // Bấm xác nhận bỏ voucher
      await tester.tap(find.text('Bỏ voucher & đổi ngày'));
      await tester.pumpAndSettle();

      expect(didConfirmRemoval, isTrue);
    });
  });
}
