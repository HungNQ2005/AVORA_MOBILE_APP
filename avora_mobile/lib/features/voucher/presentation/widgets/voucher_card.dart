import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:avora_mobile/core/theme/app_theme.dart';
import 'package:avora_mobile/features/booking/data/models/coupon_model.dart';

/// Thẻ hiển thị thông tin Mã khuyến mãi / Voucher dạng vé điện tử (Ticket Card)
class VoucherCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback? onCopied;

  const VoucherCard({
    super.key,
    required this.coupon,
    this.onCopied,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: coupon.code));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Đã sao chép mã ${coupon.code}'),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    onCopied?.call();
  }

  @override
  Widget build(BuildContext context) {
    final statusUpper = (coupon.status ?? (coupon.isCurrentlyValid ? 'ACTIVE' : 'EXPIRED')).toUpperCase();
    final isActive = statusUpper == 'ACTIVE';
    final isUpcoming = statusUpper == 'UPCOMING';
    final isExpired = statusUpper == 'EXPIRED' || (!isActive && !isUpcoming);

    Color badgeBg;
    Color badgeTextColor;
    String statusText;
    Color statusBg;
    Color statusTextColor;
    Color statusBorderColor;

    if (isActive) {
      badgeBg = AvoraTheme.primaryNavy;
      badgeTextColor = Colors.white;
      statusText = coupon.statusLabel ?? 'Đang hoạt động';
      statusBg = const Color(0xFFECFDF5);
      statusTextColor = const Color(0xFF047857);
      statusBorderColor = const Color(0xFFA7F3D0);
    } else if (isUpcoming) {
      badgeBg = const Color(0xFF0284C7);
      badgeTextColor = Colors.white;
      statusText = coupon.statusLabel ?? 'Sắp diễn ra';
      statusBg = const Color(0xFFF0F9FF);
      statusTextColor = const Color(0xFF0369A1);
      statusBorderColor = const Color(0xFFBAE6FD);
    } else {
      badgeBg = const Color(0xFF94A3B8);
      badgeTextColor = Colors.white;
      statusText = coupon.statusLabel ?? 'Hết hạn';
      statusBg = const Color(0xFFF1F5F9);
      statusTextColor = const Color(0xFF64748B);
      statusBorderColor = const Color(0xFFCBD5E1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFFE2E8F0) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cột trái: Huy hiệu mức giảm giá
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                decoration: BoxDecoration(
                  color: badgeBg,
                  gradient: isActive
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF003580),
                            Color(0xFF0052CC),
                          ],
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      coupon.discountType == 'PERCENT'
                          ? Icons.percent_rounded
                          : Icons.local_offer_rounded,
                      color: Colors.white.withOpacity(0.9),
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      coupon.formattedBadge,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'GIẢM GIÁ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              // Cột phải: Thông tin chi tiết voucher
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Hàng mã code và trạng thái
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    coupon.code,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: isExpired
                                          ? const Color(0xFF64748B)
                                          : AvoraTheme.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _copyToClipboard(context),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Icon(
                                      Icons.copy_rounded,
                                      size: 15,
                                      color: isExpired
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF0066FF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusBorderColor),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Tiêu đề & mô tả giảm giá
                      Text(
                        coupon.discountDescription,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isExpired
                              ? const Color(0xFF64748B)
                              : const Color(0xFF1E293B),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Điều kiện đơn tối thiểu
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 13.5,
                            color: isExpired
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              coupon.minOrderText,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isExpired
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF475569),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Thời hạn sử dụng
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 13.5,
                            color: isExpired
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              coupon.validityText,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isExpired
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF475569),
                                fontWeight: isActive
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
