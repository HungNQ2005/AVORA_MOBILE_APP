import 'package:equatable/equatable.dart';

// ─── Sign In Response ─────────────────────────────────────────────────────────

/// Ánh xạ response từ `POST /api/auth/signin`.
/// Backend trả về: { token: "...", user: { user_id, email, full_name, ... } }
class SignInResponse extends Equatable {
  final String token;
  final UserModel user;

  const SignInResponse({required this.token, required this.user});

  factory SignInResponse.fromJson(Map<String, dynamic> json) {
    return SignInResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [token, user];
}

// ─── Sign Up Response ─────────────────────────────────────────────────────────

/// Ánh xạ response từ `POST /api/auth/signup`.
/// Backend trả về: { user_id: "...", email: "..." }
class SignUpResponse extends Equatable {
  final String userId;
  final String email;

  const SignUpResponse({required this.userId, required this.email});

  factory SignUpResponse.fromJson(Map<String, dynamic> json) {
    return SignUpResponse(
      userId: json['user_id'] as String,
      email: json['email'] as String,
    );
  }

  @override
  List<Object?> get props => [userId, email];
}

class UserModel extends Equatable {
  final String userId;
  final String email;
  final String? fullName;
  final String? phone;
  final String? role;
  final String? accountStatus;
  final String? avatarUrl;

  const UserModel({
    required this.userId,
    required this.email,
    this.fullName,
    this.phone,
    this.role,
    this.accountStatus,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      role: (json['role_code_name'] ?? json['role'] ?? json['role_cd'])?.toString(),
      accountStatus: json['account_status'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': role,
        'account_status': accountStatus,
        'avatar_url': avatarUrl,
      };

  @override
  List<Object?> get props => [
        userId,
        email,
        fullName,
        phone,
        role,
        accountStatus,
        avatarUrl,
      ];
}

// ─── Standard API Wrapper ─────────────────────────────────────────────────────

/// Wrapper chuẩn cho response từ Backend (hỗ trợ cả status: "success" và success: true).
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final status = json['status'];
    final successVal = json['success'];
    final isSuccess = status == 'success' || successVal == true;

    return ApiResponse<T>(
      success: isSuccess,
      message: (json['message'] ?? '').toString(),
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? fromJsonT(json['data'] as Map<String, dynamic>)
          : (json['data'] != null && json['data'] is Map
              ? fromJsonT(Map<String, dynamic>.from(json['data'] as Map))
              : null),
    );
  }
}

