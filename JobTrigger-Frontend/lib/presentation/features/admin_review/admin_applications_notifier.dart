import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/admin_review_repository_impl.dart';
import '../../../domain/admin_review/admin_student_application.dart';

part 'admin_applications_notifier.g.dart';

/// US-STU-03: the chosen status filter on the applications screen.
@riverpod
class AdminFilterNotifier extends _$AdminFilterNotifier {
  @override
  AdminStatusFilter build() => AdminStatusFilter.pending;

  void select(AdminStatusFilter filter) => state = filter;
}

/// US-STU-02/03: the applications for one filter, newest first (the
/// backend's order). A failure is shown with a retry.
@riverpod
class AdminApplicationsNotifier extends _$AdminApplicationsNotifier {
  @override
  Future<List<AdminStudentApplication>> build(AdminStatusFilter filter) async {
    return switch (await ref.read(adminReviewRepositoryProvider).list(filter)) {
      Ok(:final value) => value,
      Err(error: final failure) => throw failure,
    };
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future.then((_) {}, onError: (_) {});
  }
}
