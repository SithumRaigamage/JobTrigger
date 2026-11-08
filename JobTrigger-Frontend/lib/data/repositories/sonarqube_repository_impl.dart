import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../../domain/sonarqube/sonarqube_analysis.dart';
import '../../domain/sonarqube/sonarqube_issue.dart';
import '../../domain/sonarqube/sonarqube_metrics.dart';
import '../../domain/sonarqube/sonarqube_project.dart';
import '../../domain/sonarqube/sonarqube_quality_gate.dart';
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
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) async {
    // The call SonarQube's own Projects page uses: any user with Browse
    // access may call it.
    final primary = await _projectsVia(
      '/api/components/search_projects',
      page,
      pageSize,
    );
    // A server that doesn't have it (404 or 400) gets the administrator-only
    // call earlier versions of the app used, so a setup that worked before
    // keeps working. A refusal (403) is final: that call is stricter.
    if (primary is Err<SonarQubeProjectsPage, AppFailure> &&
        _lacksEndpoint(primary.error)) {
      return _projectsVia('/api/projects/search', page, pageSize);
    }
    return primary;
  }

  static bool _lacksEndpoint(AppFailure failure) =>
      failure is NotFoundFailure ||
      (failure is ServerFailure && failure.statusCode == 400);

  Future<Result<SonarQubeProjectsPage, AppFailure>> _projectsVia(
    String path,
    int page,
    int pageSize,
  ) => guardRequest(
    () async {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          'ps': pageSize,
          'p': page,
          'organization': ?_organization,
        },
      );
      final data = response.data ?? const <String, dynamic>{};
      final components = data['components'] as List<dynamic>? ?? const [];
      final projects = components
          .map(
            (json) => SonarQubeProjectDto.fromJson(
              json as Map<String, dynamic>,
            ).toDomain(),
          )
          .toList();
      final total =
          (data['paging'] as Map<String, dynamic>?)?['total'] as int? ??
          projects.length;
      return SonarQubeProjectsPage(projects: projects, total: total);
    },
    // A 404 with an organization set means SonarCloud doesn't know that
    // key: say so, instead of the generic "couldn't be found".
    recover: (exception) {
      final status = exception.response?.statusCode;
      if (status == 403) return const Err(SonarQubeAccessDeniedFailure());
      if (status == 404 && _organization != null) {
        return const Err(SonarQubeOrganizationNotFoundFailure());
      }
      return null;
    },
  );

  /// SonarQube-specific wording for the two refusals that mean something
  /// particular here, for calls about one project. Everything else keeps the
  /// shared mapping.
  static Result<T, AppFailure>? _projectRecover<T>(DioException exception) =>
      switch (exception.response?.statusCode) {
        403 => const Err(SonarQubeAccessDeniedFailure()),
        404 => const Err(SonarQubeProjectNotFoundFailure()),
        _ => null,
      };

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/qualitygates/project_status',
      // No organization: a project key is unique, and this endpoint
      // documents no such parameter.
      queryParameters: {'projectKey': projectKey},
    );
    final status = response.data?['projectStatus'] as Map<String, dynamic>?;
    final conditions = status?['conditions'] as List<dynamic>? ?? const [];
    return SonarQubeQualityGate(
      state: QualityGateState.parse(status?['status'] as String?),
      conditions: [
        for (final c in conditions.cast<Map<String, dynamic>>())
          QualityGateCondition(
            metricKey: c['metricKey'] as String? ?? '',
            comparator: c['comparator'] as String? ?? '',
            threshold: c['errorThreshold'] as String?,
            actual: c['actualValue'] as String?,
            failed: c['status'] == 'ERROR',
          ),
      ],
    );
  }, recover: _projectRecover);

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/measures/component',
      queryParameters: {
        'component': projectKey,
        'metricKeys': sonarQubeMeasureKeys.join(','),
      },
    );
    final component = response.data?['component'] as Map<String, dynamic>?;
    final measures = component?['measures'] as List<dynamic>? ?? const [];
    return {
      for (final m in measures.cast<Map<String, dynamic>>())
        if (m['value'] is String) m['metric'] as String: m['value'] as String,
    };
  }, recover: _projectRecover);

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) => guardRequest(() async {
    // Order matters only for a stable request; the server treats these as
    // sets.
    String join(Set<String> values, List<String> order) => ([
      ...order.where(values.contains),
      ...values.where((v) => !order.contains(v)),
    ]).join(',');
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/issues/search',
      queryParameters: {
        'componentKeys': projectKey,
        'resolved': 'false',
        'ps': sonarQubeIssuesPageSize,
        'p': page,
        if (filter.types.isNotEmpty)
          'types': join(filter.types, sonarQubeIssueTypes),
        if (filter.severities.isNotEmpty)
          'severities': join(filter.severities, sonarQubeIssueSeverities),
      },
    );
    final data = response.data ?? const <String, dynamic>{};
    final issues = data['issues'] as List<dynamic>? ?? const [];
    final total =
        (data['paging'] as Map<String, dynamic>?)?['total'] as int? ??
        issues.length;
    return SonarQubeIssuePage(
      total: total,
      issues: [
        for (final i in issues.cast<Map<String, dynamic>>())
          SonarQubeIssue(
            key: i['key'] as String? ?? '',
            type: i['type'] as String? ?? '',
            severity: i['severity'] as String? ?? '',
            message: i['message'] as String? ?? '',
            // `component` is `projectKey:path/to/File`; the project's own
            // key adds nothing to a file inside it.
            file: _fileOf(i['component'] as String?, projectKey),
            line: i['line'] as int?,
          ),
      ],
    );
  }, recover: _projectRecover);

  static String? _fileOf(String? component, String projectKey) {
    // An issue on the project itself has the project as its component.
    if (component == null || component.isEmpty || component == projectKey) {
      return null;
    }
    final prefix = '$projectKey:';
    return component.startsWith(prefix)
        ? component.substring(prefix.length)
        : component;
  }

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/project_analyses/search',
      queryParameters: {'project': projectKey, 'ps': sonarQubeAnalysesLimit},
    );
    final analyses = response.data?['analyses'] as List<dynamic>? ?? const [];
    final result = [
      for (final a in analyses.cast<Map<String, dynamic>>())
        SonarQubeAnalysis(
          key: a['key'] as String? ?? '',
          date: a['date'] == null
              ? null
              : DateTime.tryParse(a['date'] as String),
          projectVersion: (a['projectVersion'] as String?)?.isEmpty ?? true
              ? null
              : a['projectVersion'] as String,
        ),
    ];
    // Newest first, whatever order the server used; undated ones last.
    result.sort(
      (a, b) => (b.date ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        a.date ?? DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
    return result;
  }, recover: _projectRecover);
}

@riverpod
SonarQubeRepository sonarQubeRepository(Ref ref) {
  final credential = ref.watch(activeSonarQubeCredentialNotifierProvider);
  return SonarQubeRepositoryImpl(
    ref.watch(sonarQubeClientProvider),
    organization: credential?.defaultOrganization,
  );
}

/// "Test connection", second half (`US-SQ-CRED-04`): after the token is
/// accepted, try to list one project the way the app will. A token can be
/// valid and still be refused here (its user can't browse projects), and
/// that is better learned at setup than after saving.
///
/// [dio] is for tests; by default a throwaway client is built and closed,
/// never the active credential's, as for the token check.
Future<Result<void, AppFailure>> checkSonarQubeProjectAccess({
  required String baseUrl,
  required String token,
  String? organization,
  Dio? dio,
}) async {
  final client = dio ?? buildSonarQubeDio(baseUrl: baseUrl, token: token);
  try {
    final result = await SonarQubeRepositoryImpl(
      client,
      organization: organization,
    ).fetchProjects(pageSize: 1);
    return switch (result) {
      Ok() => const Ok(null),
      Err(:final error) => Err(error),
    };
  } finally {
    if (dio == null) client.close();
  }
}
