// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parameter_definition_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ParameterDefinitionDto _$ParameterDefinitionDtoFromJson(
  Map<String, dynamic> json,
) => _ParameterDefinitionDto(
  name: json['name'] as String,
  type: json['type'] as String,
  description: json['description'] as String?,
  choices: (json['choices'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  defaultValue: _defaultValueFromJson(json['defaultParameterValue']),
);

Map<String, dynamic> _$ParameterDefinitionDtoToJson(
  _ParameterDefinitionDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'type': instance.type,
  'description': instance.description,
  'choices': instance.choices,
  'defaultParameterValue': instance.defaultValue,
};
