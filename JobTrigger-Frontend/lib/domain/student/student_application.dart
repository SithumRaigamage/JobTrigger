/// Phase 21 (SP-4): the signed-in user's student-plan application, as the
/// backend reports it (`GET /api/student`, `docs/api-reference.md`).
enum StudentStatus { none, pending, approved, rejected, expired }

/// How the student proved it: a code sent to a university email, or an
/// uploaded student ID / enrolment letter reviewed by hand.
enum StudentMethod { email, document }

class StudentApplication {
  const StudentApplication({
    required this.status,
    this.method,
    this.universityEmail,
    this.rejectionReason,
    this.approvedAt,
    this.expiresAt,
  });

  static const none = StudentApplication(status: StudentStatus.none);

  final StudentStatus status;
  final StudentMethod? method;
  final String? universityEmail;

  /// Why a document was refused, in the reviewer's words.
  final String? rejectionReason;
  final DateTime? approvedAt;

  /// When the free year ends.
  final DateTime? expiresAt;

  /// [status] with the date applied: an approved year past its end reads as
  /// expired even before the backend's daily job marks it so.
  StudentStatus statusAt(DateTime now) =>
      status == StudentStatus.approved &&
          expiresAt != null &&
          !expiresAt!.isAfter(now)
      ? StudentStatus.expired
      : status;
}
