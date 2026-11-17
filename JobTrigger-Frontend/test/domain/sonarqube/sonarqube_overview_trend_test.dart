import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_overview.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_overview_trend.dart';

SonarQubeOverview _overview({int failing = 0, int warning = 0}) =>
    SonarQubeOverview(
      failing: failing,
      warning: warning,
      passing: 3,
      notAnalysed: 0,
      unknown: 0,
      bugs: 0,
      vulnerabilities: 0,
      codeSmells: 0,
      needsAttention: const [],
      neverAnalysed: const [],
    );

SonarQubeOverviewSnapshot _snap(DateTime at, int failing) =>
    SonarQubeOverviewSnapshot(at: at, failing: failing, warning: 0, passing: 3);

void main() {
  final now = DateTime(2026, 11, 17, 12);

  test('the first visit has no trend and is saved (US-SQ-OVERVIEW-02)', () {
    final outcome = compareWithSnapshots(const [], _overview(failing: 2), now);
    expect(outcome.trend, isNull);
    expect(outcome.history, hasLength(1));
    expect(outcome.history.single.failing, 2);
  });

  test('compares with the newest snapshot at least an hour old', () {
    final history = [
      _snap(now.subtract(const Duration(days: 3)), 1),
      _snap(now.subtract(const Duration(days: 1)), 2),
    ];
    final outcome = compareWithSnapshots(history, _overview(failing: 5), now);
    expect(outcome.trend!.failingChange, 3);
    expect(outcome.trend!.since, history.last.at);
    expect(outcome.history, hasLength(3));
  });

  test('fewer failing is a negative change', () {
    final outcome = compareWithSnapshots(
      [_snap(now.subtract(const Duration(days: 1)), 4)],
      _overview(failing: 1),
      now,
    );
    expect(outcome.trend!.failingChange, -3);
  });

  test('a visit minutes after the last is not a new "last time"', () {
    final yesterday = _snap(now.subtract(const Duration(days: 1)), 2);
    final recent = _snap(now.subtract(const Duration(minutes: 5)), 9);
    final outcome = compareWithSnapshots(
      [yesterday, recent],
      _overview(failing: 2),
      now,
    );
    // Still compared with yesterday, and the recent one is not duplicated.
    expect(outcome.trend!.failingChange, 0);
    expect(outcome.trend!.since, yesterday.at);
    expect(outcome.history, hasLength(2));
  });

  test('only a recent snapshot means the trend has not started yet', () {
    final outcome = compareWithSnapshots(
      [_snap(now.subtract(const Duration(minutes: 5)), 1)],
      _overview(failing: 1),
      now,
    );
    expect(outcome.trend, isNull);
    expect(outcome.history, hasLength(1));
  });

  test('keeps at most $sonarQubeSnapshotLimit, dropping the oldest', () {
    final history = [
      for (var i = 0; i < sonarQubeSnapshotLimit; i++)
        _snap(now.subtract(Duration(days: sonarQubeSnapshotLimit + 1 - i)), i),
    ];
    final outcome = compareWithSnapshots(history, _overview(), now);
    expect(outcome.history, hasLength(sonarQubeSnapshotLimit));
    expect(outcome.history.first.failing, 1);
  });

  test('round-trips through json without anything but counts and time', () {
    final json = _snap(now, 2).toJson();
    expect(json.keys, {'at', 'failing', 'warning', 'passing'});
    expect(SonarQubeOverviewSnapshot.fromJson(json).failing, 2);
  });
}
