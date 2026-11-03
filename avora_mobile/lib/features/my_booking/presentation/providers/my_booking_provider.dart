import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/booking_item_model.dart';
import '../../data/repositories/my_booking_repository.dart';

/// Trạng thái của màn hình Quản lý đặt phòng & Lịch sử
class MyBookingState extends Equatable {
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final String? actionSuccessMessage;
  final String activeTab; // 'all', 'upcoming', 'completed', 'cancelled'
  final String searchQuery;
  final String timeRange; // 'all', 'last_30_days', 'last_90_days', 'this_month', 'last_month', 'this_year'
  final bool requireVatOnly;
  final List<BookingItemModel> bookings;
  final BookingCountsModel counts;
  final List<int> availableYears;
  final BookingVoucherModel? selectedVoucher;
  final bool isLoadingVoucher;

  const MyBookingState({
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
    this.actionSuccessMessage,
    this.activeTab = 'all',
    this.searchQuery = '',
    this.timeRange = 'all',
    this.requireVatOnly = false,
    this.bookings = const [],
    this.counts = const BookingCountsModel(),
    this.availableYears = const [],
    this.selectedVoucher,
    this.isLoadingVoucher = false,
  });

  MyBookingState copyWith({
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionSuccessMessage,
    bool clearActionSuccessMessage = false,
    String? activeTab,
    String? searchQuery,
    String? timeRange,
    bool? requireVatOnly,
    List<BookingItemModel>? bookings,
    BookingCountsModel? counts,
    List<int>? availableYears,
    BookingVoucherModel? selectedVoucher,
    bool clearSelectedVoucher = false,
    bool? isLoadingVoucher,
  }) {
    return MyBookingState(
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionSuccessMessage: clearActionSuccessMessage
          ? null
          : (actionSuccessMessage ?? this.actionSuccessMessage),
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      timeRange: timeRange ?? this.timeRange,
      requireVatOnly: requireVatOnly ?? this.requireVatOnly,
      bookings: bookings ?? this.bookings,
      counts: counts ?? this.counts,
      availableYears: availableYears ?? this.availableYears,
      selectedVoucher: clearSelectedVoucher
          ? null
          : (selectedVoucher ?? this.selectedVoucher),
      isLoadingVoucher: isLoadingVoucher ?? this.isLoadingVoucher,
    );
  }

  /// Danh sách bookings đã lọc qua điều kiện VAT nếu được bật
  List<BookingItemModel> get visibleBookings {
    if (!requireVatOnly) return bookings;
    return bookings
        .where((b) => b.payment.hasVatInvoice || b.category == 'completed')
        .toList();
  }

  /// Chuyến đi sắp tới
  List<BookingItemModel> get upcomingBookings =>
      visibleBookings.where((b) => b.category == 'upcoming').toList();

  /// Kỳ nghỉ đã hoàn thành
  List<BookingItemModel> get completedBookings =>
      visibleBookings.where((b) => b.category == 'completed').toList();

  /// Đơn đặt phòng đã hủy
  List<BookingItemModel> get cancelledBookings =>
      visibleBookings.where((b) => b.category == 'cancelled').toList();

  @override
  List<Object?> get props => [
        isLoading,
        isActionLoading,
        errorMessage,
        actionSuccessMessage,
        activeTab,
        searchQuery,
        timeRange,
        requireVatOnly,
        bookings,
        counts,
        availableYears,
        selectedVoucher,
        isLoadingVoucher,
      ];
}

/// Notifier điều khiển logic và dữ liệu đặt phòng
class MyBookingNotifier extends StateNotifier<MyBookingState> {
  final MyBookingRepository _repository;

  MyBookingNotifier(this._repository) : super(const MyBookingState()) {
    loadBookings();
  }

  /// Tải danh sách đơn đặt phòng từ API backend
  Future<void> loadBookings({
    String? overrideTab,
    String? overrideSearch,
    String? overrideTimeRange,
    bool silent = false,
  }) async {
    final targetTab = overrideTab ?? state.activeTab;
    final targetSearch = overrideSearch ?? state.searchQuery;
    final targetTimeRange = overrideTimeRange ?? state.timeRange;

    if (!silent) {
      state = state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
        activeTab: targetTab,
        searchQuery: targetSearch,
        timeRange: targetTimeRange,
      );
    }

    try {
      final response = await _repository.fetchMyBookings(
        status: targetTab,
        search: targetSearch,
        timeRange: targetTimeRange,
      );

      state = state.copyWith(
        isLoading: false,
        bookings: response.bookings,
        counts: response.counts,
        availableYears: response.availableYears,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Chuyển tab lọc trạng thái ('all', 'upcoming', 'completed', 'cancelled')
  void changeTab(String newTab) {
    if (state.activeTab == newTab) return;
    state = state.copyWith(activeTab: newTab);
    loadBookings(overrideTab: newTab);
  }

  /// Tìm kiếm theo từ khóa
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadBookings(overrideSearch: query);
  }

  /// Lọc theo khoảng thời gian đặt phòng
  void setTimeRange(String newTimeRange) {
    state = state.copyWith(timeRange: newTimeRange);
    loadBookings(overrideTimeRange: newTimeRange);
  }

  /// Bật/tắt chỉ lọc đơn có hóa đơn VAT
  void toggleVatOnly() {
    state = state.copyWith(requireVatOnly: !state.requireVatOnly);
  }

  /// Tải thông tin Voucher chi tiết của đơn
  Future<void> loadVoucher(String bookingId) async {
    state = state.copyWith(
      isLoadingVoucher: true,
      clearSelectedVoucher: true,
      clearErrorMessage: true,
    );

    try {
      final voucher = await _repository.fetchBookingVoucher(bookingId);
      state = state.copyWith(
        isLoadingVoucher: false,
        selectedVoucher: voucher,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingVoucher: false,
        errorMessage: 'Không thể tải voucher: ${e.toString().replaceFirst("Exception: ", "")}',
      );
    }
  }

  /// Đóng modal Voucher
  void clearSelectedVoucher() {
    state = state.copyWith(clearSelectedVoucher: true);
  }

  /// Cập nhật thông tin khách lưu trú
  Future<bool> updateGuestInfo(
    String bookingId, {
    required String guestName,
    required String guestPhone,
    String? specialRequest,
  }) async {
    state = state.copyWith(
      isActionLoading: true,
      clearErrorMessage: true,
      clearActionSuccessMessage: true,
    );

    try {
      await _repository.updateGuestInfo(
        bookingId,
        guestName: guestName,
        guestPhone: guestPhone,
        specialRequest: specialRequest,
      );

      state = state.copyWith(
        isActionLoading: false,
        actionSuccessMessage: 'Cập nhật thông tin khách thành công!',
      );

      // Tải lại danh sách đơn để cập nhật UI
      await loadBookings(silent: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Đổi ngày lưu trú
  Future<bool> changeBookingDates(
    String bookingId, {
    required String checkInDate,
    required String checkOutDate,
    bool confirmCouponRemoval = false,
  }) async {
    state = state.copyWith(
      isActionLoading: true,
      clearErrorMessage: true,
      clearActionSuccessMessage: true,
    );

    try {
      await _repository.changeBookingDates(
        bookingId,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        confirmCouponRemoval: confirmCouponRemoval,
      );

      state = state.copyWith(
        isActionLoading: false,
        actionSuccessMessage: 'Đổi ngày lưu trú thành công!',
      );

      await loadBookings(silent: true);
      return true;
    } on CouponRemovalRequiredException {
      state = state.copyWith(isActionLoading: false);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Hủy đơn đặt phòng
  Future<bool> cancelBooking(
    String bookingId, {
    required String reason,
  }) async {
    state = state.copyWith(
      isActionLoading: true,
      clearErrorMessage: true,
      clearActionSuccessMessage: true,
    );

    try {
      final message = await _repository.cancelBooking(
        bookingId,
        reason: reason,
      );

      state = state.copyWith(
        isActionLoading: false,
        actionSuccessMessage: message,
      );

      await loadBookings(silent: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Xóa các thông báo lỗi và thành công
  void clearMessages() {
    state = state.copyWith(
      clearErrorMessage: true,
      clearActionSuccessMessage: true,
    );
  }
}

/// Provider toàn cục cho MyBooking
final myBookingNotifierProvider =
    StateNotifierProvider<MyBookingNotifier, MyBookingState>((ref) {
  final repository = ref.watch(myBookingRepositoryProvider);
  return MyBookingNotifier(repository);
});
