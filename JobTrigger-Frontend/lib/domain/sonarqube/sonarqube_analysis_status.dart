/// A project's analysis status from `GET api/ce/component`
/// (`US-SQ-CE-01`): the background task running now, anything queued behind
/// it, and whether the newest task failed.
class SonarQubeCeTask {
  const SonarQubeCeTask({
    required this.status,
    this.type,
    this.submittedAt,
    this.executedAt,
    this.errorMessage,
  });

  /// `PENDING`, `IN_PROGRESS`, `SUCCESS`, `FAILED` or `CANCELED`.
  final String status;

  /// `REPORT` for a normal scan; older servers add `PROVISION_PROJECT` and
  /// the like, which matter to nobody on this screen.
  final String? type;
  final DateTime? submittedAt;
  final DateTime? executedAt;

  /// Why it failed, when it did — the only place the server explains it.
  final String? errorMessage;

  bool get isQueued => status == 'PENDING';
  bool get isRunning => status == 'IN_PROGRESS';
  bool get failed => status == 'FAILED';
  bool get succeeded => status == 'SUCCESS';

  /// When the server finished this task: `executedAt`, else when it was
  /// submitted (a queued task has no `executedAt`).
  DateTime? get when => executedAt ?? submittedAt;
}

/// `api/ce/component`'s answer for one project.
class SonarQubeAnalysisStatus {
  const SonarQubeAnalysisStatus({this.current, this.queue = const []});

  /// The newest task, whatever its state; null when the server sent none.
  final SonarQubeCeTask? current;

  /// Tasks waiting behind [current].
  final List<SonarQubeCeTask> queue;

  static const none = SonarQubeAnalysisStatus();

  /// A scan is queued or running: the gate shown is from the previous
  /// analysis and about to change.
  SonarQubeCeTask? get pending {
    final newest = current;
    if (newest != null && (newest.isQueued || newest.isRunning)) return newest;
    return queue.isEmpty ? null : queue.first;
  }

  bool get isBusy => pending != null;

  /// The newest task failed, so the gate on screen predates the failure.
  SonarQubeCeTask? get lastFailure =>
      current != null && current!.failed ? current : null;

  /// Nothing to add to the page: no scan pending and no failure to explain.
  bool get isQuiet => !isBusy && lastFailure == null;
}

/// "Analysing…" / "Queued" — what the banner says while a scan is pending.
String sonarQubeCePendingLabel(SonarQubeCeTask task) =>
    task.isRunning ? 'Analysing…' : 'Queued';
