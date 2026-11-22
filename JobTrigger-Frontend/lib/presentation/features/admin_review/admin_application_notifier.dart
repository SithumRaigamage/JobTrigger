import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/platform/pdf_page_renderer.dart';
import '../../../data/repositories/admin_review_repository_impl.dart';
import '../../../domain/admin_review/admin_student_application.dart';
import 'admin_applications_notifier.dart';

part 'admin_application_notifier.g.dart';

/// The backend's limit on a rejection reason.
const maxRejectionReasonLength = 500;

/// A reason the student will see: 1–500 characters once trimmed.
bool isValidRejectionReason(String raw) {
  final reason = raw.trim();
  return reason.isNotEmpty && reason.length <= maxRejectionReasonLength;
}

/// The decision a reviewer just made on this screen.
enum AdminDecision { approved, rejected }

class AdminApplicationState {
  const AdminApplicationState({
    required this.item,
    this.busy = false,
    this.failure,
    this.decided,
  });

  final AdminStudentApplication item;

  /// A decision is being sent; the buttons are disabled.
  final bool busy;

  /// Why the last decision was refused (already decided, email used, ...).
  final AppFailure? failure;
  final AdminDecision? decided;

  /// Approve and Reject show only while undecided.
  bool get canDecide => item.isPending;
}

/// US-STU-02: one application and the approve/reject actions. The screen
/// asks for confirmation first and only renders this state.
@riverpod
class AdminApplicationNotifier extends _$AdminApplicationNotifier {
  @override
  Future<AdminApplicationState> build(String id) async {
    return switch (await ref.read(adminReviewRepositoryProvider).get(id)) {
      Ok(:final value) => AdminApplicationState(item: value),
      Err(error: final failure) => throw failure,
    };
  }

  Future<void> approve() => _decide(
    AdminDecision.approved,
    () => ref.read(adminReviewRepositoryProvider).approve(id),
  );

  /// Does nothing for an empty or over-long [reason]; the dialog keeps its
  /// button disabled until the reason is valid.
  Future<void> reject(String reason) async {
    if (!isValidRejectionReason(reason)) return;
    await _decide(
      AdminDecision.rejected,
      () => ref.read(adminReviewRepositoryProvider).reject(id, reason.trim()),
    );
  }

  Future<void> _decide(
    AdminDecision decision,
    Future<Result<AdminStudentApplication, AppFailure>> Function() send,
  ) async {
    final current = state.value;
    // Never twice: not while a decision is in flight, not once decided.
    if (current == null || current.busy || !current.canDecide) return;
    state = AsyncData(AdminApplicationState(item: current.item, busy: true));
    final result = await send();
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        state = AsyncData(
          AdminApplicationState(item: value, decided: decision),
        );
        // Every list may hold it (Pending, the new status, All).
        ref.invalidate(adminApplicationsNotifierProvider);
      case Err(error: final failure):
        state = AsyncData(
          AdminApplicationState(item: current.item, failure: failure),
        );
    }
  }
}

/// What the document area shows.
sealed class AdminDocumentContent {
  const AdminDocumentContent();
}

final class AdminDocumentImage extends AdminDocumentContent {
  const AdminDocumentImage(this.bytes);
  final Uint8List bytes;
}

/// A PDF drawn to page images in memory.
final class AdminDocumentPdf extends AdminDocumentContent {
  const AdminDocumentPdf(this.pages);
  final List<Uint8List> pages;
}

/// A PDF this device can't draw in memory (older Android) or an unreadable
/// file: the reviewer is pointed to the website.
final class AdminDocumentUnreadable extends AdminDocumentContent {
  const AdminDocumentUnreadable();
}

/// Deleted 30 days after the decision (410).
final class AdminDocumentDeleted extends AdminDocumentContent {
  const AdminDocumentDeleted();
}

/// US-STU-02: the uploaded document, fetched with the admin's session and
/// held only in this provider's memory. Auto-disposed when the screen
/// closes, so the bytes go with it; nothing is written to disk.
@riverpod
Future<AdminDocumentContent> adminDocument(Ref ref, String id) async {
  final result = await ref.read(adminReviewRepositoryProvider).document(id);
  switch (result) {
    case Err(error: final failure):
      throw failure;
    case Ok(value: null):
      return const AdminDocumentDeleted();
    case Ok(value: final AdminStudentDocument document):
      if (document.isImage) return AdminDocumentImage(document.bytes);
      if (!document.isPdf) return const AdminDocumentUnreadable();
      final pages = await ref
          .read(pdfPageRendererProvider)
          .render(document.bytes);
      return pages == null
          ? const AdminDocumentUnreadable()
          : AdminDocumentPdf(pages);
  }
}
