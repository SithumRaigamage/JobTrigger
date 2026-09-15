import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/build_artifact.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/jenkins_repository.dart';
import 'package:job_trigger/domain/jenkins/log_chunk.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/domain/jenkins/queue_item.dart';
import 'package:job_trigger/domain/jenkins/test_report.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/job_detail/artifact_download_notifier.dart';

const _buildUrl = 'https://jenkins.test/job/demo/1/';
const _artifact = BuildArtifact(
  fileName: 'app.apk',
  relativePath: 'build/outputs/app.apk',
);

/// `share_plus`'s `MethodChannelShare` (the implementation used on every
/// desktop/mobile platform, including macOS -- see
/// `share_plus_macos.dart`'s doc comment) talks over this channel. There's
/// no real OS share sheet in a unit test, so it's mocked here to a
/// successful response, matching how the task brief treats
/// `HapticFeedback`: a real side effect that must not be allowed to break
/// the test, not something asserted on directly.
const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

class _FakeRepository implements JenkinsRepository {
  _FakeRepository(this.result);

  final Result<Uint8List, AppFailure> result;
  int fetchArtifactBytesCallCount = 0;

  @override
  Future<Result<Uint8List, AppFailure>> fetchArtifactBytes(
    String buildUrl,
    String relativePath,
  ) async {
    fetchArtifactBytesCallCount++;
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
  Future<Result<TestReport?, AppFailure>> fetchTestReport(String buildUrl) =>
      throw UnimplementedError();

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          _shareChannel,
          (call) async => 'dev.fluttercommunity.plus/share/success',
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_shareChannel, null);
  });

  test(
    'a successful download resolves to AsyncData and hands the file to the share sheet',
    () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final repo = _FakeRepository(Ok(bytes));
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      // ArtifactDownloadNotifier is itself autoDispose -- keep it alive so
      // its async `download()` call (temp-file I/O, then the share sheet)
      // can't be torn down mid-flight.
      container.listen(
        artifactDownloadNotifierProvider(_artifact.relativePath),
        (_, _) {},
      );

      await container
          .read(artifactDownloadNotifierProvider(_artifact.relativePath).notifier)
          .download(buildUrl: _buildUrl, artifact: _artifact);

      final state = container.read(
        artifactDownloadNotifierProvider(_artifact.relativePath),
      );
      expect(state.hasError, isFalse);
      expect(repo.fetchArtifactBytesCallCount, 1);
    },
  );

  test(
    'a repository failure surfaces as AsyncError and shows an error toast',
    () async {
      final repo = _FakeRepository(const Err(NetworkFailure()));
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(
        artifactDownloadNotifierProvider(_artifact.relativePath),
        (_, _) {},
      );

      await container
          .read(artifactDownloadNotifierProvider(_artifact.relativePath).notifier)
          .download(buildUrl: _buildUrl, artifact: _artifact);

      final state = container.read(
        artifactDownloadNotifierProvider(_artifact.relativePath),
      );
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkFailure>());
      expect(container.read(currentToastProvider)?.type, ToastType.error);
    },
  );
}
