import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/jenkins/pipeline_stage.dart';

part 'pipeline_stage_dto.freezed.dart';
part 'pipeline_stage_dto.g.dart';

/// `GET {buildURL}wfapi/describe` (US-PIPE-04) — the Pipeline: REST API
/// plugin's build description. Only `stages` is used; the rest of the
/// response (`_links`, overall `status`/timing, already covered by
/// `JenkinsBuildDto`) is left unparsed.
@freezed
abstract class PipelineDescribeDto with _$PipelineDescribeDto {
  const factory PipelineDescribeDto({
    @Default(<PipelineStageDto>[]) List<PipelineStageDto> stages,
  }) = _PipelineDescribeDto;

  factory PipelineDescribeDto.fromJson(Map<String, dynamic> json) =>
      _$PipelineDescribeDtoFromJson(json);
}

@freezed
abstract class PipelineStageDto with _$PipelineStageDto {
  const factory PipelineStageDto({
    required String id,
    required String name,
    required String status,
    int? durationMillis,
  }) = _PipelineStageDto;

  factory PipelineStageDto.fromJson(Map<String, dynamic> json) =>
      _$PipelineStageDtoFromJson(json);
}

extension PipelineDescribeDtoX on PipelineDescribeDto {
  List<PipelineStage> toDomain() => stages
      .map(
        (s) => PipelineStage(
          id: s.id,
          name: s.name,
          status: s.status,
          durationMillis: s.durationMillis,
        ),
      )
      .toList();
}
