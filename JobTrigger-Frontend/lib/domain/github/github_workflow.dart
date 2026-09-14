/// A GitHub Actions workflow (US-GH-REPO-02) —
/// `GET /repos/{owner}/{repo}/actions/workflows`.
class GitHubWorkflow {
  const GitHubWorkflow({
    required this.id,
    required this.name,
    required this.path,
    required this.state,
  });

  final int id;
  final String name;

  /// `.github/workflows/<file>.yml` — usable in place of [id] wherever
  /// GitHub's API accepts a `workflow_id` path segment.
  final String path;

  /// `active` | `disabled_manually` | `disabled_inactivity` | others GitHub
  /// may add. Only `active` is triggerable — `US-GH-REPO-02`'s disabled
  /// state.
  final String state;

  bool get isActive => state == 'active';
}
