import 'jenkins_job.dart';

/// P14-07: the "Running · Failing · Passing" strip at the top of Home
/// (`UI-UX/screens/05-home-jenkins-dark`), counted from the jobs listed at
/// the current level. Folders aren't counted, and a job is counted once:
/// one that is building is Running whatever its last result was.
///
/// Reads Jenkins' job ball `color` (`blue` = last build passed, `red` =
/// failed, an `_anime` suffix = building now), the same field the job rows
/// colour their status dot from.
class JobStatusSummary {
  const JobStatusSummary({
    required this.running,
    required this.failing,
    required this.passing,
  });

  factory JobStatusSummary.of(Iterable<JenkinsJob> jobs) {
    var running = 0, failing = 0, passing = 0;
    for (final job in jobs) {
      if (job.isFolder) continue;
      final color = job.color?.toLowerCase() ?? '';
      if (color.endsWith('_anime') || (job.lastBuild?.building ?? false)) {
        running++;
      } else if (color == 'red') {
        failing++;
      } else if (color == 'blue') {
        passing++;
      }
    }
    return JobStatusSummary(
      running: running,
      failing: failing,
      passing: passing,
    );
  }

  final int running;
  final int failing;
  final int passing;

  /// Nothing to show — an empty folder, or only folders and jobs that have
  /// never built.
  bool get isEmpty => running == 0 && failing == 0 && passing == 0;
}
