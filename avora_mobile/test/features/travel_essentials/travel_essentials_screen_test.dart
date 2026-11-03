import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/travel_essentials/data/models/packing_item_model.dart';
import 'package:avora_mobile/features/travel_essentials/presentation/providers/travel_essentials_provider.dart';
import 'package:avora_mobile/features/travel_essentials/presentation/screens/travel_essentials_screen.dart';

void main() {
  testWidgets('renders TravelEssentialsScreen with tabs and packing checklist', (
    WidgetTester tester,
  ) async {
    final fakeItems = [
      const PackingItem(id: '1', title: 'CCCD / Hộ chiếu', category: 'documents', isChecked: true),
      const PackingItem(id: '2', title: 'Xác nhận đặt phòng Avora', category: 'documents', isChecked: false),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packingProvider.overrideWith(
            (ref) => _FakePackingNotifier(fakeItems),
          ),
        ],
        child: const MaterialApp(
          home: TravelEssentialsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tiện ích du lịch'), findsOneWidget);
    expect(find.text('Hành lý'), findsOneWidget);
    expect(find.text('Đổi tiền'), findsOneWidget);
    expect(find.text('Thời tiết'), findsOneWidget);
    expect(find.text('Hotline SOS'), findsOneWidget);
    expect(find.text('Mẹo lưu trú'), findsOneWidget);
    expect(find.text('Tiến độ chuẩn bị đồ đạc'), findsOneWidget);
  });
}

class _FakePackingNotifier extends PackingNotifier {
  _FakePackingNotifier(List<PackingItem> items) : super(_DummyEssentialsRepo()) {
    state = PackingState(items: items, isLoading: false);
  }
}

class _DummyEssentialsRepo extends dynamic {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
