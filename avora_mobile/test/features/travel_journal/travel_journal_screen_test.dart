import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/travel_journal/data/models/travel_journal_entry_model.dart';
import 'package:avora_mobile/features/travel_journal/presentation/providers/travel_journal_provider.dart';
import 'package:avora_mobile/features/travel_journal/presentation/screens/travel_journal_screen.dart';

void main() {
  testWidgets('renders TravelJournalScreen with passport card and filters', (
    WidgetTester tester,
  ) async {
    final fakeEntries = [
      TravelJournalEntry(
        id: 'entry-1',
        bookingId: 'bk-1',
        title: 'Avora Grand Hotel Đà Nẵng',
        placeName: 'Avora Grand Hotel Đà Nẵng',
        address: '28 Võ Nguyên Giáp, Đà Nẵng',
        cityName: 'Đà Nẵng',
        startDate: '2026-11-10',
        endDate: '2026-11-12',
        nights: 2,
        isCustomTrip: false,
        journalNote: 'Kỳ nghỉ tuyệt vời cùng gia đình!',
        mood: 'family',
        ratingScore: 10,
        highlights: const ['View cực đẹp', 'Buffet ngon'],
        updatedAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          travelJournalProvider.overrideWith(
            (ref) => _FakeTravelJournalNotifier(fakeEntries),
          ),
        ],
        child: const MaterialApp(
          home: TravelJournalScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and passport card
    expect(find.text('Nhật ký hành trình'), findsOneWidget);
    expect(find.text('HỘ CHIẾU HÀNH TRÌNH AVORA'), findsOneWidget);
    expect(find.text('EXPLORER'), findsOneWidget);

    // Verify hotel card and note
    expect(find.text('Avora Grand Hotel Đà Nẵng'), findsOneWidget);
    expect(find.text('"Kỳ nghỉ tuyệt vời cùng gia đình!"'), findsOneWidget);
    expect(find.text('10/10'), findsOneWidget);
  });
}

class _FakeTravelJournalNotifier extends TravelJournalNotifier {
  _FakeTravelJournalNotifier(List<TravelJournalEntry> entries)
      : super(_DummyRepository(), 'test_user') {
    state = TravelJournalState(
      isLoading: false,
      allEntries: entries,
      stats: TravelStats(
        totalTrips: entries.length,
        completedTrips: 0,
        upcomingTrips: 1,
        totalNights: 2,
        visitedCities: const ['Đà Nẵng'],
      ),
    );
  }
}

class _DummyRepository extends dynamic {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
