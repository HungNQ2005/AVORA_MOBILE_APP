import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:avora_mobile/features/auth/presentation/screens/signup_screen.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:avora_mobile/features/auth/data/auth_repository.dart';
import 'package:avora_mobile/core/theme/app_theme.dart';
import 'package:avora_mobile/core/storage/secure_storage.dart';

class _FakeSecureStorage extends SecureStorageService {
  @override
  Future<String?> getToken() async => null;
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> deleteToken() async {}
  @override
  Future<bool> hasToken() async => false;
}

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier()
      : super(
          AuthRepository(
            dio: Dio(),
            storage: _FakeSecureStorage(),
          ),
        );

  void emitSignUpSuccess(String email) {
    state = AuthSignUpSuccess(email);
  }
}

void main() {
  testWidgets(
    '🎉 Đăng ký thành công → hiển thị Popup Dialog hướng dẫn kích hoạt email',
    (tester) async {
      final fakeNotifier = _MockAuthNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((_) => fakeNotifier),
          ],
          child: MaterialApp(
            theme: AvoraTheme.lightTheme,
            home: const SignupScreen(),
          ),
        ),
      );

      // Emit AuthSignUpSuccess
      fakeNotifier.emitSignUpSuccess('test@example.com');
      await tester.pumpAndSettle();

      // Assert popup xuất hiện
      expect(find.text('Đăng ký tài khoản thành công!'), findsOneWidget);
      expect(find.textContaining('test@example.com', findRichText: true), findsOneWidget);
      expect(find.text('Đến trang Đăng nhập'), findsOneWidget);
    },
  );
}
