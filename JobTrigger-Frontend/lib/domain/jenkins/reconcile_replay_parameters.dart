import 'parameter_definition.dart';
import 'parameter_values.dart';

/// US-PIPE-08: reconciles a job's *current* declared parameter
/// definitions with a *previous* build's actually-recorded values, for
/// "replay with same parameters." Returns [currentDefinitions] with each
/// [ParameterDefinition.defaultValue] overridden by the matching entry in
/// [historicValues] where one exists — feeding the result straight into
/// the existing `ParameterForm` (`US-JOB-03`) pre-fills it without that
/// widget needing to know anything about replay.
///
/// - A parameter present in both: pre-filled with its historic value.
/// - A parameter only in [currentDefinitions] (added to the job since):
///   falls back to its current declared default, untouched.
/// - A parameter only in [historicValues] (removed from the job since):
///   silently dropped — it can no longer be submitted.
/// - A secret (password) parameter: never pre-filled from history, so it
///   stays blank and Jenkins applies its stored default (US-JX-01).
///   Jenkins doesn't return recorded password values anyway; this makes
///   the rule explicit rather than incidental.
List<ParameterDefinition> reconcileReplayParameters(
  List<ParameterDefinition> currentDefinitions,
  Map<String, String> historicValues,
) {
  return currentDefinitions.map((definition) {
    final historic = historicValues[definition.name];
    if (historic == null || isSecretParameter(definition)) return definition;
    return ParameterDefinition(
      name: definition.name,
      type: definition.type,
      description: definition.description,
      choices: definition.choices,
      defaultValue: historic,
    );
  }).toList();
}
