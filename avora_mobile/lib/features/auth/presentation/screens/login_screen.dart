import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/router/app_router.dart';
import 'forgot_password_modal.dart';

/// Màn hình Đăng nhập.
/// Xử lý UI, form validation và lắng nghe AuthState từ Riverpod.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email không được để trống.';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Email không hợp lệ.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Mật khẩu không được để trống.';
    // Backend yêu cầu tối thiểu 8 ký tự
    if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự.';
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  // ── Listen to State Changes ────────────────────────────────────────────────
  void _handleStateChange(AuthState? previous, AuthState next) {
    // Dùng addPostFrameCallback để đảm bảo showDialog/navigate
    // được gọi SAU khi frame build hiện tại hoàn tất,
    // tránh dialog bị hủy do widget tree rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (next is AuthSuccess) {
        context.go(AppRoutes.home);
      } else if (next is AuthError) {
        final upperCode = (next.code ?? '').toUpperCase();
        final upperMsg = next.message.toUpperCase();
        final isDeactivated = upperCode.contains('DEACTIVATED') ||
            upperMsg.contains('VÔ HIỆU HÓA') ||
            upperMsg.contains('BỊ KHÓA') ||
            upperMsg.contains('DEACTIVATED');
        final isVerifying = upperCode.contains('VERIFYING') ||
            upperMsg.contains('CHƯA KÍCH HOẠT') ||
            upperMsg.contains('XÁC THỰC') ||
            upperMsg.contains('VERIFYING');

        if (isDeactivated) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              icon: const Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 44),
              title: const Text(
                'Tài khoản đã bị khóa',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              content: Text(
                next.message,
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ref.read(authNotifierProvider.notifier).reset();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        } else if (isVerifying) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              icon: const Icon(Icons.mark_email_unread_outlined, color: Color(0xFF0284C7), size: 44),
              title: const Text(
                'Xác thực tài khoản',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              content: Text(
                next.message,
                style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                textAlign: TextAlign.center,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ref.read(authNotifierProvider.notifier).reset();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 4),
            ),
          );
          ref.read(authNotifierProvider.notifier).reset();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe state thay đổi để xử lý side effects
    ref.listen<AuthState>(authNotifierProvider, _handleStateChange);

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                const SizedBox(height: 32),
                _buildHeader(),
                const SizedBox(height: 40),

                // ── Email Field ──────────────────────────────────────────────
                TextFormField(
                  key: const Key('login_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                // ── Password Field ───────────────────────────────────────────
                TextFormField(
                  key: const Key('login_password_field'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 8),

                // ── Forgot Password Link ─────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    key: const Key('login_forgot_password_button'),
                    onPressed: () => ForgotPasswordModal.show(
                      context,
                      initialEmail: _emailController.text.trim(),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    ),
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Login Button ─────────────────────────────────────────────
                ElevatedButton(
                  key: const Key('login_submit_button'),
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Đăng nhập'),
                ),
                const SizedBox(height: 20),

                // ── Navigate to Signup ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chưa có tài khoản?'),
                    TextButton(
                      key: const Key('login_to_signup_button'),
                      onPressed: () => context.go(AppRoutes.signup),
                      child: const Text('Đăng ký ngay'),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo text
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF0284C7), Color(0xFF2563EB)],
          ).createShader(bounds),
          child: const Text(
            'AVORA',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chào mừng trở lại!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Đăng nhập để tiếp tục.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
              ),
        ),
      ],
    );
  }
}
