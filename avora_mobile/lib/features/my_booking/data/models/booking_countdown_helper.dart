import 'package:equatable/equatable.dart';

/// Kết quả tính toán đếm ngược thời gian giữ chỗ thanh toán 10 phút
class BookingCountdownResult extends Equatable {
  final DateTime? deadline;
  final int remainingMs;
  final int totalSeconds;
  final int minutes;
  final int seconds;
  final bool expired;
  final String label;

  const BookingCountdownResult({
    this.deadline,
    required this.remainingMs,
    required this.totalSeconds,
    required this.minutes,
    required this.seconds,
    required this.expired,
    required this.label,
  });

  @override
  List<Object?> get props => [
        deadline,
        remainingMs,
        totalSeconds,
        minutes,
        seconds,
        expired,
        label,
      ];
}

/// Helper tính toán đếm ngược thời gian thanh toán 10 phút cho đơn đặt phòng.
/// Đồng bộ chuẩn 1:1 với logic `getBookingCountdown` trên bản Web AVORA.
class BookingCountdownHelper {
  /// Thời gian chờ thanh toán: 10 phút (tính bằng milliseconds)
  static const int paymentHoldMs = 10 * 60 * 1000;

  /// Tính deadline thanh toán từ thời điểm tạo đơn
  static DateTime? getDeadline({String? createdAtStr, DateTime? createdAt}) {
    DateTime? dt = createdAt;
    if (dt == null && createdAtStr != null && createdAtStr.trim().isNotEmpty) {
      String s = createdAtStr.trim();
      if (s.contains('T') && !s.endsWith('Z') && !RegExp(r'[+-]\d{2}(:\d{2})?$').hasMatch(s)) {
        s = '${s}Z';
      }
      dt = DateTime.tryParse(s);
    }
    if (dt == null) return null;
    return dt.add(const Duration(milliseconds: paymentHoldMs));
  }

  /// Tính toán đếm ngược thời gian giữ chỗ.
  static BookingCountdownResult? getCountdown({
    required String? createdAtStr,
    required DateTime currentTime,
    DateTime? createdAt,
  }) {
    DateTime? dt = createdAt;
    if (dt == null && createdAtStr != null && createdAtStr.trim().isNotEmpty) {
      String s = createdAtStr.trim();
      if (s.contains('T') && !s.endsWith('Z') && !RegExp(r'[+-]\d{2}(:\d{2})?$').hasMatch(s)) {
        s = '${s}Z';
      }
      dt = DateTime.tryParse(s);
    }
    if (dt == null) return null;

    final deadline = dt.toUtc().add(const Duration(milliseconds: paymentHoldMs));
    final nowUtc = currentTime.toUtc();

    final remainingMs = deadline.difference(nowUtc).inMilliseconds;
    final clampedRemainingMs = remainingMs > 0 ? remainingMs : 0;
    final totalSeconds = (clampedRemainingMs / 1000).ceil();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    final label =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return BookingCountdownResult(
      deadline: deadline.toLocal(),
      remainingMs: clampedRemainingMs,
      totalSeconds: totalSeconds,
      minutes: minutes,
      seconds: seconds,
      expired: remainingMs <= 0,
      label: label,
    );
  }
}
