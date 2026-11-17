/// A file's value for one ranking measure (`US-SQ-QUALITY-12`).
class SonarQubeFileMeasures {
  const SonarQubeFileMeasures({required this.path, this.value});

  /// Path inside the project, without the project key.
  final String path;
  final num? value;

  /// Full component key, as `api/issues/search` wants it.
  String componentKey(String projectKey) => '$projectKey:$path';
}

class SonarQubeWorstFiles {
  const SonarQubeWorstFiles({
    required this.metric,
    required this.files,
    this.unit = '',
  });

  final String metric;
  final List<SonarQubeFileMeasures> files;
  final String unit;

  String format(num? value) {
    if (value == null) return '—';
    final rounded = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$rounded$unit';
  }
}

/// The rankings offered, each with its own direction: a file with no
/// coverage is worse than one with 90%, a file with more duplication is
/// worse than one with none.
class SonarQubeFileMetric {
  const SonarQubeFileMetric(
    this.metric,
    this.label,
    this.unit, {
    required this.lowestFirst,
  });

  final String metric;
  final String label;
  final String unit;
  final bool lowestFirst;
}

const sonarQubeFileMetrics = [
  SonarQubeFileMetric('coverage', 'Least covered', '%', lowestFirst: true),
  SonarQubeFileMetric(
    'duplicated_lines_density',
    'Most duplicated',
    '%',
    lowestFirst: false,
  ),
  SonarQubeFileMetric('code_smells', 'Most issues', '', lowestFirst: false),
  SonarQubeFileMetric('complexity', 'Most complex', '', lowestFirst: false),
];

/// Ten files, as the story asks.
const sonarQubeWorstFilesLimit = 10;
