import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/github_repository_impl.dart';
import '../../common_widgets/toast_controller.dart';
import '../app_lock/app_lock_notifier.dart';
import '../first_run/first_run_notifier.dart';
import 'github_runs_notifier.dart';

part 'github_trigger_notifier.g.dart';

/// Dispatches a workflow (`US-GH-RUN-02`), keyed by `(owner, repo,
/// workflowId)`. GitHub's 204 carries no run id, so there is nothing to
/// track: on success the runs list is refreshed now and once more after a
/// short delay, since the new run takes a moment to appear.
@riverpod
class GitHubTriggerNotifier extends _$GitHubTriggerNotifier {
  @override
  FutureOr<void> build(String owner, String repo, int workflowId) {}

  Future<void> trigger({
    required String ref,
    Map<String, String> inputs = const {},
    required String workflowName,
  }) async {
    // Re-entrancy guard, as for Jenkins triggers (AUD-64).
    if (state.isLoading) return;
    // The trigger sheet only calls this (it does not watch the provider), and
    // an auto-dispose provider with no listener is disposed while this awaits
    // (the app-lock prompt, the request), which would drop the trigger. Hold
    // it open until the work, including the delayed refresh, is done.
    final link = this.ref.keepAlive();
    var holdForRefresh = false;
    try {
      holdForRefresh = await _trigger(
        link,
        ref: ref,
        inputs: inputs,
        workflowName: workflowName,
      );
    } finally {
      if (!holdForRefresh) link.close();
    }
  }

  /// Returns true when [link] was handed to the delayed refresh, which then
  /// closes it.
  Future<bool> _trigger(
    KeepAliveLink link, {
    required String ref,
    required Map<String, String> inputs,
    required String workflowName,
  }) async {
    // US-JX-21: re-prompt when the user asked for it.
    final allowed = await this.ref
        .read(appLockNotifierProvider.notifier)
        .confirmSensitive('Confirm to run $workflowName');
    if (!allowed || !this.ref.mounted) return false;
    state = const AsyncLoading();

    final result = await this.ref
        .read(gitHubRepositoryProvider)
        .triggerRun(owner, repo, workflowId, ref: ref, inputs: inputs);
    if (!this.ref.mounted) return false;

    switch (result) {
      case Ok():
        // PI-08: the first-run card's "trigger a build" step is done.
        unawaited(
          this.ref.read(firstRunNotifierProvider.notifier).markTriggered(),
        );
        state = const AsyncData(null);
        unawaited(HapticFeedback.mediumImpact());
        this.ref
            .read(toastControllerProvider)
            .show(
              type: ToastType.success,
              title: 'Triggered',
              message: '$workflowName was triggered. Refreshing shortly…',
            );
        this.ref.invalidate(
          gitHubRunsNotifierProvider(owner, repo, workflowId),
        );
        unawaited(
          Future<void>.delayed(const Duration(seconds: 3), () {
            if (this.ref.mounted) {
              this.ref.invalidate(
                gitHubRunsNotifierProvider(owner, repo, workflowId),
              );
            }
            link.close();
          }),
        );
        return true;
      case Err(:final error):
        state = AsyncError(error, StackTrace.current);
        unawaited(HapticFeedback.heavyImpact());
        this.ref
            .read(toastControllerProvider)
            .show(
              type: ToastType.error,
              title: 'Trigger Failed',
              message: error.message,
            );
        return false;
    }
  }
}
