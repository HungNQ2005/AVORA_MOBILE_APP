import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/core/network/api_client.dart';
import 'package:avora_mobile/core/router/app_router.dart';
import 'package:avora_mobile/features/auth/data/auth_model.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:avora_mobile/features/profile/data/profile_repository.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_section.dart';
import '../widgets/profile_security_section.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/deactivate_account_modal.dart';

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
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF003580)),
      );
    }
    if (_loadError != null) return _buildLoadError();

    return TabBarView(
      children: [
        _buildProfileTab(_profile!),
        _buildSecurityTab(_profile!),
      ],
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

  Widget _buildProfileTab(UserModel profile) {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          ProfileHeader(profile: profile),
          const SizedBox(height: 16),
          _buildShortcuts(),
          const SizedBox(height: 16),
          ProfileInfoSection(
            profile: profile,
            isEditing: _isEditing,
            isSaving: _isSavingProfile,
            message: _profileMessage,
            messageIsError: _profileMessageIsError,
            fullNameController: _fullNameController,
            phoneController: _phoneController,
            onEdit: _startEditing,
            onCancel: _cancelEditing,
            onSave: _saveProfile,
          ),
        ],
      ),
    );
  }

  Widget _buildShortcuts() {
    return Row(
      children: [
        Expanded(
          child: ProfileShortcutCard(
            icon: Icons.favorite_border,
            label: 'Yêu thích',
            onTap: () => context.push(AppRoutes.favorites),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ProfileShortcutCard(
            icon: Icons.confirmation_number_outlined,
            label: 'Mã Khuyến Mãi',
            onTap: () => context.push(AppRoutes.voucherWallet),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ProfileShortcutCard(
            icon: Icons.luggage_outlined,
            label: 'Đặt chỗ',
            onTap: () => context.push(AppRoutes.myBooking),
          ),
        ),
      ],
    );
  }

  void _handleDeactivateAccount(UserModel profile) {
    DeactivateAccountModal.show(
      context,
      userEmail: profile.email,
      onDeactivatedSuccess: () async {
        if (!mounted) return;
        await ref.read(authNotifierProvider.notifier).signOut();
      },
    );
  }

  Widget _buildSecurityTab(UserModel profile) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        ProfileHeader(profile: profile),
        const SizedBox(height: 16),
        ProfileSecuritySection(
          currentPasswordController: _currentPasswordController,
          newPasswordController: _newPasswordController,
          confirmPasswordController: _confirmPasswordController,
          obscureCurrentPassword: _obscureCurrentPassword,
          obscureNewPassword: _obscureNewPassword,
          obscureConfirmPassword: _obscureConfirmPassword,
          isChangingPassword: _isChangingPassword,
          message: _passwordMessage,
          messageIsError: _passwordMessageIsError,
          onToggleCurrentPassword: () => setState(
            () => _obscureCurrentPassword = !_obscureCurrentPassword,
          ),
          onToggleNewPassword: () =>
              setState(() => _obscureNewPassword = !_obscureNewPassword),
          onToggleConfirmPassword: () => setState(
            () => _obscureConfirmPassword = !_obscureConfirmPassword,
          ),
          onChangePassword: _changePassword,
          onDeactivateAccount: () => _handleDeactivateAccount(profile),
        ),
      ],
    );
  }
}
