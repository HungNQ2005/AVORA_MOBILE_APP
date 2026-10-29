import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:avora_mobile/features/my_booking/data/models/booking_item_model.dart';
import 'package:avora_mobile/features/travel_journal/data/models/travel_journal_entry_model.dart';
import 'package:avora_mobile/features/travel_journal/data/repositories/travel_journal_repository.dart';

class TravelJournalState {
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final List<TravelJournalEntry> allEntries;
  final TravelStats stats;
  final String activeFilter; // 'all', 'completed', 'upcoming'

  const TravelJournalState({
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.allEntries = const [],
    this.stats = const TravelStats(),
    this.activeFilter = 'all',
  });

  List<TravelJournalEntry> get filteredEntries {
    if (activeFilter == 'completed') {
      return allEntries.where((e) => e.isCompleted).toList();
    }
    if (activeFilter == 'upcoming') {
      return allEntries.where((e) => e.isUpcoming).toList();
    }
    return allEntries;
  }

  TravelJournalState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    List<TravelJournalEntry>? allEntries,
    TravelStats? stats,
    String? activeFilter,
  }) {
    return TravelJournalState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      allEntries: allEntries ?? this.allEntries,
      stats: stats ?? this.stats,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

class TravelJournalNotifier extends StateNotifier<TravelJournalState> {
  final TravelJournalRepository _repository;
  final String _userId;

  TravelJournalNotifier(this._repository, this._userId)
      : super(const TravelJournalState()) {
    loadJournal();
  }

  Future<void> loadJournal() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final entries = await _repository.getJournalEntries(userId: _userId);
      final stats = _repository.computeStats(entries);
      state = state.copyWith(
        isLoading: false,
        allEntries: entries,
        stats: stats,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải nhật ký hành trình: $e',
      );
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  /// Lấy danh sách đơn đặt phòng Avora để người dùng chọn liên kết nhanh
  Future<List<BookingItemModel>> getAvailableBookings() async {
    return await _repository.getAvailableBookings();
  }

  /// Thêm chuyến đi mới do người dùng tự tạo
  Future<bool> createCustomTrip({
    required String title,
    required String placeName,
    required String cityName,
    String? address,
    required String startDate,
    required String endDate,
    int nights = 1,
    num totalAmount = 0,
    String note = '',
    String mood = 'relaxing',
    int? ratingScore,
    List<String> highlights = const [],
    String? linkedBookingId,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final newEntry = await _repository.createCustomTrip(
        userId: _userId,
        title: title,
        placeName: placeName,
        cityName: cityName,
        address: address,
        startDate: startDate,
        endDate: endDate,
        nights: nights,
        totalAmount: totalAmount,
        note: note,
        mood: mood,
        ratingScore: ratingScore,
        highlights: highlights,
        linkedBookingId: linkedBookingId,
      );

      final updated = [
        newEntry,
        ...state.allEntries.where((e) => e.id != newEntry.id),
      ];
      updated.sort((a, b) => b.startDate.compareTo(a.startDate));

      state = state.copyWith(
        isSaving: false,
        allEntries: updated,
        stats: _repository.computeStats(updated),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Lỗi khi tạo chuyến đi: $e',
      );
      return false;
    }
  }

  /// Cập nhật ghi chép cảm xúc / kỷ niệm cho chuyến đi
  Future<bool> updateEntry({
    required String entryId,
    required String note,
    required String mood,
    int? ratingScore,
    List<String> highlights = const [],
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.updateJournalEntry(
        userId: _userId,
        entryId: entryId,
        note: note,
        mood: mood,
        ratingScore: ratingScore,
        highlights: highlights,
      );

      final updated = state.allEntries.map((e) {
        if (e.id == entryId) {
          return e.copyWith(
            journalNote: note,
            mood: mood,
            ratingScore: ratingScore,
            highlights: highlights,
            updatedAt: DateTime.now(),
          );
        }
        return e;
      }).toList();

      state = state.copyWith(
        isSaving: false,
        allEntries: updated,
        stats: _repository.computeStats(updated),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Lỗi khi lưu nhật ký: $e',
      );
      return false;
    }
  }

  /// Xóa chuyến đi
  Future<void> deleteEntry(String entryId) async {
    try {
      await _repository.deleteJournalEntry(userId: _userId, entryId: entryId);
      final updated = state.allEntries.where((e) => e.id != entryId).toList();
      state = state.copyWith(
        allEntries: updated,
        stats: _repository.computeStats(updated),
      );
    } catch (_) {}
  }
}

final travelJournalProvider =
    StateNotifierProvider<TravelJournalNotifier, TravelJournalState>((ref) {
  final repo = ref.watch(travelJournalRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final userId = authState is AuthSuccess ? authState.user.userId : 'guest_user';
  return TravelJournalNotifier(repo, userId);
});
