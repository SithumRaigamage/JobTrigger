import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'first_run_notifier.g.dart';

/// PI-08 / IMP-74: whether this user has triggered a build from the app.
/// User-scoped (see `userScopedPrefKeys`), so a new sign-in starts clean.
const firstRunTriggeredKey = 'first_run_triggered';

/// PI-08 / IMP-74: whether the user dismissed the first-run card. Also
/// user-scoped, so the next person to use this device sees their own card.
const firstRunDismissedKey = 'first_run_dismissed';

typedef FirstRunState = ({bool triggered, bool dismissed});

/// Local milestones for the first-run card. The "connected" and "alerts"
/// steps are read live from the credential and watch providers; only the
/// "triggered" and "dismissed" flags need storing.
///
/// Follows the synchronous-build pattern from `ServerSafetyNotifier`: state
/// starts empty and fills from `shared_preferences` in the background, so
/// widgets can `ref.watch` it without handling an `AsyncValue`.
@Riverpod(keepAlive: true)
class FirstRunNotifier extends _$FirstRunNotifier {
  @override
  FirstRunState build() {
    _load();
    return (triggered: false, dismissed: false);
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Another isolate may have written since.
      if (!ref.mounted) return;
      // Never undo a flag written while this load was in flight.
      state = (
        triggered:
            state.triggered || (prefs.getBool(firstRunTriggeredKey) ?? false),
        dismissed:
            state.dismissed || (prefs.getBool(firstRunDismissedKey) ?? false),
      );
    } on Object {
      // No prefs on this host: keep the defaults rather than failing Home.
    }
  }

  /// Called by the Jenkins and GitHub trigger notifiers on success.
  Future<void> markTriggered() async {
    if (state.triggered) return;
    state = (triggered: true, dismissed: state.dismissed);
    await _write(firstRunTriggeredKey);
  }

  /// Hides the card for good for this user.
  Future<void> dismiss() async {
    if (state.dismissed) return;
    state = (triggered: state.triggered, dismissed: true);
    await _write(firstRunDismissedKey);
  }

  Future<void> _write(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    } on Object {
      // The in-memory flag still hides the card for this session.
    }
  }
}
