import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/credential/github_credential.dart';
import '../../domain/credential/github_credentials_repository.dart';
import '../credentials/credential_secrets.dart';
import '../models/credential/github_credential_dto.dart';

import '../demo/demo_account_repositories.dart';
import '../demo/demo_mode_notifier.dart';
part 'github_credentials_repository_impl.g.dart';

/// Talks to `JobTrigger-Backend`'s `/api/github-credentials` (JWT-authed,
/// via `dioBackendProvider` — credential storage always goes through our
/// own backend regardless of which CI tool the credential is for; this is
/// not the GitHub Actions API client itself, see `github_client_factory
/// .dart` for that, Bearer-token-authed against `api.github.com`).
class GitHubCredentialsRepositoryImpl implements GitHubCredentialsRepository {
  GitHubCredentialsRepositoryImpl(this._dio, [this._secrets]);

  final Dio _dio;

  /// E4: fetches and stores the token the backend's responses no longer
  /// carry. Null in tests that don't need it.
  final CredentialSecrets? _secrets;

  static const _path = '/api/github-credentials';

  /// The domain credential for [dto], with its token from storage or the
  /// endpoint (E4).
  Future<GitHubCredential> _withSecret(GitHubCredentialDto dto) async {
    final secrets = _secrets;
    // Not masked (an older backend) or unreadable: nothing to fetch.
    if (secrets == null || dto.token != null || dto.needsReentry) {
      return dto.toDomain();
    }
    final secret = await secrets.resolve(
      tool: 'github',
      path: _path,
      id: dto.id,
      listedVersion: dto.updatedAt,
      primaryField: 'token',
    );
    return dto.copyWith(token: secret?.primary).toDomain();
  }

  /// Keeps what the user just saved so the next load needs no fetch.
  Future<GitHubCredential> _saved(
    GitHubCredentialDto dto, {
    required String secret,
  }) async {
    await _secrets?.remember(
      'github',
      dto.id,
      primary: secret,
      version: dto.updatedAt,
    );
    return dto.copyWith(token: secret).toDomain();
  }

  @override
  Future<Result<List<GitHubCredential>, AppFailure>> fetchAll() => guardRequest(
    () async {
      final response = await _dio.get<List<dynamic>>('/api/github-credentials');
      final dtos = response.data!
          .map(
            (json) =>
                GitHubCredentialDto.fromJson(json as Map<String, dynamic>),
          )
          .toList();
      return Future.wait(dtos.map(_withSecret));
    },
  );

  @override
  Future<Result<GitHubCredential, AppFailure>> add({
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) => guardRequest(
    mapDioException: AppFailure.fromCredentialsException,
    () async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/github-credentials',
        data: _body(
          label: label,
          secret: secret,
          defaultOwner: defaultOwner,
          isDefault: isDefault,
        ),
      );
      return _saved(
        GitHubCredentialDto.fromJson(response.data!),
        secret: secret,
      );
    },
  );

  @override
  Future<Result<GitHubCredential, AppFailure>> update(
    String id, {
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) => guardRequest(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/github-credentials/$id',
      data: _body(
        label: label,
        secret: secret,
        defaultOwner: defaultOwner,
        isDefault: isDefault,
      ),
    );
    return _saved(GitHubCredentialDto.fromJson(response.data!), secret: secret);
  });

  @override
  Future<Result<void, AppFailure>> delete(String id) => guardRequest(() async {
    await _dio.delete<void>('/api/github-credentials/$id');
    await _secrets?.forget('github', id);
  });

  @override
  Future<Result<GitHubCredential, AppFailure>> switchActive(String id) =>
      guardRequest(
        mapDioException: AppFailure.fromCredentialsException,
        () async {
          final response = await _dio.post<Map<String, dynamic>>(
            '/api/github-credentials/switch/$id',
          );
          return _withSecret(GitHubCredentialDto.fromJson(response.data!));
        },
      );

  Map<String, dynamic> _body({
    required String label,
    required String secret,
    String? defaultOwner,
    required bool isDefault,
  }) => {
    'label': label,
    'token': secret,
    'defaultOwner': defaultOwner,
    'isDefault': isDefault,
  };
}

@riverpod
GitHubCredentialsRepository gitHubCredentialsRepository(Ref ref) {
  // E2: demo mode never reaches the backend.
  if (ref.watch(demoModeNotifierProvider)) {
    return demoGitHubCredentialsRepository;
  }
  return GitHubCredentialsRepositoryImpl(
    ref.watch(dioBackendProvider),
    CredentialSecrets(
      ref.watch(dioBackendProvider),
      ref.watch(secureStorageProvider),
    ),
  );
}
