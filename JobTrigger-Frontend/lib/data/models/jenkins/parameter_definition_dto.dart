import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/jenkins/parameter_definition.dart';

part 'parameter_definition_dto.freezed.dart';
part 'parameter_definition_dto.g.dart';

/// Jenkins' actual JSON key here is `defaultParameterValue` (confirmed
/// against the old Swift app's `ParameterDefinition.defaultParameterValue`
/// field and its own `detailsTree` query, which explicitly requests
/// `defaultParameterValue[value]`) — **not** `defaultValue` as
/// `docs/data-models.md`'s sample names it. It nests as
/// `{"name": ..., "value": <actual default>}`; `_defaultValueFromJson`
/// unwraps it. The value itself is polymorphic (string/bool/number
/// depending on the parameter type), hence `dynamic`.
@freezed
abstract class ParameterDefinitionDto with _$ParameterDefinitionDto {
  const factory ParameterDefinitionDto({
    required String name,
    required String
    type, // StringParameterDefinition | ChoiceParameterDefinition | BooleanParameterDefinition
    String? description,
    List<String>? choices,
    @JsonKey(name: 'defaultParameterValue', fromJson: _defaultValueFromJson)
    dynamic defaultValue,
  }) = _ParameterDefinitionDto;

  factory ParameterDefinitionDto.fromJson(Map<String, dynamic> json) =>
      _$ParameterDefinitionDtoFromJson(json);
}

dynamic _defaultValueFromJson(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw['value'];
  return raw;
}

extension ParameterDefinitionDtoX on ParameterDefinitionDto {
  ParameterDefinition toDomain() => ParameterDefinition(
    name: name,
    type: type,
    description: description,
    choices: choices,
    defaultValue: defaultValue,
  );
}
