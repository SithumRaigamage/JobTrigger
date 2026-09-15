import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/github/github_workflow.dart';

part 'github_workflow_dto.freezed.dart';
part 'github_workflow_dto.g.dart';

/// One entry of `GET /repos/{owner}/{repo}/actions/workflows`'s
/// `workflows[]`.
@freezed
abstract class GitHubWorkflowDto with _$GitHubWorkflowDto {
  const factory GitHubWorkflowDto({
    required int id,
    required String name,
    required String path,
    required String state,
  }) = _GitHubWorkflowDto;

  factory GitHubWorkflowDto.fromJson(Map<String, dynamic> json) =>
      _$GitHubWorkflowDtoFromJson(json);
}

extension GitHubWorkflowDtoX on GitHubWorkflowDto {
  GitHubWorkflow toDomain() =>
      GitHubWorkflow(id: id, name: name, path: path, state: state);
}
