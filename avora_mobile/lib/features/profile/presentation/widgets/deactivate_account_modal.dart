import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/profile_repository.dart';

enum DeactivateStep { confirm, otp, success }

/// Pedal Modal BottomSheet thực hiện luồng Hủy kích hoạt tài khoản.
/// Gồm 3 bước: Xác nhận cảnh báo -> Nhập mã OTP 6 số -> Thông báo thành công và chuyển hướng.
class DeactivateAccountModal extends ConsumerStatefulWidget {
  final String userEmail;
  final VoidCallback onDeactivatedSuccess;

  const DeactivateAccountModal({
    super.key,
    required this.userEmail,
    required this.onDeactivatedSuccess,
  });

  /// Hàm helper tiện lợi để hiển thị Modal BottomSheet kéo từ dưới lên
  static Future<void> show(
    BuildContext context, {
    required String userEmail,
    required VoidCallback onDeactivatedSuccess,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DeactivateAccountModal(
          userEmail: userEmail,
          onDeactivatedSuccess: onDeactivatedSuccess,
        ),
      ),
    );
  }

  @override
  ConsumerState<DeactivateAccountModal> createState() =>
      _DeactivateAccountModalState();
}

class _DeactivateAccountModalState
    extends ConsumerState<DeactivateAccountModal> {
  static const int _otpLength = 6;
  static const int _otpExpirySeconds = 300; // 5 phút

  DeactivateStep _step = DeactivateStep.confirm;

  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _focusNodes;

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _infoMessage;

  int _timeLeft = _otpExpirySeconds;
  Timer? _countdownTimer;

  int _redirectCountdown = 3;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _otpControllers =
        List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _redirectTimer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startOtpTimer() {
    _countdownTimer?.cancel();
    _timeLeft = _otpExpirySeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft <= 1) {
        timer.cancel();
        setState(() => _timeLeft = 0);
      } else {
        setState(() => _timeLeft -= 1);
      }
    });
  }

  void _startRedirectTimer() {
    _redirectTimer?.cancel();
    _redirectCountdown = 3;
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_redirectCountdown <= 1) {
        timer.cancel();
        _finishAndRedirect();
      } else {
        setState(() => _redirectCountdown -= 1);
      }
    });
  }

  void _finishAndRedirect() {
    Navigator.of(context).pop();
    widget.onDeactivatedSuccess();
  }

  String _formatTime(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String _getOtp() {
    return _otpControllers.map((c) => c.text.trim()).join();
  }

  // ── Step 1: Request OTP ───────────────────────────────────────────────────
  Future<void> _handleRequestOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await ref.read(profileRepositoryProvider).requestDeactivateOtp();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = DeactivateStep.otp;
        _infoMessage =
            'Mã xác thực 6 chữ số đã được gửi tới email của bạn.';
      });
      _startOtpTimer();
      // Tự động focus vào ô đầu tiên
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNodes.isNotEmpty) {
          _focusNodes[0].requestFocus();
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Không thể gửi mã xác thực. Vui lòng kiểm tra mạng và thử lại.';
      });
    }
  }

  // ── Step 2: Resend OTP ────────────────────────────────────────────────────
  Future<void> _handleResendOtp() async {
    if (_isResending || _isLoading) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await ref.read(profileRepositoryProvider).requestDeactivateOtp();
      if (!mounted) return;

      for (final c in _otpControllers) {
        c.clear();
      }
      _startOtpTimer();
      setState(() {
        _isResending = false;
        _infoMessage =
            'Mã xác thực mới đã được gửi tới email của bạn.';
      });
      _focusNodes[0].requestFocus();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorMessage = 'Không thể gửi lại mã xác thực. Vui lòng thử lại sau.';
      });
    }
  }

  // ── Step 2: Submit OTP ────────────────────────────────────────────────────
  Future<void> _handleSubmitOtp() async {
    final otp = _getOtp();
    if (otp.length < _otpLength) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đủ 6 chữ số của mã xác thực.';
      });
      return;
    }

    if (_timeLeft <= 0) {
      setState(() {
        _errorMessage =
            'Mã xác thực đã hết hạn. Vui lòng nhấn "Gửi lại mã" để nhận mã mới.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await ref
          .read(profileRepositoryProvider)
          .deactivateAccount(otp: otp);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _step = DeactivateStep.success;
      });
      _startRedirectTimer();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Xác thực không thành công. Vui lòng kiểm tra lại mã OTP.';
      });
    }
  }

  // ── Handle OTP Digit Input ────────────────────────────────────────────────
  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Người dùng dán chuỗi OTP (paste)
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _otpLength && i < digits.length; i++) {
        _otpControllers[i].text = digits[i];
      }
      final nextIndex = digits.length >= _otpLength ? _otpLength - 1 : digits.length;
      _focusNodes[nextIndex].requestFocus();
      setState(() => _errorMessage = null);
      if (digits.length >= _otpLength) {
        _handleSubmitOtp();
      }
      return;
    }

    setState(() => _errorMessage = null);

    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Khi nhập đủ 6 ký tự, tự động submit
        if (_getOtp().length == _otpLength) {
          _handleSubmitOtp();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thanh kéo (Drag handle bar)
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Nút đóng góc phải
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF64748B)),
              onPressed: _isLoading || _step == DeactivateStep.success
                  ? null
                  : () => Navigator.of(context).pop(),
            ),
          ),

          // Nội dung theo từng bước
          switch (_step) {
            DeactivateStep.confirm => _buildConfirmStep(),
            DeactivateStep.otp => _buildOtpStep(),
            DeactivateStep.success => _buildSuccessStep(),
          },
        ],
      ),
    );
  }

  // ── Step 1: Warning & Confirm ─────────────────────────────────────────────
  Widget _buildConfirmStep() {
    return Column(
      children: [
        // Icon cảnh báo
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFDC2626),
            size: 34,
          ),
        ),
        const SizedBox(height: 16),

        // Tiêu đề
        const Text(
          'Vô hiệu hóa tài khoản?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        // Nội dung cảnh báo
        const Text(
          'Vô hiệu hóa tài khoản sẽ tạm dừng quyền truy cập và đăng xuất khỏi hệ thống. Một mã xác thực 6 chữ số sẽ được gửi tới email của bạn để xác minh danh tính. Bạn có muốn tiếp tục?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),

        // Khung hiển thị email nhận mã
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.email_outlined,
                  color: Color(0xFF003580), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.userEmail,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_errorMessage != null) ...[
          _buildMessageBanner(
            message: _errorMessage!,
            isError: true,
          ),
          const SizedBox(height: 16),
        ],

        // Nút hành động
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleRequestOtp,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            label: Text(
              _isLoading ? 'Đang gửi mã...' : 'Tiếp tục & Gửi mã OTP',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Hủy bỏ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: OTP Verification ──────────────────────────────────────────────
  Widget _buildOtpStep() {
    final isOtpComplete = _getOtp().length == _otpLength;
    final isExpired = _timeLeft <= 0;

    return Column(
      children: [
        // Icon email
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFF003580),
            size: 32,
          ),
        ),
        const SizedBox(height: 16),

        // Tiêu đề
        const Text(
          'Xác thực mã OTP',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),

        // Hướng dẫn
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Vui lòng nhập mã xác thực gồm 6 chữ số đã được gửi tới email:\n'),
              TextSpan(
                text: widget.userEmail,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // 6 ô nhập OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_otpLength, (index) {
            return _buildOtpBox(index);
          }),
        ),
        const SizedBox(height: 16),

        // Đồng hồ đếm ngược hiệu lực mã
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 16,
              color: isExpired
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              isExpired
                  ? 'Mã xác thực đã hết hạn'
                  : 'Mã có hiệu lực trong: ${_formatTime(_timeLeft)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isExpired ? FontWeight.bold : FontWeight.w500,
                color: isExpired
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Banner thông báo lỗi / info
        if (_errorMessage != null) ...[
          _buildMessageBanner(
            message: _errorMessage!,
            isError: true,
          ),
          const SizedBox(height: 14),
        ] else if (_infoMessage != null) ...[
          _buildMessageBanner(
            message: _infoMessage!,
            isError: false,
          ),
          const SizedBox(height: 14),
        ],

        // Nút Xác nhận hủy kích hoạt
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (_isLoading || !isOtpComplete || isExpired)
                ? null
                : _handleSubmitOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFFCA5A5),
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Xác nhận hủy kích hoạt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Nút Gửi lại mã OTP
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Chưa nhận được mã? ',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            _isResending
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _isLoading ? null : _handleResendOtp,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Gửi lại mã',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003580),
                      ),
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  // ── Step 3: Success State ─────────────────────────────────────────────────
  Widget _buildSuccessStep() {
    return Column(
      children: [
        // Icon tích xanh
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF059669),
            size: 38,
          ),
        ),
        const SizedBox(height: 18),

        // Tiêu đề
        const Text(
          'Đã vô hiệu hóa tài khoản',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        // Lời nhắn
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
            children: [
              const TextSpan(
                text: 'Tài khoản của bạn đã được vô hiệu hóa thành công.\n'
                    'Hệ thống đang chuyển về trang đăng nhập trong ',
              ),
              TextSpan(
                text: '${_redirectCountdown}s',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003580),
                ),
              ),
              const TextSpan(text: '...'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Nút chuyển ngay
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _finishAndRedirect,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003580),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Về trang đăng nhập ngay',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper: 1 Single Digit OTP Box ────────────────────────────────────────
  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 44,
      height: 54,
      child: KeyboardListener(
        focusNode: FocusNode(), // Node trung gian để bắt Backspace
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_otpControllers[index].text.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
              _otpControllers[index - 1].clear();
            }
          }
        },
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: _focusNodes[index].hasFocus
                ? const Color(0xFFEFF6FF)
                : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF003580), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _otpControllers[index].text.isNotEmpty
                    ? const Color(0xFF003580)
                    : const Color(0xFFCBD5E1),
              ),
            ),
          ),
          onChanged: (value) => _onDigitChanged(index, value),
        ),
      ),
    );
  }

  // ── Helper: Message Banner ────────────────────────────────────────────────
  Widget _buildMessageBanner({
    required String message,
    required bool isError,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? const Color(0xFFEF4444) : const Color(0xFF1D4ED8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isError ? const Color(0xFFB91C1C) : const Color(0xFF1E40AF),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
