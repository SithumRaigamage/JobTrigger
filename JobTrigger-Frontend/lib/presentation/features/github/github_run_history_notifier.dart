import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/github_repository_impl.dart';
import '../../../domain/github/github_repository.dart';
import '../../../domain/github/github_workflow_run.dart';

part 'github_run_history_notifier.g.dart';

/// Every page of one workflow's runs loaded so far (`US-GH-HIST-01`).
class GitHubRunPages {
  const GitHubRunPages({
    required this.runs,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreFailure,
  });

  final List<GitHubWorkflowRun> runs;

  /// False once a page came back short: the end of history.
  final bool hasMore;
  final bool isLoadingMore;

  /// Set when the last "load more" failed, so the screen can say so and
  /// offer a retry instead of silently ending the list.
  final Object? loadMoreFailure;

  GitHubRunPages copyWith({
    List<GitHubWorkflowRun>? runs,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreFailure,
    bool clearFailure = false,
  }) => GitHubRunPages(
    runs: runs ?? this.runs,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: clearFailure
        ? null
        : (loadMoreFailure ?? this.loadMoreFailure),
  );
}

/// A workflow's run history, [gitHubRunsPageSize] runs at a time, newest
/// first (`US-GH-HIST-01`). The first page loads with the screen;
/// [loadMore] appends the next. This is the same call as the runs list,
/// just paged further.
@riverpod
class GitHubRunHistoryNotifier extends _$GitHubRunHistoryNotifier {
  @override
  Future<GitHubRunPages> build(
    String owner,
    String repo,
    int workflowId,
  ) async {
    final result = await ref
        .watch(gitHubRepositoryProvider)
        .fetchRuns(owner, repo, workflowId);
    final runs = result.fold((runs) => runs, (failure) => throw failure);
    return GitHubRunPages(
      runs: runs,
      hasMore: runs.length == gitHubRunsPageSize,
    );
  }

  /// Appends the next page. A failure keeps what's loaded and records the
  /// failure (shown with a retry) rather than replacing the list with an
  /// error screen.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearFailure: true),
    );
    // Pages are 1-based and a full page is gitHubRunsPageSize runs, so the
    // next page follows from how many pages are already loaded.
    final nextPage = current.runs.length ~/ gitHubRunsPageSize + 1;
    final result = await ref
        .read(gitHubRepositoryProvider)
        .fetchRuns(owner, repo, workflowId, page: nextPage);
    if (!ref.mounted) return;
    state = AsyncData(switch (result) {
      Ok(value: final page) => GitHubRunPages(
        runs: [...current.runs, ...page],
        hasMore: page.length == gitHubRunsPageSize,
      ),
      Err(:final error) => current.copyWith(
        isLoadingMore: false,
        loadMoreFailure: error,
      ),
    });
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
