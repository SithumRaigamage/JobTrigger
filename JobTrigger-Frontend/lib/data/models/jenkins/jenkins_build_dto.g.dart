// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jenkins_build_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JenkinsBuildDto _$JenkinsBuildDtoFromJson(Map<String, dynamic> json) =>
    _JenkinsBuildDto(
      number: (json['number'] as num).toInt(),
      url: json['url'] as String,
      result: json['result'] as String?,
      timestamp: (json['timestamp'] as num).toDouble(),
      duration: (json['duration'] as num?)?.toDouble(),
      estimatedDuration: (json['estimatedDuration'] as num?)?.toDouble(),
      building: json['building'] as bool? ?? false,
      displayName: json['displayName'] as String?,
      causes: json['actions'] == null
          ? const <String>[]
          : _causesFromJson(json['actions']),
      upstreamCause: _upstreamCauseFromJson(json['actions']),
      changes: json['changeSet'] == null
          ? const <ScmChange>[]
          : _changesFromJson(json['changeSet']),
      artifacts:
          (json['artifacts'] as List<dynamic>?)
              ?.map((e) => BuildArtifactDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BuildArtifactDto>[],
    );

Map<String, dynamic> _$JenkinsBuildDtoToJson(_JenkinsBuildDto instance) =>
    <String, dynamic>{
      'number': instance.number,
      'url': instance.url,
      'result': instance.result,
      'timestamp': instance.timestamp,
      'duration': instance.duration,
      'estimatedDuration': instance.estimatedDuration,
      'building': instance.building,
      'displayName': instance.displayName,
      'artifacts': instance.artifacts,
    };

_BuildArtifactDto _$BuildArtifactDtoFromJson(Map<String, dynamic> json) =>
    _BuildArtifactDto(
      fileName: json['fileName'] as String,
      relativePath: json['relativePath'] as String,
    );

Map<String, dynamic> _$BuildArtifactDtoToJson(_BuildArtifactDto instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'relativePath': instance.relativePath,
    };
