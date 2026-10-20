import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/platform/notification_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/cache/build_watch_store.dart';
import '../../../data/repositories/credentials_repository_impl.dart';
import '../../../data/repositories/jenkins_repository_impl.dart';
import '../../../domain/jenkins/jenkins_repository.dart';
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
      await runWatchCheck(
        store: BuildWatchStore(),
        repositoryFor: (serverId) => _repositoryFor(container, serverId),
        notify: NotificationService().show,
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

/// Registers the periodic background check while there are watches, and
/// cancels it when there are none. The OS decides when it actually runs
/// (15 minutes at the earliest): best effort, and the UI says so.
class BackgroundWatchScheduler {
  bool _initialized = false;

  Future<void> sync({required bool hasWatches}) async {
    try {
      if (!_initialized) {
        await Workmanager().initialize(buildWatchDispatcher);
        _initialized = true;
      }
      if (hasWatches) {
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
      // Unsupported platform (desktop dev target) or unavailable: the
      // in-app check still runs while the app is open.
    }
  }
}
