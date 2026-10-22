class BookingCountdown {
  final String label;
  final bool expired;

  const BookingCountdown({required this.label, required this.expired});
}

class BookingCountdownHelper {
  static const _paymentHold = Duration(minutes: 10);

  static BookingCountdown? getCountdown({
    required String createdAtStr,
    required DateTime currentTime,
  }) {
    final input = createdAtStr.trim();
    if (input.isEmpty) return null;

    var normalized = input;
    if (normalized.contains('T') &&
        !normalized.endsWith('Z') &&
        !RegExp(r'[+-]\d{2}(:\d{2})?$').hasMatch(normalized)) {
      normalized = '${normalized}Z';
    }

    final createdAt = DateTime.tryParse(normalized);
    if (createdAt == null) return null;

    final remainingMs = createdAt
        .add(_paymentHold)
        .difference(currentTime)
        .inMilliseconds;
    final expired = remainingMs <= 0;
    final totalSeconds = expired ? 0 : (remainingMs + 999) ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return BookingCountdown(
      label: '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      expired: expired,
    );
  }
}