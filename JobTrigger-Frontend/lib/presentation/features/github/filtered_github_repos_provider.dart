import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/github/github_repo.dart';
import 'github_repo_search_notifier.dart';
import 'github_repos_notifier.dart';

part 'filtered_github_repos_provider.g.dart';

/// The repos `GitHubRepoScreen` should actually display — filtered by
/// name/[GitHubRepo.fullName] (so searching "octocat/" narrows to one
/// owner). No folder/breadcrumb concept here unlike `filteredJobs`:
/// GitHub's repo list is flat, not a tree.
@riverpod
List<GitHubRepo> filteredGitHubRepos(Ref ref) {
  final repos =
      ref.watch(gitHubReposNotifierProvider).value ?? const <GitHubRepo>[];
  final query = ref.watch(gitHubRepoSearchNotifierProvider);

  if (query.isEmpty) return repos;

  final lowerQuery = query.toLowerCase();
  return repos
      .where((repo) => repo.fullName.toLowerCase().contains(lowerQuery))
      .toList();
}
