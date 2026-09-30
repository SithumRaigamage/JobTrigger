import 'package:flutter_test/flutter_test.dart';
import 'package:job_trigger/data/cache/user_scoped_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    "logout clears the user's prefs and keeps the device's (AUD-28)",
    () async {
      SharedPreferences.setMockInitialValues({
        // The user's.
        'active_server_id': 's1',
        'active_github_credential_id': 'g1',
        'active_sonarqube_credential_id': 'q1',
        'build_watches': '[]',
        'pinned_jobs_s1': '[]',
        'pinned_jobs_s2': '[]',
        'selected_view_s1': 'All',
        // The device's.
        'theme_mode': 'dark',
        'reduce_transparency': true,
        'console_wrap': false,
        'app_lock_enabled': true,
        'login_saved_email': 'a@b.com',
      });

      await clearUserScopedPrefs();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {
        'theme_mode',
        'reduce_transparency',
        'console_wrap',
        'app_lock_enabled',
        'login_saved_email',
      });
    },
  );
}
