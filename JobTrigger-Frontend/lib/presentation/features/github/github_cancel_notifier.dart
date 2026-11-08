import 'dart:async';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/github_repository_impl.dart';
import '../../common_widgets/toast_controller.dart';
import '../app_lock/app_lock_notifier.dart';
import 'github_run_notifier.dart';

part 'github_cancel_notifier.g.dart';

/// Cancels a run (`US-GH-RUN-04`). State is `true` once a cancel has been
/// *requested*. Unlike Jenkins there is no optimistic flip to cancelled:
/// GitHub's 202 means the cancel is queued, so the screen shows
/// "Cancelling…" until polling sees the run's real `conclusion`.
@riverpod
class GitHubCancelNotifier extends _$GitHubCancelNotifier {
  @override
  FutureOr<bool> build(String owner, String repo, int runId) => false;

  Future<void> cancel({required int runNumber}) async {
    if (state.isLoading) return;
    // US-JX-21: re-prompt when the user asked for it.
    final allowed = await ref
        .read(appLockNotifierProvider.notifier)
        .confirmSensitive('Confirm to cancel run #$runNumber');
    if (!allowed || !ref.mounted) return;
    state = const AsyncLoading();

    final result = await ref
        .read(gitHubRepositoryProvider)
        .cancelRun(owner, repo, runId);
    if (!ref.mounted) return;

    switch (result) {
      case Ok():
        state = const AsyncData(true);
        unawaited(HapticFeedback.mediumImpact());
        ref
            .read(toastControllerProvider)
            .show(
              type: ToastType.success,
              title: 'Cancel Requested',
              message: 'Requested cancellation of run #$runNumber.',
            );
        // Poll sooner than the 5s tick to catch the state change.
        ref.invalidate(gitHubRunNotifierProvider(owner, repo, runId));
      case Err(:final error):
        // No optimistic change: the cancel did not go through.
        state = const AsyncData(false);
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
