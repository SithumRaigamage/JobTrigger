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
    };
