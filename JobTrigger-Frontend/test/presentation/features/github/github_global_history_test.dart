import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/presentation/features/github/github_global_history_notifier.dart';
import 'package:job_trigger/presentation/features/github/github_global_history_screen.dart';

import '../../../support/fake_github_repository.dart';

GitHubRepo _repo(String name) => GitHubRepo(
  id: name.hashCode,
  name: name,
  owner: 'acme',
  fullName: 'acme/$name',
);

DateTime _at(int hoursAgo) =>
    DateTime.now().subtract(Duration(hours: hoursAgo));

ProviderContainer _container(FakeGitHubRepository repo) {
  final c = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [gitHubRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('GitHubGlobalHistoryNotifier (US-GH-HIST-02)', () {
    test('merges runs from several repos newest first', () async {
      final repo = FakeGitHubRepository()
        ..reposResult = Ok([_repo('api'), _repo('web')])
        ..repoRuns['api'] = Ok([
          testRun(1, createdAt: _at(5)),
          testRun(2, createdAt: _at(1)),
        ])
        ..repoRuns['web'] = Ok([testRun(3, createdAt: _at(3))]);
      final c = _container(repo);

      final feed = await c.read(gitHubGlobalHistoryNotifierProvider.future);

      expect(feed.entries.map((e) => e.run.id), [2, 3, 1]);
      expect(feed.entries.map((e) => e.repo.name), ['api', 'web', 'api']);
      expect(feed.reposFailed, 0);
      expect(feed.reposSkipped, 0);
    });

    test(
      'asks at most the capped number of repos and reports the rest',
      () async {
        final repo = FakeGitHubRepository()
          ..reposResult = Ok([for (var i = 0; i < 12; i++) _repo('r$i')]);
        final c = _container(repo);

        final feed = await c.read(gitHubGlobalHistoryNotifierProvider.future);

        expect(repo.repoRunsRequested, hasLength(globalHistoryRepoCap));
        expect(repo.repoRunsRequested, [for (var i = 0; i < 8; i++) 'r$i']);
        expect(feed.reposAsked, 8);
        expect(feed.reposSkipped, 4);
      },
    );

    test('one repo failing does not hide the others', () async {
      final repo = FakeGitHubRepository()
        ..reposResult = Ok([_repo('api'), _repo('web')])
        ..repoRuns['api'] = const Err(NotFoundFailure())
        ..repoRuns['web'] = Ok([testRun(3, createdAt: _at(1))]);
      final c = _container(repo);

      final feed = await c.read(gitHubGlobalHistoryNotifierProvider.future);

      expect(feed.entries.map((e) => e.run.id), [3]);
      expect(feed.reposFailed, 1);
      expect(feed.firstFailure, isA<NotFoundFailure>());
    });

    test('every repo failing is an error, not an empty feed', () async {
      final repo = FakeGitHubRepository()
        ..reposResult = Ok([_repo('api'), _repo('web')])
        ..repoRuns['api'] = const Err(RateLimitFailure())
        ..repoRuns['web'] = const Err(RateLimitFailure());
      final c = _container(repo);
      c.listen(gitHubGlobalHistoryNotifierProvider, (_, _) {});

      await expectLater(
        c.read(gitHubGlobalHistoryNotifierProvider.future),
        throwsA(isA<RateLimitFailure>()),
      );
    });

    test('no repos is an empty feed, not an error', () async {
      final repo = FakeGitHubRepository()..reposResult = const Ok([]);
      final c = _container(repo);

      final feed = await c.read(gitHubGlobalHistoryNotifierProvider.future);

      expect(feed.entries, isEmpty);
      expect(repo.repoRunsRequested, isEmpty);
    });

    test('keeps only the newest runs overall', () async {
      final repo = FakeGitHubRepository()
        ..reposResult = Ok([_repo('api')])
        ..repoRuns['api'] = Ok([
          for (var i = 0; i < 80; i++) testRun(i, createdAt: _at(i)),
        ]);
      final c = _container(repo);

      final feed = await c.read(gitHubGlobalHistoryNotifierProvider.future);

      expect(feed.entries, hasLength(globalHistoryLimit));
      expect(feed.entries.first.run.id, 0);
    });
  });

  group('GitHubGlobalHistoryScreen', () {
    Future<void> pump(WidgetTester tester, FakeGitHubRepository fake) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (retryCount, error) => null,
          overrides: [gitHubRepositoryProvider.overrideWithValue(fake)],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const GitHubGlobalHistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('prefixes each run with its repo and explains coverage', (
      tester,
    ) async {
      final fake = FakeGitHubRepository()
        ..reposResult = Ok([for (var i = 0; i < 10; i++) _repo('r$i')])
        ..repoRuns['r0'] = Ok([testRun(1, createdAt: _at(1))])
        ..repoRuns['r1'] = const Err(NotFoundFailure());

      await pump(tester, fake);

      expect(find.textContaining('acme/r0'), findsWidgets);
      expect(find.textContaining('2 more were left out'), findsOneWidget);
      expect(find.textContaining('1 could not be read'), findsOneWidget);
    });

    testWidgets('as the History tab root it has no back button', (
      tester,
    ) async {
      final fake = FakeGitHubRepository()
        ..reposResult = Ok([_repo('api')])
        ..repoRuns['api'] = Ok([testRun(1, createdAt: _at(1))]);
      await tester.pumpWidget(
        ProviderScope(
          retry: (retryCount, error) => null,
          overrides: [gitHubRepositoryProvider.overrideWithValue(fake)],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const GitHubGlobalHistoryScreen(isTab: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent activity'), findsOneWidget);
      expect(find.byTooltip('Back'), findsNothing);
      expect(find.textContaining('acme/api'), findsWidgets);
    });

    testWidgets('an empty feed says so', (tester) async {
      await pump(tester, FakeGitHubRepository()..reposResult = const Ok([]));

      expect(find.text('No recent runs'), findsOneWidget);
    });

    testWidgets('a total failure shows the error with retry', (tester) async {
      final fake = FakeGitHubRepository()
        ..reposResult = Ok([_repo('api')])
        ..repoRuns['api'] = const Err(NetworkFailure());
      await pump(tester, fake);
      expect(find.textContaining("Can't reach the server"), findsOneWidget);

      fake.repoRuns['api'] = Ok([testRun(1, createdAt: _at(1))]);
      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();

      expect(find.textContaining('acme/api'), findsWidgets);
    });
  });
}
