import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/hotels/presentation/widgets/hotel_search_card.dart';

import 'hotel_search_screen_test.dart' show FakeHotelRepository, createTestWidget;

void main() {
  for (final size in const [Size(360, 740), Size(393, 851), Size(412, 915)]) {
    testWidgets('📱 Layout không lỗi trên màn hình ${size.width}x${size.height}',
        (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(repository: FakeHotelRepository()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HotelSearchCard), findsOneWidget);
    });
  }
}
