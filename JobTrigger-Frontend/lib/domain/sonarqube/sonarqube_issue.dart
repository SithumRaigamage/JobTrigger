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
    this.component,
    this.rule,
    this.effort,
    this.tags = const [],
    this.author,
    this.status,
    this.creationDate,
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

  /// The file's full component key (`project:path/File.java`), which the
  /// source lookup needs; [file] has the project prefix removed.
  final String? component;

  /// The rule that raised it, e.g. `java:S1135`.
  final String? rule;

  /// Estimated time to fix, as SonarQube writes it (`5min`, `1h 30min`).
  final String? effort;
  final List<String> tags;
  final String? author;

  /// `OPEN`, `CONFIRMED`, `REOPENED`, `RESOLVED` or `CLOSED`.
  final String? status;
  final DateTime? creationDate;

  /// `src/Foo.java:42`, `src/Foo.java`, or null.
  String? get location =>
      file == null ? null : (line == null ? file : '$file:$line');

  /// Two issues are the same issue when they have the same key: the key is
  /// the server's id for it, and a reloaded list yields new objects.
  @override
  bool operator ==(Object other) => other is SonarQubeIssue && other.key == key;

  @override
  int get hashCode => key.hashCode;
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

/// A line of source code around an issue (`api/sources/show`).
class SonarQubeSourceLine {
  const SonarQubeSourceLine({required this.number, required this.code});

  final int number;

  /// Plain text: the server's HTML highlighting is removed.
  final String code;
}

/// What the issue screen shows beyond the issue itself: the rule's name and
/// the code around the issue. Either may be missing without the other.
class SonarQubeIssueContext {
  const SonarQubeIssueContext({this.ruleName, this.snippet = const []});

  final String? ruleName;
  final List<SonarQubeSourceLine> snippet;
}

/// SonarQube's source lines are HTML (`<span class="k">if</span> a &lt; b`).
/// This turns one into the plain code it shows: tags removed, the handful of
/// entities SonarQube writes decoded.
String sonarQubeCodeToText(String html) => html
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&#x27;', "'")
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&'); // last, so "&amp;lt;" stays "&lt;"

/// Source lines shown on either side of the issue's line.
const sonarQubeSnippetContext = 4;

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
