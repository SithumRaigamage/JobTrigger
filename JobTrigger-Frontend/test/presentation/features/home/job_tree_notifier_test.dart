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
import 'package:job_trigger/presentation/features/home/job_tree_notifier.dart';

class _FakeJenkinsRepository implements JenkinsRepository {
  Result<List<JenkinsJob>, AppFailure> fetchJobTreeResult = const Ok([]);
  int fetchJobTreeCallCount = 0;

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() async {
    fetchJobTreeCallCount++;
    return fetchJobTreeResult;
  }

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

  test('a repository failure surfaces as an AsyncError with the AppFailure', () async {
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
  });

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
