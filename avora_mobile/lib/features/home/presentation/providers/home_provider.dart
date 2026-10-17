import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/hotel_model.dart';
import '../../data/repositories/home_repository.dart';

// ─── Home State ───────────────────────────────────────────────────────────────

class HomeState extends Equatable {
  final bool isLoading;
  final List<HotelModel> hotels;
  final List<TrendingDestination> destinations;
  final String? errorMessage;
  final Set<String> favorites;
  final Set<String> activeFilters;

  // Search Parameters
  final String destination;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final int rooms;

  const HomeState({
    this.isLoading = false,
    this.hotels = const [],
    this.destinations = const [],
    this.errorMessage,
    this.favorites = const {},
    this.activeFilters = const {},
    required this.destination,
    required this.checkIn,
    required this.checkOut,
    this.adults = 2,
    this.children = 0,
    this.rooms = 1,
  });

  int get nights {
    final diff = checkOut.difference(checkIn).inDays;
    return diff > 0 ? diff : 1;
  }

  HomeState copyWith({
    bool? isLoading,
    List<HotelModel>? hotels,
    List<TrendingDestination>? destinations,
    String? errorMessage,
    bool clearError = false,
    Set<String>? favorites,
    Set<String>? activeFilters,
    String? destination,
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
    int? children,
    int? rooms,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      hotels: hotels ?? this.hotels,
      destinations: destinations ?? this.destinations,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      favorites: favorites ?? this.favorites,
      activeFilters: activeFilters ?? this.activeFilters,
      destination: destination ?? this.destination,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      rooms: rooms ?? this.rooms,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        hotels,
        destinations,
        errorMessage,
        favorites,
        activeFilters,
        destination,
        checkIn,
        checkOut,
        adults,
        children,
        rooms,
      ];
}

// ─── Home Notifier ────────────────────────────────────────────────────────────

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier(ref.watch(homeRepositoryProvider));
});

class HomeNotifier extends StateNotifier<HomeState> {
  final HomeRepository _repository;

  HomeNotifier(this._repository)
      : super(HomeState(
          destination: '',
          checkIn: DateTime.now(),
          checkOut: DateTime.now().add(const Duration(days: 2)),
        )) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      destinations: _repository.getTrendingDestinations(),
    );

    try {
      final hotels = await _repository.fetchHotels();
      state = state.copyWith(
        isLoading: false,
        hotels: hotels,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Toggle trạng thái yêu thích của một khách sạn.
  void toggleFavorite(String hotelId) {
    final updated = Set<String>.from(state.favorites);
    if (updated.contains(hotelId)) {
      updated.remove(hotelId);
    } else {
      updated.add(hotelId);
    }
    state = state.copyWith(favorites: updated);
  }

  /// Toggle bộ lọc nhanh (nearby, freeCancel, payAtProperty, geniusOffer).
  void toggleFilter(String filterKey) {
    final updated = Set<String>.from(state.activeFilters);
    if (updated.contains(filterKey)) {
      updated.remove(filterKey);
    } else {
      updated.add(filterKey);
    }
    state = state.copyWith(activeFilters: updated);
  }

  /// Cập nhật điểm đến tìm kiếm.
  void setDestination(String destination) {
    state = state.copyWith(destination: destination);
  }

  /// Cập nhật ngày nhận/trả phòng.
  void setDates(DateTime checkIn, DateTime checkOut) {
    state = state.copyWith(checkIn: checkIn, checkOut: checkOut);
  }

  /// Cập nhật số lượng khách và phòng.
  void setGuestsAndRooms({int? adults, int? children, int? rooms}) {
    state = state.copyWith(
      adults: adults ?? state.adults,
      children: children ?? state.children,
      rooms: rooms ?? state.rooms,
    );
  }

  /// Làm mới dữ liệu.
  Future<void> refresh() => loadInitialData();
}
