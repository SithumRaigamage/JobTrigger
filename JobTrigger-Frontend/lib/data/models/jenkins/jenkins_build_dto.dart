import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/jenkins/jenkins_build.dart';

part 'jenkins_build_dto.freezed.dart';
part 'jenkins_build_dto.g.dart';

/// Unified for both `lastBuild` (on `JenkinsJobDto`) and `builds[]` (job
/// history) — `docs/data-models.md` calls these `BuildSummary`/`JenkinsBuild`
/// in the old app, but the fields are the same shape, so one DTO covers
/// both rather than duplicating.
@freezed
abstract class JenkinsBuildDto with _$JenkinsBuildDto {
  const factory JenkinsBuildDto({
    required int number,
    required String url,
    String? result, // SUCCESS | FAILURE | ABORTED | UNSTABLE | null (building)
    required double timestamp, // epoch ms
    double? duration,
    double? estimatedDuration,
    @Default(false) bool building,
    String? displayName,
  }) = _JenkinsBuildDto;

  factory JenkinsBuildDto.fromJson(Map<String, dynamic> json) =>
      _$JenkinsBuildDtoFromJson(json);
}

extension JenkinsBuildDtoX on JenkinsBuildDto {
  JenkinsBuild toDomain() => JenkinsBuild(
    number: number,
    url: url,
    result: result,
    timestamp: timestamp,
    duration: duration,
    estimatedDuration: estimatedDuration,
    building: building,
    displayName: displayName,
  );
}
