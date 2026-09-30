import 'dart:typed_data';

import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/domain/jenkins/branch_kind.dart';
import 'package:job_trigger/domain/jenkins/history_filter.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/jenkins_repository.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/domain/jenkins/parameter_file.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/queue_entry.dart';
import 'package:job_trigger/domain/jenkins/queue_item.dart';
import 'package:job_trigger/domain/jenkins/server_status.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';

/// Base for test fakes of [JenkinsRepository]: every method throws
/// [UnimplementedError] until a subclass overrides the ones its test uses.
/// Extend this (don't `implements` the interface) so adding a repository
/// method only touches this file, not every fake.
class FakeJenkinsRepository implements JenkinsRepository {
  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchJobTree() =>
      throw UnimplementedError('fetchJobTree');

  @override
  Future<Result<ServerStatus, AppFailure>> fetchServerStatus() =>
      throw UnimplementedError('fetchServerStatus');

  @override
  Future<Result<List<JenkinsJob>, AppFailure>> fetchFolder(String? folderUrl) =>
      throw UnimplementedError('fetchFolder');

  @override
  Future<Result<Map<String, BranchKind>, AppFailure>> fetchBranchKinds(
    String multibranchUrl,
  ) => throw UnimplementedError('fetchBranchKinds');

  @override
  Future<Result<void, AppFailure>> scanMultibranch(String projectUrl) =>
      throw UnimplementedError('scanMultibranch');

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) =>
      throw UnimplementedError('fetchJobDetail');

  @override
  Future<Result<LogChunk, AppFailure>> streamBuildLog(
    String buildUrl, {
    int start = 0,
  }) => throw UnimplementedError('streamBuildLog');

  @override
  Future<Result<int, AppFailure>> fetchLogSize(String buildUrl) =>
      throw UnimplementedError('fetchLogSize');

  @override
  Future<Result<List<String>?, AppFailure>> fetchTimestamps(
    String buildUrl, {
    required int startLine,
    int? endLine,
  }) => throw UnimplementedError('fetchTimestamps');

  @override
  Future<Result<void, AppFailure>> downloadConsoleText(
    String buildUrl,
    String savePath,
  ) => throw UnimplementedError('downloadConsoleText');

  @override
  Future<Result<List<JenkinsBuild>, AppFailure>> fetchJobHistory(
    String jobUrl, {
    int start = 0,
    int count = historyPageSize,
  }) => throw UnimplementedError('fetchJobHistory');

  @override
  Future<Result<String?, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    Map<String, ParameterFile> files = const {},
    String? paramToken,
  }) => throw UnimplementedError('triggerBuild');

  @override
  Future<Result<void, AppFailure>> setJobEnabled(
    String jobUrl, {
    required bool enabled,
  }) => throw UnimplementedError('setJobEnabled');

  @override
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl) =>
      throw UnimplementedError('cancelBuild');

  @override
  Future<Result<List<QueueEntry>, AppFailure>> fetchQueue() =>
      throw UnimplementedError('fetchQueue');

  @override
  Future<Result<void, AppFailure>> cancelQueueItem(int id) =>
      throw UnimplementedError('cancelQueueItem');

  @override
  Future<Result<QueueItem, AppFailure>> fetchQueueItem(String queueItemUrl) =>
      throw UnimplementedError('fetchQueueItem');

  @override
  Future<Result<TestReport?, AppFailure>> fetchTestReport(String buildUrl) =>
      throw UnimplementedError('fetchTestReport');

  @override
  Future<Result<Uint8List, AppFailure>> fetchArtifactBytes(
    String buildUrl,
    String relativePath,
  ) => throw UnimplementedError('fetchArtifactBytes');

  @override
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
    String buildUrl,
  ) => throw UnimplementedError('fetchPipelineStages');

  @override
  Future<Result<List<PipelineStep>?, AppFailure>> fetchStageSteps(
    String buildUrl,
    String stageId,
  ) => throw UnimplementedError('fetchStageSteps');

  @override
  Future<Result<StepLog, AppFailure>> fetchStepLog(
    String buildUrl,
    String stepId,
  ) => throw UnimplementedError('fetchStepLog');

  @override
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(
    String buildUrl,
  ) => throw UnimplementedError('fetchPendingInput');

  @override
  Future<Result<void, AppFailure>> submitInput({
    required String buildUrl,
    required String inputId,
    required bool proceed,
    Map<String, String> parameters = const {},
  }) => throw UnimplementedError('submitInput');
}
