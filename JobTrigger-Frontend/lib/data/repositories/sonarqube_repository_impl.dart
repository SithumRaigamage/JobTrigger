import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../domain/sonarqube/sonarqube_project.dart';
import '../../domain/sonarqube/sonarqube_repository.dart';
import '../credentials/active_sonarqube_credential_notifier.dart';
import '../datasources/sonarqube_client_factory.dart';
import '../models/sonarqube/sonarqube_project_dto.dart';

part 'sonarqube_repository_impl.g.dart';

class SonarQubeRepositoryImpl implements SonarQubeRepository {
  /// [organization] is the active credential's SonarCloud organization key,
  /// or null for a self-hosted server.
  SonarQubeRepositoryImpl(this._dio, {String? organization})
    : _organization = (organization?.trim().isEmpty ?? true)
          ? null
          : organization!.trim();

  final Dio _dio;
  final String? _organization;

  @override
  Future<Result<List<SonarQubeProject>, AppFailure>> fetchProjects() =>
      guardRequest(
        () async {
          final response = await _dio.get<Map<String, dynamic>>(
            '/api/projects/search',
            queryParameters: {
              'ps': sonarQubeProjectsPageSize,
              'organization': ?_organization,
            },
          );
          final components =
              response.data?['components'] as List<dynamic>? ?? const [];
          return components
              .map(
                (json) => SonarQubeProjectDto.fromJson(
                  json as Map<String, dynamic>,
                ).toDomain(),
              )
              .toList();
        },
        // A 404 with an organization set means SonarCloud doesn't know that
        // key: say so, instead of the generic "couldn't be found".
        recover: (exception) =>
            exception.response?.statusCode == 404 && _organization != null
            ? const Err(SonarQubeOrganizationNotFoundFailure())
            : null,
      );
}

@riverpod
SonarQubeRepository sonarQubeRepository(Ref ref) {
  final credential = ref.watch(activeSonarQubeCredentialNotifierProvider);
  return SonarQubeRepositoryImpl(
    ref.watch(sonarQubeClientProvider),
    organization: credential?.defaultOrganization,
  );
}
