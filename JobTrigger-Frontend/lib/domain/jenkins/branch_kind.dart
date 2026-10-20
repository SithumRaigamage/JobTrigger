/// How a multibranch project classifies each of its jobs (US-JX-03), taken
/// from the branch-api views Jenkins exposes on the project. Verified on the
/// fixture Jenkins: `default` holds branches, `tags` holds tags, and
/// `change-requests` holds pull/merge requests.
enum BranchKind {
  branch('Branches'),
  pullRequest('Pull requests'),
  tag('Tags');

  const BranchKind(this.sectionTitle);

  final String sectionTitle;

  static BranchKind forView(String viewName) => switch (viewName) {
    'change-requests' => BranchKind.pullRequest,
    'tags' => BranchKind.tag,
    _ => BranchKind.branch,
  };
}

/// Maps each job name in a multibranch project to its [BranchKind], from
/// the project's `views[name,jobs[name]]`. A job in several views takes the
/// most specific one (pull request or tag over plain branch).
Map<String, BranchKind> branchKindsFromViews(
  Map<String, List<String>> jobNamesByView,
) {
  final kinds = <String, BranchKind>{};
  for (final MapEntry(key: view, value: names) in jobNamesByView.entries) {
    final kind = BranchKind.forView(view);
    for (final name in names) {
      final existing = kinds[name];
      if (existing == null || existing == BranchKind.branch) kinds[name] = kind;
    }
  }
  return kinds;
}
