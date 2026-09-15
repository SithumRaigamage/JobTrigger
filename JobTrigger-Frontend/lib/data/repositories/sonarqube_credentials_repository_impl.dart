import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../core/network/backend_api_client.dart';
import '../../domain/credential/sonarqube_credential.dart';
import '../../domain/credential/sonarqube_credentials_repository.dart';
import '../models/credential/sonarqube_credential_dto.dart';

part 'sonarqube_credentials_repository_impl.g.dart';

/// Talks to `JobTrigger-Backend`'s `/api/sonarqube-credentials` (JWT-authed,
/// via `dioBackendProvider` — credential storage always goes through our
/// own backend regardless of which CI tool the credential is for; this is
/// not the SonarQube Web API client itself, see `sonarqube_client_factory
/// .dart` for that, Bearer-token-authed against the credential's own
/// `baseUrl`).
class SonarQubeCredentialsRepositoryImpl
    implements SonarQubeCredentialsRepository {
  SonarQubeCredentialsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<SonarQubeCredential>, AppFailure>> fetchAll() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/sonarqube-credentials',
      );
      final credentials = response.data!
          .map(
            (json) => SonarQubeCredentialDto.fromJson(
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
  Future<Result<SonarQubeCredential, AppFailure>> add({
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  }) async {
    try {
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
      return Ok(SonarQubeCredentialDto.fromJson(response.data!).toDomain());
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<SonarQubeCredential, AppFailure>> update(
    String id, {
    required String label,
    required String baseUrl,
    required String secret,
    String? defaultOrganization,
    bool isDefault = false,
  }) async {
    try {
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
      return Ok(SonarQubeCredentialDto.fromJson(response.data!).toDomain());
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<void, AppFailure>> delete(String id) async {
    try {
      await _dio.delete<void>('/api/sonarqube-credentials/$id');
      return const Ok(null);
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

  @override
  Future<Result<SonarQubeCredential, AppFailure>> switchActive(
    String id,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/sonarqube-credentials/switch/$id',
      );
      return Ok(SonarQubeCredentialDto.fromJson(response.data!).toDomain());
    } on DioException catch (exception) {
      return Err(AppFailure.fromDioException(exception));
    }
  }

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
SonarQubeCredentialsRepository sonarQubeCredentialsRepository(Ref ref) =>
    SonarQubeCredentialsRepositoryImpl(ref.watch(dioBackendProvider));
