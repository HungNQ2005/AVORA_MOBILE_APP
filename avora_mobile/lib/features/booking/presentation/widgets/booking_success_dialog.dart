import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../my_booking/data/models/booking_countdown_helper.dart';
import '../../data/models/booking_guest_info_args.dart';
import '../../data/models/booking_result_model.dart';

/// Modal dialog hiển thị thông báo đặt phòng thành công
/// Đồng bộ chuẩn 1:1 với BookingSuccessModal.jsx của bản Web (kèm đếm ngược 10 phút hủy tự động)
class BookingSuccessDialog extends StatefulWidget {
  final BookingResultModel booking;
  final BookingGuestInfoArgs args;

  const BookingSuccessDialog({
    super.key,
    required this.booking,
    required this.args,
  });

  @override
  State<BookingSuccessDialog> createState() => _BookingSuccessDialogState();
}

class _BookingSuccessDialogState extends State<BookingSuccessDialog> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  late final DateTime _fallbackCreatedAt;

  @override
  void initState() {
    super.initState();
    _fallbackCreatedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###', 'vi_VN');
    final hotelName = widget.booking.hotelName ??
        widget.args.hotel?.name ??
        widget.args.hotelName;
    final roomName =
        widget.booking.roomName ?? widget.args.room?.name ?? widget.args.roomName;

    final createdAtStr =
        widget.booking.createdAt ?? _fallbackCreatedAt.toIso8601String();
    final countdown = BookingCountdownHelper.getCountdown(
      createdAtStr: createdAtStr,
      currentTime: _now,
    );

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon thành công
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AvoraTheme.successGreen,
                  size: 46,
                ),
              ),
              const SizedBox(height: 16),

              // Tiêu đề
              const Text(
                'Đặt phòng thành công!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AvoraTheme.primaryNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Đơn đặt chỗ của bạn đã được ghi nhận trên hệ thống AVORA với trạng thái chờ thanh toán.',
                style: TextStyle(
                  fontSize: 13,
                  color: AvoraTheme.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // ─── Khung đếm ngược 10 phút hủy đặt phòng tự động (Đồng bộ 1:1 Web) ───
              if (countdown != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: countdown.expired
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: countdown.expired
                          ? const Color(0xFFFECACA)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: countdown.expired
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          countdown.expired
                              ? Icons.error_outline_rounded
                              : Icons.access_time_rounded,
                          size: 18,
                          color: countdown.expired
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              countdown.expired
                                  ? 'Đơn đặt phòng đã hết hạn'
                                  : 'Vui lòng hoàn tất thanh toán trong 10 phút',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: countdown.expired
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 3),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 12,
                                  color: countdown.expired
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF78350F),
                                  height: 1.35,
                                ),
                                children: countdown.expired
                                    ? const [
                                        TextSpan(
                                          text:
                                              'Đơn sẽ được hệ thống tự động hủy.',
                                        ),
                                      ]
                                    : [
                                        const TextSpan(
                                          text:
                                              'Nếu không thanh toán, đơn sẽ tự động hủy sau ',
                                        ),
                                        TextSpan(
                                          text: countdown.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const TextSpan(text: '.'),
                                      ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Khung hiển thị Mã đơn đặt chỗ
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined,
                        size: 20, color: AvoraTheme.primaryNavy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MÃ ĐẶT CHỖ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AvoraTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.booking.bookingCode,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AvoraTheme.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Sao chép mã',
                      color: AvoraTheme.actionBlue,
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: widget.booking.bookingCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép mã đặt chỗ vào bộ nhớ tạm'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bảng tóm tắt đơn phòng
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AvoraTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotelName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AvoraTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roomName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AvoraTheme.textSecondary,
                      ),
                    ),
                    const Divider(height: 18, color: AvoraTheme.cardBorder),
                    _buildSummaryRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Thời gian lưu trú',
                      value:
                          '${widget.args.checkInDate} → ${widget.args.checkOutDate} (${widget.args.nights} đêm)',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Khách đại diện',
                      value:
                          '${widget.booking.guestName} (${widget.booking.guestPhone})',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      icon: Icons.meeting_room_outlined,
                      label: 'Số lượng phòng',
                      value: '${widget.args.rooms} phòng',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      icon: Icons.hourglass_top_rounded,
                      label: 'Trạng thái đơn',
                      value: 'Chờ thanh toán',
                      valueColor: const Color(0xFFD97706),
                    ),
                    if (widget.booking.couponApplied != null &&
                        widget.booking.couponApplied!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        icon: Icons.discount_outlined,
                        label: 'Mã giảm giá',
                        value:
                            '${widget.booking.couponApplied} (-${currency.format(widget.booking.discountAmount)} ₫)',
                        valueColor: const Color(0xFF059669),
                      ),
                    ],
                    const Divider(height: 18, color: AvoraTheme.cardBorder),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng thanh toán:',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AvoraTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${currency.format(widget.booking.totalAmount)} ₫',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AvoraTheme.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Nút hành động
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.myBooking);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AvoraTheme.actionBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Xem đặt chỗ của tôi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.home);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AvoraTheme.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Về trang chủ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AvoraTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AvoraTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 12.5, color: AvoraTheme.textSecondary),
              children: [
                TextSpan(
                    text: '$label: ',
                    style: const TextStyle(color: AvoraTheme.textMuted)),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AvoraTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
