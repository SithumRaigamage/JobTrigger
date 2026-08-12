import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/credential/credentials_repository.dart';
import '../../domain/credential/jenkins_server.dart';
import '../models/credential/credential_dto.dart';

part 'credentials_repository_impl.g.dart';

class CredentialsRepositoryImpl implements CredentialsRepository {
  CredentialsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/credentials');
      final servers = response.data!
          .map(
            (json) =>
                CredentialDto.fromJson(json as Map<String, dynamic>).toDomain(),
          )
          .toList();
      return Ok(servers);
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<JenkinsServer, AppFailure>> add({
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/credentials',
        data: _body(
          serverName: serverName,
          jenkinsURL: jenkinsURL,
          username: username,
          secret: secret,
          paramToken: paramToken,
          isDefault: isDefault,
        ),
      );
      return Ok(CredentialDto.fromJson(response.data!).toDomain());
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<JenkinsServer, AppFailure>> update(
    String id, {
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/credentials/$id',
        data: _body(
          serverName: serverName,
          jenkinsURL: jenkinsURL,
          username: username,
          secret: secret,
          paramToken: paramToken,
          isDefault: isDefault,
        ),
      );
      return Ok(CredentialDto.fromJson(response.data!).toDomain());
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<void, AppFailure>> delete(String id) async {
    try {
      await _dio.delete<void>('/api/credentials/$id');
      return const Ok(null);
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<JenkinsServer, AppFailure>> switchActive(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/credentials/switch/$id',
      );
      return Ok(CredentialDto.fromJson(response.data!).toDomain());
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  Map<String, dynamic> _body({
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    required bool isDefault,
  }) => {
    'serverName': serverName,
    'jenkinsURL': jenkinsURL,
    'username': username,
    'password': secret,
    'paramToken': paramToken,
    'isDefault': isDefault,
  };
}

@riverpod
CredentialsRepository credentialsRepository(Ref ref) =>
    CredentialsRepositoryImpl(ref.watch(dioBackendProvider));
