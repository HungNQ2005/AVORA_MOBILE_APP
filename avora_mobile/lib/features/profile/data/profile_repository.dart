import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avora_mobile/core/network/api_client.dart';
import 'package:avora_mobile/features/auth/data/auth_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(dio: ref.watch(apiClientProvider));
});

class ProfileRepository {
  final Dio _dio;

  ProfileRepository({required Dio dio}) : _dio = dio;

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/account/profile');
      return _parseUser(response.data);
    } on DioException catch (error) {
      throw _toApiException(error, 'Không thể tải hồ sơ. Vui lòng thử lại.');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: 'Lỗi xử lý dữ liệu hồ sơ: $error');
    }
  }

  Future<UserModel> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    try {
      final response = await _dio.put(
        '/account/profile',
        data: {'full_name': fullName, 'phone': phone},
      );
      return _parseUser(response.data);
    } on DioException catch (error) {
      throw _toApiException(error, 'Không thể cập nhật hồ sơ. Vui lòng thử lại.');
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: 'Lỗi xử lý dữ liệu hồ sơ: $error');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.put(
        '/account/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      final body = _asMap(response.data);
      if (body['status'] != 'success' && body['success'] != true) {
        throw ApiException(
          message: body['message']?.toString() ??
              'Không thể cập nhật mật khẩu. Vui lòng thử lại.',
        );
      }
    } on DioException catch (error) {
      throw _toApiException(
        error,
        'Không thể cập nhật mật khẩu. Vui lòng thử lại.',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: 'Lỗi xử lý dữ liệu bảo mật: $error');
    }
  }

  Future<void> requestDeactivateOtp() async {
    try {
      final response = await _dio.post('/account/deactivate/request-otp');
      final body = _asMap(response.data);
      if (body['status'] != 'success' && body['success'] != true) {
        throw ApiException(
          message: body['message']?.toString() ??
              'Không thể gửi mã xác thực. Vui lòng thử lại.',
        );
      }
    } on DioException catch (error) {
      throw _toApiException(
        error,
        'Không thể gửi mã xác thực. Vui lòng thử lại.',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: 'Lỗi gửi mã xác thực: $error');
    }
  }

  Future<void> deactivateAccount({required String otp}) async {
    try {
      final response = await _dio.post(
        '/account/deactivate',
        data: {'otp': otp},
      );
      final body = _asMap(response.data);
      if (body['status'] != 'success' && body['success'] != true) {
        throw ApiException(
          message: body['message']?.toString() ??
              'Không thể hủy kích hoạt tài khoản. Vui lòng thử lại.',
        );
      }
    } on DioException catch (error) {
      throw _toApiException(
        error,
        'Không thể hủy kích hoạt tài khoản. Vui lòng thử lại.',
      );
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: 'Lỗi hủy kích hoạt tài khoản: $error');
    }
  }

  UserModel _parseUser(dynamic responseData) {
    final body = _asMap(responseData);
    if (body['status'] != 'success' && body['success'] != true) {
      throw ApiException(
        message: body['message']?.toString() ??
            'Máy chủ không thể cung cấp thông tin hồ sơ.',
      );
    }
    final data = body['data'];
    if (data is! Map) {
      throw const ApiException(
        message: 'Dữ liệu hồ sơ từ máy chủ không đúng định dạng.',
      );
    }
    return UserModel.fromJson(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const ApiException(
      message: 'Phản hồi từ máy chủ không đúng định dạng.',
    );
  }

  ApiException _toApiException(DioException error, String fallback) {
    if (error.error is ApiException) return error.error as ApiException;
    return ApiException(message: error.message ?? fallback);
  }
}
