import 'package:equatable/equatable.dart';
import 'package:avora_mobile/features/home/data/models/hotel_model.dart';

/// Một phương án khách sạn do AI Concierge đề xuất (`POST /api/ai/chat`).
class AiHotelPick extends Equatable {
  final HotelModel hotel;
  final String badgeKey; // optimal | saving | upgrade | match
  final String badgeLabel;
  final int matchPercent;
  final int nights;
  final int rooms;
  final num totalPrice;
  final String? budgetNote;
  final List<String> perks;
  final String reason;
  final String? roomName;
  final String? bedType;
  final String? roomSize;
  final int? freeCancelHours;

  const AiHotelPick({
    required this.hotel,
    required this.badgeKey,
    required this.badgeLabel,
    required this.matchPercent,
    required this.nights,
    required this.rooms,
    required this.totalPrice,
    this.budgetNote,
    this.perks = const [],
    this.reason = '',
    this.roomName,
    this.bedType,
    this.roomSize,
    this.freeCancelHours,
  });

  factory AiHotelPick.fromJson(Map<String, dynamic> json) {
    final ai = Map<String, dynamic>.from((json['ai'] as Map?) ?? const {});
    final room = json['room_highlight'] is Map
        ? Map<String, dynamic>.from(json['room_highlight'] as Map)
        : <String, dynamic>{};
    final cancel = json['cancellation_policy'] is Map
        ? Map<String, dynamic>.from(json['cancellation_policy'] as Map)
        : <String, dynamic>{};

    return AiHotelPick(
      hotel: HotelModel.fromJson(json),
      badgeKey: ai['badge_key']?.toString() ?? 'match',
      badgeLabel: ai['badge_label']?.toString() ?? 'GỢI Ý PHÙ HỢP',
      matchPercent: (ai['match_percent'] as num?)?.toInt() ?? 0,
      nights: (ai['nights'] as num?)?.toInt() ?? 1,
      rooms: (ai['rooms'] as num?)?.toInt() ?? 1,
      totalPrice: (ai['total_price'] as num?) ?? (json['price'] as num? ?? 0),
      budgetNote: ai['budget_note']?.toString(),
      perks: (ai['perks'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      reason: ai['reason']?.toString() ?? '',
      roomName: room['name']?.toString(),
      bedType: room['bed_type']?.toString(),
      roomSize: room['room_size']?.toString(),
      freeCancelHours: (cancel['free_before_hours'] as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props => [hotel, badgeKey, matchPercent, totalPrice];
}

/// Tóm tắt tiêu chí AI đã dùng để tìm kiếm.
class AiSearchSummary extends Equatable {
  final String destination;
  final String checkIn;
  final String checkOut;
  final int nights;
  final int adults;
  final int children;
  final int rooms;
  final num? budget;
  final String? budgetType;
  final bool assumedDates;
  final int totalFound;

  const AiSearchSummary({
    required this.destination,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    required this.rooms,
    this.budget,
    this.budgetType,
    this.assumedDates = false,
    this.totalFound = 0,
  });

  factory AiSearchSummary.fromJson(Map<String, dynamic> json) {
    return AiSearchSummary(
      destination: json['destination']?.toString() ?? 'Toàn quốc',
      checkIn: json['check_in']?.toString() ?? '',
      checkOut: json['check_out']?.toString() ?? '',
      nights: (json['nights'] as num?)?.toInt() ?? 1,
      adults: (json['adults'] as num?)?.toInt() ?? 2,
      children: (json['children'] as num?)?.toInt() ?? 0,
      rooms: (json['rooms'] as num?)?.toInt() ?? 1,
      budget: json['budget'] as num?,
      budgetType: json['budget_type']?.toString(),
      assumedDates: json['assumed_dates'] == true,
      totalFound: (json['total_found'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [destination, checkIn, checkOut, nights, adults, children, rooms, budget];
}

/// Kết quả một lượt chat từ backend.
class AiChatResponse {
  final String reply;
  final List<AiHotelPick> hotels;
  final Map<String, dynamic> criteria;
  final AiSearchSummary? summary;
  final List<String> quickReplies;

  const AiChatResponse({
    required this.reply,
    this.hotels = const [],
    this.criteria = const {},
    this.summary,
    this.quickReplies = const [],
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      reply: json['reply']?.toString() ?? '',
      hotels: (json['hotels'] as List?)
              ?.map((e) => AiHotelPick.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      criteria: json['criteria'] is Map
          ? Map<String, dynamic>.from(json['criteria'] as Map)
          : const {},
      summary: json['summary'] is Map
          ? AiSearchSummary.fromJson(Map<String, dynamic>.from(json['summary'] as Map))
          : null,
      quickReplies:
          (json['quick_replies'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }
}

/// Tin nhắn hiển thị trong khung chat.
class AiChatMessage extends Equatable {
  final bool isUser;
  final String text;
  final List<String> quickReplies;
  final bool isError;

  const AiChatMessage({
    required this.isUser,
    required this.text,
    this.quickReplies = const [],
    this.isError = false,
  });

  @override
  List<Object?> get props => [isUser, text, quickReplies, isError];
}
