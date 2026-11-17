import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/data/datasources/sonarqube_client_factory.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_branch_ref.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue_grouping.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_project_detail_screen.dart';
import '../../../support/sonarqube_insights_defaults.dart';

class _Repo with SonarQubeInsightsDefaults implements SonarQubeRepository {
  @override
  Future<Result<SonarQubeIssueContext, AppFailure>> fetchIssueContext(
    SonarQubeIssue issue,
  ) => throw UnimplementedError();

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) => throw UnimplementedError();

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) => throw UnimplementedError();

  Result<SonarQubeQualityGate, AppFailure> gate = const Ok(
    SonarQubeQualityGate(state: QualityGateState.passed, conditions: []),
  );
  Result<Map<String, String>, AppFailure> measures = const Ok({});
  int gateCalls = 0;
  int measuresCalls = 0;
  Result<SonarQubeRefChoices, AppFailure> refs = const Ok(
    SonarQubeRefChoices.none,
  );

  @override
  Future<Result<SonarQubeRefChoices, AppFailure>> fetchProjectRefs(
    String projectKey,
  ) async => refs;

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) async {
    gateCalls++;
    return gate;
  }

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) async {
    measuresCalls++;
    return measures;
  }

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
    SonarQubeIssueGrouping grouping = SonarQubeIssueGrouping.none,
  }) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) => throw UnimplementedError();
}

const _project = SonarQubeProject(
  key: 'acme:api',
  name: 'API Gateway',
  lastAnalysisDate: null,
);

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  // Tall enough for the whole page: a lazy list only builds what's on
  // screen, and the measures sit below the gate and the navigation rows.
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [sonarQubeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SonarQubeProjectDetailScreen(project: _project),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// A fresh repository per build, as the real client is: Riverpod only
/// rebuilds dependents when the value changes identity, and a new instance is
/// what makes the gate refetch after a branch switch.
class _RepoPerBuild
    with SonarQubeInsightsDefaults
    implements SonarQubeRepository {
  _RepoPerBuild(this._inner);

  final _Repo _inner;

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) => _inner.fetchQualityGate(projectKey);

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) => _inner.fetchMeasures(projectKey);

  @override
  Future<Result<SonarQubeRefChoices, AppFailure>> fetchProjectRefs(
    String projectKey,
  ) => _inner.fetchProjectRefs(projectKey);

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
    SonarQubeIssueGrouping grouping = SonarQubeIssueGrouping.none,
  }) => throw UnimplementedError();

  // Not the page's business; the mixin's defaults cover the rest.
  @override
  Future<Result<SonarQubeIssueContext, AppFailure>> fetchIssueContext(
    SonarQubeIssue issue,
  ) => throw UnimplementedError();

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) => throw UnimplementedError();

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) => throw UnimplementedError();
}

Future<void> _pumpTrackingRefs(WidgetTester tester, _Repo repo) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        // Watches the selections like the real client does, so choosing a ref
        // rebuilds the repository and the gate notifier refetches.
        sonarQubeRepositoryProvider.overrideWith((ref) {
          ref.watch(sonarQubeBranchSelectionsNotifierProvider);
          return _RepoPerBuild(repo);
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SonarQubeProjectDetailScreen(project: _project),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('branch picker (US-SQ-QUALITY-10)', () {
    testWidgets('is hidden when the server only has main', (tester) async {
      await _pumpTrackingRefs(tester, _Repo());

      expect(find.byIcon(Icons.call_split_rounded), findsNothing);
      expect(find.text('Main branch'), findsNothing);
    });

    testWidgets('shows the choices when the server has them', (tester) async {
      final repo = _Repo()
        ..refs = Ok(
          parseSonarQubeRefs(
            branches: {
              'branches': [
                {'name': 'main', 'isMain': true},
                {'name': 'release/2.0', 'isMain': false},
              ],
            },
            pullRequests: {
              'pullRequests': [
                {'key': '42', 'title': 'Add login'},
              ],
            },
          ),
        );

      await _pumpTrackingRefs(tester, repo);

      expect(find.byIcon(Icons.call_split_rounded), findsOneWidget);
      expect(find.text('Main branch'), findsOneWidget);

      await tester.tap(find.text('Main branch'));
      await tester.pumpAndSettle();

      expect(find.text('release/2.0'), findsOneWidget);
      expect(find.text('PR 42'), findsOneWidget);
    });

    testWidgets('choosing one re-queries the gate', (tester) async {
      final repo = _Repo()
        ..refs = Ok(
          parseSonarQubeRefs(
            branches: {
              'branches': [
                {'name': 'main', 'isMain': true},
                {'name': 'release/2.0', 'isMain': false},
              ],
            },
          ),
        );

      await _pumpTrackingRefs(tester, repo);
      final before = repo.gateCalls;

      await tester.tap(find.text('Main branch'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('release/2.0'));
      await tester.pumpAndSettle();

      expect(repo.gateCalls, greaterThan(before));
      // The picker now names the chosen ref.
      expect(find.text('release/2.0'), findsOneWidget);
    });

    test('another project keeps its own ref', () {
      final repo = _Repo();
      final container = ProviderContainer(
        overrides: [sonarQubeRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      container
          .read(sonarQubeBranchSelectionsNotifierProvider.notifier)
          .set('acme:api', const SonarQubeBranchRef.pullRequest('42'));

      expect(
        container.read(sonarQubeBranchSelectionsNotifierProvider)['acme:api'],
        const SonarQubeBranchRef.pullRequest('42'),
      );
      expect(
        container.read(sonarQubeBranchSelectionsNotifierProvider)['acme:web'],
        isNull,
      );
    });
  });

  testWidgets('a passing gate and its measures, with a dash for a metric the '
      'server did not compute', (tester) async {
    final repo = _Repo()
      ..measures = const Ok({
        'coverage': '71.46',
        'bugs': '3',
        'ncloc': '12345',
        // vulnerabilities, code_smells and duplication not computed
      });

    await _pump(tester, repo);

    expect(find.text('API Gateway'), findsOneWidget);
    expect(find.text('acme:api'), findsOneWidget);
    expect(find.text('Passed'), findsOneWidget);
    expect(find.text('71.5%'), findsOneWidget);
    expect(find.text('12,345'), findsOneWidget);
    expect(find.text('Coverage'), findsOneWidget);
    expect(find.text('Lines of code'), findsOneWidget);
    // Three uncomputed metrics show a dash, not a zero.
    expect(find.text('—'), findsNWidgets(3));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('a failing gate says what failed and why', (tester) async {
    final repo = _Repo()
      ..gate = const Ok(
        SonarQubeQualityGate(
          state: QualityGateState.failed,
          conditions: [
            QualityGateCondition(
              metricKey: 'new_coverage',
              comparator: 'LT',
              threshold: '80',
              actual: '62.1',
              failed: true,
            ),
            QualityGateCondition(
              metricKey: 'new_bugs',
              comparator: 'GT',
              threshold: '0',
              actual: '0',
              failed: false,
            ),
          ],
        ),
      );

    await _pump(tester, repo);

    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('What failed'), findsOneWidget);
    expect(find.text('Coverage on new code: 62.1%'), findsOneWidget);
    expect(find.text('Fails when below 80%'), findsOneWidget);
    // P10-18 (US-SQ-QUALITY-07): the passing condition stays out of "What
    // failed" but is now listed under "All conditions", which is the point
    // of that story — a pass one bug from failing is visible.
    expect(find.text('All conditions'), findsOneWidget);
    expect(find.textContaining('New bugs'), findsOneWidget);
    expect(find.text('New bugs: 0 (fails when above 0)'), findsOneWidget);
  });

  testWidgets('a project never analysed says so instead of passing', (
    tester,
  ) async {
    final repo = _Repo()
      ..gate = const Ok(
        SonarQubeQualityGate(state: QualityGateState.none, conditions: []),
      );

    await _pump(tester, repo);

    expect(find.text('Not yet analyzed'), findsOneWidget);
    expect(find.text('Passed'), findsNothing);
  });

  testWidgets('a measures failure does not hide the gate, and retries alone', (
    tester,
  ) async {
    final repo = _Repo()..measures = const Err(NetworkFailure());

    await _pump(tester, repo);

    expect(find.text('Passed'), findsOneWidget);
    expect(find.textContaining("Can't reach the server"), findsOneWidget);

    repo.measures = const Ok({'bugs': '2'});
    await tester.tap(find.text('Retry Connection'));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(repo.measuresCalls, 2);
    expect(repo.gateCalls, 1);
  });

  testWidgets('a gate failure shows its error with retry', (tester) async {
    final repo = _Repo()..gate = const Err(AuthFailure());

    await _pump(tester, repo);

    expect(find.textContaining('credentials were rejected'), findsOneWidget);
  });
}
