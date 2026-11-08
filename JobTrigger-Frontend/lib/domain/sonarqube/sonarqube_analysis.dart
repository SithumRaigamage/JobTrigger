/// One past analysis of a project (`US-SQ-QUALITY-04`) —
/// `GET api/project_analyses/search`'s `analyses[]`. A snapshot of the
/// project's data, not a job run, so there is nothing to open.
class SonarQubeAnalysis {
  const SonarQubeAnalysis({
    required this.key,
    required this.date,
    required this.projectVersion,
  });

  final String key;
  final DateTime? date;

  /// The version the analysis was tagged with, when the build set one.
  final String? projectVersion;
}

/// Analyses fetched (newest first). History is a "when was this last
/// checked" aid, so one page is enough.
const sonarQubeAnalysesLimit = 50;
