import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_issue.dart';

part 'sonarqube_issues_notifier.g.dart';

/// SonarQube won't page past this many results.
const sonarQubeIssuesMaxResults = 10000;

/// The issue filter chips for one project (`US-SQ-QUALITY-03`).
@riverpod
class SonarQubeIssueFilterNotifier extends _$SonarQubeIssueFilterNotifier {
  @override
  SonarQubeIssueFilter build(String projectKey) => const SonarQubeIssueFilter();

  void toggleType(String type) => state = state.toggleType(type);

  void toggleSeverity(String severity) =>
      state = state.toggleSeverity(severity);

  void clear() => state = const SonarQubeIssueFilter();
}

/// Everything loaded so far under the current filter.
class SonarQubeIssues {
  const SonarQubeIssues({
    required this.issues,
    required this.total,
    this.isLoadingMore = false,
    this.loadMoreFailure,
  });

  final List<SonarQubeIssue> issues;

  /// How many issues match the filter on the server.
  final int total;
  final bool isLoadingMore;
  final Object? loadMoreFailure;

  bool get hasMore =>
      issues.length < total && issues.length < sonarQubeIssuesMaxResults;

  SonarQubeIssues copyWith({
    bool? isLoadingMore,
    Object? loadMoreFailure,
    bool clearFailure = false,
  }) => SonarQubeIssues(
    issues: issues,
    total: total,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: clearFailure
        ? null
        : (loadMoreFailure ?? this.loadMoreFailure),
  );
}

/// A project's issues, server-filtered and paged (`US-SQ-QUALITY-03`).
/// Changing the filter rebuilds from page one.
@riverpod
class SonarQubeIssuesNotifier extends _$SonarQubeIssuesNotifier {
  @override
  Future<SonarQubeIssues> build(String projectKey) async {
    final filter = ref.watch(sonarQubeIssueFilterNotifierProvider(projectKey));
    final result = await ref
        .watch(sonarQubeRepositoryProvider)
        .fetchIssues(projectKey, filter: filter);
    final page = result.fold((page) => page, (failure) => throw failure);
    return SonarQubeIssues(issues: page.issues, total: page.total);
  }

  /// Appends the next page. A failure keeps what's loaded and offers a
  /// retry instead of replacing the list with an error.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearFailure: true),
    );
    final filter = ref.read(sonarQubeIssueFilterNotifierProvider(projectKey));
    final nextPage = current.issues.length ~/ sonarQubeIssuesPageSize + 1;
    final result = await ref
        .read(sonarQubeRepositoryProvider)
        .fetchIssues(projectKey, filter: filter, page: nextPage);
    if (!ref.mounted) return;
    state = AsyncData(switch (result) {
      Ok(value: final page) => SonarQubeIssues(
        issues: [...current.issues, ...page.issues],
        total: page.total,
      ),
      Err(:final error) => current.copyWith(
        isLoadingMore: false,
        loadMoreFailure: error,
      ),
    });
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
