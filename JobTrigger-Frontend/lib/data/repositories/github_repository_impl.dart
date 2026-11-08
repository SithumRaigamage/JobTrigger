import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/guard.dart';
import '../../core/error/result.dart';
import '../datasources/github_client_factory.dart';
import '../../domain/github/github_repo.dart';
import '../../domain/github/github_repository.dart';
import '../../domain/github/github_workflow.dart';
import '../models/github/github_repo_dto.dart';
import '../models/github/github_job_dto.dart';
import '../models/github/github_workflow_dto.dart';
import '../../domain/github/github_job.dart';
import '../models/github/github_workflow_run_dto.dart';
import '../../domain/github/github_workflow_run.dart';

part 'github_repository_impl.g.dart';

class GitHubRepositoryImpl implements GitHubRepository {
  /// [downloadDio] fetches the signed log URL GitHub redirects to. It must
  /// carry no credentials, so the default is a bare client built on demand;
  /// tests inject one with a fake adapter.
  GitHubRepositoryImpl(this._dio, {this._downloadDio});

  final Dio _dio;
  final Dio? _downloadDio;

  @override
  Future<Result<List<GitHubRepo>, AppFailure>> fetchRepos() => guardRequest(
    () async {
      final response = await _dio.get<List<dynamic>>(
        '/user/repos',
        queryParameters: {'per_page': 100, 'sort': 'updated'},
      );
      final repos = (response.data ?? const [])
          .map(
            (json) =>
                GitHubRepoDto.fromJson(json as Map<String, dynamic>).toDomain(),
          )
          .toList();
      return repos;
    },
    mapDioException: AppFailure.fromGitHubException,
  );

  @override
  Future<Result<List<GitHubWorkflow>, AppFailure>> fetchWorkflows(
    String owner,
    String repo,
  ) => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/repos/$owner/$repo/actions/workflows',
    );
    final workflowsJson =
        response.data?['workflows'] as List<dynamic>? ?? const [];
    final workflows = workflowsJson
        .map(
          (json) => GitHubWorkflowDto.fromJson(
            json as Map<String, dynamic>,
          ).toDomain(),
        )
        .toList();
    return workflows;
  }, mapDioException: AppFailure.fromGitHubException);

  @override
  Future<Result<List<GitHubWorkflowRun>, AppFailure>> fetchRuns(
    String owner,
    String repo,
    int workflowId,
  ) => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/repos/$owner/$repo/actions/workflows/$workflowId/runs',
      queryParameters: {'per_page': 30},
    );
    final runsJson =
        response.data?['workflow_runs'] as List<dynamic>? ?? const [];
    return runsJson
        .map(
          (json) => GitHubWorkflowRunDto.fromJson(
            json as Map<String, dynamic>,
          ).toDomain(),
        )
        .toList();
  }, mapDioException: AppFailure.fromGitHubException);

  @override
  Future<Result<void, AppFailure>> triggerRun(
    String owner,
    String repo,
    int workflowId, {
    required String ref,
    Map<String, String> inputs = const {},
  }) => guardRequest<void>(
    () async {
      await _dio.post<void>(
        '/repos/$owner/$repo/actions/workflows/$workflowId/dispatches',
        // Dio JSON-encodes this; values are never string-concatenated
        // (US-GH-RUN-02's injection note).
        data: {'ref': ref, if (inputs.isNotEmpty) 'inputs': inputs},
      );
    },
    mapDioException: (exception) {
      if (exception.response?.statusCode == 422) {
        final body = exception.response?.data;
        final detail = body is Map<String, dynamic>
            ? body['message'] as String?
            : null;
        return DispatchRejectedFailure(detail);
      }
      return AppFailure.fromGitHubException(exception);
    },
  );

  @override
  Future<Result<GitHubWorkflowRun, AppFailure>> fetchRun(
    String owner,
    String repo,
    int runId,
  ) => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/repos/$owner/$repo/actions/runs/$runId',
    );
    return GitHubWorkflowRunDto.fromJson(response.data!).toDomain();
  }, mapDioException: AppFailure.fromGitHubException);

  @override
  Future<Result<void, AppFailure>> cancelRun(
    String owner,
    String repo,
    int runId,
  ) => guardRequest<void>(() async {
    await _dio.post<void>('/repos/$owner/$repo/actions/runs/$runId/cancel');
  }, mapDioException: AppFailure.fromGitHubException);

  @override
  Future<Result<List<GitHubJob>, AppFailure>> fetchJobs(
    String owner,
    String repo,
    int runId,
  ) => guardRequest(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/repos/$owner/$repo/actions/runs/$runId/jobs',
      queryParameters: {'per_page': 100},
    );
    final jobsJson = response.data?['jobs'] as List<dynamic>? ?? const [];
    return jobsJson
        .map(
          (json) =>
              GitHubJobDto.fromJson(json as Map<String, dynamic>).toDomain(),
        )
        .toList();
  }, mapDioException: AppFailure.fromGitHubException);

  @override
  Future<Result<String, AppFailure>> fetchJobLog(
    String owner,
    String repo,
    int jobId,
  ) => guardRequest(() async {
    // Hop 1, with the Bearer token: GitHub replies 302 + a signed URL.
    // Redirects are followed by hand so the token is never sent to the
    // storage host, and so the URL stays in this method (it expires in
    // about a minute, so it must not be kept or reused).
    final first = await _dio.get<String>(
      '/repos/$owner/$repo/actions/jobs/$jobId/logs',
      options: Options(
        followRedirects: false,
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final status = first.statusCode ?? 200;
    if (status < 300) return first.data ?? '';

    final location = first.headers.value('location');
    if (location == null || location.isEmpty) {
      throw const FormatException('Log redirect had no Location header');
    }
    final download =
        _downloadDio ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );
    try {
      // Hop 2, with no credentials.
      final second = await download.get<String>(
        location,
        options: Options(responseType: ResponseType.plain),
      );
      return second.data ?? '';
    } finally {
      if (_downloadDio == null) download.close();
    }
  }, mapDioException: AppFailure.fromGitHubException);
}

@riverpod
GitHubRepository gitHubRepository(Ref ref) =>
    GitHubRepositoryImpl(ref.watch(gitHubClientProvider));
