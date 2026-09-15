import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'github_repo.dart';
import 'github_workflow.dart';

/// GitHub Actions data access — the GitHub-side equivalent of
/// `JenkinsRepository`, entirely independent (no shared code, per
/// `docs/user-stories/12-github-actions.md`'s epic intro). Grown
/// incrementally, one method per GH-REPO/GH-RUN/GH-LOG/GH-HIST task
/// landing, rather than declared upfront in full — avoids a large
/// interface change rippling through every fake implementation each time
/// (the exact cost Phase 7's Jenkins interface changes kept hitting).
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
}
