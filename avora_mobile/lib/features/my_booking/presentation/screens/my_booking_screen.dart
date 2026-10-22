import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/core/router/app_router.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';

import '../../data/models/booking_item_model.dart';
import '../../data/repositories/my_booking_repository.dart';
import '../providers/my_booking_provider.dart';
import '../widgets/booking_card.dart';
import '../widgets/booking_filter_bar.dart';
import '../widgets/booking_support_banner.dart';
import '../widgets/booking_voucher_sheet.dart';
import '../widgets/cancel_booking_modal.dart';
import '../widgets/date_change_modal.dart';
import '../widgets/edit_guest_modal.dart';
import '../widgets/review_widget_modal.dart';

/// Màn hình Quản lý đặt phòng và lịch sử lưu trú cá nhân
/// Hỗ trợ cả người dùng thông thường và Vendor (đối tác quản lý chỗ nghỉ)
/// Thiết kế đồng bộ chuẩn 1:1 từ phiên bản Web OTA Avora (MyBookingsPage.jsx)
class MyBookingScreen extends ConsumerStatefulWidget {
  const MyBookingScreen({super.key});

  @override
  ConsumerState<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends ConsumerState<MyBookingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myBookingNotifierProvider.notifier).loadBookings();
    });
  }

  // ─── Modal Handlers ────────────────────────────────────────────────────────

  /// Mở Voucher điện tử (E-Ticket)
  Future<void> _handleOpenVoucher(BookingItemModel booking) async {
    final notifier = ref.read(myBookingNotifierProvider.notifier);

    // Hiển thị dialog loading tạm thời trong lúc nạp voucher
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF003580),
        ),
      ),
    );

    await notifier.loadVoucher(booking.bookingId);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // đóng loading dialog

    final state = ref.read(myBookingNotifierProvider);
    if (state.selectedVoucher != null) {
      await BookingVoucherSheet.show(context, state.selectedVoucher!);
    } else if (state.errorMessage != null) {
      _showSnackBar(state.errorMessage!, isError: true);
    }
  }

  /// Mở modal sửa thông tin khách
  Future<void> _handleOpenEditGuest(BookingItemModel booking) async {
    final notifier = ref.read(myBookingNotifierProvider.notifier);

    final success = await EditGuestModal.show(
      context,
      booking: booking,
      onSave: ({
        required String guestName,
        required String guestPhone,
        String? specialRequest,
      }) {
        return notifier.updateGuestInfo(
          booking.bookingId,
          guestName: guestName,
          guestPhone: guestPhone,
          specialRequest: specialRequest,
        );
      },
    );

    if (success == true && mounted) {
      _showSnackBar('Cập nhật thông tin khách thành công!');
    }
  }

  /// Mở modal đổi ngày lưu trú
  Future<void> _handleOpenDateChange(BookingItemModel booking) async {
    final notifier = ref.read(myBookingNotifierProvider.notifier);

    final success = await DateChangeModal.show(
      context,
      booking: booking,
      onConfirmDateChange: ({
        required String checkInDate,
        required String checkOutDate,
      }) {
        return notifier.changeBookingDates(
          booking.bookingId,
          checkInDate: checkInDate,
          checkOutDate: checkOutDate,
        );
      },
    );

    if (success == true && mounted) {
      _showSnackBar('Đổi ngày lưu trú thành công!');
    }
  }

  /// Mở modal xác nhận hủy phòng
  Future<void> _handleOpenCancel(BookingItemModel booking) async {
    final notifier = ref.read(myBookingNotifierProvider.notifier);

    final success = await CancelBookingModal.show(
      context,
      booking: booking,
      onConfirmCancel: ({required String reason}) {
        return notifier.cancelBooking(
          booking.bookingId,
          reason: reason,
        );
      },
    );

    if (success == true && mounted) {
      _showSnackBar('Đã hủy đơn đặt phòng thành công!');
    }
  }

  Future<void> _handleOpenReview(BookingItemModel booking) async {
    await ReviewWidgetModal.show(
      context,
      booking: booking,
      repository: ref.read(myBookingRepositoryProvider),
    );
  }

  /// Đặt lại phòng tại khách sạn này
  void _handleRebook(BookingItemModel booking) {
    if (booking.hotel.hotelId.isNotEmpty) {
      context.push(AppRoutes.hotelDetailPath(booking.hotel.hotelId));
    } else {
      context.push(AppRoutes.hotelSearch);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(myBookingNotifierProvider);
    final bookingNotifier = ref.read(myBookingNotifierProvider.notifier);

    // Xác định thông tin vai trò người dùng (Vendor / Khách hàng)
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthSuccess ? authState.user : null;
    final userRole = (user?.role ?? '').toUpperCase();
    final isVendor = userRole.contains('VEN') || userRole.contains('VENDOR');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003580),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản lý Đặt Chỗ & Lịch Sử',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                if (isVendor) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 2, right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'VENDOR / ĐỐI TÁC',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
                const Text(
                  'Trung tâm điều hành chuyến đi Avora',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFBFDBFE),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 21),
            tooltip: 'Làm mới',
            onPressed: () => bookingNotifier.loadBookings(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── 1. BỘ LỌC TABS & TÌM KIẾM ──────────────────────────────────
          BookingFilterBar(
            activeTab: bookingState.activeTab,
            onTabChange: (tab) => bookingNotifier.changeTab(tab),
            counts: bookingState.counts,
            searchQuery: bookingState.searchQuery,
            onSearchSubmitted: (q) => bookingNotifier.setSearchQuery(q),
            timeRange: bookingState.timeRange,
            onTimeRangeChanged: (tr) => bookingNotifier.setTimeRange(tr),
            availableYears: bookingState.availableYears,
            requireVatOnly: bookingState.requireVatOnly,
            onToggleVatOnly: () => bookingNotifier.toggleVatOnly(),
          ),

          // ─── 2. DANH SÁCH HOẶC TRẠNG THÁI RỖNG / LOADING ─────────────────
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF003580),
              onRefresh: () => bookingNotifier.loadBookings(silent: true),
              child: _buildBodyContent(bookingState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(MyBookingState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF003580)),
            SizedBox(height: 14),
            Text(
              'Đang tải danh sách đặt phòng...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (state.errorMessage != null && state.bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(myBookingNotifierProvider.notifier).loadBookings(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003580),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final visibleBookings = state.visibleBookings;

    // Không có kết quả nào
    if (visibleBookings.isEmpty) {
      return _buildEmptyState(state);
    }

    // Hiển thị danh sách booking theo dạng các Section hoặc Danh sách phẳng
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ─── NẾU CHỌN TAB "TẤT CẢ ĐƠN" → PHÂN KHỐI THEO 3 SECTION CHUẨN WEB ───
        if (state.activeTab == 'all') ...[
          // Section Sắp tới
          if (state.upcomingBookings.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Chuyến Đi Sắp Tới',
              dotColor: const Color(0xFF10B981),
              countBadge: '${state.upcomingBookings.length} đơn',
            ),
            ...state.upcomingBookings.map((b) => _buildBookingCard(b)),
            const SizedBox(height: 10),
          ],

          // Section Đã hoàn thành
          if (state.completedBookings.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Kỳ Nghỉ Đã Hoàn Thành',
              dotColor: const Color(0xFF3B82F6),
              countBadge: '${state.completedBookings.length} kỳ nghỉ',
            ),
            ...state.completedBookings.map((b) => _buildBookingCard(b)),
            const SizedBox(height: 10),
          ],

          // Section Đã hủy
          if (state.cancelledBookings.isNotEmpty) ...[
            _buildSectionHeader(
              title: 'Đơn Đặt Phòng Đã Hủy',
              dotColor: const Color(0xFF94A3B8),
              countBadge: '${state.cancelledBookings.length} đơn',
            ),
            ...state.cancelledBookings.map((b) => _buildBookingCard(b)),
            const SizedBox(height: 10),
          ],
        ] else ...[
          // ─── TAB CỤ THỂ (Sắp tới / Đã hoàn thành / Đã hủy) ──────────────
          _buildSectionHeader(
            title: state.activeTab == 'upcoming'
                ? 'Chuyến Đi Sắp Tới Của Bạn'
                : state.activeTab == 'completed'
                ? 'Kỳ Nghỉ Đã Hoàn Thành'
                : 'Đơn Đặt Phòng Đã Hủy',
            dotColor: state.activeTab == 'upcoming'
                ? const Color(0xFF10B981)
                : state.activeTab == 'completed'
                ? const Color(0xFF3B82F6)
                : const Color(0xFF94A3B8),
            countBadge: '${visibleBookings.length} đơn',
          ),
          ...visibleBookings.map((b) => _buildBookingCard(b)),
        ],

        // ─── BANNER HỖ TRỢ 24/7 ──────────────────────────────────────────
        const SizedBox(height: 12),
        const BookingSupportBanner(),
      ],
    );
  }

  Widget _buildBookingCard(BookingItemModel booking) {
    return BookingCard(
      key: ValueKey(booking.bookingId),
      booking: booking,
      onOpenVoucher: () => _handleOpenVoucher(booking),
      onOpenEditGuest: () => _handleOpenEditGuest(booking),
      onOpenDateChange: () => _handleOpenDateChange(booking),
      onOpenCancel: () => _handleOpenCancel(booking),
      onRebook: () => _handleRebook(booking),
      onOpenReview: () => _handleOpenReview(booking),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required Color dotColor,
    required String countBadge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              countBadge,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Trạng thái rỗng (Empty State)
  Widget _buildEmptyState(MyBookingState state) {
    final hasSearchOrFilter = state.searchQuery.isNotEmpty ||
        state.timeRange != 'all' ||
        state.requireVatOnly;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.luggage_outlined,
                color: Color(0xFF0284C7),
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSearchOrFilter
                  ? 'Không tìm thấy đơn đặt phòng phù hợp'
                  : 'Bạn chưa có lịch đặt phòng nào',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearchOrFilter
                  ? 'Thử thay đổi từ khóa tìm kiếm hoặc đặt lại bộ lọc thời gian để hiển thị đầy đủ đơn.'
                  : 'Hãy tìm một điểm dừng chân lý tưởng cho kỳ nghỉ sắp tới và đặt phòng cùng Avora ngay hôm nay.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            if (hasSearchOrFilter) ...[
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(myBookingNotifierProvider.notifier)
                    ..setSearchQuery('')
                    ..setTimeRange('all');
                },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text('Xóa bộ lọc tìm kiếm'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF003580),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.hotelSearch),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Khám phá khách sạn ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003580),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
