// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sonarqube_project_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SonarQubeProjectDto _$SonarQubeProjectDtoFromJson(Map<String, dynamic> json) =>
    _SonarQubeProjectDto(
      key: json['key'] as String,
      name: json['name'] as String? ?? '',
      lastAnalysisDate: json['lastAnalysisDate'] as String?,
    );

Map<String, dynamic> _$SonarQubeProjectDtoToJson(
  _SonarQubeProjectDto instance,
) => <String, dynamic>{
  'key': instance.key,
  'name': instance.name,
  'lastAnalysisDate': instance.lastAnalysisDate,
};
