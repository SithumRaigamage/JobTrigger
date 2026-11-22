import 'dart:typed_data';

import '../student/student_application.dart';

/// US-STU-02/03: one student application as the super admin sees it
/// (`GET /api/admin/students`, `docs/api-reference.md`). Never holds the
/// document itself; that is [AdminStudentDocument], fetched on its own.
class AdminStudentApplication {
  const AdminStudentApplication({
    required this.id,
    required this.method,
    required this.status,
    required this.submittedAt,
    this.accountEmail,
    this.fullName,
    this.universityEmail,
    this.emailVerifiedAt,
    this.reviewedAt,
    this.reviewedByEmail,
    this.approvedAt,
    this.expiresAt,
    this.rejectionReason,
    this.documentMime,
    this.hasDocument = false,
    this.documentDeleted = false,
  });

  final String id;
  final StudentMethod method;

  /// Never [StudentStatus.none] here.
  final StudentStatus status;
  final DateTime submittedAt;

  /// Null once the student deleted their account.
  final String? accountEmail;

  /// Document method: the name on the ID (deleted with the document).
  final String? fullName;
  final String? universityEmail;
  final DateTime? emailVerifiedAt;
  final DateTime? reviewedAt;

  /// Who decided it; null while undecided or once that account is gone.
  final String? reviewedByEmail;
  final DateTime? approvedAt;
  final DateTime? expiresAt;
  final String? rejectionReason;
  final String? documentMime;
  final bool hasDocument;

  /// The bytes were deleted 30 days after the decision.
  final bool documentDeleted;

  bool get isPending => status == StudentStatus.pending;

  /// The line a list shows first: the name on the ID, or the university email.
  String get title => switch (method) {
    StudentMethod.email => universityEmail ?? '(email deleted)',
    StudentMethod.document => fullName ?? '(name deleted)',
  };
}

/// The uploaded student ID or letter, in memory only.
class AdminStudentDocument {
  const AdminStudentDocument({required this.mime, required this.bytes});

  final String mime;
  final Uint8List bytes;

  bool get isPdf => mime == 'application/pdf';
  bool get isImage => mime == 'image/jpeg' || mime == 'image/png';
}

/// The history filters (US-STU-03), in the backend's words.
enum AdminStatusFilter {
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected'),
  expired('expired', 'Ended'),
  all('all', 'All');

  const AdminStatusFilter(this.query, this.label);

  final String query;
  final String label;
}
