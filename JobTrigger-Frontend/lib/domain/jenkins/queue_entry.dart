/// One item waiting in the server-wide build queue (US-JX-09), from
/// `/queue/api/json`.
class QueueEntry {
  const QueueEntry({
    required this.id,
    required this.taskName,
    required this.taskUrl,
    this.why,
    this.inQueueSince,
    this.stuck = false,
    this.blocked = false,
    this.taskColor,
  });

  final int id;
  final String taskName;

  /// The queued job's URL, rewritten to the active server.
  final String taskUrl;

  /// Jenkins' own reason, e.g. "Waiting for next available executor".
  final String? why;
  final DateTime? inQueueSince;

  /// Waiting abnormally long — shown as a warning.
  final bool stuck;
  final bool blocked;
  final String? taskColor;
}
