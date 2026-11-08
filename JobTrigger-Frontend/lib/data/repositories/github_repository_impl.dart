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
import '../models/github/github_workflow_dto.dart';
import '../models/github/github_workflow_run_dto.dart';
import '../../domain/github/github_workflow_run.dart';

part 'github_repository_impl.g.dart';

class GitHubRepositoryImpl implements GitHubRepository {
  GitHubRepositoryImpl(this._dio);

  final Dio _dio;

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
}

@riverpod
GitHubRepository gitHubRepository(Ref ref) =>
    GitHubRepositoryImpl(ref.watch(gitHubClientProvider));
