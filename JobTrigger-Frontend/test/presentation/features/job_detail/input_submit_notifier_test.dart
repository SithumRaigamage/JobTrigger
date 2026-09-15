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
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/job_detail/input_submit_notifier.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_notifier.dart';
import 'package:job_trigger/presentation/features/job_detail/pending_input_notifier.dart';

const _jobUrl = 'https://jenkins.test/job/demo/';
const _buildUrl = '${_jobUrl}1/';

class _FakeRepository implements JenkinsRepository {
  Result<void, AppFailure>? submitResult;
  int fetchJobDetailCallCount = 0;
  int fetchPendingInputCallCount = 0;
  int submitInputCallCount = 0;
  bool? lastProceed;

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async {
    fetchJobDetailCallCount++;
    return Ok(JenkinsJob(name: 'demo', url: jobUrl));
  }

  @override
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(
    String buildUrl,
  ) async {
    fetchPendingInputCallCount++;
    return const Ok(PendingInput(id: 'input-1'));
  }

  @override
  Future<Result<void, AppFailure>> submitInput({
    required String buildUrl,
    required String inputId,
    required bool proceed,
    Map<String, String> parameters = const {},
  }) async {
    submitInputCallCount++;
    lastProceed = proceed;
    return submitResult!;
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
}

void main() {
  // HapticFeedback (called on both the success and failure path) talks over
  // a platform channel, which needs a binding -- see
  // `artifact_download_notifier_test.dart` for the same requirement with
  // `share_plus`.
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a successful approve refreshes job detail, invalidates pending input, and shows a success toast',
    () async {
      final repo = _FakeRepository()..submitResult = const Ok(null);
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      container.listen(jobDetailNotifierProvider(_jobUrl), (_, _) {});
      await container.read(pendingInputNotifierProvider(_buildUrl).future);
      container.listen(pendingInputNotifierProvider(_buildUrl), (_, _) {});
      // InputSubmitNotifier is itself autoDispose -- keep it alive so its
      // async `submit()` call can't be torn down mid-flight.
      container.listen(inputSubmitNotifierProvider(_buildUrl), (_, _) {});
      expect(repo.fetchJobDetailCallCount, 1);
      expect(repo.fetchPendingInputCallCount, 1);

      await container
          .read(inputSubmitNotifierProvider(_buildUrl).notifier)
          .submit(jobUrl: _jobUrl, inputId: 'input-1', proceed: true);
      // `refresh()`/`invalidate()` only mark the providers dirty -- the
      // actual re-fetches are scheduled, not synchronous, so wait for them
      // before checking the call counts.
      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      await container.read(pendingInputNotifierProvider(_buildUrl).future);

      expect(
        container.read(inputSubmitNotifierProvider(_buildUrl)).hasError,
        isFalse,
      );
      expect(repo.submitInputCallCount, 1);
      expect(repo.lastProceed, isTrue);
      expect(repo.fetchJobDetailCallCount, 2);
      expect(repo.fetchPendingInputCallCount, 2);
      expect(container.read(currentToastProvider)?.type, ToastType.success);
    },
  );

  test(
    'a repository failure surfaces as AsyncError and shows an error toast, without refreshing anything',
    () async {
      final repo = _FakeRepository()
        ..submitResult = const Err(AuthFailure());
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      container.listen(jobDetailNotifierProvider(_jobUrl), (_, _) {});
      await container.read(pendingInputNotifierProvider(_buildUrl).future);
      container.listen(pendingInputNotifierProvider(_buildUrl), (_, _) {});
      container.listen(inputSubmitNotifierProvider(_buildUrl), (_, _) {});
      expect(repo.fetchJobDetailCallCount, 1);
      expect(repo.fetchPendingInputCallCount, 1);

      await container
          .read(inputSubmitNotifierProvider(_buildUrl).notifier)
          .submit(jobUrl: _jobUrl, inputId: 'input-1', proceed: false);

      final state = container.read(inputSubmitNotifierProvider(_buildUrl));
      expect(state.hasError, isTrue);
      expect(state.error, isA<AuthFailure>());
      expect(repo.lastProceed, isFalse);
      expect(repo.fetchJobDetailCallCount, 1);
      expect(repo.fetchPendingInputCallCount, 1);
      expect(container.read(currentToastProvider)?.type, ToastType.error);
    },
  );
}
