import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/features/home/presentation/widgets/home_helpers.dart';
import '../../data/models/ai_chat_models.dart';
import '../providers/ai_chat_provider.dart';
import 'ai_hotel_pick_card.dart';

enum _Sort { fit, price, score }

/// Danh sách "3 lựa chọn chuẩn nhất" do AI đề xuất.
class AiResultsSection extends ConsumerStatefulWidget {
  const AiResultsSection({super.key});

  @override
  ConsumerState<AiResultsSection> createState() => _AiResultsSectionState();
}

class _AiResultsSectionState extends ConsumerState<AiResultsSection> {
  _Sort _sort = _Sort.fit;

  String _summaryLine(AiSearchSummary s) {
    final parts = <String>[
      '${s.nights} đêm',
      '${s.adults} người lớn${s.children > 0 ? ' + ${s.children} trẻ em' : ''}',
      if (s.rooms > 1) '${s.rooms} phòng',
      if (s.budget != null)
        'ngân sách ${homeCurrencyFormatter.format(s.budget)}đ'
            '${s.budgetType == 'per_night' ? '/đêm' : ''}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiChatProvider);
    final summary = state.summary;
    final picks = [...state.picks];

    switch (_sort) {
      case _Sort.price:
        picks.sort((a, b) => a.hotel.price.compareTo(b.hotel.price));
      case _Sort.score:
        picks.sort((a, b) => b.hotel.starRating.compareTo(a.hotel.starRating));
      case _Sort.fit:
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (picks.isEmpty)
            _EmptyResults(isLoading: state.isSending)
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${picks.length} lựa chọn chuẩn nhất cho bạn',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (summary != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${summary.destination} · ${_summaryLine(summary)}',
                          style: const TextStyle(
                              fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                        if (summary.assumedDates)
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Text(
                              'Chưa chọn ngày cụ thể — đang tính tạm từ ngày mai, 1 đêm.',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFFD97706)),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<_Sort>(
                    value: _sort,
                    isDense: true,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF0F172A)),
                    items: const [
                      DropdownMenuItem(
                          value: _Sort.fit, child: Text('Phù hợp nhất với ngân sách')),
                      DropdownMenuItem(
                          value: _Sort.price, child: Text('Giá thấp nhất')),
                      DropdownMenuItem(
                          value: _Sort.score, child: Text('Điểm đánh giá cao nhất')),
                    ],
                    onChanged: (v) => setState(() => _sort = v ?? _Sort.fit),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...picks.map((p) => AiHotelPickCard(pick: p)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 20, color: Color(0xFF0284C7)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Chưa tìm được phòng ưng ý? Hãy nhắn thêm yêu cầu ở khung chat phía trên '
                      '— ví dụ đổi ngân sách, ngày đi hoặc tiện ích mong muốn.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final bool isLoading;

  const _EmptyResults({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          if (isLoading)
            const SizedBox(
                width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3))
          else
            const Icon(Icons.travel_explore, size: 40, color: Color(0xFF93C5FD)),
          const SizedBox(height: 10),
          Text(
            isLoading
                ? 'AI đang tìm chỗ nghỉ phù hợp...'
                : 'Gợi ý của AI sẽ hiển thị ở đây',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hãy nhập điểm đến, ngày đi, số người và ngân sách để bắt đầu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
