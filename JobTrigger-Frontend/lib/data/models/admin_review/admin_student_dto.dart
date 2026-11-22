import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/admin_review/admin_student_application.dart';
import '../../../domain/student/student_application.dart';

part 'admin_student_dto.freezed.dart';
part 'admin_student_dto.g.dart';

/// Mirrors one item of `GET /api/admin/students` (`docs/api-reference.md`).
/// The review fields are optional so an older backend still parses.
@freezed
abstract class AdminStudentDto with _$AdminStudentDto {
  const factory AdminStudentDto({
    required String id,
    required String method,
    required String status,
    required String submittedAt,
    String? accountEmail,
    String? fullName,
    String? universityEmail,
    String? emailVerifiedAt,
    String? reviewedAt,
    String? reviewedByEmail,
    String? approvedAt,
    String? expiresAt,
    String? rejectionReason,
    String? documentMime,
    @Default(false) bool hasDocument,
    @Default(false) bool documentDeleted,
  }) = _AdminStudentDto;

  factory AdminStudentDto.fromJson(Map<String, dynamic> json) =>
      _$AdminStudentDtoFromJson(json);
}

DateTime? _date(String? value) =>
    value == null ? null : DateTime.tryParse(value);

extension AdminStudentDtoX on AdminStudentDto {
  AdminStudentApplication toDomain() => AdminStudentApplication(
    id: id,
    method: method == 'email' ? StudentMethod.email : StudentMethod.document,
    status: switch (status) {
      'approved' => StudentStatus.approved,
      'rejected' => StudentStatus.rejected,
      'expired' => StudentStatus.expired,
      _ => StudentStatus.pending,
    },
    submittedAt: DateTime.parse(submittedAt),
    accountEmail: accountEmail,
    fullName: fullName,
    universityEmail: universityEmail,
    emailVerifiedAt: _date(emailVerifiedAt),
    reviewedAt: _date(reviewedAt),
    reviewedByEmail: reviewedByEmail,
    approvedAt: _date(approvedAt),
    expiresAt: _date(expiresAt),
    rejectionReason: rejectionReason,
    documentMime: documentMime,
    hasDocument: hasDocument,
    documentDeleted: documentDeleted,
  );
}
