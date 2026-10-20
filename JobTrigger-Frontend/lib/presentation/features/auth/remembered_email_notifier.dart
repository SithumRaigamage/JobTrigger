import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'remembered_email_notifier.g.dart';

const _rememberedEmailKey = 'login_saved_email';

/// Written by builds before AUD-01 — the account password in plaintext
/// `shared_preferences`. Never written again; deleted on first load so
/// already-installed copies don't keep it around.
const _legacyPasswordKey = 'login_saved_password';

/// "Remember me" on the login screen: remembers the **email only**.
///
/// The password is deliberately never persisted (AUD-01, `CLAUDE.md` §7) —
/// a stored JWT already keeps the session alive across restarts
/// (US-AUTH-03), so a saved password would add exposure and no value. The
/// email isn't a secret, so `shared_preferences` is the right store for it,
/// same as `ThemeNotifier`.
@riverpod
class RememberedEmailNotifier extends _$RememberedEmailNotifier {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyPasswordKey);
    return prefs.getString(_rememberedEmailKey);
  }

  Future<void> remember(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rememberedEmailKey, email);
    // May be called with no listener left (e.g. from `LoginNotifier` as
    // the login screen is replaced) -- the write above is what matters.
    if (ref.mounted) state = AsyncData(email);
  }

  Future<void> forget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberedEmailKey);
    if (ref.mounted) state = const AsyncData(null);
  }
}
