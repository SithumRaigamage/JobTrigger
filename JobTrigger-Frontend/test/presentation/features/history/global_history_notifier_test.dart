import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/presentation/features/history/global_history_notifier.dart';
import 'package:job_trigger/presentation/features/home/job_tree_notifier.dart';
import '../../../support/fake_jenkins_repository.dart';

class _FakeJenkinsRepository extends FakeJenkinsRepository {
  _FakeJenkinsRepository(this.fetchJobTreeResult);

  Result<List<JenkinsJob>, AppFailure> fetchJobTreeResult;
  int fetchJobTreeCallCount = 0;

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() async {
    fetchJobTreeCallCount++;
    return fetchJobTreeResult;
  }
}

JenkinsJob _jobWithBuild(String name, int buildNumber, double timestamp) =>
    JenkinsJob(
      name: name,
      url: 'https://jenkins.test/job/$name/',
      lastBuild: JenkinsBuild(
        number: buildNumber,
        url: 'https://jenkins.test/job/$name/$buildNumber/',
        timestamp: timestamp,
      ),
    );

void main() {
  test(
    'derives the cross-job timeline from the job tree, newest first',
    () async {
      final repo = _FakeJenkinsRepository(
        Ok([_jobWithBuild('a', 1, 1000), _jobWithBuild('b', 2, 2000)]),
      );
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final entries = await container.read(
        globalHistoryNotifierProvider.future,
      );

      expect(entries.map((e) => e.jobName), ['b', 'a']);
    },
  );

  test('a job tree with no builds yields an empty timeline', () async {
    final repo = _FakeJenkinsRepository(
      const Ok([JenkinsJob(name: 'a', url: 'https://jenkins.test/job/a/')]),
    );
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final entries = await container.read(globalHistoryNotifierProvider.future);

    expect(entries, isEmpty);
  });

  test(
    'a job tree fetch failure surfaces as an AsyncError with the AppFailure',
    () async {
      final repo = _FakeJenkinsRepository(const Err(NetworkFailure()));
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(globalHistoryNotifierProvider, (_, _) {});

      await expectLater(
        container.read(globalHistoryNotifierProvider.future),
        throwsA(isA<NetworkFailure>()),
      );

      final state = container.read(globalHistoryNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkFailure>());
    },
  );

  test(
    'refresh() recomputes the timeline from a since-updated job tree',
    () async {
      final repo = _FakeJenkinsRepository(Ok([_jobWithBuild('a', 1, 1000)]));
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(globalHistoryNotifierProvider, (_, _) {});
      final firstEntries = await container.read(
        globalHistoryNotifierProvider.future,
      );
      expect(firstEntries.map((e) => e.jobName), ['a']);

      // The tree itself only changes once invalidated -- GlobalHistoryNotifier
      // doesn't own that fetch, it just re-derives from whatever
      // JobTreeNotifier currently holds (docs/state-management.md).
      repo.fetchJobTreeResult = Ok([
        _jobWithBuild('a', 1, 1000),
        _jobWithBuild('b', 2, 2000),
      ]);
      container.invalidate(jobTreeNotifierProvider);
      await container.read(globalHistoryNotifierProvider.notifier).refresh();
      final secondEntries = await container.read(
        globalHistoryNotifierProvider.future,
      );

      expect(repo.fetchJobTreeCallCount, 2);
      expect(secondEntries.map((e) => e.jobName), ['b', 'a']);
    },
  );
}
