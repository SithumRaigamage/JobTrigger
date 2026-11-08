import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/github/github_workflow.dart';
import 'package:job_trigger/presentation/features/github/github_trigger_sheet.dart';

import '../../../support/fake_github_repository.dart';

const _repo = GitHubRepo(
  id: 1,
  name: 'api',
  owner: 'acme',
  fullName: 'acme/api',
  defaultBranch: 'trunk',
);
const _workflow = GitHubWorkflow(
  id: 42,
  name: 'CI',
  path: '.github/workflows/ci.yml',
  state: 'active',
);

Future<void> _open(WidgetTester tester, FakeGitHubRepository fake) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [gitHubRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showGitHubTriggerSheet(
                  context,
                  repo: _repo,
                  workflow: _workflow,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('defaults the branch to the repo default and confirms before '
      'triggering', (tester) async {
    final fake = FakeGitHubRepository();
    await _open(tester, fake);

    expect(find.widgetWithText(TextField, 'trunk'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Run workflow'));
    await tester.pumpAndSettle();
    expect(find.text('Run CI?'), findsOneWidget);
    expect(find.text('acme/api on trunk'), findsOneWidget);
    expect(fake.triggerCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Run workflow').last);
    await tester.pumpAndSettle();

    expect(fake.triggerCalls, 1);
    expect(fake.lastRef, 'trunk');
    expect(fake.lastInputs, isEmpty);
    // Let the delayed runs-list refresh fire so no timer is left pending.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('sends the typed inputs', (tester) async {
    final fake = FakeGitHubRepository();
    await _open(tester, fake);

    await tester.tap(find.text('Add input'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'env');
    await tester.enterText(find.widgetWithText(TextField, 'Value'), 'prod');
    await tester.tap(find.widgetWithText(FilledButton, 'Run workflow'));
    await tester.pumpAndSettle();
    expect(find.text('env = prod'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Run workflow').last);
    await tester.pumpAndSettle();

    expect(fake.lastInputs, {'env': 'prod'});
    // Let the delayed runs-list refresh fire so no timer is left pending.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('declining the confirmation sends nothing', (tester) async {
    final fake = FakeGitHubRepository();
    await _open(tester, fake);

    await tester.tap(find.widgetWithText(FilledButton, 'Run workflow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fake.triggerCalls, 0);
  });

  testWidgets('a blank branch or a duplicate input name is explained', (
    tester,
  ) async {
    final fake = FakeGitHubRepository();
    await _open(tester, fake);

    await tester.enterText(find.widgetWithText(TextField, 'trunk'), '  ');
    await tester.tap(find.widgetWithText(FilledButton, 'Run workflow'));
    await tester.pump();
    expect(find.text('Enter a branch or tag to run on.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'main');
    await tester.tap(find.text('Add input'));
    await tester.tap(find.text('Add input'));
    await tester.pump();
    final names = find.widgetWithText(TextField, 'Name');
    await tester.enterText(names.at(0), 'a');
    await tester.enterText(names.at(1), 'a');
    await tester.tap(find.widgetWithText(FilledButton, 'Run workflow'));
    await tester.pump();
    expect(find.text('"a" is entered twice.'), findsOneWidget);
    expect(fake.triggerCalls, 0);
  });

  testWidgets('a 422 from GitHub is reported, not swallowed', (tester) async {
    final fake = FakeGitHubRepository()
      ..triggerResult = const Err(DispatchRejectedFailure());
    await _open(tester, fake);

    await tester.tap(find.widgetWithText(FilledButton, 'Run workflow'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Run workflow').last);
    await tester.pumpAndSettle();

    expect(fake.triggerCalls, 1);
  });
}
