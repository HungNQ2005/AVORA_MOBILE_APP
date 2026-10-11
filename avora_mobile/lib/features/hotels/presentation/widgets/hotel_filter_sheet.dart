import 'package:flutter/material.dart';
import 'package:avora_mobile/features/hotels/data/models/hotel_filter_params.dart';

/// Modal BottomSheet chứa toàn bộ tiêu chí lọc khách sạn theo chuẩn AVORA Web.
class HotelFilterBottomSheet extends StatefulWidget {
  final HotelSearchParams initialParams;
  final FilterStats filterStats;
  final int totalCount;
  final Function({
    required String priceRangeKey,
    required List<int> starRatings,
    required num? minScore,
    required List<String> facilities,
    required String capacityFilter,
    required bool onlyAvailable,
  }) onApplyFilters;
  final VoidCallback onResetFilters;

  const HotelFilterBottomSheet({
    super.key,
    required this.initialParams,
    required this.filterStats,
    required this.totalCount,
    required this.onApplyFilters,
    required this.onResetFilters,
  });

  static Future<void> show(
    BuildContext context, {
    required HotelSearchParams initialParams,
    required FilterStats filterStats,
    required int totalCount,
    required Function({
      required String priceRangeKey,
      required List<int> starRatings,
      required num? minScore,
      required List<String> facilities,
      required String capacityFilter,
      required bool onlyAvailable,
    }) onApplyFilters,
    required VoidCallback onResetFilters,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.9,
        child: HotelFilterBottomSheet(
          initialParams: initialParams,
          filterStats: filterStats,
          totalCount: totalCount,
          onApplyFilters: onApplyFilters,
          onResetFilters: onResetFilters,
        ),
      ),
    );
  }

  @override
  State<HotelFilterBottomSheet> createState() => _HotelFilterBottomSheetState();
}

class _HotelFilterBottomSheetState extends State<HotelFilterBottomSheet> {
  late String _priceRangeKey;
  late List<int> _starRatings;
  late num? _minScore;
  late List<String> _facilities;
  late String _capacityFilter;
  late bool _onlyAvailable;

  @override
  void initState() {
    super.initState();
    _priceRangeKey = widget.initialParams.priceRangeKey;
    _starRatings = List<int>.from(widget.initialParams.starRatings);
    _minScore = widget.initialParams.minScore;
    _facilities = List<String>.from(widget.initialParams.facilities);
    _capacityFilter = widget.initialParams.capacityFilter;
    _onlyAvailable = widget.initialParams.onlyAvailable;
  }

  void _resetLocalFilters() {
    setState(() {
      _priceRangeKey = 'all';
      _starRatings = [];
      _minScore = null;
      _facilities = [];
      _capacityFilter = 'all';
      _onlyAvailable = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.filterStats;

    return Column(
      children: [
        // ─── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFF003580), size: 22),
              const SizedBox(width: 8),
              const Text(
                'Bộ lọc tìm kiếm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _resetLocalFilters,
                child: const Text(
                  'Đặt lại',
                  style: TextStyle(
                    color: Color(0xFFD93025),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // ─── Filter Content Body (Scrollable) ────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // 1. Tình trạng phòng trống
              _buildSectionHeader('TÌNH TRẠNG PHÒNG'),
              SwitchListTile(
                value: _onlyAvailable,
                onChanged: (val) => setState(() => _onlyAvailable = val),
                title: const Text(
                  'Chỉ hiển thị chỗ nghỉ còn phòng',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Ẩn các khách sạn đã hết phòng cho ngày bạn chọn',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                activeThumbColor: const Color(0xFF003580),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),

              // 2. Sức chứa & Loại giường
              _buildSectionHeader('SỨC CHỨA & LOẠI GIƯỜNG'),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Color(0xFF0284C7), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '2 giường tiêu chuẩn = 4 người • Giường phụ = +1 người (Tối đa 5 người/phòng)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0369A1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildRadioItem<String>(
                title: 'Tất cả loại phòng',
                value: 'all',
                groupValue: _capacityFilter,
                count: stats.capacityAllCount,
                onChanged: (v) => setState(() => _capacityFilter = v!),
              ),
              _buildRadioItem<String>(
                title: '2 giường tiêu chuẩn (4-5 người)',
                value: 'standard_two_beds',
                groupValue: _capacityFilter,
                count: stats.capacityStandardTwoBedsCount,
                onChanged: (v) => setState(() => _capacityFilter = v!),
              ),
              _buildRadioItem<String>(
                title: '1 giường đôi (2-3 người)',
                value: 'standard_double',
                groupValue: _capacityFilter,
                count: stats.capacityStandardDoubleCount,
                onChanged: (v) => setState(() => _capacityFilter = v!),
              ),
              _buildRadioItem<String>(
                title: 'Có hỗ trợ giường phụ (Tối đa 5 người)',
                value: 'with_extra_bed',
                groupValue: _capacityFilter,
                count: stats.capacityWithExtraBedCount,
                onChanged: (v) => setState(() => _capacityFilter = v!),
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),

              // 3. Ngân sách mỗi đêm
              _buildSectionHeader('NGÂN SÁCH MỖI ĐÊM'),
              _buildRadioItem<String>(
                title: 'Tất cả mức giá',
                value: 'all',
                groupValue: _priceRangeKey,
                count: stats.totalCount,
                onChanged: (v) => setState(() => _priceRangeKey = v!),
              ),
              _buildRadioItem<String>(
                title: 'Dưới 1.200.000 VND',
                value: '0-1.2m',
                groupValue: _priceRangeKey,
                count: stats.under1m2Count,
                onChanged: (v) => setState(() => _priceRangeKey = v!),
              ),
              _buildRadioItem<String>(
                title: '1.200.000 VND – 2.500.000 VND',
                value: '1.2m-2.5m',
                groupValue: _priceRangeKey,
                count: stats.from1m2To2m5Count,
                onChanged: (v) => setState(() => _priceRangeKey = v!),
              ),
              _buildRadioItem<String>(
                title: '2.500.000 VND – 5.000.000 VND',
                value: '2.5m-5m',
                groupValue: _priceRangeKey,
                count: stats.from2m5To5mCount,
                onChanged: (v) => setState(() => _priceRangeKey = v!),
              ),
              _buildRadioItem<String>(
                title: '5.000.000 VND trở lên',
                value: 'above-5m',
                groupValue: _priceRangeKey,
                count: stats.above5mCount,
                onChanged: (v) => setState(() => _priceRangeKey = v!),
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),

              // 4. Xếp hạng sao
              _buildSectionHeader('XẾP HẠNG SAO'),
              _buildCheckboxItem(
                title: '5 sao',
                icon: _buildStarsIcon(5),
                checked: _starRatings.contains(5),
                count: stats.star5Count,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _starRatings.add(5);
                    } else {
                      _starRatings.remove(5);
                    }
                  });
                },
              ),
              _buildCheckboxItem(
                title: '4 sao',
                icon: _buildStarsIcon(4),
                checked: _starRatings.contains(4),
                count: stats.star4Count,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _starRatings.add(4);
                    } else {
                      _starRatings.remove(4);
                    }
                  });
                },
              ),
              _buildCheckboxItem(
                title: '3 sao',
                icon: _buildStarsIcon(3),
                checked: _starRatings.contains(3),
                count: stats.star3Count,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _starRatings.add(3);
                    } else {
                      _starRatings.remove(3);
                    }
                  });
                },
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),

              // 5. Điểm đánh giá của khách
              _buildSectionHeader('ĐIỂM ĐÁNH GIÁ CỦA KHÁCH'),
              _buildRadioItem<num?>(
                title: 'Tuyệt hảo: 9 điểm trở lên',
                value: 9,
                groupValue: _minScore,
                count: stats.rating9Count,
                onChanged: (v) => setState(() => _minScore = _minScore == 9 ? null : 9),
              ),
              _buildRadioItem<num?>(
                title: 'Rất tốt: 8 điểm trở lên',
                value: 8,
                groupValue: _minScore,
                count: stats.rating8Count,
                onChanged: (v) => setState(() => _minScore = _minScore == 8 ? null : 8),
              ),
              _buildRadioItem<num?>(
                title: 'Tốt: 7 điểm trở lên',
                value: 7,
                groupValue: _minScore,
                count: stats.rating7Count,
                onChanged: (v) => setState(() => _minScore = _minScore == 7 ? null : 7),
              ),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),

              // 6. Tiện nghi được ưa chuộng
              _buildSectionHeader('TIỆN NGHI ĐƯỢC ƯA CHUỘNG'),
              _buildCheckboxItem(
                title: 'Bãi biển riêng / Sát biển',
                checked: _facilities.contains('beach'),
                count: stats.beachCount,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _facilities.add('beach');
                    } else {
                      _facilities.remove('beach');
                    }
                  });
                },
              ),
              _buildCheckboxItem(
                title: 'Hồ bơi vô cực',
                checked: _facilities.contains('pool'),
                count: stats.poolCount,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _facilities.add('pool');
                    } else {
                      _facilities.remove('pool');
                    }
                  });
                },
              ),
              _buildCheckboxItem(
                title: 'Bao bữa sáng tự chọn',
                checked: _facilities.contains('breakfast'),
                count: stats.breakfastCount,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _facilities.add('breakfast');
                    } else {
                      _facilities.remove('breakfast');
                    }
                  });
                },
              ),
              _buildCheckboxItem(
                title: 'Miễn phí hủy phòng',
                checked: _facilities.contains('freeCancel'),
                count: stats.freeCancelCount,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _facilities.add('freeCancel');
                    } else {
                      _facilities.remove('freeCancel');
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),

        // ─── Footer Action Bar ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003580),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApplyFilters(
                    priceRangeKey: _priceRangeKey,
                    starRatings: _starRatings,
                    minScore: _minScore,
                    facilities: _facilities,
                    capacityFilter: _capacityFilter,
                    onlyAvailable: _onlyAvailable,
                  );
                },
                child: const Text(
                  'Áp dụng bộ lọc',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStarsIcon(int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (_) => const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
      ),
    );
  }

  Widget _buildRadioItem<T>({
    required String title,
    required T value,
    required T groupValue,
    required int count,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // ignore: deprecated_member_use
            Radio<T>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: groupValue,
              // ignore: deprecated_member_use
              onChanged: onChanged,
              activeColor: const Color(0xFF003580),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF003580)
                      : const Color(0xFF1E293B),
                ),
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxItem({
    required String title,
    Widget? icon,
    required bool checked,
    required int count,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: checked,
              onChanged: onChanged,
              activeColor: const Color(0xFF003580),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: checked ? FontWeight.w600 : FontWeight.normal,
                      color: checked
                          ? const Color(0xFF003580)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 6),
                    icon,
                  ],
                ],
              ),
            ),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
