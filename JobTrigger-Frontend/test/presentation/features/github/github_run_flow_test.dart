import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/presentation/features/github/github_run_notifier.dart';
import 'package:job_trigger/presentation/features/github/github_run_polling_notifier.dart';
import 'package:job_trigger/presentation/features/github/github_runs_notifier.dart';
import 'package:job_trigger/presentation/features/github/github_trigger_notifier.dart';

import '../../../support/fake_github_repository.dart';

/// PE-40 (P8-20): the remaining GH-RUN notifier behaviour.
ProviderContainer _container(FakeGitHubRepository repo) => ProviderContainer(
  retry: (retryCount, error) => null,
  overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
);

void main() {
  group('GitHubRunNotifier', () {
    test('refresh() fetches the run again', () async {
      final repo = FakeGitHubRepository()
        ..runResult = Ok(testRun(5, status: 'in_progress', conclusion: null));
      final c = _container(repo);
      addTearDown(c.dispose);
      c.listen(gitHubRunNotifierProvider('o', 'r', 5), (_, _) {});
      await c.read(gitHubRunNotifierProvider('o', 'r', 5).future);

      repo.runResult = Ok(testRun(5));
      await c.read(gitHubRunNotifierProvider('o', 'r', 5).notifier).refresh();
      final run = await c.read(gitHubRunNotifierProvider('o', 'r', 5).future);

      expect(repo.fetchRunCalls, 2);
      expect(run.isCompleted, isTrue);
    });
  });

  group('GitHubRunPollingNotifier (US-GH-RUN-03)', () {
    testWidgets('a network error mid-poll keeps polling, unlike a rate limit', (
      tester,
    ) async {
      final repo = FakeGitHubRepository()
        ..runResult = Ok(testRun(9, status: 'in_progress', conclusion: null));
      final c = _container(repo);
      await c.read(gitHubRunNotifierProvider('o', 'r', 9).future);
      c.listen(gitHubRunNotifierProvider('o', 'r', 9), (_, _) {});
      c.listen(gitHubRunPollingNotifierProvider('o', 'r', 9), (_, _) {});

      repo.runResult = const Err(NetworkFailure());
      await tester.pump(const Duration(seconds: 6));
      final afterFailure = repo.fetchRunCalls;
      expect(afterFailure, greaterThanOrEqualTo(2));

      // The network is back: the next poll goes through and ends the polling.
      repo.runResult = Ok(testRun(9));
      await tester.pump(const Duration(seconds: 6));
      expect(repo.fetchRunCalls, greaterThan(afterFailure));
      expect(
        (await c.read(
          gitHubRunNotifierProvider('o', 'r', 9).future,
        )).isCompleted,
        isTrue,
      );

      final settled = repo.fetchRunCalls;
      await tester.pump(const Duration(seconds: 20));
      expect(repo.fetchRunCalls, settled);
      c.dispose();
    });
  });

  group('GitHubTriggerNotifier (US-GH-RUN-02)', () {
    testWidgets('refreshes the runs list again about 3 s after a trigger', (
      tester,
    ) async {
      final repo = FakeGitHubRepository()..runsResult = Ok([testRun(1)]);
      final c = _container(repo);
      c.listen(gitHubTriggerNotifierProvider('o', 'r', 7), (_, _) {});
      c.listen(gitHubRunsNotifierProvider('o', 'r', 7), (_, _) {});
      await c.read(gitHubRunsNotifierProvider('o', 'r', 7).future);

      await c
          .read(gitHubTriggerNotifierProvider('o', 'r', 7).notifier)
          .trigger(ref: 'main', workflowName: 'CI');
      await tester.pump();
      final immediately = repo.fetchRunsCalls;

      await tester.pump(const Duration(seconds: 4));
      await tester.pump();

      expect(repo.fetchRunsCalls, greaterThan(immediately));
      c.dispose();
    });

    testWidgets('the delayed refresh does nothing once disposed', (
      tester,
    ) async {
      final repo = FakeGitHubRepository()..runsResult = Ok([testRun(1)]);
      final c = _container(repo);
      c.listen(gitHubTriggerNotifierProvider('o', 'r', 7), (_, _) {});
      c.listen(gitHubRunsNotifierProvider('o', 'r', 7), (_, _) {});
      await c.read(gitHubRunsNotifierProvider('o', 'r', 7).future);
      await c
          .read(gitHubTriggerNotifierProvider('o', 'r', 7).notifier)
          .trigger(ref: 'main', workflowName: 'CI');
      await tester.pump();
      final before = repo.fetchRunsCalls;

      c.dispose();
      await tester.pump(const Duration(seconds: 5));

      expect(repo.fetchRunsCalls, before);
    });
  });
}
