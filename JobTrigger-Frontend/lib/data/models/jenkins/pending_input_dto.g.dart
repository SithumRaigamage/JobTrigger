// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_input_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingInputDto _$PendingInputDtoFromJson(Map<String, dynamic> json) =>
    _PendingInputDto(
      id: json['id'] as String,
      message: json['message'] as String?,
      proceedText: json['proceedText'] as String? ?? 'Proceed',
      abortText: json['abortText'] as String? ?? 'Abort',
      inputs:
          (json['inputs'] as List<dynamic>?)
              ?.map(
                (e) => PendingInputParameterDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const <PendingInputParameterDto>[],
    );

Map<String, dynamic> _$PendingInputDtoToJson(_PendingInputDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'proceedText': instance.proceedText,
      'abortText': instance.abortText,
      'inputs': instance.inputs,
    };

_PendingInputParameterDto _$PendingInputParameterDtoFromJson(
  Map<String, dynamic> json,
) => _PendingInputParameterDto(
  name: json['name'] as String,
  type: json['type'] as String,
  description: json['description'] as String?,
  definition: json['definition'] == null
      ? null
      : PendingInputParameterDefinitionDto.fromJson(
          json['definition'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PendingInputParameterDtoToJson(
  _PendingInputParameterDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'type': instance.type,
  'description': instance.description,
  'definition': instance.definition,
};

_PendingInputParameterDefinitionDto
_$PendingInputParameterDefinitionDtoFromJson(Map<String, dynamic> json) =>
    _PendingInputParameterDefinitionDto(
      defaultVal: json['defaultVal'],
      choices: (json['choices'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PendingInputParameterDefinitionDtoToJson(
  _PendingInputParameterDefinitionDto instance,
) => <String, dynamic>{
  'defaultVal': instance.defaultVal,
  'choices': instance.choices,
};
