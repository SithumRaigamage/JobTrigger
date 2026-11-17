import 'sonarqube_overview.dart';

/// Counts only — no keys, names or secrets — of what the Overview showed at
/// one moment (`US-SQ-OVERVIEW-02`).
class SonarQubeOverviewSnapshot {
  const SonarQubeOverviewSnapshot({
    required this.at,
    required this.failing,
    required this.warning,
    required this.passing,
  });

  factory SonarQubeOverviewSnapshot.of(
    SonarQubeOverview overview,
    DateTime at,
  ) => SonarQubeOverviewSnapshot(
    at: at,
    failing: overview.failing,
    warning: overview.warning,
    passing: overview.passing,
  );

  factory SonarQubeOverviewSnapshot.fromJson(Map<String, dynamic> json) =>
      SonarQubeOverviewSnapshot(
        at: DateTime.parse(json['at'] as String),
        failing: json['failing'] as int,
        warning: json['warning'] as int,
        passing: json['passing'] as int,
      );

  Map<String, dynamic> toJson() => {
    'at': at.toUtc().toIso8601String(),
    'failing': failing,
    'warning': warning,
    'passing': passing,
  };

  final DateTime at;
  final int failing;
  final int warning;
  final int passing;
}

/// Snapshots closer together than this are the same visit to the Overview,
/// not a "last time": opening the tab twice in a row must not erase the
/// comparison with yesterday.
const sonarQubeSnapshotMinGap = Duration(hours: 1);

/// The device keeps this many snapshots per credential, oldest dropped.
const sonarQubeSnapshotLimit = 30;

/// How the failing-project count moved since the last snapshot taken at
/// least [sonarQubeSnapshotMinGap] ago. Honest label: "since you last
/// looked", not "over time" — SonarQube has no portfolio-level history, so
/// this is only what this device saw.
class SonarQubeOverviewTrend {
  const SonarQubeOverviewTrend({
    required this.since,
    required this.failingChange,
    required this.warningChange,
  });

  /// When the compared snapshot was taken.
  final DateTime since;

  /// Positive means more projects failing than then.
  final int failingChange;
  final int warningChange;
}

/// What to show and what to keep after the Overview has fully loaded.
class SonarQubeSnapshotOutcome {
  const SonarQubeSnapshotOutcome({required this.trend, required this.history});

  /// Null on the first visit: the screen says the trend starts now.
  final SonarQubeOverviewTrend? trend;

  /// The history to persist, with this visit added when it is due.
  final List<SonarQubeOverviewSnapshot> history;
}

/// Compares [overview] with the newest snapshot in [history] that is at least
/// [sonarQubeSnapshotMinGap] old, and appends this visit when the newest
/// snapshot is that old (or there is none). Pure, so it is tested without a
/// device.
SonarQubeSnapshotOutcome compareWithSnapshots(
  List<SonarQubeOverviewSnapshot> history,
  SonarQubeOverview overview,
  DateTime now,
) {
  final cutoff = now.subtract(sonarQubeSnapshotMinGap);
  SonarQubeOverviewSnapshot? baseline;
  for (final snapshot in history) {
    if (!snapshot.at.isAfter(cutoff) &&
        (baseline == null || snapshot.at.isAfter(baseline.at))) {
      baseline = snapshot;
    }
  }
  final trend = baseline == null
      ? null
      : SonarQubeOverviewTrend(
          since: baseline.at,
          failingChange: overview.failing - baseline.failing,
          warningChange: overview.warning - baseline.warning,
        );
  final newest = history.isEmpty
      ? null
      : history.reduce((a, b) => a.at.isAfter(b.at) ? a : b);
  final due = newest == null || !newest.at.isAfter(cutoff);
  final kept = due
      ? [...history, SonarQubeOverviewSnapshot.of(overview, now)]
      : history;
  final trimmed = kept.length > sonarQubeSnapshotLimit
      ? kept.sublist(kept.length - sonarQubeSnapshotLimit)
      : kept;
  return SonarQubeSnapshotOutcome(trend: trend, history: trimmed);
}
