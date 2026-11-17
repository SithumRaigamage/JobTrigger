import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/sonarqube_repository_impl.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_issue.dart';
import 'package:job_trigger/domain/sonarqube/sonarqube_repository.dart';
import 'package:job_trigger/presentation/features/sonarqube/sonarqube_issue_search_screen.dart';

import '../../../support/sonarqube_insights_defaults.dart';

class _Repo with SonarQubeInsightsDefaults implements SonarQubeRepository {
  final searches = <(String, SonarQubeIssueSearchField)>[];
  List<SonarQubeIssue> found = const [];

  @override
  Future<Result<SonarQubeIssuePage, AppFailure>> searchIssues(
    String term, {
    SonarQubeIssueSearchField field = SonarQubeIssueSearchField.rule,
    SonarQubeIssueFilter filter = const SonarQubeIssueFilter(),
    int page = 1,
  }) async {
    searches.add((term, field));
    return Ok(SonarQubeIssuePage(issues: found, total: found.length));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, _Repo repo) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [sonarQubeRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const SonarQubeIssueSearchScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asks nothing until a term is submitted, then lists matches '
      '(US-SQ-ISSUES-03)', (tester) async {
    final repo = _Repo()
      ..found = const [
        SonarQubeIssue(
          key: 'i1',
          type: 'BUG',
          severity: 'MAJOR',
          message: 'Remove this eval',
          file: 'src/app.js',
          line: 6,
          project: 'jt-sample',
          projectName: 'JT Sample',
        ),
      ];
    await _pump(tester, repo);

    expect(repo.searches, isEmpty);
    expect(find.textContaining('no free-text issue search'), findsOneWidget);

    await tester.tap(find.text('Tag'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'security');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(repo.searches.single, ('security', SonarQubeIssueSearchField.tag));
    expect(find.text('Remove this eval'), findsOneWidget);
    expect(find.textContaining('JT Sample'), findsOneWidget);
  });

  testWidgets('says "No issues match" when nothing comes back', (tester) async {
    final repo = _Repo();
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField), 'java:S0');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('No issues match'), findsOneWidget);
  });
}
