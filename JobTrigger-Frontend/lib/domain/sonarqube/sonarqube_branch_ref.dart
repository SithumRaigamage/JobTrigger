/// Which branch or pull request a project view reads (`US-SQ-QUALITY-10`).
/// Community Builds analyse only the main branch, so [main] is the default
/// and [SonarQubeRefChoices.hasChoice] keeps the picker off such servers.
enum SonarQubeRefKind { main, branch, pullRequest }

class SonarQubeBranchRef {
  const SonarQubeBranchRef.main() : kind = SonarQubeRefKind.main, name = '';
  const SonarQubeBranchRef.branch(this.name) : kind = SonarQubeRefKind.branch;
  const SonarQubeBranchRef.pullRequest(this.name)
    : kind = SonarQubeRefKind.pullRequest;

  final SonarQubeRefKind kind;
  final String name;

  bool get isMain => kind == SonarQubeRefKind.main;

  /// SonarQube's query parameter for this kind; null for the main branch,
  /// which is the absence of a parameter.
  String? get queryKey => switch (kind) {
    SonarQubeRefKind.main => null,
    SonarQubeRefKind.branch => 'branch',
    SonarQubeRefKind.pullRequest => 'pullRequest',
  };

  String get label => switch (kind) {
    SonarQubeRefKind.main => 'Main branch',
    SonarQubeRefKind.branch => name,
    SonarQubeRefKind.pullRequest => 'PR $name',
  };

  @override
  bool operator ==(Object other) =>
      other is SonarQubeBranchRef && other.kind == kind && other.name == name;

  @override
  int get hashCode => Object.hash(kind, name);
}

/// Every analysed ref except the main branch: branches first, then pull
/// requests, each in the server's order.
class SonarQubeRefChoices {
  const SonarQubeRefChoices({required this.refs});

  final List<SonarQubeBranchRef> refs;

  /// More than the main branch exists, so a picker is worth showing.
  bool get hasChoice => refs.isNotEmpty;

  static const none = SonarQubeRefChoices(refs: []);
}

/// Reads `api/project_branches/list` (`{branches: [{name, isMain}]}`) and
/// `api/project_pull_requests/list` (`{pullRequests: [{key, title}]}`).
/// Malformed entries are skipped; a server without either endpoint passes
/// null and gets no choices.
SonarQubeRefChoices parseSonarQubeRefs({
  Object? branches,
  Object? pullRequests,
}) {
  final refs = <SonarQubeBranchRef>[];
  final branchList = branches is Map ? branches['branches'] : null;
  if (branchList is List) {
    for (final branch in branchList) {
      if (branch is! Map || branch['isMain'] == true) continue;
      final name = branch['name'];
      if (name is String && name.isNotEmpty) {
        refs.add(SonarQubeBranchRef.branch(name));
      }
    }
  }
  final pullRequestList = pullRequests is Map
      ? pullRequests['pullRequests']
      : null;
  if (pullRequestList is List) {
    for (final pullRequest in pullRequestList) {
      if (pullRequest is! Map) continue;
      final key = pullRequest['key'];
      if (key is String && key.isNotEmpty) {
        refs.add(SonarQubeBranchRef.pullRequest(key));
      }
    }
  }
  return SonarQubeRefChoices(refs: refs);
}
