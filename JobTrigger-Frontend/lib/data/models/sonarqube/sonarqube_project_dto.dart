import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/sonarqube/sonarqube_project.dart';

part 'sonarqube_project_dto.freezed.dart';
part 'sonarqube_project_dto.g.dart';

/// One entry of `GET api/projects/search`'s `components[]`.
@freezed
abstract class SonarQubeProjectDto with _$SonarQubeProjectDto {
  const factory SonarQubeProjectDto({
    required String key,
    @Default('') String name,
    String? lastAnalysisDate,
  }) = _SonarQubeProjectDto;

  factory SonarQubeProjectDto.fromJson(Map<String, dynamic> json) =>
      _$SonarQubeProjectDtoFromJson(json);
}

extension SonarQubeProjectDtoX on SonarQubeProjectDto {
  SonarQubeProject toDomain() => SonarQubeProject(
    key: key,
    // A project always has a name; fall back to the key rather than show a
    // blank row if the server ever omits it.
    name: name.isEmpty ? key : name,
    lastAnalysisDate: lastAnalysisDate == null
        ? null
        : _parseSonarDate(lastAnalysisDate!),
  );
}

/// SonarQube writes `2026-11-08T10:00:00+0000`, an offset without a colon.
/// Dart's parser takes that form; a value it can't read is "no date" rather
/// than a crash that would hide the whole project list.
DateTime? _parseSonarDate(String raw) => DateTime.tryParse(raw);
