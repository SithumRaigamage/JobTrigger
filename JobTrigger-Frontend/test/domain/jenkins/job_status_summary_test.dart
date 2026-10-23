import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/job_status_summary.dart';

JenkinsJob _job(String name, String? color, {bool building = false}) =>
    JenkinsJob(
      name: name,
      url: 'https://ci.example.com/job/$name/',
      color: color,
      lastBuild: building
          ? JenkinsBuild(
              number: 1,
              url: 'https://ci.example.com/job/$name/1/',
              timestamp: 0,
              building: true,
            )
          : null,
    );

void main() {
  test('counts each job once by its ball colour', () {
    final summary = JobStatusSummary.of([
      _job('a', 'blue'),
      _job('b', 'blue'),
      _job('c', 'red'),
      _job('d', 'red_anime'),
      _job('e', 'blue_anime'),
      _job('f', 'notbuilt'),
      _job('g', 'yellow'),
    ]);

    expect(summary.running, 2);
    expect(summary.failing, 1);
    expect(summary.passing, 2);
  });

  test('a job whose last build is still building is running', () {
    final summary = JobStatusSummary.of([_job('a', 'blue', building: true)]);
    expect(summary.running, 1);
    expect(summary.passing, 0);
  });

  test('folders are not counted', () {
    const folder = JenkinsJob(
      name: 'infra',
      url: 'https://ci.example.com/job/infra/',
      color: 'blue',
      jobs: [],
    );
    expect(JobStatusSummary.of([folder]).isEmpty, isTrue);
  });
}
