import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:avora_mobile/features/my_booking/data/models/booking_item_model.dart';
import 'package:avora_mobile/features/my_booking/data/repositories/my_booking_repository.dart';
import 'package:avora_mobile/features/travel_journal/data/models/travel_journal_entry_model.dart';

const String _kJournalStoragePrefix = 'avora_travel_journal_v2_';

final travelJournalRepositoryProvider = Provider<TravelJournalRepository>((ref) {
  final myBookingRepo = ref.watch(myBookingRepositoryProvider);
  return TravelJournalRepository(
    myBookingRepository: myBookingRepo,
    storage: const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
});

class TravelJournalRepository {
  final MyBookingRepository _myBookingRepository;
  final FlutterSecureStorage _storage;

  TravelJournalRepository({
    required MyBookingRepository myBookingRepository,
    required FlutterSecureStorage storage,
  })  : _myBookingRepository = myBookingRepository,
        _storage = storage;

  /// Lấy toàn bộ danh sách chuyến đi của người dùng (theo userId).
  /// Tự động nạp các chuyến đi tự tạo đã lưu cục bộ + đồng bộ với đơn đặt chỗ Avora nếu có.
  Future<List<TravelJournalEntry>> getJournalEntries({required String userId}) async {
    // 1. Tải các mục nhật ký người dùng đã lưu trong local secure storage
    final localEntries = await _loadLocalEntries(userId);
    final entriesMap = <String, TravelJournalEntry>{
      for (final e in localEntries) e.id: e,
    };

    // 2. Thử nạp danh sách đơn đặt phòng từ DB backend (nếu có mạng)
    try {
      final response = await _myBookingRepository.fetchMyBookings(status: 'all');
      for (final b in response.bookings) {
        final id = 'booking_${b.bookingId}';
        // Nếu đã có bản ghi cục bộ thì giữ nguyên kỷ niệm/ghi chú của người dùng
        if (entriesMap.containsKey(id)) {
          final existing = entriesMap[id]!;
          entriesMap[id] = existing.copyWith(
            placeName: b.hotel.name,
            address: b.hotel.address,
            cityName: _extractCityName(b.hotel.address),
            thumbnailUrl: b.hotel.thumbnailUrl,
            startDate: b.stay.checkInDate,
            endDate: b.stay.checkOutDate,
            nights: b.stay.nights,
            totalAmount: b.totalAmount,
          );
        } else {
          // Tạo mục chuyến đi mới liên kết với đơn đặt chỗ
          entriesMap[id] = TravelJournalEntry(
            id: id,
            bookingId: b.bookingId,
            title: b.hotel.name,
            placeName: b.hotel.name,
            cityName: _extractCityName(b.hotel.address),
            address: b.hotel.address,
            thumbnailUrl: b.hotel.thumbnailUrl,
            startDate: b.stay.checkInDate,
            endDate: b.stay.checkOutDate,
            nights: b.stay.nights,
            totalAmount: b.totalAmount,
            isCustomTrip: false,
            updatedAt: DateTime.now(),
          );
        }
      }
    } catch (_) {
      // Offline hoặc không có đơn đặt phòng: Vẫn tiếp tục dùng dữ liệu cục bộ!
    }

    final result = entriesMap.values.toList();
    // Sắp xếp ngày đi mới nhất lên trước
    result.sort((a, b) => b.startDate.compareTo(a.startDate));

    // Lưu lại trạng thái đồng bộ
    await _saveLocalEntries(userId, result);
    return result;
  }

  /// Tải danh sách đơn đặt phòng từ Avora để người dùng chọn liên kết nhanh
  Future<List<BookingItemModel>> getAvailableBookings() async {
    try {
      final response = await _myBookingRepository.fetchMyBookings(status: 'all');
      return response.bookings;
    } catch (_) {
      return [];
    }
  }

  /// Thêm chuyến đi tự do mới do người dùng tự tạo
  Future<TravelJournalEntry> createCustomTrip({
    required String userId,
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
    final entries = await _loadLocalEntries(userId);
    final newId = linkedBookingId != null && linkedBookingId.isNotEmpty
        ? 'booking_$linkedBookingId'
        : 'custom_${DateTime.now().millisecondsSinceEpoch}';

    final entry = TravelJournalEntry(
      id: newId,
      bookingId: linkedBookingId,
      title: title.trim(),
      placeName: placeName.trim(),
      cityName: cityName.trim(),
      address: address?.trim(),
      startDate: startDate,
      endDate: endDate,
      nights: nights,
      totalAmount: totalAmount,
      isCustomTrip: linkedBookingId == null,
      journalNote: note.trim(),
      mood: mood,
      ratingScore: ratingScore,
      highlights: highlights,
      updatedAt: DateTime.now(),
    );

    // Cập nhật hoặc chèn
    final index = entries.indexWhere((e) => e.id == newId);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.insert(0, entry);
    }

    await _saveLocalEntries(userId, entries);
    return entry;
  }

  /// Cập nhật ghi chú và cảm xúc của một chuyến đi
  Future<void> updateJournalEntry({
    required String userId,
    required String entryId,
    required String note,
    required String mood,
    int? ratingScore,
    List<String> highlights = const [],
  }) async {
    final entries = await _loadLocalEntries(userId);
    final index = entries.indexWhere((e) => e.id == entryId);
    if (index >= 0) {
      entries[index] = entries[index].copyWith(
        journalNote: note.trim(),
        mood: mood,
        ratingScore: ratingScore,
        highlights: highlights,
        updatedAt: DateTime.now(),
      );
      await _saveLocalEntries(userId, entries);
    }
  }

  /// Xóa chuyến đi khỏi nhật ký
  Future<void> deleteJournalEntry({
    required String userId,
    required String entryId,
  }) async {
    final entries = await _loadLocalEntries(userId);
    entries.removeWhere((e) => e.id == entryId);
    await _saveLocalEntries(userId, entries);
  }

  /// Tính toán thống kê hành trình cá nhân
  TravelStats computeStats(List<TravelJournalEntry> entries) {
    int completed = 0;
    int upcoming = 0;
    int nights = 0;
    num totalSpent = 0;
    final Set<String> cities = {};

    for (final e in entries) {
      if (e.isCompleted) completed++;
      if (e.isUpcoming) upcoming++;
      nights += e.nights;
      totalSpent += e.totalAmount;
      if (e.cityName.trim().isNotEmpty) {
        cities.add(e.cityName.trim());
      }
    }

    return TravelStats(
      totalTrips: entries.length,
      completedTrips: completed,
      upcomingTrips: upcoming,
      totalNights: nights,
      visitedCities: cities.toList(),
      totalSpent: totalSpent,
    );
  }

  Future<List<TravelJournalEntry>> _loadLocalEntries(String userId) async {
    try {
      final key = '$_kJournalStoragePrefix$userId';
      final raw = await _storage.read(key: key);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => TravelJournalEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalEntries(String userId, List<TravelJournalEntry> entries) async {
    try {
      final key = '$_kJournalStoragePrefix$userId';
      final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
      await _storage.write(key: key, value: encoded);
    } catch (_) {}
  }

  String _extractCityName(String address) {
    if (address.isEmpty) return 'Điểm đến du lịch';
    final parts = address.split(',');
    if (parts.isNotEmpty) {
      final lastPart = parts.last.trim();
      if (lastPart.isNotEmpty) return lastPart;
    }
    return address;
  }
}
