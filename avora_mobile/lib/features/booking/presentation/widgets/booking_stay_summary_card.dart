import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/booking_guest_info_args.dart';

/// Card tóm tắt nhanh thông tin chuyến đi (Khách sạn, phòng, ngày lưu trú, số lượng khách)
/// Giúp người dùng đối chiếu trong lúc điền thông tin khách nhận phòng.
class BookingStaySummaryCard extends StatelessWidget {
  final BookingGuestInfoArgs args;
  final num? subtotal;
  final num? discountAmount;
  final num? finalTotal;
  final String? appliedCouponCode;

  const BookingStaySummaryCard({
    super.key,
    required this.args,
    this.subtotal,
    this.discountAmount,
    this.finalTotal,
    this.appliedCouponCode,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###', 'vi_VN');
    final hotelName = args.hotel?.name ?? args.hotelName;
    final roomName = args.room?.name ?? args.roomName;
    final address = args.hotel?.fullAddress ?? args.hotel?.address ?? 'Đà Nẵng, Việt Nam';
    final starRating = args.hotel?.starRating ?? 9.2;
    final scoreLabel = args.hotel?.scoreLabel ?? 'Xuất sắc';
    final currentSubtotal = subtotal ?? args.totalPrice;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvoraTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với tiêu đề và badge đối tác ưu đãi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: AvoraTheme.cardBorder)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.hotel_rounded,
                  size: 20,
                  color: AvoraTheme.primaryNavy,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Chi tiết đơn đặt phòng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AvoraTheme.primaryNavy,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AvoraTheme.primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: AvoraTheme.actionBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$scoreLabel $starRating',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AvoraTheme.actionBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên khách sạn
                Text(
                  hotelName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AvoraTheme.textPrimary,
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
                      color: AvoraTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AvoraTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Divider(height: 1, color: AvoraTheme.cardBorder),
                const SizedBox(height: 14),

                // Chi tiết hạng phòng & số khách
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaItem(
                        icon: Icons.meeting_room_outlined,
                        title: 'Hạng phòng',
                        value: roomName,
                      ),
                    ),
                    Expanded(
                      child: _buildMetaItem(
                        icon: Icons.people_outline_rounded,
                        title: 'Khách & Phòng',
                        value:
                            '${args.adults} Lớn${args.children > 0 ? ', ${args.children} Trẻ' : ''} · ${args.rooms} phòng',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Lịch trình lưu trú
                _buildMetaItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Thời gian lưu trú (${args.nights} đêm)',
                  value: args.stayDates,
                ),

                // Chi tiết giá tiền và giảm giá
                if (currentSubtotal != null && currentSubtotal > 0) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AvoraTheme.cardBorder),
                  const SizedBox(height: 12),

                  // Tạm tính
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tạm tính:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AvoraTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${currency.format(currentSubtotal)} ₫',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AvoraTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  // Dòng giảm giá (nếu có coupon)
                  if (discountAmount != null && discountAmount! > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.discount_outlined,
                              size: 15,
                              color: Color(0xFF059669),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appliedCouponCode != null
                                  ? 'Giảm giá ($appliedCouponCode):'
                                  : 'Giảm giá coupon:',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '-${currency.format(discountAmount)} ₫',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AvoraTheme.cardBorder),
                  const SizedBox(height: 8),

                  // Tổng chi phí
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng chi phí thanh toán:',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AvoraTheme.primaryNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${currency.format(finalTotal ?? (currentSubtotal - (discountAmount ?? 0)))} ₫',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AvoraTheme.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AvoraTheme.primaryNavy),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AvoraTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AvoraTheme.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
