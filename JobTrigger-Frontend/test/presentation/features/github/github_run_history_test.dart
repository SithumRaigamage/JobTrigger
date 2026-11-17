import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/github/github_repository.dart';
import 'package:job_trigger/domain/github/github_workflow.dart';
import 'package:job_trigger/presentation/features/github/github_run_history_notifier.dart';
import 'package:job_trigger/presentation/features/github/github_run_history_screen.dart';

import '../../../support/fake_github_repository.dart';

const _repo = GitHubRepo(
  id: 1,
  name: 'api',
  owner: 'acme',
  fullName: 'acme/api',
);
const _workflow = GitHubWorkflow(
  id: 42,
  name: 'CI',
  path: '.github/workflows/ci.yml',
  state: 'active',
);

List<T> _page<T>(int start, int count, T Function(int) make) => [
  for (var i = 0; i < count; i++) make(start + i),
];

ProviderContainer _container(FakeGitHubRepository repo) {
  final c = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('GitHubRunHistoryNotifier (US-GH-HIST-01)', () {
    test('a full first page means there may be more', () async {
      final repo = FakeGitHubRepository()
        ..runsResult = Ok(_page(1, gitHubRunsPageSize, testRun));
      final c = _container(repo);

      final pages = await c.read(
        gitHubRunHistoryNotifierProvider('o', 'r', 7).future,
      );

      expect(pages.runs, hasLength(gitHubRunsPageSize));
      expect(pages.hasMore, isTrue);
    });

    test('a short first page is the whole history', () async {
      final repo = FakeGitHubRepository()
        ..runsResult = Ok(_page(1, 5, testRun));
      final c = _container(repo);

      final pages = await c.read(
        gitHubRunHistoryNotifierProvider('o', 'r', 7).future,
      );

      expect(pages.hasMore, isFalse);
    });

    test('loadMore appends the next page, then stops on a short one', () async {
      final repo = FakeGitHubRepository()
        ..runsPages[1] = Ok(_page(100, gitHubRunsPageSize, testRun))
        ..runsPages[2] = Ok(_page(200, gitHubRunsPageSize, testRun))
        ..runsPages[3] = Ok(_page(300, 4, testRun));
      final c = _container(repo);
      c.listen(gitHubRunHistoryNotifierProvider('o', 'r', 7), (_, _) {});
      await c.read(gitHubRunHistoryNotifierProvider('o', 'r', 7).future);
      final notifier = c.read(
        gitHubRunHistoryNotifierProvider('o', 'r', 7).notifier,
      );

      await notifier.loadMore();
      await notifier.loadMore();
      await notifier.loadMore(); // already at the end: a no-op

      final pages = c
          .read(gitHubRunHistoryNotifierProvider('o', 'r', 7))
          .value!;
      expect(repo.requestedPages, [1, 2, 3]);
      expect(pages.runs, hasLength(gitHubRunsPageSize * 2 + 4));
      expect(pages.hasMore, isFalse);
    });

    test('a failed loadMore keeps the list and can be retried', () async {
      final repo = FakeGitHubRepository()
        ..runsPages[1] = Ok(_page(100, gitHubRunsPageSize, testRun))
        ..runsPages[2] = const Err(NetworkFailure());
      final c = _container(repo);
      c.listen(gitHubRunHistoryNotifierProvider('o', 'r', 7), (_, _) {});
      await c.read(gitHubRunHistoryNotifierProvider('o', 'r', 7).future);
      final notifier = c.read(
        gitHubRunHistoryNotifierProvider('o', 'r', 7).notifier,
      );

      await notifier.loadMore();
      var pages = c.read(gitHubRunHistoryNotifierProvider('o', 'r', 7)).value!;
      expect(pages.runs, hasLength(gitHubRunsPageSize));
      expect(pages.loadMoreFailure, isA<NetworkFailure>());
      expect(pages.hasMore, isTrue);

      repo.runsPages[2] = Ok(_page(200, 3, testRun));
      await notifier.loadMore();
      pages = c.read(gitHubRunHistoryNotifierProvider('o', 'r', 7)).value!;
      expect(pages.runs, hasLength(gitHubRunsPageSize + 3));
      expect(pages.loadMoreFailure, isNull);
    });
  });

  group('GitHubRunHistoryScreen', () {
    Future<void> pump(WidgetTester tester, FakeGitHubRepository fake) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (retryCount, error) => null,
          overrides: [gitHubRepositoryProvider.overrideWithValue(fake)],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const GitHubRunHistoryScreen(
              repo: _repo,
              workflow: _workflow,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists runs and marks the start of a short history', (
      tester,
    ) async {
      final fake = FakeGitHubRepository()
        ..runsResult = Ok([testRun(2, conclusion: 'failure'), testRun(1)]);

      await pump(tester, fake);

      expect(find.text('History'), findsOneWidget);
      expect(find.textContaining('run 2'), findsOneWidget);
      expect(find.textContaining('Failed'), findsOneWidget);
      expect(find.textContaining('Success'), findsOneWidget);
      expect(find.text('Start of history'), findsOneWidget);
    });

    testWidgets('scrolling near the end loads the next page', (tester) async {
      final fake = FakeGitHubRepository()
        ..runsPages[1] = Ok(_page(100, gitHubRunsPageSize, testRun))
        ..runsPages[2] = Ok(_page(200, 2, testRun));
      await pump(tester, fake);
      expect(fake.requestedPages, [1]);

      await tester.fling(find.byType(ListView), const Offset(0, -4000), 4000);
      await tester.pumpAndSettle();

      expect(fake.requestedPages, [1, 2]);
    });

    testWidgets('a first-page failure shows the error with retry', (
      tester,
    ) async {
      final fake = FakeGitHubRepository()
        ..runsResult = const Err(RateLimitFailure());
      await pump(tester, fake);
      expect(find.textContaining('rate limit'), findsOneWidget);

      fake.runsResult = Ok([testRun(1)]);
      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();

      expect(find.textContaining('run 1'), findsOneWidget);
    });
  });
}
