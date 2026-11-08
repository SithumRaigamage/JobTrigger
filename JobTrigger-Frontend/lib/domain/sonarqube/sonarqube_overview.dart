import 'sonarqube_project.dart';
import 'sonarqube_project_summary.dart';
import 'sonarqube_quality_gate.dart';

/// The SonarQube tab's picture of all projects at once (`US-SQ-OVERVIEW-01`):
/// how many pass, which ones need a look, and the totals.
class SonarQubeOverview {
  const SonarQubeOverview({
    required this.failing,
    required this.warning,
    required this.passing,
    required this.notAnalysed,
    required this.unknown,
    required this.bugs,
    required this.vulnerabilities,
    required this.codeSmells,
    required this.needsAttention,
    required this.neverAnalysed,
  });

  /// Projects whose gate failed / warns / passed / has no result.
  final int failing;
  final int warning;
  final int passing;
  final int notAnalysed;

  /// Projects whose numbers have not arrived yet (or could not be loaded):
  /// counted separately so they are never mistaken for passing.
  final int unknown;

  /// Totals over the analysed projects.
  final int bugs;
  final int vulnerabilities;
  final int codeSmells;

  /// Failed and warning projects, worst first.
  final List<SonarQubeProject> needsAttention;

  /// Projects with no gate result.
  final List<SonarQubeProject> neverAnalysed;

  int get total => failing + warning + passing + notAnalysed + unknown;
  int get analysed => failing + warning + passing;
}

/// Builds the [SonarQubeOverview] from the loaded projects and whatever
/// summaries have arrived. Worst first means failed before warning, then the
/// most bugs plus vulnerabilities, then by name.
SonarQubeOverview buildSonarQubeOverview(
  List<SonarQubeProject> projects,
  Map<String, SonarQubeProjectSummary> summaries,
) {
  var failing = 0, warning = 0, passing = 0, notAnalysed = 0, unknown = 0;
  var bugs = 0, vulnerabilities = 0, codeSmells = 0;
  final attention = <SonarQubeProject>[];
  final never = <SonarQubeProject>[];

  for (final project in projects) {
    final summary = summaries[project.key];
    if (summary == null) {
      unknown++;
      continue;
    }
    switch (summary.gate) {
      case QualityGateState.failed:
        failing++;
        attention.add(project);
      case QualityGateState.warning:
        warning++;
        attention.add(project);
      case QualityGateState.passed:
        passing++;
      case QualityGateState.none:
        notAnalysed++;
        never.add(project);
    }
    if (summary.isAnalysed) {
      bugs += summary.bugs ?? 0;
      vulnerabilities += summary.vulnerabilities ?? 0;
      codeSmells += summary.codeSmells ?? 0;
    }
  }

  int rank(SonarQubeProject p) =>
      summaries[p.key]!.gate == QualityGateState.failed ? 0 : 1;
  attention.sort((a, b) {
    final byGate = rank(a).compareTo(rank(b));
    if (byGate != 0) return byGate;
    final byScore = summaries[b.key]!.severityScore.compareTo(
      summaries[a.key]!.severityScore,
    );
    if (byScore != 0) return byScore;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  never.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return SonarQubeOverview(
    failing: failing,
    warning: warning,
    passing: passing,
    notAnalysed: notAnalysed,
    unknown: unknown,
    bugs: bugs,
    vulnerabilities: vulnerabilities,
    codeSmells: codeSmells,
    needsAttention: attention,
    neverAnalysed: never,
  );
}
