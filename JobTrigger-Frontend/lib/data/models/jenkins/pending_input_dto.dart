import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/jenkins/parameter_definition.dart';
import '../../../domain/jenkins/pending_input.dart';

part 'pending_input_dto.freezed.dart';
part 'pending_input_dto.g.dart';

/// One entry of `GET {buildURL}wfapi/pendingInputActions` (US-PIPE-05).
/// Shape verified against a real paused pipeline on the fixture Jenkins
/// (P11-02; recorded in `test/fixtures/jenkins_pending_input_params.json`).
/// Jenkins sends no `abortText` — the default below is what its own UI
/// shows.
@freezed
abstract class PendingInputDto with _$PendingInputDto {
  const factory PendingInputDto({
    required String id,
    String? message,
    @Default('Proceed') String proceedText,
    @Default('Abort') String abortText,
    @Default(<PendingInputParameterDto>[])
    List<PendingInputParameterDto> inputs,
  }) = _PendingInputDto;

  factory PendingInputDto.fromJson(Map<String, dynamic> json) =>
      _$PendingInputDtoFromJson(json);
}

/// An input step's requested parameter. **Not** the same shape as a job's
/// `parameterDefinitions` (`ParameterDefinitionDto`): the default and the
/// choices are nested under `definition` as `defaultVal`/`choices`, rather
/// than `defaultParameterValue.value`/`choices` at the top level. P7-07
/// assumed the job shape, which left choice parameters with no options —
/// found by P11-02's real-server verification.
@freezed
abstract class PendingInputParameterDto with _$PendingInputParameterDto {
  const factory PendingInputParameterDto({
    required String name,
    required String type,
    String? description,
    PendingInputParameterDefinitionDto? definition,
  }) = _PendingInputParameterDto;

  factory PendingInputParameterDto.fromJson(Map<String, dynamic> json) =>
      _$PendingInputParameterDtoFromJson(json);
}

@freezed
abstract class PendingInputParameterDefinitionDto
    with _$PendingInputParameterDefinitionDto {
  const factory PendingInputParameterDefinitionDto({
    // Polymorphic (string/bool/number) by parameter type, like
    // `ParameterDefinitionDto.defaultValue`.
    dynamic defaultVal,
    List<String>? choices,
  }) = _PendingInputParameterDefinitionDto;

  factory PendingInputParameterDefinitionDto.fromJson(
    Map<String, dynamic> json,
  ) => _$PendingInputParameterDefinitionDtoFromJson(json);
}

extension PendingInputParameterDtoX on PendingInputParameterDto {
  ParameterDefinition toDomain() => ParameterDefinition(
    name: name,
    type: type,
    description: description,
    choices: definition?.choices,
    defaultValue: definition?.defaultVal,
  );
}

extension PendingInputDtoX on PendingInputDto {
  PendingInput toDomain() => PendingInput(
    id: id,
    message: message,
    proceedText: proceedText,
    abortText: abortText,
    inputs: inputs.map((input) => input.toDomain()).toList(),
  );
}
