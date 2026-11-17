/// One comment on an issue (`api/issues/search?additionalFields=comments`).
class SonarQubeIssueComment {
  const SonarQubeIssueComment({
    required this.login,
    required this.text,
    this.createdAt,
  });

  final String? login;
  final String text;
  final DateTime? createdAt;
}

/// What the issue page needs beyond the issue as listed (`US-SQ-WRITE-01..03`):
/// the server's current status and assignee, the transitions it **offers**
/// (never a fixed list in the app) and the comments.
class SonarQubeIssueDetail {
  const SonarQubeIssueDetail({
    required this.status,
    this.assignee,
    this.transitions = const [],
    this.comments = const [],
  });

  /// `OPEN`, `CONFIRMED`, `REOPENED`, `RESOLVED`, `CLOSED`, …
  final String status;

  /// The assignee's login, or null when unassigned.
  final String? assignee;

  /// `confirm`, `unconfirm`, `reopen`, `resolve`, `falsepositive`, `wontfix`,
  /// `accept` — whatever this server and this user may do to this issue.
  final List<String> transitions;
  final List<SonarQubeIssueComment> comments;
}

/// How a transition reads on a button. Unknown ones are title-cased as sent.
String sonarQubeTransitionLabel(String transition) => switch (transition) {
  'confirm' => 'Confirm',
  'unconfirm' => 'Unconfirm',
  'reopen' => 'Reopen',
  'resolve' => 'Resolve as fixed',
  'falsepositive' => 'Mark as false positive',
  'wontfix' => "Mark as won't fix",
  'accept' => 'Accept',
  final other when other.isNotEmpty =>
    other[0].toUpperCase() + other.substring(1),
  _ => transition,
};

/// A security hotspot review decision (`US-SQ-WRITE-04`) and how
/// `api/hotspots/change_status` spells it.
enum SonarQubeHotspotReview {
  toReview('Back to review', 'TO_REVIEW', null),
  acknowledged('Acknowledged', 'REVIEWED', 'ACKNOWLEDGED'),
  fixed('Fixed', 'REVIEWED', 'FIXED'),
  safe('Safe', 'REVIEWED', 'SAFE');

  const SonarQubeHotspotReview(this.label, this.status, this.resolution);

  final String label;
  final String status;
  final String? resolution;
}
