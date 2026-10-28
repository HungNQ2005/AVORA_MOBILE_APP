import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Data model đại diện cho chi tiết một đơn đặt phòng (View Booking Details).
/// Tương thích 1:1 với phản hồi API từ Backend Avora:
/// `GET /api/bookings/:id` (hoặc đối tượng trong `GET /api/bookings/my`).
class BookingDetailModel extends Equatable {
  final String bookingId;
  final String bookingCode;
  final String userId;
  final String hotelId;
  final String hotelName;
  final String hotelAddress;
  final double? hotelStarRating;
  final int? hotelStarQuality;
  final String? hotelThumbnailUrl;

  final String guestName;
  final String guestPhone;
  final String? specialRequest;

  final String? roomTypeId;
  final String roomTypeName;
  final String? bedType;
  final String? roomSize;
  final int maxAdults;
  final int maxChildren;
  final int quantity;
  final num unitPrice;

  final String checkInDate;
  final String checkOutDate;
  final int nights;

  final num totalAmount;
  final num discountAmount;
  final String? couponCode;
  final String? couponDiscountText;

  final String bookingStatusCd;
  final String? statusCodeName;
  final String statusName;
  final String statusBadgeVariant;

  final bool isPaid;
  final String? paymentMethod;
  final String? paidAt;
  final String? transactionId;

  final String? cancellationPolicyDescription;
  final int? freeCancelHours;
  final num? penaltyRate;

  final String? createdAt;
  final String? updatedAt;

  const BookingDetailModel({
    required this.bookingId,
    required this.bookingCode,
    required this.userId,
    required this.hotelId,
    required this.hotelName,
    required this.hotelAddress,
    this.hotelStarRating,
    this.hotelStarQuality,
    this.hotelThumbnailUrl,
    required this.guestName,
    required this.guestPhone,
    this.specialRequest,
    this.roomTypeId,
    required this.roomTypeName,
    this.bedType,
    this.roomSize,
    this.maxAdults = 2,
    this.maxChildren = 0,
    this.quantity = 1,
    this.unitPrice = 0,
    required this.checkInDate,
    required this.checkOutDate,
    this.nights = 1,
    required this.totalAmount,
    this.discountAmount = 0,
    this.couponCode,
    this.couponDiscountText,
    required this.bookingStatusCd,
    this.statusCodeName,
    required this.statusName,
    required this.statusBadgeVariant,
    this.isPaid = false,
    this.paymentMethod,
    this.paidAt,
    this.transactionId,
    this.cancellationPolicyDescription,
    this.freeCancelHours,
    this.penaltyRate,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse từ JSON của backend: hỗ trợ cả schema quan hệ thô `t_booking` và schema enriched
  factory BookingDetailModel.fromJson(Map<String, dynamic> json) {
    final bookingId = (json['booking_id'] ?? '').toString();
    final createdAtStr = json['created_at']?.toString();

    // 1. Mã đơn đặt phòng (Booking Code)
    String bookingCode = (json['booking_code'] ?? '').toString();
    if (bookingCode.isEmpty && bookingId.isNotEmpty) {
      bookingCode = _generateFallbackBookingCode(bookingId, createdAtStr);
    }

    // 2. Thông tin khách sạn (m_hotel hoặc hotel)
    final hotelMap = (json['m_hotel'] is Map)
        ? Map<String, dynamic>.from(json['m_hotel'] as Map)
        : (json['hotel'] is Map)
            ? Map<String, dynamic>.from(json['hotel'] as Map)
            : <String, dynamic>{};

    final hotelId = (hotelMap['hotel_id'] ?? json['hotel_id'] ?? '').toString();
    final hotelName = hotelMap['name']?.toString() ?? 'Chỗ nghỉ AVORA';
    final hotelAddress = hotelMap['address']?.toString() ?? '';
    final hotelStarRating = (hotelMap['star_rating'] as num?)?.toDouble() ??
        (hotelMap['rating_score'] as num?)?.toDouble();
    final hotelStarQuality = (hotelMap['star_quality'] as num?)?.toInt();

    // Hình ảnh khách sạn
    String? thumbnailUrl;
    if (hotelMap['thumbnail_url'] != null) {
      thumbnailUrl = hotelMap['thumbnail_url']?.toString();
    } else if (hotelMap['m_hotel_image'] is List) {
      final imgList = hotelMap['m_hotel_image'] as List;
      for (final item in imgList) {
        if (item is Map && item['is_thumbnail'] == true) {
          thumbnailUrl = item['image_url']?.toString();
          break;
        }
      }
      if (thumbnailUrl == null && imgList.isNotEmpty) {
        final first = imgList.first;
        if (first is Map) thumbnailUrl = first['image_url']?.toString();
      }
    } else if (hotelMap['images'] is List && (hotelMap['images'] as List).isNotEmpty) {
      thumbnailUrl = (hotelMap['images'] as List).first?.toString();
    }

    // 3. Thông tin chi tiết phòng (t_booking_detail hoặc stay)
    final stayMap = (json['stay'] is Map)
        ? Map<String, dynamic>.from(json['stay'] as Map)
        : null;

    final bookingDetailsList = (json['t_booking_detail'] is List)
        ? (json['t_booking_detail'] as List)
        : null;

    final firstDetail = (bookingDetailsList != null && bookingDetailsList.isNotEmpty && bookingDetailsList.first is Map)
        ? Map<String, dynamic>.from(bookingDetailsList.first as Map)
        : null;

    final roomTypeMap = (firstDetail != null && firstDetail['m_room_type'] is Map)
        ? Map<String, dynamic>.from(firstDetail['m_room_type'] as Map)
        : null;

    final roomTypeId = firstDetail?['room_type_id']?.toString() ??
        stayMap?['room_type_id']?.toString();

    final roomTypeName = stayMap?['room_type_name']?.toString() ??
        roomTypeMap?['type_name']?.toString() ??
        json['room_name']?.toString() ??
        'Phòng tiêu chuẩn';

    final bedType = stayMap?['bed_type']?.toString() ??
        roomTypeMap?['bed_type']?.toString();

    final roomSize = stayMap?['room_size']?.toString() ??
        roomTypeMap?['room_size']?.toString();

    final maxAdults = (stayMap?['max_adults'] as num?)?.toInt() ??
        (roomTypeMap?['max_adults'] as num?)?.toInt() ??
        2;

    final maxChildren = (stayMap?['max_children'] as num?)?.toInt() ??
        (roomTypeMap?['max_children'] as num?)?.toInt() ??
        0;

    final quantity = (stayMap?['quantity'] as num?)?.toInt() ??
        (firstDetail?['quantity'] as num?)?.toInt() ??
        1;

    final unitPrice = (stayMap?['unit_price'] as num?) ??
        (firstDetail?['unit_price'] as num?) ??
        (roomTypeMap?['default_price'] as num?) ??
        0;

    // Ngày nhận & trả phòng
    String checkInDate = stayMap?['check_in_date']?.toString() ??
        firstDetail?['check_in_date']?.toString() ??
        '';
    String checkOutDate = stayMap?['check_out_date']?.toString() ??
        firstDetail?['check_out_date']?.toString() ??
        '';

    // Tính số đêm (nights)
    int nights = (stayMap?['nights'] as num?)?.toInt() ?? 1;
    if (checkInDate.isNotEmpty && checkOutDate.isNotEmpty) {
      try {
        final dIn = DateTime.parse(checkInDate);
        final dOut = DateTime.parse(checkOutDate);
        final diff = dOut.difference(dIn).inDays;
        if (diff > 0) nights = diff;
      } catch (_) {}
    }

    // 4. Mã giảm giá (m_coupon hoặc coupon)
    final couponMap = (json['m_coupon'] is Map)
        ? Map<String, dynamic>.from(json['m_coupon'] as Map)
        : (json['coupon'] is Map)
            ? Map<String, dynamic>.from(json['coupon'] as Map)
            : null;

    final couponCode = couponMap?['code']?.toString() ??
        json['coupon_applied']?.toString();

    String? couponDiscountText;
    if (couponMap != null) {
      if (couponMap['discount_text'] != null) {
        couponDiscountText = couponMap['discount_text']?.toString();
      } else {
        final discType = couponMap['discount_type']?.toString();
        final discVal = couponMap['discount_value'];
        if (discType == 'PERCENT') {
          couponDiscountText = 'Giảm $discVal%';
        } else if (discVal != null) {
          final curFmt = NumberFormat('#,###', 'vi_VN');
          couponDiscountText = 'Giảm ${curFmt.format(discVal)} ₫';
        }
      }
    }

    // 5. Thanh toán (t_payment_transaction hoặc payment)
    final paymentMap = (json['payment'] is Map)
        ? Map<String, dynamic>.from(json['payment'] as Map)
        : null;

    final paymentTxns = (json['t_payment_transaction'] is List)
        ? (json['t_payment_transaction'] as List)
        : null;

    final firstTxn = (paymentTxns != null && paymentTxns.isNotEmpty && paymentTxns.first is Map)
        ? Map<String, dynamic>.from(paymentTxns.first as Map)
        : null;

    final isPaid = paymentMap?['is_paid'] == true ||
        (firstTxn != null && (firstTxn['paid_at'] != null || ((firstTxn['amount_paid'] as num?) ?? 0) > 0));

    final paymentMethodCd = firstTxn?['payment_method_cd']?.toString() ??
        paymentMap?['payment_method_cd']?.toString();

    final paymentMethod = paymentMap?['payment_method']?.toString() ??
        _resolvePaymentMethodLabel(paymentMethodCd);

    final paidAt = firstTxn?['paid_at']?.toString() ?? paymentMap?['paid_at']?.toString();
    final transactionId = firstTxn?['transaction_id']?.toString() ??
        paymentMap?['transaction_id']?.toString() ??
        firstTxn?['gateway_ref_id']?.toString();

    // 6. Trạng thái đặt phòng (Status logic)
    final rawStatusCode = (json['booking_status_cd'] ?? '1').toString();
    final statusCodeName = json['status_code_name']?.toString();

    final statusInfo = _resolveBookingStatus(
      rawStatusCode: rawStatusCode,
      statusCodeName: statusCodeName,
      explicitStatusName: json['status_name']?.toString(),
      explicitBadgeVariant: json['status_badge_variant']?.toString(),
      checkOutDate: checkOutDate,
      isPaid: isPaid,
    );

    // 7. Chính sách hủy phòng (m_cancellation_policy hoặc cancellation)
    final cancelMap = (json['m_cancellation_policy'] is Map)
        ? Map<String, dynamic>.from(json['m_cancellation_policy'] as Map)
        : (json['cancellation'] is Map)
            ? Map<String, dynamic>.from(json['cancellation'] as Map)
            : null;

    final cancelDesc = cancelMap?['description']?.toString() ??
        cancelMap?['policy_note']?.toString();
    final freeCancelHours = (cancelMap?['free_cancel_before_hours'] as num?)?.toInt();
    final penaltyRate = (cancelMap?['penalty_rate'] as num?) ??
        (json['applied_penalty_rate'] as num?);

    return BookingDetailModel(
      bookingId: bookingId,
      bookingCode: bookingCode,
      userId: (json['user_id'] ?? '').toString(),
      hotelId: hotelId,
      hotelName: hotelName,
      hotelAddress: hotelAddress,
      hotelStarRating: hotelStarRating,
      hotelStarQuality: hotelStarQuality,
      hotelThumbnailUrl: thumbnailUrl,
      guestName: json['guest_name']?.toString() ?? '',
      guestPhone: json['guest_phone']?.toString() ?? '',
      specialRequest: json['special_request']?.toString(),
      roomTypeId: roomTypeId,
      roomTypeName: roomTypeName,
      bedType: bedType,
      roomSize: roomSize,
      maxAdults: maxAdults,
      maxChildren: maxChildren,
      quantity: quantity,
      unitPrice: unitPrice,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      nights: nights,
      totalAmount: (json['total_amount'] as num?) ?? 0,
      discountAmount: (json['discount_amount'] as num?) ?? 0,
      couponCode: couponCode,
      couponDiscountText: couponDiscountText,
      bookingStatusCd: rawStatusCode,
      statusCodeName: statusCodeName,
      statusName: statusInfo.name,
      statusBadgeVariant: statusInfo.variant,
      isPaid: isPaid,
      paymentMethod: paymentMethod,
      paidAt: paidAt,
      transactionId: transactionId,
      cancellationPolicyDescription: cancelDesc,
      freeCancelHours: freeCancelHours,
      penaltyRate: penaltyRate,
      createdAt: createdAtStr,
      updatedAt: json['updated_at']?.toString(),
    );
  }

  // ─── Helpers: Format ngày tháng & Trạng thái ─────────────────────────────

  /// Ngày giờ nhận phòng chuẩn: "Từ 14:00, Thứ Sáu, 25/10/2026"
  String get formattedCheckIn {
    if (checkInDate.isEmpty) return 'Từ 14:00';
    return 'Từ 14:00, ${_formatVnDate(checkInDate)}';
  }

  /// Ngày giờ trả phòng chuẩn: "Trước 12:00, Chủ Nhật, 27/10/2026"
  String get formattedCheckOut {
    if (checkOutDate.isEmpty) return 'Trước 12:00';
    return 'Trước 12:00, ${_formatVnDate(checkOutDate)}';
  }

  /// Ngày đặt phòng hiển thị: "21/10/2026 19:20"
  String get formattedCreatedAt {
    if (createdAt == null || createdAt!.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt!).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return createdAt!;
    }
  }

  /// Số khách tóm tắt: "2 người lớn, 1 trẻ em"
  String get guestsSummary {
    final buffer = StringBuffer('$maxAdults người lớn');
    if (maxChildren > 0) {
      buffer.write(', $maxChildren trẻ em');
    }
    return buffer.toString();
  }

  static String _formatVnDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final weekdays = [
        'Chủ Nhật',
        'Thứ Hai',
        'Thứ Ba',
        'Thứ Tư',
        'Thứ Năm',
        'Thứ Sáu',
        'Thứ Bảy',
      ];
      final dayName = weekdays[dt.weekday % 7];
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final yyyy = dt.year;
      return '$dayName, $dd/$mm/$yyyy';
    } catch (_) {
      return dateStr;
    }
  }

  static String _generateFallbackBookingCode(String bookingId, String? createdAtStr) {
    try {
      final dt = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
      final yearShort = (dt.year % 100).toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final suffix = bookingId.length >= 4
          ? bookingId.substring(0, 4).toUpperCase()
          : bookingId.toUpperCase();
      return 'AV-$month$yearShort-$suffix';
    } catch (_) {
      return bookingId.length >= 8 ? bookingId.substring(0, 8).toUpperCase() : bookingId;
    }
  }

  static String _resolvePaymentMethodLabel(String? code) {
    if (code == null || code.isEmpty) return 'Thanh toán trực tiếp';
    final normalized = code.toUpperCase();
    return switch (normalized) {
      'BTR' => 'Chuyển khoản ngân hàng',
      'VNP' => 'VNPAY QR',
      'MOM' => 'Ví MoMo',
      'CRD' => 'Thẻ tín dụng / Ghi nợ',
      _ => code,
    };
  }

  static ({String name, String variant}) _resolveBookingStatus({
    required String rawStatusCode,
    required String? statusCodeName,
    required String? explicitStatusName,
    required String? explicitBadgeVariant,
    required String checkOutDate,
    required bool isPaid,
  }) {
    if (explicitStatusName != null && explicitBadgeVariant != null) {
      return (name: explicitStatusName, variant: explicitBadgeVariant);
    }

    final code = (statusCodeName ?? rawStatusCode).toUpperCase();

    // 1. Đã hủy
    if (code == 'CAN' || rawStatusCode == '3') {
      return (name: 'Đã hủy phòng', variant: 'cancelled');
    }

    // 2. Đã hoàn thành (ngày checkout đã qua và không bị hủy)
    if (checkOutDate.isNotEmpty) {
      try {
        final dOut = DateTime.parse(checkOutDate);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (dOut.isBefore(today)) {
          return (name: 'Đã hoàn thành lưu trú', variant: 'completed');
        }
      } catch (_) {}
    }

    // 3. Chờ thanh toán
    if (code == 'PND' || rawStatusCode == '1') {
      return (name: 'Chờ thanh toán', variant: 'pending');
    }

    // 4. Đã xác nhận
    return (
      name: isPaid ? 'Đã xác nhận & Đã thanh toán' : 'Đã xác nhận đặt chỗ',
      variant: 'confirmed',
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        bookingCode,
        userId,
        hotelId,
        hotelName,
        guestName,
        guestPhone,
        totalAmount,
        discountAmount,
        checkInDate,
        checkOutDate,
        bookingStatusCd,
        statusCodeName,
        statusName,
        isPaid,
      ];
}
