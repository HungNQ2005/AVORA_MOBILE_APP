import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/features/home/data/models/hotel_model.dart';
import 'package:avora_mobile/features/home/presentation/providers/home_provider.dart';
import 'package:avora_mobile/features/hotels/data/models/hotel_filter_params.dart';
import 'package:avora_mobile/features/hotels/data/repositories/hotel_repository.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class HotelSearchState extends Equatable {
  final bool isLoading;
  final List<HotelModel> hotels;
  final int total;
  final FilterStats filterStats;
  final HotelSearchParams params;
  final String? errorMessage;
  final bool exceededCapacity;
  final String? capacityMessage;
  final Set<String> favorites;

  const HotelSearchState({
    this.isLoading = false,
    this.hotels = const [],
    this.total = 0,
    this.filterStats = const FilterStats(),
    required this.params,
    this.errorMessage,
    this.exceededCapacity = false,
    this.capacityMessage,
    this.favorites = const {},
  });

  HotelSearchState copyWith({
    bool? isLoading,
    List<HotelModel>? hotels,
    int? total,
    FilterStats? filterStats,
    HotelSearchParams? params,
    String? errorMessage,
    bool clearError = false,
    bool? exceededCapacity,
    String? capacityMessage,
    bool clearCapacityMessage = false,
    Set<String>? favorites,
  }) {
    return HotelSearchState(
      isLoading: isLoading ?? this.isLoading,
      hotels: hotels ?? this.hotels,
      total: total ?? this.total,
      filterStats: filterStats ?? this.filterStats,
      params: params ?? this.params,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      exceededCapacity: exceededCapacity ?? this.exceededCapacity,
      capacityMessage: clearCapacityMessage
          ? null
          : (capacityMessage ?? this.capacityMessage),
      favorites: favorites ?? this.favorites,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        hotels,
        total,
        filterStats,
        params,
        errorMessage,
        exceededCapacity,
        capacityMessage,
        favorites,
      ];
}

// ─── Notifier Provider ───────────────────────────────────────────────────────

final hotelSearchProvider =
    StateNotifierProvider<HotelSearchNotifier, HotelSearchState>((ref) {
  final repository = ref.watch(hotelRepositoryProvider);
  // Đồng bộ danh sách yêu thích từ HomeProvider nếu có
  final homeFavorites = ref.watch(homeProvider).favorites;
  return HotelSearchNotifier(repository, homeFavorites: homeFavorites);
});

class HotelSearchNotifier extends StateNotifier<HotelSearchState> {
  final HotelRepository _repository;

  HotelSearchNotifier(
    this._repository, {
    Set<String> homeFavorites = const {},
  }) : super(HotelSearchState(
          params: HotelSearchParams(
            checkIn: DateTime.now(),
            checkOut: DateTime.now().add(const Duration(days: 2)),
          ),
          favorites: homeFavorites,
        ));

  /// Thực hiện tìm kiếm với bộ tham số mới hoặc tham số hiện tại.
  Future<void> performSearch({HotelSearchParams? newParams}) async {
    final queryParams = newParams ?? state.params;

    // Kiểm tra quy tắc sức chứa: tối đa 5 người/phòng
    final guestsPerRoom = queryParams.guestsPerRoom;
    if (guestsPerRoom > 5) {
      final minRooms = queryParams.minRoomsRequired;
      state = state.copyWith(
        isLoading: false,
        hotels: const [],
        total: 0,
        exceededCapacity: true,
        capacityMessage:
            'Không có loại phòng nào như vậy. Sức chứa tối đa của 1 phòng là 5 người '
            '(2 giường tiêu chuẩn × 2 người = 4 người, có thêm 1 giường phụ × 1 người = tối đa 5 người). '
            'Bạn đang tìm cho $guestsPerRoom người/phòng, vượt quá sức chứa tối đa. '
            'Vui lòng tăng lên tối thiểu $minRooms phòng hoặc giảm số lượng người.',
        params: queryParams,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearCapacityMessage: true,
      exceededCapacity: false,
      params: queryParams,
    );

    try {
      final result = await _repository.searchHotels(queryParams);

      if (result.exceededCapacity) {
        state = state.copyWith(
          isLoading: false,
          hotels: const [],
          total: 0,
          filterStats: result.filterStats,
          exceededCapacity: true,
          capacityMessage: result.message ??
              'Vượt quá sức chứa tối đa của phòng. Vui lòng tăng số lượng phòng.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          hotels: result.hotels,
          total: result.total,
          filterStats: result.filterStats,
          exceededCapacity: false,
          clearCapacityMessage: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('ApiException: ', ''),
      );
    }
  }

  /// Cập nhật điểm đến và tìm kiếm lại.
  void setDestination(String destination) {
    final updated = state.params.copyWith(destination: destination);
    performSearch(newParams: updated);
  }

  /// Cập nhật ngày nhận/trả phòng và tìm kiếm lại.
  void setDates(DateTime checkIn, DateTime checkOut) {
    final updated = state.params.copyWith(checkIn: checkIn, checkOut: checkOut);
    performSearch(newParams: updated);
  }

  /// Cập nhật số khách và phòng và tìm kiếm lại.
  void setGuestsAndRooms({int? adults, int? children, int? rooms}) {
    final updated = state.params.copyWith(
      adults: adults ?? state.params.adults,
      children: children ?? state.params.children,
      rooms: rooms ?? state.params.rooms,
    );
    performSearch(newParams: updated);
  }

  /// Đổi tiêu chí sắp xếp.
  void setSortBy(String sortBy) {
    if (state.params.sortBy == sortBy) return;
    final updated = state.params.copyWith(sortBy: sortBy);
    performSearch(newParams: updated);
  }

  /// Cập nhật khoảng giá theo chuẩn của Web AVORA.
  void setPriceRange(String rangeKey) {
    num? minPrice;
    num? maxPrice;

    switch (rangeKey) {
      case '0-1.2m':
        minPrice = 0;
        maxPrice = 1200000;
        break;
      case '1.2m-2.5m':
        minPrice = 1200000;
        maxPrice = 2500000;
        break;
      case '2.5m-5m':
        minPrice = 2500000;
        maxPrice = 5000000;
        break;
      case 'above-5m':
        minPrice = 5000000;
        maxPrice = null;
        break;
      case 'all':
      default:
        minPrice = null;
        maxPrice = null;
        break;
    }

    final updated = state.params.copyWith(
      priceRangeKey: rangeKey,
      minPrice: minPrice,
      clearMinPrice: minPrice == null,
      maxPrice: maxPrice,
      clearMaxPrice: maxPrice == null,
    );
    performSearch(newParams: updated);
  }

  /// Bật/tắt số sao lọc.
  void toggleStar(int star) {
    final currentStars = List<int>.from(state.params.starRatings);
    if (currentStars.contains(star)) {
      currentStars.remove(star);
    } else {
      currentStars.add(star);
    }
    final updated = state.params.copyWith(starRatings: currentStars);
    performSearch(newParams: updated);
  }

  /// Đặt điểm đánh giá tối thiểu.
  void setMinScore(num? minScore) {
    final updated = state.params.copyWith(
      minScore: minScore,
      clearMinScore: minScore == null,
    );
    performSearch(newParams: updated);
  }

  /// Bật/tắt tiện nghi.
  void toggleFacility(String facility) {
    final current = List<String>.from(state.params.facilities);
    if (current.contains(facility)) {
      current.remove(facility);
    } else {
      current.add(facility);
    }
    final updated = state.params.copyWith(facilities: current);
    performSearch(newParams: updated);
  }

  /// Đổi bộ lọc sức chứa & loại giường.
  void setCapacityFilter(String capacity) {
    final updated = state.params.copyWith(capacityFilter: capacity);
    performSearch(newParams: updated);
  }

  /// Bật/tắt chỉ hiển thị phòng còn trống.
  void setOnlyAvailable(bool onlyAvailable) {
    final updated = state.params.copyWith(onlyAvailable: onlyAvailable);
    performSearch(newParams: updated);
  }

  /// Áp dụng toàn bộ bộ lọc từ Modal Filter Sheet.
  void applyAllFilters({
    required String priceRangeKey,
    required List<int> starRatings,
    required num? minScore,
    required List<String> facilities,
    required String capacityFilter,
    required bool onlyAvailable,
  }) {
    num? minPrice;
    num? maxPrice;

    switch (priceRangeKey) {
      case '0-1.2m':
        minPrice = 0;
        maxPrice = 1200000;
        break;
      case '1.2m-2.5m':
        minPrice = 1200000;
        maxPrice = 2500000;
        break;
      case '2.5m-5m':
        minPrice = 2500000;
        maxPrice = 5000000;
        break;
      case 'above-5m':
        minPrice = 5000000;
        maxPrice = null;
        break;
      case 'all':
      default:
        minPrice = null;
        maxPrice = null;
        break;
    }

    final updated = state.params.copyWith(
      priceRangeKey: priceRangeKey,
      minPrice: minPrice,
      clearMinPrice: minPrice == null,
      maxPrice: maxPrice,
      clearMaxPrice: maxPrice == null,
      starRatings: starRatings,
      minScore: minScore,
      clearMinScore: minScore == null,
      facilities: facilities,
      capacityFilter: capacityFilter,
      onlyAvailable: onlyAvailable,
    );

    performSearch(newParams: updated);
  }

  /// Đặt lại toàn bộ bộ lọc về mặc định (giữ nguyên destination, dates, guests và sort).
  void resetFilters() {
    final reset = state.params.copyWith(
      priceRangeKey: 'all',
      clearMinPrice: true,
      clearMaxPrice: true,
      starRatings: const [],
      clearMinScore: true,
      facilities: const [],
      capacityFilter: 'all',
      onlyAvailable: false,
    );
    performSearch(newParams: reset);
  }

  /// Toggle yêu thích khách sạn.
  void toggleFavorite(String hotelId) {
    final updated = Set<String>.from(state.favorites);
    if (updated.contains(hotelId)) {
      updated.remove(hotelId);
    } else {
      updated.add(hotelId);
    }
    state = state.copyWith(favorites: updated);
  }

  /// Thử lại khi gặp lỗi.
  Future<void> retry() => performSearch();
}
