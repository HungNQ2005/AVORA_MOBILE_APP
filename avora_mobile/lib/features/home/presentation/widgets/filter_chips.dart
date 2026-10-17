import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_provider.dart';
import 'home_helpers.dart';

/// Các bộ lọc nhanh dạng capsule 100% bo tròn chuyển thể từ .avora-search-filter-boxes trên Web:
/// - Gần vị trí (Ocean Sky Blue #0284c7)
/// - Miễn phí hủy (Emerald Green #059669)
/// - Thanh toán tại chỗ (Indigo #6366f1)
/// - Ưu đãi Genius (Amber Gold #d97706)
class HomeFilterChips extends ConsumerWidget {
  const HomeFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final filters = [
      const _QuickFilterSpec(
        key: 'nearby',
        label: 'Gần vị trí',
        icon: Icons.near_me_rounded,
        accentColor: Color(0xFF0284C7),
        iconBgColor: Color(0xFFE0F2FE),
        activeBgColor: Color(0xFFF0F9FF),
      ),
      const _QuickFilterSpec(
        key: 'freeCancel',
        label: 'Miễn phí hủy',
        icon: Icons.verified_user_rounded,
        accentColor: Color(0xFF059669),
        iconBgColor: Color(0xFFD1FAE5),
        activeBgColor: Color(0xFFECFDF5),
      ),
      const _QuickFilterSpec(
        key: 'payAtProperty',
        label: 'Thanh toán tại chỗ',
        icon: Icons.credit_card_rounded,
        accentColor: Color(0xFF6366F1),
        iconBgColor: Color(0xFFE0E7FF),
        activeBgColor: Color(0xFFEEF2FF),
      ),
      const _QuickFilterSpec(
        key: 'geniusOffer',
        label: 'Ưu đãi Genius',
        icon: Icons.auto_awesome_rounded,
        accentColor: Color(0xFFD97706),
        iconBgColor: Color(0xFFFEF3C7),
        activeBgColor: Color(0xFFFFFBEB),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: filters.map((f) {
          final isSelected = state.activeFilters.contains(f.key);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  ref.read(homeProvider.notifier).toggleFilter(f.key);
                  showHomeSnackBar(
                    context,
                    isSelected
                        ? 'Đã bỏ chọn bộ lọc'
                        : 'Đã kích hoạt bộ lọc: ${f.label}',
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? f.activeBgColor : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? f.accentColor
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isSelected ? f.accentColor : Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? f.accentColor
                                : const Color(0xFFCBD5E1),
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 11,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: f.iconBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(f.icon, size: 14, color: f.accentColor),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        f.label,
                        style: TextStyle(
                          color: isSelected
                              ? f.accentColor
                              : const Color(0xFF1E293B),
                          fontSize: 12.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickFilterSpec {
  final String key;
  final String label;
  final IconData icon;
  final Color accentColor;
  final Color iconBgColor;
  final Color activeBgColor;

  const _QuickFilterSpec({
    required this.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.iconBgColor,
    required this.activeBgColor,
  });
}
