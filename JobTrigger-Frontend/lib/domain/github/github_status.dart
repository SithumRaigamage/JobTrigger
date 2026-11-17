// GitHub reports a run, a job and a step the same way: `status` (where it
// is) plus `conclusion` (how it ended, only once `completed`). These turn
// that pair into one display state and label, shared by all three
// (`US-GH-RUN-01`, `US-GH-RUN-05`).

/// The pair as one visual state, so the UI teaches one status model across
/// Jenkins and GitHub.
enum GitHubRunOutcome { success, failure, running, queued, attention, neutral }

GitHubRunOutcome githubOutcome(String status, String? conclusion) {
  if (status != 'completed') {
    return switch (status) {
      'in_progress' => GitHubRunOutcome.running,
      // queued / waiting / requested / pending — not running yet.
      _ => GitHubRunOutcome.queued,
    };
  }
  return switch (conclusion) {
    'success' => GitHubRunOutcome.success,
    'failure' || 'timed_out' || 'startup_failure' => GitHubRunOutcome.failure,
    'action_required' => GitHubRunOutcome.attention,
    // cancelled / skipped / neutral / stale / null / anything new.
    _ => GitHubRunOutcome.neutral,
  };
}

String githubLabel(String status, String? conclusion) {
  if (status != 'completed') {
    return switch (status) {
      'in_progress' => 'In progress',
      'queued' => 'Queued',
      'waiting' => 'Waiting',
      'requested' => 'Requested',
      'pending' => 'Pending',
      final other => _humanize(other),
    };
  }
  return switch (conclusion) {
    'success' => 'Success',
    'failure' => 'Failed',
    'cancelled' => 'Cancelled',
    'skipped' => 'Skipped',
    'timed_out' => 'Timed out',
    'action_required' => 'Action required',
    'neutral' => 'Neutral',
    'stale' => 'Stale',
    'startup_failure' => 'Startup failure',
    null => 'Completed',
    final other => _humanize(other),
  };
}

String _humanize(String raw) {
  final words = raw.replaceAll('_', ' ').trim();
  if (words.isEmpty) return 'Unknown';
  return words[0].toUpperCase() + words.substring(1);
}
