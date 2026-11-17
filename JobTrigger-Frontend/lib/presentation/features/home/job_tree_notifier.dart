import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/no_retry.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import 'folder_contents_notifier.dart';

part 'job_tree_notifier.g.dart';

/// The recursive crawl of the active server (6 folder levels) — standard
/// shape from `docs/architecture.md §4`. Since P11-05 it backs only
/// cross-folder search and the global history timeline; Home browses
/// lazily with `FolderContentsNotifier`. So it's first fetched when someone
/// searches or opens global history, not on every Home load (AUD-20).
@Riverpod(retry: noRetry)
class JobTreeNotifier extends _$JobTreeNotifier {
  @override
  Future<List<JenkinsJob>> build() async {
    // Back online after a failed load: try again without the user having
    // to find the retry button.
    ref.listen(offlineSnapshotNotifierProvider, (previous, next) {
      if (previous != null && next == null && state.hasError) {
        ref.invalidateSelf();
      }
    });
    final result = await ref.watch(jenkinsRepositoryProvider).fetchJobTree();
    return result.fold((jobs) => jobs, (failure) => throw failure);
  }

  Future<void> refresh() async => ref.invalidateSelf();
}
