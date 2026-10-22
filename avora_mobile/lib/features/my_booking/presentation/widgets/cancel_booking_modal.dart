import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/booking_item_model.dart';

/// Modal xác nhận hủy đơn đặt phòng kèm tính toán tiền hoàn và chính sách
class CancelBookingModal extends StatefulWidget {
  final BookingItemModel booking;
  final Future<bool> Function({required String reason}) onConfirmCancel;

  const CancelBookingModal({
    super.key,
    required this.booking,
    required this.onConfirmCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required BookingItemModel booking,
    required Future<bool> Function({required String reason}) onConfirmCancel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelBookingModal(
        booking: booking,
        onConfirmCancel: onConfirmCancel,
      ),
    );
  }

  @override
  State<CancelBookingModal> createState() => _CancelBookingModalState();
}

class _CancelBookingModalState extends State<CancelBookingModal> {
  final List<String> _reasons = [
    'Khách thay đổi kế hoạch chuyến đi',
    'Tìm thấy giá tốt hơn ở nơi khác',
    'Lý do sức khỏe hoặc việc đột xuất',
    'Đặt nhầm ngày hoặc thông tin phòng',
    'Khác (nhập lý do cụ thể)',
  ];

  late String _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedReason = _reasons.first;
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final finalReason = _selectedReason == 'Khác (nhập lý do cụ thể)'
        ? _customReasonController.text.trim()
        : _selectedReason;

    if (finalReason.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng cung cấp lý do hủy phòng.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await widget.onConfirmCancel(reason: finalReason);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Không thể hủy đơn đặt phòng. Vui lòng thử lại sau.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###', 'vi_VN');
    final cancellation = widget.booking.cancellation;
    final isFreeCancel = cancellation.isFreeCancel;

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
                    'Xác nhận hủy đặt phòng',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
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

              // ─── Hộp Chính Sách Hủy & Tiền Hoàn ────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isFreeCancel
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFreeCancel
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isFreeCancel
                              ? Icons.check_circle_outline_rounded
                              : Icons.warning_amber_rounded,
                          color: isFreeCancel
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFB45309),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isFreeCancel
                              ? 'Được hủy miễn phí 100%'
                              : 'Áp dụng phí phạt theo chính sách',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isFreeCancel
                                ? const Color(0xFF15803D)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cancellation.policyNote.isNotEmpty
                          ? cancellation.policyNote
                          : 'Hạn hủy: ${cancellation.deadlineText}. Phí phạt: ${cancellation.penaltyRate}%.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ước tính tiền hoàn lại:',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${currency.format(cancellation.estimatedRefundAmount)} ₫ (${cancellation.refundPercentage}%)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isFreeCancel
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── Chọn lý do hủy ────────────────────────────────────────
              const Text(
                'Lý do hủy phòng *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                    items: _reasons
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedReason = val);
                      }
                    },
                  ),
                ),
              ),

              if (_selectedReason == 'Khác (nhập lý do cụ thể)') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customReasonController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Nhập chi tiết lý do muốn hủy phòng...',
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ─── Nút Xác nhận ──────────────────────────────────────────
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
                      child: const Text('Giữ lại phòng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _handleConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
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
                          : const Text('Xác nhận hủy phòng'),
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
