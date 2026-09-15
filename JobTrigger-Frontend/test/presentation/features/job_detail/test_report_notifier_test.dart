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
import 'package:job_trigger/presentation/features/job_detail/test_report_notifier.dart';

const _buildUrl = 'https://jenkins.test/job/demo/1/';

class _FakeRepository implements JenkinsRepository {
  _FakeRepository(this.result);

  final Result<TestReport?, AppFailure> result;
  int fetchTestReportCallCount = 0;

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(
    String buildUrl,
  ) async {
    fetchTestReportCallCount++;
    return result;
  }

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) =>
      throw UnimplementedError();

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
  test('a successful fetch with a published report resolves to it', () async {
    final repo = _FakeRepository(
      const Ok(
        TestReport(
          passCount: 10,
          failCount: 1,
          skipCount: 0,
          failingTests: ['com.example.FooTest.testBar'],
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final report = await container.read(
      testReportNotifierProvider(_buildUrl).future,
    );

    expect(report?.passCount, 10);
    expect(report?.failCount, 1);
    expect(report?.failingTests, ['com.example.FooTest.testBar']);
    expect(repo.fetchTestReportCallCount, 1);
  });

  test(
    'a successful fetch with no published report resolves to null (not an error)',
    () async {
      final repo = _FakeRepository(const Ok(null));
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      final report = await container.read(
        testReportNotifierProvider(_buildUrl).future,
      );

      expect(report, isNull);
      expect(
        container.read(testReportNotifierProvider(_buildUrl)).hasError,
        isFalse,
      );
    },
  );

  test('a repository failure maps to AsyncError carrying the AppFailure', () async {
    final repo = _FakeRepository(const Err(NotFoundFailure()));
    final container = ProviderContainer(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    // Keep the (autoDispose) provider alive so its settled error state can
    // be observed below -- `.future` itself isn't used here: awaiting it
    // for a family provider that already has a permanent listener attached
    // never resolves in this Riverpod version, so the settled `AsyncError`
    // is polled for directly instead.
    container.listen(testReportNotifierProvider(_buildUrl), (_, _) {});

    final state = await _settled(
      () => container.read(testReportNotifierProvider(_buildUrl)),
    );

    expect(state.error, isA<NotFoundFailure>());
  });
}

/// Polls [read] until it stops reporting `AsyncLoading`, for asserting on an
/// `AsyncNotifier`'s settled state without relying on `.future` (see the
/// test above for why).
Future<AsyncValue<T>> _settled<T>(AsyncValue<T> Function() read) async {
  var state = read();
  for (var i = 0; i < 100 && state.isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
    state = read();
  }
  return state;
}
