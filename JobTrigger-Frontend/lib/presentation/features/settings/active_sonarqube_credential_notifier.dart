import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/sonarqube_credentials_repository_impl.dart';
import '../../../domain/credential/sonarqube_credential.dart';
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
      if (current == null || fresh == null) return;
      final match = _findById(fresh, current.id);
      if (match != null && match != current) state = match;
    }, weak: true);
    return null;
  }

  Future<void> _rehydrate() async {
    final List<SonarQubeCredential> credentials;
    try {
      credentials = await ref.read(sonarQubeCredentialsNotifierProvider.future);
    } catch (_) {
      // Credentials failed to load — leave state null; the settings screen
      // surfaces the underlying AppFailure via
      // sonarQubeCredentialsNotifierProvider directly.
      return;
    }
    if (credentials.isEmpty) {
      state = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final persistedId = prefs.getString(_activeSonarQubeCredentialIdKey);

    final resolved =
        _findById(credentials, persistedId) ??
        _findDefault(credentials) ??
        credentials.first;
    state = resolved;
    await prefs.setString(_activeSonarQubeCredentialIdKey, resolved.id);
  }

  Future<void> setActiveCredential(SonarQubeCredential credential) async {
    state = credential;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSonarQubeCredentialIdKey, credential.id);
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
