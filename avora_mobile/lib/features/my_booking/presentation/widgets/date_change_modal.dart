import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/booking_item_model.dart';

/// Modal đổi ngày lưu trú cho đơn đặt phòng
class DateChangeModal extends StatefulWidget {
  final BookingItemModel booking;
  final Future<bool> Function({
    required String checkInDate,
    required String checkOutDate,
  }) onConfirmDateChange;

  const DateChangeModal({
    super.key,
    required this.booking,
    required this.onConfirmDateChange,
  });

  static Future<bool?> show(
    BuildContext context, {
    required BookingItemModel booking,
    required Future<bool> Function({
      required String checkInDate,
      required String checkOutDate,
    }) onConfirmDateChange,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DateChangeModal(
        booking: booking,
        onConfirmDateChange: onConfirmDateChange,
      ),
    );
  }

  @override
  State<DateChangeModal> createState() => _DateChangeModalState();
}

class _DateChangeModalState extends State<DateChangeModal> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    try {
      _checkIn = DateTime.parse(widget.booking.stay.checkInDate);
      if (_checkIn.isBefore(now)) {
        _checkIn = DateTime(now.year, now.month, now.day + 1);
      }
    } catch (_) {
      _checkIn = DateTime(now.year, now.month, now.day + 1);
    }

    try {
      _checkOut = DateTime.parse(widget.booking.stay.checkOutDate);
      if (!_checkOut.isAfter(_checkIn)) {
        _checkOut = _checkIn.add(const Duration(days: 1));
      }
    } catch (_) {
      _checkOut = _checkIn.add(const Duration(days: 1));
    }
  }

  int get _nights => _checkOut.difference(_checkIn).inDays;

  Future<void> _pickCheckInDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _checkIn.isBefore(today) ? today : _checkIn,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'CHỌN NGÀY NHẬN PHÒNG',
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
    );

    if (picked != null) {
      setState(() {
        _checkIn = picked;
        if (!_checkOut.isAfter(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _pickCheckOutDate() async {
    final firstAllowed = _checkIn.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate:
          _checkOut.isAfter(_checkIn) ? _checkOut : firstAllowed,
      firstDate: firstAllowed,
      lastDate: _checkIn.add(const Duration(days: 365)),
      helpText: 'CHỌN NGÀY TRẢ PHÒNG',
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
    );

    if (picked != null) {
      setState(() {
        _checkOut = picked;
      });
    }
  }

  Future<void> _handleConfirm() async {
    if (!_checkOut.isAfter(_checkIn)) {
      setState(() {
        _errorMessage = 'Ngày trả phòng phải sau ngày nhận phòng ít nhất 1 đêm.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final format = DateFormat('yyyy-MM-dd');
    final success = await widget.onConfirmDateChange(
      checkInDate: format.format(_checkIn),
      checkOutDate: format.format(_checkOut),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'Không thể đổi ngày lưu trú. Có thể phòng đã hết trong khoảng ngày bạn chọn.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Đổi ngày lưu trú',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                'Mã đơn: ${widget.booking.bookingCode} • ${widget.booking.hotel.name}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Chọn ngày Nhận và Trả phòng
              Row(
                children: [
                  Expanded(
                    child: _DateSelectorTile(
                      label: 'NGÀY NHẬN PHÒNG',
                      dateText: dateFormat.format(_checkIn),
                      onTap: _pickCheckInDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateSelectorTile(
                      label: 'NGÀY TRẢ PHÒNG',
                      dateText: dateFormat.format(_checkOut),
                      onTap: _pickCheckOutDate,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Thống kê số đêm mới
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thời gian lưu trú mới:',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      '$_nights đêm',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Lưu ý
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'Lưu ý: Việc đổi ngày phụ thuộc vào số lượng phòng còn trống tại khách sạn và có thể có sự chênh lệch giá theo ngày trong tuần hoặc mùa cao điểm.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Nút bấm
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Hủy bỏ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _handleConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF003580),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Xác nhận đổi ngày'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateSelectorTile extends StatelessWidget {
  final String label;
  final String dateText;
  final VoidCallback onTap;

  const _DateSelectorTile({
    required this.label,
    required this.dateText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: Color(0xFF003580),
                ),
                const SizedBox(width: 6),
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
