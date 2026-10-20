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
      startTimeMillis: (json['startTimeMillis'] as num?)?.toInt(),
      error: json['error'] == null
          ? null
          : PipelineErrorDto.fromJson(json['error'] as Map<String, dynamic>),
      stageFlowNodes:
          (json['stageFlowNodes'] as List<dynamic>?)
              ?.map((e) => PipelineStepDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PipelineStepDto>[],
    );

Map<String, dynamic> _$PipelineStageDtoToJson(_PipelineStageDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': instance.status,
      'durationMillis': instance.durationMillis,
      'startTimeMillis': instance.startTimeMillis,
      'error': instance.error,
      'stageFlowNodes': instance.stageFlowNodes,
    };

_PipelineErrorDto _$PipelineErrorDtoFromJson(Map<String, dynamic> json) =>
    _PipelineErrorDto(message: json['message'] as String?);

Map<String, dynamic> _$PipelineErrorDtoToJson(_PipelineErrorDto instance) =>
    <String, dynamic>{'message': instance.message};

_PipelineStepDto _$PipelineStepDtoFromJson(Map<String, dynamic> json) =>
    _PipelineStepDto(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      parameterDescription: json['parameterDescription'] as String?,
      durationMillis: (json['durationMillis'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PipelineStepDtoToJson(_PipelineStepDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': instance.status,
      'parameterDescription': instance.parameterDescription,
      'durationMillis': instance.durationMillis,
    };

_StepLogDto _$StepLogDtoFromJson(Map<String, dynamic> json) => _StepLogDto(
  text: json['text'] as String? ?? '',
  hasMore: json['hasMore'] as bool? ?? false,
);

Map<String, dynamic> _$StepLogDtoToJson(_StepLogDto instance) =>
    <String, dynamic>{'text': instance.text, 'hasMore': instance.hasMore};
