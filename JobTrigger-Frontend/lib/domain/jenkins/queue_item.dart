/// A Jenkins queue item — what a just-triggered build becomes before an
/// executor picks it up (US-PIPE-01). Tracked via the trigger response's
/// `Location` header, not fetched from any per-job endpoint (Jenkins'
/// queue is server-wide) — see `jenkins_repository_impl.dart#triggerBuild`.
class QueueItem {
  const QueueItem({this.why, this.cancelled = false, this.executable});

  /// Why the item is still waiting (e.g. "Waiting for next available
  /// executor", a quiet period, a resource lock) — Jenkins omits this once
  /// [executable] is set.
  final String? why;

  /// True if the item was cancelled before it ever became a build.
  final bool cancelled;

  /// Set once Jenkins assigns an executor and the item becomes a real
  /// build — `null` while still queued.
  final QueueExecutable? executable;

  /// True once there's nothing left to poll for: either it started
  /// building or it was cancelled.
  bool get isResolved => cancelled || executable != null;
}

class QueueExecutable {
  const QueueExecutable({required this.number, required this.url});

  final int number;
  final String url;
}
