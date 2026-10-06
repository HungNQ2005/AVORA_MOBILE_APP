import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:avora_mobile/features/auth/data/auth_model.dart';
import 'package:avora_mobile/features/auth/data/auth_repository.dart';
import 'package:avora_mobile/core/storage/secure_storage.dart';
import 'package:avora_mobile/core/network/api_client.dart';

// Chạy lệnh này để sinh mock: dart run build_runner build
@GenerateMocks([Dio, SecureStorageService])
import 'auth_repository_test.mocks.dart';

void main() {
  late AuthRepository repository;
  late MockDio mockDio;
  late MockSecureStorageService mockStorage;

  setUp(() {
    mockDio = MockDio();
    mockStorage = MockSecureStorageService();
    repository = AuthRepository(dio: mockDio, storage: mockStorage);
  });

  // ─── signIn Tests ──────────────────────────────────────────────────────────
  group('AuthRepository.signIn()', () {
    const testEmail = 'test@avora.vn';
    const testPassword = 'password123';
    const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test';

    final successResponseData = {
      'success': true,
      'message': 'Signed in successfully.',
      'data': {
        'token': testToken,
        'user': {
          'user_id': 'uuid-001',
          'email': testEmail,
          'full_name': 'Avora Tester',
          'phone': null,
          'role': 'customer',
        },
      },
    };

    test('✅ signIn thành công → trả về SignInResponse và lưu token', () async {
      // Arrange
      when(
        mockDio.post('/auth/signin', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          data: successResponseData,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/signin'),
        ),
      );
      when(mockStorage.saveToken(testToken)).thenAnswer((_) async {});

      // Act
      final result = await repository.signIn(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result, isA<SignInResponse>());
      expect(result.token, equals(testToken));
      expect(result.user.email, equals(testEmail));
      expect(result.user.userId, equals('uuid-001'));

      // Verify token được lưu
      verify(mockStorage.saveToken(testToken)).called(1);
    });

    test('✅ signIn thành công với format backend thật (status: "success", role_code_name)', () async {
      final backendRealFormat = {
        'status': 'success',
        'message': 'Signed in successfully.',
        'data': {
          'token': testToken,
          'user': {
            'user_id': '967ff82e-0bd6-4157-a63f-f6886022d6f6',
            'email': 'hungnq@example.com',
            'full_name': 'Nguyen Quoc Hung',
            'phone': '0333833081',
            'role_cd': '2',
            'account_status': 'ACTIVE',
            'avatar_url': null,
            'role_code_name': 'CUS',
          },
        },
      };

      when(
        mockDio.post('/auth/signin', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          data: backendRealFormat,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/signin'),
        ),
      );
      when(mockStorage.saveToken(testToken)).thenAnswer((_) async {});

      final result = await repository.signIn(
        email: 'hungnq@example.com',
        password: testPassword,
      );

      expect(result.token, equals(testToken));
      expect(result.user.email, equals('hungnq@example.com'));
      expect(result.user.role, equals('CUS'));
      expect(result.user.accountStatus, equals('ACTIVE'));
      verify(mockStorage.saveToken(testToken)).called(1);
    });

    test('❌ signIn sai mật khẩu → throw ApiException với message từ server',
        () async {
      // Arrange
      when(
        mockDio.post('/auth/signin', data: anyNamed('data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/signin'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            data: {'success': false, 'message': 'Sai email hoặc mật khẩu.'},
            requestOptions: RequestOptions(path: '/auth/signin'),
          ),
          error: const ApiException(
            message: 'Sai email hoặc mật khẩu.',
            statusCode: 401,
          ),
        ),
      );

      // Act & Assert
      expect(
        () => repository.signIn(email: testEmail, password: 'wrongpass'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Sai email hoặc mật khẩu.',
          ),
        ),
      );

      // Verify token KHÔNG được lưu
      verifyNever(mockStorage.saveToken(any));
    });

    test('❌ signIn mất kết nối → throw ApiException timeout', () async {
      // Arrange
      when(
        mockDio.post('/auth/signin', data: anyNamed('data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/signin'),
          type: DioExceptionType.connectionTimeout,
          error: const ApiException(
            message: 'Kết nối quá thời gian. Vui lòng thử lại.',
          ),
        ),
      );

      // Act & Assert
      expect(
        () => repository.signIn(email: testEmail, password: testPassword),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ─── signUp Tests ──────────────────────────────────────────────────────────
  group('AuthRepository.signUp()', () {
    const testEmail = 'newuser@avora.vn';
    const testPassword = 'securepass';
    const testFullName = 'Nguyen Van A';

    final successResponseData = {
      'success': true,
      'message': 'Account created successfully. Please check your email.',
      'data': {
        'user_id': 'uuid-002',
        'email': testEmail,
      },
    };

    test('✅ signUp thành công → trả về SignUpResponse', () async {
      // Arrange
      when(
        mockDio.post('/auth/signup', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          data: successResponseData,
          statusCode: 201,
          requestOptions: RequestOptions(path: '/auth/signup'),
        ),
      );

      // Act
      final result = await repository.signUp(
        email: testEmail,
        password: testPassword,
        fullName: testFullName,
      );

      // Assert
      expect(result, isA<SignUpResponse>());
      expect(result.email, equals(testEmail));
      expect(result.userId, equals('uuid-002'));

      // Verify KHÔNG lưu token (cần verify email trước)
      verifyNever(mockStorage.saveToken(any));
    });

    test('❌ signUp email đã tồn tại → throw ApiException 409', () async {
      // Arrange
      when(
        mockDio.post('/auth/signup', data: anyNamed('data')),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/signup'),
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 409,
            data: {'success': false, 'message': 'Email đã được sử dụng.'},
            requestOptions: RequestOptions(path: '/auth/signup'),
          ),
          error: const ApiException(
            message: 'Email đã được sử dụng.',
            statusCode: 409,
          ),
        ),
      );

      // Act & Assert
      expect(
        () => repository.signUp(
          email: testEmail,
          password: testPassword,
          fullName: testFullName,
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ─── signOut Tests ─────────────────────────────────────────────────────────
  group('AuthRepository.signOut()', () {
    test('✅ signOut → xóa token khỏi storage', () async {
      // Arrange
      when(mockStorage.deleteToken()).thenAnswer((_) async {});

      // Act
      await repository.signOut();

      // Assert
      verify(mockStorage.deleteToken()).called(1);
    });
  });
}
