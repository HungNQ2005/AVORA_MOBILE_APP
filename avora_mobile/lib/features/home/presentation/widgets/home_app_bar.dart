import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import 'home_helpers.dart';

/// AppBar của màn hình Home: logo, lời chào, thông báo và đăng xuất.
class HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String userName;

  const HomeAppBar({super.key, required this.userName});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: const Color(0xFF003580),
      elevation: 0,
      centerTitle: false,
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
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'OTA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Xin chào, $userName',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_awesome, color: Color(0xFFFBBF24)),
          tooltip: 'Trợ lý AI',
          onPressed: () => context.push('/ai-chat'),
        ),
        Consumer(
          builder: (context, ref, _) {
            final count =
                ref.watch(homeProvider.select((s) => s.favorites.length));
            return IconButton(
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count', style: const TextStyle(fontSize: 10)),
                backgroundColor: const Color(0xFFEF4444),
                child: const Icon(Icons.favorite_rounded, color: Colors.white),
              ),
              tooltip: 'Yêu thích',
              onPressed: () => context.push('/favorites'),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          tooltip: 'Thông báo',
          onPressed: () =>
              showHomeSnackBar(context, 'Bạn không có thông báo mới.'),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Đăng xuất',
          onPressed: () => _confirmSignOut(context, ref),
        ),
      ],
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authNotifierProvider.notifier).signOut();
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
