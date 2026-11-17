import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/github_repository_impl.dart';
import '../../../domain/github/github_repo.dart';
import '../../common_widgets/data_freshness.dart';

part 'github_repos_notifier.g.dart';

/// Fetches the active credential's repos (`US-GH-REPO-01`) — the
/// GitHub-side equivalent of `JobTreeNotifier`. `refresh()` backs
/// pull-to-refresh on `GitHubRepoScreen`.
@riverpod
class GitHubReposNotifier extends _$GitHubReposNotifier {
  @override
  Future<List<GitHubRepo>> build() async {
    final result = await ref.watch(gitHubRepositoryProvider).fetchRepos();
    final repos = result.fold((repos) => repos, (failure) => throw failure);
    recordFreshness(ref, gitHubReposFreshnessKey);
    return repos;
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
