import 'dart:async';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../common_widgets/toast_controller.dart';
import 'job_detail_notifier.dart';

part 'cancel_build_notifier.g.dart';

/// POST `{buildNumber}/stop` + optimistic local flip to `ABORTED`
/// (`JobDetailNotifier.applyOptimisticCancel`), reconciled by the next poll
/// — see `docs/state-management.md`. P6-04: haptic feedback on success/error
/// mirrors `JobDetailViewModel.swift:242/252`'s
/// `UINotificationFeedbackGenerator` calls (see `trigger_build_notifier.dart`
/// for why `mediumImpact`/`heavyImpact` stand in for `.success`/`.error`).
@riverpod
class CancelBuildNotifier extends _$CancelBuildNotifier {
  @override
  FutureOr<void> build(String jobUrl) {}

  Future<void> cancel({
    required String buildUrl,
    required int buildNumber,
  }) async {
    state = const AsyncLoading();

    final result = await ref
        .read(jenkinsRepositoryProvider)
        .cancelBuild(buildUrl);

    switch (result) {
      case Ok():
        ref
            .read(jobDetailNotifierProvider(jobUrl).notifier)
            .applyOptimisticCancel();
        state = const AsyncData(null);
        unawaited(HapticFeedback.mediumImpact());
        ref
            .read(toastControllerProvider)
            .show(
              type: ToastType.success,
              title: 'Cancel Requested',
              message: 'Requested cancellation of build #$buildNumber.',
            );
      case Err(:final error):
        state = AsyncError(error, StackTrace.current);
        unawaited(HapticFeedback.heavyImpact());
        ref
            .read(toastControllerProvider)
            .show(
              type: ToastType.error,
              title: 'Cancel Failed',
              message: error.message,
            );
    }
  }
}
