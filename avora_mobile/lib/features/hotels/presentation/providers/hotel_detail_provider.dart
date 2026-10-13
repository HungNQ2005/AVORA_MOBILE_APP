import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../home/presentation/providers/home_provider.dart';
import '../../data/models/hotel_detail_model.dart';
import '../../data/repositories/hotel_detail_repository.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class HotelDetailState extends Equatable {
  final bool isLoading;
  final HotelDetailModel? hotel;
  final String? errorMessage;
  final RoomTypeDetailModel? selectedRoomForBooking;
  final int activePhotoIndex;
  final bool isLightboxOpen;
  final bool isMapModalOpen;

  // Search parameters for room inventory
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final int rooms;

  const HotelDetailState({
    this.isLoading = false,
    this.hotel,
    this.errorMessage,
    this.selectedRoomForBooking,
    this.activePhotoIndex = 0,
    this.isLightboxOpen = false,
    this.isMapModalOpen = false,
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

  int get totalGuests => adults + children;

  int get guestsPerRoom => (totalGuests / (rooms > 0 ? rooms : 1)).ceil();

  String get formattedStayDates {
    final fmt = DateFormat('dd/MM');
    return '${fmt.format(checkIn)} – ${fmt.format(checkOut)}';
  }

  HotelDetailState copyWith({
    bool? isLoading,
    HotelDetailModel? hotel,
    String? errorMessage,
    bool clearError = false,
    RoomTypeDetailModel? selectedRoomForBooking,
    bool clearSelectedRoom = false,
    int? activePhotoIndex,
    bool? isLightboxOpen,
    bool? isMapModalOpen,
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
    int? children,
    int? rooms,
  }) {
    return HotelDetailState(
      isLoading: isLoading ?? this.isLoading,
      hotel: hotel ?? this.hotel,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedRoomForBooking: clearSelectedRoom
          ? null
          : (selectedRoomForBooking ?? this.selectedRoomForBooking),
      activePhotoIndex: activePhotoIndex ?? this.activePhotoIndex,
      isLightboxOpen: isLightboxOpen ?? this.isLightboxOpen,
      isMapModalOpen: isMapModalOpen ?? this.isMapModalOpen,
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
        hotel,
        errorMessage,
        selectedRoomForBooking,
        activePhotoIndex,
        isLightboxOpen,
        isMapModalOpen,
        checkIn,
        checkOut,
        adults,
        children,
        rooms,
      ];
}

// ─── Provider & Notifier ─────────────────────────────────────────────────────

final hotelDetailProvider =
    StateNotifierProvider.autoDispose.family<HotelDetailNotifier, HotelDetailState, String>(
  (ref, hotelId) {
    final repository = ref.watch(hotelDetailRepositoryProvider);
    final homeState = ref.watch(homeProvider);

    return HotelDetailNotifier(
      ref: ref,
      repository: repository,
      hotelId: hotelId,
      initialCheckIn: homeState.checkIn,
      initialCheckOut: homeState.checkOut,
      initialAdults: homeState.adults,
      initialChildren: homeState.children,
      initialRooms: homeState.rooms,
    );
  },
);

class HotelDetailNotifier extends StateNotifier<HotelDetailState> {
  final Ref _ref;
  final HotelDetailRepository _repository;
  final String _hotelId;

  HotelDetailNotifier({
    required Ref ref,
    required HotelDetailRepository repository,
    required String hotelId,
    required DateTime initialCheckIn,
    required DateTime initialCheckOut,
    required int initialAdults,
    required int initialChildren,
    required int initialRooms,
  })  : _ref = ref,
        _repository = repository,
        _hotelId = hotelId,
        super(HotelDetailState(
          isLoading: true,
          checkIn: initialCheckIn,
          checkOut: initialCheckOut,
          adults: initialAdults,
          children: initialChildren,
          rooms: initialRooms,
        )) {
    loadHotelDetail();
  }

  /// Tải thông tin chi tiết khách sạn từ backend
  Future<void> loadHotelDetail() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final dateFmt = DateFormat('yyyy-MM-dd');
      final hotel = await _repository.fetchHotelDetail(
        _hotelId,
        checkIn: dateFmt.format(state.checkIn),
        checkOut: dateFmt.format(state.checkOut),
        adults: state.adults,
        children: state.children,
        rooms: state.rooms,
      );

      state = state.copyWith(
        isLoading: false,
        hotel: hotel,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('ApiException: ', ''),
      );
    }
  }

  /// Toggle yêu thích và đồng bộ với Home Provider
  void toggleFavorite() {
    final currentHotelId = state.hotel?.hotelId ?? _hotelId;
    _ref.read(homeProvider.notifier).toggleFavorite(currentHotelId);
  }

  /// Kiểm tra xem khách sạn có đang trong danh sách yêu thích không
  bool isFavorite() {
    final currentHotelId = state.hotel?.hotelId ?? _hotelId;
    final homeState = _ref.read(homeProvider);
    return homeState.favorites.contains(currentHotelId);
  }

  void selectRoomForBooking(RoomTypeDetailModel? room) {
    state = state.copyWith(
      selectedRoomForBooking: room,
      clearSelectedRoom: room == null,
    );
  }

  void setActivePhotoIndex(int index) {
    state = state.copyWith(activePhotoIndex: index);
  }

  void setLightboxOpen(bool isOpen, [int? initialIndex]) {
    state = state.copyWith(
      isLightboxOpen: isOpen,
      activePhotoIndex: initialIndex ?? state.activePhotoIndex,
    );
  }

  void setMapModalOpen(bool isOpen) {
    state = state.copyWith(isMapModalOpen: isOpen);
  }

  void updateStayDates({DateTime? checkIn, DateTime? checkOut}) {
    state = state.copyWith(
      checkIn: checkIn ?? state.checkIn,
      checkOut: checkOut ?? state.checkOut,
    );
    loadHotelDetail();
  }

  void updateGuests({int? adults, int? children, int? rooms}) {
    state = state.copyWith(
      adults: adults ?? state.adults,
      children: children ?? state.children,
      rooms: rooms ?? state.rooms,
    );
    loadHotelDetail();
  }
}
