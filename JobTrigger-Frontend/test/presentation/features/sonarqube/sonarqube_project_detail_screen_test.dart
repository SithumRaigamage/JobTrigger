import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_quality_gate.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_project_detail_screen.dart';

class _Repo implements SonarQubeRepository {
  Result<SonarQubeQualityGate, AppFailure> gate = const Ok(
    SonarQubeQualityGate(state: QualityGateState.passed, conditions: []),
  );
  Result<Map<String, String>, AppFailure> measures = const Ok({});
  int gateCalls = 0;
  int measuresCalls = 0;

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
  Future<Result<List<SonarQubeProject>, AppFailure>> fetchProjects() =>
      throw UnimplementedError();
}

const _project = SonarQubeProject(
  key: 'acme:api',
  name: 'API Gateway',
  lastAnalysisDate: null,
);

Future<void> _pump(WidgetTester tester, _Repo repo) async {
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

void main() {
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
    // The passing condition is not listed.
    expect(find.textContaining('New bugs'), findsNothing);
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
