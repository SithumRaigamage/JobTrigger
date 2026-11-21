import 'dart:async';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/replay_outcome.dart';
import '../../../domain/jenkins/replay_script.dart';
import '../../common_widgets/toast_controller.dart';
import '../app_lock/app_lock_notifier.dart';

part 'replay_edit_notifier.g.dart';

/// US-JX-16 AC2/AC3/AC5: the starting script for [jobUrl]. Held in memory
/// only; never cached or logged.
@riverpod
Future<ReplayScript> replayScript(Ref ref, String jobUrl) async {
  final result = await ref
      .watch(jenkinsRepositoryProvider)
      .fetchReplayScript(jobUrl);
  return result.fold((script) => script, (failure) => throw failure);
}

/// How long AC8 looks for the new build. A provider so tests can shorten it.
class ReplayPolling {
  const ReplayPolling({
    this.interval = const Duration(seconds: 1),
    this.attempts = 10,
  });

  final Duration interval;
  final int attempts;
}

@riverpod
ReplayPolling replayPolling(Ref ref) => const ReplayPolling();

/// US-JX-16 AC6–AC8: submits the edited script and finds the new build.
/// Family-keyed by the replayed build's URL.
@riverpod
class ReplayEditNotifier extends _$ReplayEditNotifier {
  @override
  FutureOr<void> build(String buildUrl) {}

  /// Null when the user declined the app-lock re-prompt or a replay is
  /// already in flight.
  Future<ReplayOutcome?> submit({
    required JenkinsJob job,
    required JenkinsBuild build,
    required String script,
  }) async {
    if (state.isLoading) return null;
    // US-JX-21: re-prompt when the user asked for it.
    final allowed = await ref
        .read(appLockNotifierProvider.notifier)
        .confirmSensitive('Confirm to replay ${job.label} with edits');
    if (!allowed || !ref.mounted) return null;
    state = const AsyncLoading();
    final repository = ref.read(jenkinsRepositoryProvider);
    final submitted = await repository.replayWithScript(build.url, script);
    if (!ref.mounted) return null;
    if (submitted case Err(:final error)) {
      state = AsyncError(error, StackTrace.current);
      unawaited(HapticFeedback.heavyImpact());
      ref
          .read(toastControllerProvider)
          .show(
            type: ToastType.error,
            title: 'Replay failed',
            message: _refusal(error),
          );
      return ReplayRefused(error);
    }
    unawaited(HapticFeedback.mediumImpact());
    final found = await _findReplay(job.url, build.number);
    if (!ref.mounted) return null;
    state = const AsyncData(null);
    ref
        .read(toastControllerProvider)
        .show(
          type: ToastType.success,
          title: 'Replay started',
          message: found == null
              ? '${job.label} is replaying #${build.number} with your edits.'
              : 'Opening #${found.number}.',
        );
    return found == null ? const ReplayStarted() : ReplayedBuild(found);
  }

  /// AC8: Jenkins redirects to the job, not the new build, so match the
  /// cause it writes on the replay ("Replayed #N").
  Future<JenkinsBuild?> _findReplay(String jobUrl, int original) async {
    final polling = ref.read(replayPollingProvider);
    final cause = replayedCause(original);
    for (var attempt = 0; attempt < polling.attempts; attempt++) {
      if (attempt > 0) await Future<void>.delayed(polling.interval);
      if (!ref.mounted) return null;
      final history = await ref
          .read(jenkinsRepositoryProvider)
          .fetchJobHistory(jobUrl, count: 5);
      if (history case Ok(:final value)) {
        for (final candidate in value) {
          if (candidate.number > original && candidate.causes.contains(cause)) {
            return candidate;
          }
        }
      }
    }
    return null;
  }

  /// AC5 copy for a refusal.
  static String _refusal(AppFailure failure) => switch (failure) {
    PermissionFailure() || NotFoundFailure() =>
      "This build can't be replayed with your Jenkins permissions.",
    _ => failure.message,
  };
}
