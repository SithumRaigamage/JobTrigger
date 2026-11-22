import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/student_repository_impl.dart';
import 'package:job_trigger/data/repositories/subscription_repository_impl.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/student/student_application.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';
import 'package:job_trigger/presentation/features/student/student_document_picker.dart';
import 'package:job_trigger/presentation/features/student/student_verification_screen.dart';

import '../../../support/fake_student.dart';
import '../../../support/fake_subscription.dart';

class _Auth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'u1', email: 'a@b.dev'));
}

Future<FakeStudentRepository> _pump(
  WidgetTester tester, {
  StudentApplication initial = StudentApplication.none,
  Result<StudentApplication, AppFailure>? statusResult,
  PickedStudentFile? Function()? pick,
  FakeStudentRepository? repo,
}) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fake =
      repo ?? FakeStudentRepository(statusResult: statusResult ?? Ok(initial));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentRepositoryProvider.overrideWithValue(fake),
        subscriptionRepositoryProvider.overrideWithValue(
          FakeSubscriptionRepository(loadResult: const Ok(proSnapshot)),
        ),
        authNotifierProvider.overrideWith(_Auth.new),
        studentDocumentPickerProvider.overrideWithValue(
          () async => pick?.call(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const StudentVerificationScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('no application: asks for the university email', (tester) async {
    await _pump(tester);
    expect(find.text('Student plan'), findsOneWidget);
    expect(find.byKey(const Key('student_email_field')), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);
    expect(find.textContaining('free for one year'), findsOneWidget);
  });

  testWidgets('email → code → approved, with the expiry date', (tester) async {
    final repo = FakeStudentRepository()
      ..confirmResult = Ok(
        StudentApplication(
          status: StudentStatus.approved,
          method: StudentMethod.email,
          expiresAt: DateTime(2027, 11, 16, 12),
        ),
      );
    await _pump(tester, repo: repo);

    await tester.enterText(
      find.byKey(const Key('student_email_field')),
      'kasun@uom.ac.lk',
    );
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(repo.started, ['kasun@uom.ac.lk']);
    expect(
      find.textContaining('We sent a 6-digit code to kasun@uom.ac.lk'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('student_code_field')),
      '123456',
    );
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('You have JobTrigger Pro as a student'), findsOneWidget);
    expect(find.textContaining('16 Nov 2027'), findsOneWidget);
  });

  testWidgets('US-STU-01: the right code leads to Pending review, not Pro', (
    tester,
  ) async {
    final repo = FakeStudentRepository()
      ..confirmResult = const Ok(
        StudentApplication(
          status: StudentStatus.pending,
          method: StudentMethod.email,
          universityEmail: 'kasun@uom.ac.lk',
        ),
      );
    await _pump(tester, repo: repo);
    await tester.enterText(
      find.byKey(const Key('student_email_field')),
      'kasun@uom.ac.lk',
    );
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('student_code_field')),
      '123456',
    );
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Pending review'), findsOneWidget);
    expect(
      find.textContaining('Your university email is verified'),
      findsOneWidget,
    );
    expect(find.text('You have JobTrigger Pro as a student'), findsNothing);
  });

  testWidgets('US-STU-01: a rejected email application shows the reason and '
      'Try again', (tester) async {
    await _pump(
      tester,
      initial: const StudentApplication(
        status: StudentStatus.rejected,
        method: StudentMethod.email,
        rejectionReason: 'Not a student address',
      ),
    );
    expect(find.text("We couldn't approve your application"), findsOneWidget);
    expect(find.text('Not a student address'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('student_email_field')), findsOneWidget);
  });

  testWidgets('a pending document keeps the document wording', (tester) async {
    await _pump(
      tester,
      initial: const StudentApplication(
        status: StudentStatus.pending,
        method: StudentMethod.document,
      ),
    );
    expect(
      find.textContaining('received your student document'),
      findsOneWidget,
    );
  });

  testWidgets(
    'a wrong code shows the backend reason and stays on the code step',
    (tester) async {
      final repo = FakeStudentRepository()
        ..confirmResult = const Err(
          StudentRequestFailure(
            400,
            'wrong_code',
            'That code is not right. 4 tries left.',
          ),
        );
      await _pump(tester, repo: repo);
      await tester.enterText(
        find.byKey(const Key('student_email_field')),
        'a@uom.ac.lk',
      );
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('student_code_field')),
        '000000',
      );
      await tester.tap(find.text('Verify'));
      await tester.pumpAndSettle();
      expect(
        find.text('That code is not right. 4 tries left.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('student_code_field')), findsOneWidget);
      expect(find.text('Send a new code'), findsOneWidget);
    },
  );

  testWidgets('a domain that is not listed moves to the document upload', (
    tester,
  ) async {
    final repo = FakeStudentRepository()
      ..startResult = const Err(
        StudentRequestFailure(400, 'domain_not_listed', 'Upload instead.'),
      );
    await _pump(tester, repo: repo);
    await tester.enterText(
      find.byKey(const Key('student_email_field')),
      'a@gmail.com',
    );
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining("can't check that email domain"),
      findsOneWidget,
    );
    expect(find.text('Full name as on your student ID'), findsOneWidget);
    expect(find.text('Choose file'), findsOneWidget);
    // Nothing to send until a file is chosen.
    final send = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Send for review'),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('document upload: choose, name, send, then pending review', (
    tester,
  ) async {
    final repo = await _pump(tester, pick: () => pickedFile('id.png'));
    await tester.tap(find.text('No university email? Upload a student ID'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('student_choose_file')));
    await tester.pumpAndSettle();
    expect(find.text('Selected: id.png'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('student_name_field')),
      'Kasun Perera',
    );
    await tester.tap(find.text('Send for review'));
    await tester.pumpAndSettle();

    expect(repo.uploads.single.fullName, 'Kasun Perera');
    expect(find.text('Pending review'), findsOneWidget);
  });

  testWidgets('a file over 5 MB is refused with the agreed message', (
    tester,
  ) async {
    await _pump(
      tester,
      pick: () => PickedStudentFile(
        name: 'big.pdf',
        sizeBytes: 6 * 1024 * 1024,
        read: () async => Uint8List(0),
      ),
    );
    await tester.tap(find.text('No university email? Upload a student ID'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('student_choose_file')));
    await tester.pumpAndSettle();
    expect(find.text('File too large, max 5 MB.'), findsOneWidget);
    expect(find.textContaining('Selected:'), findsNothing);
  });

  testWidgets('a file of the wrong type is refused', (tester) async {
    await _pump(tester, pick: () => pickedFile('notes.txt'));
    await tester.tap(find.text('No university email? Upload a student ID'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('student_choose_file')));
    await tester.pumpAndSettle();
    expect(
      find.text('Only JPG, PNG or PDF files are accepted.'),
      findsOneWidget,
    );
  });

  testWidgets('pending review', (tester) async {
    await _pump(
      tester,
      initial: const StudentApplication(
        status: StudentStatus.pending,
        method: StudentMethod.document,
      ),
    );
    expect(find.text('Pending review'), findsOneWidget);
    expect(find.byKey(const Key('student_email_field')), findsNothing);
  });

  testWidgets('approved shows the expiry date', (tester) async {
    await _pump(
      tester,
      initial: StudentApplication(
        status: StudentStatus.approved,
        expiresAt: DateTime.now().add(const Duration(days: 200)),
      ),
    );
    expect(find.text('You have JobTrigger Pro as a student'), findsOneWidget);
    expect(find.textContaining('Your free year runs until'), findsOneWidget);
  });

  testWidgets('an approved year past its end reads as ended', (tester) async {
    await _pump(
      tester,
      initial: StudentApplication(
        status: StudentStatus.approved,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
    expect(find.text('Your student year has ended'), findsOneWidget);
  });

  testWidgets('expired: one year per person, back on Free', (tester) async {
    await _pump(
      tester,
      initial: const StudentApplication(status: StudentStatus.expired),
    );
    expect(find.text('Your student year has ended'), findsOneWidget);
    expect(find.byKey(const Key('student_email_field')), findsNothing);
  });

  testWidgets('rejected shows the reason, and Try again reopens the form', (
    tester,
  ) async {
    await _pump(
      tester,
      initial: const StudentApplication(
        status: StudentStatus.rejected,
        method: StudentMethod.document,
        rejectionReason: 'The photo is too blurry to read.',
      ),
    );
    expect(find.text('The photo is too blurry to read.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('student_email_field')), findsOneWidget);
  });

  testWidgets('a status that cannot load can be retried', (tester) async {
    final repo = FakeStudentRepository(
      statusResult: const Err(NetworkFailure()),
    );
    await _pump(tester, repo: repo);
    expect(find.textContaining("Can't reach the server"), findsOneWidget);
    repo.statusResult = const Ok(StudentApplication.none);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('student_email_field')), findsOneWidget);
  });

  testWidgets('demo mode: sending shows "Not available in demo"', (
    tester,
  ) async {
    final repo = FakeStudentRepository()
      ..startResult = const Err(DemoUnavailableFailure());
    await _pump(tester, repo: repo);
    await tester.enterText(
      find.byKey(const Key('student_email_field')),
      'a@uom.ac.lk',
    );
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.text('Not available in demo.'), findsOneWidget);
  });
}
