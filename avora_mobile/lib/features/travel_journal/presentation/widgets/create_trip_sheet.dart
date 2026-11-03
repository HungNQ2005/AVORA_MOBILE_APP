import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:avora_mobile/core/theme/app_theme.dart';
import 'package:avora_mobile/features/my_booking/data/models/booking_item_model.dart';
import 'package:avora_mobile/features/travel_journal/data/models/travel_journal_entry_model.dart';

class CreateTripSheet extends StatefulWidget {
  final List<BookingItemModel> availableBookings;
  final Future<bool> Function({
    required String title,
    required String placeName,
    required String cityName,
    String? address,
    required String startDate,
    required String endDate,
    int nights,
    num totalAmount,
    String note,
    String mood,
    int? ratingScore,
    List<String> highlights,
    String? linkedBookingId,
  }) onSave;

  const CreateTripSheet({
    super.key,
    required this.availableBookings,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required List<BookingItemModel> availableBookings,
    required Future<bool> Function({
      required String title,
      required String placeName,
      required String cityName,
      String? address,
      required String startDate,
      required String endDate,
      int nights,
      num totalAmount,
      String note,
      String mood,
      int? ratingScore,
      List<String> highlights,
      String? linkedBookingId,
    }) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: CreateTripSheet(
          availableBookings: availableBookings,
          onSave: onSave,
        ),
      ),
    );
  }

  @override
  State<CreateTripSheet> createState() => _CreateTripSheetState();
}

class _CreateTripSheetState extends State<CreateTripSheet> {
  final _titleController = TextEditingController();
  final _cityNameController = TextEditingController();
  final _placeNameController = TextEditingController();
  final _noteController = TextEditingController();
  final _costController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  String _selectedMood = 'relaxing';
  int _ratingScore = 9;
  final List<String> _selectedHighlights = [];
  String? _linkedBookingId;
  bool _isSaving = false;

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  final List<Map<String, String>> _moods = [
    {'id': 'relaxing', 'label': 'Thư giãn', 'emoji': '🌴'},
    {'id': 'adventure', 'label': 'Khám phá', 'emoji': '🎒'},
    {'id': 'romantic', 'label': 'Lãng mạn', 'emoji': '💖'},
    {'id': 'family', 'label': 'Gia đình', 'emoji': '👨‍👩‍👧‍👦'},
    {'id': 'business', 'label': 'Công tác', 'emoji': '💼'},
  ];

  final List<String> _commonHighlights = [
    'Khung cảnh tuyệt đẹp',
    'Ẩm thực ngon nức tiếng',
    'Con người thân thiện',
    'Không khí trong lành',
    'Trải nghiệm mới lạ',
    'Chụp nhiều ảnh đẹp',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _cityNameController.dispose();
    _placeNameController.dispose();
    _noteController.dispose();
    _costController.dispose();
    super.dispose();
  }

  int get _nights {
    final diff = _endDate.difference(_startDate).inDays;
    return diff > 0 ? diff : 1;
  }

  void _fillFromBooking(BookingItemModel booking) {
    setState(() {
      _linkedBookingId = booking.bookingId;
      _titleController.text = 'Kỳ nghỉ ${booking.hotel.name}';
      _placeNameController.text = booking.hotel.name;
      final addr = booking.hotel.address;
      _cityNameController.text = addr.split(',').last.trim();
      _costController.text = booking.totalAmount.toString();

      final inDate = DateTime.tryParse(booking.stay.checkInDate);
      final outDate = DateTime.tryParse(booking.stay.checkOutDate);
      if (inDate != null) _startDate = inDate;
      if (outDate != null) _endDate = outDate;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã liên kết với đơn đặt chỗ: ${booking.hotel.name}'),
        backgroundColor: AvoraTheme.primaryNavy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showBookingPicker() {
    if (widget.availableBookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn chưa có đơn đặt phòng nào trên hệ thống Avora.'),
          backgroundColor: Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn đơn đặt chỗ Avora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: widget.availableBookings.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final b = widget.availableBookings[i];
              return ListTile(
                title: Text(b.hotel.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text('${b.stay.checkInDate} → ${b.stay.checkOutDate}', style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _fillFromBooking(b);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final city = _cityNameController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên hành trình chuyến đi.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập điểm đến (Thành phố/Tỉnh).'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final totalCost = num.tryParse(_costController.text.trim()) ?? 0;

    final success = await widget.onSave(
      title: title,
      placeName: _placeNameController.text.trim().isNotEmpty
          ? _placeNameController.text.trim()
          : city,
      cityName: city,
      startDate: _dateFormat.format(_startDate),
      endDate: _dateFormat.format(_endDate),
      nights: _nights,
      totalAmount: totalCost,
      note: _noteController.text.trim(),
      mood: _selectedMood,
      ratingScore: _ratingScore,
      highlights: _selectedHighlights,
      linkedBookingId: _linkedBookingId,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm chuyến đi vào Nhật ký thành công! ✨'),
          backgroundColor: Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_location_alt_rounded,
                    color: AvoraTheme.primaryNavy,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thêm chuyến đi mới',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Ghi dấu hành trình & lưu giữ kỷ niệm',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Body Form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                // Quick Link to Avora Booking
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFF1D4ED8), size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Đã đặt phòng trên Avora? Chọn đơn để tự động điền.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                        ),
                      ),
                      TextButton(
                        onPressed: _showBookingPicker,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1D4ED8),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Chọn đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Trip Title
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Tên chuyến đi *',
                    hintText: 'Vd: Phượt Đà Lạt ngắm mai anh đào',
                    prefixIcon: const Icon(Icons.edit_road_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // City and Place row
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _cityNameController,
                        decoration: InputDecoration(
                          labelText: 'Điểm đến (Tỉnh/TP) *',
                          hintText: 'Vd: Đà Lạt',
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _placeNameController,
                        decoration: InputDecoration(
                          labelText: 'Nơi lưu trú',
                          hintText: 'Khách sạn/Homestay',
                          prefixIcon: const Icon(Icons.hotel_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Date pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked;
                              if (_endDate.isBefore(_startDate)) {
                                _endDate = _startDate.add(const Duration(days: 1));
                              }
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Ngày bắt đầu',
                            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_dateFormat.format(_startDate), style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: _startDate,
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Ngày kết thúc',
                            prefixIcon: const Icon(Icons.event_available_outlined, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_dateFormat.format(_endDate), style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Cost (optional)
                TextField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Tổng chi phí ước tính (VND - Tùy chọn)',
                    hintText: 'Vd: 3500000',
                    prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 18),

                // Mood Choice
                const Text(
                  'Cảm xúc hành trình',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _moods.map((m) {
                      final isSelected = _selectedMood == m['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Text(m['emoji'] ?? ''),
                          label: Text(m['label'] ?? ''),
                          selected: isSelected,
                          selectedColor: const Color(0xFF003580).withOpacity(0.12),
                          backgroundColor: const Color(0xFFF8FAFC),
                          side: BorderSide(
                            color: isSelected ? AvoraTheme.primaryNavy : const Color(0xFFE2E8F0),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected ? AvoraTheme.primaryNavy : const Color(0xFF334155),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedMood = m['id']!);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Rating (1 - 10)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đánh giá chuyến đi (1 - 10)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AvoraTheme.primaryNavy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$_ratingScore/10',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _ratingScore.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_ratingScore',
                  activeColor: AvoraTheme.primaryNavy,
                  onChanged: (val) => setState(() => _ratingScore = val.round()),
                ),
                const SizedBox(height: 14),

                // Note
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Kỷ niệm & Khoảnh khắc đáng nhớ',
                    hintText: 'Ghi lại các trải nghiệm thú vị, quán ăn ngon hoặc ấn tượng sâu sắc...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Highlights
                const Text(
                  'Thẻ điểm nhấn',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonHighlights.map((tag) {
                    final isChecked = _selectedHighlights.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: isChecked,
                      selectedColor: const Color(0xFF003580).withOpacity(0.1),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide(
                        color: isChecked ? AvoraTheme.primaryNavy : const Color(0xFFE2E8F0),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isChecked ? AvoraTheme.primaryNavy : const Color(0xFF475569),
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedHighlights.add(tag);
                          } else {
                            _selectedHighlights.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AvoraTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Lưu chuyến đi vào Nhật ký',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
