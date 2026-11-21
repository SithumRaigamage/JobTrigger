import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/error/app_failure.dart';
import 'default_choice_sync.dart';
import '../../core/error/result.dart';
import '../cache/job_tree_cache.dart';
import '../repositories/credentials_repository_impl.dart';
import '../../domain/credential/jenkins_server.dart';
import '../../domain/team/team_server.dart';
import 'credentials_notifier.dart';
import 'team_servers_notifier.dart';

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
    // AUD-46: the active entry is a snapshot (URL, username, secret).
    // Whenever the saved list reloads — after an edit, from any screen —
    // swap in the fresh copy with the same id, so an edited secret or URL
    // takes effect at once instead of after a restart.
    // Weak: observing must not keep the list alive or retrying on its own;
    // the screens that show it own that.
    // Registered after `_rehydrate` starts: its first read mounts the list
    // synchronously, before this notifier has any state to compare.
    ref.listen(credentialsNotifierProvider, (_, next) {
      final current = state;
      final fresh = next.value;
      if (fresh == null) return;
      if (current == null) {
        // US-CRED-02: the first server saved (or the first list after the
        // last one was deleted) becomes active, by the same rule as a cold
        // start. Only real data, after the first rehydration: an error
        // still carrying an old list must not bring a server back.
        if (_rehydrated && next is AsyncData && fresh.isNotEmpty) {
          _adopt(fresh);
        }
        return;
      }
      final match = _findById(fresh, current.id);
      if (match != null && match != current) state = match;
      // Owner decision 2026-11-21: retry a pending default, else follow
      // the backend's (e.g. one chosen on the website, US-WEB-18).
      if (_rehydrated && next is AsyncData) unawaited(_reconcile(fresh));
    }, weak: true);
    // US-SUB-11 AC17: a team server that stops being shared (unshared,
    // removed from the team, the team lapsed) stops being the active one.
    ref.listen(teamServersNotifierProvider, (_, next) {
      final current = state;
      final shared = next.value;
      if (current == null || shared == null) return;
      if (!TeamServer.isTeamId(current.id)) return;
      final match = _findTeamServer(shared, current.id);
      if (match == null) {
        _fallBackToOwn();
      } else if (match != current) {
        state = match;
      }
    }, weak: true);
    return null;
  }

  /// Only when the saved id is a team server's, and only into an empty slot:
  /// anything chosen meanwhile (a server just added) wins.
  Future<void> _restoreTeamServer() async {
    final String? persistedId;
    try {
      persistedId = (await SharedPreferences.getInstance()).getString(
        _activeServerIdKey,
      );
    } catch (_) {
      return;
    }
    if (!TeamServer.isTeamId(persistedId)) return;
    final shared = _findTeamServer(await _teamServers(), persistedId);
    if (shared != null && ref.mounted && state == null) state = shared;
  }

  Future<List<TeamServer>> _teamServers() async {
    try {
      return await ref.read(teamServersNotifierProvider.future);
    } catch (_) {
      return const [];
    }
  }

  static JenkinsServer? _findTeamServer(List<TeamServer> shared, String? id) {
    for (final team in shared) {
      if (team.server.id == id) return team.server;
    }
    return null;
  }

  Future<void> _fallBackToOwn() async {
    // Awaited, not the cached value: off the Settings screen nothing keeps
    // the list alive, and an empty cache would clear the active server.
    final List<JenkinsServer> own;
    try {
      own = await ref.read(credentialsNotifierProvider.future);
    } catch (_) {
      return;
    }
    if (!ref.mounted) return;
    if (own.isEmpty) {
      await clear();
    } else {
      await setActiveServer(_findDefault(own) ?? own.first);
    }
  }

  /// Set once the first rehydration has finished (or given up), so the
  /// listener above never races it for the persisted choice.
  bool _rehydrated = false;

  Future<void> _rehydrate() async {
    final List<JenkinsServer> servers;
    try {
      servers = await ref.read(credentialsNotifierProvider.future);
    } catch (_) {
      // Credentials failed to load — leave state null; the settings screen
      // surfaces the underlying AppFailure via credentialsNotifierProvider
      // directly.
      _rehydrated = true;
      return;
    }
    try {
      await _adopt(servers);
    } finally {
      _rehydrated = true;
    }
  }

  /// The persisted choice if still saved, else the default, else the first.
  Future<void> _adopt(List<JenkinsServer> servers) async {
    if (servers.isEmpty) {
      state = null;
      // US-SUB-11 AC17: someone with only team servers gets theirs back.
      unawaited(_restoreTeamServer());
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final persistedId = prefs.getString(_activeServerIdKey);

    // US-SUB-11 AC17: an active team server comes back from the team's list
    // while it is still shared; otherwise the user's own server is used.
    if (TeamServer.isTeamId(persistedId)) {
      final shared = _findTeamServer(await _teamServers(), persistedId);
      if (shared != null) {
        state = shared;
        return;
      }
    }

    final resolved = pickActive(
      servers,
      idOf: (item) => item.id,
      isDefault: (item) => item.isDefault,
      pendingId: await _sync.pending(),
      savedId: persistedId,
    )!;
    state = resolved;
    await prefs.setString(_activeServerIdKey, resolved.id);
    // No default on the backend, or one still waiting: push this one.
    if (!resolved.isDefault) unawaited(_push(resolved.id));
  }

  Future<void> setActiveServer(JenkinsServer server) async {
    state = server;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeServerIdKey, server.id);
    // Owner decision 2026-11-21: the backend default follows; if that
    // fails the choice stays on the phone and is retried. A team server is
    // not one of the user's own, so the backend has no default to move.
    if (!TeamServer.isTeamId(server.id)) unawaited(_push(server.id));
  }

  static const _sync = DefaultChoiceSync('active_server_pending_default');

  Future<void> _push(String id) async {
    final ok = await _sync.push(
      id,
      ref.read(credentialsRepositoryProvider).switchActive,
    );
    // The list's default flags changed; reload it so every screen agrees.
    if (ok && ref.mounted) ref.invalidate(credentialsNotifierProvider);
  }

  Future<void> _reconcile(List<JenkinsServer> fresh) async {
    // US-SUB-11 AC17: an active team server stays active while shared; the
    // own list's default only applies to the user's own servers.
    if (TeamServer.isTeamId(state?.id)) return;
    final pendingId = await _sync.pending();
    if (!ref.mounted) return;
    if (pendingId != null) {
      if (_findById(fresh, pendingId) == null) {
        await _sync.drop();
      } else {
        await _push(pendingId);
      }
      return;
    }
    final backendDefault = _findDefault(fresh);
    if (backendDefault == null || backendDefault.id == state?.id) return;
    state = backendDefault;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeServerIdKey, backendDefault.id);
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
    // US-JX-20: drop that server's offline listings with it.
    try {
      await ref.read(jobTreeCacheProvider).clearServer(server.id);
    } on Object {
      // Best effort: the OS may already have purged the cache directory.
    }
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
