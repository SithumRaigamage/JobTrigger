import 'jenkins_build.dart';
import 'jenkins_job.dart';

/// Ported from `GlobalBuild` (Swift).
class HistoryEntry {
  const HistoryEntry({required this.jobName, required this.build});

  final String jobName;
  final JenkinsBuild build;

  /// Stable, globally unique row identity — the build's absolute URL.
  /// Previously `'$jobName-$number'`, which collided whenever two jobs in
  /// different folders share a name and build number (every multibranch
  /// repo has a `main` #1), producing duplicate list keys (AUD-09).
  String get id => build.url;
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
        entries.add(HistoryEntry(jobName: job.label, build: job.lastBuild!));
      }
      if (job.jobs != null) collect(job.jobs!);
    }
  }

  collect(jobs);
  entries.sort((a, b) => b.build.timestamp.compareTo(a.build.timestamp));
  return entries.take(limit).toList();
}

/// P14-09: [entries] (newest first) split by the local calendar day their
/// build started, keeping that order — Global History draws one section per
/// day.
List<(DateTime, List<HistoryEntry>)> groupHistoryByDay(
  List<HistoryEntry> entries,
) {
  final groups = <(DateTime, List<HistoryEntry>)>[];
  for (final entry in entries) {
    final started = DateTime.fromMillisecondsSinceEpoch(
      entry.build.timestamp.toInt(),
    );
    final day = DateTime(started.year, started.month, started.day);
    if (groups.isEmpty || groups.last.$1 != day) {
      groups.add((day, [entry]));
    } else {
      groups.last.$2.add(entry);
    }
  }
  return groups;
}
