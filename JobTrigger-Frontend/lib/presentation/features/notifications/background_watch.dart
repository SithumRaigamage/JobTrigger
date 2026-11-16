import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/platform/notification_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/cache/build_watch_store.dart';
import '../../../data/cache/sonarqube_watch_store.dart';
import '../../../data/datasources/sonarqube_client_factory.dart';
import '../../../data/repositories/credentials_repository_impl.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../data/repositories/sonarqube_credentials_repository_impl.dart';
import '../../../data/repositories/sonarqube_repository_impl.dart';
import '../../../domain/jenkins/jenkins_repository.dart';
import '../../../domain/sonarqube/sonarqube_repository.dart';
import '../sonarqube/sonarqube_watch_runner.dart';
import '../app_lock/app_lock_notifier.dart';
import 'watch_runner.dart';

/// Unique name of the periodic background check (US-JX-10).
const buildWatchTaskName = 'jobtrigger.buildWatch';

/// Entry point the OS calls for the background check, in its own isolate.
/// Rebuilds credentials the same way the app does: JWT from secure
/// storage, then servers from the backend. Nothing is persisted anywhere
/// new, and a notification carries only job name, number, result, and
/// duration.
@pragma('vm:entry-point')
void buildWatchDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final container = ProviderContainer();
    try {
      // AUD-54: no job names while the app lock is on.
      final hideNames = await readAppLockEnabled();
      final notifications = NotificationService();
      await runWatchCheck(
        store: BuildWatchStore(),
        repositoryFor: (serverId) => _repositoryFor(container, serverId),
        notify: (notification) => notifications.show(
          hideNames ? notification.redacted() : notification,
        ),
      );
      // US-SQ-WATCH-01: the same task checks gate watches, best effort.
      await runSonarQubeWatchCheck(
        store: SonarQubeWatchStore(),
        repositoryFor: (credentialId) =>
            _gateRepositoryFor(container, credentialId),
        notify: (notification) => notifications.showAlert(
          id: notification.id,
          title: notification.title,
          body: notification.body,
        ),
      );
    } on Object {
      // Best effort by design: never fail the OS task, retry next period.
    } finally {
      container.dispose();
    }
    return true;
  });
}

/// Null when the credentials are gone (logged out, or the server was
/// deleted), which drops the watch. Throws when they can't be reached right
/// now, which keeps it.
Future<JenkinsRepository?> _repositoryFor(
  ProviderContainer container,
  String serverId,
) async {
  final token = await container.read(secureStorageProvider).readToken();
  if (token == null) return null;
  final servers = await container
      .read(credentialsRepositoryProvider)
      .fetchAll();
  return switch (servers) {
    Ok(:final value) => switch (value.where((s) => s.id == serverId)) {
      final match when match.isNotEmpty => jenkinsRepositoryForServer(
        match.first,
      ),
      _ => null,
    },
    Err(error: AuthFailure()) => null,
    Err(:final error) => throw error,
  };
}

/// Null when the credential is gone (deleted, or signed out), which drops
/// its gate watches. Throws when it can't be reached right now, which keeps
/// them.
Future<SonarQubeRepository?> _gateRepositoryFor(
  ProviderContainer container,
  String credentialId,
) async {
  final token = await container.read(secureStorageProvider).readToken();
  if (token == null) return null;
  final credentials = await container
      .read(sonarQubeCredentialsRepositoryProvider)
      .fetchAll();
  return switch (credentials) {
    Ok(:final value) => switch (value.where((c) => c.id == credentialId)) {
      // AUD-63: a credential the backend could not decrypt has no token;
      // nothing is sent in its place.
      final match when match.isNotEmpty => SonarQubeRepositoryImpl(
        buildSonarQubeDio(
          baseUrl: match.first.baseUrl,
          token: match.first.secret,
        ),
        organization: match.first.defaultOrganization,
      ),
      _ => null,
    },
    Err(error: AuthFailure()) => null,
    Err(:final error) => throw error,
  };
}

/// Registers the periodic background check while there are watches, and
/// cancels it when there are none. The OS decides when it actually runs
/// (15 minutes at the earliest): best effort, and the UI says so.
///
/// Only Android and iOS schedule anything. On the desktop dev target there
/// is nothing to schedule, and the Linux plugin shells out to `systemd`
/// (`Process.run`), which is what left a pending timer in every widget test
/// on CI (AUD-42). [isSupported] is the host OS, deliberately not
/// `defaultTargetPlatform`, which tests set to Android.
class BackgroundWatchScheduler {
  BackgroundWatchScheduler({bool? isSupported})
    : isSupported = isSupported ?? (Platform.isAndroid || Platform.isIOS);

  final bool isSupported;
  bool _initialized = false;

  Future<void> sync({
    required bool hasWatches,
    // US-SQ-WATCH-01: SonarQube gate watches ride the same task.
    bool hasGateWatches = false,
  }) async {
    if (!isSupported) return;
    try {
      if (!_initialized) {
        await Workmanager().initialize(buildWatchDispatcher);
        _initialized = true;
      }
      if (hasWatches || hasGateWatches) {
        await Workmanager().registerPeriodicTask(
          buildWatchTaskName,
          buildWatchTaskName,
          frequency: const Duration(minutes: 15),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );
      } else {
        await Workmanager().cancelByUniqueName(buildWatchTaskName);
      }
    } on Object {
      // Unavailable (e.g. background fetch disabled): the in-app check
      // still runs while the app is open.
    }
  }
}
