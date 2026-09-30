import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/jenkins_repository_impl.dart';
import 'package:job_trigger/domain/jenkins/jenkins_build.dart';
import 'package:job_trigger/domain/jenkins/jenkins_job.dart';
import 'package:job_trigger/domain/jenkins/pending_input.dart';
import 'package:job_trigger/domain/jenkins/pipeline_stage.dart';
import 'package:job_trigger/presentation/features/job_detail/build_status_polling_notifier.dart';
import 'package:job_trigger/presentation/features/job_detail/job_detail_notifier.dart';
import 'package:job_trigger/presentation/features/job_detail/pending_input_notifier.dart';
import 'package:job_trigger/presentation/features/job_detail/pipeline_stages_notifier.dart';
import '../../../support/fake_jenkins_repository.dart';

const _jobUrl = 'https://jenkins.test/job/demo/';
const _buildUrl = '${_jobUrl}1/';

/// Counts `fetchJobDetail`/`fetchPipelineStages` calls so tests can
/// observe whether the polling loop actually fired (or, for the dispose
/// test, correctly did not).
class _CountingRepository extends FakeJenkinsRepository {
  int fetchJobDetailCallCount = 0;
  int fetchPipelineStagesCallCount = 0;
  int fetchPendingInputCallCount = 0;
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
  Future<Result<List<PipelineStage>?, AppFailure>> fetchPipelineStages(
    String buildUrl,
  ) async {
    fetchPipelineStagesCallCount++;
    return const Ok(null);
  }

  @override
  Future<Result<PendingInput?, AppFailure>> fetchPendingInput(
    String buildUrl,
  ) async {
    fetchPendingInputCallCount++;
    return const Ok(null);
  }
}

void main() {
  // The widget tester's fake clock: `tester.pump(6s)` advances time
  // instantly and deterministically. These used real timers before, which
  // took 30s and timed out on a loaded machine. Each test disposes its
  // container in the body, cancelling the re-armed poll timer before the
  // pending-timer check.

  testWidgets('polls again after ~5s while the build is still building', (
    tester,
  ) async {
    final repo = _CountingRepository()..building = true;
    final container = ProviderContainer(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );

    await container.read(jobDetailNotifierProvider(_jobUrl).future);
    expect(repo.fetchJobDetailCallCount, 1);

    container.listen(buildStatusPollingNotifierProvider(_jobUrl), (_, _) {});

    await tester.pump(const Duration(seconds: 6));

    expect(repo.fetchJobDetailCallCount, greaterThanOrEqualTo(2));
    container.dispose();
  });

  testWidgets(
    'also invalidates PipelineStagesNotifier for the current build on the same tick (US-PIPE-04)',
    (tester) async {
      final repo = _CountingRepository()..building = true;
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );

      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      // Keep PipelineStagesNotifier alive too -- same autoDispose
      // reasoning as jobDetailNotifierProvider elsewhere in this file.
      await container.read(pipelineStagesNotifierProvider(_buildUrl).future);
      expect(repo.fetchPipelineStagesCallCount, 1);

      container.listen(buildStatusPollingNotifierProvider(_jobUrl), (_, _) {});
      container.listen(pipelineStagesNotifierProvider(_buildUrl), (_, _) {});

      await tester.pump(const Duration(seconds: 6));

      expect(repo.fetchPipelineStagesCallCount, greaterThanOrEqualTo(2));
      container.dispose();
    },
  );

  testWidgets(
    'also invalidates PendingInputNotifier for the current build on the same tick (US-PIPE-05)',
    (tester) async {
      final repo = _CountingRepository()..building = true;
      final container = ProviderContainer(
        overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
      );

      await container.read(jobDetailNotifierProvider(_jobUrl).future);
      await container.read(pendingInputNotifierProvider(_buildUrl).future);
      expect(repo.fetchPendingInputCallCount, 1);

      container.listen(buildStatusPollingNotifierProvider(_jobUrl), (_, _) {});
      container.listen(pendingInputNotifierProvider(_buildUrl), (_, _) {});

      await tester.pump(const Duration(seconds: 6));

      expect(repo.fetchPendingInputCallCount, greaterThanOrEqualTo(2));
      container.dispose();
    },
  );

  testWidgets(
    'cancels its timer on dispose -- no further fetches after the container is gone',
    (tester) async {
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
      await tester.pump(const Duration(seconds: 6));

      expect(repo.fetchJobDetailCallCount, 1);
    },
  );

  testWidgets('does not schedule a timer at all once the build has finished', (
    tester,
  ) async {
    final repo = _CountingRepository()..building = false;
    final container = ProviderContainer(
      overrides: [jenkinsRepositoryProvider.overrideWithValue(repo)],
    );

    await container.read(jobDetailNotifierProvider(_jobUrl).future);
    container.listen(buildStatusPollingNotifierProvider(_jobUrl), (_, _) {});
    expect(repo.fetchJobDetailCallCount, 1);

    await tester.pump(const Duration(seconds: 6));

    expect(repo.fetchJobDetailCallCount, 1);
    container.dispose();
  });
}
