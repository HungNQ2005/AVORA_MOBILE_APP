import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/core/network/api_client.dart';
import 'package:avora_mobile/core/router/app_router.dart';
import 'package:avora_mobile/features/auth/data/auth_model.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:avora_mobile/features/profile/data/profile_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserModel? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _loadError;
  String? _profileMessage;
  bool _profileMessageIsError = false;
  String? _passwordMessage;
  bool _passwordMessageIsError = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final profile = await ref.read(profileRepositoryProvider).getProfile();
      if (!mounted) return;
      _setProfile(profile);
      setState(() => _isLoading = false);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.message;
      });
    }
  }

  void _setProfile(UserModel profile) {
    _profile = profile;
    _fullNameController.text = profile.fullName ?? '';
    _phoneController.text = profile.phone ?? '';
    ref.read(authNotifierProvider.notifier).setUser(profile);
  }

  void _startEditing() {
    _fullNameController.text = _profile?.fullName ?? '';
    _phoneController.text = _profile?.phone ?? '';
    setState(() {
      _isEditing = true;
      _profileMessage = null;
    });
  }

  void _cancelEditing() {
    _fullNameController.text = _profile?.fullName ?? '';
    _phoneController.text = _profile?.phone ?? '';
    setState(() {
      _isEditing = false;
      _profileMessage = null;
    });
  }

  Future<void> _saveProfile() async {
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty) {
      setState(() {
        _profileMessage = 'Vui lòng nhập họ và tên đầy đủ.';
        _profileMessageIsError = true;
      });
      return;
    }

    setState(() {
      _isSavingProfile = true;
      _profileMessage = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            fullName: fullName,
            phone: _phoneController.text.trim(),
          );
      final updatedProfile = await ref
          .read(profileRepositoryProvider)
          .getProfile();
      if (!mounted) return;
      _setProfile(updatedProfile);
      setState(() {
        _isEditing = false;
        _isSavingProfile = false;
        _profileMessage = 'Cập nhật thông tin thành công.';
        _profileMessageIsError = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSavingProfile = false;
        _profileMessage = error.message;
        _profileMessageIsError = true;
      });
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    String? validationMessage;

    if (currentPassword.isEmpty) {
      validationMessage = 'Vui lòng nhập mật khẩu hiện tại.';
    } else if (newPassword.length < 8) {
      validationMessage = 'Mật khẩu mới phải có tối thiểu 8 ký tự.';
    } else if (newPassword != confirmPassword) {
      validationMessage = 'Mật khẩu xác nhận không khớp.';
    }

    if (validationMessage != null) {
      setState(() {
        _passwordMessage = validationMessage;
        _passwordMessageIsError = true;
      });
      return;
    }

    setState(() {
      _isChangingPassword = true;
      _passwordMessage = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _isChangingPassword = false;
        _passwordMessage = 'Đổi mật khẩu thành công.';
        _passwordMessageIsError = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isChangingPassword = false;
        _passwordMessage = error.message;
        _passwordMessageIsError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF003580),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Hồ sơ của tôi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xFFBFDBFE),
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'Cá nhân'),
              Tab(icon: Icon(Icons.shield_outlined), text: 'Bảo mật'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF003580)),
              )
            : _loadError != null
            ? _buildLoadError()
            : TabBarView(children: [_buildProfileTab(), _buildSecurityTab()]),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: Color(0xFF64748B),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải hồ sơ',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final profile = _profile!;
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          _buildProfileHero(profile),
          const SizedBox(height: 16),
          _buildShortcuts(),
          const SizedBox(height: 16),
          _buildProfileCard(profile),
        ],
      ),
    );
  }

  Widget _buildProfileHero(UserModel profile) {
    final displayName = profile.fullName?.trim().isNotEmpty == true
        ? profile.fullName!.trim()
        : 'Quý khách';
    final initials = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1).toUpperCase())
        .join();
    final isActive = profile.accountStatus?.toUpperCase() == 'ACTIVE';
    final hasAvatar =
        profile.avatarUrl?.startsWith('https://') == true ||
        profile.avatarUrl?.startsWith('http://') == true;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF002244),
                foregroundImage: hasAvatar
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: hasAvatar
                    ? null
                    : Text(
                        initials.isEmpty ? 'AV' : initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                icon: isActive
                    ? Icons.verified_user_outlined
                    : Icons.info_outline,
                label: _accountStatusLabel(profile.accountStatus),
                color: isActive
                    ? const Color(0xFF059669)
                    : const Color(0xFF64748B),
                background: isActive
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFF1F5F9),
              ),
              if (profile.role?.isNotEmpty == true)
                _StatusPill(
                  icon: Icons.badge_outlined,
                  label: profile.role!,
                  color: const Color(0xFF1D4ED8),
                  background: const Color(0xFFEFF6FF),
                ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 13),
          _ContactLine(
            icon: Icons.phone_outlined,
            text: profile.phone?.trim().isNotEmpty == true
                ? profile.phone!.trim()
                : 'Chưa điền số điện thoại',
          ),
        ],
      ),
    );
  }

  String _accountStatusLabel(String? status) {
    return switch (status?.toUpperCase()) {
      'ACTIVE' => 'Tài khoản thành viên chính thức',
      'VERIFYING' => 'Chờ xác minh',
      'DEACTIVATED' => 'Đã vô hiệu hóa',
      null || '' => 'Chưa có trạng thái',
      _ => status!,
    };
  }

  Widget _buildShortcuts() {
    return Row(
      children: [
        Expanded(
          child: _ShortcutCard(
            icon: Icons.favorite_border,
            label: 'Yêu thích',
            onTap: () => context.push(AppRoutes.favorites),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutCard(
            icon: Icons.luggage_outlined,
            label: 'Đặt chỗ',
            onTap: () => context.push(AppRoutes.myBooking),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(UserModel profile) {
    final verified = profile.accountStatus?.toUpperCase() == 'ACTIVE';
    return _ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin cá nhân',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Quản lý thông tin dùng cho các kỳ nghỉ của bạn.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isEditing)
                IconButton(
                  tooltip: 'Chỉnh sửa thông tin',
                  onPressed: _startEditing,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF003580),
                  ),
                ),
            ],
          ),
          if (_profileMessage != null) ...[
            const SizedBox(height: 14),
            _InlineMessage(
              message: _profileMessage!,
              isError: _profileMessageIsError,
            ),
          ],
          const SizedBox(height: 16),
          _FormLabel(label: 'Họ và tên đầy đủ', isEditable: _isEditing),
          const SizedBox(height: 7),
          if (_isEditing)
            TextField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration('Nhập họ và tên đầy đủ'),
            )
          else
            _ReadOnlyValue(
              value: profile.fullName?.trim().isNotEmpty == true
                  ? profile.fullName!.trim()
                  : 'Chưa điền thông tin',
            ),
          const SizedBox(height: 16),
          const _FormLabel(label: 'Địa chỉ email'),
          const SizedBox(height: 7),
          _ReadOnlyValue(
            value: profile.email,
            leading: Icons.lock_outline,
            trailing: verified ? 'Đã xác minh' : 'Chưa xác minh',
            verified: verified,
          ),
          const SizedBox(height: 16),
          _FormLabel(label: 'Số điện thoại liên lạc', isEditable: _isEditing),
          const SizedBox(height: 7),
          if (_isEditing)
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: _inputDecoration('+84 0905 123 456'),
            )
          else
            _ReadOnlyValue(
              value: profile.phone?.trim().isNotEmpty == true
                  ? profile.phone!.trim()
                  : 'Chưa điền thông tin',
            ),
          if (_isEditing) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSavingProfile ? null : _cancelEditing,
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSavingProfile ? null : _saveProfile,
                    icon: _isSavingProfile
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_isSavingProfile ? 'Đang lưu' : 'Lưu thay đổi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003580),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        _buildProfileHero(_profile!),
        const SizedBox(height: 16),
        _ProfileCard(
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
              if (_passwordMessage != null) ...[
                _InlineMessage(
                  message: _passwordMessage!,
                  isError: _passwordMessageIsError,
                ),
                const SizedBox(height: 16),
              ],
              _PasswordField(
                label: 'Mật khẩu hiện tại',
                hint: 'Nhập mật khẩu hiện tại',
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                onToggleVisibility: () => setState(
                  () => _obscureCurrentPassword = !_obscureCurrentPassword,
                ),
              ),
              const SizedBox(height: 15),
              _PasswordField(
                label: 'Mật khẩu mới',
                hint: 'Tối thiểu 8 ký tự',
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                onToggleVisibility: () =>
                    setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
              const SizedBox(height: 15),
              _PasswordField(
                label: 'Xác nhận mật khẩu mới',
                hint: 'Nhập lại mật khẩu mới',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isChangingPassword ? null : _changePassword,
                  icon: _isChangingPassword
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
                    _isChangingPassword ? 'Đang cập nhật' : 'Cập nhật mật khẩu',
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
    ),
  );
}

class _ProfileCard extends StatelessWidget {
  final Widget child;

  const _ProfileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF0284C7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF003580), size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  final bool isEditable;

  const _FormLabel({required this.label, this.isEditable = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (isEditable)
          const Text(
            'Có thể chỉnh sửa',
            style: TextStyle(
              color: Color(0xFF0284C7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _ReadOnlyValue extends StatelessWidget {
  final String value;
  final IconData? leading;
  final String? trailing;
  final bool verified;

  const _ReadOnlyValue({
    required this.value,
    this.leading,
    this.trailing,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            Icon(leading, size: 15, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            Icon(
              verified ? Icons.check_circle_outline : Icons.info_outline,
              size: 14,
              color: verified
                  ? const Color(0xFF059669)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 4),
            Text(
              trailing!,
              style: TextStyle(
                color: verified
                    ? const Color(0xFF059669)
                    : const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggleVisibility;

  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormLabel(label: label),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscureText,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            suffixIcon: IconButton(
              tooltip: obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF0284C7),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String message;
  final bool isError;

  const _InlineMessage({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB91C1C) : const Color(0xFF047857);
    final background = isError
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFECFDF5);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontSize: 12, height: 1.4),
      ),
    );
  }
}
