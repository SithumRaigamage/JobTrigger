import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
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
    int workflowId,
  ) async {
    fetchRunsCalls++;
    return runsResult;
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
  Future<Result<List<GitHubRepo>, AppFailure>> fetchRepos() =>
      throw UnimplementedError();

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
}) => GitHubWorkflowRun(
  id: id,
  runNumber: id,
  title: 'run $id',
  event: 'push',
  status: status,
  conclusion: conclusion,
  branch: 'main',
  createdAt: null,
  htmlUrl: '',
);
