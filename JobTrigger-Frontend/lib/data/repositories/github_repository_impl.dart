import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../core/network/github_client_factory.dart';
import '../../domain/github/github_repo.dart';
import '../../domain/github/github_repository.dart';
import '../../domain/github/github_workflow.dart';
import '../models/github/github_repo_dto.dart';
import '../models/github/github_workflow_dto.dart';

part 'github_repository_impl.g.dart';

class GitHubRepositoryImpl implements GitHubRepository {
  GitHubRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<GitHubRepo>, AppFailure>> fetchRepos() async {
    try {
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
      return Ok(repos);
    } on DioException catch (exception) {
      return Err(AppFailure.fromGitHubException(exception));
    }
  }

  @override
  Future<Result<List<GitHubWorkflow>, AppFailure>> fetchWorkflows(
    String owner,
    String repo,
  ) async {
    try {
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
      return Ok(workflows);
    } on DioException catch (exception) {
      return Err(AppFailure.fromGitHubException(exception));
    }
  }
}

@riverpod
GitHubRepository gitHubRepository(Ref ref) =>
    GitHubRepositoryImpl(ref.watch(gitHubClientProvider));
