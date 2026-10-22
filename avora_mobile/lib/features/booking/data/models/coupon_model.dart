import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Model biểu diễn Mã giảm giá / Coupon / Voucher từ CSDL `m_coupon`.
class CouponModel extends Equatable {
  final String couponId;
  final String code;
  final String discountType; // 'PERCENT' hoặc 'FIXED'
  final num discountValue;
  final num? minOrderAmount;
  final num? maxDiscountAmount;
  final String? validTo;

  const CouponModel({
    required this.couponId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.validTo,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      couponId: (json['coupon_id'] ?? json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString().toUpperCase(),
      discountType: (json['discount_type'] ?? 'PERCENT').toString().toUpperCase(),
      discountValue: json['discount_value'] as num? ?? 0,
      minOrderAmount: json['min_order_amount'] as num?,
      maxDiscountAmount: json['max_discount_amount'] as num?,
      validTo: json['valid_to']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'coupon_id': couponId,
        'code': code,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_order_amount': minOrderAmount,
        'max_discount_amount': maxDiscountAmount,
        'valid_to': validTo,
      };

  /// Chuỗi hiển thị mức giảm giá ngắn gọn, ví dụ: "-10%" hoặc "-100.000 ₫"
  String get formattedBadge {
    if (discountType == 'PERCENT') {
      return '-${discountValue.toInt()}%';
    } else {
      final currency = NumberFormat('#,###', 'vi_VN');
      return '-${currency.format(discountValue)} ₫';
    }
  }

  @override
  List<Object?> get props => [
        couponId,
        code,
        discountType,
        discountValue,
        minOrderAmount,
        maxDiscountAmount,
        validTo,
      ];
}

/// Model biểu diễn chi tiết giá tiền và trạng thái Coupon được tính toán từ backend.
class BookingPricingModel extends Equatable {
  final int nights;
  final String checkInDate;
  final String checkOutDate;
  final num subtotal;
  final num discountAmount;
  final num totalAmount;
  final CouponModel? coupon;
  final String? couponMessage;
  final List<CouponModel> availableCoupons;

  const BookingPricingModel({
    this.nights = 1,
    this.checkInDate = '',
    this.checkOutDate = '',
    this.subtotal = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    this.coupon,
    this.couponMessage,
    this.availableCoupons = const [],
  });

  factory BookingPricingModel.fromJson(Map<String, dynamic> json) {
    final rawCoupons = json['available_coupons'];
    final parsedCoupons = <CouponModel>[];
    if (rawCoupons is List) {
      for (final item in rawCoupons) {
        if (item is Map) {
          parsedCoupons.add(CouponModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    CouponModel? appliedCoupon;
    if (json['coupon'] is Map) {
      appliedCoupon = CouponModel.fromJson(
        Map<String, dynamic>.from(json['coupon'] as Map),
      );
    }

    return BookingPricingModel(
      nights: (json['nights'] as num?)?.toInt() ?? 1,
      checkInDate: json['check_in_date']?.toString() ?? '',
      checkOutDate: json['check_out_date']?.toString() ?? '',
      subtotal: json['subtotal'] as num? ?? 0,
      discountAmount: json['discount_amount'] as num? ?? 0,
      totalAmount: json['total_amount'] as num? ?? 0,
      coupon: appliedCoupon,
      couponMessage: json['coupon_message']?.toString(),
      availableCoupons: parsedCoupons,
    );
  }

  bool get hasDiscount => discountAmount > 0 && coupon != null;

  @override
  List<Object?> get props => [
        nights,
        checkInDate,
        checkOutDate,
        subtotal,
        discountAmount,
        totalAmount,
        coupon,
        couponMessage,
        availableCoupons,
      ];
}
