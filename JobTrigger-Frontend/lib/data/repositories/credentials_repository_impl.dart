import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/credential/credentials_repository.dart';
import '../../domain/credential/jenkins_server.dart';
import '../credentials/credential_secrets.dart';
import '../models/credential/credential_dto.dart';

import '../demo/demo_account_repositories.dart';
import '../demo/demo_mode_notifier.dart';
part 'credentials_repository_impl.g.dart';

class CredentialsRepositoryImpl implements CredentialsRepository {
  CredentialsRepositoryImpl(this._dio, [this._secrets]);

  final Dio _dio;

  /// E4: fetches and stores the secrets the backend's responses no longer
  /// carry. Null in tests that don't need them.
  final CredentialSecrets? _secrets;

  static const _path = '/api/credentials';

  /// The domain server for [dto], with its secret from storage or the
  /// endpoint (E4).
  Future<JenkinsServer> _withSecret(CredentialDto dto) async {
    final secrets = _secrets;
    // Not masked (an older backend) or unreadable: nothing to fetch.
    if (secrets == null || dto.password != null || dto.needsReentry) {
      return dto.toDomain();
    }
    final secret = await secrets.resolve(
      tool: 'jenkins',
      path: _path,
      id: dto.id,
      listedVersion: dto.updatedAt,
      primaryField: 'password',
      extraField: 'paramToken',
    );
    return dto
        .copyWith(password: secret?.primary, paramToken: secret?.extra)
        .toDomain();
  }

  /// Keeps what the user just saved so the next load needs no fetch.
  Future<JenkinsServer> _saved(
    CredentialDto dto, {
    required String secret,
    String? paramToken,
  }) async {
    await _secrets?.remember(
      'jenkins',
      dto.id,
      primary: secret,
      extra: paramToken,
      version: dto.updatedAt,
    );
    return dto.copyWith(password: secret, paramToken: paramToken).toDomain();
  }

  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() =>
      guardRequest(() async {
        final response = await _dio.get<List<dynamic>>('/api/credentials');
        final dtos = response.data!
            .map((json) => CredentialDto.fromJson(json as Map<String, dynamic>))
            .toList();
        return Future.wait(dtos.map(_withSecret));
      });

  @override
  Future<Result<JenkinsServer, AppFailure>> add({
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) => guardRequest(
    mapDioException: AppFailure.fromCredentialsException,
    () async {
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
      return _saved(
        CredentialDto.fromJson(response.data!),
        secret: secret,
        paramToken: paramToken,
      );
    },
  );

  @override
  Future<Result<JenkinsServer, AppFailure>> update(
    String id, {
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) => guardRequest(() async {
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
    return _saved(
      CredentialDto.fromJson(response.data!),
      secret: secret,
      paramToken: paramToken,
    );
  });

  @override
  Future<Result<void, AppFailure>> delete(String id) => guardRequest(() async {
    await _dio.delete<void>('/api/credentials/$id');
    await _secrets?.forget('jenkins', id);
  });

  @override
  Future<Result<JenkinsServer, AppFailure>> switchActive(String id) =>
      guardRequest(
        mapDioException: AppFailure.fromCredentialsException,
        () async {
          final response = await _dio.post<Map<String, dynamic>>(
            '/api/credentials/switch/$id',
          );
          return _withSecret(CredentialDto.fromJson(response.data!));
        },
      );

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
CredentialsRepository credentialsRepository(Ref ref) {
  // E2: demo mode never reaches the backend.
  if (ref.watch(demoModeNotifierProvider)) return demoCredentialsRepository;
  return CredentialsRepositoryImpl(
    ref.watch(dioBackendProvider),
    CredentialSecrets(
      ref.watch(dioBackendProvider),
      ref.watch(secureStorageProvider),
    ),
  );
}
