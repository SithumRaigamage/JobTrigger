import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/auth/password_reset_repository.dart';

part 'password_reset_repository_impl.g.dart';

class PasswordResetRepositoryImpl implements PasswordResetRepository {
  PasswordResetRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<void, AppFailure>> requestReset({required String email}) =>
      _guard(
        () => _dio.post<void>(
          '/api/auth/password-reset/request',
          data: {'email': email},
        ),
      );

  @override
  Future<Result<void, AppFailure>> confirmReset({
    required String token,
    required String newPassword,
  }) => _guard(
    () => _dio.post<void>(
      '/api/auth/password-reset/confirm',
      data: {'token': token, 'newPassword': newPassword},
    ),
  );

  /// [guardRequest], plus the backend's own 400 explanations (AUD-65) —
  /// "This reset link is invalid or has expired…", password rules.
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
PasswordResetRepository passwordResetRepository(Ref ref) =>
    PasswordResetRepositoryImpl(ref.watch(dioBackendProvider));
