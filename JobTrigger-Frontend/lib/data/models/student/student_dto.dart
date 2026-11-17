import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/student/student_application.dart';

part 'student_dto.freezed.dart';
part 'student_dto.g.dart';

/// Mirrors `GET /api/student` and the bodies of the confirm and upload
/// calls (`docs/api-reference.md`).
@freezed
abstract class StudentApplicationDto with _$StudentApplicationDto {
  const factory StudentApplicationDto({
    required String status,
    String? method,
    String? universityEmail,
    String? rejectionReason,
    String? approvedAt,
    String? expiresAt,
  }) = _StudentApplicationDto;

  factory StudentApplicationDto.fromJson(Map<String, dynamic> json) =>
      _$StudentApplicationDtoFromJson(json);
}

extension StudentApplicationDtoX on StudentApplicationDto {
  StudentApplication toDomain() => StudentApplication(
    status: switch (status) {
      'pending' => StudentStatus.pending,
      'approved' => StudentStatus.approved,
      'rejected' => StudentStatus.rejected,
      'expired' => StudentStatus.expired,
      _ => StudentStatus.none,
    },
    method: switch (method) {
      'email' => StudentMethod.email,
      'document' => StudentMethod.document,
      _ => null,
    },
    universityEmail: universityEmail,
    rejectionReason: rejectionReason,
    approvedAt: approvedAt == null ? null : DateTime.tryParse(approvedAt!),
    expiresAt: expiresAt == null ? null : DateTime.tryParse(expiresAt!),
  );
}
