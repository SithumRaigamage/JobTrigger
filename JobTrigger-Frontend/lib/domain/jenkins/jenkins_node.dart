/// A Jenkins agent or the built-in node, from `/computer/api/json`
/// (US-JX-12).
class JenkinsNode {
  const JenkinsNode({
    required this.displayName,
    required this.isBuiltIn,
    required this.offline,
    this.temporarilyOffline = false,
    this.offlineReason,
    this.numExecutors = 0,
    this.running = const [],
    this.diskFreeBytes,
    this.diskWarningBytes,
  });

  final String displayName;

  /// The controller itself; addressed as `(built-in)` in URLs.
  final bool isBuiltIn;
  final bool offline;

  /// Marked offline by a person, as opposed to disconnected.
  final bool temporarilyOffline;
  final String? offlineReason;
  final int numExecutors;

  /// Builds currently using this node's executors.
  final List<RunningExecutable> running;

  /// From the disk-space monitor; null when unknown (e.g. offline).
  final int? diskFreeBytes;

  /// Jenkins' own warning threshold for that monitor.
  final int? diskWarningBytes;

  int get busyExecutors => running.length;

  bool get lowDiskSpace =>
      diskFreeBytes != null &&
      diskWarningBytes != null &&
      diskFreeBytes! < diskWarningBytes!;

  /// The node's path segment in `/computer/{name}/…`.
  String get urlName =>
      isBuiltIn ? '(built-in)' : Uri.encodeComponent(displayName);
}

/// A build occupying an executor.
class RunningExecutable {
  const RunningExecutable({
    required this.name,
    required this.url,
    this.progress,
  });

  /// e.g. `slow-build #9 (Work)`.
  final String name;

  /// The build URL, rewritten to the active server.
  final String url;

  /// Percent complete, or null when Jenkins can't estimate it (-1).
  final int? progress;
}
