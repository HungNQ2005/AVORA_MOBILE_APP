import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/payment_repository.dart';

/// Màn hình xác nhận thanh toán thành công.
/// Đồng bộ 1:1 với `PaymentSuccessScreen.jsx` trên Avora Web:
/// Xác minh lại trạng thái đơn với server (`GET /api/payment/status/:bookingId`)
/// trước khi hiển thị xác nhận hoàn tất.
class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const PaymentSuccessScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

enum _VerifyState { checking, paid, unpaid, error }

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  _VerifyState _state = _VerifyState.checking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyStatus();
    });
  }

  Future<void> _verifyStatus() async {
    setState(() => _state = _VerifyState.checking);
    try {
      final status = await ref
          .read(paymentRepositoryProvider)
          .fetchPaymentStatus(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _state = (status.isPaid || status.statusCodeName == 'CFM')
            ? _VerifyState.paid
            : _VerifyState.unpaid;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _VerifyState.error);
    }
  }

  String get _shortBookingRef {
    final parts = widget.bookingId.split('-');
    return parts.isNotEmpty ? parts.first.toUpperCase() : widget.bookingId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvoraTheme.pageBg,
      appBar: AppBar(
        backgroundColor: AvoraTheme.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Xác nhận thanh toán',
          style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_state) {
            _VerifyState.checking => _buildCheckingCard(),
            _VerifyState.paid => _buildPaidCard(context),
            _VerifyState.unpaid || _VerifyState.error => _buildUnpaidOrErrorCard(context),
          },
        ),
      ),
    );
  }

  Widget _buildCheckingCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AvoraTheme.cardBorder),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AvoraTheme.primaryNavy),
          SizedBox(height: 16),
          Text(
            'Đang xác minh thanh toán với máy chủ...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AvoraTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaidCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AvoraTheme.successGreen,
              size: 48,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Thanh toán thành công',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AvoraTheme.primaryNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AvoraTheme.textSecondary,
                height: 1.45,
              ),
              children: [
                const TextSpan(text: 'Đơn đặt phòng '),
                TextSpan(
                  text: '#$_shortBookingRef',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                    color: AvoraTheme.primaryNavy,
                  ),
                ),
                const TextSpan(
                  text: ' đã được xác nhận.\nCảm ơn bạn đã tin tưởng AVORA!',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go(
                AppRoutes.bookingDetailPath(widget.bookingId),
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text(
                'Xem chi tiết đơn đặt phòng',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AvoraTheme.primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.myBooking),
              style: ElevatedButton.styleFrom(
                backgroundColor: AvoraTheme.actionBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Xem đơn đặt chỗ của tôi',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
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
              child: const Text(
                'Về trang chủ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AvoraTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpaidOrErrorCard(BuildContext context) {
    final isUnpaid = _state == _VerifyState.unpaid;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AvoraTheme.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUnpaid ? Icons.info_outline_rounded : Icons.error_outline_rounded,
            size: 48,
            color: isUnpaid ? AvoraTheme.warningAmber : AvoraTheme.errorRed,
          ),
          const SizedBox(height: 14),
          Text(
            isUnpaid
                ? 'Đơn hàng chưa được thanh toán'
                : 'Không thể xác minh thanh toán',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AvoraTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isUnpaid
                ? 'Hệ thống chưa ghi nhận thanh toán cho đơn này.'
                : 'Vui lòng kiểm tra lại trong mục đơn đặt phòng của bạn.',
            style: const TextStyle(
              fontSize: 13.5,
              color: AvoraTheme.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          if (isUnpaid) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pushReplacement(
                  AppRoutes.paymentQrPath(widget.bookingId),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AvoraTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Quay lại thanh toán',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
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
        ],
      ),
    );
  }
}

