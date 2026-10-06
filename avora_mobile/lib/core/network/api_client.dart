import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';

/// Base URL của Avora Backend (port 5000).
/// Dùng 10.0.2.2 khi chạy trên Android Emulator (ánh xạ sang localhost máy host).
const String _baseUrl = 'http://10.0.2.2:5000/api';

/// Provider cung cấp Dio instance đã được cấu hình sẵn.
final apiClientProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return _buildDio(secureStorage);
});

/// Khởi tạo và cấu hình Dio với BaseURL + Interceptors.
Dio _buildDio(SecureStorageService secureStorage) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Gắn interceptors
  dio.interceptors.addAll([
    _AuthInterceptor(secureStorage),
    _ErrorInterceptor(),
    if (const bool.fromEnvironment('dart.vm.product') == false)
      LogInterceptor(requestBody: true, responseBody: true),
  ]);

  return dio;
}

// ─── Auth Interceptor ─────────────────────────────────────────────────────────
/// Tự động gắn Bearer Token vào header của mỗi request.
class _AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ─── Error Interceptor ────────────────────────────────────────────────────────
/// Bắt lỗi HTTP tập trung, chuyển đổi sang [ApiException] với thông báo thân thiện.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    final dynamic responseData = response?.data;

    String? rawMessage;
    if (responseData is Map) {
      rawMessage = responseData['message']?.toString();
    }

    final friendlyMessage = _mapErrorMessage(rawMessage, err.type);

    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: response,
        type: err.type,
        error: ApiException(
          message: friendlyMessage,
          statusCode: response?.statusCode,
          code: rawMessage,
        ),
      ),
    );
  }

  String _mapErrorMessage(String? serverMessage, DioExceptionType type) {
    if (serverMessage != null && serverMessage.trim().isNotEmpty) {
      final trimmed = serverMessage.trim();
      final upper = trimmed.toUpperCase();

      if (upper == 'ACCOUNT_DEACTIVATED') {
        return 'Tài khoản của bạn đã bị vô hiệu hóa. Vui lòng liên hệ Quản trị viên để được hỗ trợ mở lại.';
      }
      if (upper == 'ACCOUNT_VERIFYING') {
        return 'Tài khoản chưa được kích hoạt email. Vui lòng kiểm tra hộp thư để nhấn liên kết kích hoạt trước khi đăng nhập.';
      }
      if (trimmed == 'Invalid email or password.') {
        return 'Địa chỉ email hoặc mật khẩu không chính xác.';
      }
      if (trimmed == 'User not found.') {
        return 'Không tìm thấy tài khoản người dùng.';
      }
      if (trimmed == 'email and password are required.') {
        return 'Vui lòng nhập đầy đủ email và mật khẩu.';
      }
      if (trimmed == 'email, password, and full_name are required.') {
        return 'Vui lòng nhập đầy đủ email, mật khẩu và họ tên.';
      }
      if (trimmed == 'Password must be at least 8 characters.') {
        return 'Mật khẩu phải có tối thiểu 8 ký tự.';
      }
      if (trimmed.contains('already exists')) {
        return 'Email này đã được sử dụng. Vui lòng thử một email khác.';
      }

      return trimmed;
    }

    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout =>
        'Kết nối quá thời gian. Vui lòng kiểm tra kết nối mạng và thử lại.',
      DioExceptionType.connectionError =>
        'Không thể kết nối đến máy chủ. Kiểm tra mạng hoặc máy chủ.',
      _ => 'Đã có lỗi xảy ra. Vui lòng thử lại.',
    };
  }
}

// ─── Custom Exception ─────────────────────────────────────────────────────────
/// Exception chuẩn cho mọi lỗi API trong ứng dụng.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() => 'ApiException($statusCode, code: $code): $message';
}
