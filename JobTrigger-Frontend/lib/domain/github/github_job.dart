import 'github_status.dart';

/// One job of a run, with its steps (`US-GH-RUN-05`) —
/// `GET /repos/{owner}/{repo}/actions/runs/{run_id}/jobs`.
class GitHubJob {
  const GitHubJob({
    required this.id,
    required this.name,
    required this.status,
    required this.conclusion,
    required this.steps,
  });

  final int id;
  final String name;
  final String status;
  final String? conclusion;
  final List<GitHubStep> steps;

  bool get isCompleted => status == 'completed';
  GitHubRunOutcome get outcome => githubOutcome(status, conclusion);
  String get label => githubLabel(status, conclusion);
}

/// One step of a [GitHubJob]. Same `status` + `conclusion` pair as a run.
class GitHubStep {
  const GitHubStep({
    required this.number,
    required this.name,
    required this.status,
    required this.conclusion,
  });

  final int number;
  final String name;
  final String status;
  final String? conclusion;

  GitHubRunOutcome get outcome => githubOutcome(status, conclusion);
  String get label => githubLabel(status, conclusion);
}
