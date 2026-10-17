import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/core/router/app_router.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';

import '../providers/home_provider.dart';
import 'home_helpers.dart';

/// AppBar của màn hình Home chuyển thể chuẩn từ Header 2 tầng của Avora Web:
/// - Tầng 1: Logo AVORA + Badge VIỆT NAM + Lời chào + VND + Hỗ trợ 24/7 + Yêu thích + Thông báo + Đăng xuất
/// - Tầng 2: Các tab điều hướng dạng Capsule Pill (Trang chủ, Khách sạn, Về chúng tôi, Liên hệ)
class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String userName;

  const HomeAppBar({
    super.key,
    required this.userName,
  });

  @override
  Size get preferredSize => const Size.fromHeight(104);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          ),
          const SizedBox(height: 2),
          Text(
            'Xin chào, $userName',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          InkWell(
            key: const Key('open_profile_button'),
            onTap: () => context.push('/profile'),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'Xin chào, $userName',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.account_circle_outlined,
                    color: Color(0xFFE2E8F0),
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.headset_mic_outlined, color: Colors.white, size: 21),
          tooltip: 'Hỗ trợ 24/7',
          onPressed: () => _showSupportDialog(context),
        ),
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
        IconButton(

          icon: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
          key: const Key('my_booking_button'),
          tooltip: 'Đặt chỗ của tôi',
          onPressed: () => context.push('/my-bookings'),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          tooltip: 'Thông báo',
          onPressed: () =>
              showHomeSnackBar(context, 'Bạn không có thông báo mới.'),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white, size: 20),
          tooltip: 'Đăng xuất',
          onPressed: () => _confirmSignOut(context, ref),
        ),
      ],
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
                  onTap: () => _showSupportDialog(context),
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
          style: TextStyle(fontSize: 13.5, color: Color(0xFF4B5563), height: 1.5),
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

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.headset_mic, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tổng đài Hỗ trợ 24/7',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đội ngũ CSKH Avora Việt Nam luôn túc trực 24/7 để hỗ trợ đặt phòng và hoàn hủy.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF4B5563), height: 1.45),
            ),
            SizedBox(height: 12),
            Text(
              '📞 Hotline: 1900 6868 (Miễn phí)\n✉️ Email: support@avora.vn',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF003580),
                height: 1.5,
              ),
            ),
          ],
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
            child: const Text('Đã hiểu'),
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
}

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
