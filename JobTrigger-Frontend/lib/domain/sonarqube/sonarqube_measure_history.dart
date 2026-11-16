/// A measure's history for the trends chart (`US-SQ-QUALITY-11`), from
/// `api/measures/search_history`.
class SonarQubeMeasurePoint {
  const SonarQubeMeasurePoint({required this.date, required this.value});

  final DateTime date;
  final num value;

  /// Short, locale-neutral day label for the axis and the readout.
  String get dateLabel => '${date.day}/${date.month}';
}

class SonarQubeMeasureHistory {
  const SonarQubeMeasureHistory({
    required this.metric,
    required this.points,
    this.unit = '',
  });

  final String metric;

  /// Oldest first, as the server sends it.
  final List<SonarQubeMeasurePoint> points;

  /// `%` for coverage and duplication, empty for counts.
  final String unit;

  /// A line needs two points; one is a dot, not a trend.
  bool get hasEnoughHistory => points.length >= 2;

  SonarQubeMeasurePoint? get latest => points.isEmpty ? null : points.last;

  SonarQubeMeasurePoint? get lowest => _extreme(least: true);
  SonarQubeMeasurePoint? get highest => _extreme(least: false);

  SonarQubeMeasurePoint? _extreme({required bool least}) {
    if (points.isEmpty) return null;
    return points.reduce(
      (a, b) => (least ? b.value < a.value : b.value > a.value) ? b : a,
    );
  }

  String format(num value) {
    final rounded = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$rounded$unit';
  }
}

/// The measures the chart offers. Kept small on purpose: one obvious number
/// per question ("is coverage improving, are bugs growing").
class SonarQubeTrendMetric {
  const SonarQubeTrendMetric(this.metric, this.label, this.unit);

  final String metric;
  final String label;
  final String unit;
}

const sonarQubeTrendMetrics = [
  SonarQubeTrendMetric('coverage', 'Coverage', '%'),
  SonarQubeTrendMetric('bugs', 'Bugs', ''),
  SonarQubeTrendMetric('code_smells', 'Code smells', ''),
  SonarQubeTrendMetric('duplicated_lines_density', 'Duplication', '%'),
];

/// Which point a tap at [x] in a chart [width] px wide selects: the nearest
/// one. Pure so the interaction is testable without a render.
int nearestSonarQubePointIndex(
  List<SonarQubeMeasurePoint> points,
  double x,
  double width,
) {
  if (points.length < 2 || width <= 0) return 0;
  final step = width / (points.length - 1);
  return (x / step).round().clamp(0, points.length - 1);
}
