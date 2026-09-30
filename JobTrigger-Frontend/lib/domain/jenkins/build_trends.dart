import 'jenkins_build.dart';

/// Fewer finished builds than this and trends would mislead (US-JX-15).
const minBuildsForTrends = 5;

/// One point on the duration sparkline, oldest first.
typedef TrendPoint = ({int number, double durationMillis, bool failed});

/// Success rate and durations over a job's recent finished builds
/// (US-JX-15). Computed locally from already-loaded history: no request.
class BuildTrends {
  const BuildTrends({
    required this.sampleSize,
    required this.successRate,
    required this.averageMillis,
    required this.p90Millis,
    required this.points,
  });

  /// Finished builds the stats are based on.
  final int sampleSize;

  /// 0–1: SUCCESS over all finished builds (UNSTABLE counts as not
  /// successful).
  final double successRate;
  final double averageMillis;
  final double p90Millis;
  final List<TrendPoint> points;
}

/// Trends over the newest [window] finished builds of [builds] (newest
/// first, as history returns them), or null below [minBuildsForTrends].
/// Running builds are skipped, since their duration isn't final.
BuildTrends? buildTrends(List<JenkinsBuild> builds, {int window = 20}) {
  final finished = builds
      .where((build) => !build.building && build.result != null)
      .take(window)
      .toList();
  if (finished.length < minBuildsForTrends) return null;

  final durations = finished.map((build) => build.duration ?? 0).toList()
    ..sort();
  final successes = finished.where((build) => build.result == 'SUCCESS');
  // Nearest-rank percentile.
  final p90Index = ((durations.length * 0.9).ceil() - 1).clamp(
    0,
    durations.length - 1,
  );
  return BuildTrends(
    sampleSize: finished.length,
    successRate: successes.length / finished.length,
    averageMillis:
        durations.reduce((sum, value) => sum + value) / durations.length,
    p90Millis: durations[p90Index],
    points: [
      for (final build in finished.reversed)
        (
          number: build.number,
          durationMillis: build.duration ?? 0,
          failed: build.result == 'FAILURE',
        ),
    ],
  );
}
