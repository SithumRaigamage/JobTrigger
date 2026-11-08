import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/github/github_workflow_run.dart';

part 'github_workflow_run_dto.freezed.dart';
part 'github_workflow_run_dto.g.dart';

/// One entry of `GET .../workflows/{id}/runs`'s `workflow_runs[]`. Only the
/// fields the run list renders; GitHub sends many more.
@freezed
abstract class GitHubWorkflowRunDto with _$GitHubWorkflowRunDto {
  const factory GitHubWorkflowRunDto({
    required int id,
    @JsonKey(name: 'run_number') @Default(0) int runNumber,
    // `display_title` is the commit message / PR title; `name` is the
    // workflow's own name and the fallback for older responses.
    @JsonKey(name: 'display_title') String? displayTitle,
    String? name,
    @Default('') String event,
    @Default('') String status,
    String? conclusion,
    @JsonKey(name: 'head_branch') String? headBranch,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'html_url') @Default('') String htmlUrl,
    @JsonKey(name: 'workflow_id') int? workflowId,
  }) = _GitHubWorkflowRunDto;

  factory GitHubWorkflowRunDto.fromJson(Map<String, dynamic> json) =>
      _$GitHubWorkflowRunDtoFromJson(json);
}

extension GitHubWorkflowRunDtoX on GitHubWorkflowRunDto {
  GitHubWorkflowRun toDomain() => GitHubWorkflowRun(
    id: id,
    runNumber: runNumber,
    title: displayTitle ?? name ?? 'Run #$runNumber',
    event: event,
    status: status,
    conclusion: conclusion,
    branch: headBranch,
    createdAt: createdAt == null ? null : DateTime.tryParse(createdAt!),
    htmlUrl: htmlUrl,
    workflowId: workflowId,
    workflowName: name,
  );
}
