import 'dart:async';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../common_widgets/toast_controller.dart';
import 'job_detail_notifier.dart';
import 'pending_input_notifier.dart';
import '../app_lock/app_lock_notifier.dart';

part 'input_submit_notifier.g.dart';

/// US-PIPE-05. Family-keyed by build URL. Approves/rejects a paused input
/// step — see `JenkinsRepository.submitInput`'s doc comment for the
/// endpoint mechanics (verified in P11-02). Same success/error haptic + toast
/// shape as `TriggerBuildNotifier`/`CancelBuildNotifier`, plus refreshing
/// both `JobDetailNotifier` (the pipeline may have resumed/finished) and
/// `PendingInputNotifier` (this input is resolved either way) on success.
@riverpod
class InputSubmitNotifier extends _$InputSubmitNotifier {
  @override
  FutureOr<void> build(String buildUrl) {}

  Future<void> submit({
    required String jobUrl,
    required String inputId,
    required bool proceed,
    Map<String, String> parameters = const {},
  }) async {
    // US-JX-21: re-prompt when the user asked for it.
    final allowed = await ref
        .read(appLockNotifierProvider.notifier)
        .confirmSensitive(proceed ? 'Confirm to approve' : 'Confirm to abort');
    if (!allowed || !ref.mounted) return;
    state = const AsyncLoading();

    final result = await ref
        .read(jenkinsRepositoryProvider)
        .submitInput(
          buildUrl: buildUrl,
          inputId: inputId,
          proceed: proceed,
          parameters: parameters,
        );

    switch (result) {
      case Ok():
        state = const AsyncData(null);
        unawaited(HapticFeedback.mediumImpact());
        await ref.read(jobDetailNotifierProvider(jobUrl).notifier).refresh();
        ref.invalidate(pendingInputNotifierProvider(buildUrl));
        ref
            .read(toastControllerProvider)
            .show(
              type: ToastType.success,
              title: proceed ? 'Approved' : 'Rejected',
              message: proceed
                  ? 'The pipeline will resume.'
                  : 'The pipeline was aborted.',
            );
      case Err(:final error):
        state = AsyncError(error, StackTrace.current);
        unawaited(HapticFeedback.heavyImpact());
        ref
            .read(toastControllerProvider)
            .show(
              type: ToastType.error,
              title: proceed ? 'Approve Failed' : 'Reject Failed',
              message: error.message,
            );
    }
  }
}
