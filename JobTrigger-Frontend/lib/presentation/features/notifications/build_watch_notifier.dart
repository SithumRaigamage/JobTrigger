import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/platform/notification_service.dart';
import '../../../data/cache/build_watch_store.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/build_watch.dart';
import '../../../domain/jenkins/jenkins_build.dart';
import '../../../domain/jenkins/jenkins_job.dart';
import '../../../domain/jenkins/jenkins_repository.dart';
import '../settings/active_server_notifier.dart';
import '../settings/credentials_notifier.dart';
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
    state = [
      for (final existing in state)
        if (existing.key != watch.key) existing,
      watch,
    ];
    await ref.read(buildWatchStoreProvider).save(state);
    await _afterChange();
    return WatchResult.added;
  }

  Future<void> unwatch(BuildWatch watch) async {
    state = [
      for (final existing in state)
        if (existing.key != watch.key) existing,
    ];
    await ref.read(buildWatchStoreProvider).save(state);
    await _afterChange();
  }

  /// One pass now: notify for anything finished, drop what's done.
  Future<void> check() async {
    final remaining = await runWatchCheck(
      store: ref.read(buildWatchStoreProvider),
      repositoryFor: _repositoryFor,
      notify: ref.read(notificationServiceProvider).show,
    );
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
