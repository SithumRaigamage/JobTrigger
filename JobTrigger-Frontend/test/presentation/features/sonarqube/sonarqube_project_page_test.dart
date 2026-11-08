import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/link_launcher.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/credentials/active_sonarqube_credential_notifier.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/credential/sonarqube_credential.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_project_detail_screen.dart';

class _Repo implements SonarQubeRepository {
  @override
  Future<Result<SonarQubeIssueContext, AppFailure>> fetchIssueContext(
    SonarQubeIssue issue,
  ) => throw UnimplementedError();

  Result<SonarQubeQualityGate, AppFailure> gate = const Ok(
    SonarQubeQualityGate(state: QualityGateState.passed, conditions: []),
  );
  Result<Map<String, String>, AppFailure> measures = const Ok({});
  Result<List<SonarQubeAnalysis>, AppFailure> history = const Ok([]);

  @override
  Future<Result<SonarQubeQualityGate, AppFailure>> fetchQualityGate(
    String projectKey,
  ) async => gate;

  @override
  Future<Result<Map<String, String>, AppFailure>> fetchMeasures(
    String projectKey,
  ) async => measures;

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) async => history;

  @override
  Future<Result<SonarQubeProjectsPage, AppFailure>> fetchProjects({
    int page = 1,
    int pageSize = sonarQubeProjectsPageSize,
  }) => throw UnimplementedError();

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) => throw UnimplementedError();

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchIssues(
    String projectKey, {
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) => throw UnimplementedError();
}

class _Credential extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => const SonarQubeCredential(
    id: 'c',
    label: 'Local',
    baseUrl: 'http://192.168.1.53:9000',
    secret: 't',
  );
}

class _NoCredential extends ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() => null;
}

SonarQubeProject _project({DateTime? analysed}) => SonarQubeProject(
  key: 'JobTrigger',
  name: 'JobTrigger',
  lastAnalysisDate: analysed,
);

Future<void> _pump(
  WidgetTester tester,
  _Repo repo, {
  SonarQubeProject? project,
  bool credential = true,
  List<Uri>? opened,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [
        sonarQubeRepositoryProvider.overrideWithValue(repo),
        activeSonarQubeCredentialNotifierProvider.overrideWith(
          credential ? _Credential.new : _NoCredential.new,
        ),
        linkLauncherProvider.overrideWithValue((uri) async {
          opened?.add(uri);
          return true;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: SonarQubeProjectDetailScreen(project: project ?? _project()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ratings and technical debt are shown when computed', (
    tester,
  ) async {
    final repo = _Repo()
      ..measures = const Ok({
        'bugs': '0',
        'reliability_rating': '1.0',
        'security_rating': '1.0',
        'sqale_rating': '3.0',
        'sqale_index': '1560',
      });

    await _pump(tester, repo);

    expect(find.text('Reliability'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Maintainability'), findsOneWidget);
    expect(find.text('A'), findsNWidgets(2));
    expect(find.text('C'), findsOneWidget);
    expect(find.text('3d 2h'), findsOneWidget);
    expect(
      find.text('Technical debt: time to fix every issue'),
      findsOneWidget,
    );
  });

  testWidgets('without them, no empty rating or debt tiles are drawn', (
    tester,
  ) async {
    final repo = _Repo()..measures = const Ok({'bugs': '2'});

    await _pump(tester, repo);

    expect(find.text('Reliability'), findsNothing);
    expect(find.text('Maintainability'), findsNothing);
    expect(find.textContaining('Technical debt'), findsNothing);
  });

  testWidgets('the six measure tiles are equal in size (the old ones were '
      'not)', (tester) async {
    final repo = _Repo()
      ..measures = const Ok({
        'bugs': '3',
        'vulnerabilities': '1',
        'code_smells': '12345',
        'coverage': '71.4',
        'duplicated_lines_density': '3.2',
        'ncloc': '2117',
      });

    await _pump(tester, repo);

    // Each tile's card: its label's nearest card ancestor.
    Size tile(String label) => tester.getSize(
      find
          .ancestor(of: find.text(label), matching: find.byType(Material))
          .first,
    );
    final sizes = [
      for (final label in [
        'Bugs',
        'Vulnerabilities',
        'Code smells',
        'Coverage',
        'Duplication',
        'Lines of code',
      ])
        tile(label),
    ];
    expect(sizes.map((s) => s.width).toSet(), hasLength(1));
    expect(sizes.map((s) => s.height).toSet(), hasLength(1));
  });

  testWidgets('a measure the gate failed on is marked for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repo = _Repo()
      ..gate = const Ok(
        SonarQubeQualityGate(
          state: QualityGateState.failed,
          conditions: [
            QualityGateCondition(
              metricKey: 'coverage',
              comparator: 'LT',
              threshold: '80',
              actual: '62',
              failed: true,
            ),
          ],
        ),
      )
      ..measures = const Ok({'coverage': '62', 'bugs': '0'});

    await _pump(tester, repo);

    expect(
      find.bySemanticsLabel(RegExp('Coverage: 62%, failed the quality gate')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('^Bugs: 0, failed')), findsNothing);
    semantics.dispose();
  });

  testWidgets('the header says when it was last analysed, from the history if '
      'the list had no date', (tester) async {
    final repo = _Repo()
      ..history = Ok([
        SonarQubeAnalysis(
          key: 'a',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          projectVersion: null,
        ),
      ]);

    await _pump(tester, repo);

    expect(find.text('Analyzed 3h ago'), findsOneWidget);
    expect(find.text('Never analyzed'), findsNothing);
  });

  testWidgets('Open in SonarQube opens the project in the browser', (
    tester,
  ) async {
    final opened = <Uri>[];

    await _pump(tester, _Repo(), opened: opened);
    await tester.tap(find.byTooltip('Open in SonarQube'));
    await tester.pump();

    expect(
      opened.single.toString(),
      'http://192.168.1.53:9000/dashboard?id=JobTrigger',
    );
  });

  testWidgets('with no active credential there is nothing to open', (
    tester,
  ) async {
    await _pump(tester, _Repo(), credential: false);

    expect(find.byTooltip('Open in SonarQube'), findsNothing);
  });

  testWidgets('Issues and Analysis history sit together in one Explore card', (
    tester,
  ) async {
    await _pump(tester, _Repo());

    expect(find.text('EXPLORE'), findsOneWidget);
    expect(find.text('Issues'), findsOneWidget);
    expect(find.text('Analysis history'), findsOneWidget);
    // Below the measures, not between the gate and them.
    double top(String t) => tester.getTopLeft(find.text(t)).dy;
    expect(top('MEASURES'), lessThan(top('Issues')));
  });
}
