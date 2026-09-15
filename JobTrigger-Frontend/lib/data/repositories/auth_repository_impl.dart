import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
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
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'email': email, 'password': password},
      );
      final dto = AuthResponseDto.fromJson(response.data!);
      return Ok((user: dto.user.toDomain(), token: dto.token));
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }
}

@riverpod
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(dioBackendProvider));
