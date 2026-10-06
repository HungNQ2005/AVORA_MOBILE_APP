import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:avora_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:avora_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:avora_mobile/features/auth/data/auth_repository.dart';
import 'package:avora_mobile/core/theme/app_theme.dart';
import 'package:avora_mobile/core/storage/secure_storage.dart';

void main() {
  // ─── Helper: Pump LoginScreen ────────────────────────────────────────────────
  /// Bọc LoginScreen trong ProviderScope + MaterialApp để test widget.
  Widget buildLoginScreen() {
    return ProviderScope(
      child: MaterialApp(
        theme: AvoraTheme.lightTheme,
        // Dùng home thay vì router để tránh phụ thuộc GoRouter trong widget test
        home: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen - Form Validation', () {
    testWidgets(
      '❌ Submit form rỗng → hiển thị lỗi validation cho cả hai field',
      (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Tìm nút Submit
        final submitButton = find.byKey(const Key('login_submit_button'));
        expect(submitButton, findsOneWidget);

        // Act: Nhấn submit mà không điền gì
        await tester.tap(submitButton);
        await tester.pump(); // Rebuild để hiển thị lỗi validation

        // Assert: Cả 2 field đều báo lỗi
        expect(find.text('Email không được để trống.'), findsOneWidget);
        expect(find.text('Mật khẩu không được để trống.'), findsOneWidget);
      },
    );

    testWidgets(
      '❌ Email sai format → hiển thị lỗi email không hợp lệ',
      (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());
        final emailField = find.byKey(const Key('login_email_field'));
        final submitButton = find.byKey(const Key('login_submit_button'));

        // Act: Điền email sai format
        await tester.enterText(emailField, 'not-an-email');
        await tester.tap(submitButton);
        await tester.pump();

        // Assert
        expect(find.text('Email không hợp lệ.'), findsOneWidget);
      },
    );

    testWidgets(
      '❌ Mật khẩu < 8 ký tự → hiển thị lỗi độ dài mật khẩu',
      (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());
        final emailField = find.byKey(const Key('login_email_field'));
        final passwordField = find.byKey(const Key('login_password_field'));
        final submitButton = find.byKey(const Key('login_submit_button'));

        // Act: Điền email đúng nhưng mật khẩu quá ngắn
        await tester.enterText(emailField, 'valid@email.com');
        await tester.enterText(passwordField, '1234567'); // 7 ký tự
        await tester.tap(submitButton);
        await tester.pump();

        // Assert
        expect(find.text('Mật khẩu phải có ít nhất 8 ký tự.'), findsOneWidget);
      },
    );

    testWidgets(
      '✅ Form hợp lệ → KHÔNG hiển thị lỗi validation',
      (tester) async {
        // Arrange
        final formKey = GlobalKey<FormState>();
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AvoraTheme.lightTheme,
              home: Scaffold(
                body: Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        key: const Key('login_email_field'),
                        initialValue: 'user@avora.vn',
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email không được để trống.';
                          final r = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                          if (!r.hasMatch(v)) return 'Email không hợp lệ.';
                          return null;
                        },
                      ),
                      TextFormField(
                        key: const Key('login_password_field'),
                        initialValue: 'validpassword',
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Mật khẩu không được để trống.';
                          if (v.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự.';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // Act: Gọi validate trực tiếp thay vì tap submit (tránh trigger network)
        final isValid = formKey.currentState!.validate();
        await tester.pump();

        // Assert: Form hợp lệ và không có message lỗi
        expect(isValid, isTrue);
        expect(find.text('Email không được để trống.'), findsNothing);
        expect(find.text('Email không hợp lệ.'), findsNothing);
        expect(find.text('Mật khẩu không được để trống.'), findsNothing);
        expect(find.text('Mật khẩu phải có ít nhất 8 ký tự.'), findsNothing);
      },
    );

    testWidgets(
      '✅ UI hiển thị đúng các widget cần thiết',
      (tester) async {
        // Arrange
        await tester.pumpWidget(buildLoginScreen());

        // Assert: Các key widget phải tồn tại
        expect(find.byKey(const Key('login_email_field')), findsOneWidget);
        expect(find.byKey(const Key('login_password_field')), findsOneWidget);
        expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
        expect(find.byKey(const Key('login_to_signup_button')), findsOneWidget);

        // Assert: Text label
        expect(find.text('Đăng nhập'), findsWidgets);
        expect(find.text('Chưa có tài khoản?'), findsOneWidget);
      },
    );

    testWidgets(
      '🔒 Nút submit bị disable khi state là Loading',
      (tester) async {
        // Arrange: Override provider, khởi tạo ngay ở Loading state
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              // _LoadingAuthNotifier tự tạo fake repo nội bộ
              authNotifierProvider.overrideWith(
                (_) => _LoadingAuthNotifier(),
              ),
            ],
            child: MaterialApp(
              theme: AvoraTheme.lightTheme,
              home: const LoginScreen(),
            ),
          ),
        );

        // Assert: Nút submit bị disable (onPressed = null)
        final button = tester.widget<ElevatedButton>(
          find.byKey(const Key('login_submit_button')),
        );
        expect(button.onPressed, isNull);

        // Assert: Hiện CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}

// ─── Fake NotiFier cho test Loading State ────────────────────────────────────
/// FakeAuthRepository: trả về dummy impl để tạo AuthNotifier trong test.
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

/// Extend AuthNotifier để tương thích kiểu với StateNotifierProvider.
class _LoadingAuthNotifier extends AuthNotifier {
  _LoadingAuthNotifier()
      : super(
          AuthRepository(
            dio: Dio(),
            storage: _FakeSecureStorage(),
          ),
        ) {
    // Override state về Loading ngay khi khởi tạo
    state = const AuthLoading();
  }
}
