import 'package:flutter/material.dart';
import 'package:avora_mobile/features/hotels/data/models/hotel_filter_params.dart';

/// Thanh tìm kiếm thu gọn đặt ở đầu màn hình HotelSearchScreen.
class HotelSearchHeaderWidget extends StatefulWidget {
  final HotelSearchParams params;
  final ValueChanged<HotelSearchParams> onSearch;
  final VoidCallback? onBack;

  const HotelSearchHeaderWidget({
    super.key,
    required this.params,
    required this.onSearch,
    this.onBack,
  });

  @override
  State<HotelSearchHeaderWidget> createState() =>
      _HotelSearchHeaderWidgetState();
}

class _HotelSearchHeaderWidgetState extends State<HotelSearchHeaderWidget> {
  late TextEditingController _destinationController;
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _adults;
  late int _children;
  late int _rooms;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _destinationController =
        TextEditingController(text: widget.params.destination);
    _checkIn = widget.params.checkIn ?? DateTime.now();
    _checkOut =
        widget.params.checkOut ?? DateTime.now().add(const Duration(days: 2));
    _adults = widget.params.adults;
    _children = widget.params.children;
    _rooms = widget.params.rooms;
  }

  @override
  void didUpdateWidget(covariant HotelSearchHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.params.destination != oldWidget.params.destination &&
        _destinationController.text != widget.params.destination) {
      _destinationController.text = widget.params.destination;
    }
    if (widget.params.checkIn != null) _checkIn = widget.params.checkIn!;
    if (widget.params.checkOut != null) _checkOut = widget.params.checkOut!;
    _adults = widget.params.adults;
    _children = widget.params.children;
    _rooms = widget.params.rooms;
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final updated = widget.params.copyWith(
      destination: _destinationController.text.trim(),
      checkIn: _checkIn,
      checkOut: _checkOut,
      adults: _adults,
      children: _children,
      rooms: _rooms,
    );
    setState(() => _isExpanded = false);
    widget.onSearch(updated);
  }

  String _formatShortDateVN(DateTime d) {
    const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final weekday = days[d.weekday % 7];
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$weekday, $day TH$month';
  }

  @override
  Widget build(BuildContext context) {
    final datesStr =
        '${_formatShortDateVN(_checkIn)} – ${_formatShortDateVN(_checkOut)}';
    final nights = _checkOut.difference(_checkIn).inDays;
    final guestsStr =
        '$_adults người lớn · $_children trẻ em · $_rooms phòng';

    return Container(
      color: const Color(0xFF003580),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              // ─── Compact Top Bar ──────────────────────────────────────────
              Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: widget.onBack,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (widget.onBack != null) const SizedBox(width: 12),

                  // Search Summary Pill (Tap to toggle expand)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFFFC107),
                            width: 2.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search,
                                color: Color(0xFF003580), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _destinationController.text.isEmpty
                                        ? 'Nhập thành phố hoặc tên khách sạn...'
                                        : _destinationController.text,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$datesStr ($nights đêm) • $guestsStr',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFF003580),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ─── Expanded Search Form ────────────────────────────────────
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field 1: Destination
                      const Text(
                        'BẠN MUỐN ĐẾN ĐÂU?',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _destinationController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on_outlined,
                              color: Color(0xFF003580)),
                          hintText: 'Nhập thành phố hoặc tên khách sạn...',
                          isDense: true,
                          suffixIcon: _destinationController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _destinationController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),

                      // Field 2: Dates Picker
                      const Text(
                        'NGÀY NHẬN PHÒNG – NGÀY TRẢ PHÒNG',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _pickDates,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  color: Color(0xFF003580), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  datesStr,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF003580),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$nights đêm',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Field 3: Guests & Rooms Picker
                      const Text(
                        'SỐ NGƯỜI VÀ PHÒNG',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: _pickGuestsAndRooms,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people_outline,
                                  color: Color(0xFF003580), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  guestsStr,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 14, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _submitSearch,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Tìm kiếm',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _checkIn, end: _checkOut),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF003580),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _checkIn = picked.start;
        _checkOut = picked.end;
      });
    }
  }

  void _pickGuestsAndRooms() {
    int tempAdults = _adults;
    int tempChildren = _children;
    int tempRooms = _rooms;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Số lượng khách và phòng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tối đa 5 người/phòng (bao gồm cả giường phụ).',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),

                  _counterRow(
                    title: 'Người lớn',
                    subtitle: 'Từ 18 tuổi trở lên',
                    value: tempAdults,
                    minValue: 1,
                    onChanged: (val) {
                      setModalState(() {
                        tempAdults = val;
                        final minRooms =
                            ((tempAdults + tempChildren) / 5).ceil();
                        if (tempRooms < minRooms) tempRooms = minRooms;
                      });
                    },
                  ),
                  const Divider(),

                  _counterRow(
                    title: 'Trẻ em',
                    subtitle: '0 – 17 tuổi',
                    value: tempChildren,
                    minValue: 0,
                    onChanged: (val) {
                      setModalState(() {
                        tempChildren = val;
                        final minRooms =
                            ((tempAdults + tempChildren) / 5).ceil();
                        if (tempRooms < minRooms) tempRooms = minRooms;
                      });
                    },
                  ),
                  const Divider(),

                  _counterRow(
                    title: 'Số phòng',
                    subtitle: 'Tối thiểu 1 phòng',
                    value: tempRooms,
                    minValue: ((tempAdults + tempChildren) / 5).ceil(),
                    onChanged: (val) {
                      setModalState(() => tempRooms = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003580),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _adults = tempAdults;
                          _children = tempChildren;
                          _rooms = tempRooms;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Xong',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _counterRow({
    required String title,
    required String subtitle,
    required int value,
    required int minValue,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: value > minValue
                    ? const Color(0xFF003580)
                    : const Color(0xFFCBD5E1),
                onPressed:
                    value > minValue ? () => onChanged(value - 1) : null,
              ),
              Text('$value',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF003580),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
