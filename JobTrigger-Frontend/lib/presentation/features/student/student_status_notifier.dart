import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/student_repository_impl.dart';
import '../../../domain/student/student_application.dart';

part 'student_status_notifier.g.dart';

/// Phase 21 (SP-42): the signed-in user's latest student application.
/// Loaded when the verification screen opens and after every step of the
/// flow. A failure is shown with a retry; it never affects the plan.
@riverpod
class StudentStatusNotifier extends _$StudentStatusNotifier {
  @override
  Future<StudentApplication> build() async {
    return switch (await ref.read(studentRepositoryProvider).status()) {
      Ok(:final value) => value,
      Err(error: final failure) => throw failure,
    };
  }

  /// Loads it again (shows the spinner, keeps the screen mounted).
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future.then((_) {}, onError: (_) {});
  }

  /// Takes an answer the flow already has (e.g. the approval).
  void apply(StudentApplication application) => state = AsyncData(application);
}
