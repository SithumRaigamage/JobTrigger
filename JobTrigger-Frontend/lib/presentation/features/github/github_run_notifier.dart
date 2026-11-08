import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/github_repository_impl.dart';
import '../../../domain/github/github_workflow_run.dart';

part 'github_run_notifier.g.dart';

/// One run's current state (`US-GH-RUN-03`), keyed by `(owner, repo,
/// runId)`. [GitHubRunPollingNotifier] invalidates it every 5s while the
/// run is active, so the screen updates without a manual refresh.
@riverpod
class GitHubRunNotifier extends _$GitHubRunNotifier {
  @override
  Future<GitHubWorkflowRun> build(String owner, String repo, int runId) async {
    final result = await ref
        .watch(gitHubRepositoryProvider)
        .fetchRun(owner, repo, runId);
    return result.fold((run) => run, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
