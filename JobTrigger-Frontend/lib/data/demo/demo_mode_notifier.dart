import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'demo_mode_notifier.g.dart';

/// `shared_preferences` key for demo mode. It holds no secret, so it does
/// not belong in secure storage (E2, PE-11).
const demoModePrefKey = 'demo_mode';

/// The value read from `shared_preferences` before the app starts, so the
/// first frame and the session check already know whether demo mode is on.
/// `main()` overrides it; tests default to off.
@Riverpod(keepAlive: true)
bool demoModeInitial(Ref ref) => false;

/// E2 (PE-11): whether the app runs on built-in sample data. While on, the
/// repository providers return the in-memory demo repositories, so no
/// request leaves the device and no stored credential is read. Entered only
/// from the sign-in screen and left with "Exit demo".
@Riverpod(keepAlive: true)
class DemoModeNotifier extends _$DemoModeNotifier {
  @override
  bool build() => ref.watch(demoModeInitialProvider);

  Future<void> enter() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(demoModePrefKey, true);
  }

  Future<void> exit() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(demoModePrefKey);
  }
}

/// Reads the stored flag; used once by `main()`.
Future<bool> readStoredDemoMode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(demoModePrefKey) ?? false;
}
