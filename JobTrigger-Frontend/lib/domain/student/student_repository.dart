import 'dart:typed_data';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import 'student_application.dart';

/// Phase 21: the backend's student-plan calls. A failure that carries the
/// backend's own explanation is a `StudentRequestFailure`.
abstract class StudentRepository {
  /// `GET /api/student`: the latest application, or [StudentApplication.none].
  Future<Result<StudentApplication, AppFailure>> status();

  /// `POST /api/student/email/start`: emails a 6-digit code. A domain that is
  /// not on the list is a failure with `isDomainNotListed`.
  Future<Result<void, AppFailure>> startEmail(String universityEmail);

  /// `POST /api/student/email/confirm`: the right code grants the year at
  /// once and returns the approved application.
  Future<Result<StudentApplication, AppFailure>> confirmEmail(String code);

  /// `POST /api/student/document`: a student ID or enrolment letter for
  /// review, with the name as printed on it.
  Future<Result<StudentApplication, AppFailure>> uploadDocument({
    required String fullName,
    required Uint8List bytes,
  });
}
