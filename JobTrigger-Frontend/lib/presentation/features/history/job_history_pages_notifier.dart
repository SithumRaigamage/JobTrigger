import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/history_filter.dart';
import '../../../domain/jenkins/jenkins_build.dart';

part 'job_history_pages_notifier.g.dart';

/// Everything loaded so far for one job's history screen (US-JX-06).
class HistoryPages {
  const HistoryPages({
    required this.builds,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<JenkinsBuild> builds;

  /// False once a page came back short — the end of history.
  final bool hasMore;
  final bool isLoadingMore;

  HistoryPages copyWith({
    List<JenkinsBuild>? builds,
    bool? hasMore,
    bool? isLoadingMore,
  }) => HistoryPages(
    builds: builds ?? this.builds,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

/// US-JX-06: job history, [historyPageSize] builds at a time, all the way
/// back. The first page loads with the screen; [loadMore] appends the next.
/// (`JobHistoryNotifier` stays as the simple first-page source for the Run
/// parameter picker.)
@riverpod
class JobHistoryPagesNotifier extends _$JobHistoryPagesNotifier {
  @override
  Future<HistoryPages> build(String jobUrl) async {
    final page = await _fetch(0);
    return HistoryPages(builds: page, hasMore: page.length == historyPageSize);
  }

  Future<List<JenkinsBuild>> _fetch(int start) async {
    final result = await ref
        .read(jenkinsRepositoryProvider)
        .fetchJobHistory(jobUrl, start: start);
    return result.fold((builds) => builds, (failure) => throw failure);
  }

  /// Appends the next page. A failure keeps what's loaded and stops paging
  /// until [refresh], rather than replacing the list with an error.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    final result = await ref
        .read(jenkinsRepositoryProvider)
        .fetchJobHistory(jobUrl, start: current.builds.length);
    if (!ref.mounted) return;
    state = AsyncData(switch (result) {
      Ok(value: final page) => HistoryPages(
        builds: [...current.builds, ...page],
        hasMore: page.length == historyPageSize,
      ),
      Err() => current.copyWith(isLoadingMore: false, hasMore: false),
    });
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

/// US-JX-06: the history screen's filter chips, per job.
@riverpod
class JobHistoryFilterNotifier extends _$JobHistoryFilterNotifier {
  @override
  HistoryFilter build(String jobUrl) => const HistoryFilter();

  void setResult(HistoryResultFilter result) =>
      state = state.copyWith(result: result);

  void toggleStartedByMe() =>
      state = state.copyWith(startedByMe: !state.startedByMe);
}
