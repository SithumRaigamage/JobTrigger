import 'dart:typed_data';

import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/domain/student/student_application.dart';
import 'package:job_trigger/domain/student/student_repository.dart';
import 'package:job_trigger/presentation/features/student/student_document_picker.dart';

class FakeStudentRepository implements StudentRepository {
  FakeStudentRepository({
    this.statusResult = const Ok(StudentApplication.none),
  });

  Result<StudentApplication, AppFailure> statusResult;
  Result<void, AppFailure> startResult = const Ok(null);
  Result<StudentApplication, AppFailure> confirmResult = const Ok(
    StudentApplication(status: StudentStatus.approved),
  );
  Result<StudentApplication, AppFailure> uploadResult = const Ok(
    StudentApplication(
      status: StudentStatus.pending,
      method: StudentMethod.document,
    ),
  );

  final started = <String>[];
  final confirmed = <String>[];
  final uploads = <({String fullName, int bytes})>[];
  int statusCalls = 0;

  @override
  Future<Result<StudentApplication, AppFailure>> status() async {
    statusCalls++;
    return statusResult;
  }

  @override
  Future<Result<void, AppFailure>> startEmail(String universityEmail) async {
    started.add(universityEmail);
    return startResult;
  }

  @override
  Future<Result<StudentApplication, AppFailure>> confirmEmail(
    String code,
  ) async {
    confirmed.add(code);
    return confirmResult;
  }

  @override
  Future<Result<StudentApplication, AppFailure>> uploadDocument({
    required String fullName,
    required Uint8List bytes,
  }) async {
    uploads.add((fullName: fullName, bytes: bytes.length));
    return uploadResult;
  }
}

/// A picked file, with real leading bytes for a PNG.
PickedStudentFile pickedFile(String name, {int? size, Uint8List? bytes}) {
  final data =
      bytes ??
      Uint8List.fromList([
        0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 1, 2, 3, //
      ]);
  return PickedStudentFile(
    name: name,
    sizeBytes: size ?? data.length,
    read: () async => data,
  );
}
