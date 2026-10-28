import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avora_mobile/features/auth/data/auth_model.dart';
import 'package:avora_mobile/features/profile/data/profile_repository.dart';
import 'package:avora_mobile/features/profile/presentation/screens/profile_screen.dart';

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository() : super(dio: Dio());

  UserModel profile = const UserModel(
    userId: 'user-1',
    email: 'user@example.com',
    fullName: 'Avora Guest',
    phone: '0905000000',
    role: 'CUS',
    accountStatus: 'ACTIVE',
  );
  String? changedCurrentPassword;
  String? changedNewPassword;

  @override
  Future<UserModel> getProfile() async => profile;

  @override
  Future<UserModel> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    profile = UserModel(
      userId: profile.userId,
      email: profile.email,
      fullName: fullName,
      phone: phone,
      role: profile.role,
      accountStatus: profile.accountStatus,
    );
    return profile;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changedCurrentPassword = currentPassword;
    changedNewPassword = newPassword;
  }
}

void main() {
  void useMobileViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('loads profile details and provides profile/security tabs', (
    tester,
  ) async {
    useMobileViewport(tester);
    final repository = _FakeProfileRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hồ sơ của tôi'), findsOneWidget);
    expect(find.text('Avora Guest'), findsWidgets);
    expect(find.text('user@example.com'), findsWidgets);
    expect(find.text('Thông tin cá nhân'), findsOneWidget);

    await tester.tap(find.text('Bảo mật'));
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu hiện tại'), findsOneWidget);
    expect(find.text('Cập nhật mật khẩu'), findsOneWidget);
  });

  testWidgets('validates and updates profile fields', (tester) async {
    useMobileViewport(tester);
    final repository = _FakeProfileRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Chỉnh sửa thông tin'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Updated Guest');
    await tester.enterText(fields.at(1), '0912345678');
    await tester.ensureVisible(find.text('Lưu thay đổi'));
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(repository.profile.fullName, 'Updated Guest');
    expect(repository.profile.phone, '0912345678');
    expect(find.text('Cập nhật thông tin thành công.'), findsOneWidget);
  });

  testWidgets('validates password confirmation before submitting', (
    tester,
  ) async {
    useMobileViewport(tester);
    final repository = _FakeProfileRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bảo mật'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'old-password');
    await tester.enterText(fields.at(1), 'new-password');
    await tester.enterText(fields.at(2), 'different-password');
    await tester.ensureVisible(find.text('Cập nhật mật khẩu'));
    await tester.tap(find.text('Cập nhật mật khẩu'));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu xác nhận không khớp.'), findsOneWidget);
    expect(repository.changedCurrentPassword, isNull);
  });

  testWidgets('displays Mã Khuyến Mãi button between Yêu thích and Đặt chỗ', (
    tester,
  ) async {
    useMobileViewport(tester);
    final repository = _FakeProfileRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final favoriteFinder = find.text('Yêu thích');
    final voucherFinder = find.text('Mã Khuyến Mãi');
    final bookingFinder = find.text('Đặt chỗ');

    expect(favoriteFinder, findsOneWidget);
    expect(voucherFinder, findsOneWidget);
    expect(bookingFinder, findsOneWidget);

    // Verify ordering in layout: Yêu thích (left) -> Mã Khuyến Mãi (middle) -> Đặt chỗ (right)
    final favX = tester.getTopLeft(favoriteFinder).dx;
    final voucherX = tester.getTopLeft(voucherFinder).dx;
    final bookingX = tester.getTopLeft(bookingFinder).dx;

    expect(favX < voucherX, isTrue);
    expect(voucherX < bookingX, isTrue);
  });
}
