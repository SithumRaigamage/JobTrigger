/// The measure the breakdown reads (`US-SQ-QUALITY-13`). SonarQube sends it
/// as one string, e.g. `java=1200;js=340`.
const sonarQubeLanguageMetricKey = 'ncloc_language_distribution';

/// One language's share of the project's lines.
class SonarQubeLanguageLines {
  const SonarQubeLanguageLines({
    required this.language,
    required this.lines,
    required this.share,
  });

  /// The metric's own short key, e.g. `java`.
  final String language;
  final int lines;

  /// 0–100, rounded for display.
  final int share;
}

/// A project's lines split by language, biggest first. Empty when the server
/// has no distribution, which is how the section stays off the page.
class SonarQubeLanguageBreakdown {
  const SonarQubeLanguageBreakdown({required this.languages});

  final List<SonarQubeLanguageLines> languages;

  bool get isEmpty => languages.isEmpty;

  static const empty = SonarQubeLanguageBreakdown(languages: []);

  /// Parses `java=1200;js=340`. Fragments that are not `key=<positive int>`
  /// are skipped rather than failing the whole breakdown, and an all-zero
  /// string is the same as no distribution.
  static SonarQubeLanguageBreakdown parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return empty;
    final counts = <String, int>{};
    for (final fragment in raw.split(';')) {
      final separator = fragment.indexOf('=');
      if (separator <= 0) continue;
      final key = fragment.substring(0, separator).trim();
      final lines = int.tryParse(fragment.substring(separator + 1).trim());
      if (key.isEmpty || lines == null || lines <= 0) continue;
      counts[key] = (counts[key] ?? 0) + lines;
    }
    final total = counts.values.fold<int>(0, (sum, lines) => sum + lines);
    if (total <= 0) return empty;

    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byLines = b.value.compareTo(a.value);
        return byLines != 0 ? byLines : a.key.compareTo(b.key);
      });
    return SonarQubeLanguageBreakdown(
      languages: [
        for (final entry in entries)
          SonarQubeLanguageLines(
            language: entry.key,
            lines: entry.value,
            share: (entry.value * 100 / total).round(),
          ),
      ],
    );
  }
}
