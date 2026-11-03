import 'package:equatable/equatable.dart';

/// Model đại diện cho một khách sạn trong đơn đặt phòng
class BookingHotelModel extends Equatable {
  final String hotelId;
  final String name;
  final String address;
  final num? starRating;
  final int? starQuality;
  final num? ratingScore;
  final int? reviewCount;
  final String? thumbnailUrl;
  final List<String> images;

  const BookingHotelModel({
    required this.hotelId,
    required this.name,
    required this.address,
    this.starRating,
    this.starQuality,
    this.ratingScore,
    this.reviewCount,
    this.thumbnailUrl,
    this.images = const [],
  });

  factory BookingHotelModel.fromJson(Map<String, dynamic> json) {
    final imagesList = (json['images'] as List?)
            ?.map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        const <String>[];

    return BookingHotelModel(
      hotelId: (json['hotel_id'] ?? '').toString(),
      name: (json['name'] ?? 'Khách sạn Avora').toString(),
      address: (json['address'] ?? '').toString(),
      starRating: json['star_rating'] as num?,
      starQuality: (json['star_quality'] as num?)?.toInt(),
      ratingScore: json['rating_score'] as num?,
      reviewCount: (json['review_count'] as num?)?.toInt(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      images: imagesList,
    );
  }

  @override
  List<Object?> get props => [
        hotelId,
        name,
        address,
        starRating,
        starQuality,
        ratingScore,
        reviewCount,
        thumbnailUrl,
        images,
      ];
}

/// Model đại diện cho thông tin lưu trú của đơn đặt phòng
class BookingStayModel extends Equatable {
  final String checkInDate;
  final String checkOutDate;
  final int nights;
  final String daysLeftText;
  final bool isUpcoming;
  final String roomTypeName;
  final String bedType;
  final String roomSize;
  final int maxAdults;
  final int maxChildren;
  final String guestsSummary;
  final num unitPrice;
  final int quantity;

  const BookingStayModel({
    required this.checkInDate,
    required this.checkOutDate,
    this.nights = 1,
    this.daysLeftText = '',
    this.isUpcoming = false,
    this.roomTypeName = '',
    this.bedType = '',
    this.roomSize = '',
    this.maxAdults = 1,
    this.maxChildren = 0,
    this.guestsSummary = '',
    this.unitPrice = 0,
    this.quantity = 1,
  });

  factory BookingStayModel.fromJson(Map<String, dynamic> json) {
    return BookingStayModel(
      checkInDate: (json['check_in_date'] ?? '').toString(),
      checkOutDate: (json['check_out_date'] ?? '').toString(),
      nights: (json['nights'] as num?)?.toInt() ?? 1,
      daysLeftText: (json['days_left_text'] ?? '').toString(),
      isUpcoming: json['is_upcoming'] == true,
      roomTypeName: (json['room_type_name'] ?? '').toString(),
      bedType: (json['bed_type'] ?? '').toString(),
      roomSize: (json['room_size'] ?? '').toString(),
      maxAdults: (json['max_adults'] as num?)?.toInt() ?? 1,
      maxChildren: (json['max_children'] as num?)?.toInt() ?? 0,
      guestsSummary: (json['guests_summary'] ?? '').toString(),
      unitPrice: (json['unit_price'] as num?) ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [
        checkInDate,
        checkOutDate,
        nights,
        daysLeftText,
        isUpcoming,
        roomTypeName,
        bedType,
        roomSize,
        maxAdults,
        maxChildren,
        guestsSummary,
        unitPrice,
        quantity,
      ];
}

/// Model chính sách hủy phòng
class BookingCancellationModel extends Equatable {
  final String? cancellationPolicyId;
  final int? freeCancelBeforeHours;
  final num penaltyRate;
  final bool isFreeCancel;
  final String deadlineText;
  final num refundPercentage;
  final num estimatedRefundAmount;
  final String? description;
  final String policyNote;

  const BookingCancellationModel({
    this.cancellationPolicyId,
    this.freeCancelBeforeHours,
    this.penaltyRate = 0,
    this.isFreeCancel = false,
    this.deadlineText = '',
    this.refundPercentage = 100,
    this.estimatedRefundAmount = 0,
    this.description,
    this.policyNote = '',
  });

  factory BookingCancellationModel.fromJson(Map<String, dynamic> json) {
    return BookingCancellationModel(
      cancellationPolicyId: json['cancellation_policy_id']?.toString(),
      freeCancelBeforeHours:
          (json['free_cancel_before_hours'] as num?)?.toInt(),
      penaltyRate: (json['penalty_rate'] as num?) ?? 0,
      isFreeCancel: json['is_free_cancel'] == true,
      deadlineText: (json['deadline_text'] ?? '').toString(),
      refundPercentage: (json['refund_percentage'] as num?) ?? 100,
      estimatedRefundAmount:
          (json['estimated_refund_amount'] as num?) ?? 0,
      description: json['description']?.toString(),
      policyNote: (json['policy_note'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [
        cancellationPolicyId,
        freeCancelBeforeHours,
        penaltyRate,
        isFreeCancel,
        deadlineText,
        refundPercentage,
        estimatedRefundAmount,
        description,
        policyNote,
      ];
}

/// Model hoàn tiền
class BookingRefundModel extends Equatable {
  final String refundId;
  final num refundAmount;
  final String? refundStatusCd;
  final String? refundStatusName;
  final String? refundStatusLabel;
  final String? gatewayRefundRef;
  final String? reason;
  final String? createdAt;

  const BookingRefundModel({
    required this.refundId,
    required this.refundAmount,
    this.refundStatusCd,
    this.refundStatusName,
    this.refundStatusLabel,
    this.gatewayRefundRef,
    this.reason,
    this.createdAt,
  });

  factory BookingRefundModel.fromJson(Map<String, dynamic> json) {
    return BookingRefundModel(
      refundId: (json['refund_id'] ?? '').toString(),
      refundAmount: (json['refund_amount'] as num?) ?? 0,
      refundStatusCd: json['refund_status_cd']?.toString(),
      refundStatusName: json['refund_status_name']?.toString(),
      refundStatusLabel: json['refund_status_label']?.toString(),
      gatewayRefundRef: json['gateway_refund_ref']?.toString(),
      reason: json['reason']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        refundId,
        refundAmount,
        refundStatusCd,
        refundStatusName,
        refundStatusLabel,
        gatewayRefundRef,
        reason,
        createdAt,
      ];
}

/// Model thanh toán
class BookingPaymentModel extends Equatable {
  final bool isPaid;
  final String? transactionId;
  final num amountPaid;
  final String? paymentMethodCd;
  final String paymentMethod;
  final String? gatewayRefId;
  final String? paidAt;
  final bool hasVatInvoice;

  const BookingPaymentModel({
    this.isPaid = false,
    this.transactionId,
    this.amountPaid = 0,
    this.paymentMethodCd,
    this.paymentMethod = 'Chưa thanh toán',
    this.gatewayRefId,
    this.paidAt,
    this.hasVatInvoice = false,
  });

  factory BookingPaymentModel.fromJson(Map<String, dynamic> json) {
    return BookingPaymentModel(
      isPaid: json['is_paid'] == true,
      transactionId: json['transaction_id']?.toString(),
      amountPaid: (json['amount_paid'] as num?) ?? 0,
      paymentMethodCd: json['payment_method_cd']?.toString(),
      paymentMethod:
          (json['payment_method'] ?? 'Chưa thanh toán').toString(),
      gatewayRefId: json['gateway_ref_id']?.toString(),
      paidAt: json['paid_at']?.toString(),
      hasVatInvoice: json['has_vat_invoice'] == true,
    );
  }

  @override
  List<Object?> get props => [
        isPaid,
        transactionId,
        amountPaid,
        paymentMethodCd,
        paymentMethod,
        gatewayRefId,
        paidAt,
        hasVatInvoice,
      ];
}

/// Model mã giảm giá của đơn
class BookingCouponModel extends Equatable {
  final String couponId;
  final String code;
  final String? discountType;
  final num discountValue;
  final String? discountText;
  final num? minOrderAmount;
  final String? validTo;

  const BookingCouponModel({
    required this.couponId,
    required this.code,
    this.discountType,
    this.discountValue = 0,
    this.discountText,
    this.minOrderAmount,
    this.validTo,
  });

  factory BookingCouponModel.fromJson(Map<String, dynamic> json) {
    return BookingCouponModel(
      couponId: (json['coupon_id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      discountType: json['discount_type']?.toString(),
      discountValue: (json['discount_value'] as num?) ?? 0,
      discountText: json['discount_text']?.toString(),
      minOrderAmount: json['min_order_amount'] as num?,
      validTo: json['valid_to']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        couponId,
        code,
        discountType,
        discountValue,
        discountText,
        minOrderAmount,
        validTo,
      ];
}

/// Model chi tiết của một đơn đặt phòng (Booking)
class BookingItemModel extends Equatable {
  final String bookingId;
  final String bookingCode;
  final String category; // 'upcoming', 'completed', 'cancelled'
  final String? userId;
  final String guestName;
  final String guestPhone;
  final String specialRequest;
  final String? bookingStatusCd;
  final String? statusCode;
  final String statusCodeName; // 'PND', 'CFM', 'CAN', etc.
  final String statusName;
  final String statusBadgeVariant; // 'confirmed', 'amber', 'cancelled', 'success'
  final num totalAmount;
  final num discountAmount;
  final String? createdAt;
  final String bookingDateFormatted;
  final BookingHotelModel hotel;
  final BookingStayModel stay;
  final BookingCancellationModel cancellation;
  final BookingPaymentModel payment;
  final bool canEdit;
  final BookingRefundModel? refund;
  final BookingCouponModel? coupon;

  const BookingItemModel({
    required this.bookingId,
    required this.bookingCode,
    required this.category,
    this.userId,
    required this.guestName,
    required this.guestPhone,
    this.specialRequest = '',
    this.bookingStatusCd,
    this.statusCode,
    required this.statusCodeName,
    required this.statusName,
    required this.statusBadgeVariant,
    required this.totalAmount,
    this.discountAmount = 0,
    this.createdAt,
    this.bookingDateFormatted = '',
    required this.hotel,
    required this.stay,
    required this.cancellation,
    required this.payment,
    this.canEdit = false,
    this.refund,
    this.coupon,
  });

  factory BookingItemModel.fromJson(Map<String, dynamic> json) {
    return BookingItemModel(
      bookingId: (json['booking_id'] ?? '').toString(),
      bookingCode: (json['booking_code'] ?? '').toString(),
      category: (json['category'] ?? 'upcoming').toString(),
      userId: json['user_id']?.toString(),
      guestName: (json['guest_name'] ?? '').toString(),
      guestPhone: (json['guest_phone'] ?? '').toString(),
      specialRequest: (json['special_request'] ?? '').toString(),
      bookingStatusCd: json['booking_status_cd']?.toString(),
      statusCode: json['status_code']?.toString(),
      statusCodeName: (json['status_code_name'] ?? 'CFM').toString(),
      statusName: (json['status_name'] ?? 'Đã xác nhận').toString(),
      statusBadgeVariant:
          (json['status_badge_variant'] ?? 'confirmed').toString(),
      totalAmount: (json['total_amount'] as num?) ?? 0,
      discountAmount: (json['discount_amount'] as num?) ?? 0,
      createdAt: json['created_at']?.toString(),
      bookingDateFormatted: (json['booking_date_formatted'] ?? '').toString(),
      hotel: BookingHotelModel.fromJson(
        Map<String, dynamic>.from((json['hotel'] as Map?) ?? {}),
      ),
      stay: BookingStayModel.fromJson(
        Map<String, dynamic>.from((json['stay'] as Map?) ?? {}),
      ),
      cancellation: BookingCancellationModel.fromJson(
        Map<String, dynamic>.from((json['cancellation'] as Map?) ?? {}),
      ),
      payment: BookingPaymentModel.fromJson(
        Map<String, dynamic>.from((json['payment'] as Map?) ?? {}),
      ),
      canEdit: json['can_edit'] == true,
      refund: json['refund'] != null
          ? BookingRefundModel.fromJson(
              Map<String, dynamic>.from(json['refund'] as Map),
            )
          : null,
      coupon: json['coupon'] != null
          ? BookingCouponModel.fromJson(
              Map<String, dynamic>.from(json['coupon'] as Map),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        bookingCode,
        category,
        userId,
        guestName,
        guestPhone,
        specialRequest,
        bookingStatusCd,
        statusCode,
        statusCodeName,
        statusName,
        statusBadgeVariant,
        totalAmount,
        discountAmount,
        createdAt,
        bookingDateFormatted,
        hotel,
        stay,
        cancellation,
        payment,
        canEdit,
        refund,
        coupon,
      ];
}

/// Model thống kê số lượng đơn theo các tab
class BookingCountsModel extends Equatable {
  final int all;
  final int upcoming;
  final int completed;
  final int cancelled;

  const BookingCountsModel({
    this.all = 0,
    this.upcoming = 0,
    this.completed = 0,
    this.cancelled = 0,
  });

  factory BookingCountsModel.fromJson(Map<String, dynamic> json) {
    return BookingCountsModel(
      all: (json['all'] as num?)?.toInt() ?? 0,
      upcoming: (json['upcoming'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [all, upcoming, completed, cancelled];
}

/// Model kết quả trả về từ API `GET /api/bookings/my`
class BookingListResponse extends Equatable {
  final List<BookingItemModel> bookings;
  final BookingCountsModel counts;
  final List<int> availableYears;

  const BookingListResponse({
    required this.bookings,
    required this.counts,
    required this.availableYears,
  });

  factory BookingListResponse.fromJson(Map<String, dynamic> json) {
    final rawBookings = (json['bookings'] as List?) ?? [];
    final bookingsList = rawBookings
        .map((b) => BookingItemModel.fromJson(
              Map<String, dynamic>.from(b as Map),
            ))
        .toList();

    final counts = json['counts'] != null
        ? BookingCountsModel.fromJson(
            Map<String, dynamic>.from(json['counts'] as Map),
          )
        : const BookingCountsModel();

    final years = (json['available_years'] as List?)
            ?.map((y) => (y as num).toInt())
            .toList() ??
        const <int>[];

    return BookingListResponse(
      bookings: bookingsList,
      counts: counts,
      availableYears: years,
    );
  }

  @override
  List<Object?> get props => [bookings, counts, availableYears];
}

/// Model chi tiết Voucher điện tử trả về từ `GET /api/bookings/:id/voucher`
class BookingVoucherModel extends Equatable {
  final String bookingId;
  final String bookingCode;
  final String voucherCode;
  final String? couponCode;
  final String? discountText;
  final num discountAmount;
  final String bookingDate;
  final String? bookingCreatedAt;
  final String statusCodeName;
  final bool isPaid;
  final String qrData;
  final String hotelName;
  final String hotelAddress;
  final String guestName;
  final String guestPhone;
  final String specialRequest;
  final String checkInDate;
  final String checkOutDate;
  final int nights;
  final String roomTypeName;
  final int quantity;
  final num totalAmount;
  final String paymentMethod;

  const BookingVoucherModel({
    required this.bookingId,
    required this.bookingCode,
    required this.voucherCode,
    this.couponCode,
    this.discountText,
    this.discountAmount = 0,
    required this.bookingDate,
    this.bookingCreatedAt,
    required this.statusCodeName,
    required this.isPaid,
    required this.qrData,
    required this.hotelName,
    required this.hotelAddress,
    required this.guestName,
    required this.guestPhone,
    this.specialRequest = '',
    required this.checkInDate,
    required this.checkOutDate,
    this.nights = 1,
    required this.roomTypeName,
    this.quantity = 1,
    required this.totalAmount,
    required this.paymentMethod,
  });

  factory BookingVoucherModel.fromJson(Map<String, dynamic> json) {
    final stay = Map<String, dynamic>.from((json['stay'] as Map?) ?? {});
    return BookingVoucherModel(
      bookingId: (json['booking_id'] ?? '').toString(),
      bookingCode: (json['booking_code'] ?? '').toString(),
      voucherCode:
          (json['voucher_code'] ?? json['booking_code'] ?? '').toString(),
      couponCode: json['coupon_code']?.toString(),
      discountText: json['discount_text']?.toString(),
      discountAmount: (json['discount_amount'] as num?) ?? 0,
      bookingDate: (json['booking_date'] ?? '').toString(),
      bookingCreatedAt: json['booking_created_at']?.toString(),
      statusCodeName: (json['status_code_name'] ?? 'CFM').toString(),
      isPaid: json['is_paid'] == true,
      qrData: (json['qr_data'] ?? '').toString(),
      hotelName: (json['hotel_name'] ?? '').toString(),
      hotelAddress: (json['hotel_address'] ?? '').toString(),
      guestName: (json['guest_name'] ?? '').toString(),
      guestPhone: (json['guest_phone'] ?? '').toString(),
      specialRequest: (json['special_request'] ?? '').toString(),
      checkInDate: (stay['check_in_date'] ?? '').toString(),
      checkOutDate: (stay['check_out_date'] ?? '').toString(),
      nights: (stay['nights'] as num?)?.toInt() ?? 1,
      roomTypeName: (stay['room_type_name'] ?? '').toString(),
      quantity: (stay['quantity'] as num?)?.toInt() ?? 1,
      totalAmount: (json['total_amount'] as num?) ?? 0,
      paymentMethod:
          (json['payment_method'] ?? 'Chưa thanh toán').toString(),
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        bookingCode,
        voucherCode,
        couponCode,
        discountText,
        discountAmount,
        bookingDate,
        bookingCreatedAt,
        statusCodeName,
        isPaid,
        qrData,
        hotelName,
        hotelAddress,
        guestName,
        guestPhone,
        specialRequest,
        checkInDate,
        checkOutDate,
        nights,
        roomTypeName,
        quantity,
        totalAmount,
        paymentMethod,
      ];
}
