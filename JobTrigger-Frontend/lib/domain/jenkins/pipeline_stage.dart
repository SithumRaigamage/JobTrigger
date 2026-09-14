/// One stage of a pipeline (Jenkinsfile-based) build (US-PIPE-04) —
/// `{buildURL}wfapi/describe`'s `stages[]`. `null` at the call site (not
/// this type) means the build isn't a pipeline job at all (freestyle, or
/// no Pipeline: REST API plugin), a normal state, not an error.
class PipelineStage {
  const PipelineStage({
    required this.id,
    required this.name,
    required this.status,
    this.durationMillis,
  });

  final String id;
  final String name;

  /// SUCCESS | FAILED | IN_PROGRESS | NOT_EXECUTED | ABORTED | UNSTABLE |
  /// PAUSED_PENDING_INPUT (see US-PIPE-05).
  final String status;
  final int? durationMillis;
}
