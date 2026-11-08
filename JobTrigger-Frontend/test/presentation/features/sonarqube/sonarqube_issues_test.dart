import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_issues_notifier.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_issues_screen.dart';

class _Repo implements SonarQubeRepository {
  /// Total issues on the "server"; pages are sliced from it. A filter with
  /// types narrows it to that many bugs.
  int total = 120;
  int bugsTotal = 7;
  Result<SonarQubeIssuePage, AppFailure>? forcedResult;
  final List<(SonarQubeIssueFilter, int)> calls = [];

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) async {
    calls.add((filter, page));
    if (forcedResult != null) return forcedResult!;
    final count = filter.types.contains('BUG') ? bugsTotal : total;
    final start = (page - 1) * sonarQubeIssuesPageSize;
    final n = (count - start).clamp(0, sonarQubeIssuesPageSize);
    return Ok(
      SonarQubeIssuePage(
        total: count,
        issues: [
          for (var i = 0; i < n; i++)
            SonarQubeIssue(
              key: 'i${start + i}',
              type: filter.types.contains('BUG') ? 'BUG' : 'CODE_SMELL',
              severity: 'MAJOR',
              message: 'Issue ${start + i}',
              file: 'src/F.java',
              line: start + i + 1,
            ),
        ],
      ),
    );
  }

  @override
  Future<Result<List<SonarQubeProject>, AppFailure>> fetchProjects() =>
      throw UnimplementedError();

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) => throw UnimplementedError();
}

const _project = SonarQubeProject(
  key: 'acme:api',
  name: 'API Gateway',
  lastAnalysisDate: null,
);

ProviderContainer _container(_Repo repo) {
  final c = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [sonarQubeRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('SonarQubeIssuesNotifier (US-SQ-QUALITY-03)', () {
    test('loads page one, then appends the next, then stops', () async {
      final repo = _Repo()..total = 120;
      final c = _container(repo);
      c.listen(sonarQubeIssuesNotifierProvider('k'), (_, _) {});
      var issues = await c.read(sonarQubeIssuesNotifierProvider('k').future);
      expect(issues.issues, hasLength(50));
      expect(issues.total, 120);
      expect(issues.hasMore, isTrue);

      final notifier = c.read(sonarQubeIssuesNotifierProvider('k').notifier);
      await notifier.loadMore();
      await notifier.loadMore();
      await notifier.loadMore(); // at the end: a no-op

      issues = c.read(sonarQubeIssuesNotifierProvider('k')).value!;
      expect(issues.issues, hasLength(120));
      expect(issues.hasMore, isFalse);
      expect(repo.calls.map((c) => c.$2), [1, 2, 3]);
    });

    test(
      'changing the filter re-queries from page one on the server',
      () async {
        final repo = _Repo();
        final c = _container(repo);
        c.listen(sonarQubeIssuesNotifierProvider('k'), (_, _) {});
        await c.read(sonarQubeIssuesNotifierProvider('k').future);

        c
            .read(sonarQubeIssueFilterNotifierProvider('k').notifier)
            .toggleType('BUG');
        final issues = await c.read(
          sonarQubeIssuesNotifierProvider('k').future,
        );

        expect(issues.total, 7);
        expect(issues.issues, hasLength(7));
        expect(repo.calls.last.$1.types, {'BUG'});
        expect(repo.calls.last.$2, 1);
      },
    );

    test('a failed page keeps the list and can be retried', () async {
      final repo = _Repo()..total = 120;
      final c = _container(repo);
      c.listen(sonarQubeIssuesNotifierProvider('k'), (_, _) {});
      await c.read(sonarQubeIssuesNotifierProvider('k').future);
      repo.forcedResult = const Err(NetworkFailure());
      final notifier = c.read(sonarQubeIssuesNotifierProvider('k').notifier);

      await notifier.loadMore();
      var issues = c.read(sonarQubeIssuesNotifierProvider('k')).value!;
      expect(issues.issues, hasLength(50));
      expect(issues.loadMoreFailure, isA<NetworkFailure>());

      repo.forcedResult = null;
      await notifier.loadMore();
      issues = c.read(sonarQubeIssuesNotifierProvider('k')).value!;
      expect(issues.issues, hasLength(100));
      expect(issues.loadMoreFailure, isNull);
    });

    test('paging stops at the 10,000-result limit', () async {
      final repo = _Repo()..total = 25000;
      final c = _container(repo);
      c.listen(sonarQubeIssuesNotifierProvider('k'), (_, _) {});
      await c.read(sonarQubeIssuesNotifierProvider('k').future);
      final notifier = c.read(sonarQubeIssuesNotifierProvider('k').notifier);

      for (var i = 0; i < 250; i++) {
        await notifier.loadMore();
      }

      final issues = c.read(sonarQubeIssuesNotifierProvider('k')).value!;
      expect(issues.issues, hasLength(sonarQubeIssuesMaxResults));
      expect(issues.hasMore, isFalse);
    });
  });

  group('SonarQubeIssuesScreen', () {
    Future<void> pump(WidgetTester tester, _Repo repo) async {
      await tester.pumpWidget(
        ProviderScope(
          retry: (retryCount, error) => null,
          overrides: [sonarQubeRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const SonarQubeIssuesScreen(project: _project),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists issues with type, severity and location', (
      tester,
    ) async {
      await pump(tester, _Repo()..total = 3);

      expect(find.text('3 issues'), findsOneWidget);
      expect(find.text('Issue 0'), findsOneWidget);
      expect(find.text('Major'), findsWidgets);
      expect(find.text('src/F.java:1'), findsOneWidget);
    });

    testWidgets('a filter chip narrows the list and Clear filters undoes it', (
      tester,
    ) async {
      final repo = _Repo()..total = 3;
      await pump(tester, repo);

      await tester.tap(find.widgetWithText(FilterChip, 'Bug'));
      await tester.pumpAndSettle();
      expect(find.text('7 issues'), findsOneWidget);
      expect(repo.calls.last.$1.types, {'BUG'});

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('3 issues'), findsOneWidget);
    });

    testWidgets(
      'a clean project and an over-filtered one say different things',
      (tester) async {
        final repo = _Repo()..total = 0;
        await pump(tester, repo);
        expect(find.text('No issues found'), findsOneWidget);

        repo.bugsTotal = 0;
        await tester.tap(find.widgetWithText(FilterChip, 'Bug'));
        await tester.pumpAndSettle();
        expect(find.text('No issues match these filters'), findsOneWidget);
      },
    );

    testWidgets('a load failure shows the error with retry', (tester) async {
      final repo = _Repo()..forcedResult = const Err(NetworkFailure());
      await pump(tester, repo);
      expect(find.textContaining("Can't reach the server"), findsOneWidget);

      repo.forcedResult = null;
      repo.total = 2;
      await tester.tap(find.text('Retry Connection'));
      await tester.pumpAndSettle();

      expect(find.text('2 issues'), findsOneWidget);
    });
  });
}
