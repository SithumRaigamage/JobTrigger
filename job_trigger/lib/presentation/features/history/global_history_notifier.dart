import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/jenkins/history_entry.dart';
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
