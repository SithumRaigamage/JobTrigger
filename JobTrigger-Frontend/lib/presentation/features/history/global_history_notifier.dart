import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/jenkins/history_entry.dart';
import '../../../domain/jenkins/history_filter.dart';
import '../home/job_tree_notifier.dart';

part 'global_history_notifier.g.dart';

/// Traverses the already-fetched job tree (`JobTreeNotifier`) to build the
/// cross-job top-50 timeline — no separate fetch, per
/// `docs/state-management.md`.
@riverpod
class GlobalHistoryNotifier extends _$GlobalHistoryNotifier {
  @override
  Future<List<HistoryEntry>> build() async {
    final jobs = await ref.watch(jobTreeNotifierProvider.future);
    return buildHistoryTimeline(jobs);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}

/// P14-09: the result filter chips on Global History
/// (`UI-UX/screens/08-global-history`).
@riverpod
class GlobalHistoryFilterNotifier extends _$GlobalHistoryFilterNotifier {
  @override
  HistoryResultFilter build() => HistoryResultFilter.all;

  void select(HistoryResultFilter filter) => state = filter;
}

/// The timeline with the chosen filter applied, split into day sections.
@riverpod
AsyncValue<List<(DateTime, List<HistoryEntry>)>> filteredGlobalHistory(
  Ref ref,
) {
  final filter = ref.watch(globalHistoryFilterNotifierProvider);
  return ref
      .watch(globalHistoryNotifierProvider)
      .whenData(
        (entries) => groupHistoryByDay([
          for (final entry in entries)
            if (filter.matches(entry.build)) entry,
        ]),
      );
}
