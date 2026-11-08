import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/github_repository_impl.dart';
import 'package:job_trigger/domain/github/github_job.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/github/github_repository.dart';
import 'package:job_trigger/domain/github/github_workflow.dart';
import 'package:job_trigger/domain/github/github_workflow_run.dart';
import 'package:job_trigger/presentation/features/github/github_runs_notifier.dart';

class _Fake implements GitHubRepository {
  @override
  Future<Result<List<GitHubWorkflowRun>, AppFailure>> fetchRepoRuns(
    String owner,
    String repo, {
    int limit = 5,
  }) => throw UnimplementedError();

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

  Result<List<GitHubWorkflowRun>, AppFailure> result = const Ok([]);
  int calls = 0;
  (String, String, int)? last;

  @override
  Future<Result<List<GitHubWorkflowRun>, AppFailure>> fetchRuns(
    String owner,
    String repo,
    int workflowId, {
    int page = 1,
  }) async {
    calls++;
    last = (owner, repo, workflowId);
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

GitHubWorkflowRun _run(int n) => GitHubWorkflowRun(
  id: n,
  runNumber: n,
  title: 'run $n',
  event: 'push',
  status: 'completed',
  conclusion: 'success',
  branch: 'main',
  createdAt: null,
  htmlUrl: '',
);

ProviderContainer _container(_Fake fake) {
  final c = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [gitHubRepositoryProvider.overrideWithValue(fake)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('loads the runs for the given owner/repo/workflow', () async {
    final fake = _Fake()..result = Ok([_run(2), _run(1)]);
    final c = _container(fake);

    final runs = await c.read(gitHubRunsNotifierProvider('o', 'r', 7).future);

    expect(runs.map((r) => r.runNumber), [2, 1]);
    expect(fake.last, ('o', 'r', 7));
  });

  test('a failure surfaces as an AsyncError with the AppFailure', () async {
    final fake = _Fake()..result = const Err(RateLimitFailure());
    final c = _container(fake);
    c.listen(gitHubRunsNotifierProvider('o', 'r', 7), (_, _) {});

    await expectLater(
      c.read(gitHubRunsNotifierProvider('o', 'r', 7).future),
      throwsA(isA<RateLimitFailure>()),
    );
  });

  test('refresh() re-fetches', () async {
    final fake = _Fake()..result = Ok([_run(1)]);
    final c = _container(fake);
    c.listen(gitHubRunsNotifierProvider('o', 'r', 7), (_, _) {});
    await c.read(gitHubRunsNotifierProvider('o', 'r', 7).future);

    fake.result = Ok([_run(2), _run(1)]);
    await c.read(gitHubRunsNotifierProvider('o', 'r', 7).notifier).refresh();
    final runs = await c.read(gitHubRunsNotifierProvider('o', 'r', 7).future);

    expect(fake.calls, 2);
    expect(runs, hasLength(2));
  });
}
