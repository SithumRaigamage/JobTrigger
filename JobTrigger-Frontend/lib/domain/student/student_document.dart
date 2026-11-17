import 'dart:typed_data';

/// Phase 21 (SP-41): the checks a student document passes on the phone
/// before it is sent, matching the backend (`lib/studentDocument.js`), which
/// repeats them. Catching a wrong file here saves a slow upload.
const maxStudentDocumentBytes = 5 * 1024 * 1024;

/// Extensions the picker offers and the check accepts (lower case).
const studentDocumentExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

enum StudentDocumentProblem { empty, tooLarge, wrongType }

/// Cheap check from the name and size alone, before the file is read.
StudentDocumentProblem? checkStudentDocumentMeta({
  required String fileName,
  required int sizeBytes,
}) {
  if (sizeBytes <= 0) return StudentDocumentProblem.empty;
  if (sizeBytes > maxStudentDocumentBytes) {
    return StudentDocumentProblem.tooLarge;
  }
  final dot = fileName.lastIndexOf('.');
  final extension = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  if (!studentDocumentExtensions.contains(extension)) {
    return StudentDocumentProblem.wrongType;
  }
  return null;
}

/// True when [bytes] start like a JPG, a PNG or a PDF (the name can lie).
bool looksLikeStudentDocument(Uint8List bytes) {
  bool starts(List<int> prefix) =>
      bytes.length > prefix.length &&
      [
        for (var i = 0; i < prefix.length; i++) bytes[i] == prefix[i],
      ].every((match) => match);
  return starts(const [0xff, 0xd8, 0xff]) ||
      starts(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]) ||
      starts(const [0x25, 0x50, 0x44, 0x46, 0x2d]);
}

/// A document chosen on the phone, held in memory until it is sent.
class StudentDocument {
  const StudentDocument({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}
