import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:avora_mobile/features/my_booking/data/models/booking_item_model.dart';

/// Model tóm tắt một hóa đơn trong danh sách hóa đơn thanh toán
class InvoiceListItemModel extends Equatable {
  final String bookingId;
  final String bookingCode;
  final String invoiceNumber;
  final String lookupCode;
  final String hotelName;
  final String hotelAddress;
  final String? hotelThumbnailUrl;
  final String checkInDate;
  final String checkOutDate;
  final int nights;
  final String roomTypeName;
  final num totalAmount;
  final num amountPaid;
  final String? transactionId;
  final String? gatewayRefId;
  final String paymentMethod;
  final String? paymentMethodCd;
  final String? paidAt;
  final String? issuedDate;
  final String bookingStatusCd;
  final String statusCodeName;
  final String statusName;
  final String invoiceStatus;
  final bool isPaid;
  final bool hasVatInvoice;

  const InvoiceListItemModel({
    required this.bookingId,
    required this.bookingCode,
    required this.invoiceNumber,
    required this.lookupCode,
    required this.hotelName,
    required this.hotelAddress,
    this.hotelThumbnailUrl,
    required this.checkInDate,
    required this.checkOutDate,
    this.nights = 1,
    required this.roomTypeName,
    required this.totalAmount,
    required this.amountPaid,
    this.transactionId,
    this.gatewayRefId,
    required this.paymentMethod,
    this.paymentMethodCd,
    this.paidAt,
    this.issuedDate,
    required this.bookingStatusCd,
    required this.statusCodeName,
    required this.statusName,
    required this.invoiceStatus,
    this.isPaid = false,
    this.hasVatInvoice = false,
  });

  /// Khởi tạo từ [BookingItemModel] của API `GET /api/bookings/my`
  factory InvoiceListItemModel.fromBookingItem(BookingItemModel booking) {
    final year = booking.createdAt != null && booking.createdAt!.length >= 4
        ? booking.createdAt!.substring(0, 4)
        : DateTime.now().year.toString();

    final shortId = booking.bookingId.length >= 6
        ? booking.bookingId.substring(0, 6).toUpperCase()
        : booking.bookingId.toUpperCase();

    final invoiceNumber = 'BK-$year-$shortId';
    final lookupCode = booking.bookingId.length >= 8
        ? booking.bookingId.substring(0, 8).toUpperCase()
        : (booking.bookingCode.isNotEmpty ? booking.bookingCode : shortId);

    final isPaid = booking.payment.isPaid || booking.payment.amountPaid > 0;
    final amountPaid = booking.payment.amountPaid > 0
        ? booking.payment.amountPaid
        : (isPaid ? booking.totalAmount : 0);

    final txnId = booking.payment.transactionId?.isNotEmpty == true
        ? booking.payment.transactionId
        : booking.payment.gatewayRefId;

    final invoiceStatus = isPaid
        ? 'Đã ghi nhận giao dịch thành công'
        : (booking.statusCodeName == 'CFM'
            ? 'Đã xác nhận đơn đặt phòng'
            : 'Chờ thanh toán');

    return InvoiceListItemModel(
      bookingId: booking.bookingId,
      bookingCode: booking.bookingCode.isNotEmpty
          ? booking.bookingCode
          : lookupCode,
      invoiceNumber: invoiceNumber,
      lookupCode: lookupCode,
      hotelName: booking.hotel.name,
      hotelAddress: booking.hotel.address,
      hotelThumbnailUrl: booking.hotel.thumbnailUrl,
      checkInDate: booking.stay.checkInDate,
      checkOutDate: booking.stay.checkOutDate,
      nights: booking.stay.nights,
      roomTypeName: booking.stay.roomTypeName,
      totalAmount: booking.totalAmount,
      amountPaid: amountPaid,
      transactionId: txnId,
      gatewayRefId: booking.payment.gatewayRefId,
      paymentMethod: booking.payment.paymentMethod,
      paymentMethodCd: booking.payment.paymentMethodCd,
      paidAt: booking.payment.paidAt ?? booking.bookingDateFormatted,
      issuedDate: booking.bookingDateFormatted.isNotEmpty
          ? booking.bookingDateFormatted
          : booking.createdAt,
      bookingStatusCd: booking.bookingStatusCd ?? '1',
      statusCodeName: booking.statusCodeName,
      statusName: booking.statusName,
      invoiceStatus: invoiceStatus,
      isPaid: isPaid,
      hasVatInvoice: booking.payment.hasVatInvoice,
    );
  }

  /// Tiền thanh toán định dạng VND: "1.200.000 ₫"
  String get formattedAmountPaid {
    final currency = NumberFormat('#,###', 'vi_VN');
    return '${currency.format(amountPaid)} ₫';
  }

  /// Tổng tiền định dạng VND: "1.200.000 ₫"
  String get formattedTotalAmount {
    final currency = NumberFormat('#,###', 'vi_VN');
    return '${currency.format(totalAmount)} ₫';
  }

  /// Ngày thanh toán hiển thị ngắn gọn
  String get formattedDisplayDate {
    if (paidAt != null && paidAt!.isNotEmpty) {
      try {
        final d = DateTime.parse(paidAt!);
        return DateFormat('dd/MM/yyyy HH:mm').format(d);
      } catch (_) {
        return paidAt!;
      }
    }
    if (issuedDate != null && issuedDate!.isNotEmpty) {
      try {
        final d = DateTime.parse(issuedDate!);
        return DateFormat('dd/MM/yyyy').format(d);
      } catch (_) {
        return issuedDate!;
      }
    }
    return '';
  }

  @override
  List<Object?> get props => [
        bookingId,
        bookingCode,
        invoiceNumber,
        lookupCode,
        hotelName,
        hotelAddress,
        hotelThumbnailUrl,
        checkInDate,
        checkOutDate,
        nights,
        roomTypeName,
        totalAmount,
        amountPaid,
        transactionId,
        gatewayRefId,
        paymentMethod,
        paymentMethodCd,
        paidAt,
        issuedDate,
        bookingStatusCd,
        statusCodeName,
        statusName,
        invoiceStatus,
        isPaid,
        hasVatInvoice,
      ];
}

/// Model chi tiết đầy đủ của một hóa đơn & giao dịch thanh toán thành công
class InvoiceDetailModel extends Equatable {
  final String invoiceNumber;
  final String lookupCode;
  final String bookingId;
  final String bookingCode;
  final String? transactionId;
  final String? gatewayRefId;
  final String hotelName;
  final String hotelAddress;
  final String? hotelThumbnailUrl;
  final String issuedDate;
  final String? paidAt;
  final String buyerName;
  final String buyerPhone;
  final num subtotal;
  final num discountAmount;
  final String? couponCode;
  final num totalAmount;
  final num amountPaid;
  final String? paymentMethodCd;
  final String paymentMethod;
  final String bookingStatusCd;
  final String? statusCodeName;
  final String invoiceStatus;
  final bool isPaid;
  final String? roomTypeName;
  final String? checkInDate;
  final String? checkOutDate;
  final int nights;
  final int quantity;

  const InvoiceDetailModel({
    required this.invoiceNumber,
    required this.lookupCode,
    required this.bookingId,
    required this.bookingCode,
    this.transactionId,
    this.gatewayRefId,
    required this.hotelName,
    required this.hotelAddress,
    this.hotelThumbnailUrl,
    required this.issuedDate,
    this.paidAt,
    required this.buyerName,
    required this.buyerPhone,
    required this.subtotal,
    this.discountAmount = 0,
    this.couponCode,
    required this.totalAmount,
    required this.amountPaid,
    this.paymentMethodCd,
    required this.paymentMethod,
    required this.bookingStatusCd,
    this.statusCodeName,
    required this.invoiceStatus,
    this.isPaid = false,
    this.roomTypeName,
    this.checkInDate,
    this.checkOutDate,
    this.nights = 1,
    this.quantity = 1,
  });

  /// Parse dữ liệu từ endpoint `GET /api/bookings/:id/invoice` và bổ sung thông tin từ `GET /api/bookings/:id`
  factory InvoiceDetailModel.fromCombined({
    required String bookingId,
    required Map<String, dynamic> invoiceJson,
    Map<String, dynamic>? bookingJson,
  }) {
    final year = DateTime.now().year.toString();
    final shortId = bookingId.length >= 6
        ? bookingId.substring(0, 6).toUpperCase()
        : bookingId.toUpperCase();

    final invoiceNumber = invoiceJson['invoice_number']?.toString() ??
        'BK-$year-$shortId';

    final lookupCode = invoiceJson['lookup_code']?.toString() ??
        (bookingId.length >= 8
            ? bookingId.substring(0, 8).toUpperCase()
            : shortId);

    // Thông tin khách sạn
    final hotelMap = (bookingJson?['m_hotel'] is Map)
        ? Map<String, dynamic>.from(bookingJson!['m_hotel'] as Map)
        : (bookingJson?['hotel'] is Map)
            ? Map<String, dynamic>.from(bookingJson!['hotel'] as Map)
            : null;

    final hotelName = invoiceJson['hotel_name']?.toString() ??
        hotelMap?['name']?.toString() ??
        'Khách sạn AVORA';

    final hotelAddress = invoiceJson['hotel_address']?.toString() ??
        hotelMap?['address']?.toString() ??
        '';

    String? thumbnailUrl;
    if (hotelMap?['thumbnail_url'] != null) {
      thumbnailUrl = hotelMap!['thumbnail_url']?.toString();
    } else if (hotelMap?['images'] is List && (hotelMap!['images'] as List).isNotEmpty) {
      thumbnailUrl = (hotelMap['images'] as List).first?.toString();
    }

    // Thông tin phòng & lưu trú từ `t_booking_detail` hoặc `stay`
    String? roomTypeName;
    String? checkInDate;
    String? checkOutDate;
    int nights = 1;
    int quantity = 1;

    if (bookingJson != null) {
      if (bookingJson['t_booking_detail'] is List &&
          (bookingJson['t_booking_detail'] as List).isNotEmpty) {
        final firstDetail = Map<String, dynamic>.from(
          (bookingJson['t_booking_detail'] as List).first as Map,
        );
        checkInDate = firstDetail['check_in_date']?.toString();
        checkOutDate = firstDetail['check_out_date']?.toString();
        quantity = (firstDetail['quantity'] as num?)?.toInt() ?? 1;

        final roomType = firstDetail['m_room_type'];
        if (roomType is Map) {
          roomTypeName = roomType['name']?.toString();
        }
      } else if (bookingJson['stay'] is Map) {
        final stayMap = Map<String, dynamic>.from(bookingJson['stay'] as Map);
        checkInDate = stayMap['check_in_date']?.toString();
        checkOutDate = stayMap['check_out_date']?.toString();
        roomTypeName = stayMap['room_type_name']?.toString();
        nights = (stayMap['nights'] as num?)?.toInt() ?? 1;
        quantity = (stayMap['quantity'] as num?)?.toInt() ?? 1;
      }
    }

    if (checkInDate != null && checkOutDate != null) {
      try {
        final dIn = DateTime.parse(checkInDate);
        final dOut = DateTime.parse(checkOutDate);
        final diff = dOut.difference(dIn).inDays;
        if (diff > 0) nights = diff;
      } catch (_) {}
    }

    // Giao dịch thanh toán (t_payment_transaction)
    String? transactionId;
    String? paidAt;
    String? paymentMethodCd = invoiceJson['payment_method_cd']?.toString();

    if (bookingJson != null &&
        bookingJson['t_payment_transaction'] is List &&
        (bookingJson['t_payment_transaction'] as List).isNotEmpty) {
      final firstTxn = Map<String, dynamic>.from(
        (bookingJson['t_payment_transaction'] as List).first as Map,
      );
      transactionId = firstTxn['transaction_id']?.toString();
      paidAt = firstTxn['paid_at']?.toString();
      paymentMethodCd ??= firstTxn['payment_method_cd']?.toString();
    } else if (bookingJson?['payment'] is Map) {
      final payMap = Map<String, dynamic>.from(bookingJson!['payment'] as Map);
      transactionId = payMap['transaction_id']?.toString();
      paidAt = payMap['paid_at']?.toString();
      paymentMethodCd ??= payMap['payment_method_cd']?.toString();
    }

    final gatewayRefId = invoiceJson['gateway_ref_id']?.toString() ??
        bookingJson?['payment']?['gateway_ref_id']?.toString();

    // Nếu không có transaction_id UUID, dùng gateway_ref_id
    transactionId ??= gatewayRefId;

    final subtotal = (invoiceJson['subtotal'] as num?) ??
        (bookingJson?['total_amount'] as num?) ??
        0;

    final discountAmount = (invoiceJson['discount_amount'] as num?) ??
        (bookingJson?['discount_amount'] as num?) ??
        0;

    final totalAmount = (invoiceJson['total_amount'] as num?) ??
        (bookingJson?['total_amount'] as num?) ??
        0;

    final amountPaid = (invoiceJson['amount_paid'] as num?) ??
        (bookingJson?['payment']?['amount_paid'] as num?) ??
        (totalAmount > 0 ? totalAmount : 0);

    final couponCode = invoiceJson['coupon_code']?.toString() ??
        bookingJson?['m_coupon']?['code']?.toString() ??
        bookingJson?['coupon']?['code']?.toString();

    final bookingStatusCd = invoiceJson['booking_status_cd']?.toString() ??
        bookingJson?['booking_status_cd']?.toString() ??
        '2';

    final statusCodeName = invoiceJson['status_code_name']?.toString() ??
        bookingJson?['status_code_name']?.toString();

    final isPaid = amountPaid > 0 ||
        bookingJson?['payment']?['is_paid'] == true ||
        statusCodeName == 'CFM' ||
        bookingStatusCd == '2';

    final paymentMethod = _formatPaymentMethod(
      paymentMethodCd: paymentMethodCd,
      serverMethod: bookingJson?['payment']?['payment_method']?.toString(),
    );

    final invoiceStatus = invoiceJson['invoice_status']?.toString() ??
        (isPaid
            ? 'Đã ghi nhận giao dịch thành công'
            : (statusCodeName == 'CFM'
                ? 'Đơn đã xác nhận'
                : 'Chờ thanh toán'));

    final buyerName = invoiceJson['buyer_name']?.toString() ??
        bookingJson?['guest_name']?.toString() ??
        '';

    final buyerPhone = invoiceJson['buyer_phone']?.toString() ??
        bookingJson?['guest_phone']?.toString() ??
        '';

    final issuedDate = invoiceJson['issued_date']?.toString() ??
        (bookingJson?['created_at'] != null
            ? DateFormat('dd/MM/yyyy').format(
                DateTime.parse(bookingJson!['created_at'].toString()))
            : DateFormat('dd/MM/yyyy').format(DateTime.now()));

    final bookingCode = bookingJson?['booking_code']?.toString() ??
        invoiceJson['booking_code']?.toString() ??
        lookupCode;

    return InvoiceDetailModel(
      invoiceNumber: invoiceNumber,
      lookupCode: lookupCode,
      bookingId: bookingId,
      bookingCode: bookingCode,
      transactionId: transactionId,
      gatewayRefId: gatewayRefId,
      hotelName: hotelName,
      hotelAddress: hotelAddress,
      hotelThumbnailUrl: thumbnailUrl,
      issuedDate: issuedDate,
      paidAt: paidAt,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      subtotal: subtotal,
      discountAmount: discountAmount,
      couponCode: couponCode,
      totalAmount: totalAmount,
      amountPaid: amountPaid,
      paymentMethodCd: paymentMethodCd,
      paymentMethod: paymentMethod,
      bookingStatusCd: bookingStatusCd,
      statusCodeName: statusCodeName,
      invoiceStatus: invoiceStatus,
      isPaid: isPaid,
      roomTypeName: roomTypeName,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      nights: nights,
      quantity: quantity,
    );
  }

  static String _formatPaymentMethod({
    String? paymentMethodCd,
    String? serverMethod,
  }) {
    if (serverMethod != null && serverMethod.trim().isNotEmpty) {
      return serverMethod.trim();
    }
    final code = (paymentMethodCd ?? '').toUpperCase().trim();
    return switch (code) {
      'BTR' => 'Chuyển khoản VietQR (SePay)',
      'CRE' => 'Thẻ tín dụng / Ghi nợ (Credit Card)',
      'CSH' => 'Tiền mặt khi nhận phòng tại khách sạn',
      'WAL' => 'Ví điện tử',
      _ => 'Chuyển khoản trực tuyến',
    };
  }

  /// Tiền tạm tính: "1.200.000 ₫"
  String get formattedSubtotal {
    final currency = NumberFormat('#,###', 'vi_VN');
    return '${currency.format(subtotal)} ₫';
  }

  /// Giảm giá: "-100.000 ₫"
  String get formattedDiscount {
    final currency = NumberFormat('#,###', 'vi_VN');
    return '-${currency.format(discountAmount)} ₫';
  }

  /// Tổng tiền: "1.100.000 ₫"
  String get formattedTotalAmount {
    final currency = NumberFormat('#,###', 'vi_VN');
    return '${currency.format(totalAmount)} ₫';
  }

  /// Số tiền đã trả: "1.100.000 ₫"
  String get formattedAmountPaid {
    final currency = NumberFormat('#,###', 'vi_VN');
    return '${currency.format(amountPaid)} ₫';
  }

  /// Định dạng thời gian thanh toán: "14:30 - 25/10/2026"
  String get formattedPaidAt {
    if (paidAt != null && paidAt!.isNotEmpty) {
      try {
        final d = DateTime.parse(paidAt!);
        return DateFormat('HH:mm - dd/MM/yyyy').format(d);
      } catch (_) {
        return paidAt!;
      }
    }
    return issuedDate;
  }

  @override
  List<Object?> get props => [
        invoiceNumber,
        lookupCode,
        bookingId,
        bookingCode,
        transactionId,
        gatewayRefId,
        hotelName,
        hotelAddress,
        hotelThumbnailUrl,
        issuedDate,
        paidAt,
        buyerName,
        buyerPhone,
        subtotal,
        discountAmount,
        couponCode,
        totalAmount,
        amountPaid,
        paymentMethodCd,
        paymentMethod,
        bookingStatusCd,
        statusCodeName,
        invoiceStatus,
        isPaid,
        roomTypeName,
        checkInDate,
        checkOutDate,
        nights,
        quantity,
      ];
}

