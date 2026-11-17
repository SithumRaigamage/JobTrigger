import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_issue.dart';

part 'sonarqube_issue_search_notifier.g.dart';

/// What the cross-project issue search holds (`US-SQ-ISSUES-03`).
class SonarQubeIssueSearch {
  const SonarQubeIssueSearch({
    this.term = '',
    this.field = SonarQubeIssueSearchField.rule,
    this.filter = const SonarQubeIssueFilter(),
    this.issues = const [],
    this.total = 0,
    this.loadingMore = false,
  });

  final String term;
  final SonarQubeIssueSearchField field;
  final SonarQubeIssueFilter filter;
  final List<SonarQubeIssue> issues;
  final int total;
  final bool loadingMore;

  /// False until something has been searched: the screen then shows its
  /// prompt instead of an empty-result message.
  bool get hasSearched => term.isNotEmpty;

  /// SonarQube refuses to page past 10,000 results.
  bool get hasMore => issues.length < total && issues.length < 10000;

  SonarQubeIssueSearch copyWith({
    List<SonarQubeIssue>? issues,
    int? total,
    bool? loadingMore,
  }) => SonarQubeIssueSearch(
    term: term,
    field: field,
    filter: filter,
    issues: issues ?? this.issues,
    total: total ?? this.total,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// Searches issues across every project (`US-SQ-ISSUES-03`) by rule, tag,
/// file path or issue key. Nothing is requested until a term is submitted;
/// the type and severity chips narrow the same server query.
@riverpod
class SonarQubeIssueSearchNotifier extends _$SonarQubeIssueSearchNotifier {
  @override
  Future<SonarQubeIssueSearch> build() async => const SonarQubeIssueSearch();

  Future<SonarQubeIssueSearch> _fetch(
    String term,
    SonarQubeIssueSearchField field,
    SonarQubeIssueFilter filter,
    int page,
  ) async {
    final result = await ref
        .read(sonarQubeRepositoryProvider)
        .searchIssues(term, field: field, filter: filter, page: page);
    return result.fold<SonarQubeIssueSearch>(
      (found) => SonarQubeIssueSearch(
        term: term,
        field: field,
        filter: filter,
        issues: found.issues,
        total: found.total,
      ),
      (Object failure) => throw failure,
    );
  }

  Future<void> search(String term, SonarQubeIssueSearchField field) async {
    final trimmed = term.trim();
    final filter = state.value?.filter ?? const SonarQubeIssueFilter();
    if (trimmed.isEmpty) {
      state = AsyncData(SonarQubeIssueSearch(field: field, filter: filter));
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(trimmed, field, filter, 1));
  }

  Future<void> setFilter(SonarQubeIssueFilter filter) async {
    final current = state.value;
    if (current == null) return;
    if (!current.hasSearched) {
      state = AsyncData(
        SonarQubeIssueSearch(field: current.field, filter: filter),
      );
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(current.term, current.field, filter, 1),
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    final page = current.issues.length ~/ sonarQubeIssuesPageSize + 1;
    final next = await AsyncValue.guard(
      () => _fetch(current.term, current.field, current.filter, page),
    );
    if (!ref.mounted) return;
    final more = next.value;
    state = AsyncData(
      more == null
          ? current.copyWith(loadingMore: false)
          : current.copyWith(
              issues: [...current.issues, ...more.issues],
              total: more.total,
              loadingMore: false,
            ),
    );
  }
}
