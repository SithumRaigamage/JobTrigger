import '../../../core/theme/app_colors.dart';
import '../../../domain/sonarqube/sonarqube_quality_gate.dart';

/// How a quality-gate verdict reads and looks, shared by the project cards,
/// the overview and the project page so one verdict is never drawn two ways.
String gateLabel(QualityGateState state) => switch (state) {
  QualityGateState.passed => 'Passed',
  QualityGateState.warning => 'Warning',
  QualityGateState.failed => 'Failed',
  QualityGateState.none => 'Not analyzed',
};

StatusTone gateTone(QualityGateState state) => switch (state) {
  QualityGateState.passed => StatusTone.success,
  QualityGateState.warning => StatusTone.unstable,
  QualityGateState.failed => StatusTone.failure,
  QualityGateState.none => StatusTone.neutral,
};

/// Failing first, then warning, passed, and never-analysed last.
int gateRank(QualityGateState? state) => switch (state) {
  QualityGateState.failed => 0,
  QualityGateState.warning => 1,
  QualityGateState.passed => 2,
  QualityGateState.none => 3,
  null => 4, // not loaded yet
};
