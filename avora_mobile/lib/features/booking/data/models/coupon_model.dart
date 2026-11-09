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
  final String? validFrom;
  final int? usageLimit;
  final int? usageCount;
  final String? status;
  final String? statusLabel;

  const CouponModel({
    required this.couponId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscountAmount,
    this.validTo,
    this.validFrom,
    this.usageLimit,
    this.usageCount,
    this.status,
    this.statusLabel,
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
      validFrom: json['valid_from']?.toString(),
      usageLimit: (json['usage_limit'] as num?)?.toInt(),
      usageCount: (json['usage_count'] as num?)?.toInt(),
      status: json['status']?.toString(),
      statusLabel: json['status_label']?.toString(),
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
        'valid_from': validFrom,
        'usage_limit': usageLimit,
        'usage_count': usageCount,
        'status': status,
        'status_label': statusLabel,
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

  /// Tiêu đề giảm giá, ví dụ: "Giảm 10%" hoặc "Giảm 100.000 ₫"
  String get discountTitle {
    if (discountType == 'PERCENT') {
      return 'Giảm ${discountValue.toInt()}%';
    } else {
      final currency = NumberFormat('#,###', 'vi_VN');
      return 'Giảm ${currency.format(discountValue)} ₫';
    }
  }

  /// Mô tả chi tiết mức giảm (kèm giới hạn nếu có)
  String get discountDescription {
    final currency = NumberFormat('#,###', 'vi_VN');
    if (discountType == 'PERCENT') {
      if (maxDiscountAmount != null && maxDiscountAmount! > 0) {
        return 'Giảm ${discountValue.toInt()}% (Tối đa ${currency.format(maxDiscountAmount)} ₫)';
      }
      return 'Giảm ${discountValue.toInt()}% cho tổng tiền phòng';
    } else {
      return 'Giảm trực tiếp ${currency.format(discountValue)} ₫';
    }
  }

  /// Định dạng yêu cầu đơn đặt phòng tối thiểu
  String get minOrderText {
    if (minOrderAmount != null && minOrderAmount! > 0) {
      final currency = NumberFormat('#,###', 'vi_VN');
      return 'Đơn tối thiểu ${currency.format(minOrderAmount)} ₫';
    }
    return 'Áp dụng cho mọi giá trị đơn';
  }

  /// Định dạng thời hạn hiệu lực
  String get validityText {
    final fmt = DateFormat('dd/MM/yyyy');
    DateTime? fromDate;
    DateTime? toDate;
    if (validFrom != null && validFrom!.isNotEmpty) {
      fromDate = DateTime.tryParse(validFrom!);
    }
    if (validTo != null && validTo!.isNotEmpty) {
      toDate = DateTime.tryParse(validTo!);
    }

    if (fromDate != null && toDate != null) {
      return '${fmt.format(fromDate)} - ${fmt.format(toDate)}';
    } else if (toDate != null) {
      return 'HSD: ${fmt.format(toDate)}';
    } else if (fromDate != null) {
      return 'Bắt đầu từ ${fmt.format(fromDate)}';
    }
    return 'Không giới hạn thời gian';
  }

  /// Kiểm tra xem coupon có đang trong hạn dùng không
  bool get isCurrentlyValid {
    if (status != null) {
      return status?.toUpperCase() == 'ACTIVE';
    }
    final now = DateTime.now();
    if (validFrom != null && validFrom!.isNotEmpty) {
      final from = DateTime.tryParse(validFrom!);
      if (from != null && now.isBefore(from)) return false;
    }
    if (validTo != null && validTo!.isNotEmpty) {
      final to = DateTime.tryParse(validTo!);
      if (to != null && now.isAfter(to)) return false;
    }
    return true;
  }

  /// Nhãn hiển thị trạng thái của mã
  String get displayStatusLabel {
    if (statusLabel != null && statusLabel!.isNotEmpty) {
      return statusLabel!;
    }
    final s = status?.toUpperCase();
    if (s == 'EXPIRED') return 'Hết hạn';
    if (s == 'UPCOMING') return 'Sắp diễn ra';
    if (s == 'DELETED') return 'Đã vô hiệu hóa';
    return isCurrentlyValid ? 'Đang hoạt động' : 'Hết hạn';
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
        validFrom,
        usageLimit,
        usageCount,
        status,
        statusLabel,
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
