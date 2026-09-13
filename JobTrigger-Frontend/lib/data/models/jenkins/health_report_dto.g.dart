// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_report_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HealthReportDto _$HealthReportDtoFromJson(Map<String, dynamic> json) =>
    _HealthReportDto(
      description: json['description'] as String?,
      iconClassName: json['iconClassName'] as String?,
      score: (json['score'] as num?)?.toInt(),
    );

Map<String, dynamic> _$HealthReportDtoToJson(_HealthReportDto instance) =>
    <String, dynamic>{
      'description': instance.description,
      'iconClassName': instance.iconClassName,
      'score': instance.score,
    };
