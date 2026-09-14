// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_workflow_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GitHubWorkflowDto _$GitHubWorkflowDtoFromJson(Map<String, dynamic> json) =>
    _GitHubWorkflowDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      path: json['path'] as String,
      state: json['state'] as String,
    );

Map<String, dynamic> _$GitHubWorkflowDtoToJson(_GitHubWorkflowDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'path': instance.path,
      'state': instance.state,
    };
