// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jenkins_job_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JenkinsJobDto _$JenkinsJobDtoFromJson(Map<String, dynamic> json) =>
    _JenkinsJobDto(
      name: json['name'] as String,
      url: json['url'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      jobs: (json['jobs'] as List<dynamic>?)
          ?.map((e) => JenkinsJobDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastBuild: json['lastBuild'] == null
          ? null
          : JenkinsBuildDto.fromJson(json['lastBuild'] as Map<String, dynamic>),
      healthReport:
          (json['healthReport'] as List<dynamic>?)
              ?.map((e) => HealthReportDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      property:
          (json['property'] as List<dynamic>?)
              ?.map((e) => JobPropertyDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      builds:
          (json['builds'] as List<dynamic>?)
              ?.map((e) => JenkinsBuildDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$JenkinsJobDtoToJson(_JenkinsJobDto instance) =>
    <String, dynamic>{
      'name': instance.name,
      'url': instance.url,
      'description': instance.description,
      'color': instance.color,
      'jobs': instance.jobs,
      'lastBuild': instance.lastBuild,
      'healthReport': instance.healthReport,
      'property': instance.property,
      'builds': instance.builds,
    };
