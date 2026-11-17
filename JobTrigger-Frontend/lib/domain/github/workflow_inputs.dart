/// Validation for the free-form `workflow_dispatch` inputs a user types in
/// (`US-GH-RUN-02`). GitHub's API doesn't expose a workflow's declared input
/// schema, so names and values are untyped text the user supplies.
class WorkflowInputsResult {
  const WorkflowInputsResult.ok(this.inputs) : error = null;
  const WorkflowInputsResult.invalid(this.error) : inputs = const {};

  final Map<String, String> inputs;
  final String? error;

  bool get isValid => error == null;
}

/// Turns the form's rows into the `inputs` object. Fully blank rows are
/// ignored; a row with a value but no name, or a repeated name, is an error
/// the user can fix rather than something silently dropped or overwritten.
WorkflowInputsResult cleanWorkflowInputs(List<(String, String)> rows) {
  final inputs = <String, String>{};
  for (final (rawName, value) in rows) {
    final name = rawName.trim();
    if (name.isEmpty && value.isEmpty) continue;
    if (name.isEmpty) {
      return const WorkflowInputsResult.invalid('Every input needs a name.');
    }
    if (inputs.containsKey(name)) {
      return WorkflowInputsResult.invalid('"$name" is entered twice.');
    }
    inputs[name] = value;
  }
  return WorkflowInputsResult.ok(inputs);
}
