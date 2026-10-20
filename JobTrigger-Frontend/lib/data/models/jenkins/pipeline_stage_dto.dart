import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/jenkins/pipeline_stage.dart';

part 'pipeline_stage_dto.freezed.dart';
part 'pipeline_stage_dto.g.dart';

/// `{buildURL}wfapi/describe` (US-PIPE-04). Shapes verified on the fixture
/// Jenkins (P11-08).
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
    int? startTimeMillis,
    PipelineErrorDto? error,
    // Present on `execution/node/{id}/wfapi/describe`, absent on the
    // build-level describe.
    @Default(<PipelineStepDto>[]) List<PipelineStepDto> stageFlowNodes,
  }) = _PipelineStageDto;

  factory PipelineStageDto.fromJson(Map<String, dynamic> json) =>
      _$PipelineStageDtoFromJson(json);
}

@freezed
abstract class PipelineErrorDto with _$PipelineErrorDto {
  const factory PipelineErrorDto({String? message}) = _PipelineErrorDto;

  factory PipelineErrorDto.fromJson(Map<String, dynamic> json) =>
      _$PipelineErrorDtoFromJson(json);
}

@freezed
abstract class PipelineStepDto with _$PipelineStepDto {
  const factory PipelineStepDto({
    required String id,
    required String name,
    required String status,
    String? parameterDescription,
    int? durationMillis,
  }) = _PipelineStepDto;

  factory PipelineStepDto.fromJson(Map<String, dynamic> json) =>
      _$PipelineStepDtoFromJson(json);
}

/// `execution/node/{id}/wfapi/log`. `text` is absent when the log is empty.
@freezed
abstract class StepLogDto with _$StepLogDto {
  const factory StepLogDto({
    @Default('') String text,
    @Default(false) bool hasMore,
  }) = _StepLogDto;

  factory StepLogDto.fromJson(Map<String, dynamic> json) =>
      _$StepLogDtoFromJson(json);
}

extension PipelineStageDtoX on PipelineStageDto {
  PipelineStage toDomain() => PipelineStage(
    id: id,
    name: name,
    status: status,
    durationMillis: durationMillis,
    startTimeMillis: startTimeMillis,
    errorMessage: error?.message,
  );

  List<PipelineStep> stepsToDomain() => [
    for (final step in stageFlowNodes)
      PipelineStep(
        id: step.id,
        name: step.name,
        status: step.status,
        description: step.parameterDescription,
        durationMillis: step.durationMillis,
      ),
  ];
}

extension PipelineDescribeDtoX on PipelineDescribeDto {
  List<PipelineStage> toDomain() => [
    for (final stage in stages) stage.toDomain(),
  ];
}

extension StepLogDtoX on StepLogDto {
  StepLog toDomain() => StepLog(text: text, hasMore: hasMore);
}
