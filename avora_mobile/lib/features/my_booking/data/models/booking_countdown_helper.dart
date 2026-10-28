class BookingCountdown {
  final String label;
  final bool expired;

  const BookingCountdown({required this.label, required this.expired});
}

class BookingCountdownHelper {
  static const Duration paymentHoldDuration = Duration(minutes: 10);

  static BookingCountdown? getCountdown({
    required String createdAtStr,
    required DateTime currentTime,
  }) {
    final createdAt = _parseCreatedAt(createdAtStr);
    if (createdAt == null) return null;

    final remaining = createdAt
        .add(paymentHoldDuration)
        .difference(currentTime.toUtc());
    final expired = remaining <= Duration.zero;
    final totalSeconds = expired ? 0 : (remaining.inMilliseconds + 999) ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return BookingCountdown(
      label:
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}',
      expired: expired,
    );
  }

  static DateTime? _parseCreatedAt(String value) {
    final date = value.trim();
    if (date.isEmpty) return null;

    final hasTimezone =
        date.endsWith('Z') || RegExp(r'[+-]\d{2}(:?\d{2})?$').hasMatch(date);
    final normalized = hasTimezone
        ? date
        : date.contains('T')
        ? '${date}Z'
        : date;
    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return null;
    return parsed.isUtc
        ? parsed
        : DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
            parsed.microsecond,
          );
  }
}
