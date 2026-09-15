import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/history_entry.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';

JenkinsBuild _build({required int number, required double timestamp}) =>
    JenkinsBuild(
      number: number,
      url: 'https://jenkins.test/$number/',
      timestamp: timestamp,
    );

JenkinsJob _job(
  String name, {
  JenkinsBuild? lastBuild,
  List<JenkinsJob>? jobs,
}) => JenkinsJob(
  name: name,
  url: 'https://jenkins.test/job/$name/',
  lastBuild: lastBuild,
  jobs: jobs,
);

void main() {
  test(
    'collects the lastBuild of every job in the tree, sorted newest first',
    () {
      final tree = [
        _job(
          'Projects',
          jobs: [
            _job('backend', lastBuild: _build(number: 5, timestamp: 3000)),
            _job('frontend', lastBuild: _build(number: 9, timestamp: 5000)),
          ],
        ),
        _job('standalone', lastBuild: _build(number: 1, timestamp: 1000)),
        _job('never-built'), // no lastBuild -> excluded
      ];

      final timeline = buildHistoryTimeline(tree);

      expect(timeline.map((entry) => entry.jobName).toList(), [
        'frontend',
        'backend',
        'standalone',
      ]);
      expect(timeline.first.build.number, 9);
    },
  );

  test('caps at the given limit', () {
    final tree = List.generate(
      10,
      (i) => _job(
        'job-$i',
        lastBuild: _build(number: i, timestamp: i.toDouble()),
      ),
    );

    final timeline = buildHistoryTimeline(tree, limit: 3);

    expect(timeline, hasLength(3));
    // Newest three: job-9, job-8, job-7.
    expect(timeline.map((entry) => entry.jobName).toList(), [
      'job-9',
      'job-8',
      'job-7',
    ]);
  });

  test('id combines job name and build number', () {
    final entry = HistoryEntry(
      jobName: 'backend',
      build: _build(number: 5, timestamp: 1000),
    );
    expect(entry.id, 'backend-5');
  });
}
