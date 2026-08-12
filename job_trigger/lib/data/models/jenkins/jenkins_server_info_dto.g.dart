// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jenkins_server_info_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JenkinsServerInfoDto _$JenkinsServerInfoDtoFromJson(
  Map<String, dynamic> json,
) => _JenkinsServerInfoDto(
  mode: json['mode'] as String?,
  nodeDescription: json['nodeDescription'] as String?,
  numExecutors: (json['numExecutors'] as num?)?.toInt(),
  useSecurity: json['useSecurity'] as bool?,
  jobs:
      (json['jobs'] as List<dynamic>?)
          ?.map((e) => JenkinsJobDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$JenkinsServerInfoDtoToJson(
  _JenkinsServerInfoDto instance,
) => <String, dynamic>{
  'mode': instance.mode,
  'nodeDescription': instance.nodeDescription,
  'numExecutors': instance.numExecutors,
  'useSecurity': instance.useSecurity,
  'jobs': instance.jobs,
};
