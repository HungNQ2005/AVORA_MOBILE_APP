import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/features/booking/data/models/coupon_model.dart';
import 'package:avora_mobile/features/voucher/data/voucher_repository.dart';

/// Trạng thái của Ví Voucher Khách hàng
class VoucherWalletState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<CouponModel> vouchers;
  final String activeFilter; // 'ACTIVE', 'UPCOMING'
  final String searchQuery;

  const VoucherWalletState({
    this.isLoading = true,
    this.errorMessage,
    this.vouchers = const [],
    this.activeFilter = 'ACTIVE',
    this.searchQuery = '',
  });

  VoucherWalletState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<CouponModel>? vouchers,
    String? activeFilter,
    String? searchQuery,
  }) {
    return VoucherWalletState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      vouchers: vouchers ?? this.vouchers,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Danh sách voucher đã được lọc theo tab ('ACTIVE' hoặc 'UPCOMING') và từ khóa tìm kiếm
  List<CouponModel> get filteredVouchers {
    return vouchers.where((voucher) {
      // Xác định trạng thái của voucher
      final status = (voucher.status ?? (voucher.isCurrentlyValid ? 'ACTIVE' : 'EXPIRED')).toUpperCase();

      // Chỉ giữ lại voucher Đang hoạt động hoặc Sắp diễn ra
      if (activeFilter == 'ACTIVE' && status != 'ACTIVE') {
        return false;
      } else if (activeFilter == 'UPCOMING' && status != 'UPCOMING') {
        return false;
      }

      // Lọc theo từ khóa tìm kiếm
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final code = voucher.code.toLowerCase();
        final desc = voucher.discountDescription.toLowerCase();
        final title = voucher.discountTitle.toLowerCase();
        return code.contains(query) || desc.contains(query) || title.contains(query);
      }

      return true;
    }).toList();
  }

  int get activeCount => vouchers.where((v) => (v.status ?? (v.isCurrentlyValid ? 'ACTIVE' : 'EXPIRED')).toUpperCase() == 'ACTIVE').length;
  int get upcomingCount => vouchers.where((v) => (v.status ?? '').toUpperCase() == 'UPCOMING').length;

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        vouchers,
        activeFilter,
        searchQuery,
      ];
}

/// Notifier quản lý dữ liệu Ví Voucher của khách hàng
class VoucherWalletNotifier extends StateNotifier<VoucherWalletState> {
  final VoucherRepository _repository;

  VoucherWalletNotifier(this._repository) : super(const VoucherWalletState()) {
    loadVouchers();
  }

  /// Tải danh sách Voucher từ backend AVORA
  Future<void> loadVouchers({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearErrorMessage: true);
    }
    try {
      final list = await _repository.getCustomerVouchers();
      state = state.copyWith(
        isLoading: false,
        vouchers: list,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Đổi tab lọc trạng thái ('ALL', 'ACTIVE', 'UPCOMING', 'EXPIRED')
  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  /// Cập nhật từ khóa tìm kiếm voucher
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

/// Provider cung cấp StateNotifier của Voucher Wallet
final voucherWalletProvider =
    StateNotifierProvider<VoucherWalletNotifier, VoucherWalletState>((ref) {
  final repo = ref.watch(voucherRepositoryProvider);
  return VoucherWalletNotifier(repo);
});
