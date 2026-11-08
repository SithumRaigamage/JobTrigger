/// The measures shown for a project (`US-SQ-QUALITY-02`), in display order.
const sonarQubeMeasureKeys = [
  'coverage',
  'bugs',
  'vulnerabilities',
  'code_smells',
  'duplicated_lines_density',
  'ncloc',
];

/// Further measures shown when the server has them (`US-SQ-QUALITY-05`):
/// the three A–E ratings and the technical debt in minutes. Asked for in the
/// same request, and left out of the page when not computed.
const sonarQubeExtraMeasureKeys = [
  'reliability_rating',
  'security_rating',
  'sqale_rating',
  'sqale_index',
];

const _labels = {
  'sqale_index': 'Technical debt',
  'coverage': 'Coverage',
  'bugs': 'Bugs',
  'vulnerabilities': 'Vulnerabilities',
  'code_smells': 'Code smells',
  'duplicated_lines_density': 'Duplication',
  'ncloc': 'Lines of code',
  'new_coverage': 'Coverage on new code',
  'new_bugs': 'New bugs',
  'new_vulnerabilities': 'New vulnerabilities',
  'new_code_smells': 'New code smells',
  'new_duplicated_lines_density': 'Duplication on new code',
  'new_security_hotspots_reviewed': 'Security hotspots reviewed on new code',
  'security_hotspots_reviewed': 'Security hotspots reviewed',
  'reliability_rating': 'Reliability rating',
  'security_rating': 'Security rating',
  'sqale_rating': 'Maintainability rating',
  'new_reliability_rating': 'Reliability rating on new code',
  'new_security_rating': 'Security rating on new code',
  'new_maintainability_rating': 'Maintainability rating on new code',
};

/// A readable name for a SonarQube metric key. Unknown keys are turned into
/// words (`new_lines` → "New lines") so a custom gate condition still reads.
String sonarQubeMetricLabel(String key) {
  final known = _labels[key];
  if (known != null) return known;
  final words = key.replaceAll('_', ' ').trim();
  if (words.isEmpty) return key;
  return words[0].toUpperCase() + words.substring(1);
}

bool _isPercent(String key) =>
    key.endsWith('coverage') ||
    key.endsWith('density') ||
    key.endsWith('_reviewed');

bool _isRating(String key) => key.endsWith('_rating');

/// A metric value for display: percentages with a `%` and at most one
/// decimal, ratings as A–E, other numbers with thousands separators. A
/// missing value is "—", never "0": zero would claim a verified perfect
/// score the server never gave (`US-SQ-QUALITY-02`).
String formatSonarQubeValue(String key, String? value) {
  if (value == null || value.isEmpty) return '—';
  final number = double.tryParse(value);
  if (number == null) return value;
  if (key == 'sqale_index') return formatTechnicalDebt(number.round());
  if (_isRating(key)) {
    // SonarQube sends ratings as 1.0 … 5.0.
    final index = number.round() - 1;
    return index >= 0 && index < 5 ? 'ABCDE'[index] : value;
  }
  if (_isPercent(key)) {
    final fixed = number.toStringAsFixed(1);
    return '${fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed}%';
  }
  return _withSeparators(number.round().toString());
}

String _withSeparators(String digits) {
  final negative = digits.startsWith('-');
  final body = negative ? digits.substring(1) : digits;
  final out = StringBuffer();
  for (var i = 0; i < body.length; i++) {
    if (i > 0 && (body.length - i) % 3 == 0) out.write(',');
    out.write(body[i]);
  }
  return negative ? '-$out' : out.toString();
}

/// Technical debt from minutes, the way SonarQube writes it: a working day
/// is 8 hours. `45min`, `3h 20min`, `2d 3h`; nothing at all is `0min`.
String formatTechnicalDebt(int minutes) {
  if (minutes <= 0) return '0min';
  if (minutes < 60) return '${minutes}min';
  final hours = minutes ~/ 60;
  final restMinutes = minutes % 60;
  if (hours < 8) {
    return restMinutes == 0 ? '${hours}h' : '${hours}h ${restMinutes}min';
  }
  final days = hours ~/ 8;
  final restHours = hours % 8;
  return restHours == 0 ? '${days}d' : '${days}d ${restHours}h';
}
