import 'sonarqube_metrics.dart';
import 'sonarqube_quality_gate.dart';

/// `US-SQ-WATCH-01`: a project the user asked to be told about when its gate
/// fails after a new analysis. Stored on the device only — a credential id,
/// a project key and name, and the analysis already judged. No token, no
/// issue text.
class SonarQubeProjectWatch {
  const SonarQubeProjectWatch({
    required this.credentialId,
    required this.projectKey,
    required this.projectName,
    this.lastAnalysis,
    this.lastGate = QualityGateState.none,
  });

  factory SonarQubeProjectWatch.fromJson(Map<String, dynamic> json) =>
      SonarQubeProjectWatch(
        credentialId: json['credentialId'] as String,
        projectKey: json['projectKey'] as String,
        projectName: json['projectName'] as String,
        lastAnalysis: json['lastAnalysis'] as String?,
        lastGate: QualityGateState.parse(json['lastGate'] as String?),
      );

  /// The SonarQube credential this project belongs to, so a check can rebuild
  /// that credential's client after a restart.
  final String credentialId;
  final String projectKey;
  final String projectName;

  /// The newest analysis this watch has already judged, as the server wrote
  /// it (`api/ce/component`'s `executedAt`). Null before the first check.
  final String? lastAnalysis;

  /// That analysis's gate verdict, so a server that reports no date still
  /// only notifies on a change.
  final QualityGateState lastGate;

  /// One watch per project per credential.
  String get key => '$credentialId|$projectKey';

  SonarQubeProjectWatch withSeenAnalysis(
    String? analysis,
    QualityGateState gate,
  ) => SonarQubeProjectWatch(
    credentialId: credentialId,
    projectKey: projectKey,
    projectName: projectName,
    lastAnalysis: analysis,
    lastGate: gate,
  );

  Map<String, Object?> toJson() => {
    'credentialId': credentialId,
    'projectKey': projectKey,
    'projectName': projectName,
    'lastAnalysis': lastAnalysis,
    'lastGate': lastGate.name,
  };
}

/// A gate-failure notification. Named and counted only: the project's name
/// and the first failing condition, never issue text or a token.
class SonarQubeGateNotification {
  const SonarQubeGateNotification({
    required this.title,
    required this.body,
    required this.credentialId,
    required this.projectKey,
    required this.id,
  });

  final String title;
  final String body;
  final String credentialId;
  final String projectKey;

  /// Stable per analysis, so the same analysis never notifies twice.
  final int id;

  /// AUD-54: the same notification without the project, for while the app
  /// lock is on.
  SonarQubeGateNotification redacted() => SonarQubeGateNotification(
    title: 'A watched project failed its quality gate',
    body: 'Unlock JobTrigger to see which.',
    credentialId: credentialId,
    projectKey: projectKey,
    id: id,
  );
}

/// What happens to one gate watch after a check.
typedef GateWatchOutcome = ({
  SonarQubeProjectWatch? keep,
  SonarQubeGateNotification? notify,
});

/// Decides [watch]'s outcome from the project's current [gate] and
/// [analysisDate] (`api/ce/component`'s `executedAt`). Pure, so the in-app
/// timer and the background task decide identically.
///
/// Rules (the story's "once per analysis"):
/// - the analysis already judged is not news, whatever its gate says;
/// - a **failing** gate on an analysis not seen before is the regression;
/// - a server that reports no date only notifies when the verdict changes,
///   so an old failure cannot re-notify on every check;
/// - everything else updates the watch silently, so a later failure can be
///   recognised as new.
GateWatchOutcome decideGateWatch(
  SonarQubeProjectWatch watch, {
  required SonarQubeQualityGate gate,
  required String? analysisDate,
}) {
  if (analysisDate != null && analysisDate == watch.lastAnalysis) {
    return (keep: watch, notify: null);
  }

  final keep = watch.withSeenAnalysis(analysisDate, gate.state);
  final failingNow = gate.state == QualityGateState.failed;
  final wasFailing = watch.lastGate == QualityGateState.failed;
  final isNews = failingNow && (analysisDate != null || !wasFailing);

  return (
    keep: keep,
    notify: isNews
        ? gateNotification(watch, gate, analysisDate: analysisDate)
        : null,
  );
}

/// "Payments API failed its quality gate" / "Coverage on new code is 62.1%,
/// below 80%".
SonarQubeGateNotification gateNotification(
  SonarQubeProjectWatch watch,
  SonarQubeQualityGate gate, {
  String? analysisDate,
}) {
  final condition = gate.failing.isEmpty ? null : gate.failing.first;
  final body = condition == null
      ? 'The quality gate failed. Tap to open.'
      : '${sonarQubeMetricLabel(condition.metricKey)} is '
            '${formatSonarQubeValue(condition.metricKey, condition.actual)}, '
            '${condition.failsWhen} '
            '${formatSonarQubeValue(condition.metricKey, condition.threshold)}';
  return SonarQubeGateNotification(
    title: '${watch.projectName} failed its quality gate',
    body: body,
    credentialId: watch.credentialId,
    projectKey: watch.projectKey,
    id:
        '${watch.key}|${analysisDate ?? ''}|${gate.state.name}'.hashCode &
        0x7fffffff,
  );
}
