import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/booking_result_model.dart';
import '../../data/models/booking_guest_info_args.dart';

/// Modal dialog hiển thị thông báo đặt phòng thành công
/// Đồng bộ 1:1 với BookingSuccessModal.jsx của bản Web
class BookingSuccessDialog extends StatelessWidget {
  final BookingResultModel booking;
  final BookingGuestInfoArgs args;

  const BookingSuccessDialog({
    super.key,
    required this.booking,
    required this.args,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###', 'vi_VN');
    final hotelName = booking.hotelName ?? args.hotel?.name ?? args.hotelName;
    final roomName = booking.roomName ?? args.room?.name ?? args.roomName;

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
                'Đơn đặt chỗ của bạn đã được ghi nhận trên hệ thống AVORA.',
                style: TextStyle(
                  fontSize: 13,
                  color: AvoraTheme.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

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
                            booking.bookingCode,
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
                        Clipboard.setData(ClipboardData(text: booking.bookingCode));
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
                      value: '${args.checkInDate} → ${args.checkOutDate} (${args.nights} đêm)',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Khách đại diện',
                      value: '${booking.guestName} (${booking.guestPhone})',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      icon: Icons.meeting_room_outlined,
                      label: 'Số lượng phòng',
                      value: '${args.rooms} phòng',
                    ),
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
                          '${currency.format(booking.totalAmount)} ₫',
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
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.bookingDetailPath(booking.bookingId));
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text(
                    'Xem chi tiết đơn đặt phòng',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AvoraTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AvoraTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12.5, color: AvoraTheme.textSecondary),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(color: AvoraTheme.textMuted)),
                TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
