import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';

/// Trạng thái của màn hình Danh sách hóa đơn thanh toán
class InvoiceListState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<InvoiceListItemModel> invoices;
  final String searchQuery;
  final String activeFilter; // 'ALL', 'PAID', 'PENDING'

  const InvoiceListState({
    this.isLoading = true,
    this.errorMessage,
    this.invoices = const [],
    this.searchQuery = '',
    this.activeFilter = 'ALL',
  });

  InvoiceListState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<InvoiceListItemModel>? invoices,
    String? searchQuery,
    String? activeFilter,
  }) {
    return InvoiceListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      invoices: invoices ?? this.invoices,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  /// Danh sách hóa đơn đã lọc theo tab và từ khóa tìm kiếm
  List<InvoiceListItemModel> get filteredInvoices {
    return invoices.where((invoice) {
      // 1. Lọc theo tab trạng thái
      if (activeFilter == 'PAID' && !invoice.isPaid) {
        return false;
      } else if (activeFilter == 'PENDING' && invoice.isPaid) {
        return false;
      }

      // 2. Lọc theo từ khóa tìm kiếm
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchInvoiceNo =
            invoice.invoiceNumber.toLowerCase().contains(query);
        final matchLookup = invoice.lookupCode.toLowerCase().contains(query);
        final matchBookingCode =
            invoice.bookingCode.toLowerCase().contains(query);
        final matchHotel = invoice.hotelName.toLowerCase().contains(query);
        final matchTxn =
            invoice.transactionId?.toLowerCase().contains(query) ?? false;
        final matchGateway =
            invoice.gatewayRefId?.toLowerCase().contains(query) ?? false;

        return matchInvoiceNo ||
            matchLookup ||
            matchBookingCode ||
            matchHotel ||
            matchTxn ||
            matchGateway;
      }

      return true;
    }).toList();
  }

  int get totalCount => invoices.length;
  int get paidCount => invoices.where((i) => i.isPaid).length;
  int get pendingCount => invoices.where((i) => !i.isPaid).length;

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        invoices,
        searchQuery,
        activeFilter,
      ];
}

/// Notifier quản lý danh sách hóa đơn thanh toán
class InvoiceListNotifier extends StateNotifier<InvoiceListState> {
  final InvoiceRepository _repository;

  InvoiceListNotifier(this._repository) : super(const InvoiceListState()) {
    loadInvoices();
  }

  /// Tải danh sách hóa đơn từ backend AVORA
  Future<void> loadInvoices({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearErrorMessage: true);
    }
    try {
      final list = await _repository.fetchInvoices();
      state = state.copyWith(
        isLoading: false,
        invoices: list,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setActiveFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }
}

/// Provider cung cấp InvoiceListNotifier
final invoiceListNotifierProvider =
    StateNotifierProvider<InvoiceListNotifier, InvoiceListState>((ref) {
  final repository = ref.watch(invoiceRepositoryProvider);
  return InvoiceListNotifier(repository);
});

/// Provider tải chi tiết hóa đơn & giao dịch theo bookingId
final invoiceDetailProvider =
    FutureProvider.autoDispose.family<InvoiceDetailModel, String>(
        (ref, bookingId) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.fetchInvoiceDetail(bookingId);
});

