import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/coupon_model.dart';

/// Card nhập và áp dụng mã giảm giá / Coupon / Voucher vào đơn đặt phòng.
/// Đồng bộ thiết kế 1:1 với Section Voucher trong `OrderSummarySidebar.jsx` trên Website Avora.
class BookingCouponCard extends StatelessWidget {
  final TextEditingController couponController;
  final CouponModel? appliedCoupon;
  final List<CouponModel> availableCoupons;
  final bool isApplying;
  final String? couponMessage;
  final bool? isSuccess;
  final VoidCallback onApplyCoupon;
  final VoidCallback onRemoveCoupon;
  final ValueChanged<String> onSelectAvailableCoupon;

  const BookingCouponCard({
    super.key,
    required this.couponController,
    required this.appliedCoupon,
    required this.availableCoupons,
    required this.isApplying,
    this.couponMessage,
    this.isSuccess,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
    required this.onSelectAvailableCoupon,
  });

  @override
  Widget build(BuildContext context) {
    final hasApplied = appliedCoupon != null;

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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Tiêu đề
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AvoraTheme.primaryNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: AvoraTheme.primaryNavy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã giảm giá / Voucher',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AvoraTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Nhập mã khuyến mãi hoặc chọn voucher có sẵn để nhận ưu đãi tốt nhất.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AvoraTheme.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AvoraTheme.cardBorder),
            const SizedBox(height: 16),

            // Input Row: Ô nhập mã và nút bấm Áp dụng / Bỏ mã
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ô nhập mã Coupon
                Expanded(
                  child: TextFormField(
                    controller: couponController,
                    textCapitalization: TextCapitalization.characters,
                    enabled: !isApplying && !hasApplied,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AvoraTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập mã (VD: SAIGON10)',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                        color: Color(0xFF9CA3AF),
                      ),
                      prefixIcon: const Icon(Icons.local_offer_outlined, size: 18),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 38, minHeight: 20),
                      prefixIconColor: AvoraTheme.textMuted,
                      isDense: true,
                      filled: true,
                      fillColor: hasApplied
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFFFAFAFA),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AvoraTheme.inputBorder,
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AvoraTheme.inputBorder,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AvoraTheme.primaryNavy,
                          width: 1.8,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) {
                      if (!hasApplied) onApplyCoupon();
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Nút Áp dụng hoặc Bỏ mã
                SizedBox(
                  height: 46,
                  child: hasApplied
                      ? OutlinedButton(
                          onPressed: isApplying ? null : onRemoveCoupon,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AvoraTheme.errorRed,
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            backgroundColor: const Color(0xFFFEF2F2),
                            minimumSize: const Size(0, 46),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Bỏ mã',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: isApplying ? null : onApplyCoupon,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AvoraTheme.primaryNavy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(0, 46),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: isApplying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Áp dụng',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                ),
              ],
            ),

            // Banner thông báo kết quả kiểm tra mã
            if (couponMessage != null && couponMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSuccess == true
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSuccess == true
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSuccess == true
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      size: 18,
                      color: isSuccess == true
                          ? const Color(0xFF059669)
                          : AvoraTheme.errorRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        couponMessage!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isSuccess == true
                              ? const Color(0xFF047857)
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Danh sách Voucher gợi ý từ CSDL (nếu có)
            if (availableCoupons.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Voucher dành cho bạn:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AvoraTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableCoupons.take(6).map((c) {
                  final isCurrent = appliedCoupon?.code == c.code;

                  return InkWell(
                    onTap: hasApplied && isCurrent
                        ? null
                        : () => onSelectAvailableCoupon(c.code),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent
                              ? const Color(0xFF10B981)
                              : const Color(0xFFCBD5E1),
                          width: isCurrent ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.discount_outlined,
                            size: 14,
                            color: isCurrent
                                ? const Color(0xFF059669)
                                : AvoraTheme.primaryNavy,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            c.code,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isCurrent
                                  ? const Color(0xFF059669)
                                  : AvoraTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF003580),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              c.formattedBadge,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
