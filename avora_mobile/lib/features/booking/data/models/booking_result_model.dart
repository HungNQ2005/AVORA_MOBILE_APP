import 'package:equatable/equatable.dart';

/// Data model đại diện cho kết quả trả về khi tạo đơn đặt phòng thành công
/// Đồng bộ 1:1 với phản hồi API `POST /api/bookings`
class BookingResultModel extends Equatable {
  final String bookingId;
  final String bookingCode;
  final String bookingStatusCd;
  final String? statusCodeName;
  final String hotelId;
  final String guestName;
  final String guestPhone;
  final num totalAmount;
  final num discountAmount;
  final String? couponApplied;
  final String? createdAt;
  final String? hotelName;
  final String? roomName;

  const BookingResultModel({
    required this.bookingId,
    required this.bookingCode,
    required this.bookingStatusCd,
    this.statusCodeName,
    required this.hotelId,
    required this.guestName,
    required this.guestPhone,
    required this.totalAmount,
    this.discountAmount = 0,
    this.couponApplied,
    this.createdAt,
    this.hotelName,
    this.roomName,
  });

  factory BookingResultModel.fromJson(Map<String, dynamic> json) {
    return BookingResultModel(
      bookingId: (json['booking_id'] ?? '').toString(),
      bookingCode: (json['booking_code'] ?? '').toString(),
      bookingStatusCd: (json['booking_status_cd'] ?? '1').toString(),
      statusCodeName: json['status_code_name']?.toString(),
      hotelId: (json['hotel_id'] ?? '').toString(),
      guestName: json['guest_name']?.toString() ?? '',
      guestPhone: json['guest_phone']?.toString() ?? '',
      totalAmount: (json['total_amount'] as num?) ?? 0,
      discountAmount: (json['discount_amount'] as num?) ?? 0,
      couponApplied: json['coupon_applied']?.toString(),
      createdAt: json['created_at']?.toString(),
      hotelName: json['hotel_name']?.toString(),
      roomName: json['room_name']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        bookingCode,
        bookingStatusCd,
        statusCodeName,
        hotelId,
        guestName,
        guestPhone,
        totalAmount,
        discountAmount,
        couponApplied,
        createdAt,
        hotelName,
        roomName,
      ];
}
