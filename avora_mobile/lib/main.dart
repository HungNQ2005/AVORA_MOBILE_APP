import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  // Đảm bảo Flutter binding được khởi tạo trước khi dùng plugin
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // Bọc toàn bộ app trong ProviderScope để Riverpod hoạt động
    const ProviderScope(child: AvoraApp()),
  );
}

/// Root widget của ứng dụng Avora Mobile.
class AvoraApp extends ConsumerWidget {
  const AvoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Đọc GoRouter từ Provider (reactive với authState)
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Avora',
      debugShowCheckedModeBanner: false,

      // Material 3 Theme
      theme: AvoraTheme.lightTheme,

      // GoRouter config
      routerConfig: router,
    );
  }
}
