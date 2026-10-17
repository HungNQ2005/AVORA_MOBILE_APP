import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:avora_mobile/features/home/data/models/hotel_model.dart';

/// Bộ tham số tìm kiếm, lọc và sắp xếp khách sạn gửi lên `GET /api/hotels`.
class HotelSearchParams extends Equatable {
  final String destination;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int adults;
  final int children;
  final int rooms;
  final String priceRangeKey;
  final num? minPrice;
  final num? maxPrice;
  final List<int> starRatings;
  final num? minScore;
  final List<String> facilities;
  final String capacityFilter;
  final bool onlyAvailable;
  final String sortBy;

  const HotelSearchParams({
    this.destination = '',
    this.checkIn,
    this.checkOut,
    this.adults = 2,
    this.children = 0,
    this.rooms = 1,
    this.priceRangeKey = 'all',
    this.minPrice,
    this.maxPrice,
    this.starRatings = const [],
    this.minScore,
    this.facilities = const [],
    this.capacityFilter = 'all',
    this.onlyAvailable = false,
    this.sortBy = 'popularity',
  });

  int get totalGuests => adults + children;
  int get guestsPerRoom => (totalGuests / (rooms > 0 ? rooms : 1)).ceil();
  int get minRoomsRequired => (totalGuests / 5).ceil();

  int get nights {
    if (checkIn == null || checkOut == null) return 1;
    final diff = checkOut!.difference(checkIn!).inDays;
    return diff > 0 ? diff : 1;
  }

  /// Đếm số bộ lọc đang được kích hoạt (không tính sort và destination/dates/guests).
  int get activeFiltersCount {
    int count = 0;
    if (priceRangeKey != 'all') count++;
    if (starRatings.isNotEmpty) count += starRatings.length;
    if (minScore != null) count++;
    if (facilities.isNotEmpty) count += facilities.length;
    if (capacityFilter != 'all') count++;
    if (onlyAvailable) count++;
    return count;
  }

  /// Chuyển đổi tham số thành query parameters cho API.
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (destination.trim().isNotEmpty) {
      params['destination'] = destination.trim();
    }
    if (checkIn != null) {
      params['checkIn'] = DateFormat('yyyy-MM-dd').format(checkIn!);
    }
    if (checkOut != null) {
      params['checkOut'] = DateFormat('yyyy-MM-dd').format(checkOut!);
    }
    params['adults'] = adults;
    params['children'] = children;
    params['rooms'] = rooms;

    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;

    if (starRatings.isNotEmpty) {
      params['starRatings'] = starRatings.join(',');
    }
    if (minScore != null) {
      params['minScore'] = minScore;
    }
    if (facilities.isNotEmpty) {
      params['facilities'] = facilities.join(',');
    }
    if (capacityFilter != 'all') {
      params['capacityFilter'] = capacityFilter;
    }
    if (onlyAvailable) {
      params['onlyAvailable'] = 'true';
    }
    if (sortBy.isNotEmpty && sortBy != 'popularity') {
      params['sortBy'] = sortBy;
    }

    return params;
  }

  HotelSearchParams copyWith({
    String? destination,
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
    int? children,
    int? rooms,
    String? priceRangeKey,
    num? minPrice,
    bool clearMinPrice = false,
    num? maxPrice,
    bool clearMaxPrice = false,
    List<int>? starRatings,
    num? minScore,
    bool clearMinScore = false,
    List<String>? facilities,
    String? capacityFilter,
    bool? onlyAvailable,
    String? sortBy,
  }) {
    return HotelSearchParams(
      destination: destination ?? this.destination,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      rooms: rooms ?? this.rooms,
      priceRangeKey: priceRangeKey ?? this.priceRangeKey,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      starRatings: starRatings ?? this.starRatings,
      minScore: clearMinScore ? null : (minScore ?? this.minScore),
      facilities: facilities ?? this.facilities,
      capacityFilter: capacityFilter ?? this.capacityFilter,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
        destination,
        checkIn,
        checkOut,
        adults,
        children,
        rooms,
        priceRangeKey,
        minPrice,
        maxPrice,
        starRatings,
        minScore,
        facilities,
        capacityFilter,
        onlyAvailable,
        sortBy,
      ];
}

/// Thống kê số lượng khách sạn cho từng facet filter trả về từ backend.
class FilterStats extends Equatable {
  final int totalCount;
  final int under1m2Count;
  final int from1m2To2m5Count;
  final int from2m5To5mCount;
  final int above5mCount;
  final int star5Count;
  final int star4Count;
  final int star3Count;
  final int rating9Count;
  final int rating8Count;
  final int rating7Count;
  final int beachCount;
  final int poolCount;
  final int breakfastCount;
  final int freeCancelCount;
  final int capacityAllCount;
  final int capacityStandardDoubleCount;
  final int capacityStandardTwoBedsCount;
  final int capacityWithExtraBedCount;

  const FilterStats({
    this.totalCount = 0,
    this.under1m2Count = 0,
    this.from1m2To2m5Count = 0,
    this.from2m5To5mCount = 0,
    this.above5mCount = 0,
    this.star5Count = 0,
    this.star4Count = 0,
    this.star3Count = 0,
    this.rating9Count = 0,
    this.rating8Count = 0,
    this.rating7Count = 0,
    this.beachCount = 0,
    this.poolCount = 0,
    this.breakfastCount = 0,
    this.freeCancelCount = 0,
    this.capacityAllCount = 0,
    this.capacityStandardDoubleCount = 0,
    this.capacityStandardTwoBedsCount = 0,
    this.capacityWithExtraBedCount = 0,
  });

  factory FilterStats.fromJson(Map<String, dynamic> json) {
    final prices = (json['priceRanges'] as Map?) ?? {};
    final stars = (json['stars'] as Map?) ?? {};
    final ratings = (json['ratings'] as Map?) ?? {};
    final facilities = (json['popularFacilities'] as Map?) ?? {};
    final capacities = (json['capacities'] as Map?) ?? {};

    return FilterStats(
      totalCount: (prices['all'] as num?)?.toInt() ?? 0,
      under1m2Count: (prices['under1m2'] as num?)?.toInt() ?? 0,
      from1m2To2m5Count: (prices['from1m2To2m5'] as num?)?.toInt() ?? 0,
      from2m5To5mCount: (prices['from2m5To5m'] as num?)?.toInt() ?? 0,
      above5mCount: (prices['above5m'] as num?)?.toInt() ?? 0,
      star5Count: (stars['5'] as num?)?.toInt() ?? 0,
      star4Count: (stars['4'] as num?)?.toInt() ?? 0,
      star3Count: (stars['3'] as num?)?.toInt() ?? 0,
      rating9Count: (ratings['9'] as num?)?.toInt() ?? 0,
      rating8Count: (ratings['8'] as num?)?.toInt() ?? 0,
      rating7Count: (ratings['7'] as num?)?.toInt() ?? 0,
      beachCount: (facilities['beach'] as num?)?.toInt() ?? 0,
      poolCount: (facilities['pool'] as num?)?.toInt() ?? 0,
      breakfastCount: (facilities['breakfast'] as num?)?.toInt() ?? 0,
      freeCancelCount: (facilities['freeCancel'] as num?)?.toInt() ?? 0,
      capacityAllCount: (capacities['all'] as num?)?.toInt() ?? 0,
      capacityStandardDoubleCount:
          (capacities['standard_double'] as num?)?.toInt() ?? 0,
      capacityStandardTwoBedsCount:
          (capacities['standard_two_beds'] as num?)?.toInt() ?? 0,
      capacityWithExtraBedCount:
          (capacities['with_extra_bed'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        totalCount,
        under1m2Count,
        from1m2To2m5Count,
        from2m5To5mCount,
        above5mCount,
        star5Count,
        star4Count,
        star3Count,
        rating9Count,
        rating8Count,
        rating7Count,
        beachCount,
        poolCount,
        breakfastCount,
        freeCancelCount,
        capacityAllCount,
        capacityStandardDoubleCount,
        capacityStandardTwoBedsCount,
        capacityWithExtraBedCount,
      ];
}

/// Kết quả tìm kiếm khách sạn trả về từ API Backend.
class HotelSearchResult extends Equatable {
  final List<HotelModel> hotels;
  final int total;
  final FilterStats filterStats;
  final bool exceededCapacity;
  final String? message;
  final int? minRoomsRequired;
  final int? guestsPerRoom;

  const HotelSearchResult({
    this.hotels = const [],
    this.total = 0,
    this.filterStats = const FilterStats(),
    this.exceededCapacity = false,
    this.message,
    this.minRoomsRequired,
    this.guestsPerRoom,
  });

  @override
  List<Object?> get props => [
        hotels,
        total,
        filterStats,
        exceededCapacity,
        message,
        minRoomsRequired,
        guestsPerRoom,
      ];
}
