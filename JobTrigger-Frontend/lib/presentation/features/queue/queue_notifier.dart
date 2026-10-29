import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/no_retry.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/queue_entry.dart';
import '../../common_widgets/toast_controller.dart';
import '../app_lock/app_lock_notifier.dart';

part 'queue_notifier.g.dart';

/// US-JX-09: the server-wide build queue, refreshed every [_refreshEvery]
/// while the queue screen is open. The timer is cancelled on dispose.
@Riverpod(retry: noRetry)
class QueueNotifier extends _$QueueNotifier {
  static const _refreshEvery = Duration(seconds: 5);

  @override
  Future<List<QueueEntry>> build() async {
    final result = await ref.watch(jenkinsRepositoryProvider).fetchQueue();
    final items = result.fold((items) => items, (failure) => throw failure);
    _refreshLater();
    return items;
  }

  /// P19-05: the next refresh is timed from a *successful* fetch. Started
  /// before it, a 5s timer restarted any request slower than that (an
  /// unreachable server takes the full connect timeout), so the screen never
  /// got to show the failure. After a failure it stays quiet until Retry.
  void _refreshLater() {
    if (!ref.mounted) return;
    final timer = Timer(_refreshEvery, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }

  /// Cancels a queued item: removed from the list at once, then confirmed
  /// by the next refresh. On failure the item comes back with a toast.
  Future<void> cancel(QueueEntry entry) async {
    // US-JX-21: re-prompt when the user asked for it.
    final allowed = await ref
        .read(appLockNotifierProvider.notifier)
        .confirmSensitive('Confirm to cancel the queued build');
    if (!allowed || !ref.mounted) return;
    final before = state.value;
    if (before != null) {
      state = AsyncData([
        for (final item in before)
          if (item.id != entry.id) item,
      ]);
    }
    final result = await ref
        .read(jenkinsRepositoryProvider)
        .cancelQueueItem(entry.id);
    if (!ref.mounted) return;
    final toast = ref.read(toastControllerProvider);
    switch (result) {
      case Ok():
        toast.show(
          type: ToastType.success,
          title: 'Removed from queue',
          message: '${entry.taskName} won\'t start.',
        );
      case Err(:final error)
          when error is NotFoundFailure || error is ServerFailure:
        // Jenkins can't tell us *why* (a 404, or a bare 500 "not
        // cancellable"), so check whether the item is still waiting.
        final fresh = await ref.read(jenkinsRepositoryProvider).fetchQueue();
        if (!ref.mounted) return;
        final stillQueued = switch (fresh) {
          Ok(:final value) => value.any((item) => item.id == entry.id),
          Err() => true,
        };
        if (stillQueued) {
          if (before != null) state = AsyncData(before);
          toast.show(
            type: ToastType.error,
            title: 'Cancel failed',
            message: error.message,
          );
        } else {
          if (fresh case Ok(:final value)) state = AsyncData(value);
          toast.show(
            type: ToastType.info,
            title: 'Already left the queue',
            message: '${entry.taskName} may have started building.',
          );
        }
      case Err(:final error):
        if (before != null) state = AsyncData(before);
        toast.show(
          type: ToastType.error,
          title: 'Cancel failed',
          message: error.message,
        );
    }
  }
}
