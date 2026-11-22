import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../domain/admin_review/admin_review_repository.dart';
import '../../domain/admin_review/admin_student_application.dart';

/// E2 / US-STU-02: demo mode is never a super admin, so the review screen
/// never shows and nothing here reaches the backend.
class DemoAdminReviewRepository implements AdminReviewRepository {
  const DemoAdminReviewRepository();

  @override
  Future<Result<bool, AppFailure>> hasAccess() async => const Ok(false);

  @override
  Future<Result<List<AdminStudentApplication>, AppFailure>> list(
    AdminStatusFilter filter,
  ) async => const Err(DemoUnavailableFailure());

  @override
  Future<Result<AdminStudentApplication, AppFailure>> get(String id) async =>
      const Err(DemoUnavailableFailure());

  @override
  Future<Result<AdminStudentDocument?, AppFailure>> document(String id) async =>
      const Err(DemoUnavailableFailure());

  @override
  Future<Result<AdminStudentApplication, AppFailure>> approve(
    String id,
  ) async => const Err(DemoUnavailableFailure());

  @override
  Future<Result<AdminStudentApplication, AppFailure>> reject(
    String id,
    String reason,
  ) async => const Err(DemoUnavailableFailure());
}

const demoAdminReviewRepository = DemoAdminReviewRepository();
