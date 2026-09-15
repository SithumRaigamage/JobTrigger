import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/jenkins/job_property.dart';
import 'parameter_definition_dto.dart';

part 'job_property_dto.freezed.dart';
part 'job_property_dto.g.dart';

@freezed
abstract class JobPropertyDto with _$JobPropertyDto {
  const factory JobPropertyDto({
    List<ParameterDefinitionDto>? parameterDefinitions,
  }) = _JobPropertyDto;

  factory JobPropertyDto.fromJson(Map<String, dynamic> json) =>
      _$JobPropertyDtoFromJson(json);
}

extension JobPropertyDtoX on JobPropertyDto {
  JobProperty toDomain() => JobProperty(
    parameterDefinitions: parameterDefinitions
        ?.map((dto) => dto.toDomain())
        .toList(),
  );
}
