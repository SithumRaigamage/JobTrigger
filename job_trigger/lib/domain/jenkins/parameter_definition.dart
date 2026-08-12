/// Jenkins returns `defaultValue` as string/bool/number depending on
/// [type] — see `data/models/jenkins/parameter_definition_dto.dart`. The
/// parameter form (Phase 5) switches on [type] to render a text
/// field/dropdown/switch, and always serializes the submitted value back to
/// a `String` regardless of the declared type.
class ParameterDefinition {
  const ParameterDefinition({
    required this.name,
    required this.type,
    this.description,
    this.choices,
    this.defaultValue,
  });

  final String name;
  final String type;
  final String? description;
  final List<String>? choices;
  final dynamic defaultValue;
}
