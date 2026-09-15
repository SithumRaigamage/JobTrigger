import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/jenkins/pending_input.dart';
import 'parameter_definition_dto.dart';

part 'pending_input_dto.freezed.dart';
part 'pending_input_dto.g.dart';

/// One entry of `GET {buildURL}wfapi/pendingInputActions` (US-PIPE-05).
/// See `pending_input.dart`'s doc comment — this shape is unverified
/// against a real paused pipeline.
@freezed
abstract class PendingInputDto with _$PendingInputDto {
  const factory PendingInputDto({
    required String id,
    String? message,
    @Default('Proceed') String proceedText,
    @Default('Abort') String abortText,
    @Default(<ParameterDefinitionDto>[]) List<ParameterDefinitionDto> inputs,
  }) = _PendingInputDto;

  factory PendingInputDto.fromJson(Map<String, dynamic> json) =>
      _$PendingInputDtoFromJson(json);
}

extension PendingInputDtoX on PendingInputDto {
  PendingInput toDomain() => PendingInput(
    id: id,
    message: message,
    proceedText: proceedText,
    abortText: abortText,
    inputs: inputs.map((i) => i.toDomain()).toList(),
  );
}
