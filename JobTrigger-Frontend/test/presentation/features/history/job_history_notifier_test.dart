import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/history_filter.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/presentation/features/history/job_history_notifier.dart';
import '../../../support/fake_jenkins_repository.dart';

const _jobUrl = 'https://jenkins.test/job/demo/';

class _FakeJenkinsRepository extends FakeJenkinsRepository {
  Result<List<JenkinsBuild>, AppFailure> fetchJobHistoryResult = const Ok([]);
  int fetchJobHistoryCallCount = 0;
  String? lastJobUrl;

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl, {
    int start = 0,
    int count = historyPageSize,
  }) async {
    fetchJobHistoryCallCount++;
    lastJobUrl = jobUrl;
    return fetchJobHistoryResult;
  }
}

JenkinsBuild _build(int number) => JenkinsBuild(
  number: number,
  url: '$_jobUrl$number/',
  timestamp: number.toDouble(),
);

void main() {
  test(
    'fetches and exposes the build history for the given job on success',
    () async {
      final repo = _FakeJenkinsRepository()
        ..fetchJobHistoryResult = Ok([_build(2), _build(1)]);
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final builds = await container.read(
        jobHistoryNotifierProvider(_jobUrl).future,
      );

      expect(builds.map((b) => b.number), [2, 1]);
      expect(repo.lastJobUrl, _jobUrl);
    },
  );

  test('an empty repository response surfaces as an empty list', () async {
    final repo = _FakeJenkinsRepository()..fetchJobHistoryResult = const Ok([]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final builds = await container.read(
      jobHistoryNotifierProvider(_jobUrl).future,
    );

    expect(builds, isEmpty);
  });

  test(
    'a repository failure surfaces as an AsyncError with the AppFailure',
    () async {
      final repo = _FakeJenkinsRepository()
        ..fetchJobHistoryResult = const Err(NetworkFailure());
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(jobHistoryNotifierProvider(_jobUrl), (_, _) {});

      await expectLater(
        container.read(jobHistoryNotifierProvider(_jobUrl).future),
        throwsA(isA<NetworkFailure>()),
      );

      final state = container.read(jobHistoryNotifierProvider(_jobUrl));
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkFailure>());
    },
  );

  test('refresh() re-fetches the build history', () async {
    final repo = _FakeJenkinsRepository()
      ..fetchJobHistoryResult = Ok([_build(1)]);
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(jobHistoryNotifierProvider(_jobUrl), (_, _) {});
    await container.read(jobHistoryNotifierProvider(_jobUrl).future);

    repo.fetchJobHistoryResult = Ok([_build(2), _build(1)]);
    await container
        .read(jobHistoryNotifierProvider(_jobUrl).notifier)
        .refresh();
    final builds = await container.read(
      jobHistoryNotifierProvider(_jobUrl).future,
    );

    expect(repo.fetchJobHistoryCallCount, 2);
    expect(builds.map((b) => b.number), [2, 1]);
  });
}
