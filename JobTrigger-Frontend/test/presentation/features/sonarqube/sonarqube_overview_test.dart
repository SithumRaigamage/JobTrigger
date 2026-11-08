import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/credentials/sonarqube_credentials_notifier.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_overview_screen.dart';
import 'package:job_trigger/presentation/navigation/main_scaffold.dart';

class _Repo implements SonarQubeRepository {
  @override
  Future<Result<SonarQubeIssueContext, AppFailure>> fetchIssueContext(
    SonarQubeIssue issue,
  ) => throw UnimplementedError();

  _Repo(this.projects, {this.total});

  final List<SonarQubeProject> projects;
  final int? total;
  final Map<String, SonarQubeProjectSummary> summaries = {};
  Result<Map<String, SonarQubeProjectSummary>, AppFailure>? summaryResult;
  Result<SonarQubeProjectsPage, AppFailure>? projectsResult;

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) async =>
      projectsResult ??
      Ok(
        SonarQubeProjectsPage(
          projects: projects,
          total: total ?? projects.length,
        ),
      );

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) async =>
      summaryResult ??
      Ok({
        for (final k in projectKeys)
          k:
              summaries[k] ??
              const SonarQubeProjectSummary(gate: QualityGateState.none),
      });

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) async => const Ok([]);

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

class _NoActive extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => null;
}

class _NoSaved extends SonarQubeCredentialsNotifier {
  @override
  Future<List<SonarQubeCredential>> build() async => const [];
}

SonarQubeProject _p(String key, String name) =>
    SonarQubeProject(key: key, name: name, lastAnalysisDate: null);

const _failed = SonarQubeProjectSummary(
  gate: QualityGateState.failed,
  bugs: 3,
  vulnerabilities: 1,
  codeSmells: 10,
);
const _passed = SonarQubeProjectSummary(
  gate: QualityGateState.passed,
  bugs: 0,
  vulnerabilities: 0,
  codeSmells: 4,
);

Future<void> _pump(
  WidgetTester tester,
  _Repo repo, {
  bool credential = true,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        activeSonarQubeCredentialNotifierProvider.overrideWith(
          credential ? _Credential.new : _NoActive.new,
        ),
        sonarQubeCredentialsNotifierProvider.overrideWith(_NoSaved.new),
        sonarQubeRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SonarQubeOverviewScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SonarQubeOverviewScreen', () {
    testWidgets('counts verdicts, totals the numbers and lists what needs a '
        'look', (tester) async {
      final repo = _Repo([
        _p('bad', 'Broken'),
        _p('ok', 'Healthy'),
        _p('new', 'Untouched'),
      ]);
      repo.summaries['bad'] = _failed;
      repo.summaries['ok'] = _passed;

      await _pump(tester, repo);

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.text('Failing'), findsOneWidget);
      expect(find.text('Passing'), findsOneWidget);
      expect(find.text('Not analyzed'), findsWidgets);
      // Totals: 3 bugs, 1 vulnerability, 14 smells over 2 analysed projects.
      expect(find.text('Bugs'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('Across 2 analyzed projects'), findsOneWidget);
      expect(find.text('Needs attention'.toUpperCase()), findsOneWidget);
      expect(find.text('Broken'), findsOneWidget);
      // A passing project is not in "needs attention".
      expect(find.text('Healthy'), findsNothing);
      expect(find.text('Not analyzed yet'.toUpperCase()), findsOneWidget);
      expect(find.text('Untouched'), findsOneWidget);
    });

    testWidgets('when everything passes it says so', (tester) async {
      final repo = _Repo([_p('a', 'A'), _p('b', 'B')]);
      repo.summaries['a'] = _passed;
      repo.summaries['b'] = _passed;

      await _pump(tester, repo);

      expect(
        find.text('All 2 analyzed projects pass their quality gate.'),
        findsOneWidget,
      );
      expect(find.text('Needs attention'.toUpperCase()), findsNothing);
    });

    testWidgets('does not claim all is well while verdicts are missing', (
      tester,
    ) async {
      // The summaries call fails: no project has a verdict.
      final repo = _Repo([_p('a', 'A')])
        ..summaryResult = const Err(NetworkFailure());

      await _pump(tester, repo);

      expect(find.textContaining('pass their quality gate'), findsNothing);
      expect(
        find.textContaining("Couldn't load the quality gates"),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);

      repo.summaryResult = null;
      repo.summaries['a'] = _failed;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Couldn't load"), findsNothing);
      expect(find.text('A'), findsOneWidget); // now in "needs attention"
    });

    testWidgets('failed before warning, with the worse project first', (
      tester,
    ) async {
      final repo = _Repo([_p('w', 'Warn'), _p('f1', 'Few'), _p('f2', 'Many')]);
      repo.summaries['w'] = const SonarQubeProjectSummary(
        gate: QualityGateState.warning,
        bugs: 99,
      );
      repo.summaries['f1'] = const SonarQubeProjectSummary(
        gate: QualityGateState.failed,
        bugs: 1,
      );
      repo.summaries['f2'] = const SonarQubeProjectSummary(
        gate: QualityGateState.failed,
        bugs: 7,
      );

      await _pump(tester, repo);

      double top(String name) => tester.getTopLeft(find.text(name)).dy;
      expect(top('Many'), lessThan(top('Few')));
      expect(top('Few'), lessThan(top('Warn')));
    });

    testWidgets('a partial list says what it is based on, and loads more', (
      tester,
    ) async {
      final repo = _Repo([_p('a', 'A')], total: 3);

      await _pump(tester, repo);

      expect(find.text('Based on the first 1 of 3 projects.'), findsOneWidget);
      expect(find.text('Load more'), findsOneWidget);
    });

    testWidgets('no projects, a failed load, and no credential', (
      tester,
    ) async {
      await _pump(tester, _Repo(const []));
      expect(find.text('No projects found'), findsOneWidget);
    });

    testWidgets('a failed project load shows the error with retry', (
      tester,
    ) async {
      final repo = _Repo(const [])
        ..projectsResult = const Err(NetworkFailure());
      await _pump(tester, repo);

      expect(find.textContaining("Can't reach the server"), findsOneWidget);
      expect(find.text('Retry Connection'), findsOneWidget);
    });

    testWidgets('with no credential it asks for one', (tester) async {
      await _pump(tester, _Repo(const []), credential: false);

      expect(find.text('No SonarQube Credential'), findsOneWidget);
    });
  });

  group('the second tab', () {
    GoRouter router({required bool overview}) => GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              MainScaffold(navigationShell: shell, overviewTab: overview),
          branches: [
            for (final path in ['/a', '/b', '/c', '/d'])
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: path,
                    builder: (_, _) => const Scaffold(body: Text('page')),
                  ),
                ],
              ),
          ],
        ),
      ],
    );

    Future<void> pumpBar(WidgetTester tester, bool overview) =>
        tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(routerConfig: router(overview: overview)),
          ),
        );

    testWidgets('is History by default, as for Jenkins and GitHub', (
      tester,
    ) async {
      await pumpBar(tester, false);

      for (final label in ['Home', 'History', 'Settings', 'Profile']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Overview'), findsNothing);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });

    testWidgets('is Overview for SonarQube, the other three unchanged', (
      tester,
    ) async {
      await pumpBar(tester, true);

      for (final label in ['Home', 'Overview', 'Settings', 'Profile']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('History'), findsNothing);
      expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsNothing);
    });
  });
}
