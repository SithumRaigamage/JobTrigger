// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StudentApplicationDto _$StudentApplicationDtoFromJson(
  Map<String, dynamic> json,
) => _StudentApplicationDto(
  status: json['status'] as String,
  method: json['method'] as String?,
  universityEmail: json['universityEmail'] as String?,
  rejectionReason: json['rejectionReason'] as String?,
  approvedAt: json['approvedAt'] as String?,
  expiresAt: json['expiresAt'] as String?,
);

Map<String, dynamic> _$StudentApplicationDtoToJson(
  _StudentApplicationDto instance,
) => <String, dynamic>{
  'status': instance.status,
  'method': instance.method,
  'universityEmail': instance.universityEmail,
  'rejectionReason': instance.rejectionReason,
  'approvedAt': instance.approvedAt,
  'expiresAt': instance.expiresAt,
};
