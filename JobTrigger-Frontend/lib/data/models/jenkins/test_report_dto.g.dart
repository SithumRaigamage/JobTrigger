// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_report_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TestReportDto _$TestReportDtoFromJson(Map<String, dynamic> json) =>
    _TestReportDto(
      passCount: (json['passCount'] as num?)?.toInt() ?? 0,
      failCount: (json['failCount'] as num?)?.toInt() ?? 0,
      skipCount: (json['skipCount'] as num?)?.toInt() ?? 0,
      failingTests: json['suites'] == null
          ? const <String>[]
          : _failingTestsFromJson(json['suites']),
    );

Map<String, dynamic> _$TestReportDtoToJson(_TestReportDto instance) =>
    <String, dynamic>{
      'passCount': instance.passCount,
      'failCount': instance.failCount,
      'skipCount': instance.skipCount,
    };
