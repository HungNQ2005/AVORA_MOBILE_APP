import 'dart:math' as math;
import 'package:intl/intl.dart';

/// Logic chấm điểm & chọn 3 phương án khách sạn (thuần Dart, không gọi mạng).
/// Dữ liệu đầu vào là JSON khách sạn lấy từ `GET /api/hotels` của backend.

const double upgradeMargin = 1.35; // "Nâng hạng" được vượt ngân sách tối đa 35%

final NumberFormat _vnd = NumberFormat('#,###', 'vi_VN');
String fmtVnd(num n) => '${_vnd.format(n.round())}đ';

int? _toInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

num? _toNum(dynamic v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

/// Tiêu chí đã chuẩn hóa (có mặc định hợp lý).
class SearchCriteria {
  final String destination;
  final String checkIn;
  final String checkOut;
  final int nights;
  final int adults;
  final int children;
  final int rooms;
  final num? budget;
  final String budgetType; // total | per_night
  final double? perNightCap;
  final List<String> preferences;
  final bool assumedDates;

  const SearchCriteria({
    required this.destination,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    required this.rooms,
    required this.budget,
    required this.budgetType,
    required this.perNightCap,
    required this.preferences,
    required this.assumedDates,
  });
}

/// Gộp tiêu chí mới vào tiêu chí cũ (bỏ qua giá trị null/rỗng).
Map<String, dynamic> mergeCriteria(
    Map<String, dynamic> prev, Map<String, dynamic>? next) {
  final out = Map<String, dynamic>.from(prev);
  next?.forEach((k, v) {
    if (v == null || v == '') return;
    if (v is List && v.isEmpty) return;
    out[k] = v;
  });
  return out;
}

SearchCriteria normalizeCriteria(Map<String, dynamic> c, {DateTime? now}) {
  final fmt = DateFormat('yyyy-MM-dd');
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);

  final adults = math.max(1, _toInt(c['adults']) ?? 2);
  final children = math.max(0, _toInt(c['children']) ?? 0);
  final guests = adults + children;
  final rooms = math.max(_toInt(c['rooms']) ?? 1, (guests / 5).ceil());

  var assumed = false;
  DateTime? ci = DateTime.tryParse('${c['checkIn'] ?? ''}');
  DateTime? co = DateTime.tryParse('${c['checkOut'] ?? ''}');
  if (ci != null) ci = DateTime(ci.year, ci.month, ci.day);
  if (co != null) co = DateTime(co.year, co.month, co.day);

  if (ci == null || ci.isBefore(today)) {
    ci = today.add(const Duration(days: 1));
    co = null;
    assumed = true;
  }
  if (co == null || !co.isAfter(ci)) {
    co = ci.add(const Duration(days: 1));
    assumed = true;
  }
  final nights = math.max(1, co.difference(ci).inDays);

  final budgetRaw = _toNum(c['budget']);
  final budget = (budgetRaw != null && budgetRaw > 0) ? budgetRaw : null;
  final budgetType = c['budgetType'] == 'per_night' ? 'per_night' : 'total';
  double? cap;
  if (budget != null) {
    cap = budgetType == 'per_night'
        ? budget / rooms
        : budget / (nights * rooms);
  }

  final prefs = (c['preferences'] is List)
      ? (c['preferences'] as List).map((e) => e.toString()).toList()
      : <String>[];

  return SearchCriteria(
    destination: (c['destination'] ?? '').toString(),
    checkIn: fmt.format(ci),
    checkOut: fmt.format(co),
    nights: nights,
    adults: adults,
    children: children,
    rooms: rooms,
    budget: budget,
    budgetType: budgetType,
    perNightCap: cap,
    preferences: prefs,
    assumedDates: assumed,
  );
}

const _childKeywords = ['hồ bơi', 'bể bơi', 'trẻ', 'gia đình', 'family', 'kid'];

const badgeLabels = {
  'optimal': 'LỰA CHỌN TỐI ƯU NHẤT',
  'saving': 'LỰA CHỌN TIẾT KIỆM',
  'upgrade': 'DỊP NÂNG HẠNG',
  'match': 'GỢI Ý PHÙ HỢP',
};

class _Scored {
  final Map<String, dynamic> hotel;
  final double score;
  final List<String> matches;
  String badge = 'match';
  _Scored(this.hotel, this.score, this.matches);

  num get price => _toNum(hotel['price']) ?? 0;
  String get id => '${hotel['hotel_id']}';
}

List<String> _facilityNames(Map<String, dynamic> h) {
  final f = h['facilities'];
  if (f is! List) return const [];
  return f
      .whereType<Map>()
      .map((e) => '${e['name'] ?? ''}')
      .where((e) => e.isNotEmpty)
      .toList();
}

int _freeCancelHours(Map<String, dynamic> h) {
  final p = h['cancellation_policy'];
  if (p is Map) return _toInt(p['free_before_hours']) ?? 0;
  return 0;
}

_Scored _score(Map<String, dynamic> h, SearchCriteria c) {
  final p = _toNum(h['price']) ?? 0;
  double fit = 0.7;
  final cap = c.perNightCap;
  if (cap != null && cap > 0) {
    final ratio = p / cap;
    fit = ratio <= 1 ? 0.6 + 0.4 * ratio : math.max(0, 1 - (ratio - 1) * 3);
  }
  final rating = (_toNum(h['star_rating']) ?? 8).toDouble();
  final stars = (_toNum(h['star_quality']) ?? 4).toDouble();
  final quality = 0.6 * (rating / 10) + 0.4 * (stars / 5);

  final keywords = [...c.preferences, if (c.children > 0) ..._childKeywords];
  final names = _facilityNames(h).map((e) => e.toLowerCase()).toList();
  final addr = '${h['address'] ?? ''}'.toLowerCase();
  final matches = keywords.where((kw) {
    final k = kw.toLowerCase();
    return names.any((n) => n.contains(k)) ||
        (k.contains('biển') && addr.contains('biển'));
  }).toList();
  final fam = math.min(1.0, matches.length / 2);
  final cancel = _freeCancelHours(h) > 0 ? 1.0 : 0.0;

  final score = 0.35 * fit + 0.35 * quality + 0.2 * fam + 0.1 * cancel;
  return _Scored(h, score, matches);
}

/// Chọn tối đa 3 phương án: tối ưu / tiết kiệm / nâng hạng.
List<Map<String, dynamic>> buildPicks(
    List<Map<String, dynamic>> hotels, SearchCriteria c) {
  final scored = hotels.map((h) => _score(h, c)).toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  final cap = c.perNightCap;
  final within = cap != null ? scored.where((s) => s.price <= cap).toList() : scored;

  final picks = <_Scored>[];
  final used = <String>{};
  void add(_Scored? s, String badge) {
    if (s == null || used.contains(s.id)) return;
    used.add(s.id);
    s.badge = badge;
    picks.add(s);
  }

  add(within.isNotEmpty ? within.first : scored.first, 'optimal');

  final savingPool = within.where((s) => !used.contains(s.id)).toList()
    ..sort((a, b) => a.price.compareTo(b.price));
  add(savingPool.isNotEmpty ? savingPool.first : null, 'saving');

  final upgradePool = scored
      .where((s) =>
          !used.contains(s.id) && (cap == null || s.price <= cap * upgradeMargin))
      .toList()
    ..sort((a, b) {
      final sa = _toNum(a.hotel['star_quality']) ?? 0;
      final sb = _toNum(b.hotel['star_quality']) ?? 0;
      final byStar = sb.compareTo(sa);
      if (byStar != 0) return byStar;
      return (_toNum(b.hotel['star_rating']) ?? 0)
          .compareTo(_toNum(a.hotel['star_rating']) ?? 0);
    });
  add(upgradePool.isNotEmpty ? upgradePool.first : null, 'upgrade');

  for (final s in scored) {
    if (picks.length >= 3) break;
    add(s, 'match');
  }

  return picks.map((s) => _toItem(s, c)).toList();
}

Map<String, dynamic> _toItem(_Scored s, SearchCriteria c) {
  final h = s.hotel;
  final p = s.price;
  final total = p * c.nights * c.rooms;

  String? budgetNote;
  final cap = c.perNightCap;
  if (cap != null) {
    final diff = cap - p;
    budgetNote = diff >= 0
        ? 'Tiết kiệm ${fmtVnd(diff)}/đêm so với ngân sách'
        : 'Vượt ngân sách ${fmtVnd(-diff)}/đêm';
  }

  final fc = _freeCancelHours(h);
  final perks = <String>{
    ...s.matches.map((m) => 'Có $m'),
    if (fc > 0) 'Miễn phí hủy trước ${fc}h',
    ..._facilityNames(h),
  }.take(4).toList();

  final parts = <String>[
    'Phù hợp ${c.adults} người lớn${c.children > 0 ? ' + ${c.children} trẻ em' : ''}',
    '${fmtVnd(p)}/đêm (tổng ${fmtVnd(total)} cho ${c.nights} đêm${c.rooms > 1 ? ', ${c.rooms} phòng' : ''})',
    if (s.matches.isNotEmpty) 'có ${s.matches.join(', ')}',
    if (fc > 0) 'miễn phí hủy trước ${fc}h',
  ];

  return {
    ...h,
    'ai': {
      'badge_key': s.badge,
      'badge_label': badgeLabels[s.badge],
      'match_percent': (s.score * 100).round().clamp(50, 99),
      'nights': c.nights,
      'rooms': c.rooms,
      'total_price': total,
      'budget_note': budgetNote,
      'perks': perks,
      'reason': parts.join(' · '),
    },
  };
}
