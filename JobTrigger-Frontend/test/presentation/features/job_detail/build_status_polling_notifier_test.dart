import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/jenkins_repository.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/presentation/features/job_detail/build_status_polling_notifier.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_notifier.dart';

const _jobUrl = 'https://jenkins.test/job/demo/';

/// Counts `fetchJobDetail` calls so tests can observe whether the polling
/// loop actually fired (or, for the dispose test, correctly did not).
class _CountingRepository implements JenkinsRepository {
  int fetchJobDetailCallCount = 0;
  bool building = true;

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async {
    fetchJobDetailCallCount++;
    return Ok(
      JenkinsJob(
        name: 'demo',
        url: jobUrl,
        lastBuild: JenkinsBuild(
          number: 1,
          url: '${jobUrl}1/',
          timestamp: 0,
          building: building,
        ),
      ),
    );
  }

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() =>
      throw UnimplementedError();

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl,
  ) => throw UnimplementedError();

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) => throw UnimplementedError();

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

void main() {
  // Real timers, not fake_async — keeps the test dependency-free at the
  // cost of a few real seconds of wall-clock time.

  test(
    'polls again after ~5s while the build is still building',
    () async {
      final repo = _CountingRepository()..building = true;
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      expect(repo.fetchJobDetailCallCount, 1);

      container.listen(buildStatusPollingNotifierProvider(_jobUrl), (_, _) {});

      await Future<void>.delayed(const Duration(seconds: 6));

      expect(repo.fetchJobDetailCallCount, greaterThanOrEqualTo(2));
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );

  test(
    'cancels its timer on dispose -- no further fetches after the container is gone',
    () async {
      final repo = _CountingRepository()..building = true;
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );

      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      container.listen(buildStatusPollingNotifierProvider(_jobUrl), (_, _) {});
      expect(repo.fetchJobDetailCallCount, 1);

      container.dispose();

      // Wait past the 5s poll interval -- if the timer wasn't cancelled, this
      // would fire another fetch (and likely also throw, since it'd be
      // reading through a disposed container).
      await Future<void>.delayed(const Duration(seconds: 6));

      expect(repo.fetchJobDetailCallCount, 1);
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );

  test(
    'does not schedule a timer at all once the build has finished',
    () async {
      final repo = _CountingRepository()..building = false;
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      container.listen(buildStatusPollingNotifierProvider(_jobUrl), (_, _) {});
      expect(repo.fetchJobDetailCallCount, 1);

      await Future<void>.delayed(const Duration(seconds: 6));

      expect(repo.fetchJobDetailCallCount, 1);
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );
}
