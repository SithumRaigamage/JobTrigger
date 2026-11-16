import 'dart:typed_data';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../../domain/student/student_application.dart';
import '../../domain/student/student_repository.dart';

/// E2 / Phase 21: demo mode is read-only. There is no application, and
/// nothing can be started or sent.
class DemoStudentRepository implements StudentRepository {
  const DemoStudentRepository();

  @override
  Future<Result<StudentApplication, AppFailure>> status() async =>
      const Ok(StudentApplication.none);

  @override
  Future<Result<void, AppFailure>> startEmail(String universityEmail) async =>
      const Err(DemoUnavailableFailure());

  @override
  Future<Result<StudentApplication, AppFailure>> confirmEmail(
    String code,
  ) async => const Err(DemoUnavailableFailure());

  @override
  Future<Result<StudentApplication, AppFailure>> uploadDocument({
    required String fullName,
    required Uint8List bytes,
  }) async => const Err(DemoUnavailableFailure());
}

const demoStudentRepository = DemoStudentRepository();
