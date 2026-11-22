import '../../../domain/admin_review/admin_student_application.dart';
import '../../../domain/student/student_application.dart';
import '../student/student_verification_screen.dart' show formatStudentDate;

/// Shared words for the review screens (US-STU-02/03).
String methodLabel(StudentMethod method) => switch (method) {
  StudentMethod.email => 'University email',
  StudentMethod.document => 'Student ID / letter',
};

String statusLabel(StudentStatus status) => switch (status) {
  StudentStatus.pending => 'Pending',
  StudentStatus.approved => 'Approved',
  StudentStatus.rejected => 'Rejected',
  StudentStatus.expired => 'Ended',
  StudentStatus.none => '',
};

/// "Decided 18 Nov 2026 by developer@jobtrigger.app", or null while undecided.
String? decisionLine(AdminStudentApplication item) {
  final at = item.reviewedAt;
  if (at == null) return null;
  return 'Decided ${formatStudentDate(at)} by '
      '${item.reviewedByEmail ?? '(account deleted)'}';
}
