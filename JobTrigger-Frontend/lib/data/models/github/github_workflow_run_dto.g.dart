// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_workflow_run_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GitHubWorkflowRunDto _$GitHubWorkflowRunDtoFromJson(
  Map<String, dynamic> json,
) => _GitHubWorkflowRunDto(
  id: (json['id'] as num).toInt(),
  runNumber: (json['run_number'] as num?)?.toInt() ?? 0,
  displayTitle: json['display_title'] as String?,
  name: json['name'] as String?,
  event: json['event'] as String? ?? '',
  status: json['status'] as String? ?? '',
  conclusion: json['conclusion'] as String?,
  headBranch: json['head_branch'] as String?,
  createdAt: json['created_at'] as String?,
  htmlUrl: json['html_url'] as String? ?? '',
);

Map<String, dynamic> _$GitHubWorkflowRunDtoToJson(
  _GitHubWorkflowRunDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'run_number': instance.runNumber,
  'display_title': instance.displayTitle,
  'name': instance.name,
  'event': instance.event,
  'status': instance.status,
  'conclusion': instance.conclusion,
  'head_branch': instance.headBranch,
  'created_at': instance.createdAt,
  'html_url': instance.htmlUrl,
};
