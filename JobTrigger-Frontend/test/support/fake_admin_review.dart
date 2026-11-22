import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/domain/admin_review/admin_review_repository.dart';
import 'package:job_trigger/domain/admin_review/admin_student_application.dart';
import 'package:job_trigger/domain/student/student_application.dart';

/// A pending email application (US-STU-01).
final pendingEmail = AdminStudentApplication(
  id: 'e1',
  method: StudentMethod.email,
  status: StudentStatus.pending,
  submittedAt: DateTime.utc(2026, 11, 20, 10),
  accountEmail: 'kasun@example.com',
  universityEmail: 'kasun@uom.ac.lk',
  emailVerifiedAt: DateTime.utc(2026, 11, 20, 10, 5),
);

/// A pending document application with an image.
final pendingDocument = AdminStudentApplication(
  id: 'd1',
  method: StudentMethod.document,
  status: StudentStatus.pending,
  submittedAt: DateTime.utc(2026, 11, 21, 9),
  accountEmail: 'amal@example.com',
  fullName: 'Amal Fernando',
  documentMime: 'image/png',
  hasDocument: true,
);

AdminStudentApplication decided(
  AdminStudentApplication item,
  StudentStatus status, {
  String? reason,
}) => AdminStudentApplication(
  id: item.id,
  method: item.method,
  status: status,
  submittedAt: item.submittedAt,
  accountEmail: item.accountEmail,
  fullName: item.fullName,
  universityEmail: item.universityEmail,
  emailVerifiedAt: item.emailVerifiedAt,
  reviewedAt: DateTime.utc(2026, 11, 22, 8),
  reviewedByEmail: 'developer@jobtrigger.app',
  approvedAt: status == StudentStatus.approved
      ? DateTime.utc(2026, 11, 22, 8)
      : null,
  expiresAt: status == StudentStatus.approved
      ? DateTime.utc(2027, 11, 22, 8)
      : null,
  rejectionReason: reason,
  documentMime: item.documentMime,
  hasDocument: item.hasDocument,
);

class FakeAdminReviewRepository implements AdminReviewRepository {
  FakeAdminReviewRepository({
    this.access = const Ok(true),
    Map<AdminStatusFilter, Result<List<AdminStudentApplication>, AppFailure>>?
    lists,
    Map<String, AdminStudentApplication>? items,
  }) : lists = lists ?? {},
       items = items ?? {};

  Result<bool, AppFailure> access;
  final Map<
    AdminStatusFilter,
    Result<List<AdminStudentApplication>, AppFailure>
  >
  lists;
  final Map<String, AdminStudentApplication> items;
  Result<AdminStudentDocument?, AppFailure> documentResult = const Ok(null);
  Result<AdminStudentApplication, AppFailure>? approveResult;
  Result<AdminStudentApplication, AppFailure>? rejectResult;

  int accessCalls = 0;
  final listed = <AdminStatusFilter>[];
  final approved = <String>[];
  final rejected = <({String id, String reason})>[];
  final documents = <String>[];

  @override
  Future<Result<bool, AppFailure>> hasAccess() async {
    accessCalls++;
    return access;
  }

  @override
  Future<Result<List<AdminStudentApplication>, AppFailure>> list(
    AdminStatusFilter filter,
  ) async {
    listed.add(filter);
    return lists[filter] ?? const Ok([]);
  }

  @override
  Future<Result<AdminStudentApplication, AppFailure>> get(String id) async {
    final item = items[id];
    return item == null ? const Err(NotFoundFailure()) : Ok(item);
  }

  @override
  Future<Result<AdminStudentDocument?, AppFailure>> document(String id) async {
    documents.add(id);
    return documentResult;
  }

  @override
  Future<Result<AdminStudentApplication, AppFailure>> approve(String id) async {
    approved.add(id);
    return approveResult ?? Ok(decided(items[id]!, StudentStatus.approved));
  }

  @override
  Future<Result<AdminStudentApplication, AppFailure>> reject(
    String id,
    String reason,
  ) async {
    rejected.add((id: id, reason: reason));
    return rejectResult ??
        Ok(decided(items[id]!, StudentStatus.rejected, reason: reason));
  }
}
