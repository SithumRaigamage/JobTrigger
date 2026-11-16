import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_analysis_status.dart';
import '../../../domain/sonarqube/sonarqube_issue.dart';
import '../../../domain/sonarqube/sonarqube_measure_delta.dart';

part 'sonarqube_insights_notifiers.g.dart';

/// A project's analysis status (`US-SQ-CE-01`), read when the page opens and
/// on pull-to-refresh — never polled, like the rest of the epic.
@riverpod
class SonarQubeAnalysisStatusNotifier
    extends _$SonarQubeAnalysisStatusNotifier {
  @override
  Future<SonarQubeAnalysisStatus> build(String projectKey) async {
    final result = await ref
        .watch(sonarQubeRepositoryProvider)
        .fetchAnalysisStatus(projectKey);
    return result.fold((status) => status, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

/// Which measures the project page shows (`US-SQ-QUALITY-08`): the overall
/// numbers, or the new-code ones the quality gate is judged on.
enum SonarQubeMeasureScope { overall, newCode }

@riverpod
class SonarQubeMeasureScopeNotifier extends _$SonarQubeMeasureScopeNotifier {
  @override
  SonarQubeMeasureScope build() => SonarQubeMeasureScope.overall;

  void set(SonarQubeMeasureScope scope) => state = scope;
}

/// A project's new-code measures (`US-SQ-QUALITY-08`). Empty when the server
/// computes none — the switch is then hidden rather than showing zeros.
@riverpod
class SonarQubeNewCodeMeasuresNotifier
    extends _$SonarQubeNewCodeMeasuresNotifier {
  @override
  Future<Map<String, String>> build(String projectKey) async {
    final result = await ref
        .watch(sonarQubeRepositoryProvider)
        .fetchNewCodeMeasures(projectKey);
    return result.fold((measures) => measures, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

/// Each measure's change since the previous analysis (`US-SQ-QUALITY-09`),
/// keyed by metric; a metric with one data point is absent.
@riverpod
class SonarQubeMeasureDeltasNotifier extends _$SonarQubeMeasureDeltasNotifier {
  @override
  Future<Map<String, SonarQubeMeasureDelta>> build(String projectKey) async {
    final result = await ref
        .watch(sonarQubeRepositoryProvider)
        .fetchMeasureDeltas(projectKey);
    return result.fold(
      (deltas) => {for (final delta in deltas) delta.metricKey: delta},
      (failure) => throw failure,
    );
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

/// What the cross-project issue list holds (`US-SQ-ISSUES-01`), plus the
/// filter and page the next "Load more" continues from.
class SonarQubeMyIssues {
  const SonarQubeMyIssues({
    required this.issues,
    required this.total,
    this.filter = const SonarQubeIssueFilter(),
    this.loadingMore = false,
  });

  final List<SonarQubeIssue> issues;

  /// How many the server says exist, which can exceed what is loaded.
  final int total;
  final SonarQubeIssueFilter filter;
  final bool loadingMore;

  /// SonarQube refuses to page past 10,000 results (`US-SQ-QUALITY-03`).
  bool get hasMore => issues.length < total && issues.length < 10000;
}

/// The unresolved issues assigned to the token's user, across every project
/// (`US-SQ-ISSUES-01`). Filtering re-queries the server; "Load more" pages it.
@riverpod
class SonarQubeMyIssuesNotifier extends _$SonarQubeMyIssuesNotifier {
  SonarQubeIssueFilter _filter = const SonarQubeIssueFilter();

  @override
  Future<SonarQubeMyIssues> build() => _fetch(1);

  Future<SonarQubeMyIssues> _fetch(int page) async {
    final result = await ref
        .read(sonarQubeRepositoryProvider)
        .fetchMyIssues(filter: _filter, page: page);
    return result.fold(
      (page) => SonarQubeMyIssues(
        issues: page.issues,
        total: page.total,
        filter: _filter,
      ),
      (failure) => throw failure,
    );
  }

  Future<void> setFilter(SonarQubeIssueFilter filter) async {
    _filter = filter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(1));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      SonarQubeMyIssues(
        issues: current.issues,
        total: current.total,
        filter: current.filter,
        loadingMore: true,
      ),
    );
    final page = current.issues.length ~/ sonarQubeIssuesPageSize + 1;
    final next = await AsyncValue.guard(() => _fetch(page));
    if (next.hasError || next.value == null) {
      state = AsyncData(current);
      return;
    }
    state = AsyncData(
      SonarQubeMyIssues(
        issues: [...current.issues, ...next.value!.issues],
        total: next.value!.total,
        filter: current.filter,
      ),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(1));
  }
}
