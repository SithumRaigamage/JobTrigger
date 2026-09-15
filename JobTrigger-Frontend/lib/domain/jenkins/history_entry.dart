import 'jenkins_build.dart';
import 'jenkins_job.dart';

/// Ported from `GlobalBuild` (Swift).
class HistoryEntry {
  const HistoryEntry({required this.jobName, required this.build});

  final String jobName;
  final JenkinsBuild build;

  String get id => '$jobName-${build.number}';
}

/// Builds the cross-job history timeline from an already-fetched job tree
/// (reuses `JobTreeNotifier`'s data — see `tasks/phase-5-...md` P5-14, no
/// separate fetch). The tree fetch only carries each job's `lastBuild`
/// (not a full `builds[]` history, per `docs/api-reference.md`'s split
/// between the tree and detail/history endpoints), so this yields one
/// entry per job — its most recent build — sorted newest first and capped
/// at [limit].
List<HistoryEntry> buildHistoryTimeline(
  List<JenkinsJob> jobs, {
  int limit = 50,
}) {
  final entries = <HistoryEntry>[];

  void collect(List<JenkinsJob> jobs) {
    for (final job in jobs) {
      if (job.lastBuild != null) {
        entries.add(HistoryEntry(jobName: job.name, build: job.lastBuild!));
      }
      if (job.jobs != null) collect(job.jobs!);
    }
  }

  collect(jobs);
  entries.sort((a, b) => b.build.timestamp.compareTo(a.build.timestamp));
  return entries.take(limit).toList();
}
