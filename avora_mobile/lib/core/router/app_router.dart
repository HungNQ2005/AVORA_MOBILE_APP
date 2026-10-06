import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

// ─── Route Paths ──────────────────────────────────────────────────────────────
class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home'; // Placeholder cho màn hình chính
}

/// Provider cung cấp GoRouter đã cấu hình redirect theo trạng thái auth.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isLoggedIn = authState is AuthSuccess;
      final isAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;

      // Nếu đã login và đang ở auth route → chuyển về Home
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;
      // Nếu chưa login và không ở auth route → chuyển về Login
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      return null; // Không redirect
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const _HomePlaceholder(),
      ),
    ],
  );
});

// ─── Placeholder Home Screen ──────────────────────────────────────────────────
/// Màn hình Home tạm thời, sẽ được thay thế bởi feature tiếp theo.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avora')),
      body: const Center(
        child: Text(
          '🎉 Đăng nhập thành công!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
