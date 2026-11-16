import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/student/student_document.dart';

part 'student_document_picker.g.dart';

/// A file the user chose, not yet read: the checks look at the name and size
/// first, so an oversized file is never loaded into memory.
class PickedStudentFile {
  const PickedStudentFile({
    required this.name,
    required this.sizeBytes,
    required this.read,
  });

  final String name;
  final int sizeBytes;
  final Future<Uint8List> Function() read;
}

/// Opens the platform file picker for a JPG, PNG or PDF, or returns null if
/// the user cancelled. A provider so tests can substitute it. Uses the
/// already-approved `file_picker` (no camera package).
typedef StudentDocumentPicker = Future<PickedStudentFile?> Function();

@riverpod
StudentDocumentPicker studentDocumentPicker(Ref ref) => () async {
  final picked = await FilePicker.pickFile(
    dialogTitle: 'Choose your student ID or enrolment letter',
    allowedExtensions: studentDocumentExtensions,
  );
  if (picked == null) return null;
  return PickedStudentFile(
    name: picked.name,
    sizeBytes: await picked.length() ?? 0,
    read: picked.readAsBytes,
  );
};
