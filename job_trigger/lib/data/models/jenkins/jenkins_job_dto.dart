import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/jenkins/jenkins_job.dart';
import 'health_report_dto.dart';
import 'jenkins_build_dto.dart';
import 'job_property_dto.dart';

part 'jenkins_job_dto.freezed.dart';
part 'jenkins_job_dto.g.dart';

/// `jobs` is deliberately plain-nullable, **not** `@Default([])` (the
/// literal sample in `docs/data-models.md` uses `@Default([])` on a
/// nullable field, which is a bug): verified against a real recursive tree
/// fetch (`test/fixtures/jenkins_tree_fixture.json`) that Jenkins omits the
/// `jobs` key entirely for leaf jobs and always includes it (possibly `[]`)
/// for folders. `isFolder` (see `domain/jenkins/jenkins_job.dart`) depends
/// on that null-vs-empty distinction surviving — `@Default([])` would
/// silently turn every leaf job into a "folder" with zero children.
@freezed
abstract class JenkinsJobDto with _$JenkinsJobDto {
  const factory JenkinsJobDto({
    required String name,
    required String url,
    String? description,
    String? color,
    List<JenkinsJobDto>? jobs, // nested folders — see the null-vs-[] note above
    JenkinsBuildDto? lastBuild,
    @Default([]) List<HealthReportDto>? healthReport,
    @Default([]) List<JobPropertyDto>? property, // holds parameterDefinitions
    @Default([]) List<JenkinsBuildDto>? builds,
  }) = _JenkinsJobDto;

  factory JenkinsJobDto.fromJson(Map<String, dynamic> json) =>
      _$JenkinsJobDtoFromJson(json);
}

extension JenkinsJobDtoX on JenkinsJobDto {
  JenkinsJob toDomain() => JenkinsJob(
    name: name,
    url: url,
    description: description,
    color: color,
    jobs: jobs?.map((dto) => dto.toDomain()).toList(),
    lastBuild: lastBuild?.toDomain(),
    healthReport: (healthReport ?? const [])
        .map((dto) => dto.toDomain())
        .toList(),
    property: (property ?? const []).map((dto) => dto.toDomain()).toList(),
    builds: (builds ?? const []).map((dto) => dto.toDomain()).toList(),
  );
}
