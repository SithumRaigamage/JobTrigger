import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/domain/github/github_job.dart';
import 'package:job_trigger/domain/github/github_repo.dart';
import 'package:job_trigger/domain/github/github_repository.dart';
import 'package:job_trigger/domain/github/github_workflow.dart';
import 'package:job_trigger/domain/github/github_workflow_run.dart';

/// A configurable [GitHubRepository] for the GH-RUN notifier and screen
/// tests: set a result, call the code under test, read the recorded calls.
class FakeGitHubRepository implements GitHubRepository {
  Result<List<GitHubWorkflowRun>, AppFailure> runsResult = const Ok([]);
  Result<GitHubWorkflowRun, AppFailure>? runResult;
  Result<void, AppFailure> triggerResult = const Ok(null);
  Result<void, AppFailure> cancelResult = const Ok(null);
  Result<List<GitHubJob>, AppFailure> jobsResult = const Ok([]);
  Result<String, AppFailure> logResult = const Ok('');
  int fetchJobsCalls = 0;
  int fetchJobLogCalls = 0;

  /// For the cross-repo feed: the repo list, and runs keyed by repo name.
  Result<List<GitHubRepo>, AppFailure>? reposResult;
  final Map<String, Result<List<GitHubWorkflowRun>, AppFailure>> repoRuns = {};
  final List<String> repoRunsRequested = [];

  /// Per-page overrides for [runsResult] (1-based), for paging tests.
  final Map<int, Result<List<GitHubWorkflowRun>, AppFailure>> runsPages = {};
  final List<int> requestedPages = [];
  int fetchRunsCalls = 0;
  int fetchRunCalls = 0;
  int triggerCalls = 0;
  int cancelCalls = 0;
  String? lastRef;
  Map<String, String>? lastInputs;

  @override
  Future<Result<List<GitHubWorkflowRun>, AppFailure>> fetchRuns(
    String owner,
    String repo,
    int workflowId, {
    int page = 1,
  }) async {
    fetchRunsCalls++;
    requestedPages.add(page);
    return runsPages[page] ?? runsResult;
  }

  @override
  Future<Result<GitHubWorkflowRun, AppFailure>> fetchRun(
    String owner,
    String repo,
    int runId,
  ) async {
    fetchRunCalls++;
    return runResult!;
  }

  @override
  Future<Result<void, AppFailure>> triggerRun(
    String owner,
    String repo,
    int workflowId, {
    required String ref,
    Map<String, String> inputs = const {},
  }) async {
    triggerCalls++;
    lastRef = ref;
    lastInputs = inputs;
    return triggerResult;
  }

  @override
  Future<Result<void, AppFailure>> cancelRun(
    String owner,
    String repo,
    int runId,
  ) async {
    cancelCalls++;
    return cancelResult;
  }

  @override
  Future<Result<List<GitHubJob>, AppFailure>> fetchJobs(
    String owner,
    String repo,
    int runId,
  ) async {
    fetchJobsCalls++;
    return jobsResult;
  }

  @override
  Future<Result<String, AppFailure>> fetchJobLog(
    String owner,
    String repo,
    int jobId,
  ) async {
    fetchJobLogCalls++;
    return logResult;
  }

  @override
  Future<Result<List<GitHubRepo>, AppFailure>> fetchRepos() async =>
      reposResult ?? (throw UnimplementedError());

  @override
  Future<Result<List<GitHubWorkflowRun>, AppFailure>> fetchRepoRuns(
    String owner,
    String repo, {
    int limit = 5,
  }) async {
    repoRunsRequested.add(repo);
    return repoRuns[repo] ?? const Ok([]);
  }

  @override
  Future<Result<List<GitHubWorkflow>, AppFailure>> fetchWorkflows(
    String owner,
    String repo,
  ) => throw UnimplementedError();
}

GitHubWorkflowRun testRun(
  int id, {
  String status = 'completed',
  String? conclusion = 'success',
  DateTime? createdAt,
}) => GitHubWorkflowRun(
  id: id,
  runNumber: id,
  title: 'run $id',
  event: 'push',
  status: status,
  conclusion: conclusion,
  branch: 'main',
  createdAt: createdAt,
  htmlUrl: '',
  workflowId: 42,
  workflowName: 'CI',
);
