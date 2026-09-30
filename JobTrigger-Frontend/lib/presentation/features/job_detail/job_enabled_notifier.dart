import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../common_widgets/toast_controller.dart';
import 'job_detail_notifier.dart';

part 'job_enabled_notifier.g.dart';

/// US-JX-13: enables or disables a job, then refreshes its detail so the
/// badge and Trigger button follow the server's real state.
@riverpod
class JobEnabledNotifier extends _$JobEnabledNotifier {
  @override
  FutureOr<void> build(String jobUrl) {}

  Future<void> setEnabled({
    required bool enabled,
    required String label,
  }) async {
    state = const AsyncLoading();
    final result = await ref
        .read(jenkinsRepositoryProvider)
        .setJobEnabled(jobUrl, enabled: enabled);
    if (!ref.mounted) return;
    final toast = ref.read(toastControllerProvider);
    switch (result) {
      case Ok():
        state = const AsyncData(null);
        await ref.read(jobDetailNotifierProvider(jobUrl).notifier).refresh();
        toast.show(
          type: ToastType.success,
          title: enabled ? 'Job enabled' : 'Job disabled',
          message: enabled
              ? '$label can be built again.'
              : "$label won't build until it's enabled.",
        );
      case Err(:final error):
        state = AsyncError(error, StackTrace.current);
        toast.show(
          type: ToastType.error,
          title: enabled ? "Couldn't enable" : "Couldn't disable",
          // A 403 here is either missing permission or a multibranch branch
          // job, which only its branch source may change (verified: even an
          // admin gets 403).
          message: error is PermissionFailure
              ? "You may not have permission, or this is a branch job that's "
                    'managed by its multibranch project.'
              : error.message,
        );
    }
  }
}
