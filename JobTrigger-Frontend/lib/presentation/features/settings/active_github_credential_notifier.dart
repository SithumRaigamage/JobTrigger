import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../data/repositories/github_credentials_repository_impl.dart';
import '../../../domain/credential/github_credential.dart';
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
    return null;
  }

  Future<void> _rehydrate() async {
    final List<GitHubCredential> credentials;
    try {
      credentials = await ref.read(gitHubCredentialsNotifierProvider.future);
    } catch (_) {
      // Credentials failed to load — leave state null; the settings screen
      // surfaces the underlying AppFailure via
      // gitHubCredentialsNotifierProvider directly.
      return;
    }
    if (credentials.isEmpty) {
      state = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final persistedId = prefs.getString(_activeGitHubCredentialIdKey);

    final resolved =
        _findById(credentials, persistedId) ??
        _findDefault(credentials) ??
        credentials.first;
    state = resolved;
    await prefs.setString(_activeGitHubCredentialIdKey, resolved.id);
  }

  Future<void> setActiveCredential(GitHubCredential credential) async {
    state = credential;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeGitHubCredentialIdKey, credential.id);
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
