import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/jenkins/flatten_jobs.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import 'folder_breadcrumb_notifier.dart';
import 'folder_contents_notifier.dart';
import 'job_search_notifier.dart';
import 'job_tree_notifier.dart';
import 'views_notifier.dart';

part 'visible_jobs_provider.g.dart';

/// The jobs `HomeScreen` shows (replaces `filteredJobsProvider`, P11-05).
///
/// - **No search:** the current breadcrumb folder's children, fetched
///   lazily by `FolderContentsNotifier`.
/// - **Search:** the recursive crawl (`JobTreeNotifier`, fetched only once
///   someone searches) flattened and filtered by label or name across
///   every folder, as `HomeViewModel.displayedJobs` (Swift) did.
///
/// An `AsyncValue` because both sources load on demand; `HomeScreen`
/// renders its loading and error states.
@riverpod
AsyncValue<List<JenkinsJob>> visibleJobs(Ref ref) {
  final query = ref.watch(jobSearchNotifierProvider);
  if (query.isEmpty) {
    final breadcrumb = ref.watch(folderBreadcrumbNotifierProvider);
    // The root is the selected view's listing (US-JX-17), or the server
    // root for the primary view.
    final root = ref.watch(selectedViewNotifierProvider) ?? rootFolderKey;
    // Watch the root and every folder on the path, not just the last one:
    // it keeps ancestors cached so "Back" is instant, and releases them
    // when the path (or Home) goes away. No timers involved.
    final path = [root, for (final folder in breadcrumb) folder.url];
    final levels = [
      for (final folderKey in path)
        ref.watch(folderContentsNotifierProvider(folderKey)),
    ];
    return levels.last;
  }

  final lowerQuery = query.toLowerCase();
  return ref
      .watch(jobTreeNotifierProvider)
      .whenData(
        (jobs) => flattenJobs(jobs)
            .where(
              (job) =>
                  job.label.toLowerCase().contains(lowerQuery) ||
                  job.name.toLowerCase().contains(lowerQuery),
            )
            .toList(),
      );
}

/// Re-fetches whatever [visibleJobsProvider] is currently showing — backs
/// pull-to-refresh and the error view's retry.
Future<void> refreshVisibleJobs(WidgetRef ref) async {
  final query = ref.read(jobSearchNotifierProvider);
  if (query.isNotEmpty) {
    return ref.read(jobTreeNotifierProvider.notifier).refresh();
  }
  final breadcrumb = ref.read(folderBreadcrumbNotifierProvider);
  final root = ref.read(selectedViewNotifierProvider) ?? rootFolderKey;
  final folderKey = breadcrumb.isEmpty ? root : breadcrumb.last.url;
  return ref.read(folderContentsNotifierProvider(folderKey).notifier).refresh();
}
