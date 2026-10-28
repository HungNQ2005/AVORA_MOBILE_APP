import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/core/router/app_router.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';

import '../../data/models/booking_item_model.dart';
import '../providers/my_booking_provider.dart';
import '../widgets/booking_card.dart';
import '../widgets/booking_filter_bar.dart';
import '../widgets/booking_support_banner.dart';
import '../widgets/booking_voucher_sheet.dart';
import '../widgets/cancel_booking_modal.dart';
import '../widgets/date_change_modal.dart';
import '../widgets/edit_guest_modal.dart';

class MyBookingScreen extends ConsumerStatefulWidget {
  const MyBookingScreen({super.key});

  @override
  ConsumerState<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends ConsumerState<MyBookingScreen> {
  bool _showHistory = false;

  Future<void> _openVoucher(BookingItemModel booking) async {
    final notifier = ref.read(myBookingNotifierProvider.notifier);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF003580)),
      ),
    );

    await notifier.loadVoucher(booking.bookingId);
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop();
    final state = ref.read(myBookingNotifierProvider);
    if (state.selectedVoucher != null) {
      await BookingVoucherSheet.show(context, state.selectedVoucher!);
    } else if (state.errorMessage != null) {
      _showMessage(state.errorMessage!, isError: true);
    }
  }

  Future<void> _editGuest(BookingItemModel booking) async {
    final notifier = ref.read(myBookingNotifierProvider.notifier);
    final saved = await EditGuestModal.show(
      context,
      booking: booking,
      onSave:
          ({
            required String guestName,
            required String guestPhone,
            String? specialRequest,
          }) => notifier.updateGuestInfo(
            booking.bookingId,
            guestName: guestName,
            guestPhone: guestPhone,
            specialRequest: specialRequest,
          ),
    );

    if (saved == true && mounted) {
      _showMessage('Cập nhật thông tin khách thành công!');
    }
  }

  Future<void> _changeDates(BookingItemModel booking) async {
    final notifier = ref.read(myBookingNotifierProvider.notifier);
    final changed = await DateChangeModal.show(
      context,
      booking: booking,
      onConfirmDateChange:
          ({required String checkInDate, required String checkOutDate}) =>
              notifier.changeBookingDates(
                booking.bookingId,
                checkInDate: checkInDate,
                checkOutDate: checkOutDate,
              ),
    );

    if (changed == true && mounted) {
      _showMessage('Đổi ngày lưu trú thành công!');
    }
  }

  Future<void> _cancelBooking(BookingItemModel booking) async {
    final notifier = ref.read(myBookingNotifierProvider.notifier);
    final cancelled = await CancelBookingModal.show(
      context,
      booking: booking,
      onConfirmCancel: ({required String reason}) =>
          notifier.cancelBooking(booking.bookingId, reason: reason),
    );

    if (cancelled == true && mounted) {
      _showMessage('Đã hủy đơn đặt phòng thành công!');
    }
  }

  void _rebook(BookingItemModel booking) {
    final hotelId = booking.hotel.hotelId;
    context.push(
      hotelId.isNotEmpty
          ? AppRoutes.hotelDetailPath(hotelId)
          : AppRoutes.hotelSearch,
    );
  }

  void _changeGroup(bool showHistory) {
    setState(() => _showHistory = showHistory);
    final targetTab = showHistory ? 'all' : 'upcoming';
    ref.read(myBookingNotifierProvider.notifier).changeTab(targetTab);
  }

  void _changeStatusFilter(String tab) {
    if (tab == 'upcoming') {
      setState(() => _showHistory = false);
    } else if (tab == 'completed' || tab == 'cancelled') {
      setState(() => _showHistory = true);
    }
    ref.read(myBookingNotifierProvider.notifier).changeTab(tab);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myBookingNotifierProvider);
    final notifier = ref.read(myBookingNotifierProvider.notifier);
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthSuccess ? authState.user : null;
    final role = (user?.role ?? '').toUpperCase();
    final isVendor = role.contains('VEN') || role.contains('VENDOR');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003580),
        foregroundColor: Colors.white,
        elevation: 0,
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
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
            ),
            Text(
              isVendor
                  ? 'VENDOR / ĐỐI TÁC'
                  : 'Trung tâm điều hành chuyến đi Avora',
              style: const TextStyle(fontSize: 11, color: Color(0xFFBFDBFE)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 21),
            tooltip: 'Làm mới',
            onPressed: () => notifier.loadBookings(),
          ),
        ],
      ),
      body: Column(
        children: [
          BookingFilterBar(
            activeTab: state.activeTab,
            onTabChange: _changeStatusFilter,
            counts: state.counts,
            searchQuery: state.searchQuery,
            onSearchSubmitted: notifier.setSearchQuery,
            timeRange: state.timeRange,
            onTimeRangeChanged: notifier.setTimeRange,
            availableYears: state.availableYears,
            requireVatOnly: state.requireVatOnly,
            onToggleVatOnly: notifier.toggleVatOnly,
          ),
          _BookingGroupSelector(
            showHistory: _showHistory,
            upcomingCount: state.counts.upcoming,
            historyCount: state.counts.completed + state.counts.cancelled,
            onChanged: _changeGroup,
          ),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF003580),
              onRefresh: () => notifier.loadBookings(silent: true),
              child: _buildBodyContent(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(MyBookingState state) {
    if (state.isLoading && state.bookings.isEmpty) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 300,
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF003580)),
            ),
          ),
        ],
      );
    }

    if (state.errorMessage != null && state.bookings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 300,
            child: Center(
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
                    Text(state.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref
                          .read(myBookingNotifierProvider.notifier)
                          .loadBookings(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final groupBookings = state.visibleBookings.where((booking) {
      return _showHistory
          ? booking.category == 'completed' || booking.category == 'cancelled'
          : booking.category == 'upcoming';
    }).toList();

    if (groupBookings.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 300,
            child: Center(
              child: Text(
                _showHistory
                    ? 'Lịch sử đặt chỗ chưa khả dụng'
                    : 'Đặt chỗ sắp tới sẽ ở đây',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
              ),
            ),
          ),
          const BookingSupportBanner(),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildSectionHeader(
          title: _showHistory ? 'Lịch sử đặt chỗ' : 'Chuyến Đi Sắp Tới',
          count: groupBookings.length,
        ),
        ...groupBookings.map(_buildBookingCard),
        const SizedBox(height: 12),
        const BookingSupportBanner(),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, required int count}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            '$count đơn',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingItemModel booking) {
    return BookingCard(
      key: ValueKey(booking.bookingId),
      booking: booking,
      onOpenDetails: () =>
          context.push(AppRoutes.bookingDetailPath(booking.bookingId)),
      onOpenVoucher: () => _openVoucher(booking),
      onOpenEditGuest: booking.category == 'upcoming'
          ? () => _editGuest(booking)
          : null,
      onOpenDateChange: booking.category == 'upcoming'
          ? () => _changeDates(booking)
          : null,
      onOpenCancel: booking.category == 'upcoming'
          ? () => _cancelBooking(booking)
          : null,
      onRebook: () => _rebook(booking),
    );
  }
}

class _BookingGroupSelector extends StatelessWidget {
  final bool showHistory;
  final int upcomingCount;
  final int historyCount;
  final ValueChanged<bool> onChanged;

  const _BookingGroupSelector({
    required this.showHistory,
    required this.upcomingCount,
    required this.historyCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _BookingGroupButton(
              label: 'Chuyến sắp tới',
              count: upcomingCount,
              isSelected: !showHistory,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _BookingGroupButton(
              label: 'Lịch sử',
              count: historyCount,
              isSelected: showHistory,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingGroupButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _BookingGroupButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFF003580)
        : const Color(0xFF64748B);
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
