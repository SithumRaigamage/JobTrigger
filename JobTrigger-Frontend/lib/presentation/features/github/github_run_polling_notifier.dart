import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import 'github_run_notifier.dart';

part 'github_run_polling_notifier.g.dart';

/// Side-effect-only notifier (`US-GH-RUN-03`): while the run isn't
/// `completed`, invalidates [GitHubRunNotifier] every 5s, same cadence and
/// timer discipline as `BuildStatusPollingNotifier` — the timer is always
/// cancelled in `ref.onDispose`.
///
/// Unlike Jenkins, GitHub has an hourly rate limit, so a [RateLimitFailure]
/// stops polling instead of retrying into a worse state; the screen shows
/// the failure's message and the user refreshes by hand once it lifts.
/// Other errors keep polling: the previous value stays visible, so a
/// dropped connection recovers on its own.
@riverpod
class GitHubRunPollingNotifier extends _$GitHubRunPollingNotifier {
  Timer? _timer;

  @override
  void build(String owner, String repo, int runId) {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    ref.listen(gitHubRunNotifierProvider(owner, repo, runId), (previous, next) {
      _timer?.cancel();
      _timer = null;
      if (next.hasError && next.error is RateLimitFailure) return;
      if (!(next.value?.isActive ?? false)) return;
      _timer = Timer(const Duration(seconds: 5), () {
        ref.invalidate(gitHubRunNotifierProvider(owner, repo, runId));
      });
    }, fireImmediately: true);
  }
}
