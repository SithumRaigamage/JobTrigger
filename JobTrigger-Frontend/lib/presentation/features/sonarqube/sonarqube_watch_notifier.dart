import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/platform/notification_service.dart';
import '../../../data/cache/sonarqube_watch_store.dart';
import '../../../data/credentials/active_sonarqube_credential_notifier.dart';
import '../../../data/demo/demo_mode_notifier.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/sonarqube/sonarqube_project.dart';
import '../../../domain/sonarqube/sonarqube_project_watch.dart';
import '../../../domain/sonarqube/sonarqube_repository.dart';
import '../app_lock/app_lock_notifier.dart';
import '../notifications/build_watch_notifier.dart'
    show backgroundWatchSchedulerProvider;
import '../subscription/plan_gate.dart';
import 'sonarqube_watch_runner.dart';

part 'sonarqube_watch_notifier.g.dart';

/// Why a gate watch wasn't turned on.
enum GateWatchResult {
  added,
  permissionDenied,
  noCredential,
  unavailableInDemo,

  /// P20-25: the plan has no background notifications (billing on, Free).
  requiresPro,
}

/// `US-SQ-WATCH-01`: projects watched for a failing quality gate. While the
/// app is alive it checks every [_checkEvery]; while it is closed the shared
/// background task takes over at the OS's pace. Same discipline as
/// `BuildWatchNotifier`: one pass at a time, serialized writes.
@Riverpod(keepAlive: true)
class SonarQubeWatchNotifier extends _$SonarQubeWatchNotifier {
  static const _checkEvery = Duration(minutes: 5);
  Timer? _timer;
  bool _checking = false;
  Future<void> _writes = Future.value();

  Future<T> _serially<T>(Future<T> Function() write) {
    final result = _writes.then((_) => write());
    _writes = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  @override
  List<SonarQubeProjectWatch> build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(planGateProvider, (_, _) {
      if (ref.mounted) _afterChange();
    });
    _load();
    return const [];
  }

  Future<void> _load() async {
    final watches = await ref.read(sonarQubeWatchStoreProvider).load();
    if (!ref.mounted) return;
    state = watches;
    await _afterChange();
  }

  /// P20-25: the paywall reason when the plan has no background
  /// notifications, else null. SonarQube shares the Jenkins limit: one
  /// background tier, not two.
  String? get blockedReason => ref.read(planGateProvider).backgroundWatch;

  bool isWatching(String projectKey) {
    final credentialId = ref
        .read(activeSonarQubeCredentialNotifierProvider)
        ?.id;
    return state.any(
      (watch) =>
          watch.projectKey == projectKey && watch.credentialId == credentialId,
    );
  }

  /// Turns the watch on, or off when it is already on. Off needs no
  /// permission, so it always succeeds.
  Future<GateWatchResult> toggle(SonarQubeProject project) async {
    if (isWatching(project.key)) {
      await unwatch(project.key);
      return GateWatchResult.added;
    }
    // E2 (PE-14): no stored watches and no background task in demo mode.
    if (ref.read(demoModeNotifierProvider)) {
      return GateWatchResult.unavailableInDemo;
    }
    if (blockedReason != null) return GateWatchResult.requiresPro;
    final credential = ref.read(activeSonarQubeCredentialNotifierProvider);
    if (credential == null) return GateWatchResult.noCredential;

    final granted = await ref
        .read(notificationServiceProvider)
        .requestPermission();
    if (!granted) return GateWatchResult.permissionDenied;

    final watch = SonarQubeProjectWatch(
      credentialId: credential.id,
      projectKey: project.key,
      projectName: project.name,
    );
    await _edit(
      (watches) => [
        for (final existing in watches)
          if (existing.key != watch.key) existing,
        watch,
      ],
    );
    return GateWatchResult.added;
  }

  Future<void> unwatch(String projectKey) => _edit(
    (watches) => [
      for (final existing in watches)
        if (existing.projectKey != projectKey) existing,
    ],
  );

  /// Applies [change] to what is stored now (the background task may have
  /// written since), not to this notifier's possibly older copy.
  Future<void> _edit(
    List<SonarQubeProjectWatch> Function(List<SonarQubeProjectWatch> watches)
    change,
  ) async {
    final store = ref.read(sonarQubeWatchStoreProvider);
    final updated = await _serially(() async {
      final next = change(await store.load());
      await store.save(next);
      return next;
    });
    if (!ref.mounted) return;
    state = updated;
    await _afterChange();
  }

  /// One pass now. A tick that arrives while a pass runs is skipped.
  Future<void> check() async {
    if (_checking || ref.read(demoModeNotifierProvider)) return;
    _checking = true;
    final List<SonarQubeProjectWatch> remaining;
    try {
      remaining = await runSonarQubeWatchCheck(
        store: ref.read(sonarQubeWatchStoreProvider),
        repositoryFor: _repositoryFor,
        // AUD-54: no project names while the app lock is on. Read from
        // storage, like the background task.
        notify: (notification) async {
          final shown = await readAppLockEnabled()
              ? notification.redacted()
              : notification;
          await ref
              .read(notificationServiceProvider)
              .showAlert(id: shown.id, title: shown.title, body: shown.body);
        },
        serialize: _serially,
      );
    } finally {
      _checking = false;
    }
    if (!ref.mounted) return;
    state = remaining;
    await _afterChange();
  }

  Future<SonarQubeRepository?> _repositoryFor(String credentialId) async {
    final credential = ref.read(activeSonarQubeCredentialNotifierProvider);
    if (credential == null) return null; // Nothing configured: drop.
    // Only the active credential has a client here; a watch on another
    // credential waits for its turn rather than being dropped.
    if (credential.id != credentialId) {
      throw StateError('not the active SonarQube credential');
    }
    return ref.read(sonarQubeRepositoryProvider);
  }

  Future<void> _afterChange() async {
    _timer?.cancel();
    _timer = state.isEmpty ? null : Timer.periodic(_checkEvery, (_) => check());
    await ref
        .read(backgroundWatchSchedulerProvider)
        // P20-25: after a downgrade the watches stay stored, but nothing is
        // scheduled for them while the plan has no notifications.
        .sync(
          hasWatches: state.isNotEmpty && blockedReason == null,
          hasGateWatches: state.isNotEmpty && blockedReason == null,
        );
  }
}
