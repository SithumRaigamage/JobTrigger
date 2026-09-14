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
                (e) =>
                    ParameterDefinitionDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ParameterDefinitionDto>[],
    );

Map<String, dynamic> _$PendingInputDtoToJson(_PendingInputDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'message': instance.message,
      'proceedText': instance.proceedText,
      'abortText': instance.abortText,
      'inputs': instance.inputs,
    };
