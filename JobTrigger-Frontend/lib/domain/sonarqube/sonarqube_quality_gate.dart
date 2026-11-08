/// A project's quality gate result (`US-SQ-QUALITY-01`) —
/// `GET api/qualitygates/project_status`'s `projectStatus`.
class SonarQubeQualityGate {
  const SonarQubeQualityGate({required this.state, required this.conditions});

  final QualityGateState state;
  final List<QualityGateCondition> conditions;

  /// The conditions that broke the gate. Passing ones are not listed: the
  /// point of the breakdown is to say what to fix.
  List<QualityGateCondition> get failing =>
      conditions.where((c) => c.failed).toList();
}

/// SonarQube's `status`: `OK`, `WARN` (older servers), `ERROR`, `NONE`.
/// Anything unrecognised is [none]: "no verdict" is safer to show than a
/// guessed pass or fail.
enum QualityGateState {
  passed,
  warning,
  failed,

  /// No analysis yet, so no verdict.
  none;

  static QualityGateState parse(String? status) => switch (status) {
    'OK' => passed,
    'WARN' => warning,
    'ERROR' => failed,
    _ => none,
  };
}

/// One rule of the gate with the project's actual value against it.
class QualityGateCondition {
  const QualityGateCondition({
    required this.metricKey,
    required this.comparator,
    required this.threshold,
    required this.actual,
    required this.failed,
  });

  /// e.g. `new_coverage`, `bugs`.
  final String metricKey;

  /// `GT` or `LT` (also `EQ`, `NE`): the gate **fails when** the actual
  /// value is greater than / less than the [threshold].
  final String comparator;
  final String? threshold;
  final String? actual;
  final bool failed;

  /// "below" / "above" / "equal to" / "different from" — how the actual
  /// value breaks the threshold, in words.
  String get failsWhen => switch (comparator) {
    'LT' => 'below',
    'GT' => 'above',
    'EQ' => 'equal to',
    'NE' => 'different from',
    _ => comparator.toLowerCase(),
  };
}
