import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_issue.dart';
import '../../../domain/sonarqube/sonarqube_issue_grouping.dart';
import '../../common_widgets/data_freshness.dart';

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

/// How the list is grouped (`US-SQ-ISSUES-02`), per project.
@riverpod
class SonarQubeIssueGroupingNotifier extends _$SonarQubeIssueGroupingNotifier {
  @override
  SonarQubeIssueGrouping build(String projectKey) =>
      SonarQubeIssueGrouping.none;

  void set(SonarQubeIssueGrouping grouping) => state = grouping;
}

/// Everything loaded so far under the current filter.
class SonarQubeIssues {
  const SonarQubeIssues({
    required this.issues,
    required this.total,
    this.isLoadingMore = false,
    this.loadMoreFailure,
    this.groups = const [],
  });

  final List<SonarQubeIssue> issues;

  /// How many issues match the filter on the server.
  final int total;
  final bool isLoadingMore;
  final Object? loadMoreFailure;

  /// The server's counts per group, when grouping is on.
  final List<SonarQubeIssueGroup> groups;

  bool get hasMore =>
      issues.length < total && issues.length < sonarQubeIssuesMaxResults;

  SonarQubeIssues copyWith({
    bool? isLoadingMore,
    Object? loadMoreFailure,
    bool clearFailure = false,
  }) => SonarQubeIssues(
    issues: issues,
    total: total,
    groups: groups,
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
    final grouping = ref.watch(
      sonarQubeIssueGroupingNotifierProvider(projectKey),
    );
    final result = await ref
        .watch(sonarQubeRepositoryProvider)
        .fetchIssues(projectKey, filter: filter, grouping: grouping);
    final page = result.fold((page) => page, (failure) => throw failure);
    recordFreshness(ref, sonarqubeIssuesFreshnessKey(projectKey));
    return SonarQubeIssues(
      issues: page.issues,
      total: page.total,
      groups: page.groups,
    );
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
        .fetchIssues(
          projectKey,
          filter: filter,
          page: nextPage,
          grouping: ref.read(
            sonarQubeIssueGroupingNotifierProvider(projectKey),
          ),
        );
    if (!ref.mounted) return;
    state = AsyncData(switch (result) {
      Ok(value: final page) => SonarQubeIssues(
        issues: [...current.issues, ...page.issues],
        total: page.total,
        groups: current.groups,
      ),
      Err(:final error) => current.copyWith(
        isLoadingMore: false,
        loadMoreFailure: error,
      ),
    });
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
