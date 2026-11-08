import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_job.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/presentation/features/github/github_job_log_screen.dart';

import '../../../support/fake_github_repository.dart';

const _repo = GitHubRepo(
  id: 1,
  name: 'api',
  owner: 'acme',
  fullName: 'acme/api',
);

GitHubJob _job(String status, [String? conclusion]) => GitHubJob(
  id: 3,
  name: 'build',
  status: status,
  conclusion: conclusion,
  steps: const [],
);

Future<void> _pump(
  WidgetTester tester,
  FakeGitHubRepository fake,
  GitHubJob job,
) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [gitHubRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: GitHubJobLogScreen(repo: _repo, runId: 7, job: job),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a completed job shows its log', (tester) async {
    final fake = FakeGitHubRepository()
      ..jobsResult = Ok([_job('completed', 'success')])
      ..logResult = const Ok('Run tests\nAll 12 passed\n');

    await _pump(tester, fake, _job('completed', 'success'));

    expect(find.text('build'), findsOneWidget);
    expect(find.text('Run tests', findRichText: true), findsOneWidget);
    expect(find.text('All 12 passed', findRichText: true), findsOneWidget);
    expect(fake.fetchJobLogCalls, 1);
  });

  testWidgets('a running job never fetches a log; Check now refreshes the '
      'job and switches to the log once it completes', (tester) async {
    final fake = FakeGitHubRepository()
      ..jobsResult = Ok([_job('in_progress')])
      ..logResult = const Ok('done\n');

    await _pump(tester, fake, _job('in_progress'));

    expect(
      find.textContaining('available once this job finishes'),
      findsOneWidget,
    );
    expect(fake.fetchJobLogCalls, 0);

    fake.jobsResult = Ok([_job('completed', 'success')]);
    await tester.tap(find.text('Check now'));
    await tester.pumpAndSettle();

    expect(find.text('done', findRichText: true), findsOneWidget);
    expect(fake.fetchJobLogCalls, 1);
  });

  testWidgets('a fetch failure shows the error with a working retry', (
    tester,
  ) async {
    final fake = FakeGitHubRepository()
      ..jobsResult = Ok([_job('completed', 'failure')])
      ..logResult = const Err(NotFoundFailure());

    await _pump(tester, fake, _job('completed', 'failure'));
    expect(find.textContaining('removed'), findsOneWidget);

    fake.logResult = const Ok('recovered\n');
    await tester.tap(find.text('Retry Connection'));
    await tester.pumpAndSettle();

    expect(find.text('recovered', findRichText: true), findsOneWidget);
  });

  testWidgets('copy puts the whole log on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final fake = FakeGitHubRepository()
      ..jobsResult = Ok([_job('completed', 'success')])
      ..logResult = const Ok('a\nb\nc');

    await _pump(tester, fake, _job('completed', 'success'));
    await tester.tap(find.byTooltip('Copy log'));
    await tester.pump();

    expect(copied, 'a\nb\nc');
  });

  testWidgets('copy and share are disabled until a log has loaded', (
    tester,
  ) async {
    final fake = FakeGitHubRepository()..jobsResult = Ok([_job('queued')]);

    await _pump(tester, fake, _job('queued'));

    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.copy_rounded),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.ios_share_rounded),
          )
          .onPressed,
      isNull,
    );
  });
}
