import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_provider.dart';
import 'home_helpers.dart';

/// Các bộ lọc nhanh dạng capsule.
class HomeFilterChips extends ConsumerWidget {
  const HomeFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final filters = [
      {'key': 'nearby', 'label': 'Gần vị trí', 'icon': Icons.near_me},
      {'key': 'freeCancel', 'label': 'Miễn phí hủy', 'icon': Icons.security},
      {
        'key': 'payAtProperty',
        'label': 'Thanh toán tại chỗ',
        'icon': Icons.payment
      },
      {'key': 'geniusOffer', 'label': 'Ưu đãi Genius', 'icon': Icons.star},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final key = f['key'] as String;
          final isSelected = state.activeFilters.contains(key);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: isSelected,
              label: Text(f['label'] as String),
              avatar: Icon(
                f['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF003580),
              ),
              selectedColor: const Color(0xFF003580),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF003580)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              onSelected: (_) {
                ref.read(homeProvider.notifier).toggleFilter(key);
                showHomeSnackBar(
                    context,
                    isSelected
                        ? 'Đã bỏ chọn bộ lọc'
                        : 'Đã kích hoạt bộ lọc: ${f['label']}');
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
