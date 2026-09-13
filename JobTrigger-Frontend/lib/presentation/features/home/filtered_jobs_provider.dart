import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/jenkins/flatten_jobs.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import 'folder_breadcrumb_notifier.dart';
import 'job_search_notifier.dart';
import 'job_tree_notifier.dart';

part 'filtered_jobs_provider.g.dart';

/// The jobs `HomeScreen` should actually display — ported from
/// `HomeViewModel.displayedJobs` (Swift): empty search shows the current
/// breadcrumb folder's contents; a non-empty search flattens and filters
/// the *entire* tree by name, regardless of which folder is open.
@riverpod
List<JenkinsJob> filteredJobs(Ref ref) {
  final rootJobs =
      ref.watch(jobTreeNotifierProvider).value ?? const <JenkinsJob>[];
  final query = ref.watch(jobSearchNotifierProvider);
  final breadcrumb = ref.watch(folderBreadcrumbNotifierProvider);

  if (query.isEmpty) {
    return breadcrumb.isEmpty ? rootJobs : (breadcrumb.last.jobs ?? const []);
  }

  final lowerQuery = query.toLowerCase();
  return flattenJobs(
    rootJobs,
  ).where((job) => job.name.toLowerCase().contains(lowerQuery)).toList();
}
