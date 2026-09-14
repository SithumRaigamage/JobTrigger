// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pipeline_stage_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PipelineDescribeDto _$PipelineDescribeDtoFromJson(Map<String, dynamic> json) =>
    _PipelineDescribeDto(
      stages:
          (json['stages'] as List<dynamic>?)
              ?.map((e) => PipelineStageDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PipelineStageDto>[],
    );

Map<String, dynamic> _$PipelineDescribeDtoToJson(
  _PipelineDescribeDto instance,
) => <String, dynamic>{'stages': instance.stages};

_PipelineStageDto _$PipelineStageDtoFromJson(Map<String, dynamic> json) =>
    _PipelineStageDto(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      durationMillis: (json['durationMillis'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PipelineStageDtoToJson(_PipelineStageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': instance.status,
      'durationMillis': instance.durationMillis,
    };
