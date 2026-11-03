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

  /// Chuẩn hóa số điện thoại đồng bộ với normalizeGuestPhone của backend:
  /// - Nếu số quốc tế bắt đầu bằng '+' (không phải +84): giữ '+' và các chữ số
  /// - Nếu là số Việt Nam (bắt đầu bằng 84, 0084, hoặc số nội địa): chuẩn hóa thành 0xxxxxxxxx
  String _normalizePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('+') && !trimmed.startsWith('+84')) {
      final cleanIntl =
          '+${trimmed.substring(1).replaceAll(RegExp(r'\D'), '')}';
      return cleanIntl;
    }
    var digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('84')) digits = digits.substring(2);
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    return digits.isNotEmpty ? '0$digits' : '';
  }

  bool _isValidPhone(String raw) {
    final trimmed = raw.trim();
    if (!RegExp(r'^\+?[\d\s\-().]+$').hasMatch(trimmed)) return false;
    final normalized = _normalizePhone(trimmed);
    return RegExp(r'^0\d{9,10}$').hasMatch(normalized) ||
        RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(normalized);
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
                      'Cập nhật thông tin nhận phòng',
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
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: 'VD: Nguyễn Văn A',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    counterText: '',
                  ),
                  validator: (value) {
                    final trimmed = (value ?? '').trim();
                    if (trimmed.isEmpty) {
                      return 'Họ và tên người nhận phòng không được để trống.';
                    }
                    if (trimmed.length > 100) {
                      return 'Họ và tên người nhận phòng tối đa 100 ký tự.';
                    }
                    // Đồng bộ với GUEST_NAME_REGEX của backend và Web:
                    // Chỉ cho phép chữ cái (hỗ trợ có dấu), khoảng trắng, dấu nháy đơn, gạch nối hoặc dấu chấm.
                    final guestNameRegex = RegExp(
                      r"^\p{L}[\p{L}\p{M}]*(?:(?:\p{Zs}+|['\u2019.-])\p{L}[\p{L}\p{M}]*)*$",
                      unicode: true,
                    );
                    if (!guestNameRegex.hasMatch(trimmed)) {
                      return 'Họ và tên chỉ dùng chữ cái, khoảng trắng, dấu nháy đơn, gạch nối hoặc dấu chấm.';
                    }
                    final letterMatches =
                        RegExp(r'\p{L}', unicode: true).allMatches(trimmed);
                    if (letterMatches.length < 2) {
                      return 'Họ và tên người nhận phòng phải có ít nhất 2 chữ cái.';
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
                    hintText: 'VD: 0912345678 hoặc +84912345678',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                  validator: (value) {
                    final raw = (value ?? '').trim();
                    if (raw.isEmpty) {
                      return 'Số điện thoại liên hệ không được để trống.';
                    }
                    if (!_isValidPhone(raw)) {
                      return 'Số điện thoại không hợp lệ (hỗ trợ số VN 10-11 số hoặc số quốc tế chuẩn +... từ 8-15 số).';
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
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Giường đôi, tầng cao, nhận phòng muộn sau 18:00...',
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
