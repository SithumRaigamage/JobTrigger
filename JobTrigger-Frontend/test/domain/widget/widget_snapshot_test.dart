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
      ['Success', 'Failed', 'Unstable', 'Building'],
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
}
