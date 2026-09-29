import 'parameter_definition.dart';

/// Pure rules for turning [ParameterDefinition]s plus the user's edits into
/// what the form shows and what gets sent to Jenkins (US-JOB-03, US-JX-01).
/// Kept out of widgets and notifiers so every trigger path — job detail,
/// replay (US-PIPE-08), and later deep links — applies them identically.

const passwordParameterType = 'PasswordParameterDefinition';

/// Parameters whose value is a secret: masked in the UI, never pre-filled,
/// never echoed in a summary, never replayed.
bool isSecretParameter(ParameterDefinition parameter) =>
    parameter.type == passwordParameterType;

/// The value a field starts with before the user touches it: the declared
/// default if present, else the first choice (Jenkins doesn't always send
/// an explicit default for choice parameters), else empty. Secrets always
/// start empty — Jenkins never returns their stored default anyway
/// (verified on the fixture Jenkins, P11-04), and the app must not invent
/// one.
String initialParameterValue(ParameterDefinition parameter) {
  if (isSecretParameter(parameter)) return '';
  final declared = parameter.defaultValue;
  if (declared != null) return declared.toString();
  final choices = parameter.choices;
  if (choices != null && choices.isNotEmpty) return choices.first;
  return '';
}

/// What the form displays: each parameter's initial value, overridden by
/// any edit the user made. Edits for parameters the job no longer declares
/// are dropped.
Map<String, String> effectiveParameterValues(
  List<ParameterDefinition> parameters,
  Map<String, String> edits,
) => {
  for (final parameter in parameters)
    parameter.name: edits[parameter.name] ?? initialParameterValue(parameter),
};

/// The `buildWithParameters` body. A **blank secret is omitted** rather
/// than sent as `''`: Jenkins applies a job's stored default only to
/// parameters missing from the request, so sending `DEPLOY_TOKEN=` would
/// silently replace the real secret with an empty string (US-JX-01,
/// verified on the fixture Jenkins).
Map<String, String> triggerParameters(
  List<ParameterDefinition> parameters,
  Map<String, String> values,
) => {
  for (final parameter in parameters)
    if (values[parameter.name] case final value?)
      if (!(isSecretParameter(parameter) && value.isEmpty))
        parameter.name: value,
};

/// One row of the trigger confirmation summary (AUD-08).
typedef ParameterSummaryRow = ({String name, String display});

/// Human-readable rows for the confirmation step. Secrets are never shown:
/// `••••` when the user entered one, "server default" when left blank.
/// Multi-line values collapse to their first line with an ellipsis.
List<ParameterSummaryRow> parameterSummary(
  List<ParameterDefinition> parameters,
  Map<String, String> values,
) => [
  for (final parameter in parameters)
    (name: parameter.name, display: _displayValue(parameter, values)),
];

String _displayValue(
  ParameterDefinition parameter,
  Map<String, String> values,
) {
  final value = values[parameter.name] ?? '';
  if (isSecretParameter(parameter)) {
    return value.isEmpty ? 'server default' : '••••';
  }
  if (value.isEmpty) return '(empty)';
  final firstLine = value.split('\n').first;
  return firstLine.length < value.length ? '$firstLine …' : value;
}
