/// One issue raised against a project (`US-SQ-QUALITY-03`) —
/// `GET api/issues/search`'s `issues[]`.
class SonarQubeIssue {
  const SonarQubeIssue({
    required this.key,
    required this.type,
    required this.severity,
    required this.message,
    required this.file,
    required this.line,
  });

  final String key;

  /// `BUG` | `VULNERABILITY` | `CODE_SMELL` (older servers may add others,
  /// shown as sent).
  final String type;

  /// `BLOCKER` | `CRITICAL` | `MAJOR` | `MINOR` | `INFO`.
  final String severity;
  final String message;

  /// The file's path within the project, without the project-key prefix;
  /// null for an issue on the project as a whole.
  final String? file;
  final int? line;

  /// `src/Foo.java:42`, `src/Foo.java`, or null.
  String? get location =>
      file == null ? null : (line == null ? file : '$file:$line');
}

/// The issue types and severities the filter offers, in display order.
const sonarQubeIssueTypes = ['BUG', 'VULNERABILITY', 'CODE_SMELL'];
const sonarQubeIssueSeverities = [
  'BLOCKER',
  'CRITICAL',
  'MAJOR',
  'MINOR',
  'INFO',
];

String sonarQubeIssueTypeLabel(String type) => switch (type) {
  'BUG' => 'Bug',
  'VULNERABILITY' => 'Vulnerability',
  'CODE_SMELL' => 'Code smell',
  final other => _title(other),
};

String sonarQubeSeverityLabel(String severity) => _title(severity);

String _title(String raw) {
  final words = raw.replaceAll('_', ' ').toLowerCase().trim();
  if (words.isEmpty) return raw;
  return words[0].toUpperCase() + words.substring(1);
}

/// What the issues list is narrowed to, applied by the server
/// (`US-SQ-QUALITY-03`): the list can be far too large to filter here.
class SonarQubeIssueFilter {
  const SonarQubeIssueFilter({
    this.types = const {},
    this.severities = const {},
  });

  final Set<String> types;
  final Set<String> severities;

  bool get isEmpty => types.isEmpty && severities.isEmpty;

  SonarQubeIssueFilter toggleType(String type) =>
      SonarQubeIssueFilter(types: _toggle(types, type), severities: severities);

  SonarQubeIssueFilter toggleSeverity(String severity) => SonarQubeIssueFilter(
    types: types,
    severities: _toggle(severities, severity),
  );

  static Set<String> _toggle(Set<String> set, String value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  bool operator ==(Object other) =>
      other is SonarQubeIssueFilter &&
      other.types.length == types.length &&
      other.types.containsAll(types) &&
      other.severities.length == severities.length &&
      other.severities.containsAll(severities);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(types),
    Object.hashAllUnordered(severities),
  );
}

/// One page of issues and how many exist in total under the filter.
class SonarQubeIssuePage {
  const SonarQubeIssuePage({required this.issues, required this.total});

  final List<SonarQubeIssue> issues;
  final int total;
}

/// Issues per page.
const sonarQubeIssuesPageSize = 50;
