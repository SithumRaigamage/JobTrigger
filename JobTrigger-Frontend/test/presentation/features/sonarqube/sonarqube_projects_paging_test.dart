import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_project_screen.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_projects_notifier.dart';

/// Serves projects `p0…p(total-1)` in pages of [size], so paging can be
/// followed request by request.
class _Repo implements SonarQubeRepository {
  /// What the headline-numbers call answers, by project key; a key with no
  /// entry gets none (its card shows no numbers).
  final Map<String, SonarQubeProjectSummary> summaries = {};
  int summaryCalls = 0;

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) async {
    summaryCalls++;
    return Ok({
      for (final key in projectKeys)
        if (summaries.containsKey(key)) key: summaries[key]!,
    });
  }

  _Repo({this.total = 5});

  int total;
  static const size = 2;
  final List<int> pages = [];
  Result<SonarQubeProjectsPage, AppFailure>? forced;

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) async {
    pages.add(page);
    if (forced != null) return forced!;
    final start = (page - 1) * size;
    final end = (start + size).clamp(0, total);
    return Ok(
      SonarQubeProjectsPage(
        total: total,
        projects: [
          for (var i = start; i < end; i++)
            SonarQubeProject(
              key: 'p$i',
              name: 'Project $i',
              lastAnalysisDate: null,
            ),
        ],
      ),
    );
  }

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) => throw UnimplementedError();
}

ProviderContainer _container(_Repo repo) {
  final c = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [sonarQubeRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  c.listen(sonarQubeProjectsNotifierProvider, (_, _) {});
  return c;
}

class _Credential extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => const SonarQubeCredential(
    id: 'c',
    label: 'Local',
    baseUrl: 'http://sonar.test',
    secret: 't',
  );
}

void main() {
  group('SonarQubeProjectsNotifier paging (C)', () {
    test('loads page one and knows more exist', () async {
      final repo = _Repo();
      final c = _container(repo);

      final state = await c.read(sonarQubeProjectsNotifierProvider.future);

      expect(state.projects.map((p) => p.key), ['p0', 'p1']);
      expect(state.total, 5);
      expect(state.hasMore, isTrue);
    });

    test('loadMore appends each page until everything is loaded', () async {
      final repo = _Repo();
      final c = _container(repo);
      await c.read(sonarQubeProjectsNotifierProvider.future);
      final notifier = c.read(sonarQubeProjectsNotifierProvider.notifier);

      await notifier.loadMore();
      await notifier.loadMore();
      await notifier.loadMore(); // already complete: a no-op

      final state = c.read(sonarQubeProjectsNotifierProvider).value!;
      expect(state.projects, hasLength(5));
      expect(state.hasMore, isFalse);
      expect(repo.pages, [1, 2, 3]);
    });

    test('a project that moved between pages is not shown twice', () async {
      final repo = _Repo(total: 4);
      final c = _container(repo);
      await c.read(sonarQubeProjectsNotifierProvider.future);
      // The server's second page repeats p1, then adds p2.
      repo.forced = const Ok(
        SonarQubeProjectsPage(
          total: 4,
          projects: [
            SonarQubeProject(
              key: 'p1',
              name: 'Project 1',
              lastAnalysisDate: null,
            ),
            SonarQubeProject(
              key: 'p2',
              name: 'Project 2',
              lastAnalysisDate: null,
            ),
          ],
        ),
      );

      await c.read(sonarQubeProjectsNotifierProvider.notifier).loadMore();

      final keys = c
          .read(sonarQubeProjectsNotifierProvider)
          .value!
          .projects
          .map((p) => p.key);
      expect(keys, ['p0', 'p1', 'p2']);
    });

    test('a page that adds nothing ends paging instead of looping', () async {
      final repo = _Repo(total: 9);
      final c = _container(repo);
      await c.read(sonarQubeProjectsNotifierProvider.future);
      repo.forced = const Ok(SonarQubeProjectsPage(total: 9, projects: []));
      final notifier = c.read(sonarQubeProjectsNotifierProvider.notifier);

      await notifier.loadMore();
      await notifier.loadMore();

      final state = c.read(sonarQubeProjectsNotifierProvider).value!;
      expect(state.hasMore, isFalse);
      expect(repo.pages, [1, 2]);
    });

    test('a failed page keeps the list and can be retried', () async {
      final repo = _Repo();
      final c = _container(repo);
      await c.read(sonarQubeProjectsNotifierProvider.future);
      repo.forced = const Err(NetworkFailure());
      final notifier = c.read(sonarQubeProjectsNotifierProvider.notifier);

      await notifier.loadMore();
      var state = c.read(sonarQubeProjectsNotifierProvider).value!;
      expect(state.projects, hasLength(2));
      expect(state.loadMoreFailure, isA<NetworkFailure>());
      expect(state.hasMore, isTrue);

      repo.forced = null;
      await notifier.loadMore();
      state = c.read(sonarQubeProjectsNotifierProvider).value!;
      expect(state.projects, hasLength(4));
      expect(state.loadMoreFailure, isNull);
    });
  });

  group('SonarQubeProjectScreen paging (C)', () {
    Future<_Repo> pump(WidgetTester tester, {int total = 5}) async {
      final repo = _Repo(total: total);
      await tester.pumpWidget(
        ProviderScope(
          retry: (retryCount, error) => null,
          overrides: [
            activeSonarQubeCredentialNotifierProvider.overrideWith(
              _Credential.new,
            ),
            sonarQubeRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const SonarQubeProjectScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('a partial list says so and Load more fetches the rest', (
      tester,
    ) async {
      final repo = await pump(tester);

      expect(find.text('Showing 2 of 5 projects'), findsOneWidget);
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();

      expect(repo.pages, contains(2));
      expect(find.text('Project 2'), findsOneWidget);
    });

    testWidgets('a complete list shows no count and no button', (tester) async {
      await pump(tester, total: 2);

      expect(find.textContaining('Showing'), findsNothing);
      expect(find.text('Load more'), findsNothing);
    });

    testWidgets('searching a partial list says the search is partial', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byType(TextField), 'Project 1');
      await tester.pump();

      expect(
        find.text('Showing 2 of 5 projects. Search covers only these.'),
        findsOneWidget,
      );
    });

    testWidgets('no match among the loaded ones offers to load more', (
      tester,
    ) async {
      final repo = await pump(tester);

      await tester.enterText(find.byType(TextField), 'Project 4');
      await tester.pump();
      expect(find.text('No results for "Project 4"'), findsOneWidget);
      expect(find.text('Only 2 of 5 projects are loaded.'), findsOneWidget);

      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();

      expect(repo.pages, containsAllInOrder([1, 2, 3]));
      // The search box also holds "Project 4", so look for the tile's key.
      expect(find.text('p4'), findsOneWidget);
    });
  });
}
