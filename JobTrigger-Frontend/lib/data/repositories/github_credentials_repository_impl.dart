import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/credential/github_credential.dart';
import '../../domain/credential/github_credentials_repository.dart';
import '../models/credential/github_credential_dto.dart';

part 'github_credentials_repository_impl.g.dart';

/// Talks to `JobTrigger-Backend`'s `/api/github-credentials` (JWT-authed,
/// via `dioBackendProvider` — credential storage always goes through our
/// own backend regardless of which CI tool the credential is for; this is
/// not the GitHub Actions API client itself, see `github_client_factory
/// .dart` for that, Bearer-token-authed against `api.github.com`).
class GitHubCredentialsRepositoryImpl implements GitHubCredentialsRepository {
  GitHubCredentialsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<GitHubCredential>, AppFailure>> fetchAll() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/github-credentials');
      final credentials = response.data!
          .map(
            (json) => GitHubCredentialDto.fromJson(
              json as Map<String, dynamic>,
            ).toDomain(),
          )
          .toList();
      return Ok(credentials);
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<GitHubCredential, AppFailure>> add({
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/github-credentials',
        data: _body(
          label: label,
          secret: secret,
          defaultOwner: defaultOwner,
          isDefault: isDefault,
        ),
      );
      return Ok(GitHubCredentialDto.fromJson(response.data!).toDomain());
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<GitHubCredential, AppFailure>> update(
    String id, {
    required String label,
    required String secret,
    String? defaultOwner,
    bool isDefault = false,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/github-credentials/$id',
        data: _body(
          label: label,
          secret: secret,
          defaultOwner: defaultOwner,
          isDefault: isDefault,
        ),
      );
      return Ok(GitHubCredentialDto.fromJson(response.data!).toDomain());
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<void, AppFailure>> delete(String id) async {
    try {
      await _dio.delete<void>('/api/github-credentials/$id');
      return const Ok(null);
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<GitHubCredential, AppFailure>> switchActive(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/github-credentials/switch/$id',
      );
      return Ok(GitHubCredentialDto.fromJson(response.data!).toDomain());
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

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
GitHubCredentialsRepository githubCredentialsRepository(Ref ref) =>
    GitHubCredentialsRepositoryImpl(ref.watch(dioBackendProvider));
