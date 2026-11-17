import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/github_repository_impl.dart';
import '../../../domain/github/github_workflow.dart';

part 'github_workflows_notifier.g.dart';

/// Fetches a single repo's workflows (`US-GH-REPO-02`), keyed by
/// `(owner, repo)` — a family provider since `GitHubWorkflowListScreen`
/// can be pushed for any repo in the active credential's list.
@riverpod
class GitHubWorkflowsNotifier extends _$GitHubWorkflowsNotifier {
  @override
  Future<List<GitHubWorkflow>> build(String owner, String repo) async {
    final result = await ref
        .watch(gitHubRepositoryProvider)
        .fetchWorkflows(owner, repo);
    return result.fold((workflows) => workflows, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
