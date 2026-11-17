import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/queue_item.dart';
import 'job_detail_notifier.dart';

part 'queue_status_notifier.g.dart';

/// US-PIPE-01. Family-keyed by job URL. Tracks the queue item a
/// just-triggered build was assigned, started imperatively via [track]
/// (called by `TriggerBuildNotifier` right after a successful trigger
/// returns a queue-item URL) — there's no per-job queue endpoint to poll
/// passively, so this can't be derived reactively the way
/// `BuildStatusPollingNotifier` derives from `JobDetailNotifier`.
///
/// `null` state means "nothing currently tracked": no trigger has
/// happened yet this session, or the tracked item already resolved. Polls
/// every 2s (shorter than `US-JOB-04`'s 5s build-status poll — queue waits
/// are often brief) until the item becomes an executable build or is
/// cancelled, then stops and, if it started building, invalidates
/// `JobDetailNotifier` so the existing building-status flow picks up from
/// there. Only covers builds triggered from this app session — an
/// already-queued build discovered on a cold job-detail load isn't
/// detected (a known, deliberately out-of-scope gap; Jenkins' queue is
/// server-wide with no per-job endpoint to check without scanning
/// everyone's queued items).
@riverpod
class QueueStatusNotifier extends _$QueueStatusNotifier {
  Timer? _timer;

  @override
  QueueItem? build(String jobUrl) {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    return null;
  }

  /// Starts (or restarts) tracking [queueItemUrl]. Returns once the first
  /// poll completes — a deterministic hook for tests — while any further
  /// polling from a still-queued result keeps running independently via
  /// its own timer, same as `BuildStatusPollingNotifier`.
  Future<void> track(String queueItemUrl) {
    _timer?.cancel();
    return _poll(queueItemUrl);
  }

  Future<void> _poll(String queueItemUrl) async {
    final result = await ref
        .read(jenkinsRepositoryProvider)
        .fetchQueueItem(queueItemUrl);

    switch (result) {
      case Ok(:final value):
        if (value.isResolved) {
          state = null;
          if (value.executable != null) {
            ref.invalidate(jobDetailNotifierProvider(jobUrl));
          }
          return;
        }
        state = value;
        _timer = Timer(const Duration(seconds: 2), () => _poll(queueItemUrl));
      case Err():
        // Additive information (US-PIPE-01's "Queue fetch fails"
        // scenario) — clear quietly rather than surfacing an error for
        // something that must not block the rest of the job-detail
        // screen.
        state = null;
    }
  }
}
