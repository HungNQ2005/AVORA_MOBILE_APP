import 'package:equatable/equatable.dart';

/// Model chứa thông tin mã QR thanh toán VietQR (SePay) trả về từ `POST /api/payment/create-qr`.
class PaymentQrModel extends Equatable {
  final String bookingId;
  final String bookingRef;
  final String hotelName;
  final String qrUrl;
  final String paymentCode;
  final num amount;
  final String bankCode;
  final String accountNumber;
  final String accountHolder;
  final int remainingTimeSeconds;

  const PaymentQrModel({
    required this.bookingId,
    required this.bookingRef,
    required this.hotelName,
    required this.qrUrl,
    required this.paymentCode,
    required this.amount,
    required this.bankCode,
    required this.accountNumber,
    required this.accountHolder,
    required this.remainingTimeSeconds,
  });

  factory PaymentQrModel.fromJson(Map<String, dynamic> json) {
    return PaymentQrModel(
      bookingId: (json['booking_id'] ?? '').toString(),
      bookingRef: (json['booking_ref'] ?? '').toString(),
      hotelName: (json['hotel_name'] ?? '').toString(),
      qrUrl: (json['qr_url'] ?? '').toString(),
      paymentCode: (json['payment_code'] ?? '').toString(),
      amount: (json['amount'] as num?) ?? 0,
      bankCode: (json['bank_code'] ?? '').toString(),
      accountNumber: (json['account_number'] ?? '').toString(),
      accountHolder: (json['account_holder'] ?? '').toString(),
      remainingTimeSeconds: (json['remaining_time_seconds'] as num?)?.toInt() ?? 0,
    );
  }

  /// Tên ngân hàng hiển thị thân thiện (đồng bộ với PaymentQRScreen.jsx trên Web)
  String get displayBankName => bankCode == 'MB' ? 'MB Bank (MB)' : bankCode;

  @override
  List<Object?> get props => [
        bookingId,
        bookingRef,
        hotelName,
        qrUrl,
        paymentCode,
        amount,
        bankCode,
        accountNumber,
        accountHolder,
        remainingTimeSeconds,
      ];
}

/// Model trạng thái thanh toán trả về từ `GET /api/payment/status/:bookingId`.
class PaymentStatusModel extends Equatable {
  final String bookingId;
  final String bookingStatusCd;
  final String statusCodeName;
  final bool isPaid;
  final int remainingTimeSeconds;

  const PaymentStatusModel({
    required this.bookingId,
    required this.bookingStatusCd,
    required this.statusCodeName,
    required this.isPaid,
    required this.remainingTimeSeconds,
  });

  factory PaymentStatusModel.fromJson(Map<String, dynamic> json) {
    return PaymentStatusModel(
      bookingId: (json['booking_id'] ?? '').toString(),
      bookingStatusCd: (json['booking_status_cd'] ?? '').toString(),
      statusCodeName: (json['status_code_name'] ?? '').toString().toUpperCase(),
      isPaid: json['is_paid'] == true,
      remainingTimeSeconds: (json['remaining_time_seconds'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        bookingStatusCd,
        statusCodeName,
        isPaid,
        remainingTimeSeconds,
      ];
}

