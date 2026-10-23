import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/auth/auth_repository.dart';
import '../models/auth/user_dto.dart';

part 'auth_repository_impl.g.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<AuthSession, AppFailure>> signup({
    required String email,
    required String password,
  }) => _authenticate('/api/auth/signup', email: email, password: password);

  @override
  Future<Result<AuthSession, AppFailure>> login({
    required String email,
    required String password,
  }) => _authenticate('/api/auth/login', email: email, password: password);

  Future<Result<AuthSession, AppFailure>> _authenticate(
    String path, {
    required String email,
    required String password,
  }) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: {'email': email, 'password': password},
    );
    return _session(response.data!);
  });

  @override
  Future<Result<void, AppFailure>> logoutEverywhere() =>
      _guard(() => _dio.post<void>('/api/auth/logout-all'));

  @override
  Future<Result<AuthSession, AppFailure>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    return _session(response.data!);
  });

  @override
  Future<Result<void, AppFailure>> deleteAccount({required String password}) =>
      _guard(
        () => _dio.delete<void>(
          '/api/auth/account',
          data: {'password': password},
        ),
      );

  static AuthSession _session(Map<String, dynamic> json) {
    final dto = AuthResponseDto.fromJson(json);
    return (
      user: dto.user.toDomain(),
      token: dto.token,
      refreshToken: dto.refreshToken,
    );
  }

  /// [guardRequest], plus the backend's own 400 explanations (AUD-65).
  static Future<Result<T, AppFailure>> _guard<T>(
    Future<T> Function() request,
  ) => guardRequest(request, recover: _rejected);

  static Result<T, AppFailure>? _rejected<T>(DioException exception) {
    if (exception.response?.statusCode != 400) return null;
    if (exception.response?.data case {
      'message': final String message,
    } when message.isNotEmpty) {
      return Err(RejectedRequestFailure(message));
    }
    return null;
  }
}

@riverpod
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(dioBackendProvider));
