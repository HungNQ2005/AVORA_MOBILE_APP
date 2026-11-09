import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../booking/presentation/providers/booking_detail_provider.dart';
import '../../../my_booking/presentation/providers/my_booking_provider.dart';
import '../../data/models/payment_qr_model.dart';
import '../../data/repositories/payment_repository.dart';

/// Màn hình thanh toán VietQR (SePay) chuẩn kiến trúc Dumb Client.
/// Đồng bộ 1:1 với `PaymentQRScreen.jsx` trên Avora Web:
///  1. Gọi `POST /api/payment/create-qr` lấy VietQR URL, mã thanh toán và số giây còn lại.
///  2. Đếm ngược thời gian giữ phòng 10 phút từ `remaining_time_seconds` của server.
///  3. Polling `GET /api/payment/status/:bookingId` mỗi 3 giây.
///  4. Hiển thị overlay thành công và tự động chuyển tới màn hình xác nhận sau 2 giây.
class PaymentQrScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const PaymentQrScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends ConsumerState<PaymentQrScreen> {
  static const Duration _pollInterval = Duration(seconds: 3);
  static const Duration _redirectDelay = Duration(seconds: 2);

  PaymentQrModel? _paymentInfo;
  bool _isLoading = true;
  String? _fatalError;
  int? _remainingSeconds;
  bool _isExpired = false;
  bool _isPaid = false;
  String? _copiedField;

  DateTime? _deadline;
  Timer? _countdownTimer;
  Timer? _pollTimer;
  Timer? _redirectTimer;
  Timer? _copyResetTimer;
  bool _lastPollHadError = false;
  bool _isPollingInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQr();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    _redirectTimer?.cancel();
    _copyResetTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadQr() async {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();

    setState(() {
      _isLoading = true;
      _fatalError = null;
    });

    try {
      final data = await ref
          .read(paymentRepositoryProvider)
          .createPaymentQr(widget.bookingId);

      if (!mounted) return;

      _deadline = DateTime.now().add(
        Duration(seconds: data.remainingTimeSeconds),
      );
      final expired = data.remainingTimeSeconds <= 0;

      setState(() {
        _paymentInfo = data;
        _remainingSeconds = data.remainingTimeSeconds;
        _isExpired = expired;
        _isLoading = false;
      });

      if (!expired && !_isPaid) {
        _startCountdown();
        _startPolling();
      }
    } on ApiException catch (err) {
      if (!mounted) return;
      final code = (err.code ?? '').toUpperCase();
      if (code == 'PAYMENT_EXPIRED' || code == 'NOT_PENDING') {
        setState(() {
          _isExpired = true;
          _isLoading = false;
        });
      } else if (code == 'ALREADY_PAID') {
        _handlePaidDetected();
      } else {
        setState(() {
          _fatalError = err.message;
          _isLoading = false;
        });
        _showSnack(err.message, isError: true);
      }
    } catch (err) {
      if (!mounted) return;
      final msg = err.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      setState(() {
        _fatalError = msg.isNotEmpty
            ? msg
            : 'Không thể tạo mã QR thanh toán.';
        _isLoading = false;
      });
      _showSnack(_fatalError!, isError: true);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _deadline == null || _isPaid || _isExpired) return;
      final diffMs = _deadline!.difference(DateTime.now()).inMilliseconds;
      final left = diffMs <= 0 ? 0 : (diffMs + 999) ~/ 1000;
      setState(() {
        _remainingSeconds = left;
        if (left <= 0) {
          _isExpired = true;
          _countdownTimer?.cancel();
          _pollTimer?.cancel();
        }
      });
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (!mounted || _isPaid || _isExpired || _isPollingInFlight) return;
      _isPollingInFlight = true;
      try {
        final status = await ref
            .read(paymentRepositoryProvider)
            .fetchPaymentStatus(widget.bookingId);
        if (!mounted || _isPaid || _isExpired) return;
        _lastPollHadError = false;

        if (status.isPaid || status.statusCodeName == 'CFM') {
          _handlePaidDetected();
        } else if (status.statusCodeName == 'CAN') {
          setState(() {
            _isExpired = true;
          });
          _countdownTimer?.cancel();
          _pollTimer?.cancel();
        }
      } catch (_) {
        if (!mounted) return;
        if (!_lastPollHadError) {
          _lastPollHadError = true;
          _showSnack(
            'Mất kết nối khi kiểm tra thanh toán. Đang thử lại...',
            isError: true,
          );
        }
      } finally {
        _isPollingInFlight = false;
      }
    });
  }

  void _handlePaidDetected() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();

    setState(() {
      _isPaid = true;
      _isLoading = false;
    });

    // Làm mới dữ liệu danh sách đơn và chi tiết đơn để đồng bộ trạng thái CFM
    ref.invalidate(bookingDetailProvider(widget.bookingId));
    ref.read(myBookingNotifierProvider.notifier).loadBookings(silent: true);

    _redirectTimer?.cancel();
    _redirectTimer = Timer(_redirectDelay, () {
      if (!mounted) return;
      context.pushReplacement(AppRoutes.paymentSuccessPath(widget.bookingId));
    });
  }

  Future<void> _handleCopy(String key, String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    setState(() {
      _copiedField = key;
    });
    _copyResetTimer?.cancel();
    _copyResetTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      if (_copiedField == key) {
        setState(() {
          _copiedField = null;
        });
      }
    });
    _showSnack('Đã sao chép $label vào bộ nhớ tạm');
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AvoraTheme.errorRed : AvoraTheme.primaryNavy,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatCountdown(int? totalSeconds) {
    if (totalSeconds == null) return '--:--';
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final mins = (s ~/ 60).toString().padLeft(2, '0');
    final secs = (s % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,###', 'vi_VN');

    return Scaffold(
      backgroundColor: AvoraTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AvoraTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.myBooking);
            }
          },
        ),
        title: const Text(
          'Thanh toán đơn hàng',
          style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!_isPaid && !_isExpired)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Tải lại mã QR',
              onPressed: _isLoading ? null : _loadQr,
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isExpired && !_isPaid)
            _buildExpiredState()
          else if (_fatalError != null && !_isLoading && !_isPaid)
            _buildFatalErrorState()
          else
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Khung đếm ngược 10 phút
                  _buildCountdownBanner(),
                  const SizedBox(height: 16),

                  // 2. Thẻ Mã QR VietQR
                  _buildQrCard(),
                  const SizedBox(height: 16),

                  // 3. Thẻ Thông tin đơn hàng
                  _buildOrderSummaryCard(currency),
                  const SizedBox(height: 16),

                  // 4. Thẻ Chuyển khoản thủ công
                  _buildManualTransferCard(currency),
                ],
              ),
            ),

          // Overlay thông báo thanh toán thành công (tự chuyển trang sau 2s)
          if (_isPaid) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  // ─── 1. Countdown Banner ────────────────────────────────────────────────────
  Widget _buildCountdownBanner() {
    final isUrgent = _remainingSeconds != null && _remainingSeconds! <= 60;
    final bgColor = isUrgent ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final borderColor = isUrgent ? const Color(0xFFFECACA) : const Color(0xFFFDE68A);
    final textColor = isUrgent ? const Color(0xFFDC2626) : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isUrgent ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_outlined,
              color: textColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thời gian còn lại để thanh toán',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Đơn đặt phòng sẽ tự động hủy nếu quá hạn',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AvoraTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              _formatCountdown(_remainingSeconds),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. QR Card ─────────────────────────────────────────────────────────────
  Widget _buildQrCard() {
    final info = _paymentInfo;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvoraTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Quét mã QR để thanh toán',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AvoraTheme.primaryNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Mở ứng dụng ngân hàng bất kỳ (VietQR / Napas247) và quét mã',
            style: TextStyle(
              fontSize: 12.5,
              color: AvoraTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Khung ảnh QR
          Container(
            width: 250,
            height: 250,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: _isLoading || info == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AvoraTheme.primaryNavy,
                          strokeWidth: 2.5,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Đang tạo mã VietQR...',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AvoraTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : Image.network(
                    info.qrUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AvoraTheme.primaryNavy,
                          strokeWidth: 2.5,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 48,
                                color: AvoraTheme.textMuted,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Không tải được ảnh QR.\nVui lòng dùng thông tin chuyển khoản thủ công bên dưới.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AvoraTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // Trạng thái chờ tự động đối soát
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AvoraTheme.actionBlue,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Đang chờ bạn thanh toán (tự động xác nhận)...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Order Summary Card ──────────────────────────────────────────────────
  Widget _buildOrderSummaryCard(NumberFormat currency) {
    final info = _paymentInfo;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvoraTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: AvoraTheme.primaryNavy,
              ),
              SizedBox(width: 8),
              Text(
                'Thông tin đơn hàng',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AvoraTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoading || info == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khách sạn',
                  style: TextStyle(fontSize: 13, color: AvoraTheme.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    info.hotelName.isNotEmpty ? info.hotelName : '—',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AvoraTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mã đơn hàng',
                  style: TextStyle(fontSize: 13, color: AvoraTheme.textSecondary),
                ),
                Text(
                  '#${info.bookingRef}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AvoraTheme.primaryNavy,
                  ),
                ),
              ],
            ),
            const Divider(height: 22, color: AvoraTheme.cardBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng tiền thanh toán',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AvoraTheme.textPrimary,
                  ),
                ),
                Text(
                  '${currency.format(info.amount)} ₫',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AvoraTheme.primaryNavy,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── 4. Manual Transfer Card ────────────────────────────────────────────────
  Widget _buildManualTransferCard(NumberFormat currency) {
    final info = _paymentInfo;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvoraTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_outlined,
                size: 18,
                color: AvoraTheme.primaryNavy,
              ),
              SizedBox(width: 8),
              Text(
                'Chuyển khoản thủ công',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AvoraTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Dùng khi bạn không quét được mã QR. Vui lòng nhập chính xác nội dung chuyển khoản.',
            style: TextStyle(
              fontSize: 12.5,
              color: AvoraTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          if (_isLoading || info == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            _buildManualRow(
              fieldKey: 'bank',
              label: 'Ngân hàng',
              value: info.displayBankName,
            ),
            const Divider(height: 16, color: Color(0xFFF1F5F9)),
            _buildManualRow(
              fieldKey: 'holder',
              label: 'Tên tài khoản',
              value: info.accountHolder,
            ),
            const Divider(height: 16, color: Color(0xFFF1F5F9)),
            _buildManualRow(
              fieldKey: 'account',
              label: 'Số tài khoản',
              value: info.accountNumber,
              copyValue: info.accountNumber,
            ),
            const Divider(height: 16, color: Color(0xFFF1F5F9)),
            _buildManualRow(
              fieldKey: 'amount',
              label: 'Số tiền',
              value: '${currency.format(info.amount)} ₫',
              copyValue: info.amount.toString(),
              isStrong: true,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: _buildManualRow(
                fieldKey: 'content',
                label: 'Nội dung CK',
                value: info.paymentCode,
                copyValue: info.paymentCode,
                isHighlight: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManualRow({
    required String fieldKey,
    required String label,
    required String value,
    String? copyValue,
    bool isStrong = false,
    bool isHighlight = false,
  }) {
    final isCopied = _copiedField == fieldKey;

    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
              color: isHighlight
                  ? const Color(0xFF1E40AF)
                  : AvoraTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: isHighlight ? 'monospace' : null,
              fontSize: isHighlight || isStrong ? 14.5 : 13.5,
              fontWeight: isHighlight || isStrong
                  ? FontWeight.w800
                  : FontWeight.w600,
              color: isHighlight
                  ? AvoraTheme.primaryNavy
                  : AvoraTheme.textPrimary,
            ),
          ),
        ),
        if (copyValue != null) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _handleCopy(fieldKey, label, copyValue),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isCopied
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCopied
                      ? const Color(0xFFA7F3D0)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Icon(
                isCopied ? Icons.check_rounded : Icons.copy_rounded,
                size: 15,
                color: isCopied
                    ? const Color(0xFF059669)
                    : AvoraTheme.primaryNavy,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Expired State ──────────────────────────────────────────────────────────
  Widget _buildExpiredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.timer_off_outlined,
                  size: 34,
                  color: AvoraTheme.errorRed,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đơn hàng đã hết hạn thanh toán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AvoraTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Mã QR đã bị vô hiệu hóa. Nếu bạn đã chuyển khoản sau thời điểm này, hệ thống sẽ tự động tạo yêu cầu hoàn tiền.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AvoraTheme.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.myBooking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AvoraTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Xem đơn đặt chỗ của tôi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: AvoraTheme.cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Quay lại trang chủ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Fatal Error State ──────────────────────────────────────────────────────
  Widget _buildFatalErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AvoraTheme.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AvoraTheme.errorRed,
              ),
              const SizedBox(height: 14),
              const Text(
                'Không thể tải thông tin thanh toán',
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  color: AvoraTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _fatalError ?? 'Đã xảy ra lỗi khi tạo mã QR thanh toán.',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AvoraTheme.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.myBooking),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: AvoraTheme.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Đơn của tôi'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadQr,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AvoraTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Thử lại'),
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

  // ─── Success Overlay ────────────────────────────────────────────────────────
  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFECFDF5),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AvoraTheme.successGreen,
                  size: 44,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Thanh toán thành công!',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AvoraTheme.primaryNavy,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6),
              Text(
                'Đang chuyển đến trang xác nhận...',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AvoraTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

