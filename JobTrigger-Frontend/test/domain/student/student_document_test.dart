import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/domain/student/student_application.dart';
import 'package:job_trigger/domain/student/student_document.dart';

void main() {
  group('checkStudentDocumentMeta', () {
    test('accepts JPG, PNG and PDF by name, in any case', () {
      for (final name in ['id.jpg', 'id.JPEG', 'scan.png', 'letter.PDF']) {
        expect(
          checkStudentDocumentMeta(fileName: name, sizeBytes: 100),
          isNull,
        );
      }
    });

    test('refuses other types and names with no extension', () {
      for (final name in ['id.gif', 'a.exe', 'noext', 'x.png.exe', 'id.heic']) {
        expect(
          checkStudentDocumentMeta(fileName: name, sizeBytes: 100),
          StudentDocumentProblem.wrongType,
          reason: name,
        );
      }
    });

    test('allows exactly 5 MB and refuses 1 byte more', () {
      expect(
        checkStudentDocumentMeta(
          fileName: 'a.pdf',
          sizeBytes: maxStudentDocumentBytes,
        ),
        isNull,
      );
      expect(
        checkStudentDocumentMeta(
          fileName: 'a.pdf',
          sizeBytes: maxStudentDocumentBytes + 1,
        ),
        StudentDocumentProblem.tooLarge,
      );
    });

    test('refuses an empty file', () {
      expect(
        checkStudentDocumentMeta(fileName: 'a.png', sizeBytes: 0),
        StudentDocumentProblem.empty,
      );
    });
  });

  group('looksLikeStudentDocument', () {
    test('recognises JPG, PNG and PDF by their first bytes', () {
      expect(
        looksLikeStudentDocument(
          Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, 1]),
        ),
        isTrue,
      );
      expect(
        looksLikeStudentDocument(
          Uint8List.fromList([
            0x89,
            0x50,
            0x4e,
            0x47,
            0x0d,
            0x0a,
            0x1a,
            0x0a,
            1,
          ]),
        ),
        isTrue,
      );
      expect(
        looksLikeStudentDocument(Uint8List.fromList('%PDF-1.7 x'.codeUnits)),
        isTrue,
      );
    });

    test('refuses anything else, whatever the name says', () {
      expect(
        looksLikeStudentDocument(Uint8List.fromList('<html>'.codeUnits)),
        isFalse,
      );
      expect(looksLikeStudentDocument(Uint8List(0)), isFalse);
      expect(
        looksLikeStudentDocument(Uint8List.fromList([0xff, 0xd8])),
        isFalse,
      );
    });
  });

  group('StudentApplication.statusAt', () {
    final now = DateTime(2027, 1, 1);

    test('an approved year past its end reads as expired', () {
      final app = StudentApplication(
        status: StudentStatus.approved,
        expiresAt: DateTime(2026, 12, 31),
      );
      expect(app.statusAt(now), StudentStatus.expired);
    });

    test('an approved year still running stays approved', () {
      final app = StudentApplication(
        status: StudentStatus.approved,
        expiresAt: DateTime(2027, 6, 1),
      );
      expect(app.statusAt(now), StudentStatus.approved);
    });

    test('other statuses are unchanged', () {
      const pending = StudentApplication(status: StudentStatus.pending);
      expect(pending.statusAt(now), StudentStatus.pending);
    });
  });
}
