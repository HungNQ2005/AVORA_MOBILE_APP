import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/booking_item_model.dart';

/// Card thu gọn hiển thị đơn đặt phòng đã hủy (Tương đương CancelledBookingCard.jsx trên Web)
class CanceledBookingCard extends StatelessWidget {
  final BookingItemModel booking;
  final VoidCallback? onRebook;

  const CanceledBookingCard({
    super.key,
    required this.booking,
    this.onRebook,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###', 'vi_VN');
    final cancelReason =
        booking.cancellationReason ?? booking.refund?.reason;
    final refund = booking.refund;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with tag & status
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_busy_rounded,
                      size: 15,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      booking.createdAt != null && booking.createdAt!.length >= 10
                          ? 'Đã hủy ngày ${booking.createdAt!.substring(0, 10)}'
                          : 'Đã hủy phòng',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    refund?.refundStatusLabel != null
                        ? '${booking.statusName} • ${refund!.refundStatusLabel}'
                        : booking.statusName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel name & address
                Text(
                  booking.hotel.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        booking.hotel.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Stay details
                Text(
                  'Dự kiến: ${booking.stay.checkInDate} – ${booking.stay.checkOutDate} (${booking.stay.nights} đêm) • ${booking.stay.roomTypeName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),

                // Cancellation reason alert
                if (cancelReason != null && cancelReason.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'Lý do hủy: ',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF991B1B),
                              ),
                              children: [
                                TextSpan(
                                  text: cancelReason,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Color(0xFF7F1D1D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Refund details box
                const SizedBox(height: 10),
                if (refund != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.assignment_return_outlined,
                              size: 16,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Số tiền hoàn lại: ${currency.format(refund.refundAmount)} ₫',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã tham chiếu: ${refund.gatewayRefundRef ?? "Chưa có"} • Trạng thái: ${refund.refundStatusLabel ?? refund.refundStatusCd ?? "Đang xử lý"}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'Đơn đặt phòng đã hủy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],

                if (onRebook != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: onRebook,
                      icon: const Icon(Icons.refresh_rounded, size: 15),
                      label: const Text('Tìm lại chỗ nghỉ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF003580),
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
