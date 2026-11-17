import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis_status.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_measure_delta.dart';

/// P10-18: `US-SQ-QUALITY-09` (change since the previous analysis) and
/// `US-SQ-CE-01` (a scan running, queued, or the last one failed).
void main() {
  group('measure deltas (US-SQ-QUALITY-09)', () {
    test('more bugs is worse, less coverage is worse', () {
      const bugs = SonarQubeMeasureDelta(
        metricKey: 'bugs',
        previous: 1,
        current: 3,
      );
      expect(bugs.isWorse, isTrue);
      expect(bugs.label, '+2');

      const coverage = SonarQubeMeasureDelta(
        metricKey: 'coverage',
        previous: 70,
        current: 62.3,
      );
      expect(coverage.isWorse, isTrue);
      expect(coverage.label, '−7.7%');

      const improved = SonarQubeMeasureDelta(
        metricKey: 'coverage',
        previous: 60,
        current: 62.5,
      );
      expect(improved.isWorse, isFalse);
      expect(improved.label, '+2.5%');
    });

    test('a rating going from A (1) to B (2) is worse', () {
      const rating = SonarQubeMeasureDelta(
        metricKey: 'sqale_rating',
        previous: 1,
        current: 2,
      );
      expect(rating.isWorse, isTrue);
      expect(rating.label, '+1 grade');
    });

    test('an unchanged measure is not a change', () {
      const same = SonarQubeMeasureDelta(
        metricKey: 'bugs',
        previous: 2,
        current: 2,
      );
      expect(same.isChange, isFalse);
      expect(same.isWorse, isFalse);
    });

    test('needs two readable points, never invents one', () {
      expect(sonarQubeMeasureDelta('bugs', null, '3'), isNull);
      expect(sonarQubeMeasureDelta('bugs', '1', 'three'), isNull);
      expect(sonarQubeMeasureDelta('bugs', '1', '3')?.change, 2);
    });
  });

  group('analysis status (US-SQ-CE-01)', () {
    test('is quiet when the newest task succeeded', () {
      const status = SonarQubeAnalysisStatus(
        current: SonarQubeCeTask(status: 'SUCCESS'),
      );
      expect(status.isQuiet, isTrue);
      expect(status.isBusy, isFalse);
      expect(status.lastFailure, isNull);
    });

    test('reports a running or queued scan', () {
      const running = SonarQubeAnalysisStatus(
        current: SonarQubeCeTask(status: 'IN_PROGRESS'),
      );
      expect(running.isBusy, isTrue);
      expect(sonarQubeCePendingLabel(running.pending!), 'Analysing…');

      const queued = SonarQubeAnalysisStatus(
        queue: [SonarQubeCeTask(status: 'PENDING')],
      );
      expect(sonarQubeCePendingLabel(queued.pending!), 'Queued');
      expect(queued.isQuiet, isFalse);
    });

    test('reports the newest task failure with its reason and time', () {
      final when = DateTime.utc(2026, 11, 12, 14, 2);
      final status = SonarQubeAnalysisStatus(
        current: SonarQubeCeTask(
          status: 'FAILED',
          executedAt: when,
          errorMessage: 'The main branch was not found',
        ),
      );
      expect(status.lastFailure?.errorMessage, 'The main branch was not found');
      expect(status.lastFailure?.when, when);
      expect(status.isBusy, isFalse);
      expect(status.isQuiet, isFalse);
    });
  });
}
