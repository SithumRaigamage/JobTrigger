import 'sonarqube_metrics.dart';

/// One measure's change since the previous analysis (`US-SQ-QUALITY-09`),
/// from `GET api/measures/search_history?ps=2`.
class SonarQubeMeasureDelta {
  const SonarQubeMeasureDelta({
    required this.metricKey,
    required this.previous,
    required this.current,
  });

  final String metricKey;
  final double previous;
  final double current;

  double get change => current - previous;

  /// Nothing moved, so nothing is worth showing.
  bool get isChange => change != 0;

  /// Whether this movement is a regression: more bugs is worse, more
  /// coverage is better, and a rating going from 1 (A) to 2 (B) is worse.
  bool get isWorse =>
      change != 0 &&
      (sonarQubeHigherIsWorse(metricKey) ? change > 0 : change < 0);

  /// "+2", "−1.5%", "+1 grade" — the change in the metric's own unit,
  /// signed. A rating moves by grades, not by letters: 1 (A) to 2 (B) is
  /// one grade worse.
  String get label {
    if (change == 0) return '0';
    final sign = change > 0 ? '+' : '−';
    if (metricKey.endsWith('_rating')) {
      final grades = change.abs().round();
      return '$sign$grades grade${grades == 1 ? '' : 's'}';
    }
    return '$sign${formatSonarQubeValue(metricKey, change.abs().toString())}';
  }
}

/// For most metrics a bigger number is worse (bugs, duplication, technical
/// debt, and ratings, where 1 is the best grade). For coverage and the
/// "reviewed" percentages a bigger number is better.
bool sonarQubeHigherIsWorse(String metricKey) =>
    !metricKey.endsWith('coverage') && !metricKey.endsWith('_reviewed');

/// Turns two history points into a delta, or null when either value is
/// missing or unreadable — a change is never invented from one point.
SonarQubeMeasureDelta? sonarQubeMeasureDelta(
  String metricKey,
  String? previous,
  String? current,
) {
  final before = double.tryParse(previous ?? '');
  final after = double.tryParse(current ?? '');
  if (before == null || after == null) return null;
  return SonarQubeMeasureDelta(
    metricKey: metricKey,
    previous: before,
    current: after,
  );
}
