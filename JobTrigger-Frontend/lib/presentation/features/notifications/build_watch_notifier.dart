import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/platform/notification_service.dart';
import '../../../data/cache/build_watch_store.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/build_watch.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/jenkins_repository.dart';
import '../app_lock/app_lock_notifier.dart';
import '../../../data/credentials/active_server_notifier.dart';
import '../../../data/credentials/credentials_notifier.dart';
import 'background_watch.dart';
import 'watch_runner.dart';

part 'build_watch_notifier.g.dart';

/// The background scheduler, behind a provider so tests can stub it.
@Riverpod(keepAlive: true)
BackgroundWatchScheduler backgroundWatchScheduler(Ref ref) =>
    BackgroundWatchScheduler();

/// Why a watch wasn't added.
enum WatchResult { added, permissionDenied, noServer }

/// US-JX-10: the builds and jobs the user wants a notification for. While
/// the app is alive, checks every [_checkEvery]. While it's suspended, the
/// background task takes over at the OS's pace. The timer is cancelled on
/// dispose, the same discipline as the other pollers.
@Riverpod(keepAlive: true)
class BuildWatchNotifier extends _$BuildWatchNotifier {
  static const _checkEvery = Duration(seconds: 30);
  Timer? _timer;

  /// AUD-49: a pass can outlast the 30s tick (two unreachable servers are
  /// enough), and overlapping passes notified the same build twice.
  bool _checking = false;

  /// AUD-49: store writes from this notifier, one at a time, so an add or
  /// remove can't land between a pass's final load and its save.
  Future<void> _writes = Future.value();

  Future<T> _serially<T>(Future<T> Function() write) {
    final result = _writes.then((_) => write());
    _writes = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  @override
  List<BuildWatch> build() {
    ref.onDispose(() => _timer?.cancel());
    _load();
    return const [];
  }

  Future<void> _load() async {
    final watches = await ref.read(buildWatchStoreProvider).load();
    if (!ref.mounted) return;
    state = watches;
    await _afterChange();
  }

  bool isWatching({required String jobUrl, int? buildNumber}) => state.any(
    (watch) => watch.jobUrl == jobUrl && watch.buildNumber == buildNumber,
  );

  /// Notify once when [build] finishes.
  Future<WatchResult> watchBuild(JenkinsJob job, JenkinsBuild build) => _add(
    (serverId) => BuildWatch(
      serverId: serverId,
      jobUrl: job.url,
      jobLabel: job.label,
      buildNumber: build.number,
    ),
  );

  /// Notify whenever a new build of [job] finishes.
  Future<WatchResult> watchJob(JenkinsJob job) => _add(
    (serverId) => BuildWatch(
      serverId: serverId,
      jobUrl: job.url,
      jobLabel: job.label,
      lastNotified: job.lastBuild?.number ?? 0,
    ),
  );

  Future<WatchResult> _add(BuildWatch Function(String serverId) create) async {
    final serverId = ref.read(activeServerNotifierProvider)?.id;
    if (serverId == null) return WatchResult.noServer;
    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    if (!granted) return WatchResult.permissionDenied;
    final watch = create(serverId);
    await _edit(
      (watches) => [
        for (final existing in watches)
          if (existing.key != watch.key) existing,
        watch,
      ],
    );
    return WatchResult.added;
  }

  Future<void> unwatch(BuildWatch watch) => _edit(
    (watches) => [
      for (final existing in watches)
        if (existing.key != watch.key) existing,
    ],
  );

  /// Applies [change] to what's stored now (the background task may have
  /// written since), not to this notifier's possibly older copy.
  Future<void> _edit(
    List<BuildWatch> Function(List<BuildWatch> watches) change,
  ) async {
    final store = ref.read(buildWatchStoreProvider);
    final updated = await _serially(() async {
      final next = change(await store.load());
      await store.save(next);
      return next;
    });
    if (!ref.mounted) return;
    state = updated;
    await _afterChange();
  }

  /// One pass now: notify for anything finished, drop what's done. A tick
  /// that arrives while a pass is running is skipped (AUD-49).
  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    final List<BuildWatch> remaining;
    try {
      // Only the final merge waits its turn: an add during the network
      // part of a pass is saved at once, and the merge keeps it.
      remaining = await runWatchCheck(
        store: ref.read(buildWatchStoreProvider),
        repositoryFor: _repositoryFor,
        // AUD-54: no job names while the app lock is on. Read from storage,
        // like the background task, since a pass at launch can run before
        // the lock notifier has loaded its settings.
        notify: (notification) async => ref
            .read(notificationServiceProvider)
            .show(
              await readAppLockEnabled()
                  ? notification.redacted()
                  : notification,
            ),
        serialize: _serially,
      );
    } finally {
      _checking = false;
    }
    if (!ref.mounted) return;
    state = remaining;
    await _afterChange();
  }

  Future<JenkinsRepository?> _repositoryFor(String serverId) async {
    // Throws on a network failure, which keeps the watch for next time.
    final servers = await ref.read(credentialsNotifierProvider.future);
    final match = servers.where((server) => server.id == serverId);
    return match.isEmpty ? null : jenkinsRepositoryForServer(match.first);
  }

  Future<void> _afterChange() async {
    _timer?.cancel();
    _timer = state.isEmpty ? null : Timer.periodic(_checkEvery, (_) => check());
    await ref
        .read(backgroundWatchSchedulerProvider)
        .sync(hasWatches: state.isNotEmpty);
  }
}
