import 'parameter_definition.dart';

/// A paused pipeline `input` step waiting for approval (US-PIPE-05) —
/// `{buildURL}wfapi/pendingInputActions`. `null` at the call site (not
/// this type) means nothing is currently paused, a normal state.
///
/// **Unverified against a real paused pipeline** — implemented against
/// the documented shape of the Pipeline: REST API plugin's
/// `pendingInputActions`/input-submission endpoints, which this
/// environment has no live Jenkins instance with an actual paused
/// pipeline to confirm field names and submit mechanics against (same
/// class of gap as `NFR-TEST-02` flags elsewhere in this project). Must
/// be confirmed against a real server before being trusted in production
/// — this is the highest-stakes action in the PIPE epic (it can directly
/// gate a production deployment), so that confirmation matters more here
/// than anywhere else in this epic.
class PendingInput {
  const PendingInput({
    required this.id,
    this.message,
    this.proceedText = 'Proceed',
    this.abortText = 'Abort',
    this.inputs = const [],
  });

  final String id;
  final String? message;
  final String proceedText;
  final String abortText;

  /// Parameter definitions the input step also requests, if any. Reuses
  /// [ParameterDefinition] on the assumption that Jenkins serializes an
  /// input step's parameters through the same `ParameterDefinition` class
  /// family as job-trigger parameters (`US-JOB-03`) — unverified, see the
  /// class doc comment above.
  final List<ParameterDefinition> inputs;
}
