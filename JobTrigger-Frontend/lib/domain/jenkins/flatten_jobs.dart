import 'jenkins_job.dart';

/// Flattens the nested job tree for global search — ported from
/// `HomeViewModel.flattenJobs` (Swift). Includes folders themselves in the
/// output (not just leaf jobs), matching the original: a folder whose name
/// matches the search query is itself a valid search result.
List<JenkinsJob> flattenJobs(List<JenkinsJob> jobs) {
  final flattened = <JenkinsJob>[];
  for (final job in jobs) {
    flattened.add(job);
    if (job.jobs != null) {
      flattened.addAll(flattenJobs(job.jobs!));
    }
  }
  return flattened;
}
