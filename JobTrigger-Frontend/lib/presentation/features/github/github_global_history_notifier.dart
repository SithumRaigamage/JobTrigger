import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/github_repository_impl.dart';
import '../../../domain/github/github_repo.dart';
import '../../../domain/github/github_workflow_run.dart';
import 'github_repos_notifier.dart';

part 'github_global_history_notifier.g.dart';

/// How many repos the feed asks, newest-updated first. GitHub has no
/// "recent runs across all repos" endpoint, so each repo is one request
/// against the 5,000/hour limit; capping keeps one screen cheap
/// (`US-GH-HIST-02`).
const globalHistoryRepoCap = 8;

/// Runs taken from each repo, and runs kept overall.
const globalHistoryPerRepo = 5;
const globalHistoryLimit = 50;

/// One run in the feed, with the repo it belongs to.
class GlobalRunEntry {
  const GlobalRunEntry(this.repo, this.run);

  final GitHubRepo repo;
  final GitHubWorkflowRun run;
}

/// The merged feed plus what it did not cover, so the screen can say so
/// instead of implying the list is complete.
class GlobalRunFeed {
  const GlobalRunFeed({
    required this.entries,
    required this.reposAsked,
    required this.reposSkipped,
    required this.reposFailed,
    this.firstFailure,
  });

  final List<GlobalRunEntry> entries;
  final int reposAsked;

  /// Repos beyond [globalHistoryRepoCap] that were not asked.
  final int reposSkipped;

  /// Repos whose request failed; the rest still show.
  final int reposFailed;
  final AppFailure? firstFailure;
}

/// Runs across the most recently updated repos, newest first
/// (`US-GH-HIST-02`). Requests run together; one repo failing (Actions
/// disabled, no access) does not hide the others. Only when every request
/// fails is the whole feed an error.
@riverpod
class GitHubGlobalHistoryNotifier extends _$GitHubGlobalHistoryNotifier {
  @override
  Future<GlobalRunFeed> build() async {
    final repos = await ref.watch(gitHubReposNotifierProvider.future);
    final asked = repos.take(globalHistoryRepoCap).toList();
    final repository = ref.watch(gitHubRepositoryProvider);

    final results = await Future.wait([
      for (final repo in asked)
        repository.fetchRepoRuns(
          repo.owner,
          repo.name,
          limit: globalHistoryPerRepo,
        ),
    ]);

    final entries = <GlobalRunEntry>[];
    AppFailure? firstFailure;
    var failed = 0;
    for (final (i, result) in results.indexed) {
      switch (result) {
        case Ok(:final value):
          entries.addAll(value.map((run) => GlobalRunEntry(asked[i], run)));
        case Err(:final error):
          failed++;
          firstFailure ??= error;
      }
    }
    if (asked.isNotEmpty && failed == asked.length) throw firstFailure!;

    // Runs GitHub sent without a date sort last rather than first.
    entries.sort(
      (a, b) => (b.run.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.run.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );
    return GlobalRunFeed(
      entries: entries.take(globalHistoryLimit).toList(),
      reposAsked: asked.length,
      reposSkipped: repos.length - asked.length,
      reposFailed: failed,
      firstFailure: firstFailure,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
