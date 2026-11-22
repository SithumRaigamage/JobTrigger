import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/no_retry.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/pdf_page_renderer.dart';
import 'package:job_trigger/data/demo/demo_mode_notifier.dart';
import 'package:job_trigger/data/repositories/admin_review_repository_impl.dart';
import 'package:job_trigger/domain/admin_review/admin_student_application.dart';
import 'package:job_trigger/domain/auth/auth_state.dart';
import 'package:job_trigger/domain/auth/user.dart';
import 'package:job_trigger/domain/student/student_application.dart';
import 'package:job_trigger/presentation/features/admin_review/admin_access_provider.dart';
import 'package:job_trigger/presentation/features/admin_review/admin_application_notifier.dart';
import 'package:job_trigger/presentation/features/admin_review/admin_applications_notifier.dart';
import 'package:job_trigger/presentation/features/admin_review/admin_review_text.dart';
import 'package:job_trigger/presentation/features/auth/auth_notifier.dart';

import '../../../support/fake_admin_review.dart';

class _SignedIn extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const Authenticated(User(id: 'a1', email: 'developer@jobtrigger.app'));
}

class _SignedOut extends AuthNotifier {
  @override
  Future<AuthState> build() async => const Unauthenticated();
}

class _Renderer implements PdfPageRenderer {
  _Renderer(this.pages);
  final List<Uint8List>? pages;
  int calls = 0;

  @override
  Future<List<Uint8List>?> render(
    Uint8List pdf, {
    int maxPages = 10,
    int width = 1200,
  }) async {
    calls++;
    return pages;
  }
}

ProviderContainer _container(
  FakeAdminReviewRepository repo, {
  AuthNotifier Function()? auth,
  PdfPageRenderer? renderer,
}) {
  final container = ProviderContainer(
    retry: noRetry,
    overrides: [
      adminReviewRepositoryProvider.overrideWithValue(repo),
      authNotifierProvider.overrideWith(auth ?? _SignedIn.new),
      if (renderer != null) pdfPageRendererProvider.overrideWithValue(renderer),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<AdminApplicationState> _load(ProviderContainer c, String id) {
  c.listen(adminApplicationNotifierProvider(id), (_, _) {});
  return c.read(adminApplicationNotifierProvider(id).future);
}

void main() {
  group('adminAccessProvider (US-STU-02)', () {
    test('true only when the backend says super admin', () async {
      final c = _container(FakeAdminReviewRepository());
      await c.read(authNotifierProvider.future);
      expect(await c.read(adminAccessProvider.future), isTrue);
    });

    test('false for everyone else and on a failure', () async {
      for (final access in <Result<bool, AppFailure>>[
        const Ok(false),
        const Err(NetworkFailure()),
      ]) {
        final c = _container(FakeAdminReviewRepository(access: access));
        await c.read(authNotifierProvider.future);
        expect(await c.read(adminAccessProvider.future), isFalse);
      }
    });

    test('signed out: false without asking the backend', () async {
      final repo = FakeAdminReviewRepository();
      final c = _container(repo, auth: _SignedOut.new);
      await c.read(authNotifierProvider.future);
      expect(await c.read(adminAccessProvider.future), isFalse);
      expect(repo.accessCalls, 0);
    });

    test('demo mode: never an admin', () async {
      final c = ProviderContainer(
        overrides: [
          demoModeInitialProvider.overrideWithValue(true),
          authNotifierProvider.overrideWith(_SignedIn.new),
        ],
      );
      addTearDown(c.dispose);
      await c.read(authNotifierProvider.future);
      expect(await c.read(adminAccessProvider.future), isFalse);
    });
  });

  test('the list loads per filter, Pending first (US-STU-03)', () async {
    final repo = FakeAdminReviewRepository(
      lists: {
        AdminStatusFilter.pending: Ok([pendingDocument, pendingEmail]),
      },
    );
    final c = _container(repo);
    expect(c.read(adminFilterNotifierProvider), AdminStatusFilter.pending);
    final pending = await c.read(
      adminApplicationsNotifierProvider(AdminStatusFilter.pending).future,
    );
    expect(pending.map((i) => i.id), ['d1', 'e1']);

    c.read(adminFilterNotifierProvider.notifier).select(AdminStatusFilter.all);
    expect(c.read(adminFilterNotifierProvider), AdminStatusFilter.all);
    await c.read(
      adminApplicationsNotifierProvider(AdminStatusFilter.all).future,
    );
    expect(repo.listed, [AdminStatusFilter.pending, AdminStatusFilter.all]);
  });

  group('AdminApplicationNotifier (US-STU-02)', () {
    test('approve replaces the item and refreshes the lists', () async {
      final repo = FakeAdminReviewRepository(items: {'e1': pendingEmail});
      final c = _container(repo);
      final listSub = c.listen(
        adminApplicationsNotifierProvider(AdminStatusFilter.pending),
        (_, _) {},
      );
      await c.read(
        adminApplicationsNotifierProvider(AdminStatusFilter.pending).future,
      );
      expect((await _load(c, 'e1')).canDecide, isTrue);

      await c.read(adminApplicationNotifierProvider('e1').notifier).approve();
      final state = c.read(adminApplicationNotifierProvider('e1')).value!;
      expect(repo.approved, ['e1']);
      expect(state.item.status, StudentStatus.approved);
      expect(state.decided, AdminDecision.approved);
      expect(state.canDecide, isFalse);
      await c.read(
        adminApplicationsNotifierProvider(AdminStatusFilter.pending).future,
      );
      expect(repo.listed, hasLength(2), reason: 'the list was reloaded');
      listSub.close();
    });

    test('never decides twice', () async {
      final repo = FakeAdminReviewRepository(items: {'e1': pendingEmail});
      final c = _container(repo);
      await _load(c, 'e1');
      final notifier = c.read(adminApplicationNotifierProvider('e1').notifier);
      await Future.wait([notifier.approve(), notifier.approve()]);
      await notifier.reject('late');
      expect(repo.approved, ['e1']);
      expect(repo.rejected, isEmpty);
    });

    test(
      'reject sends the trimmed reason; an empty or long one sends nothing',
      () async {
        final repo = FakeAdminReviewRepository(items: {'d1': pendingDocument});
        final c = _container(repo);
        await _load(c, 'd1');
        final notifier = c.read(
          adminApplicationNotifierProvider('d1').notifier,
        );
        await notifier.reject('   ');
        await notifier.reject('x' * (maxRejectionReasonLength + 1));
        expect(repo.rejected, isEmpty);
        await notifier.reject('  Too blurry  ');
        expect(repo.rejected.single.reason, 'Too blurry');
        final state = c.read(adminApplicationNotifierProvider('d1')).value!;
        expect(state.item.status, StudentStatus.rejected);
        expect(state.item.rejectionReason, 'Too blurry');
        expect(state.decided, AdminDecision.rejected);
      },
    );

    test('a refused decision keeps it pending with the failure', () async {
      final repo = FakeAdminReviewRepository(items: {'e1': pendingEmail})
        ..approveResult = const Err(
          StudentRequestFailure(409, 'email_used', 'That email was used.'),
        );
      final c = _container(repo);
      await _load(c, 'e1');
      await c.read(adminApplicationNotifierProvider('e1').notifier).approve();
      final state = c.read(adminApplicationNotifierProvider('e1')).value!;
      expect(state.item.isPending, isTrue);
      expect(state.failure?.message, 'That email was used.');
      expect(state.busy, isFalse);
      expect(state.canDecide, isTrue);
    });

    test('validates the reason the same way the backend does', () {
      expect(isValidRejectionReason(''), isFalse);
      expect(isValidRejectionReason('  '), isFalse);
      expect(isValidRejectionReason('ok'), isTrue);
      expect(isValidRejectionReason('x' * 500), isTrue);
      expect(isValidRejectionReason('x' * 501), isFalse);
    });
  });

  test(
    'the decision line names the reviewer, or a deleted account (US-STU-03)',
    () {
      expect(decisionLine(pendingEmail), isNull);
      final done = decided(pendingEmail, StudentStatus.approved);
      expect(
        decisionLine(done),
        'Decided 22 Nov 2026 by developer@jobtrigger.app',
      );
      final gone = AdminStudentApplication(
        id: 'x',
        method: StudentMethod.email,
        status: StudentStatus.approved,
        submittedAt: DateTime.utc(2026, 11, 1),
        reviewedAt: DateTime.utc(2026, 11, 22, 8),
      );
      expect(decisionLine(gone), 'Decided 22 Nov 2026 by (account deleted)');
    },
  );

  group('adminDocumentProvider (US-STU-02)', () {
    final png = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 1]);
    final pdf = Uint8List.fromList('%PDF-1.4'.codeUnits);

    Future<AdminDocumentContent> load(
      Result<AdminStudentDocument?, AppFailure> result, {
      List<Uint8List>? pages,
      _Renderer? renderer,
    }) {
      final repo = FakeAdminReviewRepository()..documentResult = result;
      final c = _container(repo, renderer: renderer ?? _Renderer(pages));
      c.listen(adminDocumentProvider('d1'), (_, _) {});
      return c.read(adminDocumentProvider('d1').future);
    }

    test('an image is shown from memory', () async {
      final content = await load(
        Ok(AdminStudentDocument(mime: 'image/png', bytes: png)),
      );
      expect((content as AdminDocumentImage).bytes, png);
    });

    test('a PDF is drawn to pages in memory', () async {
      final page = Uint8List.fromList([1, 2, 3]);
      final content = await load(
        Ok(AdminStudentDocument(mime: 'application/pdf', bytes: pdf)),
        pages: [page, page],
      );
      expect((content as AdminDocumentPdf).pages, hasLength(2));
    });

    test('a PDF the phone cannot draw points to the website', () async {
      final content = await load(
        Ok(AdminStudentDocument(mime: 'application/pdf', bytes: pdf)),
      );
      expect(content, isA<AdminDocumentUnreadable>());
    });

    test(
      'a deleted document says so, an image is never sent to the PDF drawer',
      () async {
        final renderer = _Renderer(null);
        expect(
          await load(const Ok(null), renderer: renderer),
          isA<AdminDocumentDeleted>(),
        );
        await load(
          Ok(AdminStudentDocument(mime: 'image/jpeg', bytes: png)),
          renderer: renderer,
        );
        expect(renderer.calls, 0);
      },
    );
  });
}
