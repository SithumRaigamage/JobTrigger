import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project_summary.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_analysis.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_analysis_screen.dart';

class _Repo implements SonarQubeRepository {
  @override
  Future<Result<SonarQubeIssueContext, AppFailure>> fetchIssueContext(
    SonarQubeIssue issue,
  ) => throw UnimplementedError();

  @override
  Future<Result<Map<String, SonarQubeProjectSummary>, AppFailure>>
  fetchProjectSummaries(List<String> projectKeys) => throw UnimplementedError();

  _Repo(this.result);

  Result<List<SonarQubeAnalysis>, AppFailure> result;
  int calls = 0;

  @override
  Future<Result<List<SonarQubeAnalysis>, AppFailure>> fetchAnalysisHistory(
    String projectKey,
  ) async {
    calls++;
    return result;
  }

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

SonarQubeAnalysis _analysis(String key, Duration ago, {String? version}) =>
    SonarQubeAnalysis(
      key: key,
      date: DateTime.now().subtract(ago),
      projectVersion: version,
    );

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [sonarQubeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SonarQubeAnalysisScreen(project: _project),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists analyses with how long ago and the version', (
    tester,
  ) async {
    await _pump(
      tester,
      _Repo(
        Ok([
          _analysis('a2', const Duration(hours: 2), version: '2.1'),
          _analysis('a1', const Duration(days: 3)),
        ]),
      ),
    );

    expect(find.text('Analysis history'), findsOneWidget);
    expect(find.text('2h ago'), findsOneWidget);
    expect(find.text('3d ago'), findsOneWidget);
    expect(find.text('2.1'), findsOneWidget);
    expect(find.textContaining('Not enough history'), findsNothing);
  });

  testWidgets('a single analysis explains there is not enough history', (
    tester,
  ) async {
    await _pump(tester, _Repo(Ok([_analysis('a1', const Duration(hours: 1))])));

    expect(find.text('1h ago'), findsOneWidget);
    expect(find.textContaining('Not enough history yet'), findsOneWidget);
  });

  testWidgets('a never-analysed project says so, not a blank list', (
    tester,
  ) async {
    await _pump(tester, _Repo(const Ok([])));

    expect(
      find.text('This project has not been analyzed yet.'),
      findsOneWidget,
    );
  });

  testWidgets('a failure shows the error with a working retry', (tester) async {
    final repo = _Repo(const Err(NetworkFailure()));
    await _pump(tester, repo);
    expect(find.textContaining("Can't reach the server"), findsOneWidget);

    repo.result = Ok([
      _analysis('a2', const Duration(hours: 1)),
      _analysis('a1', const Duration(hours: 5)),
    ]);
    await tester.tap(find.text('Retry Connection'));
    await tester.pumpAndSettle();

    expect(find.text('1h ago'), findsOneWidget);
    expect(repo.calls, 2);
  });
}
