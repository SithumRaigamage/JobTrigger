import 'package:freezed_annotation/freezed_annotation.dart';

import 'jenkins_job_dto.dart';

part 'jenkins_server_info_dto.freezed.dart';
part 'jenkins_server_info_dto.g.dart';

/// The root `/api/json` response shape. `jobs` uses `@Default([])` here
/// (unlike `JenkinsJobDto.jobs`) because this is the top-level server info,
/// not a job — there's no "is this a folder" ambiguity to preserve at this
/// level, and an absent `jobs` key here should just mean "no jobs."
@freezed
abstract class JenkinsServerInfoDto with _$JenkinsServerInfoDto {
  const factory JenkinsServerInfoDto({
    String? mode,
    String? nodeDescription,
    int? numExecutors,
    bool? useSecurity,
    @Default([]) List<JenkinsJobDto> jobs,
  }) = _JenkinsServerInfoDto;

  factory JenkinsServerInfoDto.fromJson(Map<String, dynamic> json) =>
      _$JenkinsServerInfoDtoFromJson(json);
}
