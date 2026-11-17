import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/jenkins/flatten_jobs.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';

JenkinsJob _job(String name, {List<JenkinsJob>? jobs}) =>
    JenkinsJob(name: name, url: 'https://jenkins.test/job/$name/', jobs: jobs);

void main() {
  test('flattens a nested tree, including folders themselves', () {
    final tree = [
      _job(
        'Projects',
        jobs: [
          _job('backend-CI'),
          _job('frontend', jobs: [_job('CI'), _job('CD')]),
        ],
      ),
      _job('standalone-job'),
    ];

    final flattened = flattenJobs(tree);

    // Every node appears, folders included — matches HomeViewModel.flattenJobs
    // (Swift), which appends the folder itself before recursing.
    expect(flattened.map((job) => job.name).toSet(), {
      'Projects',
      'backend-CI',
      'frontend',
      'CI',
      'CD',
      'standalone-job',
    });
    expect(flattened, hasLength(6));
  });

  test('returns an empty list for an empty tree', () {
    expect(flattenJobs(const []), isEmpty);
  });

  test('a leaf job with no children flattens to just itself', () {
    final flattened = flattenJobs([_job('solo')]);
    expect(flattened, hasLength(1));
    expect(flattened.single.name, 'solo');
  });
}
