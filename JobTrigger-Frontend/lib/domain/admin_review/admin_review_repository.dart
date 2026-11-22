import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'admin_student_application.dart';

/// US-STU-02/03: the super admin's student-review calls
/// (`/api/admin/students`). The backend checks the role on every call and
/// answers anyone else with its plain 404. A refused decision (already
/// decided, email or document used) is a `StudentRequestFailure` carrying
/// the backend's sentence.
abstract class AdminReviewRepository {
  /// `GET /api/admin/students/access`: true for a super admin, false for
  /// everyone else (the 404).
  Future<Result<bool, AppFailure>> hasAccess();

  /// `GET /api/admin/students?status=`: newest first, both methods.
  Future<Result<List<AdminStudentApplication>, AppFailure>> list(
    AdminStatusFilter filter,
  );

  /// `GET /api/admin/students/:id`.
  Future<Result<AdminStudentApplication, AppFailure>> get(String id);

  /// `GET /api/admin/students/:id/document`: the bytes, held in memory only.
  /// `Ok(null)` once the file was deleted (410).
  Future<Result<AdminStudentDocument?, AppFailure>> document(String id);

  /// `POST /api/admin/students/:id/approve`: grants the 365 days.
  Future<Result<AdminStudentApplication, AppFailure>> approve(String id);

  /// `POST /api/admin/students/:id/reject` with the reason the student sees.
  Future<Result<AdminStudentApplication, AppFailure>> reject(
    String id,
    String reason,
  );
}
