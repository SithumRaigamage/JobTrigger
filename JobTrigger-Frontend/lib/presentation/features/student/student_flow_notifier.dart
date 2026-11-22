import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/student_repository_impl.dart';
import '../../../domain/student/student_document.dart';
import '../subscription/entitlements_notifier.dart';
import 'student_document_picker.dart';
import 'student_status_notifier.dart';

part 'student_flow_notifier.g.dart';

/// Where the user is in verifying: email → code, or (domain not listed, or
/// the user's choice) a document. The screen only renders this.
sealed class StudentFlowState {
  const StudentFlowState();
}

/// Asking for the university email.
final class StudentFlowEmail extends StudentFlowState {
  const StudentFlowEmail({this.failure, this.busy = false});

  final AppFailure? failure;
  final bool busy;
}

/// A code was sent to [email]; waiting for it.
final class StudentFlowCode extends StudentFlowState {
  const StudentFlowCode({
    required this.email,
    this.failure,
    this.busy = false,
    this.resent = false,
  });

  final String email;
  final AppFailure? failure;
  final bool busy;

  /// A new code was just sent.
  final bool resent;
}

/// Uploading a student ID or enrolment letter.
final class StudentFlowDocument extends StudentFlowState {
  const StudentFlowDocument({
    this.domainNotListed = false,
    this.document,
    this.problem,
    this.nameProblem = false,
    this.failure,
    this.busy = false,
  });

  /// Shown above the form: the email's domain can't be checked by code.
  final bool domainNotListed;
  final StudentDocument? document;

  /// Why the chosen file was refused before sending.
  final StudentDocumentProblem? problem;

  /// The name field was empty or too short.
  final bool nameProblem;
  final AppFailure? failure;
  final bool busy;
}

/// The final, signed-in view takes over from here (`StudentStatusNotifier`).
final class StudentFlowDone extends StudentFlowState {
  const StudentFlowDone();
}

/// Phase 21 (SP-41): the logic of the verify flow. Widgets only render
/// [StudentFlowState] and call these methods.
@riverpod
class StudentFlowNotifier extends _$StudentFlowNotifier {
  @override
  StudentFlowState build() => const StudentFlowEmail();

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _codePattern = RegExp(r'^\d{6}$');
  static const _minNameLength = 2;

  Future<void> submitEmail(String raw) async {
    final email = raw.trim();
    if (!_emailPattern.hasMatch(email)) {
      state = const StudentFlowEmail(
        failure: StudentRequestFailure(
          400,
          null,
          'Enter your university email address.',
        ),
      );
      return;
    }
    state = const StudentFlowEmail(busy: true);
    switch (await ref.read(studentRepositoryProvider).startEmail(email)) {
      case Ok():
        if (ref.mounted) state = StudentFlowCode(email: email);
      case Err(error: final failure):
        if (!ref.mounted) return;
        state = failure is StudentRequestFailure && failure.isDomainNotListed
            ? const StudentFlowDocument(domainNotListed: true)
            : StudentFlowEmail(failure: failure);
    }
  }

  Future<void> resendCode() async {
    final current = state;
    if (current is! StudentFlowCode) return;
    state = StudentFlowCode(email: current.email, busy: true);
    switch (await ref
        .read(studentRepositoryProvider)
        .startEmail(current.email)) {
      case Ok():
        if (ref.mounted) {
          state = StudentFlowCode(email: current.email, resent: true);
        }
      case Err(error: final failure):
        if (ref.mounted) {
          state = StudentFlowCode(email: current.email, failure: failure);
        }
    }
  }

  Future<void> confirmCode(String raw) async {
    final current = state;
    if (current is! StudentFlowCode) return;
    final code = raw.trim();
    if (!_codePattern.hasMatch(code)) {
      state = StudentFlowCode(
        email: current.email,
        failure: const StudentRequestFailure(
          400,
          null,
          'Enter the 6-digit code.',
        ),
      );
      return;
    }
    state = StudentFlowCode(email: current.email, busy: true);
    switch (await ref.read(studentRepositoryProvider).confirmEmail(code)) {
      case Ok(:final value):
        if (!ref.mounted) return;
        ref.read(studentStatusNotifierProvider.notifier).apply(value);
        // Pick up the plan now (an approval may already have landed).
        await ref.read(entitlementsNotifierProvider.notifier).refresh();
        if (ref.mounted) state = const StudentFlowDone();
      case Err(error: final failure):
        if (ref.mounted) {
          state = StudentFlowCode(email: current.email, failure: failure);
        }
    }
  }

  void useDocument() => state = const StudentFlowDocument();

  void backToEmail() => state = const StudentFlowEmail();

  /// Picks a file and checks it on the phone (name, size, then the file's
  /// first bytes) before it can be sent.
  Future<void> chooseDocument() async {
    final current = state;
    if (current is! StudentFlowDocument) return;
    final picked = await ref.read(studentDocumentPickerProvider)();
    if (picked == null || !ref.mounted) return;

    StudentFlowDocument refused(StudentDocumentProblem problem) =>
        StudentFlowDocument(
          domainNotListed: current.domainNotListed,
          problem: problem,
        );

    final meta = checkStudentDocumentMeta(
      fileName: picked.name,
      sizeBytes: picked.sizeBytes,
    );
    if (meta != null) {
      state = refused(meta);
      return;
    }
    final Uint8List bytes = await picked.read();
    if (!ref.mounted) return;
    if (bytes.length > maxStudentDocumentBytes) {
      state = refused(StudentDocumentProblem.tooLarge);
    } else if (!looksLikeStudentDocument(bytes)) {
      state = refused(StudentDocumentProblem.wrongType);
    } else {
      state = StudentFlowDocument(
        domainNotListed: current.domainNotListed,
        document: StudentDocument(name: picked.name, bytes: bytes),
      );
    }
  }

  Future<void> uploadDocument(String rawName) async {
    final current = state;
    if (current is! StudentFlowDocument || current.document == null) return;
    final name = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.length < _minNameLength) {
      state = StudentFlowDocument(
        domainNotListed: current.domainNotListed,
        document: current.document,
        nameProblem: true,
      );
      return;
    }
    state = StudentFlowDocument(
      domainNotListed: current.domainNotListed,
      document: current.document,
      busy: true,
    );
    final result = await ref
        .read(studentRepositoryProvider)
        .uploadDocument(fullName: name, bytes: current.document!.bytes);
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        ref.read(studentStatusNotifierProvider.notifier).apply(value);
        state = const StudentFlowDone();
      case Err(error: final failure):
        state = StudentFlowDocument(
          domainNotListed: current.domainNotListed,
          document: current.document,
          failure: failure,
        );
    }
  }
}
