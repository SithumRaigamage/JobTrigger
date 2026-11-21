import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/error/app_failure.dart';
import 'default_choice_sync.dart';
import '../../core/error/result.dart';
import '../repositories/github_credentials_repository_impl.dart';
import '../../domain/credential/github_credential.dart';
import 'github_credentials_notifier.dart';

part 'active_github_credential_notifier.g.dart';

const _activeGitHubCredentialIdKey = 'active_github_credential_id';

/// Currently active GitHub credential. Mirrors `ActiveServerNotifier`'s
/// shape exactly (`US-GH-CRED-03`) — entirely independent state, its own
/// `SharedPreferences` key, its own fallback logic. Switching this never
/// touches `ActiveServerNotifier`'s state and vice versa: two unrelated
/// "active" concepts, not a single "active CI tool" selector
/// (`NFR-SEC-03`).
@riverpod
class ActiveGitHubCredentialNotifier extends _$ActiveGitHubCredentialNotifier {
  @override
  GitHubCredential? build() {
    _rehydrate();
    // AUD-46: the active entry is a snapshot (URL, username, secret).
    // Whenever the saved list reloads — after an edit, from any screen —
    // swap in the fresh copy with the same id, so an edited secret or URL
    // takes effect at once instead of after a restart.
    // Weak: observing must not keep the list alive or retrying on its own;
    // the screens that show it own that.
    // Registered after `_rehydrate` starts: its first read mounts the list
    // synchronously, before this notifier has any state to compare.
    ref.listen(gitHubCredentialsNotifierProvider, (_, next) {
      final current = state;
      final fresh = next.value;
      if (fresh == null) return;
      if (current == null) {
        // The first credential saved (or the first list after the last one
        // was deleted) becomes active, by the same rule as a cold start
        // (as US-CRED-02 for Jenkins). Only real data, after the first
        // rehydration: an error still carrying an old list must not bring
        // a credential back.
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
    return null;
  }

  /// Set once the first rehydration has finished (or given up), so the
  /// listener above never races it for the persisted choice.
  bool _rehydrated = false;

  Future<void> _rehydrate() async {
    final List<GitHubCredential> credentials;
    try {
      credentials = await ref.read(gitHubCredentialsNotifierProvider.future);
    } catch (_) {
      // Credentials failed to load — leave state null; the settings screen
      // surfaces the underlying AppFailure via
      // gitHubCredentialsNotifierProvider directly.
      _rehydrated = true;
      return;
    }
    try {
      await _adopt(credentials);
    } finally {
      _rehydrated = true;
    }
  }

  /// The persisted choice if still saved, else the default, else the first.
  Future<void> _adopt(List<GitHubCredential> credentials) async {
    if (credentials.isEmpty) {
      state = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final persistedId = prefs.getString(_activeGitHubCredentialIdKey);

    final resolved = pickActive(
      credentials,
      idOf: (item) => item.id,
      isDefault: (item) => item.isDefault,
      pendingId: await _sync.pending(),
      savedId: persistedId,
    )!;
    state = resolved;
    await prefs.setString(_activeGitHubCredentialIdKey, resolved.id);
    // No default on the backend, or one still waiting: push this one.
    if (!resolved.isDefault) unawaited(_push(resolved.id));
  }

  Future<void> setActiveCredential(GitHubCredential credential) async {
    state = credential;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeGitHubCredentialIdKey, credential.id);
    // Owner decision 2026-11-21: the backend default follows; if that
    // fails the choice stays on the phone and is retried.
    unawaited(_push(credential.id));
  }

  static const _sync = DefaultChoiceSync('active_github_pending_default');

  Future<void> _push(String id) async {
    final ok = await _sync.push(
      id,
      ref.read(gitHubCredentialsRepositoryProvider).switchActive,
    );
    // The list's default flags changed; reload it so every screen agrees.
    if (ok && ref.mounted) ref.invalidate(gitHubCredentialsNotifierProvider);
  }

  Future<void> _reconcile(List<GitHubCredential> fresh) async {
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
    await prefs.setString(_activeGitHubCredentialIdKey, backendDefault.id);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeGitHubCredentialIdKey);
  }

  /// Deletes [credential] via the repository, then — if it was the active
  /// one — falls back to another `isDefault`/first remaining credential,
  /// or clears the active credential entirely if none are left. Mirrors
  /// `ActiveServerNotifier.deleteServer`'s shape exactly.
  Future<Result<void, AppFailure>> deleteCredential(
    GitHubCredential credential,
  ) async {
    final wasActive = credential.id == state?.id;

    final result = await ref
        .read(gitHubCredentialsRepositoryProvider)
        .delete(credential.id);
    if (result case Err()) return result;

    await ref.read(gitHubCredentialsNotifierProvider.notifier).refresh();
    if (!wasActive) return const Ok(null);

    final remaining = await ref.read(gitHubCredentialsNotifierProvider.future);
    if (remaining.isEmpty) {
      await clear();
    } else {
      final fallback = remaining.firstWhere(
        (candidate) => candidate.isDefault,
        orElse: () => remaining.first,
      );
      await setActiveCredential(fallback);
    }
    return const Ok(null);
  }

  static GitHubCredential? _findById(
    List<GitHubCredential> credentials,
    String? id,
  ) {
    if (id == null) return null;
    for (final credential in credentials) {
      if (credential.id == id) return credential;
    }
    return null;
  }

  static GitHubCredential? _findDefault(List<GitHubCredential> credentials) {
    for (final credential in credentials) {
      if (credential.isDefault) return credential;
    }
    return null;
  }
}
