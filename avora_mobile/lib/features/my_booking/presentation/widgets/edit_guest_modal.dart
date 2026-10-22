import 'package:flutter/material.dart';
import '../../data/models/booking_item_model.dart';

/// Modal cập nhật thông tin khách lưu trú đại diện
/// Bao quát toàn diện các biên validation dựa trên nghiệp vụ hệ thống AVORA
class EditGuestModal extends StatefulWidget {
  final BookingItemModel booking;
  final Future<bool> Function({
    required String guestName,
    required String guestPhone,
    String? specialRequest,
  }) onSave;

  const EditGuestModal({
    super.key,
    required this.booking,
    required this.onSave,
  });

  static Future<bool?> show(
    BuildContext context, {
    required BookingItemModel booking,
    required Future<bool> Function({
      required String guestName,
      required String guestPhone,
      String? specialRequest,
    }) onSave,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditGuestModal(
        booking: booking,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditGuestModal> createState() => _EditGuestModalState();
}

class _EditGuestModalState extends State<EditGuestModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _requestController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.booking.guestName);
    _phoneController = TextEditingController(text: widget.booking.guestPhone);
    _requestController =
        TextEditingController(text: widget.booking.specialRequest);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _requestController.dispose();
    super.dispose();
  }

  /// Chuẩn hóa số điện thoại: bỏ khoảng trắng, dấu gạch ngang, tiền tố +84 / 84
  String _normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('84') && digits.length > 9) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) {
      return digits;
    }
    return digits.isNotEmpty ? '0$digits' : digits;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final normalizedPhone = _normalizePhone(_phoneController.text.trim());

    final success = await widget.onSave(
      guestName: _nameController.text.trim(),
      guestPhone: normalizedPhone,
      specialRequest: _requestController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Không thể cập nhật thông tin khách. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Form(
            key: _formKey,
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

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cập nhật thông tin khách',
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
                  'Đơn đặt phòng: ${widget.booking.bookingCode}',
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

                // ─── Input Họ và tên ─────────────────────────────────────
                const Text(
                  'Họ và tên khách đại diện *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'VD: Nguyễn Văn A',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (value) {
                    final trimmed = (value ?? '').trim();
                    if (trimmed.isEmpty) {
                      return 'Vui lòng nhập họ và tên khách đại diện.';
                    }
                    if (trimmed.length < 2) {
                      return 'Họ và tên phải có ít nhất 2 ký tự.';
                    }
                    if (trimmed.length > 80) {
                      return 'Họ và tên không được vượt quá 80 ký tự.';
                    }
                    if (RegExp(r'[0-9]').hasMatch(trimmed)) {
                      return 'Họ và tên không được chứa chữ số.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ─── Input Số điện thoại ──────────────────────────────────
                const Text(
                  'Số điện thoại liên hệ *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'VD: 0912345678',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  validator: (value) {
                    final raw = (value ?? '').trim();
                    if (raw.isEmpty) {
                      return 'Vui lòng nhập số điện thoại liên hệ.';
                    }
                    final normalized = _normalizePhone(raw);
                    // Quy chuẩn số điện thoại Việt Nam: 10 chữ số, bắt đầu bằng 03, 05, 07, 08, 09
                    final vnPhoneRegex = RegExp(r'^(03|05|07|08|09)\d{8}$');
                    if (!vnPhoneRegex.hasMatch(normalized)) {
                      return 'Số điện thoại không hợp lệ (cần 10 số, bắt đầu 03, 05, 07, 08, 09).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ─── Input Yêu cầu đặc biệt ──────────────────────────────
                const Text(
                  'Yêu cầu đặc biệt (Không bắt buộc)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _requestController,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    hintText: 'VD: Phòng tầng cao, 1 giường lớn, nhận phòng trễ...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),

                // ─── Nút Lưu & Hủy ──────────────────────────────────────
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
                        onPressed: _isSubmitting ? null : _handleSubmit,
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
                            : const Text('Lưu thông tin'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
