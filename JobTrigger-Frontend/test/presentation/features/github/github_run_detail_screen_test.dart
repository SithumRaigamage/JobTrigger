import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_job.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/github/github_workflow.dart';
import 'package:job_trigger/presentation/features/github/github_run_detail_screen.dart';

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

Future<void> _pump(WidgetTester tester, FakeGitHubRepository fake) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [gitHubRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: GitHubRunDetailScreen(
          repo: _repo,
          workflow: _workflow,
          run: testRun(7, status: 'in_progress', conclusion: null),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// `pumpAndSettle` never returns here: an active run shows a spinner that
/// animates forever. A fixed pump is enough for a dialog to open or close.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('shows each job as a group with its steps', (tester) async {
    final semantics = tester.ensureSemantics();
    final fake = FakeGitHubRepository()
      ..runResult = Ok(testRun(7, status: 'in_progress', conclusion: null))
      ..jobsResult = const Ok([
        GitHubJob(
          id: 1,
          name: 'build (ubuntu)',
          status: 'in_progress',
          conclusion: null,
          steps: [
            GitHubStep(
              number: 1,
              name: 'Checkout',
              status: 'completed',
              conclusion: 'success',
            ),
            GitHubStep(
              number: 2,
              name: 'Test',
              status: 'in_progress',
              conclusion: null,
            ),
          ],
        ),
        GitHubJob(
          id: 2,
          name: 'lint',
          status: 'completed',
          conclusion: 'failure',
          steps: [],
        ),
      ]);

    await _pump(tester, fake);

    expect(find.text('build (ubuntu)'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Step Checkout, Success')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Step Test, In progress')), findsOneWidget);
    expect(find.text('lint'), findsOneWidget);
    expect(find.text('No steps reported.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    semantics.dispose();
  });

  testWidgets('a run with no jobs yet says so', (tester) async {
    final fake = FakeGitHubRepository()
      ..runResult = Ok(testRun(7, status: 'queued', conclusion: null));

    await _pump(tester, fake);

    expect(find.textContaining('No jobs yet'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an active run shows live status and a Cancel run action', (
    tester,
  ) async {
    final fake = FakeGitHubRepository()
      ..runResult = Ok(testRun(7, status: 'in_progress', conclusion: null));

    await _pump(tester, fake);

    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Cancel run'), findsOneWidget);
    // Unmount so the poll timer is cancelled before the pending-timer check.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('cancel asks first, then shows Cancelling… until the poll '
      'reports the real conclusion', (tester) async {
    final fake = FakeGitHubRepository()
      ..runResult = Ok(testRun(7, status: 'in_progress', conclusion: null));
    await _pump(tester, fake);

    await tester.tap(find.text('Cancel run'));
    await _settle(tester);
    expect(find.text('Cancel run #7?'), findsOneWidget);
    expect(fake.cancelCalls, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Cancel run'));
    await tester.pump();
    await tester.pump();

    expect(fake.cancelCalls, 1);
    expect(find.text('Cancelling…'), findsWidgets);
    // Cancel is no longer offered a second time while it is in flight.
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Cancelling…'),
          )
          .onPressed,
      isNull,
    );

    // The poll sees GitHub's real result and the transitional state ends.
    fake.runResult = Ok(
      testRun(7, status: 'completed', conclusion: 'cancelled'),
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Cancelling…'), findsNothing);
    expect(find.text('Cancel run'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('keeping the run running sends no cancel', (tester) async {
    final fake = FakeGitHubRepository()
      ..runResult = Ok(testRun(7, status: 'in_progress', conclusion: null));
    await _pump(tester, fake);

    await tester.tap(find.text('Cancel run'));
    await _settle(tester);
    await tester.tap(find.text('Keep running'));
    await _settle(tester);

    expect(fake.cancelCalls, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a rate limit mid-poll keeps the last state and says why', (
    tester,
  ) async {
    final fake = FakeGitHubRepository()
      ..runResult = Ok(testRun(7, status: 'in_progress', conclusion: null));
    await _pump(tester, fake);

    fake.runResult = const Err(RateLimitFailure());
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    expect(find.textContaining('rate limit'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    final calls = fake.fetchRunCalls;
    await tester.pump(const Duration(seconds: 30));
    expect(fake.fetchRunCalls, calls);
    await tester.pumpWidget(const SizedBox());
  });
}
