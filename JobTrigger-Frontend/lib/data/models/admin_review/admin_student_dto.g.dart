// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_student_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminStudentDto _$AdminStudentDtoFromJson(Map<String, dynamic> json) =>
    _AdminStudentDto(
      id: json['id'] as String,
      method: json['method'] as String,
      status: json['status'] as String,
      submittedAt: json['submittedAt'] as String,
      accountEmail: json['accountEmail'] as String?,
      fullName: json['fullName'] as String?,
      universityEmail: json['universityEmail'] as String?,
      emailVerifiedAt: json['emailVerifiedAt'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
      reviewedByEmail: json['reviewedByEmail'] as String?,
      approvedAt: json['approvedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      documentMime: json['documentMime'] as String?,
      hasDocument: json['hasDocument'] as bool? ?? false,
      documentDeleted: json['documentDeleted'] as bool? ?? false,
    );

Map<String, dynamic> _$AdminStudentDtoToJson(_AdminStudentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'method': instance.method,
      'status': instance.status,
      'submittedAt': instance.submittedAt,
      'accountEmail': instance.accountEmail,
      'fullName': instance.fullName,
      'universityEmail': instance.universityEmail,
      'emailVerifiedAt': instance.emailVerifiedAt,
      'reviewedAt': instance.reviewedAt,
      'reviewedByEmail': instance.reviewedByEmail,
      'approvedAt': instance.approvedAt,
      'expiresAt': instance.expiresAt,
      'rejectionReason': instance.rejectionReason,
      'documentMime': instance.documentMime,
      'hasDocument': instance.hasDocument,
      'documentDeleted': instance.documentDeleted,
    };
