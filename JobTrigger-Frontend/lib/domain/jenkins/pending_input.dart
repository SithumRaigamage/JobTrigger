import 'parameter_definition.dart';

/// A paused pipeline `input` step waiting for approval (US-PIPE-05) —
/// `{buildURL}wfapi/pendingInputActions`. `null` at the call site (not
/// this type) means nothing is currently paused, a normal state.
///
/// Verified against real paused pipelines on the fixture Jenkins (P11-02,
/// `test/fixture/input_step_fixture_test.dart`): detection, proceed with
/// and without parameters, abort, and a read-only user's rejection. This
/// is the highest-stakes action in the PIPE epic, since it can directly
/// gate a production deployment.
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

  /// Parameter definitions the input step also requests, if any, mapped
  /// onto the same [ParameterDefinition] the trigger form uses. The wire
  /// shape differs from a job's parameters (see `PendingInputParameterDto`),
  /// but the domain type is shared so `ParameterForm` renders both.
  final List<ParameterDefinition> inputs;
}
