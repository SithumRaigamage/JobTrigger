import 'github_status.dart';

export 'github_status.dart';

/// One run of a GitHub Actions workflow (`US-GH-RUN-01`) —
/// `GET /repos/{owner}/{repo}/actions/workflows/{workflow_id}/runs`.
///
/// Unlike Jenkins' single `result` string, GitHub reports **two** fields:
/// [status] (where the run is) and [conclusion] (how it ended, only once
/// `completed`). Both are kept as GitHub sends them so values GitHub adds
/// later still round-trip; [label] and [outcome] collapse the pair into the
/// single status language the UI already uses.
class GitHubWorkflowRun {
  const GitHubWorkflowRun({
    required this.id,
    required this.runNumber,
    required this.title,
    required this.event,
    required this.status,
    required this.conclusion,
    required this.branch,
    required this.createdAt,
    required this.htmlUrl,
    this.workflowId,
    this.workflowName,
  });

  final int id;
  final int runNumber;

  /// The commit message / PR title GitHub shows for the run (`display_title`).
  final String title;

  /// What started it: `push` | `pull_request` | `workflow_dispatch` | …
  final String event;

  /// `queued` | `in_progress` | `completed` | `waiting` | `requested` |
  /// `pending` | others GitHub may add.
  final String status;

  /// `success` | `failure` | `cancelled` | `skipped` | `timed_out` |
  /// `action_required` | `neutral` | `stale` | `startup_failure`; `null`
  /// until the run completes.
  final String? conclusion;

  final String? branch;
  final DateTime? createdAt;
  final String htmlUrl;

  /// The workflow this run belongs to. Needed where runs of many workflows
  /// are mixed (the cross-repo feed); null if GitHub didn't send them.
  final int? workflowId;
  final String? workflowName;

  bool get isCompleted => status == 'completed';

  /// Not finished: the run is still moving, so live status matters.
  bool get isActive => !isCompleted;

  /// The pair as one outcome for display; see [GitHubRunOutcome].
  GitHubRunOutcome get outcome => githubOutcome(status, conclusion);

  /// Human copy for the underlying state.
  String get label => githubLabel(status, conclusion);
}
