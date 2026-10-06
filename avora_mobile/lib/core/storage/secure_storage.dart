import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provider cung cấp [SecureStorageService].
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// ─── Key Constants ────────────────────────────────────────────────────────────
const _kTokenKey = 'avora_jwt_token';

/// Wrapper quanh [FlutterSecureStorage] để quản lý JWT Token cục bộ.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          // Cấu hình Android: dùng EncryptedSharedPreferences
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  /// Lưu JWT token vào secure storage.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _kTokenKey, value: token);
  }

  /// Đọc JWT token. Trả về null nếu chưa có.
  Future<String?> getToken() async {
    return await _storage.read(key: _kTokenKey);
  }

  /// Xóa JWT token (logout).
  Future<void> deleteToken() async {
    await _storage.delete(key: _kTokenKey);
  }

  /// Kiểm tra đã có token hay chưa.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
