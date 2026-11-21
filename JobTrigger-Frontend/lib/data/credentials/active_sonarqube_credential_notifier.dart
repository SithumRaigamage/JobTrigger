import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../cache/sonarqube_cache.dart';
import 'default_choice_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/error/app_failure.dart';
import '../../core/error/result.dart';
import '../repositories/sonarqube_credentials_repository_impl.dart';
import '../../domain/credential/sonarqube_credential.dart';
import 'sonarqube_credentials_notifier.dart';

part 'active_sonarqube_credential_notifier.g.dart';

const _activeSonarQubeCredentialIdKey = 'active_sonarqube_credential_id';

/// Currently active SonarQube credential. Mirrors
/// `ActiveGitHubCredentialNotifier`'s shape exactly (`US-SQ-CRED-03`) —
/// entirely independent state, its own `SharedPreferences` key, its own
/// fallback logic. Switching this never touches any other tool's active
/// credential and vice versa (`NFR-SEC-03`).
@riverpod
class ActiveSonarQubeCredentialNotifier
    extends _$ActiveSonarQubeCredentialNotifier {
  @override
  SonarQubeCredential? build() {
    _rehydrate();
    // AUD-46: the active entry is a snapshot (URL, username, secret).
    // Whenever the saved list reloads — after an edit, from any screen —
    // swap in the fresh copy with the same id, so an edited secret or URL
    // takes effect at once instead of after a restart.
    // Weak: observing must not keep the list alive or retrying on its own;
    // the screens that show it own that.
    // Registered after `_rehydrate` starts: its first read mounts the list
    // synchronously, before this notifier has any state to compare.
    ref.listen(sonarQubeCredentialsNotifierProvider, (_, next) {
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
    final List<SonarQubeCredential> credentials;
    try {
      credentials = await ref.read(sonarQubeCredentialsNotifierProvider.future);
    } catch (_) {
      // Credentials failed to load — leave state null; the settings screen
      // surfaces the underlying AppFailure via
      // sonarQubeCredentialsNotifierProvider directly.
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
  Future<void> _adopt(List<SonarQubeCredential> credentials) async {
    if (credentials.isEmpty) {
      state = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final persistedId = prefs.getString(_activeSonarQubeCredentialIdKey);

    final resolved = pickActive(
      credentials,
      idOf: (item) => item.id,
      isDefault: (item) => item.isDefault,
      pendingId: await _sync.pending(),
      savedId: persistedId,
    )!;
    state = resolved;
    await prefs.setString(_activeSonarQubeCredentialIdKey, resolved.id);
    // No default on the backend, or one still waiting: push this one.
    if (!resolved.isDefault) unawaited(_push(resolved.id));
  }

  Future<void> setActiveCredential(SonarQubeCredential credential) async {
    state = credential;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSonarQubeCredentialIdKey, credential.id);
    // Owner decision 2026-11-21: the backend default follows; if that
    // fails the choice stays on the phone and is retried.
    unawaited(_push(credential.id));
  }

  static const _sync = DefaultChoiceSync('active_sonarqube_pending_default');

  Future<void> _push(String id) async {
    final ok = await _sync.push(
      id,
      ref.read(sonarQubeCredentialsRepositoryProvider).switchActive,
    );
    // The list's default flags changed; reload it so every screen agrees.
    if (ok && ref.mounted) ref.invalidate(sonarQubeCredentialsNotifierProvider);
  }

  Future<void> _reconcile(List<SonarQubeCredential> fresh) async {
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
    await prefs.setString(_activeSonarQubeCredentialIdKey, backendDefault.id);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSonarQubeCredentialIdKey);
  }

  /// Deletes [credential] via the repository, then — if it was the active
  /// one — falls back to another `isDefault`/first remaining credential,
  /// or clears the active credential entirely if none are left. Mirrors
  /// `ActiveGitHubCredentialNotifier.deleteCredential`'s shape exactly.
  Future<Result<void, AppFailure>> deleteCredential(
    SonarQubeCredential credential,
  ) async {
    final wasActive = credential.id == state?.id;

    final result = await ref
        .read(sonarQubeCredentialsRepositoryProvider)
        .delete(credential.id);
    if (result case Err()) return result;

    // US-SQ-OFFLINE-01: the deleted credential's saved copy goes with it.
    try {
      await ref.read(sonarQubeCacheProvider).clearCredential(credential.id);
    } on Object {
      // Best effort: the OS may already have purged the cache directory.
    }
    await ref.read(sonarQubeCredentialsNotifierProvider.notifier).refresh();
    if (!wasActive) return const Ok(null);

    final remaining = await ref.read(
      sonarQubeCredentialsNotifierProvider.future,
    );
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

  static SonarQubeCredential? _findById(
    List<SonarQubeCredential> credentials,
    String? id,
  ) {
    if (id == null) return null;
    for (final credential in credentials) {
      if (credential.id == id) return credential;
    }
    return null;
  }

  static SonarQubeCredential? _findDefault(
    List<SonarQubeCredential> credentials,
  ) {
    for (final credential in credentials) {
      if (credential.isDefault) return credential;
    }
    return null;
  }
}
