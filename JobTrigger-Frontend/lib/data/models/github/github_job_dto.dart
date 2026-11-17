import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/github/github_job.dart';

part 'github_job_dto.freezed.dart';
part 'github_job_dto.g.dart';

/// One entry of `GET .../runs/{id}/jobs`'s `jobs[]`.
@freezed
abstract class GitHubJobDto with _$GitHubJobDto {
  const factory GitHubJobDto({
    required int id,
    @Default('') String name,
    @Default('') String status,
    String? conclusion,
    @Default(<GitHubStepDto>[]) List<GitHubStepDto> steps,
  }) = _GitHubJobDto;

  factory GitHubJobDto.fromJson(Map<String, dynamic> json) =>
      _$GitHubJobDtoFromJson(json);
}

@freezed
abstract class GitHubStepDto with _$GitHubStepDto {
  const factory GitHubStepDto({
    @Default(0) int number,
    @Default('') String name,
    @Default('') String status,
    String? conclusion,
  }) = _GitHubStepDto;

  factory GitHubStepDto.fromJson(Map<String, dynamic> json) =>
      _$GitHubStepDtoFromJson(json);
}

extension GitHubJobDtoX on GitHubJobDto {
  GitHubJob toDomain() => GitHubJob(
    id: id,
    name: name,
    status: status,
    conclusion: conclusion,
    steps: [
      for (final s in steps)
        GitHubStep(
          number: s.number,
          name: s.name,
          status: s.status,
          conclusion: s.conclusion,
        ),
    ],
  );
}
