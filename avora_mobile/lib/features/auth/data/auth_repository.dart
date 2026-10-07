import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_model.dart';

/// Provider cung cấp [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageProvider),
  );
});

// ─── Auth Repository ──────────────────────────────────────────────────────────

/// Repository xử lý tất cả network call liên quan đến Auth.
/// Chỉ chứa Data Logic, không chứa Business Logic.
class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthRepository({required Dio dio, required SecureStorageService storage})
      : _dio = dio,
        _storage = storage;

  // ── Sign In ────────────────────────────────────────────────────────────────

  /// Gọi `POST /api/auth/signin`.
  /// Nếu thành công, tự động lưu token vào secure storage.
  /// Throws [ApiException] nếu có lỗi.
  Future<SignInResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signin',
        data: {'email': email, 'password': password},
      );

      final Map<String, dynamic> rawJson = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      final apiResponse = ApiResponse.fromJson(
        rawJson,
        SignInResponse.fromJson,
      );

      if (apiResponse.data == null) {
        throw const ApiException(message: 'Không nhận được dữ liệu từ máy chủ.');
      }

      // Lưu token sau khi login thành công
      await _storage.saveToken(apiResponse.data!.token);

      return apiResponse.data!;
    } on DioException catch (e) {
      // Unwrap ApiException từ ErrorInterceptor
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Lỗi kết nối.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Lỗi xử lý dữ liệu: $e');
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────

  /// Gọi `POST /api/auth/signup`.
  /// Backend yêu cầu: email, password (>= 8 ký tự), full_name.
  /// Throws [ApiException] nếu có lỗi.
  Future<SignUpResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
        },
      );

      final Map<String, dynamic> rawJson = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      final apiResponse = ApiResponse.fromJson(
        rawJson,
        SignUpResponse.fromJson,
      );

      if (apiResponse.data == null) {
        throw const ApiException(message: 'Không nhận được dữ liệu từ máy chủ.');
      }

      return apiResponse.data!;
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Lỗi kết nối.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Lỗi xử lý dữ liệu: $e');
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────────

  /// Gọi `POST /api/auth/forgot-password`.
  /// Yêu cầu gửi link đặt lại mật khẩu về email.
  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      final Map<String, dynamic> rawJson = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      return rawJson['message']?.toString() ??
          'Đã gửi email kèm liên kết đặt lại mật khẩu. Vui lòng kiểm tra hộp thư của bạn.';
    } on DioException catch (e) {
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException(message: e.message ?? 'Lỗi kết nối.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(message: 'Lỗi xử lý dữ liệu: $e');
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  /// Xóa token khỏi secure storage (logout phía client).
  Future<void> signOut() async {
    await _storage.deleteToken();
  }
}
