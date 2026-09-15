import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/credentials_repository_impl.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/credential/credentials_repository.dart';
import 'package:job_trigger/domain/credential/jenkins_server.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/jenkins_repository.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/queue_item.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_notifier.dart';
import 'package:job_trigger/presentation/features/job_detail/trigger_build_notifier.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

const _jobUrl = 'https://jenkins.test/job/demo/';

/// Fakes only what `TriggerBuildNotifier` and the `JobDetailNotifier` it
/// refreshes actually call -- same "throw UnimplementedError for the rest"
/// style as `build_status_polling_notifier_test.dart`'s `_CountingRepository`.
class _FakeRepository implements JenkinsRepository {
  Result<String?, AppFailure>? triggerResult;
  int fetchJobDetailCallCount = 0;
  int triggerBuildCallCount = 0;

  @override
  Future<Result<JenkinsJob, AppFailure>> fetchJobDetail(String jobUrl) async {
    fetchJobDetailCallCount++;
    return Ok(JenkinsJob(name: 'demo', url: jobUrl));
  }

  @override
  Future<Result<String?, AppFailure>> triggerBuild(
    String jobUrl, {
    required bool isParameterized,
    Map<String, String> parameters = const {},
    String? paramToken,
  }) async {
    triggerBuildCallCount++;
    return triggerResult!;
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

/// `TriggerBuildNotifier` reads `activeServerNotifierProvider`, which kicks
/// off `CredentialsNotifier` rehydration in the background -- fake it out so
/// no real `Dio`/backend call happens during the test.
class _FakeCredentialsRepository implements CredentialsRepository {
  @override
  Future<Result<List<JenkinsServer>, AppFailure>> fetchAll() async =>
      const Ok([]);

  @override
  Future<Result<void, AppFailure>> delete(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<JenkinsServer, AppFailure>> add({
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) => throw UnimplementedError();

  @override
  Future<Result<JenkinsServer, AppFailure>> update(
    String id, {
    required String serverName,
    required String jenkinsURL,
    required String username,
    required String secret,
    String? paramToken,
    bool isDefault = false,
  }) => throw UnimplementedError();

  @override
  Future<Result<JenkinsServer, AppFailure>> switchActive(String id) =>
      throw UnimplementedError();
}

const _job = JenkinsJob(name: 'demo', url: _jobUrl);

void main() {
  // HapticFeedback (called on both the success and failure path) talks over
  // a platform channel, which needs a binding -- see
  // `artifact_download_notifier_test.dart` for the same requirement with
  // `share_plus`.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
  });

  test(
    'a successful trigger refreshes JobDetailNotifier and shows a success toast',
    () async {
      final repo = _FakeRepository()..triggerResult = const Ok(null);
      final container = ProviderContainer(
        overrides: [
          jenkinsRepositoryProvider.overrideWithValue(repo),
          credentialsRepositoryProvider.overrideWithValue(
            _FakeCredentialsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      container.listen(jobDetailNotifierProvider(_jobUrl), (_, _) {});
      // TriggerBuildNotifier is itself autoDispose -- keep it alive so its
      // async `trigger()` call can't be torn down mid-flight.
      container.listen(triggerBuildNotifierProvider(_jobUrl), (_, _) {});
      expect(repo.fetchJobDetailCallCount, 1);

      await container
          .read(triggerBuildNotifierProvider(_jobUrl).notifier)
          .trigger(job: _job);
      // `refresh()` only invalidates -- the actual re-fetch is scheduled,
      // not synchronous, so wait for it before checking the call count.
      await container.read(jobDetailNotifierProvider(_jobUrl).future);

      expect(container.read(triggerBuildNotifierProvider(_jobUrl)).hasError, isFalse);
      expect(repo.triggerBuildCallCount, 1);
      expect(repo.fetchJobDetailCallCount, 2);
      expect(container.read(currentToastProvider)?.type, ToastType.success);
    },
  );

  test(
    'a repository failure surfaces as AsyncError and shows an error toast, without refreshing job detail',
    () async {
      final repo = _FakeRepository()..triggerResult = const Err(NetworkFailure());
      final container = ProviderContainer(
        overrides: [
          jenkinsRepositoryProvider.overrideWithValue(repo),
          credentialsRepositoryProvider.overrideWithValue(
            _FakeCredentialsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      container.listen(jobDetailNotifierProvider(_jobUrl), (_, _) {});
      container.listen(triggerBuildNotifierProvider(_jobUrl), (_, _) {});
      expect(repo.fetchJobDetailCallCount, 1);

      await container
          .read(triggerBuildNotifierProvider(_jobUrl).notifier)
          .trigger(job: _job);

      final state = container.read(triggerBuildNotifierProvider(_jobUrl));
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkFailure>());
      expect(repo.fetchJobDetailCallCount, 1);
      expect(container.read(currentToastProvider)?.type, ToastType.error);
    },
  );
}
