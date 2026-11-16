import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis_status.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_measure_delta.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_metrics.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_my_issues_screen.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_project_detail_screen.dart';

/// P10-18 (batch 1) — `US-SQ-QUALITY-07/08/09`, `US-SQ-CE-01`,
/// `US-SQ-ISSUES-01`: what the project page says about a gate, a running
/// scan and the last change, and the cross-project list of "my issues".
class _Repo with SonarQubeInsightsDefaults implements SonarQubeRepository {
  Result<SonarQubeQualityGate, AppFailure> gate = const Ok(
    SonarQubeQualityGate(state: QualityGateState.passed, conditions: []),
  );
  Result<Map<String, String>, AppFailure> measures = const Ok({});
  Result<Map<String, String>, AppFailure> newCode = const Ok({});
  Result<List<SonarQubeMeasureDelta>, AppFailure> deltas = const Ok([]);
  Result<SonarQubeAnalysisStatus, AppFailure> status = const Ok(
    SonarQubeAnalysisStatus.none,
  );

  List<SonarQubeIssue> mine = const [];
  SonarQubeIssueFilter? lastFilter;

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) async => gate;

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) async => measures;

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchNewCodeMeasures(
    String projectKey,
  ) async => newCode;

  @override
  Future<Result<List<SonarQubeMeasureDelta>, AppFailure>> fetchMeasureDeltas(
    String projectKey, {
    List<String> metricKeys = sonarQubeMeasureKeys,
  }) async => deltas;

  @override
  Future<Result<SonarQubeAnalysisStatus, AppFailure>> fetchAnalysisStatus(
    String projectKey,
  ) async => status;

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchMyIssues({
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) async {
    lastFilter = filter;
    return Ok(SonarQubeIssuePage(issues: mine, total: mine.length));
  }

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
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
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

Future<void> _pumpDetail(WidgetTester tester, _Repo repo) async {
  tester.view.physicalSize = const Size(800, 2600);
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

Future<void> _pumpMyIssues(WidgetTester tester, _Repo repo) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [sonarQubeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SonarQubeMyIssuesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('every gate condition is listed, failing ones first '
      '(US-SQ-QUALITY-07)', (tester) async {
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
              metricKey: 'bugs',
              comparator: 'GT',
              threshold: '0',
              actual: '0',
              failed: false,
            ),
          ],
        ),
      );

    await _pumpDetail(tester, repo);

    expect(find.text('What failed'), findsOneWidget);
    expect(find.text('All conditions'), findsOneWidget);
    // The passing condition is on the page too, and reads as a pass.
    expect(find.text('Bugs: 0 (fails when above 0)'), findsOneWidget);
    expect(
      find.text('Coverage on new code: 62.1% (fails when below 80%)'),
      findsOneWidget,
    );
  });

  testWidgets('a gate without conditions says so', (tester) async {
    await _pumpDetail(tester, _Repo());
    expect(find.text('This gate has no conditions'), findsOneWidget);
  });

  testWidgets('a running scan says so; a quiet one says nothing '
      '(US-SQ-CE-01)', (tester) async {
    final repo = _Repo()
      ..status = const Ok(
        SonarQubeAnalysisStatus(
          current: SonarQubeCeTask(status: 'IN_PROGRESS'),
        ),
      );
    await _pumpDetail(tester, repo);
    expect(find.text('Analysing…'), findsOneWidget);

    final quiet = _Repo();
    await _pumpDetail(tester, quiet);
    expect(find.text('Analysing…'), findsNothing);
    expect(find.text('Last analysis failed'), findsNothing);
  });

  testWidgets('a failed analysis says when and why (US-SQ-CE-01)', (
    tester,
  ) async {
    final when = DateTime.utc(2026, 11, 12, 14, 2);
    final repo = _Repo()
      ..status = Ok(
        SonarQubeAnalysisStatus(
          current: SonarQubeCeTask(
            status: 'FAILED',
            executedAt: when,
            errorMessage: 'The main branch was not found',
          ),
        ),
      );

    await _pumpDetail(tester, repo);

    // The banner shows the server's time in the phone's zone.
    final local = when.toLocal();
    final stamp =
        '${local.day}/${local.month} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    expect(find.text('Last analysis failed'), findsOneWidget);
    expect(find.text('The main branch was not found ($stamp)'), findsOneWidget);
  });

  testWidgets('the switch shows new-code measures only when the server has '
      'them (US-SQ-QUALITY-08)', (tester) async {
    final repo = _Repo()
      ..measures = const Ok({'bugs': '3'})
      ..newCode = const Ok({'new_bugs': '1'});

    await _pumpDetail(tester, repo);

    expect(find.text('New code'), findsOneWidget);
    expect(find.text('New bugs'), findsNothing);

    await tester.tap(find.text('New code'));
    await tester.pumpAndSettle();

    expect(find.text('New bugs'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('no new-code switch when the server computes none '
      '(US-SQ-QUALITY-08)', (tester) async {
    await _pumpDetail(tester, _Repo());
    expect(find.text('New code'), findsNothing);
  });

  testWidgets('the change since the previous analysis is shown '
      '(US-SQ-QUALITY-09)', (tester) async {
    final repo = _Repo()
      ..deltas = const Ok([
        SonarQubeMeasureDelta(metricKey: 'bugs', previous: 1, current: 3),
      ]);

    await _pumpDetail(tester, repo);

    expect(find.text('Since the previous analysis'), findsOneWidget);
    expect(find.text('Bugs'), findsWidgets);
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('my issues lists the project and file, and filters on the '
      'server (US-SQ-ISSUES-01)', (tester) async {
    final repo = _Repo()
      ..mine = const [
        SonarQubeIssue(
          key: 'i1',
          type: 'BUG',
          severity: 'MAJOR',
          message: 'Handle the rejected promise returned by "save".',
          file: 'src/jobs/sync.ts',
          line: 102,
          project: 'acme:api',
          projectName: 'API Gateway',
        ),
      ];

    await _pumpMyIssues(tester, repo);

    expect(
      find.text('Handle the rejected promise returned by "save".'),
      findsOneWidget,
    );
    expect(find.text('API Gateway · src/jobs/sync.ts:102'), findsOneWidget);
    expect(find.text('1 open issue'), findsOneWidget);

    await tester.tap(find.text('Bug'));
    await tester.pumpAndSettle();

    expect(repo.lastFilter?.types, {'BUG'});
  });

  testWidgets('nothing assigned says exactly that (US-SQ-ISSUES-01)', (
    tester,
  ) async {
    await _pumpMyIssues(tester, _Repo());
    expect(find.text('Nothing is assigned to you'), findsOneWidget);
  });
}
