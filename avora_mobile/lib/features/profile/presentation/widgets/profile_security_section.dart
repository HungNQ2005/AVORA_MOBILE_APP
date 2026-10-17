import 'package:flutter/material.dart';
import 'profile_widgets.dart';

class ProfileSecuritySection extends StatelessWidget {
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool obscureCurrentPassword;
  final bool obscureNewPassword;
  final bool obscureConfirmPassword;
  final bool isChangingPassword;
  final String? message;
  final bool messageIsError;
  final VoidCallback onToggleCurrentPassword;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onChangePassword;

  const ProfileSecuritySection({
    super.key,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.obscureCurrentPassword,
    required this.obscureNewPassword,
    required this.obscureConfirmPassword,
    required this.isChangingPassword,
    required this.message,
    required this.messageIsError,
    required this.onToggleCurrentPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF003580)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bảo mật tài khoản',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Sử dụng mật khẩu mạnh để giữ an toàn cho tài khoản Avora.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              if (message != null) ...[
                ProfileInlineMessage(
                  message: message!,
                  isError: messageIsError,
                ),
                const SizedBox(height: 16),
              ],
              ProfilePasswordField(
                label: 'Mật khẩu hiện tại',
                hint: 'Nhập mật khẩu hiện tại',
                controller: currentPasswordController,
                obscureText: obscureCurrentPassword,
                onToggleVisibility: onToggleCurrentPassword,
              ),
              const SizedBox(height: 15),
              ProfilePasswordField(
                label: 'Mật khẩu mới',
                hint: 'Tối thiểu 8 ký tự',
                controller: newPasswordController,
                obscureText: obscureNewPassword,
                onToggleVisibility: onToggleNewPassword,
              ),
              const SizedBox(height: 15),
              ProfilePasswordField(
                label: 'Xác nhận mật khẩu mới',
                hint: 'Nhập lại mật khẩu mới',
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                onToggleVisibility: onToggleConfirmPassword,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isChangingPassword ? null : onChangePassword,
                  icon: isChangingPassword
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.lock_reset_outlined),
                  label: Text(
                    isChangingPassword
                        ? 'Đang cập nhật'
                        : 'Cập nhật mật khẩu',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003580),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Color(0xFF1D4ED8), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Không chia sẻ mật khẩu hoặc mã xác thực của bạn với người khác.',
                  style: TextStyle(
                    color: Color(0xFF1E40AF),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
