import 'jenkins_build.dart';

/// Pure ratio function for the build progress bar — kept out of any widget
/// so it's unit-testable without a timer or a widget tree, per
/// `docs/data-models.md`.
class BuildProgress {
  const BuildProgress._();

  /// `(now - build.timestamp) / build.estimatedDuration`, clamped to
  /// `[0, 1]`. [now] defaults to the real clock; overridable for
  /// deterministic tests.
  static double ratioFor(JenkinsBuild build, {DateTime? now}) {
    final estimated = build.estimatedDuration;
    if (estimated == null || estimated <= 0) return 0;

    final currentMillis = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final ratio = (currentMillis - build.timestamp) / estimated;
    return ratio.clamp(0.0, 1.0);
  }
}
