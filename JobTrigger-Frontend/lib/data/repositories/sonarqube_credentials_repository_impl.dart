import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/credential/sonarqube_credential.dart';
import '../../domain/credential/sonarqube_credentials_repository.dart';
import '../credentials/credential_secrets.dart';
import '../models/credential/sonarqube_credential_dto.dart';

import '../demo/demo_account_repositories.dart';
import '../demo/demo_mode_notifier.dart';
part 'sonarqube_credentials_repository_impl.g.dart';

/// Talks to `JobTrigger-Backend`'s `/api/sonarqube-credentials` (JWT-authed,
/// via `dioBackendProvider` — credential storage always goes through our
/// own backend regardless of which CI tool the credential is for; this is
/// not the SonarQube Web API client itself, see `sonarqube_client_factory
/// .dart` for that, Bearer-token-authed against the credential's own
/// `baseUrl`).
class SonarQubeCredentialsRepositoryImpl
    implements SonarQubeCredentialsRepository {
  SonarQubeCredentialsRepositoryImpl(this._dio, [this._secrets]);

  final Dio _dio;

  /// E4: fetches and stores the token the backend's responses no longer
  /// carry. Null in tests that don't need it.
  final CredentialSecrets? _secrets;

  static const _path = '/api/sonarqube-credentials';

  /// The domain credential for [dto], with its token from storage or the
  /// endpoint (E4).
  Future<SonarQubeCredential> _withSecret(SonarQubeCredentialDto dto) async {
    final secrets = _secrets;
    // Not masked (an older backend) or unreadable: nothing to fetch.
    if (secrets == null || dto.token != null || dto.needsReentry) {
      return dto.toDomain();
    }
    final secret = await secrets.resolve(
      tool: 'sonarqube',
      path: _path,
      id: dto.id,
      listedVersion: dto.updatedAt,
      primaryField: 'token',
    );
    return dto.copyWith(token: secret?.primary).toDomain();
  }

  /// Keeps what the user just saved so the next load needs no fetch.
  Future<SonarQubeCredential> _saved(
    SonarQubeCredentialDto dto, {
    required String secret,
  }) async {
    await _secrets?.remember(
      'sonarqube',
      dto.id,
      primary: secret,
      version: dto.updatedAt,
    );
    return dto.copyWith(token: secret).toDomain();
  }

  @override
  Future<Result<List<SonarQubeCredential>, AppFailure>> fetchAll() =>
      guardRequest(() async {
        final response = await _dio.get<List<dynamic>>(
          '/api/sonarqube-credentials',
        );
        final dtos = response.data!
            .map(
              (json) =>
                  SonarQubeCredentialDto.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        return Future.wait(dtos.map(_withSecret));
      });

  @override
  Future<Result<SonarQubeCredential, AppFailure>> add({
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  }) => guardRequest(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/sonarqube-credentials',
      data: _body(
        label: label,
        baseUrl: baseUrl,
        secret: secret,
        defaultOrganization: defaultOrganization,
        isDefault: isDefault,
      ),
    );
    return _saved(
      SonarQubeCredentialDto.fromJson(response.data!),
      secret: secret,
    );
  });

  @override
  Future<Result<SonarQubeCredential, AppFailure>> update(
    String id, {
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  }) => guardRequest(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/sonarqube-credentials/$id',
      data: _body(
        label: label,
        baseUrl: baseUrl,
        secret: secret,
        defaultOrganization: defaultOrganization,
        isDefault: isDefault,
      ),
    );
    return _saved(
      SonarQubeCredentialDto.fromJson(response.data!),
      secret: secret,
    );
  });

  @override
  Future<Result<void, AppFailure>> delete(String id) => guardRequest(() async {
    await _dio.delete<void>('/api/sonarqube-credentials/$id');
    await _secrets?.forget('sonarqube', id);
  });

  @override
  Future<Result<SonarQubeCredential, AppFailure>> switchActive(String id) =>
      guardRequest(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/api/sonarqube-credentials/switch/$id',
        );
        return _withSecret(SonarQubeCredentialDto.fromJson(response.data!));
      });

  Map<String, dynamic> _body({
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    required bool isDefault,
  }) => {
    'label': label,
    'baseUrl': baseUrl,
    'token': secret,
    'defaultOrganization': defaultOrganization,
    'isDefault': isDefault,
  };
}

@riverpod
SonarQubeCredentialsRepository sonarQubeCredentialsRepository(Ref ref) {
  // E2: demo mode never reaches the backend.
  if (ref.watch(demoModeNotifierProvider)) {
    return demoSonarQubeCredentialsRepository;
  }
  return SonarQubeCredentialsRepositoryImpl(
    ref.watch(dioBackendProvider),
    CredentialSecrets(
      ref.watch(dioBackendProvider),
      ref.watch(secureStorageProvider),
    ),
  );
}
