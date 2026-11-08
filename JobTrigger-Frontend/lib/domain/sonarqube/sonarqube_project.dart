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

/// One page of projects and how many exist in total, so the app can tell a
/// complete list from a partial one.
class SonarQubeProjectsPage {
  const SonarQubeProjectsPage({required this.projects, required this.total});

  final List<SonarQubeProject> projects;

  /// Everything the server would return across all pages.
  final int total;
}
