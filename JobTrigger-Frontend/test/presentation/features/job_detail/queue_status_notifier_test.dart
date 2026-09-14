import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/jenkins_repository.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/domain/jenkins/queue_item.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_notifier.dart';
import 'package:job_trigger/presentation/features/job_detail/queue_status_notifier.dart';

const _jobUrl = 'https://jenkins.test/job/demo/';

/// Returns a scripted [Result] per call to `fetchQueueItem`, cycling to the
/// last entry once the list is exhausted — mirrors
/// `build_status_polling_notifier_test.dart`'s counting-fake style.
class _ScriptedRepository implements JenkinsRepository {
  _ScriptedRepository(this.queueResponses);

  final List<Result<QueueItem, AppFailure>> queueResponses;
  int queueCallCount = 0;
  int fetchJobDetailCallCount = 0;

  @override
  Future<Result<QueueItem, AppFailure>> fetchQueueItem(
    String queueItemUrl,
  ) async {
    final index = queueCallCount < queueResponses.length
        ? queueCallCount
        : queueResponses.length - 1;
    queueCallCount++;
    return queueResponses[index];
  }

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async {
    fetchJobDetailCallCount++;
    return Ok(JenkinsJob(name: 'demo', url: jobUrl));
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
  Future<Result<String?, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    String? paramToken,
  }) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl) =>
      throw UnimplementedError();

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(String buildUrl) =>
      throw UnimplementedError();
}

void main() {
  // Real timers, not fake_async — same trade-off as
  // build_status_polling_notifier_test.dart.

  test(
    'polls until an executable appears, then stops and refreshes job detail',
    () async {
      final repo = _ScriptedRepository([
        const Ok(QueueItem(why: 'Waiting for next available executor')),
        const Ok(
          QueueItem(
            executable: QueueExecutable(
              number: 57,
              url: 'https://jenkins.test/job/demo/57/',
            ),
          ),
        ),
      ]);
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      // Keep JobDetailNotifier alive (a plain one-shot `.future` read
      // doesn't — it's autoDispose and gets torn down once that read
      // completes, same reasoning as build_status_polling_notifier_test
      // .dart's `container.listen(buildStatusPollingNotifierProvider...)`,
      // which keeps it alive indirectly via that notifier's own internal
      // `ref.listen`) so a later invalidate() causes a real refetch
      // instead of silently doing nothing to an already-disposed provider.
      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      container.listen(jobDetailNotifierProvider(_jobUrl), (_, _) {});
      expect(repo.fetchJobDetailCallCount, 1);

      // QueueStatusNotifier is itself autoDispose — without a listener it
      // (and its internal Timer, cancelled by ref.onDispose) would be torn
      // down right after `track()`'s first poll returns, before the 2s
      // timer for the second poll ever fires.
      container.listen(queueStatusNotifierProvider(_jobUrl), (_, _) {});

      await container
          .read(queueStatusNotifierProvider(_jobUrl).notifier)
          .track('https://jenkins.test/queue/item/1/');

      expect(
        container.read(queueStatusNotifierProvider(_jobUrl))?.why,
        'Waiting for next available executor',
      );
      expect(repo.fetchJobDetailCallCount, 1);

      // The second poll fires after the 2s timer and resolves to
      // executable.
      await Future<void>.delayed(const Duration(seconds: 3));

      expect(container.read(queueStatusNotifierProvider(_jobUrl)), isNull);
      expect(repo.fetchJobDetailCallCount, 2);
    },
  );

  test('clears state without refreshing job detail if cancelled', () async {
    final repo = _ScriptedRepository([const Ok(QueueItem(cancelled: true))]);
    final container = ProviderContainer(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(jobDetailNotifierProvider(_jobUrl).future);
    container.listen(jobDetailNotifierProvider(_jobUrl), (_, _) {});
    expect(repo.fetchJobDetailCallCount, 1);

    await container
        .read(queueStatusNotifierProvider(_jobUrl).notifier)
        .track('https://jenkins.test/queue/item/1/');

    expect(container.read(queueStatusNotifierProvider(_jobUrl)), isNull);
    // Cancelled, never started building -- nothing new for JobDetail to
    // pick up, even though it's kept alive and could have refetched.
    expect(repo.fetchJobDetailCallCount, 1);
  });

  test('clears state quietly on a queue-item fetch failure', () async {
    final repo = _ScriptedRepository([const Err(NetworkFailure())]);
    final container = ProviderContainer(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container
        .read(queueStatusNotifierProvider(_jobUrl).notifier)
        .track('https://jenkins.test/queue/item/1/');

    expect(container.read(queueStatusNotifierProvider(_jobUrl)), isNull);
  });
}
