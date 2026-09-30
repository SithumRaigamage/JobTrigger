import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/queue_entry.dart';
import '../../common_widgets/toast_controller.dart';

part 'queue_notifier.g.dart';

/// US-JX-09: the server-wide build queue, refreshed every [_refreshEvery]
/// while the queue screen is open. The timer is cancelled on dispose; a
/// failed refresh keeps the last list rather than blanking the screen.
@riverpod
class QueueNotifier extends _$QueueNotifier {
  static const _refreshEvery = Duration(seconds: 5);

  @override
  Future<List<QueueEntry>> build() async {
    final timer = Timer(_refreshEvery, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
    final result = await ref.watch(jenkinsRepositoryProvider).fetchQueue();
    return result.fold((items) => items, (failure) => throw failure);
  }

  /// Cancels a queued item: removed from the list at once, then confirmed
  /// by the next refresh. On failure the item comes back with a toast.
  Future<void> cancel(QueueEntry entry) async {
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
