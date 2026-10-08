import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:avora_mobile/core/network/api_client.dart';
import '../models/ai_chat_models.dart';
import '../services/ai_recommender.dart';
import '../services/groq_client.dart';

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  return AiChatRepository(
    dio: ref.watch(apiClientProvider),
    groq: GroqClient(),
  );
});

/// AI Concierge chạy hoàn toàn phía app:
///  1. Groq trích xuất tiêu chí từ hội thoại (điểm đến, ngày, khách, ngân sách).
///  2. App gọi `GET /api/hotels` (database thật) rồi chấm điểm & chọn 3 phương án.
///  3. Groq viết lời tư vấn dựa trên đúng dữ liệu đã chọn (không bịa số liệu).
class AiChatRepository {
  final Dio _dio;
  final GroqClient _groq;

  List<String>? _cityCache;

  AiChatRepository({required Dio dio, required GroqClient groq})
      : _dio = dio,
        _groq = groq;

  static const _weekdays = [
    'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật'
  ];

  // ─── Backend: danh sách khách sạn thật ───────────────────────────────────

  Future<Map<String, dynamic>> _fetchHotels(Map<String, dynamic> query) async {
    try {
      final response = await _dio.get('/hotels', queryParameters: query);
      final raw = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);
      final data = raw['data'];
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Không tải được dữ liệu khách sạn.');
    }
  }

  List<Map<String, dynamic>> _hotelList(Map<String, dynamic> data) {
    final l = data['hotels'];
    if (l is! List) return const [];
    return l.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Danh sách thành phố có khách sạn trong database (để AI chuẩn hóa tên).
  Future<List<String>> _cities() async {
    if (_cityCache != null) return _cityCache!;
    try {
      final data = await _fetchHotels({});
      final names = _hotelList(data)
          .map((h) => '${h['city_name'] ?? ''}')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      _cityCache = names;
    } catch (_) {
      _cityCache = const [];
    }
    return _cityCache!;
  }

  // ─── Bước 1: trích xuất tiêu chí ─────────────────────────────────────────

  Future<Map<String, dynamic>> _extract(
    List<Map<String, String>> messages,
    Map<String, dynamic> prev,
  ) async {
    final now = DateTime.now();
    final today =
        '${_weekdays[now.weekday - 1]}, ${DateFormat('yyyy-MM-dd').format(now)}';
    final cities = await _cities();

    final system = '''
Bạn là bộ phân tích yêu cầu du lịch cho nền tảng đặt phòng Avora (Việt Nam).
Hôm nay là $today.
Các thành phố có trong hệ thống: ${cities.isEmpty ? '(chưa có dữ liệu)' : cities.join(', ')}.
Tiêu chí đã biết từ lượt trước: ${jsonEncode(prev)}.

Chỉ trả về MỘT đối tượng JSON, không giải thích, theo dạng:
{
  "intent": "search" | "chat",
  "reply": "chỉ điền khi intent=chat: câu trả lời ngắn hoặc câu hỏi làm rõ bằng tiếng Việt",
  "criteria": {
    "destination": "tên thành phố CHÍNH XÁC theo danh sách trên, hoặc null",
    "checkIn": "YYYY-MM-DD hoặc null",
    "checkOut": "YYYY-MM-DD hoặc null",
    "adults": số nguyên hoặc null,
    "children": số nguyên hoặc null,
    "rooms": số nguyên hoặc null,
    "budget": số tiền VND (số nguyên) hoặc null,
    "budgetType": "total" | "per_night" | null,
    "preferences": ["từ khóa tiện ích/nhu cầu, ví dụ: hồ bơi, ăn sáng, gần biển, gia đình"]
  }
}
Quy tắc:
- Kế thừa tiêu chí cũ, chỉ ghi đè phần người dùng vừa thay đổi.
- "triệu"/"tr" = 1.000.000; "k"/"nghìn" = 1.000. Quy đổi ngày tương đối (cuối tuần này, thứ 6 tuần sau...) sang ngày cụ thể dựa theo hôm nay.
- "2 lớn 1 nhỏ" => adults=2, children=1.
- Ngân sách "cả chuyến/tổng" => budgetType="total"; "mỗi đêm/một đêm" => "per_night".
- intent="search" khi đã biết điểm đến HOẶC ngân sách. Nếu thiếu cả hai, intent="chat" và hỏi lại ngắn gọn.
- Câu hỏi không liên quan du lịch/đặt phòng: intent="chat", từ chối lịch sự và gợi ý quay lại chủ đề.''';

    final recent = messages.length > 8
        ? messages.sublist(messages.length - 8)
        : messages;

    final raw = await _groq.complete(
      [
        {'role': 'system', 'content': system},
        ...recent,
      ],
      json: true,
      temperature: 0.1,
      maxTokens: 500,
    );

    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
    } catch (_) {}
    return {
      'intent': 'chat',
      'reply': 'Mình chưa hiểu rõ yêu cầu, bạn nói lại giúp mình nhé?',
      'criteria': <String, dynamic>{},
    };
  }

  // ─── Bước 3: lời tư vấn ──────────────────────────────────────────────────

  Future<String> _writeReply(
    SearchCriteria c,
    List<Map<String, dynamic>> items,
    String note,
  ) async {
    final facts = items.map((it) {
      final ai = it['ai'] as Map;
      return {
        'ten': it['name'],
        'nhan': ai['badge_label'],
        'thanh_pho': it['city_name'],
        'hang_sao': it['star_quality'],
        'diem': it['star_rating'],
        'gia_moi_dem': it['price'],
        'tong_gia': ai['total_price'],
        'ghi_chu_ngan_sach': ai['budget_note'],
        'tien_ich': ai['perks'],
        'phong': (it['room_highlight'] is Map) ? it['room_highlight']['name'] : null,
      };
    }).toList();

    const system =
        '''Bạn là Avora AI Concierge, trợ lý du lịch thân thiện của nền tảng đặt phòng Avora.
Viết lời tư vấn tiếng Việt 3-4 câu, tự nhiên, xưng "mình", gọi khách là "bạn".
CHỈ dùng dữ kiện được cung cấp, tuyệt đối không bịa số liệu hay tiện ích. Tiền ghi dạng 2.190.000đ.
Nêu ngắn gọn vì sao phương án tối ưu phù hợp, và nhắc phương án tiết kiệm/nâng hạng nếu có. Không dùng markdown, không liệt kê dạng gạch đầu dòng.''';

    final user = '''Tiêu chí: ${jsonEncode({
          'diem_den': c.destination.isEmpty ? 'toàn quốc' : c.destination,
          'ngay_den': c.checkIn,
          'ngay_di': c.checkOut,
          'so_dem': c.nights,
          'nguoi_lon': c.adults,
          'tre_em': c.children,
          'so_phong': c.rooms,
          'ngan_sach': c.budget,
          'loai_ngan_sach': c.budget == null
              ? null
              : (c.budgetType == 'total' ? 'tổng cả chuyến' : 'mỗi đêm'),
        })}
Các phương án: ${jsonEncode(facts)}
Lưu ý thêm: ${note.isEmpty ? 'không' : note}''';

    try {
      final text = await _groq.complete(
        [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
        temperature: 0.5,
        maxTokens: 400,
      );
      if (text.trim().isNotEmpty) return text.trim();
    } on ApiException catch (e) {
      if (e.statusCode == 401) rethrow;
    }

    final best = items.first;
    final ai = best['ai'] as Map;
    return 'Mình tìm được ${items.length} lựa chọn phù hợp. Nổi bật nhất là ${best['name']} '
        'với giá ${fmtVnd(best['price'] as num)}/đêm (tổng ${fmtVnd(ai['total_price'] as num)} cho ${c.nights} đêm).';
  }

  /// Tải 3 khách sạn gợi ý ban đầu trực tiếp từ database khi vừa mở trang.
  Future<AiChatResponse> getInitialRecommendations() async {
    final now = DateTime.now();
    final checkIn =
        DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
    final checkOut =
        DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 3)));

    final defaultCriteria = {
      'destination': 'Đà Nẵng',
      'checkIn': checkIn,
      'checkOut': checkOut,
      'adults': 2,
      'children': 1,
      'rooms': 1,
      'budget': 5000000,
      'budgetType': 'total',
      'preferences': ['view biển', 'buffet sáng'],
    };

    final c = normalizeCriteria(defaultCriteria);

    var data = await _fetchHotels({
      'destination': 'Đà Nẵng',
      'checkIn': checkIn,
      'checkOut': checkOut,
      'adults': 2,
      'children': 1,
      'rooms': 1,
      'onlyAvailable': 'true',
      'sortBy': 'rating_price',
    });

    var hotels = _hotelList(data);
    if (hotels.isEmpty) {
      data = await _fetchHotels({'onlyAvailable': 'true', 'sortBy': 'rating_price'});
      hotels = _hotelList(data);
    }

    if (hotels.isEmpty) {
      data = await _fetchHotels({});
      hotels = _hotelList(data);
    }

    final items = buildPicks(hotels, c);

    return AiChatResponse(
      reply:
          'Mình đã quét các phòng trống tại Đà Nẵng và chọn ra 3 lựa chọn tối ưu nhất '
          'cho 2 người lớn + 1 trẻ nhỏ với ngân sách khoảng 1.8 - 2.5 triệu/đêm!',
      hotels: items.map(AiHotelPick.fromJson).toList(),
      criteria: defaultCriteria,
      summary: AiSearchSummary(
        destination: c.destination.isEmpty ? 'Đà Nẵng' : c.destination,
        checkIn: checkIn,
        checkOut: checkOut,
        nights: 2,
        adults: 2,
        children: 1,
        rooms: 1,
        budget: 5000000,
        budgetType: 'total',
        totalFound: hotels.length,
      ),
      quickReplies: const [
        'Có xe đưa đón sân bay không?',
        'Check-in sớm được không?',
        'Có chỗ nào rẻ hơn không?',
      ],
    );
  }

  // ─── Entry point ─────────────────────────────────────────────────────────

  Future<AiChatResponse> chat({
    required List<Map<String, String>> messages,
    required Map<String, dynamic> criteria,
  }) async {
    final extracted = await _extract(messages, criteria);
    final nextCriteria = extracted['criteria'] is Map
        ? Map<String, dynamic>.from(extracted['criteria'] as Map)
        : <String, dynamic>{};
    final merged = mergeCriteria(criteria, nextCriteria);

    if (extracted['intent'] != 'search') {
      return AiChatResponse(
        reply: extracted['reply']?.toString().trim().isNotEmpty == true
            ? extracted['reply'].toString()
            : 'Bạn muốn nghỉ ở đâu, ngày nào và ngân sách khoảng bao nhiêu? Mình sẽ gợi ý ngay.',
        criteria: merged,
        quickReplies: const [
          'Đà Nẵng 2 đêm dưới 5 triệu',
          'Phú Quốc cho gia đình 2 lớn 1 nhỏ',
          'Khách sạn gần biển giá tốt',
        ],
      );
    }

    final c = normalizeCriteria(merged);

    final baseQuery = <String, dynamic>{
      if (c.destination.isNotEmpty) 'destination': c.destination,
      'checkIn': c.checkIn,
      'checkOut': c.checkOut,
      'adults': c.adults,
      'children': c.children,
      'rooms': c.rooms,
      'onlyAvailable': 'true',
      'sortBy': 'rating_price',
    };

    var data = await _fetchHotels({
      ...baseQuery,
      if (c.perNightCap != null)
        'maxPrice': (c.perNightCap! * upgradeMargin).round(),
    });

    if (data['exceededCapacity'] == true) {
      return AiChatResponse(
        reply: data['message']?.toString() ??
            'Số khách vượt sức chứa tối đa của một phòng.',
        criteria: merged,
        quickReplies: [
          if (data['minRoomsRequired'] != null)
            'Tăng lên ${data['minRoomsRequired']} phòng',
        ],
      );
    }

    var note = '';
    var hotels = _hotelList(data);
    if (hotels.isEmpty && c.perNightCap != null) {
      data = await _fetchHotels(baseQuery);
      hotels = _hotelList(data);
      note =
          'Không có khách sạn nào trong ngân sách ${fmtVnd(c.budget!)}; các phương án dưới đây đều cao hơn ngân sách, hãy nói rõ điều này.';
    }

    if (hotels.isEmpty) {
      return AiChatResponse(
        reply:
            'Rất tiếc, mình chưa tìm thấy chỗ nghỉ phù hợp${c.destination.isNotEmpty ? ' tại ${c.destination}' : ''} '
            'cho ${c.checkIn} → ${c.checkOut}. Bạn thử đổi ngày hoặc điểm đến nhé?',
        criteria: merged,
        quickReplies: const ['Đổi sang ngày khác', 'Tìm ở thành phố khác'],
      );
    }

    final items = buildPicks(hotels, c);
    if (c.assumedDates) {
      note +=
          ' Người dùng chưa nói ngày cụ thể nên hệ thống tạm tính từ ngày mai, 1 đêm; hãy nhắc họ cho biết ngày chính xác.';
    }

    final reply = await _writeReply(c, items, note.trim());

    return AiChatResponse(
      reply: reply,
      hotels: items.map(AiHotelPick.fromJson).toList(),
      criteria: merged,
      summary: AiSearchSummary(
        destination: c.destination.isEmpty ? 'Toàn quốc' : c.destination,
        checkIn: c.checkIn,
        checkOut: c.checkOut,
        nights: c.nights,
        adults: c.adults,
        children: c.children,
        rooms: c.rooms,
        budget: c.budget,
        budgetType: c.budget == null ? null : c.budgetType,
        assumedDates: c.assumedDates,
        totalFound: hotels.length,
      ),
      quickReplies: const [
        'Có view biển không?',
        'Có chỗ nào rẻ hơn không?',
        'Đổi sang 3 đêm',
      ],
    );
  }
}
