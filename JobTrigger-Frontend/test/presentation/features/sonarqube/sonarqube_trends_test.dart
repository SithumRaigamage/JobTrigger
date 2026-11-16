import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/demo/demo_sonarqube_repository.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_measure_history.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_trends_screen.dart';

/// The demo's history, or none, to exercise the honest empty state.
class _Repo extends DemoSonarQubeRepository {
  _Repo({this.empty = false});

  final bool empty;

  @override
  Future<Result<SonarQubeMeasureHistory, AppFailure>> fetchMeasureHistory(
    String projectKey,
    String metric,
  ) async {
    final history = await super.fetchMeasureHistory(projectKey, metric);
    if (!empty) return history;
    return Ok(SonarQubeMeasureHistory(metric: metric, points: const []));
  }
}

const _project = SonarQubeProject(
  key: 'acme:api',
  name: 'API Gateway',
  lastAnalysisDate: null,
);

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sonarQubeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SonarQubeTrendsScreen(project: _project),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('trends (US-SQ-QUALITY-11)', () {
    testWidgets('draws the history and reads out the latest point', (
      tester,
    ) async {
      await _pump(tester, _Repo());

      expect(find.text('Coverage'), findsOne);
      expect(find.text('Bugs'), findsOne);
      expect(find.byKey(const ValueKey('trend-readout')), findsOne);
      expect(find.text('15/11 · 77.8%'), findsOne);
      expect(find.textContaining('Lowest 69.2%'), findsOne);
    });

    testWidgets('says so when there is too little history', (tester) async {
      await _pump(tester, _Repo(empty: true));

      expect(find.text('Not enough history yet'), findsOne);
      expect(find.byKey(const ValueKey('trend-readout')), findsNothing);
    });

    testWidgets('a different measure re-queries the server', (tester) async {
      final repo = _Repo();
      await _pump(tester, repo);

      await tester.tap(find.text('Code smells'));
      await tester.pumpAndSettle();

      expect(find.text('15/11 · 77.8'), findsOne);
    });
  });
}
