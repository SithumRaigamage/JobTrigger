import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_watch.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';

/// P10-19 (`US-SQ-WATCH-01`): notify once per new analysis whose gate fails,
/// and never twice for the same one.
const _watch = SonarQubeProjectWatch(
  credentialId: 'c1',
  projectKey: 'acme:api',
  projectName: 'API Gateway',
);

SonarQubeQualityGate _gate(QualityGateState state) => SonarQubeQualityGate(
  state: state,
  conditions: state == QualityGateState.failed
      ? const [
          QualityGateCondition(
            metricKey: 'new_coverage',
            comparator: 'LT',
            threshold: '80',
            actual: '62.1',
            failed: true,
          ),
        ]
      : const [],
);

void main() {
  test('a failing gate on an unseen analysis notifies, once', () {
    final first = decideGateWatch(
      _watch,
      gate: _gate(QualityGateState.failed),
      analysisDate: '2026-11-17T09:00:00.000Z',
    );

    expect(first.notify, isNotNull);
    expect(first.notify!.title, 'API Gateway failed its quality gate');
    expect(first.notify!.body, 'Coverage on new code is 62.1%, below 80%');
    expect(first.keep?.lastAnalysis, '2026-11-17T09:00:00.000Z');

    // The same analysis again is not news.
    final second = decideGateWatch(
      first.keep!,
      gate: _gate(QualityGateState.failed),
      analysisDate: '2026-11-17T09:00:00.000Z',
    );
    expect(second.notify, isNull);
    expect(second.keep, same(first.keep));
  });

  test('a passing analysis updates silently, then a failure notifies', () {
    final passed = decideGateWatch(
      _watch,
      gate: _gate(QualityGateState.passed),
      analysisDate: '2026-11-17T09:00:00.000Z',
    );
    expect(passed.notify, isNull);
    expect(passed.keep?.lastGate, QualityGateState.passed);

    final failed = decideGateWatch(
      passed.keep!,
      gate: _gate(QualityGateState.failed),
      analysisDate: '2026-11-17T10:00:00.000Z',
    );
    expect(failed.notify, isNotNull);
  });

  test('with no analysis time, only a change of verdict is news', () {
    const alreadyFailing = SonarQubeProjectWatch(
      credentialId: 'c1',
      projectKey: 'acme:api',
      projectName: 'API Gateway',
      lastGate: QualityGateState.failed,
    );

    // Still failing, no date: the pass updates nothing and stays quiet.
    final quiet = decideGateWatch(
      alreadyFailing,
      gate: _gate(QualityGateState.failed),
      analysisDate: null,
    );
    expect(quiet.notify, isNull);

    // A fresh watch that finds a failing gate does notify once.
    final fresh = decideGateWatch(
      _watch,
      gate: _gate(QualityGateState.failed),
      analysisDate: null,
    );
    expect(fresh.notify, isNotNull);
  });

  test('the notification id is stable per analysis', () {
    final a = decideGateWatch(
      _watch,
      gate: _gate(QualityGateState.failed),
      analysisDate: '2026-11-17T09:00:00.000Z',
    );
    final b = decideGateWatch(
      _watch,
      gate: _gate(QualityGateState.failed),
      analysisDate: '2026-11-17T09:00:00.000Z',
    );
    expect(a.notify!.id, b.notify!.id);

    final later = decideGateWatch(
      _watch,
      gate: _gate(QualityGateState.failed),
      analysisDate: '2026-11-17T10:00:00.000Z',
    );
    expect(later.notify!.id, isNot(a.notify!.id));
  });

  test('the locked copy names neither the project nor the metric (AUD-54)', () {
    final notification = decideGateWatch(
      _watch,
      gate: _gate(QualityGateState.failed),
      analysisDate: null,
    ).notify!;

    expect(
      notification.redacted().title,
      'A watched project failed its quality gate',
    );
    expect(notification.redacted().body, 'Unlock JobTrigger to see which.');
  });
}
