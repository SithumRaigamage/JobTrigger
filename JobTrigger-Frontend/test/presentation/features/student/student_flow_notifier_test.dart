import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/data/repositories/student_repository_impl.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/student/student_application.dart';
import 'package:job_trigger/domain/student/student_document.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/student/student_document_picker.dart';
import 'package:job_trigger/presentation/features/student/student_flow_notifier.dart';
import 'package:job_trigger/presentation/features/student/student_status_notifier.dart';

import '../../../support/fake_student.dart';
import '../../../support/fake_subscription.dart';

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u1', email: 'a@b.dev'));
}

ProviderContainer _container(
  FakeStudentRepository repo, {
  PickedStudentFile? Function()? pick,
  FakeSubscriptionRepository? subscription,
}) {
  final container = ProviderContainer(
    overrides: [
      studentRepositoryProvider.overrideWithValue(repo),
      subscriptionRepositoryProvider.overrideWithValue(
        subscription ??
            FakeSubscriptionRepository(loadResult: const Ok(freeSnapshot)),
      ),
      authNotifierProvider.overrideWith(_Auth.new),
      studentDocumentPickerProvider.overrideWithValue(() async => pick?.call()),
    ],
  );
  addTearDown(container.dispose);
  // The screen watches the status while the flow runs; do the same here.
  container.listen(studentStatusNotifierProvider, (_, _) {});
  return container;
}

StudentFlowNotifier _flow(ProviderContainer c) =>
    c.read(studentFlowNotifierProvider.notifier);
StudentFlowState _state(ProviderContainer c) =>
    c.read(studentFlowNotifierProvider);

void main() {
  group('email path', () {
    test('rejects a malformed email without calling the backend', () async {
      final repo = FakeStudentRepository();
      final c = _container(repo);
      await _flow(c).submitEmail('not-an-email');
      expect(_state(c), isA<StudentFlowEmail>());
      expect((_state(c) as StudentFlowEmail).failure, isNotNull);
      expect(repo.started, isEmpty);
    });

    test('a listed domain moves on to the code step', () async {
      final repo = FakeStudentRepository();
      final c = _container(repo);
      await _flow(c).submitEmail('  kasun@uom.ac.lk ');
      expect(repo.started, ['kasun@uom.ac.lk']);
      expect((_state(c) as StudentFlowCode).email, 'kasun@uom.ac.lk');
    });

    test(
      'a domain that is not listed falls back to the document step',
      () async {
        final repo = FakeStudentRepository()
          ..startResult = const Err(
            StudentRequestFailure(400, 'domain_not_listed', 'Upload instead.'),
          );
        final c = _container(repo);
        await _flow(c).submitEmail('a@gmail.com');
        expect((_state(c) as StudentFlowDocument).domainNotListed, isTrue);
      },
    );

    test(
      'any other start failure stays on the email step with the reason',
      () async {
        final repo = FakeStudentRepository()
          ..startResult = const Err(
            StudentRequestFailure(409, 'email_used', 'Already used.'),
          );
        final c = _container(repo);
        await _flow(c).submitEmail('a@uom.ac.lk');
        final state = _state(c) as StudentFlowEmail;
        expect(state.failure!.message, 'Already used.');
      },
    );

    test('a wrong code keeps the code step and shows the reason', () async {
      final repo = FakeStudentRepository()
        ..confirmResult = const Err(
          StudentRequestFailure(400, 'wrong_code', 'Not right. 4 tries left.'),
        );
      final c = _container(repo);
      await _flow(c).submitEmail('a@uom.ac.lk');
      await _flow(c).confirmCode('111111');
      final state = _state(c) as StudentFlowCode;
      expect(state.failure!.message, 'Not right. 4 tries left.');
      expect(state.email, 'a@uom.ac.lk');
    });

    test('a malformed code is refused on the phone', () async {
      final repo = FakeStudentRepository();
      final c = _container(repo);
      await _flow(c).submitEmail('a@uom.ac.lk');
      await _flow(c).confirmCode('12ab');
      expect(repo.confirmed, isEmpty);
      expect((_state(c) as StudentFlowCode).failure, isNotNull);
    });

    test(
      'the right code approves, updates the status and re-reads the plan',
      () async {
        final repo = FakeStudentRepository();
        final subscription = FakeSubscriptionRepository(
          loadResult: const Ok(proSnapshot),
        );
        final c = _container(repo, subscription: subscription);
        await _flow(c).submitEmail('a@uom.ac.lk');
        await _flow(c).confirmCode(' 123456 ');
        expect(repo.confirmed, ['123456']);
        expect(_state(c), isA<StudentFlowDone>());
        final status = c.read(studentStatusNotifierProvider).value;
        expect(status!.status, StudentStatus.approved);
        expect(subscription.loads, greaterThan(0));
      },
    );

    test('a new code can be requested', () async {
      final repo = FakeStudentRepository();
      final c = _container(repo);
      await _flow(c).submitEmail('a@uom.ac.lk');
      await _flow(c).resendCode();
      expect(repo.started, ['a@uom.ac.lk', 'a@uom.ac.lk']);
      expect((_state(c) as StudentFlowCode).resent, isTrue);
    });
  });

  group('document path', () {
    test('a good file is held until sent', () async {
      final repo = FakeStudentRepository();
      final c = _container(repo, pick: () => pickedFile('id.png'));
      _flow(c).useDocument();
      await _flow(c).chooseDocument();
      final state = _state(c) as StudentFlowDocument;
      expect(state.document!.name, 'id.png');
      expect(state.problem, isNull);
    });

    test('cancelling the picker changes nothing', () async {
      final c = _container(FakeStudentRepository(), pick: () => null);
      _flow(c).useDocument();
      await _flow(c).chooseDocument();
      expect((_state(c) as StudentFlowDocument).document, isNull);
    });

    test('over 5 MB is refused before the file is read', () async {
      var read = false;
      final c = _container(
        FakeStudentRepository(),
        pick: () => PickedStudentFile(
          name: 'big.pdf',
          sizeBytes: maxStudentDocumentBytes + 1,
          read: () async {
            read = true;
            return Uint8List(0);
          },
        ),
      );
      _flow(c).useDocument();
      await _flow(c).chooseDocument();
      expect(
        (_state(c) as StudentFlowDocument).problem,
        StudentDocumentProblem.tooLarge,
      );
      expect(read, isFalse);
    });

    test('the wrong type is refused by name, and by content', () async {
      final byName = _container(
        FakeStudentRepository(),
        pick: () => pickedFile('notes.txt'),
      );
      _flow(byName).useDocument();
      await _flow(byName).chooseDocument();
      expect(
        (_state(byName) as StudentFlowDocument).problem,
        StudentDocumentProblem.wrongType,
      );

      final byContent = _container(
        FakeStudentRepository(),
        pick: () =>
            pickedFile('id.png', bytes: Uint8List.fromList('<html>'.codeUnits)),
      );
      _flow(byContent).useDocument();
      await _flow(byContent).chooseDocument();
      expect(
        (_state(byContent) as StudentFlowDocument).problem,
        StudentDocumentProblem.wrongType,
      );
    });

    test('the name is required before sending', () async {
      final repo = FakeStudentRepository();
      final c = _container(repo, pick: () => pickedFile('id.png'));
      _flow(c).useDocument();
      await _flow(c).chooseDocument();
      await _flow(c).uploadDocument('  ');
      expect(repo.uploads, isEmpty);
      expect((_state(c) as StudentFlowDocument).nameProblem, isTrue);
    });

    test('sending needs a chosen file', () async {
      final repo = FakeStudentRepository();
      final c = _container(repo);
      _flow(c).useDocument();
      await _flow(c).uploadDocument('Kasun Perera');
      expect(repo.uploads, isEmpty);
    });

    test('sends the tidied name and the file, then shows pending', () async {
      final repo = FakeStudentRepository();
      final c = _container(repo, pick: () => pickedFile('id.png'));
      await c.read(studentStatusNotifierProvider.future);
      _flow(c).useDocument();
      await _flow(c).chooseDocument();
      await _flow(c).uploadDocument('  Kasun   Perera ');
      expect(repo.uploads.single.fullName, 'Kasun Perera');
      expect(_state(c), isA<StudentFlowDone>());
      expect(
        c.read(studentStatusNotifierProvider).value!.status,
        StudentStatus.pending,
      );
    });

    test(
      'a refused upload keeps the file and the form, with the reason',
      () async {
        final repo = FakeStudentRepository()
          ..uploadResult = const Err(
            StudentRequestFailure(409, 'under_review', 'Already waiting.'),
          );
        final c = _container(repo, pick: () => pickedFile('id.png'));
        _flow(c).useDocument();
        await _flow(c).chooseDocument();
        await _flow(c).uploadDocument('Kasun Perera');
        final state = _state(c) as StudentFlowDocument;
        expect(state.document, isNotNull);
        expect(state.failure!.message, 'Already waiting.');
      },
    );

    test('demo mode: the repository refuses, the form shows it', () async {
      final repo = FakeStudentRepository()
        ..uploadResult = const Err(DemoUnavailableFailure());
      final c = _container(repo, pick: () => pickedFile('id.png'));
      _flow(c).useDocument();
      await _flow(c).chooseDocument();
      await _flow(c).uploadDocument('Kasun Perera');
      expect(
        (_state(c) as StudentFlowDocument).failure!.message,
        'Not available in demo.',
      );
    });
  });
}
