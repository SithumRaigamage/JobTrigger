import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/github_repository_impl.dart';
import '../../../domain/github/github_workflow_run.dart';

part 'github_runs_notifier.g.dart';

/// Fetches one workflow's recent runs (`US-GH-RUN-01`), keyed by
/// `(owner, repo, workflowId)` — a family provider since the runs screen
/// can be opened for any workflow of any repo.
@riverpod
class GitHubRunsNotifier extends _$GitHubRunsNotifier {
  @override
  Future<List<GitHubWorkflowRun>> build(
    String owner,
    String repo,
    int workflowId,
  ) async {
    final result = await ref
        .watch(gitHubRepositoryProvider)
        .fetchRuns(owner, repo, workflowId);
    return result.fold((runs) => runs, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
