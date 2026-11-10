import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/data/auth_model.dart';
import '../../data/models/bank_model.dart';
import '../../data/models/booking_item_model.dart';
import '../../data/repositories/my_booking_repository.dart';

/// Chuẩn hóa tên chủ tài khoản: chuyển sang in hoa và loại bỏ dấu tiếng Việt
/// Ví dụ: 'Nguyễn Văn An' -> 'NGUYEN VAN AN'
String sanitizeAccountHolder(String input) {
  if (input.isEmpty) return '';
  const withAccents = [
    'à','á','ạ','ả','ã','â','ầ','ấ','ậ','ẩ','ẫ','ă','ằ','ắ','ặ','ẳ','ẵ',
    'è','é','ẹ','ẻ','ẽ','ê','ề','ế','ệ','ể','ễ',
    'ì','í','ị','ỉ','ĩ',
    'ò','ó','ọ','ỏ','õ','ô','ồ','ố','ộ','ổ','ỗ','ơ','ờ','ớ','ợ','ở','ỡ',
    'ù','ú','ụ','ủ','ũ','ư','ừ','ứ','ự','ử','ữ',
    'ỳ','ý','ỵ','ỷ','ỹ',
    'đ',
    'À','Á','Ạ','Ả','Ã','Â','Ầ','Ấ','Ậ','Ẩ','Ẫ','Ă','Ằ','Ắ','Ặ','Ẳ','Ẵ',
    'È','É','Ẹ','Ẻ','Ẽ','Ê','Ề','Ế','Ệ','Ể','Ễ',
    'Ì','Í','Ị','Ỉ','Ĩ',
    'Ò','Ó','Ọ','Ỏ','Õ','Ô','Ồ','Ố','Ộ','Ổ','Ỗ','Ơ','Ờ','Ớ','Ợ','Ở','Ỡ',
    'Ù','Ú','Ụ','Ủ','Ũ','Ư','Ừ','Ứ','Ự','Ử','Ữ',
    'Ỳ','Ý','Ỵ','Ỷ','Ỹ',
    'Đ'
  ];
  const withoutAccents = [
    'a','a','a','a','a','a','a','a','a','a','a','a','a','a','a','a','a',
    'e','e','e','e','e','e','e','e','e','e','e',
    'i','i','i','i','i',
    'o','o','o','o','o','o','o','o','o','o','o','o','o','o','o','o','o',
    'u','u','u','u','u','u','u','u','u','u','u',
    'y','y','y','y','y',
    'd',
    'A','A','A','A','A','A','A','A','A','A','A','A','A','A','A','A','A',
    'E','E','E','E','E','E','E','E','E','E','E',
    'I','I','I','I','I',
    'O','O','O','O','O','O','O','O','O','O','O','O','O','O','O','O','O',
    'U','U','U','U','U','U','U','U','U','U','U',
    'Y','Y','Y','Y','Y',
    'D'
  ];

  String result = input;
  for (int i = 0; i < withAccents.length; i++) {
    result = result.replaceAll(withAccents[i], withoutAccents[i]);
  }
  return result.toUpperCase();
}

const List<String> kCommonCancellationReasons = [
  'Khách thay đổi kế hoạch chuyến đi',
  'Tìm thấy khách sạn / phòng khác phù hợp hơn',
  'Lý do sức khỏe / công việc đột xuất',
  'Giá phòng hoặc chính sách không còn phù hợp',
  'Khác',
];

/// Modal xác nhận hủy đặt phòng & Yêu cầu hoàn tiền (Phân nhánh 2 trường hợp theo bản Website)
/// - Trường hợp 1: Đơn chưa thanh toán HOẶC số tiền hoàn = 0đ
/// - Trường hợp 2: Đơn đã thanh toán VÀ số tiền hoàn > 0đ (bắt buộc nhập thông tin ngân hàng hoàn tiền)
class CancelBookingModal extends ConsumerStatefulWidget {
  final BookingItemModel booking;
  final UserModel? user;
  final List<BankModel>? initialBanks;
  final Future<bool> Function({
    required String reason,
    String? bankCd,
    String? bankName,
    String? bankBin,
    String? accountNumber,
    String? accountHolder,
  }) onConfirmCancel;

  const CancelBookingModal({
    super.key,
    required this.booking,
    this.user,
    this.initialBanks,
    required this.onConfirmCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required BookingItemModel booking,
    UserModel? user,
    List<BankModel>? initialBanks,
    required Future<bool> Function({
      required String reason,
      String? bankCd,
      String? bankName,
      String? bankBin,
      String? accountNumber,
      String? accountHolder,
    }) onConfirmCancel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelBookingModal(
        booking: booking,
        user: user,
        initialBanks: initialBanks,
        onConfirmCancel: onConfirmCancel,
      ),
    );
  }

  @override
  ConsumerState<CancelBookingModal> createState() => _CancelBookingModalState();
}

class _CancelBookingModalState extends ConsumerState<CancelBookingModal> {
  late String _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();

  List<BankModel> _banks = [];
  bool _isLoadingBanks = false;
  BankModel? _selectedBank;

  bool _isSubmitting = false;
  String? _errorMessage;

  String? _reasonError;
  String? _bankError;
  String? _accountNumberError;
  String? _accountHolderError;

  bool get _isPaid {
    final payment = widget.booking.payment;
    final hasPayment = (payment.isPaid || payment.hasPartialPayment) &&
        (payment.totalPaidAmount > 0 || payment.amountPaid > 0);
    return hasPayment;
  }

  num get _estimatedRefundAmount {
    final booking = widget.booking;
    if (booking.statusCodeName == 'PND' && booking.payment.totalPaidAmount > 0) {
      return booking.payment.totalPaidAmount;
    }
    if (booking.cancellation.estimatedRefundAmount > 0) {
      return booking.cancellation.estimatedRefundAmount;
    }
    return _isPaid ? booking.totalAmount : 0;
  }

  bool get _isCase2 => _isPaid && _estimatedRefundAmount > 0;

  @override
  void initState() {
    super.initState();
    _selectedReason = kCommonCancellationReasons.first;

    final initialAccNum = widget.user?.refundAccountNumber ?? '';
    final initialAccHolder = sanitizeAccountHolder(widget.user?.refundAccountHolder ?? '');

    _accountNumberController.text = initialAccNum;
    _accountHolderController.text = initialAccHolder;

    if (_isCase2) {
      if (widget.initialBanks != null && widget.initialBanks!.isNotEmpty) {
        _banks = widget.initialBanks!;
        _resolveDefaultBank();
      } else {
        _fetchBanks();
      }
    }
  }

  void _resolveDefaultBank() {
    final userBankCd = widget.user?.refundBankCd;
    if (userBankCd != null && userBankCd.trim().isNotEmpty && _banks.isNotEmpty) {
      try {
        final found = _banks.firstWhere(
          (b) => b.bankCd == userBankCd || b.codeName == userBankCd,
        );
        _selectedBank = found;
      } catch (_) {
        // Không tìm thấy ngân hàng mặc định
      }
    }
  }

  Future<void> _fetchBanks() async {
    setState(() => _isLoadingBanks = true);
    try {
      final repo = ref.read(myBookingRepositoryProvider);
      final list = await repo.fetchRefundBanks();
      if (!mounted) return;
      setState(() {
        _banks = list;
        _isLoadingBanks = false;
        _resolveDefaultBank();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingBanks = false);
    }
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  void _openBankPicker() {
    showModalBottomSheet<BankModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BankPickerSheet(
        banks: _banks,
        selectedBank: _selectedBank,
      ),
    ).then((picked) {
      if (picked != null) {
        setState(() {
          _selectedBank = picked;
          _bankError = null;
        });
      }
    });
  }

  void _handleAccountNumberChange(String val) {
    final clean = val.replaceAll(RegExp(r'\D'), '');
    if (clean != val) {
      _accountNumberController.value = TextEditingValue(
        text: clean,
        selection: TextSelection.collapsed(offset: clean.length),
      );
    }
    if (_accountNumberError != null) {
      setState(() => _accountNumberError = null);
    }
  }

  void _handleAccountHolderChange(String val) {
    final clean = sanitizeAccountHolder(val);
    if (clean != val) {
      _accountHolderController.value = TextEditingValue(
        text: clean,
        selection: TextSelection.collapsed(offset: clean.length),
      );
    }
    if (_accountHolderError != null) {
      setState(() => _accountHolderError = null);
    }
  }

  Future<void> _handleConfirm() async {
    bool hasError = false;
    String? reasonErr;
    String? bankErr;
    String? accNumErr;
    String? accHolderErr;

    final isCustom = _selectedReason == 'Khác';
    final finalReason = isCustom
        ? _customReasonController.text.trim()
        : _selectedReason;

    if (isCustom && finalReason.isEmpty) {
      reasonErr = 'Vui lòng nhập lý do hủy phòng cụ thể.';
      hasError = true;
    }

    if (_isCase2) {
      if (_selectedBank == null) {
        bankErr = 'Vui lòng chọn ngân hàng nhận tiền hoàn từ danh sách hệ thống.';
        hasError = true;
      }

      final accNum = _accountNumberController.text.trim();
      if (accNum.length < 6 || accNum.length > 25) {
        accNumErr = 'Vui lòng nhập số tài khoản ngân hàng hợp lệ (từ 6 đến 25 chữ số).';
        hasError = true;
      }

      final accHolder = _accountHolderController.text.trim();
      if (accHolder.length < 3) {
        accHolderErr = 'Vui lòng nhập tên chủ tài khoản (viết hoa không dấu).';
        hasError = true;
      }
    }

    if (hasError) {
      setState(() {
        _reasonError = reasonErr;
        _bankError = bankErr;
        _accountNumberError = accNumErr;
        _accountHolderError = accHolderErr;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _reasonError = null;
      _bankError = null;
      _accountNumberError = null;
      _accountHolderError = null;
    });

    final success = await widget.onConfirmCancel(
      reason: finalReason,
      bankCd: _isCase2 ? _selectedBank?.bankCd : null,
      bankName: _isCase2 ? _selectedBank?.fullNameWithShort : null,
      bankBin: _isCase2 ? _selectedBank?.effectiveBin : null,
      accountNumber: _isCase2 ? _accountNumberController.text.trim() : null,
      accountHolder: _isCase2 ? _accountHolderController.text.trim() : null,
    );

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
    final booking = widget.booking;
    final isCase2 = _isCase2;
    final estimatedRefund = _estimatedRefundAmount;
    final refundPct = booking.cancellation.refundPercentage;
    final hasPenalty = refundPct < 100;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Modal Header with Case 1 / Case 2 style
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isCase2
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFEF2F2),
                border: Border(
                  bottom: BorderSide(
                    color: isCase2
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFECACA),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCase2
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCase2
                          ? Icons.shield_outlined
                          : Icons.warning_amber_rounded,
                      color: isCase2
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCase2
                              ? 'Yêu cầu hủy phòng & Hoàn tiền'
                              : 'Xác nhận hủy đặt phòng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isCase2
                                ? const Color(0xFF14532D)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Mã đơn: #${booking.bookingCode} • ${booking.hotel.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Modal Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ─── TRƯỜNG HỢP 1: Đơn chưa thanh toán HOẶC số tiền hoàn = 0đ ───
                    if (!isCase2) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bạn có chắc chắn muốn hủy đặt phòng?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              !_isPaid
                                  ? 'Đơn đặt phòng này hiện chưa thanh toán. Sau khi hủy, phòng sẽ được giải phóng ngay lập tức trên hệ thống.'
                                  : 'Đơn đặt phòng này không phát sinh hoàn tiền theo chính sách hủy phòng của khách sạn.',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF7F1D1D),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // ─── TRƯỜNG HỢP 2: Đơn đã thanh toán VÀ hoàn > 0đ ───────────
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFECFDF5), Color(0xFFF0FDF4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'THÔNG TIN HOÀN TIỀN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasPenalty
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: hasPenalty
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFFBBF7D0),
                                    ),
                                  ),
                                  child: Text(
                                    'Hoàn $refundPct% giá trị đơn',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: hasPenalty
                                          ? const Color(0xFFB45309)
                                          : const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(
                              height: 1,
                              color: Color(0xFFBBF7D0),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                const Text(
                                  'Số tiền bạn sẽ được hoàn lại:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  '${currency.format(estimatedRefund)} ₫',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                            if (booking.cancellation.policyNote.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                booking.cancellation.policyNote,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF15803D),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Tiêu đề phần Form Tài Khoản Ngân Hàng
                      Row(
                        children: [
                          Container(
                            width: 3.5,
                            height: 15,
                            decoration: BoxDecoration(
                              color: const Color(0xFF003580),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Thông tin tài khoản nhận tiền hoàn',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Field 1: Ngân hàng nhận tiền
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text.rich(
                                TextSpan(
                                  text: 'Ngân hàng nhận tiền ',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(color: Color(0xFFDC2626)),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedBank?.effectiveBin.isNotEmpty == true)
                                Text(
                                  'Mã BIN: ${_selectedBank!.effectiveBin}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _isLoadingBanks ? null : _openBankPicker,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _bankError != null
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (_selectedBank != null) ...[
                                    if (_selectedBank!.logoUrl != null &&
                                        _selectedBank!.logoUrl!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          _selectedBank!.logoUrl!,
                                          width: 32,
                                          height: 24,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.account_balance_rounded,
                                            size: 22,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.account_balance_rounded,
                                        size: 22,
                                        color: Color(0xFF64748B),
                                      ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedBank!.shortName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            _selectedBank!.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    Expanded(
                                      child: Text(
                                        _isLoadingBanks
                                            ? 'Đang tải danh sách ngân hàng hệ thống...'
                                            : 'Chọn ngân hàng nhận tiền...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _isLoadingBanks
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_bankError != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _bankError!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Field 2: Số tài khoản nhận tiền
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Số tài khoản nhận tiền ',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(color: Color(0xFFDC2626)),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Chỉ nhập chữ số',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _accountNumberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(25),
                            ],
                            onChanged: _handleAccountNumberChange,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ví dụ: 0987654321',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.normal,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: _accountNumberError != null
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: _accountNumberError != null
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF003580),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          if (_accountNumberError != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _accountNumberError!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Field 3: Tên chủ tài khoản
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text.rich(
                                TextSpan(
                                  text: 'Tên chủ tài khoản (viết hoa không dấu) ',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(color: Color(0xFFDC2626)),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Tự động in hoa',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _accountHolderController,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(100),
                            ],
                            onChanged: _handleAccountHolderChange,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'VD: NGUYEN VAN A',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.normal,
                                letterSpacing: 0,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: _accountHolderError != null
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: _accountHolderError != null
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF003580),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          if (_accountHolderError != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _accountHolderError!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    // ─── Phần Lý do hủy phòng (Áp dụng cho CẢ 2 TRƯỜNG HỢP) ────
                    const Text.rich(
                      TextSpan(
                        text: 'Lý do hủy phòng ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _reasonError != null
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReason,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                          items: kCommonCancellationReasons
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedReason = val;
                                if (_reasonError != null) _reasonError = null;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    if (_selectedReason == 'Khác') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customReasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Vui lòng nhập lý do hủy phòng của bạn...',
                          hintStyle: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF94A3B8),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _reasonError != null
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF003580),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (_) {
                          if (_reasonError != null) {
                            setState(() => _reasonError = null);
                          }
                        },
                      ),
                    ],

                    if (_reasonError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _reasonError!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Modal Footer Actions
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Giữ lại phòng',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: isCase2 ? 2 : 1,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _handleConfirm,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isCase2
                                  ? Icons.assignment_return_outlined
                                  : Icons.cancel_outlined,
                              size: 16,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'Đang xử lý...'
                            : (isCase2
                                ? 'Xác nhận gửi yêu cầu hoàn tiền'
                                : 'Xác nhận hủy phòng'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: isCase2
                            ? const Color(0xFF0F766E)
                            : const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom Sheet tìm kiếm và chọn ngân hàng
class _BankPickerSheet extends StatefulWidget {
  final List<BankModel> banks;
  final BankModel? selectedBank;

  const _BankPickerSheet({
    required this.banks,
    this.selectedBank,
  });

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BankModel> get _filteredBanks {
    if (_query.trim().isEmpty) return widget.banks;
    return widget.banks.where((b) => b.matches(_query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBanks;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn ngân hàng nhận tiền',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('bank_search_input'),
              controller: _searchController,
              autofocus: true,
              onChanged: (val) => setState(() => _query = val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm ngân hàng (tên, mã BIN, viết tắt)...',
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF003580)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Không tìm thấy ngân hàng phù hợp.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, index) {
                      final bank = filtered[index];
                      final isSelected = widget.selectedBank?.bankCd == bank.bankCd;

                      return ListTile(
                        onTap: () => Navigator.of(context).pop(bank),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 44,
                          height: 32,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: bank.logoUrl != null && bank.logoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    bank.logoUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.account_balance_rounded,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.account_balance_rounded,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              bank.shortName,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFF003580)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            if (bank.effectiveBin.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'BIN: ${bank.effectiveBin}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          bank.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF003580),
                                size: 20,
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
