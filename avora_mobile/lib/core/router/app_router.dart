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

/// Notifier làm cầu nối Listenable giữa Riverpod và GoRouter.
/// Chỉ notify GoRouter khi trạng thái đăng nhập thực sự thay đổi (giữa đã login và chưa login),
/// tránh việc khởi tạo lại GoRouter làm hủy hoại Navigator/Dialog/Modal.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isLoggedIn = false;

  RouterNotifier(this._ref) {
    _isLoggedIn = _ref.read(authNotifierProvider) is AuthSuccess;

    _ref.listen<AuthState>(
      authNotifierProvider,
      (previous, next) {
        final newIsLoggedIn = next is AuthSuccess;
        if (_isLoggedIn != newIsLoggedIn) {
          _isLoggedIn = newIsLoggedIn;
          notifyListeners();
        }
      },
    );
  }

  bool get isLoggedIn => _isLoggedIn;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Provider cung cấp GoRouter singleton ổn định, không bị recreate khi có popup/loading.
final routerProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  // ref.read (KHÔNG phải ref.watch) để provider KHÔNG rebuild khi notifier thay đổi.
  // GoRouter tự refresh thông qua refreshListenable mà không cần tạo lại instance.
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = notifier.isLoggedIn;
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
