import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/jenkins_repository.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/queue_item.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_notifier.dart';

const _jobUrl = 'https://jenkins.test/job/demo/';

/// Returns a scripted [Result] per call to `fetchJobDetail`, cycling to the
/// last entry once exhausted -- mirrors
/// `queue_status_notifier_test.dart`'s `_ScriptedRepository` style, applied
/// here to the notifier's own fetch instead of a downstream one.
class _ScriptedRepository implements JenkinsRepository {
  _ScriptedRepository(this.responses);

  final List<Result<JenkinsJob, AppFailure>> responses;
  int fetchJobDetailCallCount = 0;

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async {
    final index = fetchJobDetailCallCount < responses.length
        ? fetchJobDetailCallCount
        : responses.length - 1;
    fetchJobDetailCallCount++;
    return responses[index];
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
  Future<Result<QueueItem, AppFailure>> fetchQueueItem(String queueItemUrl) =>
      throw UnimplementedError();

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(String buildUrl) =>
      throw UnimplementedError();

  @override
  Future<Result<Uint8List, AppFailure>> fetchArtifactBytes(
    String buildUrl,
    String relativePath,
  ) => throw UnimplementedError();

  @override
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
    String buildUrl,
  ) => throw UnimplementedError();

  @override
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(
    String buildUrl,
  ) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> submitInput({
    required String buildUrl,
    required String inputId,
    required bool proceed,
    Map<String, String> parameters = const {},
  }) => throw UnimplementedError();
}

void main() {
  test('a successful initial fetch resolves to the fetched job', () async {
    final repo = _ScriptedRepository([
      const Ok(JenkinsJob(name: 'demo', url: _jobUrl)),
    ]);
    final container = ProviderContainer(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final job = await container.read(jobDetailNotifierProvider(_jobUrl).future);

    expect(job.name, 'demo');
    expect(repo.fetchJobDetailCallCount, 1);
  });

  test('a repository failure maps to AsyncError carrying the AppFailure', () async {
    final repo = _ScriptedRepository([const Err(NotFoundFailure())]);
    final container = ProviderContainer(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    // Keep the (autoDispose) provider alive so its settled error state can
    // be observed below -- `.future` itself isn't used here: awaiting it
    // for a family provider that already has a permanent listener attached
    // never resolves in this Riverpod version, so the settled `AsyncError`
    // is polled for directly instead.
    container.listen(jobDetailNotifierProvider(_jobUrl), (_, _) {});

    final state = await _settled(
      () => container.read(jobDetailNotifierProvider(_jobUrl)),
    );

    expect(state.error, isA<NotFoundFailure>());
  });

  test('refresh() re-fetches and picks up the new value', () async {
    final repo = _ScriptedRepository([
      const Ok(JenkinsJob(name: 'demo', url: _jobUrl, description: 'first')),
      const Ok(JenkinsJob(name: 'demo', url: _jobUrl, description: 'second')),
    ]);
    final container = ProviderContainer(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(jobDetailNotifierProvider(_jobUrl), (_, _) {});

    final first = await container.read(
      jobDetailNotifierProvider(_jobUrl).future,
    );
    expect(first.description, 'first');
    expect(repo.fetchJobDetailCallCount, 1);

    await container.read(jobDetailNotifierProvider(_jobUrl).notifier).refresh();

    final second = await container.read(
      jobDetailNotifierProvider(_jobUrl).future,
    );
    expect(second.description, 'second');
    expect(repo.fetchJobDetailCallCount, 2);
  });

  test(
    'applyOptimisticCancel flips the last build to ABORTED/not-building without touching other fields',
    () async {
      final repo = _ScriptedRepository([
        const Ok(
          JenkinsJob(
            name: 'demo',
            url: _jobUrl,
            description: 'desc',
            lastBuild: JenkinsBuild(
              number: 5,
              url: '${_jobUrl}5/',
              timestamp: 0,
              building: true,
            ),
          ),
        ),
      ]);
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(jobDetailNotifierProvider(_jobUrl).future);

      container
          .read(jobDetailNotifierProvider(_jobUrl).notifier)
          .applyOptimisticCancel();

      final job = container.read(jobDetailNotifierProvider(_jobUrl)).value!;
      expect(job.description, 'desc');
      expect(job.lastBuild?.number, 5);
      expect(job.lastBuild?.result, 'ABORTED');
      expect(job.lastBuild?.building, isFalse);
    },
  );

  test(
    'applyOptimisticCancel is a no-op when there is no last build',
    () async {
      final repo = _ScriptedRepository([
        const Ok(JenkinsJob(name: 'demo', url: _jobUrl)),
      ]);
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(jobDetailNotifierProvider(_jobUrl).future);

      container
          .read(jobDetailNotifierProvider(_jobUrl).notifier)
          .applyOptimisticCancel();

      final job = container.read(jobDetailNotifierProvider(_jobUrl)).value!;
      expect(job.lastBuild, isNull);
    },
  );
}

/// Polls [read] until it stops reporting `AsyncLoading`, for asserting on an
/// `AsyncNotifier`'s settled state without relying on `.future` (see the
/// error-case test above for why).
Future<AsyncValue<T>> _settled<T>(AsyncValue<T> Function() read) async {
  var state = read();
  for (var i = 0; i < 100 && state.isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
    state = read();
  }
  return state;
}
