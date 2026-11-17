import 'sonarqube_issue.dart';

/// A security hotspot (`US-SQ-HOTSPOT-01`) — `GET api/hotspots/search`'s
/// `hotspots[]`. A hotspot is code a person must judge, not a confirmed
/// defect, so it carries a review status rather than a severity.
class SonarQubeHotspot {
  const SonarQubeHotspot({
    required this.key,
    required this.message,
    required this.status,
    this.securityCategory,
    this.vulnerabilityProbability,
    this.file,
    this.line,
    this.component,
  });

  final String key;
  final String message;

  /// `TO_REVIEW` or `REVIEWED`.
  final String status;

  /// SonarQube's category, e.g. `weak-cryptography` (older servers) or a
  /// readable `others`; shown as the server sends it.
  final String? securityCategory;

  /// `HIGH`, `MEDIUM`, `LOW` — the server's own likelihood that this is
  /// exploitable. Never a colour on its own: the label is spelled out.
  final String? vulnerabilityProbability;

  final String? file;
  final int? line;

  /// Full component key, needed for the code snippet.
  final String? component;

  bool get isReviewed => status == 'REVIEWED';

  String? get location =>
      file == null ? null : (line == null ? file : '$file:$line');

  String get probabilityLabel => switch (vulnerabilityProbability) {
    'HIGH' => 'High probability',
    'MEDIUM' => 'Medium probability',
    'LOW' => 'Low probability',
    final other when other != null && other.isNotEmpty => other,
    _ => 'Probability not stated',
  };
}

/// One page of hotspots and the total under the filter.
class SonarQubeHotspotPage {
  const SonarQubeHotspotPage({required this.hotspots, required this.total});

  final List<SonarQubeHotspot> hotspots;
  final int total;
}

/// What a hotspot's expanded row shows (`api/hotspots/show`): the rule's
/// name and the code around it, as `US-SQ-QUALITY-06` does for issues.
class SonarQubeHotspotDetail {
  const SonarQubeHotspotDetail({this.ruleName, this.snippet = const []});

  final String? ruleName;
  final List<SonarQubeSourceLine> snippet;
}

/// Hotspots per page; SonarQube's own default.
const sonarQubeHotspotsPageSize = 50;
