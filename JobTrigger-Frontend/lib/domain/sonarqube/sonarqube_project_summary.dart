import 'sonarqube_quality_gate.dart';

/// The few numbers shown on a project card and in the overview, for many
/// projects at once (`api/measures/search`): its quality-gate verdict and the
/// headline counts.
class SonarQubeProjectSummary {
  const SonarQubeProjectSummary({
    required this.gate,
    this.bugs,
    this.vulnerabilities,
    this.codeSmells,
    this.coverage,
  });

  /// [QualityGateState.none] when the project has no gate result, i.e. it
  /// has not been analysed.
  final QualityGateState gate;
  final int? bugs;
  final int? vulnerabilities;
  final int? codeSmells;

  /// Percent, 0–100; null when the server computed none.
  final double? coverage;

  bool get isAnalysed => gate != QualityGateState.none;

  /// Failed or warning: the projects that need a look.
  bool get needsAttention =>
      gate == QualityGateState.failed || gate == QualityGateState.warning;

  /// Bugs plus vulnerabilities: what "worse" means when ordering projects.
  int get severityScore => (bugs ?? 0) + (vulnerabilities ?? 0);
}

/// The metrics asked for. `alert_status` is the quality-gate verdict.
const sonarQubeSummaryMetricKeys = [
  'alert_status',
  'bugs',
  'vulnerabilities',
  'code_smells',
  'coverage',
];

/// `api/measures/search` takes at most 100 project keys per call.
const sonarQubeSummaryBatchSize = 100;
