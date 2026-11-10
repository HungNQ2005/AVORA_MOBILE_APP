import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/core/router/app_router.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';

import '../../../support/presentation/widgets/support_center_sheet.dart';
import '../providers/home_provider.dart';
import 'home_helpers.dart';

/// AppBar của màn hình Home chuyển thể chuẩn từ Header 2 tầng của Avora Web:
/// - Tầng 1: Logo AVORA + Badge VIỆT NAM + Lời chào + VND + Hỗ trợ 24/7 + Yêu thích + Thông báo + Đăng xuất
/// - Tầng 2: Các tab điều hướng dạng Capsule Pill (Trang chủ, Khách sạn, Về chúng tôi, Liên hệ)
class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String userName;
  final String? avatarUrl;

  const HomeAppBar({super.key, required this.userName, this.avatarUrl});

  @override
  Size get preferredSize => const Size.fromHeight(104);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = MediaQuery.sizeOf(context).width < 380;
    final actions = <Widget>[
      if (!isCompact)
        IconButton(
          icon: const Icon(
            Icons.headset_mic_outlined,
            color: Colors.white,
            size: 21,
          ),
          tooltip: 'Hỗ trợ 24/7',
          onPressed: () => showSupportCenter(context),
        ),
      if (!isCompact)
        Consumer(
          builder: (context, ref, _) {
            final count = ref.watch(
              homeProvider.select((s) => s.favorites.length),
            );
            return IconButton(
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                backgroundColor: const Color(0xFFFFC107),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF6B6B),
                  size: 22,
                ),
              ),
              tooltip: 'Yêu thích',
              onPressed: () => context.push(AppRoutes.favorites),
            );
          },
        ),
      if (!isCompact)
        IconButton(
          icon: const Icon(
            Icons.menu_book_outlined,
            color: Colors.white,
            size: 22,
          ),
          key: const Key('my_booking_button'),
          tooltip: 'Đặt chỗ của tôi',
          onPressed: () => context.push(AppRoutes.myBooking),
        ),
      if (!isCompact)
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          tooltip: 'Thông báo',
          onPressed: () =>
              showHomeSnackBar(context, 'Bạn không có thông báo mới.'),
        ),
      if (!isCompact)
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white, size: 20),
          tooltip: 'Đăng xuất',
          onPressed: () => _confirmSignOut(context, ref),
        ),
      if (isCompact)
        PopupMenuButton<_HomeMenuAction>(
          tooltip: 'Thêm lựa chọn',
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (action) {
            switch (action) {
              case _HomeMenuAction.favorites:
                context.push(AppRoutes.favorites);
              case _HomeMenuAction.bookings:
                context.push(AppRoutes.myBooking);
              case _HomeMenuAction.notifications:
                showHomeSnackBar(context, 'Bạn không có thông báo mới.');
              case _HomeMenuAction.support:
                showSupportCenter(context);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _HomeMenuAction.favorites,
              child: Text('Yêu thích'),
            ),
            PopupMenuItem(
              value: _HomeMenuAction.bookings,
              child: Text('Đặt chỗ của tôi'),
            ),
            PopupMenuItem(
              value: _HomeMenuAction.notifications,
              child: Text('Thông báo'),
            ),
            PopupMenuItem(
              value: _HomeMenuAction.support,
              child: Text('Hỗ trợ 24/7'),
            ),
          ],
        ),
      PopupMenuButton<_ProfileMenuAction>(
        key: const Key('profile_menu_button'),
        tooltip: 'Tài khoản',
        onSelected: (action) {
          switch (action) {
            case _ProfileMenuAction.profile:
              context.push(AppRoutes.profile);
            case _ProfileMenuAction.signOut:
              _confirmSignOut(context, ref);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: _ProfileMenuAction.profile,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_outline),
              title: Text('Hồ sơ cá nhân'),
            ),
          ),
          PopupMenuItem(
            value: _ProfileMenuAction.signOut,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout),
              title: Text('Đăng xuất'),
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CircleAvatar(
            key: const Key('profile_avatar_button'),
            radius: 17,
            backgroundColor: const Color(0xFF1D4ED8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  _initials(userName),
                  key: const Key('profile_avatar_fallback'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_hasAvatar)
                  ClipOval(
                    child: Image.network(
                      avatarUrl!,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ];

    return AppBar(
      backgroundColor: const Color(0xFF003580),
      elevation: 2,
      shadowColor: Colors.black38,
      centerTitle: false,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'AVORA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 21,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'VIỆT NAM',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    height: 1.1,
                  ),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VND',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _HeaderNavPill(
                  icon: Icons.home_outlined,
                  label: 'Trang chủ',
                  isActive: true,
                  onTap: () {},
                ),
                const SizedBox(width: 6),
                _HeaderNavPill(
                  icon: Icons.bed_outlined,
                  label: 'Khách sạn',
                  onTap: () => context.push(AppRoutes.hotelSearch),
                ),
                const SizedBox(width: 6),
                _HeaderNavPill(
                  icon: Icons.business_outlined,
                  label: 'Về chúng tôi',
                  onTap: () => _showAboutModal(context),
                ),
                const SizedBox(width: 6),
                _HeaderNavPill(
                  icon: Icons.support_agent_outlined,
                  label: 'Liên hệ',
                  onTap: () => showSupportCenter(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flag_outlined, color: Color(0xFF003580)),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Về Avora Việt Nam',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Avora.com là nền tảng đặt phòng khách sạn & khu nghỉ dưỡng trực tuyến hàng đầu tại Việt Nam, mang đến mức giá minh bạch, ưu đãi thành viên Genius giảm đến 15% và dịch vụ chăm sóc khách hàng 24/7.',
          style: TextStyle(
            fontSize: 13.5,
            color: Color(0xFF4B5563),
            height: 1.5,
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF003580),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authNotifierProvider.notifier).signOut();
            },

            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasAvatar =>
      avatarUrl?.startsWith('https://') == true ||
      avatarUrl?.startsWith('http://') == true;

  String _initials(String value) {
    final name = value.trim();
    return name.isEmpty
        ? 'A'
        : String.fromCharCode(name.runes.first).toUpperCase();
  }
}

enum _HomeMenuAction { favorites, bookings, notifications, support }

enum _ProfileMenuAction { profile, signOut }

class _HeaderNavPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _HeaderNavPill({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
