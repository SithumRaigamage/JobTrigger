import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/demo/demo_sonarqube_repository.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_project.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_worst_files.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_worst_files_screen.dart';

class _Repo extends DemoSonarQubeRepository {
  String? lastMetric;
  String? lastComponentKey;

  @override
  Future<Result<SonarQubeWorstFiles, AppFailure>> fetchWorstFiles(
    String projectKey,
    SonarQubeFileMetric metric,
  ) {
    lastMetric = metric.metric;
    return super.fetchWorstFiles(projectKey, metric);
  }

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> fetchFileIssues(
    String componentKey,
  ) async {
    lastComponentKey = componentKey;
    return const Ok(SonarQubeIssuePage(issues: [], total: 0));
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
        home: const SonarQubeWorstFilesScreen(project: _project),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('worst files (US-SQ-QUALITY-12)', () {
    testWidgets('ranks the files with their values, lowest coverage first', (
      tester,
    ) async {
      final repo = _Repo();
      await _pump(tester, repo);

      expect(repo.lastMetric, 'coverage');
      expect(find.text('src/legacy/report.ts'), findsOne);
      expect(find.text('src/config/auth.ts'), findsOne);
      expect(find.text('0%'), findsOne);
      expect(find.text('12.5%'), findsOne);
      expect(find.text('Least covered'), findsOne);
    });

    testWidgets('a different ranking asks for that metric', (tester) async {
      final repo = _Repo();
      await _pump(tester, repo);

      await tester.tap(find.text('Most issues'));
      await tester.pumpAndSettle();

      expect(repo.lastMetric, 'code_smells');
    });

    testWidgets('tapping a file opens its own issues', (tester) async {
      final repo = _Repo();
      await _pump(tester, repo);

      await tester.tap(find.text('src/legacy/report.ts'));
      await tester.pumpAndSettle();

      expect(repo.lastComponentKey, 'acme:api:src/legacy/report.ts');
      expect(find.text('No open issues in this file'), findsOne);
      // The sheet names the file it is showing.
      expect(find.text('src/legacy/report.ts'), findsWidgets);
    });
  });
}
