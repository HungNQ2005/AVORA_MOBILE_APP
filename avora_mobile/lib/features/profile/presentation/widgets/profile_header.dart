import 'package:flutter/material.dart';
import 'package:avora_mobile/features/auth/data/auth_model.dart';
import 'profile_widgets.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
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
    final hasAvatar = profile.avatarUrl?.startsWith('https://') == true ||
        profile.avatarUrl?.startsWith('http://') == true;

    return ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF002244),
                foregroundImage:
                    hasAvatar ? NetworkImage(profile.avatarUrl!) : null,
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
              ProfileStatusPill(
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
                ProfileStatusPill(
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
          ProfileContactLine(
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
}
