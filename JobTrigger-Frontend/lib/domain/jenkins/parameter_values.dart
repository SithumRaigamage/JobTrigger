import 'parameter_definition.dart';
import 'parameter_file.dart';

/// Pure rules for turning [ParameterDefinition]s plus the user's edits into
/// what the form shows and what gets sent to Jenkins (US-JOB-03, US-JX-01).
/// Kept out of widgets and notifiers so every trigger path — job detail,
/// replay (US-PIPE-08), and later deep links — applies them identically.

const passwordParameterType = 'PasswordParameterDefinition';
const textParameterType = 'TextParameterDefinition';
const runParameterType = 'RunParameterDefinition';
const credentialsParameterType = 'CredentialsParameterDefinition';
const fileParameterType = 'FileParameterDefinition';

/// The parameter types this app renders a purpose-built input for. Anything
/// else (plugin types such as Active Choices or Git Parameter) is shown as a
/// labelled text field, or a dropdown when it declares `choices` (US-JX-02).
const knownParameterTypes = {
  'StringParameterDefinition',
  'BooleanParameterDefinition',
  'ChoiceParameterDefinition',
  textParameterType,
  passwordParameterType,
  runParameterType,
  credentialsParameterType,
  fileParameterType,
};

/// Parameters whose value is a secret: masked in the UI, never pre-filled,
/// never echoed in a summary, never replayed.
bool isSecretParameter(ParameterDefinition parameter) =>
    parameter.type == passwordParameterType;

/// Types whose stored default Jenkins never returns, and which are
/// **omitted when left blank** so Jenkins applies that default itself.
/// Verified on the fixture Jenkins: a blank password sent as `''` wiped the
/// stored secret (US-JX-01), and a blank Run parameter was an HTTP 500
/// while an omitted one used the latest build (AUD-38). File parameters are
/// never sent as text; they go as multipart parts (`ParameterFile`).
bool isOmittedWhenBlank(ParameterDefinition parameter) => const {
  passwordParameterType,
  runParameterType,
  credentialsParameterType,
  fileParameterType,
}.contains(parameter.type);

/// The value a field starts with before the user touches it: the declared
/// default if present, else the first choice (Jenkins doesn't always send
/// an explicit default for choice parameters), else empty. Secrets always
/// start empty — Jenkins never returns their stored default anyway
/// (verified on the fixture Jenkins, P11-04), and the app must not invent
/// one.
String initialParameterValue(ParameterDefinition parameter) {
  if (isOmittedWhenBlank(parameter)) return '';
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

/// The text fields of the `buildWithParameters` body. Blank
/// [isOmittedWhenBlank] parameters are **left out** rather than sent as
/// `''`: Jenkins applies a job's stored default only to parameters missing
/// from the request. File parameters never appear here; see
/// [triggerFiles].
Map<String, String> triggerParameters(
  List<ParameterDefinition> parameters,
  Map<String, String> values,
) => {
  for (final parameter in parameters)
    if (parameter.type != fileParameterType)
      if (values[parameter.name] case final value?)
        if (!(isOmittedWhenBlank(parameter) && value.isEmpty))
          parameter.name: value,
};

/// The file parts of a multipart trigger: picked files for parameters the
/// job still declares as file parameters.
Map<String, ParameterFile> triggerFiles(
  List<ParameterDefinition> parameters,
  Map<String, ParameterFile> files,
) => {
  for (final parameter in parameters)
    if (parameter.type == fileParameterType)
      parameter.name: ?files[parameter.name],
};

/// One row of the trigger confirmation summary (AUD-08).
typedef ParameterSummaryRow = ({String name, String display});

/// Human-readable rows for the confirmation step. Secrets are never shown:
/// `••••` when the user entered one, "server default" when left blank.
/// Multi-line values collapse to their first line with an ellipsis.
List<ParameterSummaryRow> parameterSummary(
  List<ParameterDefinition> parameters,
  Map<String, String> values, {
  Map<String, ParameterFile> files = const {},
}) => [
  for (final parameter in parameters)
    (name: parameter.name, display: _displayValue(parameter, values, files)),
];

String _displayValue(
  ParameterDefinition parameter,
  Map<String, String> values,
  Map<String, ParameterFile> files,
) {
  if (parameter.type == fileParameterType) {
    final file = files[parameter.name];
    return file == null
        ? 'no file'
        : '${file.fileName} (${formatFileSize(file.sizeBytes)})';
  }
  final value = values[parameter.name] ?? '';
  if (isSecretParameter(parameter)) {
    return value.isEmpty ? 'server default' : '••••';
  }
  if (isOmittedWhenBlank(parameter) && value.isEmpty) return 'server default';
  if (value.isEmpty) return '(empty)';
  final firstLine = value.split('\n').first;
  return firstLine.length < value.length ? '$firstLine …' : value;
}

/// A job's URL from its Jenkins full name (`team/api` →
/// `{base}/job/team/job/api/`), for the Run parameter's build picker.
/// Each segment is percent-encoded, as Jenkins does.
String jobUrlFromFullName(String baseUrl, String fullName) {
  final base = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final segments = fullName.split('/').map(Uri.encodeComponent);
  return '$base/job/${segments.join('/job/')}/';
}
