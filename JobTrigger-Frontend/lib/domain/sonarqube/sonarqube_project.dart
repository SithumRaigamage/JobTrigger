/// A SonarQube project (`US-SQ-PROJ-01`) —
/// `GET api/projects/search`'s `components[]`.
class SonarQubeProject {
  const SonarQubeProject({
    required this.key,
    required this.name,
    required this.lastAnalysisDate,
  });

  /// The stable id every other SonarQube call is keyed by.
  final String key;
  final String name;

  /// Null for a project that exists but has never been analysed.
  final DateTime? lastAnalysisDate;
}
