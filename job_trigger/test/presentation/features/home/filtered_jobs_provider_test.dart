import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/jenkins_repository.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/presentation/features/home/filtered_jobs_provider.dart';
import 'package:job_trigger/presentation/features/home/folder_breadcrumb_notifier.dart';
import 'package:job_trigger/presentation/features/home/job_search_notifier.dart';
import 'package:job_trigger/presentation/features/home/job_tree_notifier.dart';

class _FakeJenkinsRepository implements JenkinsRepository {
  _FakeJenkinsRepository(this._jobs);

  final List<JenkinsJob> _jobs;

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() async =>
      Ok(_jobs);

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) =>
      throw UnimplementedError();

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) => throw UnimplementedError();

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl,
  ) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    String? paramToken,
  }) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl) =>
      throw UnimplementedError();
}

JenkinsJob _job(String name, {List<JenkinsJob>? jobs}) =>
    JenkinsJob(name: name, url: 'https://jenkins.test/job/$name/', jobs: jobs);

void main() {
  late List<JenkinsJob> tree;
  late ProviderContainer container;

  setUp(() {
    final frontendCi = _job('CI');
    tree = [
      _job(
        'Projects',
        jobs: [
          _job('backend-CI'),
          _job('frontend', jobs: [frontendCi]),
        ],
      ),
      _job('standalone-job'),
    ];
    container = ProviderContainer(
      overrides: [
        jenkinsRepositoryProvider.overrideWithValue(
          _FakeJenkinsRepository(tree),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test('empty query with no breadcrumb shows the root job list', () async {
    await container.read(jobTreeNotifierProvider.future);

    expect(
      container.read(filteredJobsProvider).map((job) => job.name).toList(),
      ['Projects', 'standalone-job'],
    );
  });

  test('empty query with a breadcrumb shows that folder\'s children', () async {
    await container.read(jobTreeNotifierProvider.future);
    final projects = tree.firstWhere((job) => job.name == 'Projects');
    container
        .read(folderBreadcrumbNotifierProvider.notifier)
        .navigateInto(projects);

    expect(
      container.read(filteredJobsProvider).map((job) => job.name).toList(),
      ['backend-CI', 'frontend'],
    );
  });

  test(
    'a non-empty query searches the entire tree, ignoring the current breadcrumb',
    () async {
      await container.read(jobTreeNotifierProvider.future);
      // Drill into "Projects" first, to prove search isn't scoped to it.
      final projects = tree.firstWhere((job) => job.name == 'Projects');
      container
          .read(folderBreadcrumbNotifierProvider.notifier)
          .navigateInto(projects);

      container.read(jobSearchNotifierProvider.notifier).setQuery('ci');

      // Matches backend-CI, frontend's nested "CI", but not "Projects" or
      // "standalone-job" or "frontend" itself.
      expect(
        container.read(filteredJobsProvider).map((job) => job.name).toSet(),
        {'backend-CI', 'CI'},
      );
    },
  );

  test('search is case-insensitive', () async {
    await container.read(jobTreeNotifierProvider.future);
    container.read(jobSearchNotifierProvider.notifier).setQuery('STANDALONE');

    expect(
      container.read(filteredJobsProvider).map((job) => job.name).toList(),
      ['standalone-job'],
    );
  });
}
