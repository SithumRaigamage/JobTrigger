import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/github/github_repo.dart';

part 'github_repo_dto.freezed.dart';
part 'github_repo_dto.g.dart';

/// One entry of `GET /user/repos`. GitHub's real repo object has many more
/// fields than this — only requests what's actually rendered
/// (`US-GH-REPO-01`); the rest is unverified against a real response
/// (`NFR-TEST-03`) beyond well-known, stable fields.
@freezed
abstract class GitHubRepoDto with _$GitHubRepoDto {
  const factory GitHubRepoDto({
    required int id,
    required String name,
    // GitHub's JSON is snake_case (`full_name`, `default_branch`) --
    // json_serializable doesn't infer this automatically per-field the
    // way some generators do, so each needs an explicit @JsonKey.
    @JsonKey(name: 'full_name') required String fullName,
    required GitHubRepoOwnerDto owner,
    @Default(false) bool private,
    @JsonKey(name: 'default_branch') @Default('main') String defaultBranch,
  }) = _GitHubRepoDto;

  factory GitHubRepoDto.fromJson(Map<String, dynamic> json) =>
      _$GitHubRepoDtoFromJson(json);
}

@freezed
abstract class GitHubRepoOwnerDto with _$GitHubRepoOwnerDto {
  const factory GitHubRepoOwnerDto({required String login}) =
      _GitHubRepoOwnerDto;

  factory GitHubRepoOwnerDto.fromJson(Map<String, dynamic> json) =>
      _$GitHubRepoOwnerDtoFromJson(json);
}

extension GitHubRepoDtoX on GitHubRepoDto {
  GitHubRepo toDomain() => GitHubRepo(
    id: id,
    name: name,
    owner: owner.login,
    fullName: fullName,
    private: private,
    defaultBranch: defaultBranch,
  );
}
