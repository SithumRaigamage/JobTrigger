import 'package:shared_preferences/shared_preferences.dart';

/// AUD-28: the `shared_preferences` entries that belong to the signed-in
/// user, removed on logout so the next person to sign in on this device
/// starts clean. Keep in step with the keys their owners write.
///
/// Kept on purpose: device preferences (theme, reduce transparency,
/// console options, app lock) and the remembered login email, which the
/// user opted into precisely so it survives signing out.
const userScopedPrefKeys = {
  'active_server_id', // ActiveServerNotifier
  'active_github_credential_id', // ActiveGitHubCredentialNotifier
  'active_sonarqube_credential_id', // ActiveSonarQubeCredentialNotifier
  'build_watches', // BuildWatchStore (US-JX-10)
};

/// Per-server entries, keyed `<prefix><serverId>`.
const userScopedPrefPrefixes = {
  'pinned_jobs_', // PinnedJobsNotifier (US-JX-11)
  'selected_view_', // ViewsNotifier (US-JX-17)
};

Future<void> clearUserScopedPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  for (final key in prefs.getKeys().toList()) {
    if (userScopedPrefKeys.contains(key) ||
        userScopedPrefPrefixes.any(key.startsWith)) {
      await prefs.remove(key);
    }
  }
}
