import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/credentials_repository_impl.dart';
import '../../../domain/credential/jenkins_server.dart';
import 'credentials_notifier.dart';

part 'active_server_notifier.g.dart';

const _activeServerIdKey = 'active_server_id';

/// Currently active Jenkins server. Ported from `ActiveServerManager.swift`,
/// but persists an id (not just a URL string) per `docs/state-management.md`.
///
/// A plain `Notifier`, not `AsyncNotifier` (state is `JenkinsServer?`,
/// available synchronously) — `build()` kicks off async rehydration and
/// updates `state` once it resolves, same pattern as `ThemeNotifier`
/// (Phase 1). Reuses `credentialsNotifierProvider`'s already-fetched list
/// rather than re-fetching — see `docs/state-management.md`'s "Rules of
/// thumb".
@riverpod
class ActiveServerNotifier extends _$ActiveServerNotifier {
  @override
  JenkinsServer? build() {
    _rehydrate();
    return null;
  }

  Future<void> _rehydrate() async {
    final List<JenkinsServer> servers;
    try {
      servers = await ref.read(credentialsNotifierProvider.future);
    } catch (_) {
      // Credentials failed to load — leave state null; the settings screen
      // surfaces the underlying AppFailure via credentialsNotifierProvider
      // directly.
      return;
    }
    if (servers.isEmpty) {
      state = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final persistedId = prefs.getString(_activeServerIdKey);

    final resolved =
        _findById(servers, persistedId) ??
        _findDefault(servers) ??
        servers.first;
    state = resolved;
    await prefs.setString(_activeServerIdKey, resolved.id);
  }

  Future<void> setActiveServer(JenkinsServer server) async {
    state = server;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeServerIdKey, server.id);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeServerIdKey);
  }

  /// P3-09: deletes [server] via the repository, then — if it was the
  /// active one — falls back to another `isDefault`/first remaining
  /// server, or clears the active server entirely if none are left.
  /// Lives here (not in the settings screen widget) so it's unit-testable
  /// without pumping a widget tree, per CLAUDE.md §5's "no business logic
  /// in widgets" rule.
  Future<Result<void, AppFailure>> deleteServer(JenkinsServer server) async {
    final wasActive = server.id == state?.id;

    final result = await ref
        .read(credentialsRepositoryProvider)
        .delete(server.id);
    if (result case Err()) return result;

    await ref.read(credentialsNotifierProvider.notifier).refresh();
    if (!wasActive) return const Ok(null);

    final remaining = await ref.read(credentialsNotifierProvider.future);
    if (remaining.isEmpty) {
      await clear();
    } else {
      final fallback = remaining.firstWhere(
        (candidate) => candidate.isDefault,
        orElse: () => remaining.first,
      );
      await setActiveServer(fallback);
    }
    return const Ok(null);
  }

  static JenkinsServer? _findById(List<JenkinsServer> servers, String? id) {
    if (id == null) return null;
    for (final server in servers) {
      if (server.id == id) return server;
    }
    return null;
  }

  static JenkinsServer? _findDefault(List<JenkinsServer> servers) {
    for (final server in servers) {
      if (server.isDefault) return server;
    }
    return null;
  }
}
