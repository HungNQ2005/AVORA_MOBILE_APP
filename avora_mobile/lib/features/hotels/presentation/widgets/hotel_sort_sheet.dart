import 'package:flutter/material.dart';

/// Modal BottomSheet chọn tiêu chí sắp xếp khách sạn theo chuẩn AVORA Web.
class HotelSortBottomSheet extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onSelectSort;

  const HotelSortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSelectSort,
  });

  static const List<Map<String, String>> sortOptions = [
    {
      'id': 'popularity',
      'title': 'Độ phổ biến hàng đầu',
      'subtitle': 'Lựa chọn hàng đầu kết hợp đánh giá thực tế và lượt đặt phòng',
    },
    {
      'id': 'price_asc',
      'title': 'Giá (thấp đến cao)',
      'subtitle': 'Xem các mức giá tiết kiệm và ưu đãi nhất trước tiên',
    },
    {
      'id': 'rating_price',
      'title': 'Điểm đánh giá & Giá tốt',
      'subtitle': 'Điểm đánh giá xuất sắc nhất với mức chi phí tối ưu nhất',
    },
    {
      'id': 'beach_distance',
      'title': 'Gần bãi biển nhất',
      'subtitle': 'Ưu tiên chỗ nghỉ sát bờ biển và gần trung tâm du lịch',
    },
  ];

  static Future<void> show(
    BuildContext context, {
    required String currentSort,
    required ValueChanged<String> onSelectSort,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => HotelSortBottomSheet(
        currentSort: currentSort,
        onSelectSort: (newSort) {
          Navigator.pop(ctx);
          onSelectSort(newSort);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.swap_vert,
                      color: Color(0xFF003580), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Sắp xếp theo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Options
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sortOptions.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final option = sortOptions[index];
                  final isSelected = option['id'] == currentSort;

                  return InkWell(
                    onTap: () => onSelectSort(option['id']!),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option['title']!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF003580)
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  option['subtitle']!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? const Color(0xFF003580)
                                : const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
