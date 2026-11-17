// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_job_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GitHubJobDto _$GitHubJobDtoFromJson(Map<String, dynamic> json) =>
    _GitHubJobDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      conclusion: json['conclusion'] as String?,
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((e) => GitHubStepDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <GitHubStepDto>[],
    );

Map<String, dynamic> _$GitHubJobDtoToJson(_GitHubJobDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'status': instance.status,
      'conclusion': instance.conclusion,
      'steps': instance.steps,
    };

_GitHubStepDto _$GitHubStepDtoFromJson(Map<String, dynamic> json) =>
    _GitHubStepDto(
      number: (json['number'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      conclusion: json['conclusion'] as String?,
    );

Map<String, dynamic> _$GitHubStepDtoToJson(_GitHubStepDto instance) =>
    <String, dynamic>{
      'number': instance.number,
      'name': instance.name,
      'status': instance.status,
      'conclusion': instance.conclusion,
    };
