/// How the issues list is grouped (`US-SQ-ISSUES-02`). The wire value is
/// SonarQube's own facet name, so the counts come from the server and are
/// right beyond the first page.
enum SonarQubeIssueGrouping {
  none('', 'No grouping'),
  file('files', 'By file'),
  rule('rules', 'By rule'),
  severity('severities', 'By severity');

  const SonarQubeIssueGrouping(this.facet, this.label);

  /// Empty for [none]: no facet is asked for.
  final String facet;
  final String label;

  bool get isGrouped => this != SonarQubeIssueGrouping.none;
}

/// One group with the server's count.
class SonarQubeIssueGroup {
  const SonarQubeIssueGroup({required this.label, required this.count});

  final String label;
  final int count;
}

/// Reads `facets: [{property, values: [{val, count}]}]` for [grouping],
/// biggest group first, ties by name. Unknown or malformed entries are
/// skipped; no facet in the response means no groups.
List<SonarQubeIssueGroup> sonarQubeIssueGroups(
  Object? facets,
  SonarQubeIssueGrouping grouping,
) {
  if (facets is! List || !grouping.isGrouped) return const [];
  for (final facet in facets) {
    if (facet is! Map || facet['property'] != grouping.facet) continue;
    final values = facet['values'];
    if (values is! List) return const [];
    final groups =
        <SonarQubeIssueGroup>[
          for (final value in values)
            if (value is Map &&
                value['val'] is String &&
                (value['val'] as String).isNotEmpty &&
                value['count'] is int)
              SonarQubeIssueGroup(
                label: value['val'] as String,
                count: value['count'] as int,
              ),
        ]..sort(
          (a, b) => b.count != a.count
              ? b.count.compareTo(a.count)
              : a.label.compareTo(b.label),
        );
    return groups;
  }
  return const [];
}
