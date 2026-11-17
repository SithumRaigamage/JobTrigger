import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/widget/widget_snapshot.dart';

JenkinsJob _job(String color, {int? build}) => JenkinsJob(
  name: 'api',
  url: 'https://ci/job/api/',
  color: color,
  lastBuild: build == null
      ? null
      : JenkinsBuild(
          number: build,
          url: 'https://ci/job/api/$build/',
          building: false,
          timestamp: 1000,
          duration: 0,
        ),
);

PinnedStatus _pin(JenkinsJob? job, {String label = 'api'}) =>
    (label: label, url: 'https://ci/job/$label/', job: job);

void main() {
  sonarQubeWidgetTests();
  final now = DateTime(2026, 9, 30, 12);

  test('maps ball colors to a status and spelled-out text (US-JX-23)', () {
    final jobs = buildWidgetSnapshot([
      _pin(_job('blue', build: 42)),
      _pin(_job('red')),
      _pin(_job('yellow')),
      _pin(_job('red_anime')),
    ], now: now).jobs;

    expect(
      [for (final j in jobs) j.status],
      [
        WidgetJobStatus.success,
        WidgetJobStatus.failure,
        WidgetJobStatus.unstable,
        WidgetJobStatus.running,
      ],
    );
    expect(
      [for (final j in jobs) j.statusText],
      ['Success', 'Failed', 'Unstable', 'Running'],
    );
    expect(jobs.first.buildNumber, 42);
    expect(jobs.first.buildTimestamp, 1000);
  });

  test('an unknown status still gets a row', () {
    final job = buildWidgetSnapshot([_pin(null)], now: now).jobs.single;
    expect(job.status, WidgetJobStatus.other);
    expect(job.statusText, 'Unknown');
    expect(job.buildNumber, isNull);
  });

  test('rows deep-link into the job (US-JX-19)', () {
    final job = buildWidgetSnapshot([_pin(null)], now: now).jobs.single;
    final link = Uri.parse(job.link);
    expect(link.scheme, 'jobtrigger');
    expect(link.queryParameters['url'], 'https://ci/job/api/');
  });

  test('keeps at most four jobs, in pin order', () {
    final snapshot = buildWidgetSnapshot([
      for (final label in ['a', 'b', 'c', 'd', 'e']) _pin(null, label: label),
    ], now: now);
    expect([for (final j in snapshot.jobs) j.label], ['a', 'b', 'c', 'd']);
  });

  test('the JSON the native widgets read holds no credentials', () {
    final json = buildWidgetSnapshot([
      _pin(_job('blue', build: 1)),
    ], now: now).toJson();
    expect(json['updatedAt'], now.millisecondsSinceEpoch);
    final row = (json['jobs']! as List).single as Map<String, Object?>;
    expect(row.keys, {
      'label',
      'link',
      'status',
      'statusText',
      'buildNumber',
      'buildTimestamp',
    });
  });

  test('while the app lock is on, only the count leaves the app (AUD-54)', () {
    final snapshot = buildWidgetSnapshot(
      [_pin(_job('red')), _pin(_job('blue'), label: 'web')],
      now: now,
      hideNames: true,
    );
    expect(snapshot.jobs, isEmpty);
    expect(snapshot.lockedCount, 2);
    expect(snapshot.toJson()['lockedCount'], 2);
  });

  test('unlocked, there is no locked count', () {
    final snapshot = buildWidgetSnapshot([_pin(_job('red'))], now: now);
    expect(snapshot.isLocked, isFalse);
    expect(snapshot.toJson()['lockedCount'], isNull);
  });
}

void sonarQubeWidgetTests() {
  group('pinned SonarQube projects (US-SQ-WIDGET-01)', () {
    final now = DateTime(2026, 11, 17, 12);

    test('spells the verdict out and links the project by key only', () {
      final snapshot = buildSonarQubeWidgetSnapshot([
        (key: 'acme:api', name: 'API', gate: 'failed'),
        (key: 'web', name: 'Web', gate: 'passed'),
        (key: 'old', name: 'Old', gate: 'none'),
        (key: 'warn', name: 'Warn', gate: 'warning'),
        (key: 'late', name: 'Late', gate: null),
      ], now: now);

      expect(snapshot.jobs.map((j) => j.statusText), [
        'Failed',
        'Passed',
        'Not analyzed',
        'Warning',
      ]);
      expect(snapshot.jobs.map((j) => j.status), [
        WidgetJobStatus.failure,
        WidgetJobStatus.success,
        WidgetJobStatus.other,
        WidgetJobStatus.unstable,
      ]);
      expect(
        snapshot.jobs.first.link,
        'jobtrigger://app/sonarqube/project?key=acme%3Aapi',
      );
      // At most four rows, like the jobs widget.
      expect(snapshot.jobs, hasLength(WidgetSnapshot.maxJobs));
    });

    test('an unloaded verdict is Unknown, never a pass', () {
      final snapshot = buildSonarQubeWidgetSnapshot([
        (key: 'a', name: 'A', gate: null),
      ], now: now);
      expect(snapshot.jobs.single.statusText, 'Unknown');
    });

    test('the app lock leaves only a count: no names, no verdicts', () {
      final snapshot = buildSonarQubeWidgetSnapshot(
        [
          (key: 'a', name: 'Secret project', gate: 'failed'),
          (key: 'b', name: 'Other', gate: 'passed'),
        ],
        now: now,
        hideNames: true,
      );
      expect(snapshot.jobs, isEmpty);
      expect(snapshot.lockedCount, 2);
      expect(snapshot.toJson().toString(), isNot(contains('Secret')));
    });

    test('holds no credential, token or server address', () {
      final json = buildSonarQubeWidgetSnapshot([
        (key: 'a', name: 'A', gate: 'passed'),
      ], now: now).toJson().toString();
      expect(json, isNot(contains('http')));
      expect(json, isNot(contains('token')));
    });
  });
}
