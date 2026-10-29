import 'package:equatable/equatable.dart';

/// Đại diện cho một chuyến đi trong Nhật ký hành trình.
/// Hỗ trợ cả 2 hình thức:
/// 1. Tự do tạo chuyến đi cá nhân (isCustomTrip = true)
/// 2. Liên kết tự động với đơn đặt phòng thực tế của Avora (isCustomTrip = false, có bookingId từ t_booking)
class TravelJournalEntry extends Equatable {
  final String id; // UUID hoặc bookingId
  final String? bookingId; // null nếu là chuyến đi tự do
  final String title; // Tên hành trình (vd: "Phượt Đà Lạt cùng bạn thân", "Kỳ nghỉ Avora Grand")
  final String placeName; // Tên khách sạn / resort / homestay
  final String cityName; // Điểm đến (thành phố / tỉnh)
  final String? address;
  final String? thumbnailUrl;
  final String startDate; // yyyy-MM-dd
  final String endDate; // yyyy-MM-dd
  final int nights;
  final num totalAmount;
  final bool isCustomTrip; // true nếu người dùng tự tạo

  // Ghi chép nhật ký & cảm xúc cá nhân
  final String journalNote;
  final String mood; // 'relaxing', 'adventure', 'romantic', 'family', 'business'
  final int? ratingScore; // 1 - 10 (chuẩn t_review)
  final List<String> highlights; // Các thẻ kỷ niệm nổi bật
  final DateTime updatedAt;

  const TravelJournalEntry({
    required this.id,
    this.bookingId,
    required this.title,
    required this.placeName,
    required this.cityName,
    this.address,
    this.thumbnailUrl,
    required this.startDate,
    required this.endDate,
    this.nights = 1,
    this.totalAmount = 0,
    this.isCustomTrip = false,
    this.journalNote = '',
    this.mood = 'relaxing',
    this.ratingScore,
    this.highlights = const [],
    required this.updatedAt,
  });

  bool get hasNote =>
      journalNote.trim().isNotEmpty ||
      (ratingScore != null && ratingScore! > 0) ||
      highlights.isNotEmpty;

  bool get isCompleted {
    try {
      final out = DateTime.tryParse(endDate);
      if (out != null && out.isBefore(DateTime.now())) return true;
    } catch (_) {}
    return false;
  }

  bool get isUpcoming {
    try {
      final inDate = DateTime.tryParse(startDate);
      if (inDate != null && inDate.isAfter(DateTime.now())) return true;
    } catch (_) {}
    return false;
  }

  TravelJournalEntry copyWith({
    String? title,
    String? placeName,
    String? cityName,
    String? address,
    String? thumbnailUrl,
    String? startDate,
    String? endDate,
    int? nights,
    num? totalAmount,
    String? journalNote,
    String? mood,
    int? ratingScore,
    List<String>? highlights,
    DateTime? updatedAt,
  }) {
    return TravelJournalEntry(
      id: id,
      bookingId: bookingId,
      title: title ?? this.title,
      placeName: placeName ?? this.placeName,
      cityName: cityName ?? this.cityName,
      address: address ?? this.address,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nights: nights ?? this.nights,
      totalAmount: totalAmount ?? this.totalAmount,
      isCustomTrip: isCustomTrip,
      journalNote: journalNote ?? this.journalNote,
      mood: mood ?? this.mood,
      ratingScore: ratingScore ?? this.ratingScore,
      highlights: highlights ?? this.highlights,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'title': title,
      'place_name': placeName,
      'city_name': cityName,
      'address': address,
      'thumbnail_url': thumbnailUrl,
      'start_date': startDate,
      'end_date': endDate,
      'nights': nights,
      'total_amount': totalAmount,
      'is_custom_trip': isCustomTrip,
      'journal_note': journalNote,
      'mood': mood,
      'rating_score': ratingScore,
      'highlights': highlights,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TravelJournalEntry.fromJson(Map<String, dynamic> json) {
    return TravelJournalEntry(
      id: (json['id'] ?? '').toString(),
      bookingId: json['booking_id']?.toString(),
      title: (json['title'] ?? 'Chuyến đi').toString(),
      placeName: (json['place_name'] ?? '').toString(),
      cityName: (json['city_name'] ?? 'Điểm đến').toString(),
      address: json['address']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      startDate: (json['start_date'] ?? '').toString(),
      endDate: (json['end_date'] ?? '').toString(),
      nights: (json['nights'] as num?)?.toInt() ?? 1,
      totalAmount: (json['total_amount'] as num?) ?? 0,
      isCustomTrip: json['is_custom_trip'] == true,
      journalNote: (json['journal_note'] ?? '').toString(),
      mood: (json['mood'] ?? 'relaxing').toString(),
      ratingScore: (json['rating_score'] as num?)?.toInt(),
      highlights: (json['highlights'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        title,
        placeName,
        cityName,
        address,
        thumbnailUrl,
        startDate,
        endDate,
        nights,
        totalAmount,
        isCustomTrip,
        journalNote,
        mood,
        ratingScore,
        highlights,
        updatedAt,
      ];
}

/// Thống kê hành trình tổng hợp của cá nhân
class TravelStats extends Equatable {
  final int totalTrips;
  final int completedTrips;
  final int upcomingTrips;
  final int totalNights;
  final List<String> visitedCities;
  final num totalSpent;

  const TravelStats({
    this.totalTrips = 0,
    this.completedTrips = 0,
    this.upcomingTrips = 0,
    this.totalNights = 0,
    this.visitedCities = const [],
    this.totalSpent = 0,
  });

  @override
  List<Object?> get props => [
        totalTrips,
        completedTrips,
        upcomingTrips,
        totalNights,
        visitedCities,
        totalSpent,
      ];
}
