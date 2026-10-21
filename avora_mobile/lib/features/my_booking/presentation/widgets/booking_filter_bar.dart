import 'package:flutter/material.dart';
import '../../data/models/booking_item_model.dart';

/// Thanh lọc và tìm kiếm cho trang Quản lý Đặt Chỗ
/// Đồng bộ 1:1 với BookingFilterBar.jsx trên Web
class BookingFilterBar extends StatefulWidget {
  final String activeTab;
  final ValueChanged<String> onTabChange;
  final BookingCountsModel counts;
  final String searchQuery;
  final ValueChanged<String> onSearchSubmitted;
  final String timeRange;
  final ValueChanged<String> onTimeRangeChanged;
  final List<int> availableYears;
  final bool requireVatOnly;
  final VoidCallback onToggleVatOnly;

  const BookingFilterBar({
    super.key,
    required this.activeTab,
    required this.onTabChange,
    required this.counts,
    required this.searchQuery,
    required this.onSearchSubmitted,
    required this.timeRange,
    required this.onTimeRangeChanged,
    this.availableYears = const [],
    required this.requireVatOnly,
    required this.onToggleVatOnly,
  });

  @override
  State<BookingFilterBar> createState() => _BookingFilterBarState();
}

class _BookingFilterBarState extends State<BookingFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant BookingFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text &&
        widget.searchQuery != oldWidget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. TABS TRẠNG THÁI (All, Upcoming, Completed, Cancelled) ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TabPill(
                  label: 'Tất cả đơn',
                  count: widget.counts.all,
                  isActive: widget.activeTab == 'all',
                  onTap: () => widget.onTabChange('all'),
                ),
                const SizedBox(width: 8),
                _TabPill(
                  label: 'Sắp tới',
                  count: widget.counts.upcoming,
                  isActive: widget.activeTab == 'upcoming',
                  badgeColor: const Color(0xFFFEF3C7),
                  badgeTextColor: const Color(0xFF92400E),
                  onTap: () => widget.onTabChange('upcoming'),
                ),
                const SizedBox(width: 8),
                _TabPill(
                  label: 'Đã hoàn thành',
                  count: widget.counts.completed,
                  isActive: widget.activeTab == 'completed',
                  onTap: () => widget.onTabChange('completed'),
                ),
                const SizedBox(width: 8),
                _TabPill(
                  label: 'Đã hủy',
                  count: widget.counts.cancelled,
                  isActive: widget.activeTab == 'cancelled',
                  badgeColor: const Color(0xFFFEE2E2),
                  badgeTextColor: const Color(0xFF991B1B),
                  onTap: () => widget.onTabChange('cancelled'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ─── 2. THANH TÌM KIẾM THEO MÃ / TÊN / ĐỊA CHỈ ────────────────
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => widget.onSearchSubmitted(value),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Tìm theo mã đơn (AV#...), khách sạn, khách...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      widget.onSearchSubmitted('');
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ─── 3. BỘ LỌC THỜI GIAN & HÓA ĐƠN VAT ────────────────────────
          Row(
            children: [
              // Dropdown thời gian
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: widget.timeRange,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('Tất cả thời gian'),
                        ),
                        const DropdownMenuItem(
                          value: 'last_30_days',
                          child: Text('30 ngày qua'),
                        ),
                        const DropdownMenuItem(
                          value: 'last_90_days',
                          child: Text('90 ngày qua'),
                        ),
                        const DropdownMenuItem(
                          value: 'this_month',
                          child: Text('Tháng này'),
                        ),
                        const DropdownMenuItem(
                          value: 'last_month',
                          child: Text('Tháng trước'),
                        ),
                        const DropdownMenuItem(
                          value: 'this_year',
                          child: Text('Năm nay'),
                        ),
                        ...widget.availableYears.map(
                          (yr) => DropdownMenuItem(
                            value: yr.toString(),
                            child: Text('Năm $yr'),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          widget.onTimeRangeChanged(val);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Filter VAT toggle chip
              InkWell(
                onTap: widget.onToggleVatOnly,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: widget.requireVatOnly
                        ? const Color(0xFFEFF6FF)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.requireVatOnly
                          ? const Color(0xFF003580)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.requireVatOnly
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 16,
                        color: widget.requireVatOnly
                            ? const Color(0xFF003580)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Có hóa đơn VAT',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: widget.requireVatOnly
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: widget.requireVatOnly
                              ? const Color(0xFF003580)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Nút Tab Pill dạng viên nang có kèm badge số lượng
class _TabPill extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.count,
    required this.isActive,
    this.badgeColor,
    this.badgeTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF003580) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF003580) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : (badgeColor ?? const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? Colors.white
                      : (badgeTextColor ?? const Color(0xFF334155)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
