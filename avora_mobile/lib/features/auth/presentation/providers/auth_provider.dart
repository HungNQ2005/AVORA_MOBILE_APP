import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_model.dart';
import '../../../../core/network/api_client.dart';

// ─── Auth State ───────────────────────────────────────────────────────────────

/// Sealed class mô tả 4 trạng thái của Auth flow.
sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Trạng thái ban đầu (chưa thực hiện hành động gì).
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Đang thực hiện request (loading spinner, disable buttons).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Đăng nhập thành công, chứa thông tin user.
final class AuthSuccess extends AuthState {
  final UserModel user;
  const AuthSuccess(this.user);
  @override
  List<Object?> get props => [user];
}

/// Đã đăng ký thành công (chưa login, cần verify email).
final class AuthSignUpSuccess extends AuthState {
  final String email;
  const AuthSignUpSuccess(this.email);
  @override
  List<Object?> get props => [email];
}

/// Có lỗi xảy ra (hiển thị Snackbar/Dialog).
final class AuthError extends AuthState {
  final String message;
  final String? code;

  const AuthError(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────

/// Provider chính quản lý toàn bộ Auth State.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

/// Notifier xử lý các hành động Auth: signIn, signUp, signOut.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthInitial());

  // ── Sign In ────────────────────────────────────────────────────────────────
  Future<void> signIn({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final result = await _repository.signIn(email: email, password: password);
      state = AuthSuccess(result.user);
    } on ApiException catch (e) {
      state = AuthError(e.message, code: e.code);
    } catch (e) {
      state = AuthError('Đã có lỗi không xác định: $e');
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      // Sau signup cần verify email → không tự chuyển sang AuthSuccess
      state = AuthSignUpSuccess(result.email);
    } on ApiException catch (e) {
      state = AuthError(e.message, code: e.code);
    } catch (e) {
      state = AuthError('Đã có lỗi không xác định: $e');
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthInitial();
  }

  /// Reset về Initial (dùng sau khi đã xử lý Error hoặc SignUpSuccess).
  void reset() => state = const AuthInitial();
}
