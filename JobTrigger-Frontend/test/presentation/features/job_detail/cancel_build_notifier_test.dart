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
import 'package:job_trigger/presentation/features/job_detail/cancel_build_notifier.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_notifier.dart';

const _jobUrl = 'https://jenkins.test/job/demo/';
const _buildUrl = '${_jobUrl}1/';

class _FakeRepository implements JenkinsRepository {
  Result<void, AppFailure>? cancelResult;
  int fetchJobDetailCallCount = 0;
  int cancelBuildCallCount = 0;

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async {
    fetchJobDetailCallCount++;
    return Ok(
      JenkinsJob(
        name: 'demo',
        url: jobUrl,
        lastBuild: const JenkinsBuild(
          number: 1,
          url: _buildUrl,
          timestamp: 0,
          building: true,
        ),
      ),
    );
  }

  @override
  Future<Result<void, AppFailure>> cancelBuild(String buildUrl) async {
    cancelBuildCallCount++;
    return cancelResult!;
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
  // HapticFeedback (called on both the success and failure path) talks over
  // a platform channel, which needs a binding -- see
  // `artifact_download_notifier_test.dart` for the same requirement with
  // `share_plus`.
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a successful cancel optimistically flips the build to ABORTED and shows a success toast',
    () async {
      final repo = _FakeRepository()..cancelResult = const Ok(null);
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      container.listen(jobDetailNotifierProvider(_jobUrl), (_, _) {});
      // CancelBuildNotifier is itself autoDispose -- keep it alive so its
      // async `cancel()` call can't be torn down mid-flight (same reasoning
      // as job_detail_notifier_test.dart's error-case fix).
      container.listen(cancelBuildNotifierProvider(_jobUrl), (_, _) {});

      await container
          .read(cancelBuildNotifierProvider(_jobUrl).notifier)
          .cancel(buildUrl: _buildUrl, buildNumber: 1);

      expect(
        container.read(cancelBuildNotifierProvider(_jobUrl)).hasError,
        isFalse,
      );
      expect(repo.cancelBuildCallCount, 1);
      final job = container.read(jobDetailNotifierProvider(_jobUrl)).value;
      expect(job?.lastBuild?.result, 'ABORTED');
      expect(job?.lastBuild?.building, isFalse);
      expect(container.read(currentToastProvider)?.type, ToastType.success);
    },
  );

  test(
    'a repository failure surfaces as AsyncError and shows an error toast, without touching job detail',
    () async {
      final repo = _FakeRepository()
        ..cancelResult = const Err(ServerFailure(500));
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      container.listen(jobDetailNotifierProvider(_jobUrl), (_, _) {});
      container.listen(cancelBuildNotifierProvider(_jobUrl), (_, _) {});

      await container
          .read(cancelBuildNotifierProvider(_jobUrl).notifier)
          .cancel(buildUrl: _buildUrl, buildNumber: 1);

      final state = container.read(cancelBuildNotifierProvider(_jobUrl));
      expect(state.hasError, isTrue);
      expect(state.error, isA<ServerFailure>());
      final job = container.read(jobDetailNotifierProvider(_jobUrl)).value;
      expect(job?.lastBuild?.building, isTrue);
      expect(job?.lastBuild?.result, isNull);
      expect(container.read(currentToastProvider)?.type, ToastType.error);
    },
  );
}
