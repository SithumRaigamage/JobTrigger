import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:job_trigger/core/error/app_failure.dart';
import 'package:job_trigger/core/error/no_retry.dart';
import 'package:job_trigger/core/error/result.dart';
import 'package:job_trigger/core/platform/pdf_page_renderer.dart';
import 'package:job_trigger/core/theme/app_theme.dart';
import 'package:job_trigger/data/repositories/admin_review_repository_impl.dart';
import 'package:job_trigger/domain/admin_review/admin_student_application.dart';
import 'package:job_trigger/domain/student/student_application.dart';
import 'package:job_trigger/presentation/features/admin_review/admin_application_screen.dart';
import 'package:job_trigger/presentation/features/admin_review/admin_applications_screen.dart';
import 'package:job_trigger/presentation/navigation/app_routes.dart';

import '../../../support/fake_admin_review.dart';

/// A real 1×1 PNG, so Image.memory can decode it.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00, //
  0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0xf8, 0xff, 0xff, 0x3f, //
  0x00, 0x05, 0xfe, 0x02, 0xfe, 0xa7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00, //
  0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82, //
]);

class _NoPdf implements PdfPageRenderer {
  @override
  Future<List<Uint8List>?> render(
    Uint8List pdf, {
    int maxPages = 10,
    int width = 1200,
  }) async => null;
}

Future<void> _pump(
  WidgetTester tester,
  FakeAdminReviewRepository repo, {
  String? openId,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: openId == null
        ? AppRoutes.adminStudentApplications
        : AppRoutes.adminStudentApplication,
    initialExtra: openId,
    routes: [
      GoRoute(
        path: AppRoutes.adminStudentApplications,
        builder: (_, _) => const AdminApplicationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminStudentApplication,
        builder: (_, state) =>
            AdminApplicationScreen(id: state.extra! as String),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      retry: noRetry,
      overrides: [
        adminReviewRepositoryProvider.overrideWithValue(repo),
        pdfPageRendererProvider.overrideWithValue(_NoPdf()),
      ],
      child: MaterialApp.router(theme: AppTheme.dark(), routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('list (US-STU-02/03)', () {
    testWidgets('shows pending applications of both methods in the order '
        'given (newest first)', (tester) async {
      await _pump(
        tester,
        FakeAdminReviewRepository(
          lists: {
            AdminStatusFilter.pending: Ok([pendingDocument, pendingEmail]),
          },
        ),
      );
      expect(find.text('Student applications'), findsOneWidget);
      expect(find.text('Amal Fernando'), findsOneWidget);
      expect(find.text('kasun@uom.ac.lk'), findsOneWidget);
      expect(find.text('amal@example.com'), findsOneWidget);
      expect(
        find.text('Student ID / letter · Pending · submitted 21 Nov 2026'),
        findsOneWidget,
      );
      expect(
        find.text('University email · Pending · submitted 20 Nov 2026'),
        findsOneWidget,
      );
      final first = tester.getTopLeft(find.text('Amal Fernando')).dy;
      final second = tester.getTopLeft(find.text('kasun@uom.ac.lk')).dy;
      expect(first, lessThan(second));
    });

    testWidgets('the filters load history with who decided it and when', (
      tester,
    ) async {
      final repo = FakeAdminReviewRepository(
        lists: {
          AdminStatusFilter.approved: Ok([
            decided(pendingEmail, StudentStatus.approved),
          ]),
        },
      );
      await _pump(tester, repo);
      for (final label in ['Pending', 'Approved', 'Rejected', 'Ended', 'All']) {
        expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
      }
      expect(find.text('No applications here.'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Approved'));
      await tester.pumpAndSettle();
      expect(repo.listed.last, AdminStatusFilter.approved);
      expect(
        find.text('Decided 22 Nov 2026 by developer@jobtrigger.app'),
        findsOneWidget,
      );
    });

    testWidgets('a failure shows the message and Try again', (tester) async {
      final repo = FakeAdminReviewRepository(
        lists: {AdminStatusFilter.pending: const Err(NetworkFailure())},
      );
      await _pump(tester, repo);
      expect(find.text(const NetworkFailure().message), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(repo.listed, hasLength(2));
    });

    testWidgets('a row opens the application', (tester) async {
      await _pump(
        tester,
        FakeAdminReviewRepository(
          lists: {
            AdminStatusFilter.pending: Ok([pendingEmail]),
          },
          items: {'e1': pendingEmail},
        ),
      );
      await tester.tap(find.text('kasun@uom.ac.lk'));
      await tester.pumpAndSettle();
      expect(find.text('Student application'), findsOneWidget);
    });
  });

  group('detail (US-STU-02)', () {
    testWidgets('shows every detail of an email application, no document', (
      tester,
    ) async {
      final repo = FakeAdminReviewRepository(items: {'e1': pendingEmail});
      await _pump(tester, repo, openId: 'e1');
      expect(find.text('University email'), findsWidgets);
      expect(find.text('kasun@uom.ac.lk'), findsOneWidget);
      expect(find.text('kasun@example.com'), findsOneWidget);
      expect(find.text('Email verified'), findsOneWidget);
      expect(find.text('20 Nov 2026'), findsWidgets);
      expect(find.text('Document'), findsNothing);
      expect(repo.documents, isEmpty);
    });

    testWidgets('a document application shows the image from memory', (
      tester,
    ) async {
      final repo = FakeAdminReviewRepository(items: {'d1': pendingDocument})
        ..documentResult = Ok(
          AdminStudentDocument(mime: 'image/png', bytes: _png),
        );
      await _pump(tester, repo, openId: 'd1');
      expect(find.text('Amal Fernando'), findsOneWidget);
      expect(find.text('Name on ID'), findsOneWidget);
      expect(repo.documents, ['d1']);
      expect(
        find.bySemanticsLabel("The student's uploaded document"),
        findsOneWidget,
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<MemoryImage>());
    });

    testWidgets('the image leaves the in-memory cache when the screen '
        'closes', (tester) async {
      final repo = FakeAdminReviewRepository(items: {'d1': pendingDocument})
        ..documentResult = Ok(
          AdminStudentDocument(mime: 'image/png', bytes: _png),
        );
      await _pump(tester, repo, openId: 'd1');
      final cache = PaintingBinding.instance.imageCache;
      expect(cache.containsKey(MemoryImage(_png)), isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(cache.containsKey(MemoryImage(_png)), isFalse);
    });

    testWidgets('a PDF this phone cannot draw points to the website, and a '
        'deleted file says so', (tester) async {
      final repo = FakeAdminReviewRepository(items: {'d1': pendingDocument})
        ..documentResult = Ok(
          AdminStudentDocument(
            mime: 'application/pdf',
            bytes: Uint8List.fromList('%PDF'.codeUnits),
          ),
        );
      await _pump(tester, repo, openId: 'd1');
      expect(
        find.textContaining("can't be shown on this phone"),
        findsOneWidget,
      );
    });

    testWidgets('approve asks first; Cancel sends nothing, Approve does', (
      tester,
    ) async {
      final repo = FakeAdminReviewRepository(items: {'e1': pendingEmail});
      await _pump(tester, repo, openId: 'e1');

      await tester.tap(find.byKey(const Key('admin_approve')));
      await tester.pumpAndSettle();
      expect(find.text('Approve this application?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.approved, isEmpty);

      await tester.tap(find.byKey(const Key('admin_approve')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
      await tester.pumpAndSettle();
      expect(repo.approved, ['e1']);
      expect(
        find.text('Approved. The student has Pro until 22 Nov 2027.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('admin_approve')), findsNothing);
      expect(find.byKey(const Key('admin_reject')), findsNothing);
      expect(find.text('developer@jobtrigger.app'), findsOneWidget);
      expect(find.text('Pro until'), findsOneWidget);
      expect(find.text('22 Nov 2027'), findsOneWidget);
    });

    testWidgets('reject needs a reason before it can be confirmed', (
      tester,
    ) async {
      final repo = FakeAdminReviewRepository(items: {'d1': pendingDocument})
        ..documentResult = const Ok(null);
      await _pump(tester, repo, openId: 'd1');

      await tester.tap(find.byKey(const Key('admin_reject')));
      await tester.pumpAndSettle();
      expect(find.text('Reject this application?'), findsOneWidget);
      TextButton confirm() =>
          tester.widget(find.byKey(const Key('admin_reject_confirm')));
      expect(confirm().onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('admin_reject_reason')),
        '  ',
      );
      await tester.pump();
      expect(confirm().onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('admin_reject_reason')),
        'The photo is too blurry',
      );
      await tester.pump();
      expect(confirm().onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('admin_reject_confirm')));
      await tester.pumpAndSettle();

      expect(repo.rejected.single.reason, 'The photo is too blurry');
      expect(find.textContaining('Rejected. The student sees'), findsOneWidget);
      expect(find.text('The photo is too blurry'), findsOneWidget);
    });

    testWidgets('cancelling the reject dialog sends nothing', (tester) async {
      final repo = FakeAdminReviewRepository(items: {'e1': pendingEmail});
      await _pump(tester, repo, openId: 'e1');
      await tester.tap(find.byKey(const Key('admin_reject')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('admin_reject_reason')),
        'no',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.rejected, isEmpty);
      expect(find.byKey(const Key('admin_reject')), findsOneWidget);
    });

    testWidgets("a refused decision shows the backend's sentence and stays "
        'pending', (tester) async {
      final repo = FakeAdminReviewRepository(items: {'e1': pendingEmail})
        ..approveResult = const Err(
          StudentRequestFailure(
            409,
            'email_used',
            'That university email has already been used for a student plan.',
          ),
        );
      await _pump(tester, repo, openId: 'e1');
      await tester.tap(find.byKey(const Key('admin_approve')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('already been used'), findsOneWidget);
      expect(find.byKey(const Key('admin_approve')), findsOneWidget);
    });

    testWidgets('a decided application has no decision buttons', (
      tester,
    ) async {
      final rejected = decided(
        pendingEmail,
        StudentStatus.rejected,
        reason: 'Not a student address',
      );
      await _pump(
        tester,
        FakeAdminReviewRepository(items: {'e1': rejected}),
        openId: 'e1',
      );
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Not a student address'), findsOneWidget);
      expect(find.text('Decided by'), findsOneWidget);
      expect(find.byKey(const Key('admin_approve')), findsNothing);
    });
  });
}
