import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_job.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/github/github_repository.dart';
import 'package:job_trigger/domain/github/github_workflow.dart';
import 'package:job_trigger/domain/github/github_workflow_run.dart';
import 'package:job_trigger/presentation/features/github/github_runs_screen.dart';

const _repo = GitHubRepo(
  id: 1,
  name: 'api-gateway',
  owner: 'acme-corp',
  fullName: 'acme-corp/api-gateway',
);
const _workflow = GitHubWorkflow(
  id: 42,
  name: 'CI',
  path: '.github/workflows/ci.yml',
  state: 'active',
);

GitHubWorkflowRun _run(
  int n,
  String status,
  String? conclusion, {
  String title = 'Fix flaky test',
}) => GitHubWorkflowRun(
  id: n,
  runNumber: n,
  title: title,
  event: 'push',
  status: status,
  conclusion: conclusion,
  branch: 'main',
  createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  htmlUrl: '',
);

class _Runs implements GitHubRepository {
  @override
  Future<Result<String, AppFailure>> fetchJobLog(
    String owner,
    String repo,
    int jobId,
  ) => throw UnimplementedError();

  @override
  Future<Result<List<GitHubJob>, AppFailure>> fetchJobs(
    String owner,
    String repo,
    int runId,
  ) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> triggerRun(
    String owner,
    String repo,
    int workflowId, {
    required String ref,
    Map<String, String> inputs = const {},
  }) => throw UnimplementedError();

  @override
  Future<Result<GitHubWorkflowRun, AppFailure>> fetchRun(
    String owner,
    String repo,
    int runId,
  ) => throw UnimplementedError();

  @override
  Future<Result<void, AppFailure>> cancelRun(
    String owner,
    String repo,
    int runId,
  ) => throw UnimplementedError();

  _Runs(this.result);

  Result<List<GitHubWorkflowRun>, AppFailure> result;
  int calls = 0;
  int? lastWorkflowId;

  @override
  Future<Result<List<GitHubWorkflowRun>, AppFailure>> fetchRuns(
    String owner,
    String repo,
    int workflowId, {
    int page = 1,
  }) async {
    calls++;
    lastWorkflowId = workflowId;
    return result;
  }

  @override
  Future<Result<List<GitHubRepo>, AppFailure>> fetchRepos() =>
      throw UnimplementedError();

  @override
  Future<Result<List<GitHubWorkflow>, AppFailure>> fetchWorkflows(
    String owner,
    String repo,
  ) => throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, _Runs fake) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (retryCount, error) => null,
      overrides: [gitHubRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const GitHubRunsScreen(repo: _repo, workflow: _workflow),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows each run with its status and conclusion as one pill', (
    tester,
  ) async {
    final fake = _Runs(
      Ok([
        _run(3, 'in_progress', null, title: 'Add retry'),
        _run(2, 'completed', 'failure', title: 'Break build'),
        _run(1, 'completed', 'success'),
      ]),
    );

    await _pump(tester, fake);

    expect(find.text('acme-corp/api-gateway'), findsOneWidget);
    expect(find.text('CI'), findsOneWidget);
    expect(find.text('RECENT RUNS'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Success'), findsOneWidget);
    expect(find.text('Add retry'), findsOneWidget);
    expect(find.text('#3 · push · main · 2h ago'), findsOneWidget);
    expect(fake.lastWorkflowId, 42);
  });

  testWidgets('a workflow with no runs says so', (tester) async {
    await _pump(tester, _Runs(const Ok([])));

    expect(find.text('No runs yet'), findsOneWidget);
  });

  testWidgets('a failure shows the error with a working retry', (tester) async {
    final fake = _Runs(const Err(RateLimitFailure()));
    await _pump(tester, fake);

    expect(find.textContaining('rate limit'), findsOneWidget);

    fake.result = Ok([_run(1, 'completed', 'success')]);
    await tester.tap(find.text('Retry Connection'));
    await tester.pumpAndSettle();

    expect(find.text('Success'), findsOneWidget);
    expect(fake.calls, 2);
  });
}
