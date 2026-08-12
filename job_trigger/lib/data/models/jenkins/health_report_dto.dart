import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/jenkins/health_report.dart';

part 'health_report_dto.freezed.dart';
part 'health_report_dto.g.dart';

@freezed
abstract class HealthReportDto with _$HealthReportDto {
  const factory HealthReportDto({
    String? description,
    String? iconClassName,
    int? score,
  }) = _HealthReportDto;

  factory HealthReportDto.fromJson(Map<String, dynamic> json) =>
      _$HealthReportDtoFromJson(json);
}

extension HealthReportDtoX on HealthReportDto {
  HealthReport toDomain() => HealthReport(
    description: description,
    iconClassName: iconClassName,
    score: score,
  );
}
