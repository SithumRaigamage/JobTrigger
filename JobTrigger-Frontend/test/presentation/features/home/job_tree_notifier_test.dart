import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/home/job_tree_notifier.dart';
import '../../../support/fake_jenkins_repository.dart';

class _FakeJenkinsRepository extends FakeJenkinsRepository {
  Result<List<JenkinsJob>, AppFailure> fetchJobTreeResult = const Ok([]);
  int fetchJobTreeCallCount = 0;

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() async {
    fetchJobTreeCallCount++;
    return fetchJobTreeResult;
  }
}

JenkinsJob _job(String name) =>
    JenkinsJob(name: name, url: 'https://jenkins.test/job/$name/');

void main() {
  test('fetches and exposes the job tree on success', () async {
    final repo = _FakeJenkinsRepository()
      ..fetchJobTreeResult = Ok([_job('a'), _job('b')]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final jobs = await container.read(jobTreeNotifierProvider.future);

    expect(jobs.map((job) => job.name), ['a', 'b']);
  });

  test('an empty repository response surfaces as an empty list', () async {
    final repo = _FakeJenkinsRepository()..fetchJobTreeResult = const Ok([]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final jobs = await container.read(jobTreeNotifierProvider.future);

    expect(jobs, isEmpty);
  });

  test(
    'a repository failure surfaces as an AsyncError with the AppFailure',
    () async {
      final repo = _FakeJenkinsRepository()
        ..fetchJobTreeResult = const Err(NetworkFailure());
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(jobTreeNotifierProvider, (_, _) {});

      await expectLater(
        container.read(jobTreeNotifierProvider.future),
        throwsA(isA<NetworkFailure>()),
      );

      final state = container.read(jobTreeNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkFailure>());
    },
  );

  test('refresh() re-fetches the job tree', () async {
    final repo = _FakeJenkinsRepository()..fetchJobTreeResult = Ok([_job('a')]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(jobTreeNotifierProvider, (_, _) {});
    await container.read(jobTreeNotifierProvider.future);

    repo.fetchJobTreeResult = Ok([_job('a'), _job('b')]);
    await container.read(jobTreeNotifierProvider.notifier).refresh();
    final jobs = await container.read(jobTreeNotifierProvider.future);

    expect(repo.fetchJobTreeCallCount, 2);
    expect(jobs.map((job) => job.name), ['a', 'b']);
  });
}
