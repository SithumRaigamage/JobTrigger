// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_property_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JobPropertyDto _$JobPropertyDtoFromJson(Map<String, dynamic> json) =>
    _JobPropertyDto(
      parameterDefinitions: (json['parameterDefinitions'] as List<dynamic>?)
          ?.map(
            (e) => ParameterDefinitionDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$JobPropertyDtoToJson(_JobPropertyDto instance) =>
    <String, dynamic>{'parameterDefinitions': instance.parameterDefinitions};
