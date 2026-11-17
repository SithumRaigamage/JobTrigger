import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../domain/github/github_job.dart';
import '../../domain/github/github_repo.dart';
import '../../domain/github/github_repository.dart';
import '../../domain/github/github_workflow.dart';
import '../../domain/github/github_workflow_run.dart';
import 'demo_mode_notifier.dart';

part 'demo_github_repository.g.dart';

/// The demo's GitHub Actions (E2, PE-10): two repositories, their workflows
/// and a mix of finished and running runs, all fixed in memory. It is
/// read-only: triggering and cancelling answer [DemoUnavailableFailure].
class DemoGitHubRepository implements GitHubRepository {
  DemoGitHubRepository({DateTime Function()? clock})
    : _now = (clock ?? DateTime.now)();

  final DateTime _now;

  static const _app = GitHubRepo(
    id: 1001,
    name: 'app',
    owner: 'demo-org',
    fullName: 'demo-org/app',
  );
  static const _infra = GitHubRepo(
    id: 1002,
    name: 'infra',
    owner: 'demo-org',
    fullName: 'demo-org/infra',
    private: true,
  );

  static const _ci = GitHubWorkflow(
    id: 501,
    name: 'CI',
    path: '.github/workflows/ci.yml',
    state: 'active',
  );
  static const _deploy = GitHubWorkflow(
    id: 502,
    name: 'Deploy',
    path: '.github/workflows/deploy.yml',
    state: 'active',
  );

  GitHubWorkflowRun _run(
    int id,
    int number,
    GitHubWorkflow workflow,
    String title,
    String status,
    String? conclusion,
    String branch,
    Duration ago,
  ) => GitHubWorkflowRun(
    id: id,
    runNumber: number,
    title: title,
    event: workflow.id == 502 ? 'workflow_dispatch' : 'push',
    status: status,
    conclusion: conclusion,
    branch: branch,
    createdAt: _now.subtract(ago),
    htmlUrl: 'https://github.invalid/demo-org/app/actions/runs/$id',
    workflowId: workflow.id,
    workflowName: workflow.name,
  );

  late final List<GitHubWorkflowRun> _ciRuns = [
    _run(
      9005,
      58,
      _ci,
      'Fix flaky retry test',
      'in_progress',
      null,
      'main',
      const Duration(minutes: 2),
    ),
    _run(
      9004,
      57,
      _ci,
      'Add build duration to job screen',
      'completed',
      'success',
      'main',
      const Duration(hours: 3),
    ),
    _run(
      9003,
      56,
      _ci,
      'Validate empty password',
      'completed',
      'failure',
      'feature-login',
      const Duration(hours: 6),
    ),
    _run(
      9002,
      55,
      _ci,
      'Bump dependencies',
      'completed',
      'success',
      'main',
      const Duration(days: 1),
    ),
    _run(
      9001,
      54,
      _ci,
      'Update README',
      'completed',
      'cancelled',
      'main',
      const Duration(days: 2),
    ),
  ];

  late final List<GitHubWorkflowRun> _deployRuns = [
    _run(
      9102,
      12,
      _deploy,
      'Deploy 1.8.2 to staging',
      'completed',
      'success',
      'main',
      const Duration(hours: 4),
    ),
    _run(
      9101,
      11,
      _deploy,
      'Deploy 1.8.1 to staging',
      'completed',
      'success',
      'main',
      const Duration(days: 3),
    ),
  ];

  List<GitHubWorkflowRun> get _all => [..._ciRuns, ..._deployRuns];

  @override
  Future<Result<List<GitHubRepo>, AppFailure>> fetchRepos() async =>
      const Ok([_app, _infra]);

  @override
  Future<Result<List<GitHubWorkflow>, AppFailure>> fetchWorkflows(
    String owner,
    String repo,
  ) async => Ok(repo == 'app' ? const [_ci, _deploy] : const [_ci]);

  @override
  Future<Result<List<GitHubWorkflowRun>, AppFailure>> fetchRuns(
    String owner,
    String repo,
    int workflowId, {
    int page = 1,
  }) async {
    if (repo != 'app' || page > 1) return const Ok([]);
    return Ok(workflowId == 502 ? _deployRuns : _ciRuns);
  }

  @override
  Future<Result<GitHubWorkflowRun, AppFailure>> fetchRun(
    String owner,
    String repo,
    int runId,
  ) async {
    for (final run in _all) {
      if (run.id == runId) return Ok(run);
    }
    return const Err(NotFoundFailure());
  }

  @override
  Future<Result<List<GitHubWorkflowRun>, AppFailure>> fetchRepoRuns(
    String owner,
    String repo, {
    int limit = 5,
  }) async {
    if (repo != 'app') return const Ok([]);
    final sorted = [..._all]
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    return Ok(sorted.take(limit).toList());
  }

  @override
  Future<Result<List<GitHubJob>, AppFailure>> fetchJobs(
    String owner,
    String repo,
    int runId,
  ) async {
    final run = (await fetchRun(owner, repo, runId));
    if (run case Err(:final error)) return Err(error);
    final r = (run as Ok<GitHubWorkflowRun, AppFailure>).value;
    final failed = r.conclusion == 'failure';
    final running = r.status == 'in_progress';
    GitHubStep step(int n, String name, {String? conclusion}) => GitHubStep(
      number: n,
      name: name,
      status: conclusion == null ? 'in_progress' : 'completed',
      conclusion: conclusion,
    );
    return Ok([
      GitHubJob(
        id: runId * 10 + 1,
        name: 'build',
        status: running ? 'in_progress' : 'completed',
        conclusion: running ? null : (failed ? 'failure' : r.conclusion),
        steps: [
          step(1, 'Set up job', conclusion: 'success'),
          step(2, 'Checkout', conclusion: 'success'),
          step(3, 'Install dependencies', conclusion: 'success'),
          if (running)
            step(4, 'Run tests')
          else
            step(4, 'Run tests', conclusion: failed ? 'failure' : 'success'),
        ],
      ),
    ]);
  }

  @override
  Future<Result<String, AppFailure>> fetchJobLog(
    String owner,
    String repo,
    int jobId,
  ) async {
    final failed = jobId ~/ 10 == 9003;
    return Ok(
      '##[group]Run actions/checkout@v4\n'
      'Syncing repository: demo-org/app\n'
      '##[endgroup]\n'
      '##[group]Run npm ci\n'
      'added 612 packages in 3s\n'
      '##[endgroup]\n'
      '##[group]Run npm test\n'
      '${failed ? 'FAIL src/login.test.ts\n  ● LoginForm › rejects an empty password\n'
                '##[error]Process completed with exit code 1.\n' : 'Tests: 128 passed, 128 total\n'}'
      '##[endgroup]\n',
    );
  }

  @override
  Future<Result<void, AppFailure>> triggerRun(
    String owner,
    String repo,
    int workflowId, {
    required String ref,
    Map<String, String> inputs = const {},
  }) async => const Err(DemoUnavailableFailure());

  @override
  Future<Result<void, AppFailure>> cancelRun(
    String owner,
    String repo,
    int runId,
  ) async => const Err(DemoUnavailableFailure());
}

@riverpod
DemoGitHubRepository demoGitHubRepository(Ref ref) {
  ref.watch(demoModeNotifierProvider);
  return DemoGitHubRepository();
}
