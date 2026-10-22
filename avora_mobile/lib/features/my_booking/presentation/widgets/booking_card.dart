import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../data/models/booking_item_model.dart';

/// Card hiển thị thông tin chi tiết một đơn đặt phòng
/// Thiết kế đồng bộ chuẩn với các BookingCard trên Web OTA Avora
class BookingCard extends StatelessWidget {
  final BookingItemModel booking;
  final VoidCallback onOpenVoucher;
  final VoidCallback? onOpenEditGuest;
  final VoidCallback? onOpenDateChange;
  final VoidCallback? onOpenCancel;
  final VoidCallback? onRebook;
  final VoidCallback? onOpenReview;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onOpenVoucher,
    this.onOpenEditGuest,
    this.onOpenDateChange,
    this.onOpenCancel,
    this.onRebook,
    this.onOpenReview,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###', 'vi_VN');
    final isUpcoming = booking.category == 'upcoming';
    final isCompleted = booking.category == 'completed';
    final isCancelled = booking.category == 'cancelled';
    final statusCode = (booking.bookingStatusCd ?? booking.statusCodeName)
        .trim()
        .toUpperCase();
    final canReview = ['2', 'CFM'].contains(statusCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header: Mã đơn + Trạng thái ─────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mã booking kèm nút sao chép
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: booking.bookingCode),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã sao chép mã đơn: ${booking.bookingCode}',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 16,
                          color: Color(0xFF003580),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          booking.bookingCode,
                          style: const TextStyle(
                            color: Color(0xFF003580),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.copy_rounded,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),

                // Badge trạng thái
                _StatusBadge(
                  statusName: booking.statusName,
                  variant: booking.statusBadgeVariant,
                ),
              ],
            ),
          ),

          // ─── Body: Khách sạn, Lưu trú, Phòng ──────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Khách sạn (Thumbnail + Info)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ảnh đại diện chỗ nghỉ
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 90,
                        height: 90,
                        color: const Color(0xFFF1F5F9),
                        child: booking.hotel.thumbnailUrl != null &&
                                booking.hotel.thumbnailUrl!.isNotEmpty
                            ? Image.network(
                                booking.hotel.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildImageFallback(),
                              )
                            : _buildImageFallback(),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Tên khách sạn & Địa chỉ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sao khách sạn
                          if ((booking.hotel.starQuality ?? 0) > 0)
                            Row(
                              children: [
                                Row(
                                  children: List.generate(
                                    booking.hotel.starQuality!,
                                    (_) => const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: Color(0xFFFFC107),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${booking.hotel.starQuality} sao',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 4),

                          // Tên khách sạn
                          Text(
                            booking.hotel.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Địa chỉ
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  booking.hotel.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Thông tin lưu trú (Ngày nhận - trả + số đêm)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: Color(0xFF003580),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_formatDate(booking.stay.checkInDate)}  ➜  ${_formatDate(booking.stay.checkOutDate)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${booking.stay.nights} đêm',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ],
                      ),
                        if (booking.stay.daysLeftText.isNotEmpty && isUpcoming) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              booking.stay.daysLeftText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Nhận phòng từ 14:00',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Chi tiết loại phòng & Khách
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.bed_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${booking.stay.quantity}x ${booking.stay.roomTypeName.isNotEmpty ? booking.stay.roomTypeName : 'Phòng tiêu chuẩn'} (${booking.stay.guestsSummary.isNotEmpty ? booking.stay.guestsSummary : "${booking.stay.maxAdults} người lớn"})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Tên khách đại diện
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Khách: ${booking.guestName}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${booking.guestPhone}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),

                // Thông tin hoàn tiền nếu bị hủy
                if (isCancelled && booking.refund != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.assignment_return_outlined,
                          size: 16,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${booking.refund?.refundStatusLabel ?? "Đang xử lý hoàn tiền"}: ${currency.format(booking.refund?.refundAmount ?? 0)} ₫',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // ─── Giá tiền & Tổng thanh toán ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.payment.paymentMethod,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (booking.discountAmount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Giảm ${currency.format(booking.discountAmount)} ₫',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Tổng thanh toán',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          '${currency.format(booking.totalAmount)} ₫',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF003580),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Actions Bar: Nút bấm tương tác ─────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Nút xem Voucher điện tử
                ElevatedButton.icon(
                  onPressed: onOpenVoucher,
                  icon: const Icon(Icons.qr_code_rounded, size: 16),
                  label: const Text('Voucher / Vé'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003580),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Hành động cho đơn Sắp tới (Upcoming)
                if (isUpcoming) ...[
                  if (onOpenEditGuest != null)
                    OutlinedButton.icon(
                      onPressed: onOpenEditGuest,
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: const Text('Sửa khách'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (onOpenDateChange != null)
                    OutlinedButton.icon(
                      onPressed: onOpenDateChange,
                      icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                      label: const Text('Đổi ngày'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (onOpenCancel != null)
                    OutlinedButton.icon(
                      onPressed: onOpenCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 15),
                      label: const Text('Hủy phòng'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],

                // Hành động cho đơn Đã hoàn thành hoặc Đã hủy
                if (canReview && onOpenReview != null)
                  OutlinedButton.icon(
                    onPressed: onOpenReview,
                    icon: const Icon(Icons.rate_review_outlined, size: 16),
                    label: const Text('Đánh giá'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF047857),
                      side: const BorderSide(color: Color(0xFF6EE7B7)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if ((isCompleted || isCancelled) && onRebook != null)
                  OutlinedButton.icon(
                    onPressed: onRebook,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Đặt lại chỗ này'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF003580),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(
          Icons.hotel_rounded,
          color: Color(0xFF94A3B8),
          size: 32,
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoString;
    }
  }
}

/// Widget hiển thị huy hiệu trạng thái đơn đặt phòng
class _StatusBadge extends StatelessWidget {
  final String statusName;
  final String variant;

  const _StatusBadge({
    required this.statusName,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (variant) {
      case 'amber':
      case 'pending':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFB45309);
        border = const Color(0xFFFDE68A);
        break;
      case 'cancelled':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        border = const Color(0xFFFECACA);
        break;
      case 'success':
      case 'completed':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        border = const Color(0xFFBFDBFE);
        break;
      case 'confirmed':
      default:
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF047857);
        border = const Color(0xFFA7F3D0);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        statusName,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
