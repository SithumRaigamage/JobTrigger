import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'github_repo.dart';
import 'github_job.dart';
import 'github_workflow.dart';
import 'github_workflow_run.dart';

/// GitHub Actions data access — the GitHub-side equivalent of
/// `JenkinsRepository`, entirely independent (no shared code, per
/// `docs/user-stories/12-github-actions.md`'s epic intro). Grown
/// incrementally, one method per GH-REPO/GH-RUN/GH-LOG/GH-HIST task
/// landing, rather than declared upfront in full — avoids a large
/// interface change rippling through every fake implementation each time
/// (the exact cost Phase 7's Jenkins interface changes kept hitting).
/// Runs per page of `GET .../workflows/{id}/runs`.
const gitHubRunsPageSize = 30;

abstract class GitHubRepository {
  /// `GET /user/repos` (`US-GH-REPO-01`). Currently fetches only the
  /// first page (100 repos, GitHub's max `per_page`) — true incremental
  /// pagination via the `Link` header is a known, deliberate trim, not
  /// silently dropped; most credentials won't exceed 100 repos, and this
  /// keeps the first GH-REPO slice's scope contained.
  Future<Result<List<GitHubRepo>, AppFailure>> fetchRepos();

  /// `GET /repos/{owner}/{repo}/actions/workflows` (`US-GH-REPO-02`).
  Future<Result<List<GitHubWorkflow>, AppFailure>> fetchWorkflows(
    String owner,
    String repo,
  );

  /// `GET /repos/{owner}/{repo}/actions/workflows/{workflow_id}/runs`
  /// (`US-GH-RUN-01`). Newest first, [gitHubRunsPageSize] runs per [page]
  /// (1-based). A short page is the end of history (`US-GH-HIST-01`).
  Future<Result<List<GitHubWorkflowRun>, AppFailure>> fetchRuns(
    String owner,
    String repo,
    int workflowId, {
    int page = 1,
  });

  /// `POST .../workflows/{workflow_id}/dispatches` (`US-GH-RUN-02`). GitHub
  /// answers 204 with no run id, so there is nothing to track: callers
  /// refresh the runs list instead. A 422 becomes [DispatchRejectedFailure].
  /// [inputs] are untyped key/value pairs — GitHub's API doesn't expose a
  /// workflow's declared input schema.
  Future<Result<void, AppFailure>> triggerRun(
    String owner,
    String repo,
    int workflowId, {
    required String ref,
    Map<String, String> inputs = const {},
  });

  /// `GET /repos/{owner}/{repo}/actions/runs/{run_id}` (`US-GH-RUN-03`).
  Future<Result<GitHubWorkflowRun, AppFailure>> fetchRun(
    String owner,
    String repo,
    int runId,
  );

  /// `POST .../runs/{run_id}/cancel` (`US-GH-RUN-04`). 202 Accepted: the
  /// cancel is asynchronous, so success means *requested*, not *stopped*.
  Future<Result<void, AppFailure>> cancelRun(
    String owner,
    String repo,
    int runId,
  );

  /// `GET /repos/{owner}/{repo}/actions/runs/{run_id}/jobs`
  /// (`US-GH-RUN-05`): each job with its steps.
  Future<Result<List<GitHubJob>, AppFailure>> fetchJobs(
    String owner,
    String repo,
    int runId,
  );

  /// `GET /repos/{owner}/{repo}/actions/jobs/{job_id}/logs` (`US-GH-LOG-01`):
  /// the whole log as plain text. GitHub answers 302 to a short-lived
  /// signed URL; following it is part of this one call, and that URL never
  /// leaves the data layer. Only meaningful once the job has completed:
  /// GitHub has no offset or tail to poll a partial log safely.
  Future<Result<String, AppFailure>> fetchJobLog(
    String owner,
    String repo,
    int jobId,
  );

  /// `GET /repos/{owner}/{repo}/actions/runs?per_page=[limit]`: the latest
  /// runs of every workflow in one repo (`US-GH-HIST-02`'s per-repo call).
  Future<Result<List<GitHubWorkflowRun>, AppFailure>> fetchRepoRuns(
    String owner,
    String repo, {
    int limit = 5,
  });
}
