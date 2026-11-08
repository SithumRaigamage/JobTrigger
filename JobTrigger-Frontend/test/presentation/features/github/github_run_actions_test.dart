import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/presentation/common_widgets/toast_controller.dart';
import 'package:job_trigger/presentation/features/github/github_cancel_notifier.dart';
import 'package:job_trigger/presentation/features/github/github_run_notifier.dart';
import 'package:job_trigger/presentation/features/github/github_run_polling_notifier.dart';
import 'package:job_trigger/presentation/features/github/github_runs_notifier.dart';
import 'package:job_trigger/presentation/features/github/github_trigger_notifier.dart';

import '../../../support/fake_github_repository.dart';

ProviderContainer _container(FakeGitHubRepository repo) => ProviderContainer(
  retry: (retryCount, error) => null,
  overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
);

void main() {
  group('GitHubTriggerNotifier (US-GH-RUN-02)', () {
    test('sends ref and inputs, toasts, and refreshes the runs list', () async {
      final repo = FakeGitHubRepository()..runsResult = Ok([testRun(1)]);
      final c = _container(repo);
      addTearDown(c.dispose);
      c.listen(gitHubTriggerNotifierProvider('o', 'r', 7), (_, _) {});
      c.listen(gitHubRunsNotifierProvider('o', 'r', 7), (_, _) {});
      await c.read(gitHubRunsNotifierProvider('o', 'r', 7).future);
      expect(repo.fetchRunsCalls, 1);

      await c
          .read(gitHubTriggerNotifierProvider('o', 'r', 7).notifier)
          .trigger(ref: 'release', inputs: {'env': 'prod'}, workflowName: 'CI');
      await c.read(gitHubRunsNotifierProvider('o', 'r', 7).future);

      expect(repo.triggerCalls, 1);
      expect(repo.lastRef, 'release');
      expect(repo.lastInputs, {'env': 'prod'});
      expect(repo.fetchRunsCalls, greaterThanOrEqualTo(2));
      expect(c.read(currentToastProvider)?.type, ToastType.success);
      expect(
        c.read(gitHubTriggerNotifierProvider('o', 'r', 7)).hasError,
        isFalse,
      );
    });

    test('a 422 surfaces the dispatch failure and an error toast', () async {
      final repo = FakeGitHubRepository()
        ..triggerResult = const Err(DispatchRejectedFailure('no trigger'));
      final c = _container(repo);
      addTearDown(c.dispose);
      c.listen(gitHubTriggerNotifierProvider('o', 'r', 7), (_, _) {});

      await c
          .read(gitHubTriggerNotifierProvider('o', 'r', 7).notifier)
          .trigger(ref: 'main', workflowName: 'CI');

      final state = c.read(gitHubTriggerNotifierProvider('o', 'r', 7));
      expect(state.error, isA<DispatchRejectedFailure>());
      expect(c.read(currentToastProvider)?.type, ToastType.error);
      expect(
        (state.error! as DispatchRejectedFailure).message,
        contains('workflow_dispatch'),
      );
    });
  });

  group('GitHubCancelNotifier (US-GH-RUN-04)', () {
    test(
      'success marks the cancel requested without faking a conclusion',
      () async {
        final repo = FakeGitHubRepository()
          ..runResult = Ok(testRun(5, status: 'in_progress', conclusion: null));
        final c = _container(repo);
        addTearDown(c.dispose);
        c.listen(gitHubCancelNotifierProvider('o', 'r', 5), (_, _) {});
        c.listen(gitHubRunNotifierProvider('o', 'r', 5), (_, _) {});
        await c.read(gitHubRunNotifierProvider('o', 'r', 5).future);

        await c
            .read(gitHubCancelNotifierProvider('o', 'r', 5).notifier)
            .cancel(runNumber: 5);

        expect(repo.cancelCalls, 1);
        expect(c.read(gitHubCancelNotifierProvider('o', 'r', 5)).value, isTrue);
        // The run itself is only corrected by the next poll.
        final run = await c.read(gitHubRunNotifierProvider('o', 'r', 5).future);
        expect(run.status, 'in_progress');
        expect(c.read(currentToastProvider)?.type, ToastType.success);
      },
    );

    test('a failure changes nothing and shows an error toast', () async {
      final repo = FakeGitHubRepository()
        ..cancelResult = const Err(NetworkFailure());
      final c = _container(repo);
      addTearDown(c.dispose);
      c.listen(gitHubCancelNotifierProvider('o', 'r', 5), (_, _) {});

      await c
          .read(gitHubCancelNotifierProvider('o', 'r', 5).notifier)
          .cancel(runNumber: 5);

      expect(c.read(gitHubCancelNotifierProvider('o', 'r', 5)).value, isFalse);
      expect(c.read(currentToastProvider)?.type, ToastType.error);
    });
  });

  group('GitHubRunPollingNotifier (US-GH-RUN-03)', () {
    testWidgets('polls every ~5s while the run is active', (tester) async {
      final repo = FakeGitHubRepository()
        ..runResult = Ok(testRun(9, status: 'in_progress', conclusion: null));
      final c = _container(repo);
      await c.read(gitHubRunNotifierProvider('o', 'r', 9).future);
      c.listen(gitHubRunNotifierProvider('o', 'r', 9), (_, _) {});
      c.listen(gitHubRunPollingNotifierProvider('o', 'r', 9), (_, _) {});
      expect(repo.fetchRunCalls, 1);

      await tester.pump(const Duration(seconds: 6));

      expect(repo.fetchRunCalls, greaterThanOrEqualTo(2));
      c.dispose();
    });

    testWidgets('stops once the run completes', (tester) async {
      final repo = FakeGitHubRepository()..runResult = Ok(testRun(9));
      final c = _container(repo);
      await c.read(gitHubRunNotifierProvider('o', 'r', 9).future);
      c.listen(gitHubRunNotifierProvider('o', 'r', 9), (_, _) {});
      c.listen(gitHubRunPollingNotifierProvider('o', 'r', 9), (_, _) {});

      await tester.pump(const Duration(seconds: 12));

      expect(repo.fetchRunCalls, 1);
      c.dispose();
    });

    testWidgets('a rate limit mid-poll stops polling', (tester) async {
      final repo = FakeGitHubRepository()
        ..runResult = Ok(testRun(9, status: 'in_progress', conclusion: null));
      final c = _container(repo);
      await c.read(gitHubRunNotifierProvider('o', 'r', 9).future);
      c.listen(gitHubRunNotifierProvider('o', 'r', 9), (_, _) {});
      c.listen(gitHubRunPollingNotifierProvider('o', 'r', 9), (_, _) {});

      repo.runResult = const Err(RateLimitFailure());
      await tester.pump(const Duration(seconds: 6));
      final callsAtLimit = repo.fetchRunCalls;
      expect(callsAtLimit, greaterThanOrEqualTo(2));

      await tester.pump(const Duration(seconds: 30));

      expect(repo.fetchRunCalls, callsAtLimit);
      expect(
        c.read(gitHubRunNotifierProvider('o', 'r', 9)).error,
        isA<RateLimitFailure>(),
      );
      c.dispose();
    });

    testWidgets('disposing cancels the timer', (tester) async {
      final repo = FakeGitHubRepository()
        ..runResult = Ok(testRun(9, status: 'in_progress', conclusion: null));
      final c = _container(repo);
      await c.read(gitHubRunNotifierProvider('o', 'r', 9).future);
      final sub = c.listen(
        gitHubRunPollingNotifierProvider('o', 'r', 9),
        (_, _) {},
      );
      final before = repo.fetchRunCalls;

      sub.close();
      c.dispose();
      await tester.pump(const Duration(seconds: 12));

      expect(repo.fetchRunCalls, before);
    });
  });
}
