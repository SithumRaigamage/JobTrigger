/// A GitHub repository (US-GH-REPO-01) — `GET /user/repos`.
class GitHubRepo {
  const GitHubRepo({
    required this.id,
    required this.name,
    required this.owner,
    required this.fullName,
    this.private = false,
    this.defaultBranch = 'main',
  });

  final int id;
  final String name;

  /// Login of the owning user/org — e.g. `"octocat"`.
  final String owner;

  /// `"owner/name"`, as GitHub's API and UI both address it.
  final String fullName;
  final bool private;
  final String defaultBranch;
}
