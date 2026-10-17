import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/my_booking/presentation/screens/my_booking_screen.dart';

void main() {
  testWidgets('shows upcoming booking unavailable state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyBookingScreen()));

    expect(find.text('Đặt chỗ của tôi'), findsOneWidget);
    expect(find.text('Sắp tới'), findsOneWidget);
    expect(find.text('Đặt chỗ sắp tới sẽ ở đây'), findsOneWidget);
    expect(
      find.textContaining('Dữ liệu đặt chỗ chưa được kết nối'),
      findsOneWidget,
    );
    expect(find.text('Khám phá khách sạn'), findsOneWidget);
  });

  testWidgets('switches to booking history state', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyBookingScreen()));

    await tester.tap(find.text('Lịch sử'));
    await tester.pumpAndSettle();

    expect(find.text('Lịch sử đặt chỗ chưa khả dụng'), findsOneWidget);
    expect(find.text('Chưa có đặt chỗ sắp tới'), findsNothing);
  });
}
